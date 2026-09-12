-- Allow the message notification trigger to insert its documented notification type.
begin;
alter table public.notifications drop constraint if exists notifications_type_check;
alter table public.notifications add constraint notifications_type_check check (type = any (array['like'::text,'comment'::text,'reply'::text,'follow'::text,'message'::text]));
commit;
