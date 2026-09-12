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
