-- ORA live feed realtime
-- Keep the web feed synchronized without manual refreshes.
-- Messages and notifications are enabled by earlier migrations.

do $$
begin
  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'posts'
  ) then
    alter publication supabase_realtime add table public.posts;
  end if;

  if not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'post_reposts'
  ) then
    alter publication supabase_realtime add table public.post_reposts;
  end if;
end $$;
