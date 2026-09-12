-- ORA Hood RLS recursion fix
-- Uses SECURITY DEFINER membership helpers so policies never recursively
-- query hood_members through its own RLS policy.

create or replace function public.is_hood_member(
  p_hood_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.hood_members hm
    where hm.hood_id = p_hood_id
      and hm.user_id = p_user_id
  );
$$;

create or replace function public.can_view_hood_members(
  p_hood_id uuid,
  p_user_id uuid default auth.uid()
)
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.hood_members hm
    where hm.hood_id = p_hood_id
      and hm.user_id = p_user_id
  )
  or exists (
    select 1
    from public.hoods h
    where h.id = p_hood_id
      and (h.privacy = 'public' or h.owner_id = p_user_id)
  );
$$;

revoke all on function public.is_hood_member(uuid, uuid) from public, anon;
grant execute on function public.is_hood_member(uuid, uuid) to authenticated;
revoke all on function public.can_view_hood_members(uuid, uuid) from public, anon;
grant execute on function public.can_view_hood_members(uuid, uuid) to authenticated;

alter table public.hood_members enable row level security;
alter table public.hoods enable row level security;
alter table public.hood_posts enable row level security;

drop policy if exists hood_members_select_members on public.hood_members;
create policy hood_members_select_visible
on public.hood_members
for select to authenticated
using (public.can_view_hood_members(hood_id));

drop policy if exists hoods_select_visible on public.hoods;
create policy hoods_select_visible
on public.hoods
for select to authenticated
using (
  privacy = 'public'
  or owner_id = (select auth.uid())
  or public.is_hood_member(id)
);

drop policy if exists hood_posts_select_members on public.hood_posts;
create policy hood_posts_select_members
on public.hood_posts
for select to authenticated
using (
  public.is_hood_member(hood_id)
  or exists (
    select 1
    from public.hoods h
    where h.id = hood_posts.hood_id
      and h.privacy = 'public'
  )
);

drop policy if exists hood_posts_insert_members on public.hood_posts;
create policy hood_posts_insert_members
on public.hood_posts
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and public.is_hood_member(hood_id)
);

revoke all on function public.add_hood_owner_membership() from public, anon, authenticated;
