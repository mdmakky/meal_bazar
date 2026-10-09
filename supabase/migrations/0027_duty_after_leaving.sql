-- 0027_duty_after_leaving: a member who leaves drops off the bazar roster.
-- Their duties after left_on are removed (past ones stay as history).

create or replace function public.drop_duties_on_leave() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  delete from bazar_duties where member_id = new.id and date > new.left_on;
  return null;
end $$;
create trigger mess_members_drop_duties after update of status on public.mess_members
  for each row when (new.status = 'left' and old.status is distinct from 'left')
  execute function public.drop_duties_on_leave();

-- Members who already left.
delete from public.bazar_duties d using public.mess_members m
where m.id = d.member_id and m.status = 'left' and d.date > m.left_on;
