-- A pending requester may read the mess they asked to join, so the app can show
-- "waiting for approval at <mess name>". They still see no members, meals or money.
create policy messes_read_pending on public.messes for select
  using (exists (
    select 1 from public.mess_members m
    where m.mess_id = messes.id and m.user_id = auth.uid() and m.status = 'pending'
  ));
