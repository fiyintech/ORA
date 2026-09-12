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
