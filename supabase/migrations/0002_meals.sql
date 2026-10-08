-- 0002_meals: configurable meal types and daily meal entries.
-- Rules: PRODUCT_RULES.md §1.

-- Composite keys let child tables prove a member/type belongs to the same mess.
alter table public.mess_members add constraint mess_members_id_mess_key unique (id, mess_id);

create table public.meal_types (
  id         uuid primary key default gen_random_uuid(),
  mess_id    uuid not null references public.messes(id) on delete cascade,
  name       text not null check (char_length(btrim(name)) between 1 and 30),
  sort_order smallint not null default 0,
  weight     numeric(4,2) not null default 1 check (weight between 0 and 5),
  enabled    boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, mess_id)
);
create index meal_types_mess_idx on public.meal_types(mess_id, sort_order);

create table public.meal_entries (
  id           uuid primary key default gen_random_uuid(),
  mess_id      uuid not null references public.messes(id) on delete cascade,
  member_id    uuid not null,
  meal_type_id uuid not null,
  date         date not null,
  count        numeric(3,1) not null default 1
               check (count between 0 and 5 and count * 2 = trunc(count * 2)),
  guest_count  smallint not null default 0 check (guest_count between 0 and 20),
  is_off       boolean not null default false,
  source       text not null default 'app' check (source in ('app', 'ai', 'system')),
  updated_by   uuid default auth.uid(),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now(),
  unique (member_id, date, meal_type_id),
  foreign key (member_id, mess_id) references public.mess_members(id, mess_id),
  foreign key (meal_type_id, mess_id) references public.meal_types(id, mess_id)
);
create index meal_entries_mess_date_idx on public.meal_entries(mess_id, date);

create trigger meal_types_updated_at before update on public.meal_types
  for each row execute function public.set_updated_at();
create trigger meal_entries_updated_at before update on public.meal_entries
  for each row execute function public.set_updated_at();
create trigger meal_types_audit after insert or update or delete on public.meal_types
  for each row execute function public.audit_row();
create trigger meal_entries_audit after insert or update or delete on public.meal_entries
  for each row execute function public.audit_row();

-- "Off" means the member's own meal is 0; guests still count.
create or replace function public.normalize_meal_entry() returns trigger
language plpgsql as $$
begin
  if new.is_off then
    new.count := 0;
  end if;
  new.updated_by := auth.uid();
  return new;
end $$;
create trigger meal_entries_normalize before insert or update on public.meal_entries
  for each row execute function public.normalize_meal_entry();

-- New messes start with sensible Bangla meal types (editable in settings).
create or replace function public.seed_mess_defaults() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into meal_types (mess_id, name, sort_order, weight, enabled) values
    (new.id, 'সকাল', 0, 0.5, false),
    (new.id, 'দুপুর', 1, 1, true),
    (new.id, 'রাত', 2, 1, true);
  return null;
end $$;
create trigger messes_seed_defaults after insert on public.messes
  for each row execute function public.seed_mess_defaults();

-- Billable meals per member for [p_from, p_to): (count + guests) × weight.
-- security invoker: RLS on meal_entries applies to the caller.
create or replace function public.member_meal_totals(p_mess uuid, p_from date, p_to date)
returns table (member_id uuid, meals numeric, guest_meals numeric)
language sql stable set search_path = public as $$
  select e.member_id,
         sum((e.count + e.guest_count) * t.weight) as meals,
         sum(e.guest_count * t.weight)             as guest_meals
  from meal_entries e
  join meal_types t on t.id = e.meal_type_id
  where e.mess_id = p_mess and e.date >= p_from and e.date < p_to
  group by e.member_id;
$$;

-- "Fill today": create missing entries for active members from yesterday (else 1). Manager only.
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
                   where y.member_id = m.id and y.meal_type_id = t.id and y.date = p_date - 1), 1),
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

alter table public.meal_types   enable row level security;
alter table public.meal_entries enable row level security;

create policy meal_types_read on public.meal_types for select using (is_mess_member(mess_id));
create policy meal_types_write on public.meal_types for all
  using (has_mess_role(mess_id, 'manager')) with check (has_mess_role(mess_id, 'manager'));

create policy meal_entries_read on public.meal_entries for select using (is_mess_member(mess_id));
create policy meal_entries_write on public.meal_entries for all
  using (has_mess_role(mess_id, 'manager')) with check (has_mess_role(mess_id, 'manager'));
