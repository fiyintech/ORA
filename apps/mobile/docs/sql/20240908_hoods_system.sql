-- ORA Hoods system
-- IMPORTANT: This migration is prepared for the Supabase phase.
-- Do NOT run it automatically.
-- It follows apps/mobile/docs/architecture/database_blueprint.md.

create table if not exists public.hoods (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  category text,
  banner text,
  privacy text not null default 'public' check (privacy in ('public', 'private')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists hoods_owner_id_idx on public.hoods(owner_id);
create index if not exists hoods_category_idx on public.hoods(category);

create table if not exists public.hood_members (
  hood_id uuid not null references public.hoods(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null default 'member' check (role in ('member', 'moderator', 'owner')),
  joined_at timestamptz not null default now(),
  primary key (hood_id, user_id)
);

create or replace function public.add_hood_owner_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.hood_members (hood_id, user_id, role)
  values (new.id, new.owner_id, 'owner')
  on conflict (hood_id, user_id) do update
    set role = 'owner';
  return new;
end;
$$;

drop trigger if exists trigger_add_hood_owner_membership on public.hoods;
create trigger trigger_add_hood_owner_membership
after insert on public.hoods
for each row
execute function public.add_hood_owner_membership();

create table if not exists public.hood_posts (
  id uuid primary key default gen_random_uuid(),
  hood_id uuid not null references public.hoods(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  text text not null,
  media_urls jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists hood_members_user_id_idx on public.hood_members(user_id);
create index if not exists hood_posts_hood_id_idx on public.hood_posts(hood_id);
create index if not exists hood_posts_created_at_idx on public.hood_posts(created_at desc);

alter table public.hoods enable row level security;
alter table public.hood_members enable row level security;
alter table public.hood_posts enable row level security;

create policy "Public hoods are viewable by everyone"
on public.hoods for select
using (privacy = 'public' or owner_id = auth.uid());

create policy "Authenticated users can create hoods"
on public.hoods for insert
to authenticated
with check (owner_id = auth.uid());

create policy "Owners can update their hoods"
on public.hoods for update
to authenticated
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy "Owners can delete their hoods"
on public.hoods for delete
using (owner_id = auth.uid());

create policy "Members can view public hood memberships"
on public.hood_members for select
using (exists (
  select 1 from public.hoods h
  where h.id = hood_members.hood_id and h.privacy = 'public'
));

create policy "Users can view their own membership"
on public.hood_members for select
using (user_id = auth.uid());

create policy "Users can join public hoods"
on public.hood_members for insert
to authenticated
with check (
  user_id = auth.uid()
  and exists (select 1 from public.hoods h where h.id = hood_members.hood_id and h.privacy = 'public')
);

create policy "Users can leave hoods"
on public.hood_members for delete
to authenticated
using (user_id = auth.uid());

create policy "Members can view hood posts"
on public.hood_posts for select
using (exists (
  select 1 from public.hoods h
  where h.id = hood_posts.hood_id
  and (h.privacy = 'public' or exists (
    select 1 from public.hood_members hm where hm.hood_id = h.id and hm.user_id = auth.uid()
  ))
));

create policy "Members can create hood posts"
on public.hood_posts for insert
to authenticated
with check (
  user_id = auth.uid()
  and exists (select 1 from public.hood_members hm where hm.hood_id = hood_posts.hood_id and hm.user_id = auth.uid())
);

-- Owner membership is created atomically by the AFTER INSERT trigger above.
-- No production database changes are performed by this development task.
