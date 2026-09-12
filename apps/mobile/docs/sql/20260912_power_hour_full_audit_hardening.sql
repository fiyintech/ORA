-- ORA Power Hour full-audit hardening.
-- Applied to production as four migrations on 2026-09-12:
--   power_hour_full_audit_policies
--   power_hour_audit_message_limit_helper
--   power_hour_audit_message_checks
--   power_hour_audit_helper_privileges

DROP POLICY IF EXISTS "Authenticated users can insert posts" ON public.posts;
DROP POLICY IF EXISTS "Users can update own posts" ON public.posts;
CREATE POLICY "posts_insert_entitlement_gate" ON public.posts
FOR INSERT TO authenticated
WITH CHECK (
  auth.uid() = user_id
  AND coalesce(length(trim(content)), 0) <= CASE
    WHEN EXISTS (SELECT 1 FROM public.premium_entitlements pe WHERE pe.user_id = auth.uid() AND pe.expires_at > now()) THEN 1000
    ELSE 500
  END
  AND coalesce(array_length(media_urls, 1), 0) <= CASE
    WHEN EXISTS (SELECT 1 FROM public.premium_entitlements pe WHERE pe.user_id = auth.uid() AND pe.expires_at > now()) THEN 8
    ELSE 0
  END
);

CREATE POLICY "posts_update_entitlement_gate" ON public.posts
FOR UPDATE TO authenticated
USING (auth.uid() = user_id)
WITH CHECK (
  auth.uid() = user_id
  AND coalesce(length(trim(content)), 0) <= CASE
    WHEN EXISTS (SELECT 1 FROM public.premium_entitlements pe WHERE pe.user_id = auth.uid() AND pe.expires_at > now()) THEN 1000
    ELSE 500
  END
  AND coalesce(array_length(media_urls, 1), 0) <= CASE
    WHEN EXISTS (SELECT 1 FROM public.premium_entitlements pe WHERE pe.user_id = auth.uid() AND pe.expires_at > now()) THEN 8
    ELSE 0
  END
);

DROP POLICY IF EXISTS "Authenticated users can upload posts" ON storage.objects;
DROP POLICY IF EXISTS "posts_user_upload" ON storage.objects;
CREATE POLICY "posts_user_upload_power_hour" ON storage.objects
FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'posts'
  AND (storage.foldername(name))[1] = (select auth.uid())::text
  AND EXISTS (
    SELECT 1 FROM public.premium_entitlements pe
    WHERE pe.user_id = (select auth.uid()) AND pe.expires_at > now()
  )
);

DROP POLICY IF EXISTS "Users can repost posts" ON public.post_reposts;
DROP POLICY IF EXISTS "Users can remove their reposts" ON public.post_reposts;

DROP POLICY IF EXISTS "chat_send_messages" ON public.messages;
CREATE POLICY "chat_send_messages_via_rpc" ON public.messages
FOR INSERT TO authenticated WITH CHECK (false);

CREATE OR REPLACE FUNCTION public.ora_message_content_limit_ok(p_user_id uuid, p_content text)
RETURNS boolean
LANGUAGE sql SECURITY DEFINER
SET search_path = public
AS 'select coalesce(length(trim(p_content)),0) <= case when exists (select 1 from public.premium_entitlements where user_id = p_user_id and expires_at > now()) then 1000 else 500 end';

CREATE OR REPLACE FUNCTION public.ora_message_media_ok(p_user_id uuid, p_media_path text, p_media_type text)
RETURNS boolean
LANGUAGE sql SECURITY DEFINER
SET search_path = public, storage
AS 'select case when p_media_path is null then true else exists (select 1 from storage.objects o where o.bucket_id = ''chat-media'' and o.name = p_media_path and (o.owner_id = p_user_id::text or o.owner = p_user_id) and coalesce((o.metadata->>''size'')::bigint,0) <= 52428800 and ((p_media_type = ''image'' and coalesce(o.metadata->>''mimetype'','''') like ''image/%'' and (exists (select 1 from public.premium_entitlements pe where pe.user_id = p_user_id and pe.expires_at > now()) or coalesce((o.metadata->>''size'')::bigint,0) <= 6291456)) or (p_media_type = ''video'' and coalesce(o.metadata->>''mimetype'','''') like ''video/%'' and exists (select 1 from public.premium_entitlements pe where pe.user_id = p_user_id and pe.expires_at > now())) or (p_media_type = ''audio'' and coalesce(o.metadata->>''mimetype'','''') like ''audio/%''))) end';

ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_content_entitlement_check;
ALTER TABLE public.messages ADD CONSTRAINT messages_content_entitlement_check CHECK (public.ora_message_content_limit_ok(sender_id, content));
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_media_entitlement_check;
ALTER TABLE public.messages ADD CONSTRAINT messages_media_entitlement_check CHECK (public.ora_message_media_ok(sender_id, media_path, media_type));

REVOKE EXECUTE ON FUNCTION public.ora_message_content_limit_ok(uuid,text) FROM public, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.ora_message_media_ok(uuid,text,text) FROM public, anon, authenticated;
