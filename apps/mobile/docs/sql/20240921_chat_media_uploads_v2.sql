-- ORA chat media upload compatibility
-- Prepared migration. Apply through the project's Supabase migration workflow.
-- Keeps the existing 50 MB plan-level ceiling, but supports more browser-native media MIME types.

begin;

update storage.buckets
set allowed_mime_types = array[
  'image/jpeg','image/png','image/webp','image/gif','image/avif','image/bmp',
  'video/mp4','video/webm','video/quicktime','video/ogg','video/mpeg','video/x-m4v'
]::text[]
where id = 'chat-media';

commit;
