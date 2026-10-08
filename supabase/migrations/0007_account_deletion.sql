-- 0007_account_deletion: in-app account deletion (Play Store requirement).
-- Rules: REQUIREMENTS.md §3.1, PRODUCT_RULES.md §5. Mess rows (meals, money, the
-- member row and its display_name) are mess data and stay; personal data goes.

-- Postgres cannot reliably remove a Supabase auth user. The RPC queues the user
-- here; an admin job (service role: auth.admin.deleteUser) hard-deletes them later.
-- Deleting the auth user cascades this row away, so the table holds only pending work.
create table public.deletion_requests (
  user_id      uuid primary key references auth.users(id) on delete cascade,
  requested_at timestamptz not null default now()
);
alter table public.deletion_requests enable row level security;   -- no policies: service role only

create or replace function public.delete_my_account() returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid uuid := require_user();
  m     mess_members%rowtype;
  v_others boolean;
begin
  -- Refuse while the caller is the only manager (with an account) of a mess that
  -- other app users still belong to: they must hand over first.
  if exists (
    select 1 from mess_members me
    where me.user_id = v_uid and me.role = 'manager' and me.status = 'active'
      and exists (select 1 from mess_members o
                  where o.mess_id = me.mess_id and o.id <> me.id and o.user_id is not null
                    and o.status in ('active', 'inactive'))
      and not exists (select 1 from mess_members o
                      where o.mess_id = me.mess_id and o.id <> me.id and o.user_id is not null
                        and o.role = 'manager' and o.status = 'active')
  ) then
    perform fail('LAST_MANAGER');
  end if;

  perform set_config('meal_bazar.trusted', 'on', true);
  for m in select * from mess_members where user_id = v_uid for update loop
    if m.status = 'pending' then
      delete from mess_members where id = m.id;
      continue;
    end if;

    if m.status <> 'left' then
      select exists (select 1 from mess_members o
                     where o.mess_id = m.mess_id and o.id <> m.id and o.user_id is not null
                       and o.status in ('active', 'inactive'))
        into v_others;
      if v_others then
        update mess_members
        set status = 'left', left_on = greatest(current_date, joined_on), user_id = null
        where id = m.id;
      else
        -- Nobody else can use this mess: close it. The row keeps its role/status so
        -- the last-manager guard holds; unlinking alone removes all access.
        update messes set deleted_at = now() where id = m.mess_id and deleted_at is null;
        update mess_members set user_id = null where id = m.id;
      end if;
    else
      update mess_members set user_id = null where id = m.id;
    end if;

    insert into audit_log (mess_id, actor_id, action, entity, entity_id, source)
    values (m.mess_id, v_uid, 'delete_account', 'mess_members', m.id, 'system');
  end loop;
  perform set_config('meal_bazar.trusted', '', true);

  update profiles
  set full_name = 'Former member', phone = null, avatar_path = null, deleted_at = now()
  where id = v_uid;

  insert into deletion_requests (user_id) values (v_uid) on conflict do nothing;
end $$;
