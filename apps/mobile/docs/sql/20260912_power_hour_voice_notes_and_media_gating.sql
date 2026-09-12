begin;

alter table public.messages add column if not exists media_duration_ms bigint;
alter table public.messages drop constraint if exists messages_media_duration_ms_check;
alter table public.messages add constraint messages_media_duration_ms_check check (media_duration_ms is null or media_duration_ms >= 0);

update storage.buckets
set allowed_mime_types = array[
  'image/jpeg','image/png','image/webp','image/gif','image/avif','image/bmp',
  'video/mp4','video/webm','video/quicktime','video/ogg','video/mpeg','video/x-m4v',
  'audio/webm','audio/ogg','audio/mpeg','audio/mp4','audio/wav'
]::text[]
where id = 'chat-media';

create or replace function public.send_message(p_conversation_id uuid,p_content text default '',p_media_path text default null,p_media_type text default null)
returns public.messages language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); result public.messages; premium_active boolean;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  if not public.is_conversation_member(p_conversation_id,uid) then raise exception 'You are not a member of this conversation.'; end if;
  select exists(select 1 from public.premium_entitlements where user_id=uid and expires_at>now()) into premium_active;
  if coalesce(length(trim(p_content)),0)>1000 then raise exception 'Message cannot exceed 1000 characters.'; end if;
  if p_media_type is not null and p_media_type not in ('image','video','audio') then raise exception 'Unsupported media type.'; end if;
  if p_media_type='video' and not premium_active then raise exception 'Video messages require Power Hour.'; end if;
  if p_media_path is not null and p_media_path !~ ('^'||uid::text||'/') then raise exception 'Invalid media path.'; end if;
  if coalesce(length(trim(p_content)),0)=0 and p_media_path is null then raise exception 'Message cannot be empty.'; end if;
  insert into public.messages(conversation_id,sender_id,content,media_url,media_path,media_type,media_duration_ms,media_expires_at)
  values(p_conversation_id,uid,coalesce(trim(p_content),''),case when p_media_path is null then null else 'pending' end,p_media_path,p_media_type,null,case when p_media_path is null then null else now()+interval '24 hours' end)
  returning * into result;
  update public.conversations set updated_at=now() where id=p_conversation_id;
  return result;
end; $$;

create or replace function public.send_message(p_conversation_id uuid,p_content text,p_media_path text,p_media_type text,p_media_duration_ms bigint)
returns public.messages language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); result public.messages; premium_active boolean;

begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  if not public.is_conversation_member(p_conversation_id,uid) then raise exception 'You are not a member of this conversation.'; end if;
  select exists(select 1 from public.premium_entitlements where user_id=uid and expires_at>now()) into premium_active;
  if coalesce(length(trim(p_content)),0)>1000 then raise exception 'Message cannot exceed 1000 characters.'; end if;
  if p_media_type is not null and p_media_type not in ('image','video','audio') then raise exception 'Unsupported media type.'; end if;
  if p_media_type='video' and not premium_active then raise exception 'Video messages require Power Hour.'; end if;
  if p_media_type='audio' and coalesce(p_media_duration_ms,0)>60000 and not premium_active then raise exception 'Standard voice notes are limited to 60 seconds.'; end if;
  if p_media_path is not null and p_media_path !~ ('^'||uid::text||'/') then raise exception 'Invalid media path.'; end if;
  if coalesce(length(trim(p_content)),0)=0 and p_media_path is null then raise exception 'Message cannot be empty.'; end if;
  insert into public.messages(conversation_id,sender_id,content,media_url,media_path,media_type,media_duration_ms,media_expires_at)
  values(p_conversation_id,uid,coalesce(trim(p_content),''),case when p_media_path is null then null else 'pending' end,p_media_path,p_media_type,p_media_duration_ms,case when p_media_path is null then null else now()+interval '24 hours' end)
  returning * into result;
  update public.conversations set updated_at=now() where id=p_conversation_id;
  return result;
end; $$;

revoke all on function public.send_message(uuid,text,text,text) from public,anon,authenticated;
grant execute on function public.send_message(uuid,text,text,text) to authenticated;
revoke all on function public.send_message(uuid,text,text,text,bigint) from public,anon,authenticated;
grant execute on function public.send_message(uuid,text,text,text,bigint) to authenticated;

commit;
