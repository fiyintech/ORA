-- ORA web: chat media lifecycle and rejoin protection for removed Hood members.
begin;

alter table public.messages
  add column if not exists media_url text,
  add column if not exists media_path text,
  add column if not exists media_type text,
  add column if not exists media_viewed_at timestamptz,
  add column if not exists media_expires_at timestamptz;
create index if not exists messages_media_expiry_idx on public.messages(media_expires_at) where media_expires_at is not null;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('chat-media','chat-media',true,52428800,array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm','video/quicktime']::text[])
on conflict(id) do update set public=excluded.public,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists chat_media_public_read on storage.objects;
create policy chat_media_public_read on storage.objects for select to public using (bucket_id='chat-media');
drop policy if exists chat_media_user_insert on storage.objects;
create policy chat_media_user_insert on storage.objects for insert to authenticated with check (bucket_id='chat-media' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists chat_media_user_delete on storage.objects;
create policy chat_media_user_delete on storage.objects for delete to authenticated using (bucket_id='chat-media' and (storage.foldername(name))[1]=(select auth.uid())::text);

create or replace function public.send_message(p_conversation_id uuid,p_content text default '',p_media_path text default null,p_media_type text default null)
returns public.messages language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); result public.messages;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  if not public.is_conversation_member(p_conversation_id,uid) then raise exception 'You are not a member of this conversation.'; end if;
  if coalesce(length(trim(p_content)),0)>2000 then raise exception 'Message cannot exceed 2000 characters.'; end if;
  if p_media_type is not null and p_media_type not in ('image','video') then raise exception 'Unsupported media type.'; end if;
  if p_media_path is not null and p_media_path !~ ('^'||uid::text||'/') then raise exception 'Invalid media path.'; end if;
  if coalesce(length(trim(p_content)),0)=0 and p_media_path is null then raise exception 'Message cannot be empty.'; end if;
  insert into public.messages(conversation_id,sender_id,content,media_url,media_path,media_type,media_expires_at)
  values(p_conversation_id,uid,coalesce(trim(p_content),''),case when p_media_path is null then null else 'pending' end,p_media_path,p_media_type,case when p_media_path is null then null else now()+interval '24 hours' end)
  returning * into result;
  update public.conversations set updated_at=now() where id=p_conversation_id;
  return result;
end; $$;
revoke all on function public.send_message(uuid,text,text,text) from public,anon,authenticated;
grant execute on function public.send_message(uuid,text,text,text) to authenticated;

create or replace function public.attach_message_media(p_message_id uuid,p_media_url text)
returns public.messages language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); result public.messages;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  update public.messages set media_url=p_media_url where id=p_message_id and sender_id=uid and media_path is not null returning * into result;
  if result.id is null then raise exception 'Message not found or not yours.'; end if;
  return result;
end; $$;
revoke all on function public.attach_message_media(uuid,text) from public,anon,authenticated;
grant execute on function public.attach_message_media(uuid,text) to authenticated;

create or replace function public.mark_message_media_viewed(p_message_id uuid)
returns public.messages language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); result public.messages;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  update public.messages m set media_viewed_at=coalesce(media_viewed_at,now()),media_expires_at=coalesce(media_expires_at,now())+interval '3 minutes'
  where m.id=p_message_id and m.sender_id<>uid and public.is_conversation_member(m.conversation_id,uid) and m.media_path is not null returning m.* into result;
  if result.id is null then raise exception 'Media is unavailable or you cannot view it.'; end if;
  return result;
end; $$;
revoke all on function public.mark_message_media_viewed(uuid) from public,anon,authenticated;
grant execute on function public.mark_message_media_viewed(uuid) to authenticated;

create table if not exists public.hood_member_restrictions(hood_id uuid not null references public.hoods(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,removed_at timestamptz not null default now(),removed_by uuid references auth.users(id) on delete set null,primary key(hood_id,user_id));
create index if not exists hood_member_restrictions_user_idx on public.hood_member_restrictions(user_id,hood_id);
alter table public.hood_member_restrictions enable row level security;
drop policy if exists hood_member_restrictions_select_own_or_admin on public.hood_member_restrictions;
create policy hood_member_restrictions_select_own_or_admin on public.hood_member_restrictions for select to authenticated using(user_id=(select auth.uid()) or public.is_hood_admin(hood_id,(select auth.uid())));

create table if not exists public.hood_rejoin_requests(id uuid primary key default gen_random_uuid(),hood_id uuid not null references public.hoods(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,status text not null default 'pending' check(status in ('pending','approved','declined')),created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create index if not exists hood_rejoin_requests_hood_status_idx on public.hood_rejoin_requests(hood_id,status,created_at desc);
create unique index if not exists hood_rejoin_requests_one_pending_idx on public.hood_rejoin_requests(hood_id,user_id) where status='pending';
alter table public.hood_rejoin_requests enable row level security;
drop policy if exists hood_rejoin_requests_select_own_or_owner on public.hood_rejoin_requests;
create policy hood_rejoin_requests_select_own_or_owner on public.hood_rejoin_requests for select to authenticated using(user_id=(select auth.uid()) or exists(select 1 from public.hoods h where h.id=hood_rejoin_requests.hood_id and h.owner_id=(select auth.uid())));
drop policy if exists hood_rejoin_requests_delete_own on public.hood_rejoin_requests;
create policy hood_rejoin_requests_delete_own on public.hood_rejoin_requests for delete to authenticated using(user_id=(select auth.uid()) and status='pending');

create or replace function public.request_hood_join(p_hood_id uuid) returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); hood_privacy text;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  select privacy into hood_privacy from public.hoods where id=p_hood_id;
  if hood_privacy is null then raise exception 'Hood not found.'; end if;
  if exists(select 1 from public.hood_members where hood_id=p_hood_id and user_id=uid) then return 'joined'; end if;
  if exists(select 1 from public.hood_member_restrictions where hood_id=p_hood_id and user_id=uid) then return 'removed'; end if;
  if hood_privacy='public' then insert into public.hood_members(hood_id,user_id,role) values(p_hood_id,uid,'member') on conflict(hood_id,user_id) do nothing; return 'joined'; end if;
  if exists(select 1 from public.hood_join_requests where hood_id=p_hood_id and user_id=uid and status='pending') then return 'pending'; end if;
  insert into public.hood_join_requests(hood_id,user_id,status) values(p_hood_id,uid,'pending'); return 'pending';
end; $$;

create or replace function public.remove_hood_member(p_hood_id uuid,p_user_id uuid) returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); owner_id uuid; target_role text; changed boolean;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  select h.owner_id into owner_id from public.hoods h where id=p_hood_id;
  if owner_id is null then raise exception 'Hood not found.'; end if;
  if not public.is_hood_admin(p_hood_id,uid) then raise exception 'Only Hood admins can remove members.'; end if;
  if p_user_id=owner_id then raise exception 'The Hood owner cannot be removed.'; end if;
  select role into target_role from public.hood_members where hood_id=p_hood_id and user_id=p_user_id;
  if target_role='moderator' and uid<>owner_id then raise exception 'Only the Hood owner can remove another admin.'; end if;
  delete from public.hood_members where hood_id=p_hood_id and user_id=p_user_id; changed:=found;
  if changed then insert into public.hood_member_restrictions(hood_id,user_id,removed_by) values(p_hood_id,p_user_id,uid) on conflict(hood_id,user_id) do update set removed_at=now(),removed_by=excluded.removed_by; end if;
  return changed;
end; $$;

create or replace function public.request_hood_rejoin(p_hood_id uuid) returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid();
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  if not exists(select 1 from public.hood_member_restrictions where hood_id=p_hood_id and user_id=uid) then raise exception 'You are not restricted from this Hood.'; end if;
  if exists(select 1 from public.hood_rejoin_requests where hood_id=p_hood_id and user_id=uid and status='pending') then return 'pending'; end if;
  insert into public.hood_rejoin_requests(hood_id,user_id,status) values(p_hood_id,uid,'pending'); return 'pending';
end; $$;

create or replace function public.review_hood_rejoin_request(p_request_id uuid,p_approve boolean) returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); req public.hood_rejoin_requests%rowtype; owner_id uuid;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  select * into req from public.hood_rejoin_requests where id=p_request_id;
  if req.id is null then raise exception 'Rejoin request not found.'; end if;
  if req.status<>'pending' then return req.status; end if;
  select h.owner_id into owner_id from public.hoods h where h.id=req.hood_id;
  if owner_id<>uid then raise exception 'Only the Hood owner can approve rejoin requests.'; end if;
  if p_approve then delete from public.hood_member_restrictions where hood_id=req.hood_id and user_id=req.user_id; insert into public.hood_members(hood_id,user_id,role) values(req.hood_id,req.user_id,'member') on conflict(hood_id,user_id) do nothing; update public.hood_rejoin_requests set status='approved',updated_at=now() where id=req.id; return 'approved'; end if;
  update public.hood_rejoin_requests set status='declined',updated_at=now() where id=req.id; return 'declined';
end; $$;

revoke all on function public.request_hood_join(uuid) from public,anon,authenticated; grant execute on function public.request_hood_join(uuid) to authenticated;
revoke all on function public.remove_hood_member(uuid,uuid) from public,anon,authenticated; grant execute on function public.remove_hood_member(uuid,uuid) to authenticated;
revoke all on function public.request_hood_rejoin(uuid) from public,anon,authenticated; grant execute on function public.request_hood_rejoin(uuid) to authenticated;
revoke all on function public.review_hood_rejoin_request(uuid,boolean) from public,anon,authenticated; grant execute on function public.review_hood_rejoin_request(uuid,boolean) to authenticated;

commit;
