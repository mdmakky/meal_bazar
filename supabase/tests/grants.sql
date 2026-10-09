-- Supabase's default grants on the public schema (applied after migrations).
grant usage on schema public to anon, authenticated;
grant all on all tables in schema public to anon, authenticated;
grant all on all sequences in schema public to anon, authenticated;
grant execute on all functions in schema public to anon, authenticated;
-- Supabase applies its default grants when an object is created, so these
-- migration revokes (0017) win there; re-apply them after the blanket grants.
revoke all on public.platform_secrets from anon, authenticated;
revoke execute on function public.get_platform_secrets() from public, anon, authenticated;
revoke execute on function public.setup_branding_storage() from public, anon, authenticated;
revoke execute on function public.delete_my_account_0007() from public, anon, authenticated;
grant usage on schema public to service_role;
grant execute on function public.get_platform_secrets() to service_role;
-- 0019: the push outbox and its helpers are server-only.
revoke all on public.push_outbox from anon, authenticated;
revoke execute on function public.push_kick(), public.push_mess_users(uuid, public.member_role, uuid),
  public.push_enqueue(uuid[], text, text, text, text, text, text), public.push_claim(int)
  from public, anon, authenticated;
-- 0023: hidden message texts and the tagged enqueue are server-only.
revoke all on public.message_hidden_bodies from anon, authenticated;
revoke execute on function public.push_enqueue(uuid[], text, text, text, text, text, text, text)
  from public, anon, authenticated;
-- 0024: the meal-off group notice is posted by set_my_meal_off only.
revoke execute on function public.post_meal_off_notice(uuid, uuid, date, uuid, boolean)
  from public, anon, authenticated;
-- 0028: the duty reminder is run by the cron (service role) only.
revoke execute on function public.send_duty_reminders() from public, anon, authenticated;
-- 0029: pruning is run by the cron (service role) only.
revoke execute on function public.prune_old_data() from public, anon, authenticated;
-- 0030: automatic due reminders run from the cron (service role) only.
revoke execute on function public.send_auto_due_reminders() from public, anon, authenticated;
-- 0031: the automatic meal fill runs from the cron (service role) only.
revoke execute on function public.auto_fill_meals(int, date) from public, anon, authenticated;
