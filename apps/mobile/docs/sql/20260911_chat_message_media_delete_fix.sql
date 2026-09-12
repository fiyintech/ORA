-- ORA chat message deletion: permanently delete the message row.
-- The web client captures media_path before calling this RPC and then removes
-- the owned object from the chat-media bucket.
begin;

create or replace function public.delete_own_message(p_message_id uuid)
returns boolean language plpgsql security definer set search_path=public,pg_temp as $$
declare uid uuid:=auth.uid(); changed boolean;
begin
  if uid is null then raise exception 'You must be logged in.'; end if;
  delete from public.messages where id=p_message_id and sender_id=uid;
  changed:=found;
  return changed;
end; $$;

revoke all on function public.delete_own_message(uuid) from public,anon,authenticated;
grant execute on function public.delete_own_message(uuid) to authenticated;

commit;
