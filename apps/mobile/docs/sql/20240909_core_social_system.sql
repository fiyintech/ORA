-- ORA Core Social Backend
-- IMPORTANT: Prepared for the Supabase phase. Do NOT run automatically.
-- This migration is based on the current web services and the database blueprint.
-- It establishes the core tables/RLS/RPCs required by the web app before
-- notification and Hoods migrations are applied.

create extension if not exists pgcrypto;

-- ============================================================
-- PROFILES
-- ============================================================
create table if not exists public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null unique,
  display_name text not null,
  email text not null default '',
  avatar text,
  banner_url text,
  bio text not null default '',
  school text,
  city text,
  country text,
  website text not null default '',
  location text not null default '',
  interests text[] not null default '{}',
  aura_points integer not null default 0,
  steeze_level integer not null default 1,
  verified boolean not null default false,
  profile_completed integer not null default 0 check (profile_completed between 0 and 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists profiles_aura_points_idx on public.profiles(aura_points desc);

-- ============================================================
-- POSTS
-- ============================================================
create table if not exists public.posts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  content text,
  media_urls jsonb,
  visibility text not null default 'public' check (visibility in ('public', 'friends', 'private')),
  likes_count integer not null default 0,
  comments_count integer not null default 0,
  shares_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists posts_user_id_idx on public.posts(user_id);
create index if not exists posts_created_at_idx on public.posts(created_at desc);

-- ============================================================
-- POST LIKES / REPOSTS / SHARES
-- ============================================================
create table if not exists public.post_likes (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.post_reposts (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create table if not exists public.shares (
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index if not exists post_likes_user_id_idx on public.post_likes(user_id);
create index if not exists post_reposts_user_id_idx on public.post_reposts(user_id);
create index if not exists shares_user_id_idx on public.shares(user_id);

-- ============================================================
-- COMMENTS
-- ============================================================
create table if not exists public.comments (
  id uuid primary key default gen_random_uuid(),
  post_id uuid not null references public.posts(id) on delete cascade,
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  parent_id uuid references public.comments(id) on delete cascade,
  content text not null,
  likes_count integer not null default 0,
  is_deleted boolean not null default false,
  is_edited boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists comments_post_id_idx on public.comments(post_id);
create index if not exists comments_user_id_idx on public.comments(user_id);
create index if not exists comments_parent_id_idx on public.comments(parent_id);

create table if not exists public.comment_likes (
  comment_id uuid not null references public.comments(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (comment_id, user_id)
);

-- ============================================================
-- FOLLOWS
-- ============================================================
create table if not exists public.followers (
  follower_id uuid not null references auth.users(id) on delete cascade,
  following_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (follower_id, following_id),
  check (follower_id <> following_id)
);

create index if not exists followers_following_id_idx on public.followers(following_id);

-- ============================================================
-- MESSAGING
-- ============================================================
create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.conversation_members (
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create index if not exists conversation_members_user_id_idx on public.conversation_members(user_id);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  sender_id uuid not null references auth.users(id) on delete cascade,
  content text not null,
  read_at timestamptz,
  deleted_at timestamptz,
  created_at timestamptz not null default now()
);

create index if not exists messages_conversation_id_idx on public.messages(conversation_id);
create index if not exists messages_created_at_idx on public.messages(created_at desc);

-- Helper used by RLS policies without recursive policy evaluation.
create or replace function public.is_conversation_member(p_conversation_id uuid)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.conversation_members
    where conversation_id = p_conversation_id and user_id = auth.uid()
  );
$$;

grant execute on function public.is_conversation_member(uuid) to authenticated;

-- ============================================================
-- RLS
-- ============================================================
alter table public.profiles enable row level security;
alter table public.posts enable row level security;
alter table public.post_likes enable row level security;
alter table public.post_reposts enable row level security;
alter table public.shares enable row level security;
alter table public.comments enable row level security;
alter table public.comment_likes enable row level security;
alter table public.followers enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;

-- Profiles are public to authenticated users; users control their own writes.
drop policy if exists "Authenticated users can view profiles" on public.profiles;
create policy "Authenticated users can view profiles"
on public.profiles for select to authenticated using (true);

drop policy if exists "Users can create their own profile" on public.profiles;
create policy "Users can create their own profile"
on public.profiles for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "Users can update their own profile" on public.profiles;
create policy "Users can update their own profile"
on public.profiles for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Users can delete their own profile" on public.profiles;
create policy "Users can delete their own profile"
on public.profiles for delete to authenticated using (user_id = auth.uid());

-- Public posts are readable; authors control mutations.
drop policy if exists "Public posts are viewable" on public.posts;
create policy "Public posts are viewable"
on public.posts for select using (visibility = 'public' or user_id = auth.uid());

drop policy if exists "Users can create their own posts" on public.posts;
create policy "Users can create their own posts"
on public.posts for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "Users can update their own posts" on public.posts;
create policy "Users can update their own posts"
on public.posts for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Users can delete their own posts" on public.posts;
create policy "Users can delete their own posts"
on public.posts for delete to authenticated using (user_id = auth.uid());

-- Interaction tables: authenticated users may inspect public interactions and
-- manage only their own rows.
drop policy if exists "Authenticated users can view post likes" on public.post_likes;
create policy "Authenticated users can view post likes"
on public.post_likes for select to authenticated using (true);

drop policy if exists "Users can like posts" on public.post_likes;
create policy "Users can like posts"
on public.post_likes for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "Users can unlike posts" on public.post_likes;
create policy "Users can unlike posts"
on public.post_likes for delete to authenticated using (user_id = auth.uid());

drop policy if exists "Authenticated users can view post reposts" on public.post_reposts;
create policy "Authenticated users can view post reposts"
on public.post_reposts for select to authenticated using (true);

drop policy if exists "Users can repost posts" on public.post_reposts;
create policy "Users can repost posts"
on public.post_reposts for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "Users can remove reposts" on public.post_reposts;
create policy "Users can remove reposts"
on public.post_reposts for delete to authenticated using (user_id = auth.uid());

drop policy if exists "Authenticated users can view shares" on public.shares;
create policy "Authenticated users can view shares"
on public.shares for select to authenticated using (true);

drop policy if exists "Users can create shares" on public.shares;
create policy "Users can create shares"
on public.shares for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "Users can remove shares" on public.shares;
create policy "Users can remove shares"
on public.shares for delete to authenticated using (user_id = auth.uid());

-- Comments are readable on posts visible to the user; users manage their own comments.
drop policy if exists "Comments are viewable" on public.comments;
create policy "Comments are viewable"
on public.comments for select using (exists (select 1 from public.posts p where p.id = comments.post_id and (p.visibility = 'public' or p.user_id = auth.uid())));

drop policy if exists "Users can create comments" on public.comments;
create policy "Users can create comments"
on public.comments for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "Users can update own comments" on public.comments;
create policy "Users can update own comments"
on public.comments for update to authenticated using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "Users can delete own comments" on public.comments;
create policy "Users can delete own comments"
on public.comments for delete to authenticated using (user_id = auth.uid());

drop policy if exists "Authenticated users can view comment likes" on public.comment_likes;
create policy "Authenticated users can view comment likes"
on public.comment_likes for select to authenticated using (true);

drop policy if exists "Users can like comments" on public.comment_likes;
create policy "Users can like comments"
on public.comment_likes for insert to authenticated with check (user_id = auth.uid());

drop policy if exists "Users can unlike comments" on public.comment_likes;
create policy "Users can unlike comments"
on public.comment_likes for delete to authenticated using (user_id = auth.uid());

-- Follows.
drop policy if exists "Authenticated users can view follows" on public.followers;
create policy "Authenticated users can view follows"
on public.followers for select to authenticated using (true);

drop policy if exists "Users can follow others" on public.followers;
create policy "Users can follow others"
on public.followers for insert to authenticated with check (follower_id = auth.uid());

drop policy if exists "Users can unfollow others" on public.followers;
create policy "Users can unfollow others"
on public.followers for delete to authenticated using (follower_id = auth.uid());

-- Conversations are visible only to their members.
drop policy if exists "Members can view conversations" on public.conversations;
create policy "Members can view conversations"
on public.conversations for select to authenticated using (public.is_conversation_member(id));

drop policy if exists "Members can view conversation members" on public.conversation_members;
create policy "Members can view conversation members"
on public.conversation_members for select to authenticated using (public.is_conversation_member(conversation_id));

drop policy if exists "Members can view messages" on public.messages;
create policy "Members can view messages"
on public.messages for select to authenticated using (public.is_conversation_member(conversation_id));

drop policy if exists "Members can send messages" on public.messages;
create policy "Members can send messages"
on public.messages for insert to authenticated with check (sender_id = auth.uid() and public.is_conversation_member(conversation_id));

drop policy if exists "Senders can update messages" on public.messages;
create policy "Senders can update messages"
on public.messages for update to authenticated using (sender_id = auth.uid()) with check (sender_id = auth.uid());

-- ============================================================
-- RPCS USED BY THE CURRENT WEB APP
-- ============================================================
create or replace function public.toggle_post_like(p_post_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare liked boolean;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if exists (select 1 from public.post_likes where post_id = p_post_id and user_id = auth.uid()) then
    delete from public.post_likes where post_id = p_post_id and user_id = auth.uid();
    update public.posts set likes_count = greatest(likes_count - 1, 0) where id = p_post_id;
    liked := false;
  else
    insert into public.post_likes(post_id, user_id) values (p_post_id, auth.uid());
    update public.posts set likes_count = likes_count + 1 where id = p_post_id;
    liked := true;
  end if;
  return liked;
end;
$$;

grant execute on function public.toggle_post_like(uuid) to authenticated;

create or replace function public.toggle_post_repost(p_post_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare reposted boolean;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if exists (select 1 from public.post_reposts where post_id = p_post_id and user_id = auth.uid()) then
    delete from public.post_reposts where post_id = p_post_id and user_id = auth.uid();
    update public.posts set shares_count = greatest(shares_count - 1, 0) where id = p_post_id;
    reposted := false;
  else
    insert into public.post_reposts(post_id, user_id) values (p_post_id, auth.uid());
    update public.posts set shares_count = shares_count + 1 where id = p_post_id;
    reposted := true;
  end if;
  return reposted;
end;
$$;

grant execute on function public.toggle_post_repost(uuid) to authenticated;

create or replace function public.delete_post_repost(p_post_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare deleted boolean := false;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  delete from public.post_reposts where post_id = p_post_id and user_id = auth.uid();
  if found then
    update public.posts set shares_count = greatest(shares_count - 1, 0) where id = p_post_id;
    deleted := true;
  end if;
  return deleted;
end;
$$;

grant execute on function public.delete_post_repost(uuid) to authenticated;

create or replace function public.toggle_comment_like(p_comment_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare liked boolean;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if exists (select 1 from public.comment_likes where comment_id = p_comment_id and user_id = auth.uid()) then
    delete from public.comment_likes where comment_id = p_comment_id and user_id = auth.uid();
    update public.comments set likes_count = greatest(likes_count - 1, 0) where id = p_comment_id;
    liked := false;
  else
    insert into public.comment_likes(comment_id, user_id) values (p_comment_id, auth.uid());
    update public.comments set likes_count = likes_count + 1 where id = p_comment_id;
    liked := true;
  end if;
  return liked;
end;
$$;

grant execute on function public.toggle_comment_like(uuid) to authenticated;

create or replace function public.create_post_comment(p_post_id uuid, p_content text, p_parent_id uuid default null)
returns public.comments
language plpgsql
security definer
set search_path = public
as $$
declare result public.comments;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if not exists (select 1 from public.posts where id = p_post_id and (visibility = 'public' or user_id = auth.uid())) then
    raise exception 'Post is not available';
  end if;
  if p_parent_id is not null and not exists (select 1 from public.comments where id = p_parent_id and post_id = p_post_id) then
    raise exception 'Parent comment is invalid';
  end if;
  insert into public.comments(post_id, user_id, parent_id, content)
  values (p_post_id, auth.uid(), p_parent_id, trim(p_content))
  returning * into result;
  update public.posts set comments_count = comments_count + 1 where id = p_post_id;
  return result;
end;
$$;

grant execute on function public.create_post_comment(uuid, text, uuid) to authenticated;

create or replace function public.delete_post_comment(p_comment_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare post_id_value uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  select post_id into post_id_value from public.comments where id = p_comment_id and user_id = auth.uid() and is_deleted = false;
  if post_id_value is null then return false; end if;
  update public.comments set is_deleted = true, updated_at = now() where id = p_comment_id;
  update public.posts set comments_count = greatest(comments_count - 1, 0) where id = post_id_value;
  return true;
end;
$$;

grant execute on function public.delete_post_comment(uuid) to authenticated;

create or replace function public.create_direct_conversation(other_user_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_id uuid;
  new_id uuid;
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if other_user_id = auth.uid() then raise exception 'Cannot message yourself'; end if;
  if not exists (select 1 from public.profiles where user_id = other_user_id) then raise exception 'User not found'; end if;

  select c.id into existing_id
  from public.conversations c
  where (select count(*) from public.conversation_members cm where cm.conversation_id = c.id) = 2
    and exists (select 1 from public.conversation_members cm where cm.conversation_id = c.id and cm.user_id = auth.uid())
    and exists (select 1 from public.conversation_members cm where cm.conversation_id = c.id and cm.user_id = other_user_id)
  limit 1;

  if existing_id is not null then return existing_id; end if;

  insert into public.conversations default values returning id into new_id;
  insert into public.conversation_members(conversation_id, user_id) values (new_id, auth.uid()), (new_id, other_user_id);
  return new_id;
end;
$$;

grant execute on function public.create_direct_conversation(uuid) to authenticated;

-- Public feed RPC. It returns original public posts plus public repost feed items.
create or replace function public.get_public_feed(feed_limit integer default 20)
returns table (
  post_id uuid,
  user_id uuid,
  content text,
  media_urls jsonb,
  visibility text,
  likes_count integer,
  comments_count integer,
  shares_count integer,
  created_at timestamptz,
  updated_at timestamptz,
  is_repost boolean,
  repost_user_id uuid,
  repost_created_at timestamptz
)
language sql
security definer
set search_path = public
as $$
  select p.id, p.user_id, p.content, p.media_urls, p.visibility,
         p.likes_count, p.comments_count, p.shares_count,
         p.created_at, p.updated_at,
         false, null::uuid, null::timestamptz
  from public.posts p
  where p.visibility = 'public'
  union all
  select p.id, p.user_id, p.content, p.media_urls, p.visibility,
         p.likes_count, p.comments_count, p.shares_count,
         p.created_at, p.updated_at,
         true, r.user_id, r.created_at
  from public.post_reposts r
  join public.posts p on p.id = r.post_id
  where p.visibility = 'public'
  order by created_at desc
  limit greatest(feed_limit, 1);
$$;

grant execute on function public.get_public_feed(integer) to authenticated;

-- ============================================================
-- SAFE NOTES
-- ============================================================
-- 1. No Supabase project/database was modified by preparing this file.
-- 2. Apply this migration before 20240101_notifications_system.sql and
--    20240908_hoods_system.sql because those migrations depend on core tables.
-- 3. Storage bucket policies are intentionally separate; the current web app
--    requires a public 'posts' bucket for its existing getPublicUrl() flow.
-- 4. The older feed_rpc_functions.sql assumes count columns already exist;
--    those columns are included above, so it can be applied later if desired.
