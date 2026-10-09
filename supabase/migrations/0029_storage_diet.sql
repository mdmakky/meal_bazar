-- 0029_storage_diet: keep the free database small.
-- 1. The daily meal fill (source 'system') is no longer audited: hundreds of
--    default rows a month that nobody reviews (my_activity already hid them).
-- 2. Photos are refused by the server too when the platform flag `receipts`
--    is off, not only hidden in the app.
-- 3. prune_old_data(): messages and audit rows older than 2 months go, run by
--    the daily cron. Month close/reopen audit rows are kept (the money trail).

create or replace function public.audit_row() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  v_old jsonb := case when tg_op <> 'INSERT' then to_jsonb(old) end;
  v_new jsonb := case when tg_op <> 'DELETE' then to_jsonb(new) end;
  v_row jsonb := coalesce(v_new, v_old);
begin
  if tg_op = 'UPDATE' and (v_old - 'updated_at') = (v_new - 'updated_at') then
    return null;
  end if;
  if tg_op = 'INSERT' and tg_table_name = 'meal_entries' and v_new ->> 'source' = 'system' then
    return null;
  end if;
  insert into audit_log (mess_id, actor_id, action, entity, entity_id, old, new, source)
  values (
    coalesce((v_row ->> 'mess_id')::uuid, (v_row ->> 'id')::uuid),
    auth.uid(), lower(tg_op), tg_table_name, (v_row ->> 'id')::uuid, v_old, v_new,
    coalesce(v_row ->> 'source', 'app')
  );
  return null;
end $$;

do $$
begin
  if exists (select 1 from pg_namespace where nspname = 'storage') then
    drop policy if exists receipts_insert on storage.objects;
    create policy receipts_insert on storage.objects for insert
      with check (bucket_id = 'receipts' and public.is_mess_member(public.receipt_mess(name))
                  and coalesce(public.platform_default('features', 'receipts'), 'true') <> 'false'::jsonb);
  end if;
end $$;

create or replace function public.prune_old_data() returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_cut timestamptz := now() - interval '2 months';
  n_msg int;
  n_threads int;
  n_audit int;
begin
  delete from messages where created_at < v_cut;
  get diagnostics n_msg = row_count;
  -- Private threads with nothing left in them; the mess group stays.
  delete from message_threads t
  where t.kind <> 'group' and t.created_at < v_cut
    and not exists (select 1 from messages m where m.thread_id = t.id);
  get diagnostics n_threads = row_count;
  delete from audit_log
  where at < v_cut and action not in ('close_month', 'reopen_month');
  get diagnostics n_audit = row_count;
  delete from notifications where created_at < v_cut;
  delete from push_outbox where created_at < now() - interval '30 days';
  return jsonb_build_object('messages', n_msg, 'threads', n_threads, 'audit', n_audit);
end $$;
revoke execute on function public.prune_old_data() from public, anon, authenticated;
grant execute on function public.prune_old_data() to service_role;
