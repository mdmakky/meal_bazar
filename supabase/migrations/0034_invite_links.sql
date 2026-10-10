-- 0034_invite_links: a manager invites one person by link. The link carries a
-- long single-use code; opening it with an account adds that person to the
-- mess at once (the manager's invitation IS the approval), without an account
-- the app asks them to create one first and then continues. The old shared
-- 6-letter codes keep working and still wait for approval.
-- Contract: DATABASE.md "Invite links (0034)".

alter table public.mess_invites
  drop constraint if exists mess_invites_code_check,
  add constraint mess_invites_code_check check (code ~ '^[A-Z2-9]{6,12}$'),
  add column auto_approve boolean not null default false,
  add column single_use   boolean not null default false,
  add column invitee_name text check (char_length(invitee_name) <= 60),
  add column used_by      uuid references auth.users(id) on delete set null,
  add column used_at      timestamptz;

-- Manager only. Returns the code to put in the link. Valid 7 days, one use.
create or replace function public.create_invite_link(p_mess uuid, p_invitee_name text default null)
returns text
language plpgsql security definer set search_path = public as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  v_code text;
begin
  perform require_user();
  if not has_mess_role(p_mess, 'manager') then
    perform fail('NOT_MANAGER');
  end if;
  perform assert_mess_writable(p_mess);
  loop
    select string_agg(substr(v_alphabet, 1 + floor(random() * 32)::int, 1), '')
      into v_code from generate_series(1, 10);
    begin
      insert into mess_invites (mess_id, code, created_by, auto_approve, single_use, invitee_name)
      values (p_mess, v_code, auth.uid(), true, true, nullif(btrim(p_invitee_name), ''));
      return v_code;
    exception when unique_violation then
      -- collision: try another code
    end;
  end loop;
end $$;

-- What an invite page may show before anyone signs in: the mess, who invited,
-- who it is for, and whether it still works. Nothing else is exposed.
create or replace function public.invite_preview(p_code text)
returns table (valid boolean, reason text, mess_name text, inviter_name text, invitee_name text, auto_approve boolean)
language sql stable security definer set search_path = public as $$
  with i as (
    select i.*, ms.name as mess_name,
           (select m.display_name from mess_members m
            where m.mess_id = i.mess_id and m.user_id = i.created_by limit 1) as inviter
    from mess_invites i join messes ms on ms.id = i.mess_id
    where i.code = upper(btrim(p_code))
  )
  select (i.revoked_at is null and i.expires_at > now() and i.used_at is null),
         case when i.revoked_at is not null then 'revoked'
              when i.used_at is not null then 'used'
              when i.expires_at <= now() then 'expired' end,
         i.mess_name, i.inviter, i.invitee_name, i.auto_approve
  from i
  union all
  select false, 'unknown', null, null, null, false
  where not exists (select 1 from i);
$$;
grant execute on function public.invite_preview(text) to anon, authenticated;

-- Join by code. A link invite adds the person as an active member right away
-- and uses the invite up; a shared code still creates a pending request.
create or replace function public.join_mess(p_code text, p_display_name text) returns uuid
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := require_user();
  v_inv    mess_invites%rowtype;
  v_member mess_members%rowtype;
  v_status member_status;
begin
  select * into v_inv from mess_invites
  where code = upper(btrim(p_code)) and revoked_at is null and expires_at > now()
    and used_at is null
  for update;
  if v_inv.id is null then
    perform fail('INVALID_INVITE');
  end if;

  select * into v_member from mess_members where mess_id = v_inv.mess_id and user_id = v_uid;
  if v_member.id is not null and v_member.status <> 'left' then
    perform fail('ALREADY_MEMBER');
  end if;

  v_status := case when v_inv.auto_approve then 'active' else 'pending' end;
  perform set_config('meal_bazar.trusted', 'on', true);
  if v_member.id is not null then
    update mess_members set status = v_status, left_on = null,
           joined_on = case when v_inv.auto_approve then (now() at time zone 'Asia/Dhaka')::date else joined_on end
    where id = v_member.id returning * into v_member;
  else
    insert into mess_members (mess_id, user_id, display_name, status)
    values (v_inv.mess_id, v_uid, btrim(p_display_name), v_status)
    returning * into v_member;
  end if;
  perform set_config('meal_bazar.trusted', '', true);

  if v_inv.single_use then
    update mess_invites set used_by = v_uid, used_at = now() where id = v_inv.id;
  end if;
  if v_inv.auto_approve then
    -- The manager already approved, so tell them who arrived (not a request).
    perform push_enqueue(array[v_inv.created_by], 'join_request',
      'নতুন সদস্য যোগ দিয়েছেন', format('%s মেসে যোগ দিয়েছেন', v_member.display_name),
      'New member joined', format('%s joined the mess', v_member.display_name),
      '/more/members');
  end if;
  return v_member.id;
end $$;
