-- ORA web follow-up: messaging notifications, private Hood requests/admin,
-- and profile media storage.
-- This file mirrors the targeted live migration applied to the connected project.

begin;

alter table public.notifications
  add column if not exists conversation_id uuid references public.conversations(id) on delete cascade;
create index if not exists notifications_conversation_id_idx on public.notifications(conversation_id);

create table if not exists public.hood_join_requests (
  id uuid primary key default gen_random_uuid(),
  hood_id uuid not null references public.hoods(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','approved','declined')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists hood_join_requests_hood_status_idx on public.hood_join_requests(hood_id,status,created_at desc);
create index if not exists hood_join_requests_user_status_idx on public.hood_join_requests(user_id,status,created_at desc);
create unique index if not exists hood_join_requests_one_pending_idx on public.hood_join_requests(hood_id,user_id) where status='pending';
alter table public.hood_join_requests enable row level security;
drop policy if exists hood_join_requests_select_own_or_owner on public.hood_join_requests;
create policy hood_join_requests_select_own_or_owner on public.hood_join_requests for select to authenticated using (
  user_id=(select auth.uid()) or exists(select 1 from public.hoods h where h.id=hood_join_requests.hood_id and h.owner_id=(select auth.uid()))
);
drop policy if exists hood_join_requests_delete_own on public.hood_join_requests;
create policy hood_join_requests_delete_own on public.hood_join_requests for delete to authenticated using (user_id=(select auth.uid()) and status='pending');

create or replace function public.request_hood_join(p_hood_id uuid) returns text
language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); hood_privacy text;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  select privacy into hood_privacy from public.hoods where id=p_hood_id;
  if hood_privacy is null then raise exception 'Hood not found.'; end if;
  if exists(select 1 from public.hood_members where hood_id=p_hood_id and user_id=uid) then return 'joined'; end if;
  if hood_privacy='public' then
    insert into public.hood_members(hood_id,user_id,role) values(p_hood_id,uid,'member') on conflict(hood_id,user_id) do nothing;
    return 'joined';
  end if;
  if exists(select 1 from public.hood_join_requests where hood_id=p_hood_id and user_id=uid and status='pending') then return 'pending'; end if;
  insert into public.hood_join_requests(hood_id,user_id,status) values(p_hood_id,uid,'pending');
  return 'pending';
end; $$;

create or replace function public.review_hood_join_request(p_request_id uuid,p_approve boolean) returns text
language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); req public.hood_join_requests%rowtype; hood_owner uuid;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  select * into req from public.hood_join_requests where id=p_request_id;
  if req.id is null then raise exception 'Join request not found.'; end if;
  if req.status<>'pending' then return req.status; end if;
  select owner_id into hood_owner from public.hoods where id=req.hood_id;
  if hood_owner<>uid then raise exception 'Only the Hood owner can review join requests.'; end if;
  if p_approve then
    insert into public.hood_members(hood_id,user_id,role) values(req.hood_id,req.user_id,'member') on conflict(hood_id,user_id) do nothing;
    update public.hood_join_requests set status='approved',updated_at=now() where id=req.id;
    return 'approved';
  else
    update public.hood_join_requests set status='declined',updated_at=now() where id=req.id;
    return 'declined';
  end if;
end; $$;

create or replace function public.remove_hood_member(p_hood_id uuid,p_user_id uuid) returns boolean
language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); owner_id uuid;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  select owner_id into owner_id from public.hoods where id=p_hood_id;
  if owner_id is null then raise exception 'Hood not found.'; end if;
  if owner_id<>uid then raise exception 'Only the Hood owner can remove members.'; end if;
  if p_user_id=owner_id then raise exception 'The Hood owner cannot be removed.'; end if;
  delete from public.hood_members where hood_id=p_hood_id and user_id=p_user_id;
  return found;
end; $$;
revoke all on function public.request_hood_join(uuid) from public,anon,authenticated;
grant execute on function public.request_hood_join(uuid) to authenticated;
revoke all on function public.review_hood_join_request(uuid,boolean) from public,anon,authenticated;
grant execute on function public.review_hood_join_request(uuid,boolean) to authenticated;
revoke all on function public.remove_hood_member(uuid,uuid) from public,anon,authenticated;
grant execute on function public.remove_hood_member(uuid,uuid) to authenticated;

create or replace function public.notify_on_message() returns trigger
language plpgsql security definer set search_path=public,pg_temp as $$
declare recipient uuid;
begin
  for recipient in select cm.user_id from public.conversation_members cm where cm.conversation_id=new.conversation_id and cm.user_id<>new.sender_id loop
    insert into public.notifications(recipient_id,actor_id,conversation_id,type,is_read,created_at)
    values(recipient,new.sender_id,new.conversation_id,'message',false,coalesce(new.created_at,now()));
  end loop;
  return new;
end; $$;
revoke all on function public.notify_on_message() from public,anon,authenticated;
drop trigger if exists notifications_message on public.messages;
create trigger notifications_message after insert on public.messages for each row execute function public.notify_on_message();
alter publication supabase_realtime add table public.notifications;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('profile-media','profile-media',true,5242880,array['image/jpeg','image/png','image/webp','image/gif']::text[])
on conflict(id) do update set public=excluded.public,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists profile_media_public_read on storage.objects;
create policy profile_media_public_read on storage.objects for select to public using(bucket_id='profile-media');
drop policy if exists profile_media_user_insert on storage.objects;
create policy profile_media_user_insert on storage.objects for insert to authenticated with check(bucket_id='profile-media' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists profile_media_user_update on storage.objects;
create policy profile_media_user_update on storage.objects for update to authenticated using(bucket_id='profile-media' and (storage.foldername(name))[1]=(select auth.uid())::text) with check(bucket_id='profile-media' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists profile_media_user_delete on storage.objects;
create policy profile_media_user_delete on storage.objects for delete to authenticated using(bucket_id='profile-media' and (storage.foldername(name))[1]=(select auth.uid())::text);

create or replace function public.get_hood_by_id(p_hood_id uuid)
returns table(id uuid,owner_id uuid,name text,description text,category text,banner text,privacy text,created_at timestamptz,updated_at timestamptz,member_count bigint,is_joined boolean,join_status text)
language sql stable security definer set search_path=public,pg_temp as $$
  select h.id,h.owner_id,h.name,h.description,h.category,h.banner,h.privacy,h.created_at,h.updated_at,
    (select count(*) from public.hood_members hm where hm.hood_id=h.id),
    exists(select 1 from public.hood_members hm where hm.hood_id=h.id and hm.user_id=auth.uid()),
    case when exists(select 1 from public.hood_members hm where hm.hood_id=h.id and hm.user_id=auth.uid()) then 'joined'
         when exists(select 1 from public.hood_join_requests r where r.hood_id=h.id and r.user_id=auth.uid() and r.status='pending') then 'pending'
         else 'none' end
  from public.hoods h where h.id=p_hood_id and auth.uid() is not null;
$$;
revoke all on function public.get_hood_by_id(uuid) from public,anon,authenticated;
grant execute on function public.get_hood_by_id(uuid) to authenticated;

commit;
