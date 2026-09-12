-- ORA web: scheduled cleanup of expired chat media.
begin;
create extension if not exists pg_cron;
create extension if not exists pg_net;
select cron.unschedule(jobid) from cron.job where jobname='ora-cleanup-chat-media';
select cron.schedule('ora-cleanup-chat-media','* * * * *',$cmd$select net.http_post(url:='https://mmfwdetkqxrxrdirvsdp.supabase.co/functions/v1/cleanup-chat-media',headers:='{"Content-Type":"application/json"}'::jsonb,body:='{}'::jsonb);$cmd$);
commit;
