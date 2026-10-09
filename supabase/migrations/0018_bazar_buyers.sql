-- 0018_bazar_buyers: several members can go to the bazar together.
-- Buyers are informational only: they change no money math. The credit for an
-- own-pocket bazar still goes to the single bazars.paid_by_member_id.
-- bazars.buyer_member_id is kept as the first buyer for older clients.

create table public.bazar_buyers (
  bazar_id  uuid not null references public.bazars(id) on delete cascade,
  mess_id   uuid not null references public.messes(id) on delete cascade,
  member_id uuid not null,
  primary key (bazar_id, member_id),
  foreign key (member_id, mess_id) references public.mess_members(id, mess_id)
);
create index bazar_buyers_mess_idx on public.bazar_buyers(mess_id);

-- Buyer rows always belong to the bazar's mess.
create or replace function public.bazar_buyer_mess() returns trigger
language plpgsql as $$
begin
  select mess_id into new.mess_id from bazars where id = new.bazar_id;
  return new;
end $$;
create trigger bazar_buyers_mess before insert or update on public.bazar_buyers
  for each row execute function public.bazar_buyer_mess();

-- Closed-month guard via the parent bazar's date.
create or replace function public.guard_closed_month_buyer() returns trigger
language plpgsql as $$
begin
  if exists (select 1 from bazars b
             where b.id in (old.bazar_id, new.bazar_id) and month_is_closed(b.mess_id, b.date)) then
    perform fail('MONTH_CLOSED');
  end if;
  return coalesce(new, old);
end $$;
create trigger bazar_buyers_closed_month before insert or update or delete on public.bazar_buyers
  for each row execute function public.guard_closed_month_buyer();

-- Named *_suspension so it fires after bazar_buyers_mess fills mess_id.
create trigger bazar_buyers_suspension before insert or update or delete on public.bazar_buyers
  for each row execute function public.guard_suspension();
create trigger bazar_buyers_audit after insert or update or delete on public.bazar_buyers
  for each row execute function public.audit_row();

alter table public.bazar_buyers enable row level security;
create policy bazar_buyers_read on public.bazar_buyers for select using (is_mess_member(mess_id));
create policy bazar_buyers_write on public.bazar_buyers for all
  using (has_mess_role(mess_id, 'manager')) with check (has_mess_role(mess_id, 'manager'));

-- Backfill: the one buyer each existing bazar already has. Closed months and
-- suspended messes must still be backfilled, and this is not a user action,
-- so the guard, suspension and audit triggers are off for this one insert.
alter table public.bazar_buyers disable trigger bazar_buyers_closed_month;
alter table public.bazar_buyers disable trigger bazar_buyers_suspension;
alter table public.bazar_buyers disable trigger bazar_buyers_audit;
insert into public.bazar_buyers (bazar_id, member_id)
select id, buyer_member_id from public.bazars b where buyer_member_id is not null
  and not exists (select 1 from public.bazar_buyers x where x.bazar_id = b.id);
alter table public.bazar_buyers enable trigger bazar_buyers_closed_month;
alter table public.bazar_buyers enable trigger bazar_buyers_suspension;
alter table public.bazar_buyers enable trigger bazar_buyers_audit;

-- Replaces a bazar's buyers in one go and keeps bazars.buyer_member_id = the
-- first one (null for []). Security invoker: RLS decides who may write.
create or replace function public.set_bazar_buyers(p_bazar uuid, p_members uuid[]) returns void
language plpgsql set search_path = public as $$
declare
  v_mess  uuid;
  v_first uuid := p_members[1];
begin
  select mess_id into v_mess from bazars where id = p_bazar;
  if v_mess is null then
    perform fail('NOT_FOUND');
  end if;
  if not has_mess_role(v_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  if exists (select 1 from unnest(coalesce(p_members, '{}')) u(id)
             where not exists (select 1 from mess_members m
                               where m.id = u.id and m.mess_id = v_mess and m.status <> 'pending')) then
    perform fail('NOT_MEMBER');
  end if;
  delete from bazar_buyers where bazar_id = p_bazar;
  insert into bazar_buyers (bazar_id, member_id)
  select distinct p_bazar, u.id from unnest(coalesce(p_members, '{}')) u(id);
  update bazars set buyer_member_id = v_first
  where id = p_bazar and buyer_member_id is distinct from v_first;
end $$;
