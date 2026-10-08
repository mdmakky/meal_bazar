-- 0003_money: bazar, expenses, deposits. Rules: PRODUCT_RULES.md §2.

create type public.split_method as enum ('meal', 'equal');
create type public.pay_method as enum ('cash', 'bkash', 'nagad', 'bank', 'other');
create type public.deposit_status as enum ('verified', 'pending', 'rejected');

create table public.bazars (
  id                uuid primary key default gen_random_uuid(),
  mess_id           uuid not null references public.messes(id) on delete cascade,
  date              date not null,
  buyer_member_id   uuid,
  amount            numeric(12,2) not null check (amount >= 0),
  paid_by_member_id uuid,                 -- null = paid from the mess fund
  note              text check (char_length(note) <= 300),
  receipt_path      text,
  source            text not null default 'app' check (source in ('app', 'ai', 'system')),
  created_by        uuid default auth.uid(),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz,
  foreign key (buyer_member_id, mess_id) references public.mess_members(id, mess_id),
  foreign key (paid_by_member_id, mess_id) references public.mess_members(id, mess_id)
);
create index bazars_mess_date_idx on public.bazars(mess_id, date);

create table public.bazar_items (
  id       uuid primary key default gen_random_uuid(),
  bazar_id uuid not null references public.bazars(id) on delete cascade,
  mess_id  uuid not null references public.messes(id) on delete cascade,
  name     text not null check (char_length(btrim(name)) between 1 and 60),
  qty      numeric(10,3) check (qty >= 0),
  unit     text check (char_length(unit) <= 12),
  price    numeric(12,2) not null check (price >= 0),
  sort     smallint not null default 0
);
create index bazar_items_bazar_idx on public.bazar_items(bazar_id);

create table public.expense_categories (
  id            uuid primary key default gen_random_uuid(),
  mess_id       uuid not null references public.messes(id) on delete cascade,
  name          text not null check (char_length(btrim(name)) between 1 and 30),
  default_split public.split_method not null default 'equal',
  sort_order    smallint not null default 0,
  archived      boolean not null default false,
  unique (id, mess_id)
);

create table public.expenses (
  id                uuid primary key default gen_random_uuid(),
  mess_id           uuid not null references public.messes(id) on delete cascade,
  date              date not null,
  category_id       uuid not null,
  amount            numeric(12,2) not null check (amount >= 0),
  split             public.split_method not null,
  paid_by_member_id uuid,
  note              text check (char_length(note) <= 300),
  receipt_path      text,
  source            text not null default 'app' check (source in ('app', 'ai', 'system')),
  created_by        uuid default auth.uid(),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now(),
  deleted_at        timestamptz,
  foreign key (category_id, mess_id) references public.expense_categories(id, mess_id),
  foreign key (paid_by_member_id, mess_id) references public.mess_members(id, mess_id)
);
create index expenses_mess_date_idx on public.expenses(mess_id, date);

create table public.deposits (
  id              uuid primary key default gen_random_uuid(),
  mess_id         uuid not null references public.messes(id) on delete cascade,
  member_id       uuid not null,
  date            date not null,
  amount          numeric(12,2) not null check (amount > 0),
  method          public.pay_method not null default 'cash',
  trx_id          text check (char_length(trx_id) <= 40),
  status          public.deposit_status not null default 'verified',
  note            text check (char_length(note) <= 300),
  screenshot_path text,
  source          text not null default 'app' check (source in ('app', 'ai', 'system')),
  created_by      uuid default auth.uid(),
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now(),
  deleted_at      timestamptz,
  foreign key (member_id, mess_id) references public.mess_members(id, mess_id)
);
create index deposits_mess_date_idx on public.deposits(mess_id, date);

-- Item lines must belong to the bazar's mess.
create or replace function public.bazar_item_mess() returns trigger
language plpgsql as $$
begin
  select mess_id into new.mess_id from bazars where id = new.bazar_id;
  return new;
end $$;
create trigger bazar_items_mess before insert or update on public.bazar_items
  for each row execute function public.bazar_item_mess();

do $$
declare t text;
begin
  foreach t in array array['bazars', 'expenses', 'deposits'] loop
    execute format('create trigger %1$s_updated_at before update on public.%1$s
                    for each row execute function public.set_updated_at()', t);
    execute format('create trigger %1$s_audit after insert or update or delete on public.%1$s
                    for each row execute function public.audit_row()', t);
  end loop;
end $$;
create trigger expense_categories_audit after insert or update or delete on public.expense_categories
  for each row execute function public.audit_row();

-- Seed default expense categories alongside meal types.
create or replace function public.seed_expense_categories() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into expense_categories (mess_id, name, default_split, sort_order) values
    (new.id, 'বিদ্যুৎ', 'equal', 0), (new.id, 'গ্যাস', 'equal', 1), (new.id, 'ওয়াইফাই', 'equal', 2),
    (new.id, 'পানি', 'equal', 3), (new.id, 'বাসা ভাড়া', 'equal', 4), (new.id, 'বুয়া', 'equal', 5),
    (new.id, 'পরিষ্কার', 'equal', 6), (new.id, 'মেরামত', 'equal', 7), (new.id, 'অন্যান্য', 'equal', 8);
  return null;
end $$;
create trigger messes_seed_categories after insert on public.messes
  for each row execute function public.seed_expense_categories();

alter table public.bazars             enable row level security;
alter table public.bazar_items        enable row level security;
alter table public.expense_categories enable row level security;
alter table public.expenses           enable row level security;
alter table public.deposits           enable row level security;

do $$
declare t text;
begin
  foreach t in array array['bazars', 'bazar_items', 'expense_categories', 'expenses', 'deposits'] loop
    execute format('create policy %1$s_read on public.%1$s for select using (is_mess_member(mess_id))', t);
    execute format('create policy %1$s_write on public.%1$s for all
                    using (has_mess_role(mess_id, ''manager'')) with check (has_mess_role(mess_id, ''manager''))', t);
  end loop;
end $$;
