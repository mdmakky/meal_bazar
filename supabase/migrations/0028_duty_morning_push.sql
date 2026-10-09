-- 0028_duty_morning_push: the member on bazar duty today is told in the
-- morning. Called by the daily cron (ai-gateway/api/cron/daily.ts, 09:00
-- Dhaka). Once per member per day, however often it runs.

create or replace function public.send_duty_reminders() returns int
language plpgsql security definer set search_path = public as $$
declare
  v_today date := (now() at time zone 'Asia/Dhaka')::date;
  r       record;
  n       int := 0;
begin
  if coalesce(platform_default('features', 'duty'), 'true') = 'false'::jsonb then
    return 0;
  end if;
  for r in
    select distinct m.user_id, ms.name as mess
    from bazar_duties d
    join mess_members m on m.id = d.member_id
    join messes ms on ms.id = d.mess_id
    where d.date = v_today and not d.done and m.status = 'active' and m.user_id is not null
      and ms.suspended_at is null
      and not exists (select 1 from notifications x
                      where x.user_id = m.user_id and x.type = 'duty_today'
                        and x.created_at >= v_today::timestamp at time zone 'Asia/Dhaka')
  loop
    perform push_enqueue(array[r.user_id], 'duty_today',
      'আজ আপনার বাজারের পালা', format('%s: বাজার করে অ্যাপে হিসাব জমা দিন', r.mess),
      'Your bazar duty today', format('%s: do the bazar, then submit it in the app', r.mess),
      '/today');
    n := n + 1;
  end loop;
  return n;
end $$;
revoke execute on function public.send_duty_reminders() from public, anon, authenticated;
grant execute on function public.send_duty_reminders() to service_role;
