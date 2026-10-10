-- 0040_shopping_lists: "বাজারের তালিকা" (the bazar list). Plan a bazar before
-- going: items and quantities, tick them off while shopping and write each
-- price, hand the list to a member to shop, and submit it as a bazar. A
-- member's list is approved by a manager exactly like a member's bazar request
-- (0026); a manager's own list becomes the bazar at once.
-- No money math reads these tables; the bazar (and its items) is only created
-- through review_bazar_request.

create table public.shopping_lists (
  id            uuid primary key,                       -- client generated
  mess_id       uuid not null references public.messes(id) on delete cascade,
  created_by    uuid not null,                          -- member who made the list
  assignee_id   uuid,                                   -- member who goes; null = created_by
  date          date not null,                          -- the planned day
  title         text check (char_length(title) <= 60),
  note          text check (char_length(note) <= 300),
  status        text not null default 'open' check (status in ('open', 'submitted', 'done', 'cancelled')),
  request_id    uuid references public.bazar_requests(id) on delete set null,
  reject_reason text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now(),
  foreign key (created_by, mess_id) references public.mess_members(id, mess_id),
  foreign key (assignee_id, mess_id) references public.mess_members(id, mess_id)
);
create index shopping_lists_mess_idx on public.shopping_lists(mess_id, status, date);

create table public.shopping_items (
  id         uuid primary key,                          -- client generated
  list_id    uuid not null references public.shopping_lists(id) on delete cascade,
  name       text not null check (char_length(btrim(name)) between 1 and 60),
  qty        numeric(8,2) check (qty > 0),
  unit       text check (char_length(unit) <= 12),
  bought     boolean not null default false,
  price      numeric(12,2) check (price >= 0),
  extra      boolean not null default false,            -- added by the shopper on the spot
  sort       int not null default 0,
  created_at timestamptz not null default now()
);
create index shopping_items_list_idx on public.shopping_items(list_id, sort);

create trigger shopping_lists_updated_at before update on public.shopping_lists
  for each row execute function public.set_updated_at();
create trigger shopping_lists_suspension before insert or update or delete on public.shopping_lists
  for each row execute function public.guard_suspension();

-- 'manager' | 'owner' (made it) | 'shopper' (assigned) | null (no access).
create or replace function public.shopping_access(p_list uuid) returns text
language sql stable security definer set search_path = public as $$
  select case
    when has_mess_role(l.mess_id, 'manager') then 'manager'
    when exists (select 1 from mess_members m where m.id = l.created_by and m.user_id = auth.uid()) then 'owner'
    when exists (select 1 from mess_members m where m.id = l.assignee_id and m.user_id = auth.uid()) then 'shopper'
  end
  from shopping_lists l where l.id = p_list;
$$;

alter table public.shopping_lists enable row level security;
alter table public.shopping_items enable row level security;
create policy shopping_lists_read on public.shopping_lists for select using (shopping_access(id) is not null);
create policy shopping_items_read on public.shopping_items for select using (shopping_access(list_id) is not null);
-- While the list is open, whoever may work on it may add and tick items;
-- the planner (owner / manager) may remove any, the shopper only their own extras.
create policy shopping_items_insert on public.shopping_items for insert with check (
  shopping_access(list_id) is not null
  and exists (select 1 from shopping_lists l where l.id = list_id and l.status = 'open'));
create policy shopping_items_update on public.shopping_items for update using (
  shopping_access(list_id) is not null
  and exists (select 1 from shopping_lists l where l.id = list_id and l.status = 'open'));
create policy shopping_items_delete on public.shopping_items for delete using (
  exists (select 1 from shopping_lists l where l.id = list_id and l.status = 'open')
  and (shopping_access(list_id) in ('manager', 'owner') or (extra and shopping_access(list_id) = 'shopper')));

-- Create or edit a list's details (idempotent on id). Only a manager may hand a
-- list to someone else; a member's list is their own.
create or replace function public.save_shopping_list(
  p_id uuid, p_mess uuid, p_date date, p_title text, p_note text, p_assignee uuid
) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid   uuid := require_user();
  v_me    uuid;
  v_mgr   boolean;
  v_old   shopping_lists%rowtype;
  v_for   uuid := p_assignee;
  v_user  uuid;
  v_mess  text;
begin
  select id into v_me from mess_members where mess_id = p_mess and user_id = v_uid and status = 'active';
  if v_me is null then
    perform fail('NOT_MEMBER');
  end if;
  v_mgr := has_mess_role(p_mess, 'manager');
  select * into v_old from shopping_lists where id = p_id;
  if v_old.id is not null and (v_old.mess_id <> p_mess or v_old.status <> 'open'
                               or shopping_access(p_id) not in ('manager', 'owner')) then
    perform fail('NOT_MANAGER');
  end if;
  if v_for is not null and v_for <> v_me then
    if not v_mgr then
      perform fail('NOT_MANAGER');
    end if;
    if not exists (select 1 from mess_members where id = v_for and mess_id = p_mess and status = 'active') then
      perform fail('NOT_MEMBER');
    end if;
  end if;
  -- "Me" is no assignee when I made the list; a manager taking over someone
  -- else's list is named.
  if v_for = v_me and v_me = coalesce(v_old.created_by, v_me) then
    v_for := null;
  end if;

  insert into shopping_lists (id, mess_id, created_by, assignee_id, date, title, note)
  values (p_id, p_mess, v_me, v_for, p_date, nullif(btrim(p_title), ''), nullif(btrim(p_note), ''))
  on conflict (id) do update
    set assignee_id = excluded.assignee_id, date = excluded.date,
        title = excluded.title, note = excluded.note;

  if v_for is not null and v_for is distinct from v_old.assignee_id then
    select user_id into v_user from mess_members where id = v_for;
    select name into v_mess from messes where id = p_mess;
    perform push_enqueue(array[v_user], 'shopping_assigned',
      'বাজারের তালিকা', format('%s: আপনাকে বাজারে যেতে বলা হয়েছে', v_mess),
      'Bazar list for you', format('%s: you were asked to do the bazar', v_mess),
      '/bazar/list/' || p_id::text);
  end if;
  -- A manager who sends the list to someone else (or takes it back) tells
  -- the person it was taken from.
  if v_old.assignee_id is not null and v_old.assignee_id is distinct from v_for then
    select user_id into v_user from mess_members where id = v_old.assignee_id;
    if v_user is not null and v_user is distinct from v_uid then
      select name into v_mess from messes where id = p_mess;
      perform push_enqueue(array[v_user], 'shopping_assigned',
        'বাজারের তালিকা সরানো হয়েছে', format('%s: বাজারের তালিকাটি আপনার কাছ থেকে সরানো হয়েছে', v_mess),
        'Bazar list taken back', format('%s: the bazar list was taken back from you', v_mess),
        '/bazar');
    end if;
  end if;
  return p_id;
end $$;

-- The shopper (or the owner of an unassigned list, or a manager) hands the
-- ticked items in as a bazar. A manager's submission is approved at once.
create or replace function public.submit_shopping_list(p_list uuid, p_own_pocket boolean default true)
returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := require_user();
  l        shopping_lists%rowtype;
  v_access text;
  v_total  numeric;
  v_items  jsonb;
  v_date   date;
  v_req    uuid := gen_random_uuid();   -- a fresh request each time: a rejected one stays as it was
begin
  select * into l from shopping_lists where id = p_list for update;
  v_access := shopping_access(p_list);
  if l.id is null or v_access is null then
    perform fail('NOT_MEMBER');
  end if;
  -- An assigned list is submitted by whoever shops (or a manager); an own list by its owner.
  if l.status <> 'open' or (v_access = 'owner' and l.assignee_id is not null) then
    perform fail('BAZAR_REQUEST_NOT_PENDING');
  end if;
  select coalesce(sum(price), 0),
         coalesce(jsonb_agg(jsonb_strip_nulls(jsonb_build_object('name', name, 'qty', qty, 'unit', unit, 'price', price))
                            order by sort, created_at), '[]')
    into v_total, v_items
  from shopping_items where list_id = p_list and bought and price is not null;
  if v_total <= 0 then
    perform fail('ITEMS_INVALID');
  end if;
  v_date := least(l.date, (now() at time zone 'Asia/Dhaka')::date);
  perform submit_bazar_request(l.mess_id, v_req, v_date, v_total, p_own_pocket, null, v_items, l.note, null);
  update shopping_lists set status = 'submitted', request_id = v_req, reject_reason = null where id = p_list;
  if has_mess_role(l.mess_id, 'manager') then
    perform review_bazar_request(v_req, true);   -- a manager's own bazar needs no second pair of eyes
  end if;
  return v_req;
end $$;

-- Withdraw an open list (the planner only).
create or replace function public.cancel_shopping_list(p_list uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  perform require_user();
  if shopping_access(p_list) not in ('manager', 'owner') then
    perform fail('NOT_MANAGER');
  end if;
  update shopping_lists set status = 'cancelled' where id = p_list and status = 'open';
end $$;

-- The review of its request decides the list: approved → done, rejected → back
-- to open with the reason, so the shopper can fix and resubmit.
create or replace function public.shopping_on_request() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.status is distinct from old.status then
    update shopping_lists
       set status = case new.status when 'approved' then 'done' else 'open' end,
           reject_reason = case new.status when 'rejected' then new.reject_reason end
     where request_id = new.id and status = 'submitted';
  end if;
  return null;
end $$;
create trigger bazar_requests_shopping after update of status on public.bazar_requests
  for each row execute function public.shopping_on_request();

grant execute on function public.save_shopping_list(uuid, uuid, date, text, text, uuid),
                          public.submit_shopping_list(uuid, boolean),
                          public.cancel_shopping_list(uuid) to authenticated;
