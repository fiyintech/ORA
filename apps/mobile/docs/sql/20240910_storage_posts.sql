-- ORA Post Media Storage
-- IMPORTANT: Prepared for the Supabase phase. Do NOT run automatically.
-- Based on the current web post service: bucket "posts", public image URLs,
-- and object paths rooted at <authenticated-user-id>/.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'posts',
  'posts',
  true,
  10485760,
  array['image/jpeg','image/png','image/webp','image/gif']
)
on conflict (id) do update
set public = excluded.public,
    file_size_limit = excluded.file_size_limit,
    allowed_mime_types = excluded.allowed_mime_types;

-- Public read is intentional because the web app stores public object URLs
-- in posts.media_urls and renders them directly in the feed.
drop policy if exists "Public can read post media" on storage.objects;
create policy "Public can read post media"
on storage.objects for select
using (bucket_id = 'posts');

-- Uploads must live under the authenticated user's UUID directory.
drop policy if exists "Users can upload their own post media" on storage.objects;
create policy "Users can upload their own post media"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'posts'
  and (storage.foldername(name))[1] = auth.uid()::text
);

-- Users may replace/remove only objects in their own directory.
drop policy if exists "Users can update their own post media" on storage.objects;
create policy "Users can update their own post media"
on storage.objects for update to authenticated
using (
  bucket_id = 'posts'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'posts'
  and (storage.foldername(name))[1] = auth.uid()::text
);

drop policy if exists "Users can delete their own post media" on storage.objects;
create policy "Users can delete their own post media"
on storage.objects for delete to authenticated
using (
  bucket_id = 'posts'
  and (storage.foldername(name))[1] = auth.uid()::text
);
