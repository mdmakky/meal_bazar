-- 0009_storage_and_deposits: private `receipts` bucket + member-recorded deposits.
-- Rules: PRODUCT_RULES.md §2 (pending deposits don't count until verified), §6.
-- Storage: DATABASE.md "Storage". Re-runnable (the SQL test replays it with a storage stub).

-- Mess id from an object path `{mess_id}/{uuid}.jpg`; null when the first segment
-- is not a uuid (so a stray object never breaks a policy with a cast error).
create or replace function public.receipt_mess(p_name text) returns uuid
language sql immutable as $$
  select case when split_part(p_name, '/', 1) ~ '^[0-9a-fA-F]{8}-([0-9a-fA-F]{4}-){3}[0-9a-fA-F]{12}$'
              then split_part(p_name, '/', 1)::uuid end;
$$;

-- Plain local Postgres has no `storage` schema; Supabase does.
do $$
begin
  if exists (select 1 from pg_namespace where nspname = 'storage') then
    insert into storage.buckets (id, name, public) values ('receipts', 'receipts', false)
    on conflict (id) do nothing;

    drop policy if exists receipts_read on storage.objects;
    drop policy if exists receipts_insert on storage.objects;
    drop policy if exists receipts_update on storage.objects;
    drop policy if exists receipts_delete on storage.objects;

    create policy receipts_read on storage.objects for select
      using (bucket_id = 'receipts' and public.is_mess_member(public.receipt_mess(name)));
    -- Members upload too (deposit screenshots); managers attach bazar/expense receipts.
    create policy receipts_insert on storage.objects for insert
      with check (bucket_id = 'receipts' and public.is_mess_member(public.receipt_mess(name)));
    create policy receipts_update on storage.objects for update
      using (bucket_id = 'receipts' and public.has_mess_role(public.receipt_mess(name), 'manager'))
      with check (bucket_id = 'receipts' and public.has_mess_role(public.receipt_mess(name), 'manager'));
    create policy receipts_delete on storage.objects for delete
      using (bucket_id = 'receipts' and public.has_mess_role(public.receipt_mess(name), 'manager'));
  end if;
end $$;

-- A member records their own deposit; it stays 'pending' until a manager verifies it.
-- Security definer because deposits RLS is manager-only for writes. Idempotent on p_id
-- (offline retry). The closed-month guard and audit triggers still run.
create or replace function public.record_my_deposit(
  p_mess uuid, p_id uuid, p_date date, p_amount numeric, p_method public.pay_method,
  p_trx_id text, p_note text, p_screenshot_path text
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := require_user();
  v_member uuid;
begin
  -- Inactive only hides a member from the meal grid; they still pay (PRODUCT_RULES §2).
  select id into v_member from mess_members
  where mess_id = p_mess and user_id = v_uid and status in ('active', 'inactive');
  if v_member is null then
    perform fail('NOT_MEMBER');
  end if;
  if p_screenshot_path is not null and receipt_mess(p_screenshot_path) is distinct from p_mess then
    perform fail('RECEIPT_PATH_INVALID');
  end if;

  insert into deposits (id, mess_id, member_id, date, amount, method, trx_id, status, note,
                        screenshot_path, source)
  values (p_id, p_mess, v_member, p_date, p_amount, p_method, nullif(btrim(p_trx_id), ''),
          'pending', nullif(btrim(p_note), ''), p_screenshot_path, 'app')
  on conflict (id) do nothing;

  if not exists (select 1 from deposits where id = p_id and member_id = v_member) then
    perform fail('NOT_MEMBER');            -- id taken by someone else's row
  end if;
  return p_id;
end $$;

-- Manager approves (→ verified, counts as credit) or rejects a pending deposit.
-- The status change is audited by the deposits audit trigger.
create or replace function public.verify_deposit(p_id uuid, p_approve boolean) returns void
language plpgsql security definer set search_path = public as $$
declare
  v deposits%rowtype;
begin
  perform require_user();
  select * into v from deposits where id = p_id and deleted_at is null;
  if v.id is null or not has_mess_role(v.mess_id, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  if v.status <> 'pending' then
    perform fail('DEPOSIT_NOT_PENDING');
  end if;
  update deposits
  set status = case when p_approve then 'verified' else 'rejected' end::deposit_status
  where id = p_id;
end $$;
