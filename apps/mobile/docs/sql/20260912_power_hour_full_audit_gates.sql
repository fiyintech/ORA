-- ORA Power Hour full-audit hardening.
-- Enforces the Standard/Premium limits at the database/storage boundary so
-- browser-only restrictions cannot be bypassed through direct Supabase calls.

-- Posts: Standard = text-only, <=500 chars; Power Hour = <=8 images, <=1000 chars.
drop policy if exists "Authenticated users can insert posts" on public.posts;
drop policy if exists "Users can update own posts" on public.posts;

create policy "posts_insert_entitlement_gate"
on public.posts
for insert
to authenticated
with check (
  auth.uid() = user_id
  and coalesce(length(trim(content)), 0) <= case
    when exists (
      select 1 from public.premium_entitlements pe
      where pe.user_id = auth.uid() and pe.expires_at > now()
    ) then 1000 else 500 end
  and coalesce(array_length(media_urls, 1), 0) <= case
    when exists (
      select 1 from public.premium_entitlements pe
      where pe.user_id = auth.uid() and pe.expires_at > now()
    ) then 8 else 0 end
);

create policy "posts_update_entitlement_gate"
on public.posts
for update
to authenticated
using (auth.uid() = user_id)
with check (
  auth.uid() = user_id
  and coalesce(length(trim(content)), 0) <= case
    when exists (
      select 1 from public.premium_entitlements pe
      where pe.user_id = auth.uid() and pe.expires_at > now()
    ) then 1000 else 500 end
  and coalesce(array_length(media_urls, 1), 0) <= case
    when exists (
      select 1 from public.premium_entitlements pe
      where pe.user_id = auth.uid() and pe.expires_at > now()
    ) then 8 else 0 end
);

-- Feed image objects are Power Hour-only. This prevents Standard users from
-- uploading an image and then attaching it through a direct posts INSERT.
drop policy if exists "Authenticated users can upload posts" on storage.objects;
drop policy if exists "posts_user_upload" on storage.objects;

create policy "posts_user_upload_power_hour"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'posts'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (
    select 1 from public.premium_entitlements pe
    where pe.user_id = (select auth.uid()) and pe.expires_at > now()
  )
);

-- Reposts are created/removed only through the entitlement-aware RPCs.
drop policy if exists "Users can repost posts" on public.post_reposts;
drop policy if exists "Users can remove their reposts" on public.post_reposts;

-- Messages are created only through send_message(), which enforces membership,
-- content limits, media type, media size and the daily voice quota atomically.
drop policy if exists "chat_send_messages" on public.messages;

create policy "chat_send_messages_via_rpc"
on public.messages
for insert
to authenticated
with check (false);

-- Harden the 5-argument send_message function itself against direct RPC calls.
create or replace function public.send_message(
  p_conversation_id uuid,
  p_content text,
  p_media_path text,
  p_media_type text,
  p_media_duration_ms bigint
)
returns public.messages
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  uid uuid := auth.uid();
  result public.messages;
  premium_active boolean;
  today_utc date := (now() at time zone 'utc')::date;
  used_ms bigint := 0;
  new_used_ms bigint;
  media_size bigint;
  media_mimetype text;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  if not public.is_conversation_member(p_conversation_id, uid) then
    raise exception 'You are not a member of this conversation.';
  end if;

  select exists(
    select 1 from public.premium_entitlements
    where user_id = uid and expires_at > now()
  ) into premium_active;

  if coalesce(length(trim(p_content)), 0) > case when premium_active then 1000 else 500 end then
    raise exception 'Message cannot exceed % characters.', case when premium_active then 1000 else 500 end;
  end if;

  if p_media_type is not null and p_media_type not in ('image','video','audio') then
    raise exception 'Unsupported media type.';
  end if;

  if p_media_type = 'video' and not premium_active then
    raise exception 'Video messages require Power Hour.';
  end if;

  if p_media_path is not null then
    if p_media_path !~ ('^'||uid::text||'/') then
      raise exception 'Invalid media path.';
    end if;

    select
      nullif(metadata->>'size','')::bigint,
      metadata->>'mimetype'
    into media_size, media_mimetype
    from storage.objects
    where bucket_id = 'chat-media'
      and name = p_media_path
      and (owner_id = uid::text or owner = uid)
    limit 1;

    if media_size is null then
      raise exception 'Uploaded media could not be verified.';
    end if;

    if media_size > 52428800 then
      raise exception 'Media must be 50 MB or smaller.';
    end if;

    if not premium_active and p_media_type = 'image' and media_size > 6291456 then
      raise exception 'Standard photo messages are limited to 6 MB.';
    end if;

    if p_media_type = 'image' and media_mimetype not like 'image/%' then
      raise exception 'Invalid image media.';
    end if;
    if p_media_type = 'video' and media_mimetype not like 'video/%' then
      raise exception 'Invalid video media.';
    end if;
    if p_media_type = 'audio' and media_mimetype not like 'audio/%' then
      raise exception 'Invalid audio media.';
    end if;
  end if;

  if p_media_type = 'audio' then
    if coalesce(p_media_duration_ms, 0) <= 0 then
      raise exception 'Voice note duration is required.';
    end if;

    if not premium_active then
      select coalesce(v.used_ms,0)
      into used_ms
      from public.voice_note_daily_usage v
      where v.user_id = uid
        and v.usage_date = today_utc
      for update;

      new_used_ms := used_ms + p_media_duration_ms;
      if new_used_ms > 60000 then
        raise exception 'You have used your 60-second Standard voice-note allowance for today.';
      end if;

      insert into public.voice_note_daily_usage(user_id,usage_date,used_ms,updated_at)
      values(uid,today_utc,new_used_ms,now())
      on conflict(user_id,usage_date)
      do update set used_ms=excluded.used_ms,updated_at=now();
    end if;
  end if;

  if coalesce(length(trim(p_content)),0)=0 and p_media_path is null then
    raise exception 'Message cannot be empty.';
  end if;

  insert into public.messages(
    conversation_id,sender_id,content,media_url,media_path,media_type,media_duration_ms,media_expires_at
  ) values(
    p_conversation_id,uid,coalesce(trim(p_content),''),
    case when p_media_path is null then null else 'pending' end,
    p_media_path,p_media_type,p_media_duration_ms,
    case when p_media_path is null then null else now()+interval '24 hours' end
  ) returning * into result;

  update public.conversations set updated_at=now() where id=p_conversation_id;
  return result;
end;
$$;

-- Keep the legacy wrapper aligned with the hardened implementation.
create or replace function public.send_message(
  p_conversation_id uuid,
  p_content text default '',
  p_media_path text default null,
  p_media_type text default null
)
returns public.messages
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  return public.send_message(p_conversation_id,p_content,p_media_path,p_media_type,null);
end;
$$;
