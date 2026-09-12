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
