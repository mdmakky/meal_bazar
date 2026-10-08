-- 0015_recurring_and_templates: monthly bills that repeat, and each member's
-- default meal pattern used by "fill today". Rules: PRODUCT_RULES.md §1–2.

-- ── recurring monthly bills ──────────────────────────────────────────────
create table public.recurring_expenses (
  id             uuid primary key default gen_random_uuid(),
  mess_id        uuid not null references public.messes(id) on delete cascade,
  category_id    uuid not null,
  amount         numeric(12,2) not null check (amount >= 0),
  split          public.split_method not null,
  note           text check (char_length(note) <= 300),
  active         boolean not null default true,
  day_of_period  smallint not null default 1 check (day_of_period between 1 and 28),
  created_by     uuid default auth.uid(),
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now(),
  foreign key (category_id, mess_id) references public.expense_categories(id, mess_id)
);
create index recurring_expenses_mess_idx on public.recurring_expenses(mess_id);

-- One row per (bill, billing period) once its expense was created: makes
-- apply_recurring_expenses idempotent even if that expense is later deleted.
create table public.recurring_applied (
  recurring_id uuid not null references public.recurring_expenses(id) on delete cascade,
  period_start date not null,
  mess_id      uuid not null references public.messes(id) on delete cascade,
  applied_at   timestamptz not null default now(),
  primary key (recurring_id, period_start)
);
create index recurring_applied_mess_idx on public.recurring_applied(mess_id, period_start);

create trigger recurring_expenses_updated_at before update on public.recurring_expenses
  for each row execute function public.set_updated_at();
create trigger recurring_expenses_audit after insert or update or delete on public.recurring_expenses
  for each row execute function public.audit_row();

-- Manager: create this period's expense for every active bill not yet applied,
-- dated period start + day_of_period − 1. Returns how many were created.
-- security invoker: RLS and the closed-month trigger on expenses apply, and a
-- MONTH_CLOSED failure rolls back the recurring_applied marks with it.
create or replace function public.apply_recurring_expenses(p_mess uuid, p_date date) returns int
language plpgsql security invoker set search_path = public as $$
declare
  v_from date;
  n int;
begin
  if not has_mess_role(p_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  select start_date into v_from from month_period(p_mess, p_date);
  with marked as (
    insert into recurring_applied (recurring_id, period_start, mess_id)
    select r.id, v_from, p_mess from recurring_expenses r
    where r.mess_id = p_mess and r.active
    on conflict do nothing
    returning recurring_id
  )
  insert into expenses (mess_id, date, category_id, amount, split, note, source)
  select p_mess, v_from + r.day_of_period - 1, r.category_id, r.amount, r.split, r.note, 'system'
  from marked join recurring_expenses r on r.id = marked.recurring_id;
  get diagnostics n = row_count;
  return n;
end $$;

-- Active bills not yet applied in the period containing p_date (for the
-- "bills still to post" prompt). 0 for non-members (RLS).
create or replace function public.pending_recurring_count(p_mess uuid, p_date date) returns int
language sql stable security invoker set search_path = public as $$
  select count(*)::int from recurring_expenses r
  where r.mess_id = p_mess and r.active
    and not exists (select 1 from recurring_applied a
                    where a.recurring_id = r.id
                      and a.period_start = (select start_date from month_period(p_mess, p_date)));
$$;

-- ── default meal pattern ─────────────────────────────────────────────────
create table public.meal_defaults (
  member_id    uuid not null,
  meal_type_id uuid not null,
  mess_id      uuid not null references public.messes(id) on delete cascade,
  count        numeric(3,1) not null
               check (count between 0 and 5 and count * 2 = trunc(count * 2)),
  primary key (member_id, meal_type_id),
  foreign key (member_id, mess_id) references public.mess_members(id, mess_id) on delete cascade,
  foreign key (meal_type_id, mess_id) references public.meal_types(id, mess_id) on delete cascade
);
create index meal_defaults_mess_idx on public.meal_defaults(mess_id);

-- "Fill today": missing rows take yesterday's count, else the member's
-- default, else 1. Manager only. Same signature as 0002.
create or replace function public.fill_meals_for_day(p_mess uuid, p_date date) returns int
language plpgsql security invoker set search_path = public as $$
declare
  n int;
begin
  if not has_mess_role(p_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  insert into meal_entries (mess_id, member_id, meal_type_id, date, count, source)
  select p_mess, m.id, t.id, p_date,
         coalesce((select y.count from meal_entries y
                   where y.member_id = m.id and y.meal_type_id = t.id and y.date = p_date - 1),
                  (select d.count from meal_defaults d
                   where d.member_id = m.id and d.meal_type_id = t.id),
                  1),
         'system'
  from mess_members m
  cross join meal_types t
  where m.mess_id = p_mess and m.status = 'active'
    and t.mess_id = p_mess and t.enabled
    and m.joined_on <= p_date
  on conflict (member_id, date, meal_type_id) do nothing;
  get diagnostics n = row_count;
  return n;
end $$;

-- ── RLS: members read, managers write ────────────────────────────────────
alter table public.recurring_expenses enable row level security;
alter table public.recurring_applied  enable row level security;
alter table public.meal_defaults      enable row level security;

do $$
declare t text;
begin
  foreach t in array array['recurring_expenses', 'recurring_applied', 'meal_defaults'] loop
    execute format('create policy %1$s_read on public.%1$s for select using (is_mess_member(mess_id))', t);
    execute format('create policy %1$s_write on public.%1$s for all
                    using (has_mess_role(mess_id, ''manager'')) with check (has_mess_role(mess_id, ''manager''))', t);
  end loop;
end $$;
