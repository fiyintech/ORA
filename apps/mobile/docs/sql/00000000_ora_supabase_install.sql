-- ORA SUPABASE INSTALL BUNDLE
-- Prepared only. DO NOT run automatically.
-- Dependency order: core -> notifications -> hoods -> storage -> aura.


-- ============================================================
-- 20240909_core_social_system.sql
-- ============================================================

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


-- ============================================================
-- 20240101_notifications_system.sql
-- ============================================================

-- ============================================
-- ORA Phase 5.1: Notification Backend System
-- ============================================
-- This migration creates a production-ready notification system
-- with automatic triggers for likes, comments, replies, and follows.

-- ============================================
-- 1. CREATE NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
    actor_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('like', 'comment', 'reply', 'follow')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- ============================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ============================================

-- Index for fetching user's notifications (most common query)
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_id 
    ON notifications(recipient_id);

-- Index for ordering notifications by time
CREATE INDEX IF NOT EXISTS idx_notifications_created_at 
    ON notifications(created_at DESC);

-- Composite index for unread notifications query
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_unread 
    ON notifications(recipient_id, is_read, created_at DESC);

-- Index for actor_id to prevent duplicate notifications
CREATE INDEX IF NOT EXISTS idx_notifications_actor_id 
    ON notifications(actor_id);

-- ============================================
-- 3. ENABLE ROW LEVEL SECURITY
-- ============================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. CREATE RLS POLICIES
-- ============================================

-- Policy: Users can view their own notifications
CREATE POLICY "Users can view their own notifications"
    ON notifications
    FOR SELECT
    USING (auth.uid() = recipient_id);

-- Policy: Users can update (mark as read) their own notifications
CREATE POLICY "Users can update their own notifications"
    ON notifications
    FOR UPDATE
    USING (auth.uid() = recipient_id)
    WITH CHECK (auth.uid() = recipient_id);

-- Policy: Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications"
    ON notifications
    FOR DELETE
    USING (auth.uid() = recipient_id);

-- Notifications are inserted by SECURITY DEFINER trigger functions below;
-- clients are not granted a direct INSERT policy.
DROP POLICY IF EXISTS "Service role can insert notifications" ON notifications;

-- ============================================
-- 5. HELPER FUNCTION TO PREVENT SELF-NOTIFICATIONS
-- ============================================

CREATE OR REPLACE FUNCTION check_notification_recipient()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Prevent self-notifications
    IF NEW.recipient_id = NEW.actor_id THEN
        RETURN NULL; -- Skip the notification
    END IF;
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_check_notification_recipient ON notifications;
CREATE TRIGGER trigger_check_notification_recipient
    BEFORE INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION check_notification_recipient();

-- ============================================
-- 6. TRIGGER FUNCTION: POST LIKES
-- ============================================

CREATE OR REPLACE FUNCTION create_like_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only create notification if user is liking someone else's post
    IF (SELECT user_id FROM posts WHERE id = NEW.post_id) != NEW.user_id THEN
        INSERT INTO notifications (
            recipient_id,
            actor_id,
            post_id,
            type
        ) VALUES (
            (SELECT user_id FROM posts WHERE id = NEW.post_id),
            NEW.user_id,
            NEW.post_id,
            'like'
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for post likes
DROP TRIGGER IF EXISTS trigger_create_like_notification ON post_likes;
CREATE TRIGGER trigger_create_like_notification
    AFTER INSERT ON post_likes
    FOR EACH ROW
    EXECUTE FUNCTION create_like_notification();

-- ============================================
-- 7. TRIGGER FUNCTION: COMMENTS
-- ============================================

CREATE OR REPLACE FUNCTION create_comment_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only create notification if user is commenting on someone else's post
    IF (SELECT user_id FROM posts WHERE id = NEW.post_id) != NEW.user_id THEN
        INSERT INTO notifications (
            recipient_id,
            actor_id,
            post_id,
            comment_id,
            type
        ) VALUES (
            (SELECT user_id FROM posts WHERE id = NEW.post_id),
            NEW.user_id,
            NEW.post_id,
            NEW.id,
            'comment'
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for comments
DROP TRIGGER IF EXISTS trigger_create_comment_notification ON comments;
CREATE TRIGGER trigger_create_comment_notification
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION create_comment_notification();

-- ============================================
-- 8. TRIGGER FUNCTION: COMMENT REPLIES
-- ============================================
-- Note: This trigger assumes the comments table has a parent_id column
-- for threaded replies. If parent_id doesn't exist, this trigger will
-- gracefully skip reply notifications.

CREATE OR REPLACE FUNCTION create_reply_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    parent_comment_author UUID;
    post_author UUID;
    has_parent_id BOOLEAN;
BEGIN
    -- Check if parent_id column exists in comments table
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'comments' 
        AND column_name = 'parent_id'
    ) INTO has_parent_id;
    
    -- Only proceed if parent_id column exists and is set
    IF has_parent_id AND NEW.parent_id IS NOT NULL THEN
        -- Get the author of the parent comment
        SELECT user_id INTO parent_comment_author 
        FROM comments 
        WHERE id = NEW.parent_id;
        
        -- Notify the parent comment author (if not self)
        IF parent_comment_author IS NOT NULL AND parent_comment_author != NEW.user_id THEN
            INSERT INTO notifications (
                recipient_id,
                actor_id,
                post_id,
                comment_id,
                type
            ) VALUES (
                parent_comment_author,
                NEW.user_id,
                NEW.post_id,
                NEW.id,
                'reply'
            );
        END IF;
        
        -- Also notify the post author if they're not already notified
        SELECT user_id INTO post_author 
        FROM posts 
        WHERE id = NEW.post_id;
        
        -- Only notify post author if they're not the commenter and not the parent commenter
        IF post_author IS NOT NULL 
           AND post_author != NEW.user_id 
           AND post_author != parent_comment_author THEN
            INSERT INTO notifications (
                recipient_id,
                actor_id,
                post_id,
                comment_id,
                type
            ) VALUES (
                post_author,
                NEW.user_id,
                NEW.post_id,
                NEW.id,
                'reply'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for replies (only fires when parent_id is not null)
DROP TRIGGER IF EXISTS trigger_create_reply_notification ON comments;
CREATE TRIGGER trigger_create_reply_notification
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION create_reply_notification();

-- ============================================
-- 9. TRIGGER FUNCTION: FOLLOWS
-- ============================================

CREATE OR REPLACE FUNCTION create_follow_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Create notification for the user being followed
    INSERT INTO notifications (
        recipient_id,
        actor_id,
        type
    ) VALUES (
        NEW.following_id,
        NEW.follower_id,
        'follow'
    );
    
    RETURN NEW;
END;
$$;

-- Create trigger for follows
DROP TRIGGER IF EXISTS trigger_create_follow_notification ON followers;
CREATE TRIGGER trigger_create_follow_notification
    AFTER INSERT ON followers
    FOR EACH ROW
    EXECUTE FUNCTION create_follow_notification();

-- ============================================
-- 10. GRANT PERMISSIONS
-- ============================================

-- Grant authenticated users permission to read/update/delete their notifications
GRANT SELECT, UPDATE, DELETE ON notifications TO authenticated;

-- Trigger functions run as SECURITY DEFINER, so clients do not need
-- direct INSERT privileges on notifications.

-- ============================================
-- 11. COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE notifications IS 'User notifications for likes, comments, replies, and follows';
COMMENT ON COLUMN notifications.recipient_id IS 'User who receives the notification';
COMMENT ON COLUMN notifications.actor_id IS 'User who triggered the notification';
COMMENT ON COLUMN notifications.post_id IS 'Related post (nullable)';
COMMENT ON COLUMN notifications.comment_id IS 'Related comment (nullable)';
COMMENT ON COLUMN notifications.type IS 'Notification type: like, comment, reply, follow';
COMMENT ON COLUMN notifications.is_read IS 'Whether the notification has been read';
COMMENT ON COLUMN notifications.created_at IS 'When the notification was created';

-- ============================================
-- MIGRATION COMPLETE
-- ============================================

-- ============================================================
-- 20240908_hoods_system.sql
-- ============================================================

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


-- ============================================================
-- 20240910_storage_posts.sql
-- ============================================================

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


-- ============================================================
-- 20240911_aura_system.sql
-- ============================================================

-- ORA Aura System
-- Prepared only. Do NOT run automatically.
-- Aura values mirror the existing mobile AuraEngine reward table.

create table if not exists public.aura_history (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(user_id) on delete cascade,
  action text not null,
  points integer not null check (points <> 0),
  description text not null,
  created_at timestamptz not null default now()
);

create index if not exists aura_history_user_created_idx
  on public.aura_history(user_id, created_at desc);

alter table public.aura_history enable row level security;

drop policy if exists "Users can view own aura history" on public.aura_history;
create policy "Users can view own aura history"
on public.aura_history for select to authenticated
using (user_id = auth.uid());

-- Server-authoritative Aura mutation. Clients do not receive direct INSERT/UPDATE/DELETE access.
create or replace function public.apply_aura(
  p_user_id uuid,
  p_action text,
  p_points integer,
  p_description text
)
returns public.aura_history
language plpgsql
security definer
set search_path = public
as $$
declare
  result public.aura_history;
begin
  if p_user_id is null or p_points = 0 then
    raise exception 'Invalid Aura award';
  end if;

  insert into public.aura_history(user_id, action, points, description)
  values (p_user_id, p_action, p_points, p_description)
  returning * into result;

  update public.profiles
  set aura_points = greatest(aura_points + p_points, 0),
      steeze_level = greatest(floor(greatest(aura_points + p_points, 0) / 100)::integer + 1, 1),
      updated_at = now()
  where user_id = p_user_id;

  return result;
end;
$$;

revoke execute on function public.apply_aura(uuid, text, integer, text) from public, authenticated;

-- Prevent authenticated clients from writing Aura history directly.
drop policy if exists "Users can insert aura history" on public.aura_history;
drop policy if exists "Users can update aura history" on public.aura_history;
drop policy if exists "Users can delete aura history" on public.aura_history;

-- Existing AuraEngine values:
-- dailyLogin 2, createPost 5, receiveLike 1, receiveComment 3,
-- receiveShare 2, joinHood 10, createHood 50, followUser 5,
-- completeProfile 25, dailyStreak 10, seasonReward 100,
-- reportResolved 15, inviteFriend 30.

-- Post creation: +5 to author.
create or replace function public.award_aura_for_post()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.apply_aura(new.user_id, 'createPost', 5, 'Created a post');
  return new;
end;
$$;

drop trigger if exists trigger_aura_post_created on public.posts;
create trigger trigger_aura_post_created
after insert on public.posts
for each row execute function public.award_aura_for_post();

-- Post like: +1 to post owner, -1 when removed.
create or replace function public.award_aura_for_post_like()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner_id uuid;
begin
  select user_id into owner_id from public.posts where id = coalesce(new.post_id, old.post_id);
  if owner_id is not null then
    if tg_op = 'INSERT' then
      perform public.apply_aura(owner_id, 'receiveLike', 1, 'Received a like');
    else
      perform public.apply_aura(owner_id, 'receiveLike', -1, 'Like removed');
    end if;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trigger_aura_post_like on public.post_likes;
create trigger trigger_aura_post_like
after insert or delete on public.post_likes
for each row execute function public.award_aura_for_post_like();

-- Comment creation: +3 to post owner. Deleted comments reverse the award.
create or replace function public.award_aura_for_comment()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner_id uuid;
begin
  select user_id into owner_id from public.posts where id = coalesce(new.post_id, old.post_id);
  if owner_id is not null then
    if tg_op = 'INSERT' then
      perform public.apply_aura(owner_id, 'receiveComment', 3, 'Received a comment');
    end if;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trigger_aura_comment_created on public.comments;
create trigger trigger_aura_comment_created
after insert on public.comments
for each row execute function public.award_aura_for_comment();

-- Share: +2 to post owner. The shares table represents explicit shares.
create or replace function public.award_aura_for_share()
returns trigger language plpgsql security definer set search_path = public as $$
declare owner_id uuid;
begin
  select user_id into owner_id from public.posts where id = coalesce(new.post_id, old.post_id);
  if owner_id is not null then
    if tg_op = 'INSERT' then
      perform public.apply_aura(owner_id, 'receiveShare', 2, 'Post was shared');
    else
      perform public.apply_aura(owner_id, 'receiveShare', -2, 'Share removed');
    end if;
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trigger_aura_share on public.shares;
create trigger trigger_aura_share
after insert or delete on public.shares
for each row execute function public.award_aura_for_share();

-- Follow: +5 to the user being followed. Unfollow reverses it.
create or replace function public.award_aura_for_follow()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' then
    perform public.apply_aura(new.following_id, 'followUser', 5, 'Followed by another user');
  else
    perform public.apply_aura(old.following_id, 'followUser', -5, 'Follow removed');
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trigger_aura_follow on public.followers;
create trigger trigger_aura_follow
after insert or delete on public.followers
for each row execute function public.award_aura_for_follow();

-- Trigger functions are internal implementation details and must not be callable by clients.
revoke execute on function public.award_aura_for_post() from public, authenticated;
revoke execute on function public.award_aura_for_post_like() from public, authenticated;
revoke execute on function public.award_aura_for_comment() from public, authenticated;
revoke execute on function public.award_aura_for_share() from public, authenticated;
revoke execute on function public.award_aura_for_follow() from public, authenticated;

-- Hood creation: +50 to the owner.
create or replace function public.award_aura_for_hood_creation()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  perform public.apply_aura(new.owner_id, 'createHood', 50, 'Created a Hood');
  return new;
end;
$$;

drop trigger if exists trigger_aura_hood_created on public.hoods;
create trigger trigger_aura_hood_created
after insert on public.hoods
for each row execute function public.award_aura_for_hood_creation();

-- Joining/leaving a Hood: +10/-10 for the member.
create or replace function public.award_aura_for_hood_membership()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'INSERT' and new.role <> 'owner' then
    perform public.apply_aura(new.user_id, 'joinHood', 10, 'Joined a Hood');
  elsif tg_op = 'DELETE' and old.role <> 'owner' then
    perform public.apply_aura(old.user_id, 'joinHood', -10, 'Left a Hood');
  end if;
  return coalesce(new, old);
end;
$$;

drop trigger if exists trigger_aura_hood_membership on public.hood_members;
create trigger trigger_aura_hood_membership
after insert or delete on public.hood_members
for each row execute function public.award_aura_for_hood_membership();

revoke execute on function public.award_aura_for_hood_creation() from public, authenticated;
revoke execute on function public.award_aura_for_hood_membership() from public, authenticated;

-- Leaderboard helper. Country/city use the existing profile columns.
create or replace function public.get_aura_leaderboard(
  p_scope text default 'global',
  p_scope_value text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table (
  user_id uuid,
  username text,
  display_name text,
  avatar text,
  aura_points integer,
  steeze_level integer,
  rank bigint
)
language sql
security definer
set search_path = public
as $$
  with ranked as (
    select
      p.user_id, p.username, p.display_name, p.avatar,
      p.aura_points, p.steeze_level,
      row_number() over (order by p.aura_points desc, p.created_at asc, p.user_id) as rank
    from public.profiles p
    where p_scope = 'global'
       or (p_scope = 'country' and p.country = p_scope_value)
       or (p_scope = 'city' and p.city = p_scope_value)
  )
  select * from ranked
  order by rank
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

grant execute on function public.get_aura_leaderboard(text, text, integer, integer) to authenticated;


-- Notification triggers (20240912)
-- ORA notifications triggers: post likes, comments/replies, follows.
-- These functions run server-side and are not executable by clients.

create or replace function public.notify_on_post_like()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  insert into public.notifications (recipient_id, actor_id, post_id, type)
  select p.user_id, new.user_id, new.post_id, 'like'
  from public.posts p
  where p.id = new.post_id and p.user_id is not null and p.user_id <> new.user_id;
  return new;
end;
$$;

create or replace function public.notify_on_comment()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  insert into public.notifications (recipient_id, actor_id, post_id, comment_id, type)
  select p.user_id, new.user_id, new.post_id, new.id, 'comment'
  from public.posts p
  where p.id = new.post_id and p.user_id is not null and p.user_id <> new.user_id;

  if new.parent_id is not null then
    insert into public.notifications (recipient_id, actor_id, post_id, comment_id, type)
    select parent.user_id, new.user_id, new.post_id, new.id, 'reply'
    from public.comments parent
    where parent.id = new.parent_id
      and parent.user_id is not null
      and parent.user_id <> new.user_id
      and parent.user_id is distinct from (select p.user_id from public.posts p where p.id = new.post_id);
  end if;
  return new;
end;
$$;

create or replace function public.notify_on_follow()
returns trigger language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if new.follower_id is not null and new.following_id is not null and new.follower_id <> new.following_id then
    insert into public.notifications (recipient_id, actor_id, type)
    values (new.following_id, new.follower_id, 'follow');
  end if;
  return new;
end;
$$;

drop trigger if exists notifications_post_like on public.post_likes;
drop trigger if exists notifications_comment on public.comments;
drop trigger if exists notifications_follow on public.followers;

create trigger notifications_post_like after insert on public.post_likes
for each row execute function public.notify_on_post_like();
create trigger notifications_comment after insert on public.comments
for each row execute function public.notify_on_comment();
create trigger notifications_follow after insert on public.followers
for each row execute function public.notify_on_follow();

revoke all on function public.notify_on_post_like() from public, anon, authenticated;
revoke all on function public.notify_on_comment() from public, anon, authenticated;
revoke all on function public.notify_on_follow() from public, anon, authenticated;


-- 20240913 Hood RLS recursion fix
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


-- 20240914 Messaging notifications, Hood requests/admin, and profile media
-- Kept in the consolidated install bundle for fresh ORA environments.
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


-- 20240915 Chat write security hardening
-- ORA chat write security hardening.
begin;
create or replace function public.mark_conversation_messages_read(p_conversation_id uuid)
returns integer language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); changed integer;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  if not public.is_conversation_member(p_conversation_id,uid) then raise exception 'You are not a member of this conversation.'; end if;
  update public.messages set read_at=now() where conversation_id=p_conversation_id and sender_id<>uid and read_at is null;
  get diagnostics changed=row_count;
  return changed;
end; $$;
create or replace function public.delete_own_message(p_message_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); changed boolean;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  update public.messages set deleted_at=coalesce(deleted_at,now()), content='This message was deleted.' where id=p_message_id and sender_id=uid;
  changed:=found;
  return changed;
end; $$;
revoke all on function public.mark_conversation_messages_read(uuid) from public,anon,authenticated;
grant execute on function public.mark_conversation_messages_read(uuid) to authenticated;
revoke all on function public.delete_own_message(uuid) from public,anon,authenticated;
grant execute on function public.delete_own_message(uuid) to authenticated;
drop policy if exists chat_update_messages on public.messages;
drop policy if exists chat_insert_conversation_members on public.conversation_members;
commit;


-- 20240916 Hood owner/admin controls
-- ORA Hood owner/admin controls: owner-only management, mini admins,
-- ownership transfer, privacy switching, deletion, and safe membership mutations.
-- Applied to the connected ORA Supabase project as ora_hood_owner_admin_controls_v1.

begin;

create or replace function public.is_hood_admin(p_hood_id uuid, p_user_id uuid default auth.uid())
returns boolean language sql stable security definer set search_path=public,pg_temp as $$
  select exists (select 1 from public.hood_members hm where hm.hood_id=p_hood_id and hm.user_id=p_user_id and hm.role in ('owner','moderator'));
$$;
create or replace function public.is_hood_owner(p_hood_id uuid, p_user_id uuid default auth.uid())
returns boolean language sql stable security definer set search_path=public,pg_temp as $$
  select exists (select 1 from public.hoods h where h.id=p_hood_id and h.owner_id=p_user_id);
$$;

drop policy if exists hood_members_insert_self on public.hood_members;
drop policy if exists hood_members_delete_self on public.hood_members;

create or replace function public.leave_hood(p_hood_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid();
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  if exists(select 1 from public.hoods where id=p_hood_id and owner_id=uid) then raise exception 'The Hood owner must transfer ownership or delete the Hood.'; end if;
  delete from public.hood_members where hood_id=p_hood_id and user_id=uid;
  return found;
end; $$;

create or replace function public.set_hood_admin(p_hood_id uuid,p_user_id uuid,p_make_admin boolean)
returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); target_role text;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  if not public.is_hood_owner(p_hood_id,uid) then raise exception 'Only the Hood owner can manage admins.'; end if;
  if p_user_id=uid then raise exception 'The Hood owner is always the owner.'; end if;
  if not exists(select 1 from public.hood_members where hood_id=p_hood_id and user_id=p_user_id) then raise exception 'Only Hood members can be made admins.'; end if;
  target_role:=case when p_make_admin then 'moderator' else 'member' end;
  update public.hood_members set role=target_role where hood_id=p_hood_id and user_id=p_user_id;
  return target_role;
end; $$;

create or replace function public.transfer_hood_ownership(p_hood_id uuid,p_new_owner_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); old_owner uuid;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  select owner_id into old_owner from public.hoods where id=p_hood_id for update;
  if old_owner is null then raise exception 'Hood not found.'; end if;
  if old_owner<>uid then raise exception 'Only the Hood owner can transfer ownership.'; end if;
  if p_new_owner_id=uid then raise exception 'You are already the owner.'; end if;
  if not exists(select 1 from public.hood_members where hood_id=p_hood_id and user_id=p_new_owner_id) then raise exception 'Ownership can only be transferred to a Hood member.'; end if;
  update public.hoods set owner_id=p_new_owner_id,updated_at=now() where id=p_hood_id;
  update public.hood_members set role='moderator' where hood_id=p_hood_id and user_id=uid;
  update public.hood_members set role='owner' where hood_id=p_hood_id and user_id=p_new_owner_id;
  return true;
end; $$;

create or replace function public.update_hood_privacy(p_hood_id uuid,p_privacy text)
returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid();
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  if p_privacy not in ('public','private') then raise exception 'Invalid Hood privacy.'; end if;
  if not public.is_hood_owner(p_hood_id,uid) then raise exception 'Only the Hood owner can change privacy.'; end if;
  update public.hoods set privacy=p_privacy,updated_at=now() where id=p_hood_id;
  return p_privacy;
end; $$;

create or replace function public.delete_hood(p_hood_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); deleted boolean;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  if not public.is_hood_owner(p_hood_id,uid) then raise exception 'Only the Hood owner can delete the Hood.'; end if;
  delete from public.hoods where id=p_hood_id and owner_id=uid;
  deleted:=found;
  return deleted;
end; $$;

create or replace function public.review_hood_join_request(p_request_id uuid,p_approve boolean)
returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); req public.hood_join_requests%rowtype;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  select * into req from public.hood_join_requests where id=p_request_id;
  if req.id is null then raise exception 'Join request not found.'; end if;
  if req.status<>'pending' then return req.status; end if;
  if not public.is_hood_admin(req.hood_id,uid) then raise exception 'Only Hood admins can review join requests.'; end if;
  if p_approve then
    insert into public.hood_members(hood_id,user_id,role) values(req.hood_id,req.user_id,'member') on conflict(hood_id,user_id) do nothing;
    update public.hood_join_requests set status='approved',updated_at=now() where id=req.id;
    return 'approved';
  else
    update public.hood_join_requests set status='declined',updated_at=now() where id=req.id;
    return 'declined';
  end if;
end; $$;

create or replace function public.remove_hood_member(p_hood_id uuid,p_user_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); owner_id uuid; target_role text;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  select h.owner_id into owner_id from public.hoods h where h.id=p_hood_id;
  if owner_id is null then raise exception 'Hood not found.'; end if;
  if not public.is_hood_admin(p_hood_id,uid) then raise exception 'Only Hood admins can remove members.'; end if;
  if p_user_id=owner_id then raise exception 'The Hood owner cannot be removed.'; end if;
  select role into target_role from public.hood_members where hood_id=p_hood_id and user_id=p_user_id;
  if target_role='moderator' and uid<>owner_id then raise exception 'Only the Hood owner can remove another admin.'; end if;
  delete from public.hood_members where hood_id=p_hood_id and user_id=p_user_id;
  return found;
end; $$;

drop policy if exists hood_join_requests_select_own_or_owner on public.hood_join_requests;
create policy hood_join_requests_select_own_or_admin on public.hood_join_requests for select to authenticated using (user_id=(select auth.uid()) or public.is_hood_admin(hood_id,(select auth.uid())));

revoke all on function public.is_hood_admin(uuid,uuid) from public,anon,authenticated;
revoke all on function public.is_hood_owner(uuid,uuid) from public,anon,authenticated;
revoke all on function public.leave_hood(uuid) from public,anon,authenticated;
revoke all on function public.set_hood_admin(uuid,uuid,boolean) from public,anon,authenticated;
revoke all on function public.transfer_hood_ownership(uuid,uuid) from public,anon,authenticated;
revoke all on function public.update_hood_privacy(uuid,text) from public,anon,authenticated;
revoke all on function public.delete_hood(uuid) from public,anon,authenticated;
revoke all on function public.review_hood_join_request(uuid,boolean) from public,anon,authenticated;
revoke all on function public.remove_hood_member(uuid,uuid) from public,anon,authenticated;
grant execute on function public.is_hood_admin(uuid,uuid) to authenticated;
grant execute on function public.is_hood_owner(uuid,uuid) to authenticated;
grant execute on function public.leave_hood(uuid) to authenticated;
grant execute on function public.set_hood_admin(uuid,uuid,boolean) to authenticated;
grant execute on function public.transfer_hood_ownership(uuid,uuid) to authenticated;
grant execute on function public.update_hood_privacy(uuid,text) to authenticated;
grant execute on function public.delete_hood(uuid) to authenticated;
grant execute on function public.review_hood_join_request(uuid,boolean) to authenticated;
grant execute on function public.remove_hood_member(uuid,uuid) to authenticated;

drop function if exists public.get_hood_by_id(uuid);
create function public.get_hood_by_id(p_hood_id uuid)
returns table(id uuid,owner_id uuid,name text,description text,category text,banner text,privacy text,created_at timestamptz,updated_at timestamptz,member_count bigint,is_joined boolean,join_status text,member_role text,is_owner boolean,is_admin boolean)
language sql stable security definer set search_path=public,pg_temp as $$
  select h.id,h.owner_id,h.name,h.description,h.category,h.banner,h.privacy,h.created_at,h.updated_at,
    (select count(*) from public.hood_members hm where hm.hood_id=h.id),
    exists(select 1 from public.hood_members hm where hm.hood_id=h.id and hm.user_id=auth.uid()),
    case when exists(select 1 from public.hood_members hm where hm.hood_id=h.id and hm.user_id=auth.uid()) then 'joined'
         when exists(select 1 from public.hood_join_requests r where r.hood_id=h.id and r.user_id=auth.uid() and r.status='pending') then 'pending'
         else 'none' end,
    (select hm.role from public.hood_members hm where hm.hood_id=h.id and hm.user_id=auth.uid()),
    h.owner_id=auth.uid(),
    exists(select 1 from public.hood_members hm where hm.hood_id=h.id and hm.user_id=auth.uid() and hm.role in ('owner','moderator'))
  from public.hoods h where h.id=p_hood_id and auth.uid() is not null;
$$;
revoke all on function public.get_hood_by_id(uuid) from public,anon,authenticated;
grant execute on function public.get_hood_by_id(uuid) to authenticated;

insert into public.hood_members(hood_id,user_id,role)
select h.id,h.owner_id,'owner' from public.hoods h
where not exists(select 1 from public.hood_members hm where hm.hood_id=h.id and hm.user_id=h.owner_id)
on conflict (hood_id,user_id) do nothing;
update public.hood_members hm set role='owner'
from public.hoods h where h.id=hm.hood_id and h.owner_id=hm.user_id and hm.role<>'owner';

commit;
-- ORA web: chat media lifecycle and rejoin protection for removed Hood members.
begin;

alter table public.messages
  add column if not exists media_url text,
  add column if not exists media_path text,
  add column if not exists media_type text,
  add column if not exists media_viewed_at timestamptz,
  add column if not exists media_expires_at timestamptz;
create index if not exists messages_media_expiry_idx on public.messages(media_expires_at) where media_expires_at is not null;

insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values ('chat-media','chat-media',true,52428800,array['image/jpeg','image/png','image/webp','image/gif','video/mp4','video/webm','video/quicktime']::text[])
on conflict(id) do update set public=excluded.public,file_size_limit=excluded.file_size_limit,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists chat_media_public_read on storage.objects;
create policy chat_media_public_read on storage.objects for select to public using (bucket_id='chat-media');
drop policy if exists chat_media_user_insert on storage.objects;
create policy chat_media_user_insert on storage.objects for insert to authenticated with check (bucket_id='chat-media' and (storage.foldername(name))[1]=(select auth.uid())::text);
drop policy if exists chat_media_user_delete on storage.objects;
create policy chat_media_user_delete on storage.objects for delete to authenticated using (bucket_id='chat-media' and (storage.foldername(name))[1]=(select auth.uid())::text);

create or replace function public.send_message(p_conversation_id uuid,p_content text default '',p_media_path text default null,p_media_type text default null)
returns public.messages language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); result public.messages;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  if not public.is_conversation_member(p_conversation_id,uid) then raise exception 'You are not a member of this conversation.'; end if;
  if coalesce(length(trim(p_content)),0)>2000 then raise exception 'Message cannot exceed 2000 characters.'; end if;
  if p_media_type is not null and p_media_type not in ('image','video') then raise exception 'Unsupported media type.'; end if;
  if p_media_path is not null and p_media_path !~ ('^'||uid::text||'/') then raise exception 'Invalid media path.'; end if;
  if coalesce(length(trim(p_content)),0)=0 and p_media_path is null then raise exception 'Message cannot be empty.'; end if;
  insert into public.messages(conversation_id,sender_id,content,media_url,media_path,media_type,media_expires_at)
  values(p_conversation_id,uid,coalesce(trim(p_content),''),case when p_media_path is null then null else 'pending' end,p_media_path,p_media_type,case when p_media_path is null then null else now()+interval '24 hours' end)
  returning * into result;
  update public.conversations set updated_at=now() where id=p_conversation_id;
  return result;
end; $$;
revoke all on function public.send_message(uuid,text,text,text) from public,anon,authenticated;
grant execute on function public.send_message(uuid,text,text,text) to authenticated;

create or replace function public.attach_message_media(p_message_id uuid,p_media_url text)
returns public.messages language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); result public.messages;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  update public.messages set media_url=p_media_url where id=p_message_id and sender_id=uid and media_path is not null returning * into result;
  if result.id is null then raise exception 'Message not found or not yours.'; end if;
  return result;
end; $$;
revoke all on function public.attach_message_media(uuid,text) from public,anon,authenticated;
grant execute on function public.attach_message_media(uuid,text) to authenticated;

create or replace function public.mark_message_media_viewed(p_message_id uuid)
returns public.messages language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); result public.messages;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  update public.messages m set media_viewed_at=coalesce(media_viewed_at,now()),media_expires_at=coalesce(media_expires_at,now())+interval '3 minutes'
  where m.id=p_message_id and m.sender_id<>uid and public.is_conversation_member(m.conversation_id,uid) and m.media_path is not null returning m.* into result;
  if result.id is null then raise exception 'Media is unavailable or you cannot view it.'; end if;
  return result;
end; $$;
revoke all on function public.mark_message_media_viewed(uuid) from public,anon,authenticated;
grant execute on function public.mark_message_media_viewed(uuid) to authenticated;

create table if not exists public.hood_member_restrictions(hood_id uuid not null references public.hoods(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,removed_at timestamptz not null default now(),removed_by uuid references auth.users(id) on delete set null,primary key(hood_id,user_id));
create index if not exists hood_member_restrictions_user_idx on public.hood_member_restrictions(user_id,hood_id);
alter table public.hood_member_restrictions enable row level security;
drop policy if exists hood_member_restrictions_select_own_or_admin on public.hood_member_restrictions;
create policy hood_member_restrictions_select_own_or_admin on public.hood_member_restrictions for select to authenticated using(user_id=(select auth.uid()) or public.is_hood_admin(hood_id,(select auth.uid())));

create table if not exists public.hood_rejoin_requests(id uuid primary key default gen_random_uuid(),hood_id uuid not null references public.hoods(id) on delete cascade,user_id uuid not null references auth.users(id) on delete cascade,status text not null default 'pending' check(status in ('pending','approved','declined')),created_at timestamptz not null default now(),updated_at timestamptz not null default now());
create index if not exists hood_rejoin_requests_hood_status_idx on public.hood_rejoin_requests(hood_id,status,created_at desc);
create unique index if not exists hood_rejoin_requests_one_pending_idx on public.hood_rejoin_requests(hood_id,user_id) where status='pending';
alter table public.hood_rejoin_requests enable row level security;
drop policy if exists hood_rejoin_requests_select_own_or_owner on public.hood_rejoin_requests;
create policy hood_rejoin_requests_select_own_or_owner on public.hood_rejoin_requests for select to authenticated using(user_id=(select auth.uid()) or exists(select 1 from public.hoods h where h.id=hood_rejoin_requests.hood_id and h.owner_id=(select auth.uid())));
drop policy if exists hood_rejoin_requests_delete_own on public.hood_rejoin_requests;
create policy hood_rejoin_requests_delete_own on public.hood_rejoin_requests for delete to authenticated using(user_id=(select auth.uid()) and status='pending');

create or replace function public.request_hood_join(p_hood_id uuid) returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); hood_privacy text;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  select privacy into hood_privacy from public.hoods where id=p_hood_id;
  if hood_privacy is null then raise exception 'Hood not found.'; end if;
  if exists(select 1 from public.hood_members where hood_id=p_hood_id and user_id=uid) then return 'joined'; end if;
  if exists(select 1 from public.hood_member_restrictions where hood_id=p_hood_id and user_id=uid) then return 'removed'; end if;
  if hood_privacy='public' then insert into public.hood_members(hood_id,user_id,role) values(p_hood_id,uid,'member') on conflict(hood_id,user_id) do nothing; return 'joined'; end if;
  if exists(select 1 from public.hood_join_requests where hood_id=p_hood_id and user_id=uid and status='pending') then return 'pending'; end if;
  insert into public.hood_join_requests(hood_id,user_id,status) values(p_hood_id,uid,'pending'); return 'pending';
end; $$;

create or replace function public.remove_hood_member(p_hood_id uuid,p_user_id uuid) returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); owner_id uuid; target_role text; changed boolean;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  select h.owner_id into owner_id from public.hoods h where id=p_hood_id;
  if owner_id is null then raise exception 'Hood not found.'; end if;
  if not public.is_hood_admin(p_hood_id,uid) then raise exception 'Only Hood admins can remove members.'; end if;
  if p_user_id=owner_id then raise exception 'The Hood owner cannot be removed.'; end if;
  select role into target_role from public.hood_members where hood_id=p_hood_id and user_id=p_user_id;
  if target_role='moderator' and uid<>owner_id then raise exception 'Only the Hood owner can remove another admin.'; end if;
  delete from public.hood_members where hood_id=p_hood_id and user_id=p_user_id; changed:=found;
  if changed then insert into public.hood_member_restrictions(hood_id,user_id,removed_by) values(p_hood_id,p_user_id,uid) on conflict(hood_id,user_id) do update set removed_at=now(),removed_by=excluded.removed_by; end if;
  return changed;
end; $$;

create or replace function public.request_hood_rejoin(p_hood_id uuid) returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid();
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  if not exists(select 1 from public.hood_member_restrictions where hood_id=p_hood_id and user_id=uid) then raise exception 'You are not restricted from this Hood.'; end if;
  if exists(select 1 from public.hood_rejoin_requests where hood_id=p_hood_id and user_id=uid and status='pending') then return 'pending'; end if;
  insert into public.hood_rejoin_requests(hood_id,user_id,status) values(p_hood_id,uid,'pending'); return 'pending';
end; $$;

create or replace function public.review_hood_rejoin_request(p_request_id uuid,p_approve boolean) returns text language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); req public.hood_rejoin_requests%rowtype; owner_id uuid;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  select * into req from public.hood_rejoin_requests where id=p_request_id;
  if req.id is null then raise exception 'Rejoin request not found.'; end if;
  if req.status<>'pending' then return req.status; end if;
  select h.owner_id into owner_id from public.hoods h where h.id=req.hood_id;
  if owner_id<>uid then raise exception 'Only the Hood owner can approve rejoin requests.'; end if;
  if p_approve then delete from public.hood_member_restrictions where hood_id=req.hood_id and user_id=req.user_id; insert into public.hood_members(hood_id,user_id,role) values(req.hood_id,req.user_id,'member') on conflict(hood_id,user_id) do nothing; update public.hood_rejoin_requests set status='approved',updated_at=now() where id=req.id; return 'approved'; end if;
  update public.hood_rejoin_requests set status='declined',updated_at=now() where id=req.id; return 'declined';
end; $$;

revoke all on function public.request_hood_join(uuid) from public,anon,authenticated; grant execute on function public.request_hood_join(uuid) to authenticated;
revoke all on function public.remove_hood_member(uuid,uuid) from public,anon,authenticated; grant execute on function public.remove_hood_member(uuid,uuid) to authenticated;
revoke all on function public.request_hood_rejoin(uuid) from public,anon,authenticated; grant execute on function public.request_hood_rejoin(uuid) to authenticated;
revoke all on function public.review_hood_rejoin_request(uuid,boolean) from public,anon,authenticated; grant execute on function public.review_hood_rejoin_request(uuid,boolean) to authenticated;

commit;
-- ORA web: scheduled cleanup of expired chat media.
begin;
create extension if not exists pg_cron;
create extension if not exists pg_net;
select cron.unschedule(jobid) from cron.job where jobname='ora-cleanup-chat-media';
select cron.schedule('ora-cleanup-chat-media','* * * * *',$cmd$select net.http_post(url:='https://mmfwdetkqxrxrdirvsdp.supabase.co/functions/v1/cleanup-chat-media',headers:='{"Content-Type":"application/json"}'::jsonb,body:='{}'::jsonb);$cmd$);
commit;
-- Allow the message notification trigger to insert its documented notification type.
begin;
alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check check (type = any (array['like'::text,'comment'::text,'reply'::text,'follow'::text,'message'::text]));
commit;

-- ORA web: live feed Realtime for posts and reposts.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='posts'
  ) then
    alter publication supabase_realtime add table public.posts;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='post_reposts'
  ) then
    alter publication supabase_realtime add table public.post_reposts;
  end if;
end $$;
