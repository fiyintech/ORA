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
