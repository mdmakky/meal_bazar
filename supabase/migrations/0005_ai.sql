-- 0005_ai: per-mess daily AI quota and the minimal context the gateway sends to a model.
-- Rules: AI.md (quota, kill switch, pseudonymisation), PRODUCT_RULES.md §7.

create table public.ai_usage (
  mess_id uuid not null references public.messes(id) on delete cascade,
  day     date not null,
  feature text not null check (char_length(feature) <= 40),
  count   int  not null default 0 check (count >= 0),
  primary key (mess_id, day, feature)
);

alter table public.ai_usage enable row level security;
-- Members may read usage; no write policy, so only ai_consume() (security definer) writes.
create policy ai_usage_read on public.ai_usage for select using (is_mess_member(mess_id));

-- Spends one unit of today's (Asia/Dhaka) quota for p_feature.
-- Returns false when the quota is used up. Raises NOT_MEMBER / AI_DISABLED.
create or replace function public.ai_consume(p_mess uuid, p_feature text, p_limit int)
returns boolean
language plpgsql security definer set search_path = public as $$
declare
  v_count int;
begin
  perform require_user();
  if not exists (
    select 1 from mess_members
    where mess_id = p_mess and user_id = auth.uid() and status = 'active'
  ) then
    perform fail('NOT_MEMBER');
  end if;
  if (select coalesce(ai_settings ->> 'enabled', 'true') = 'false'
      from messes where id = p_mess and deleted_at is null) is not false then
    perform fail('AI_DISABLED');
  end if;
  if p_limit < 1 then
    return false;
  end if;

  insert into ai_usage as u (mess_id, day, feature, count)
  values (p_mess, (now() at time zone 'Asia/Dhaka')::date, p_feature, 1)
  on conflict (mess_id, day, feature) do update set count = u.count + 1
    where u.count < p_limit
  returning u.count into v_count;
  return v_count is not null;
end $$;

-- Compact member/meal-type list for the meal-draft prompt. Refs (M1, T1…) are
-- positional; the gateway maps them back to ids. Security invoker: RLS applies.
create or replace function public.ai_meal_context(p_mess uuid) returns jsonb
language sql stable as $$
  select jsonb_build_object(
    'members', coalesce((
      select jsonb_agg(jsonb_build_object(
               'ref', 'M' || rn, 'member_id', id, 'aliases', jsonb_build_array(display_name))
             order by rn)
      from (select id, display_name, row_number() over (order by joined_on, created_at, id) rn
            from mess_members
            where mess_id = p_mess and status = 'active') m
    ), '[]'::jsonb),
    'meal_types', coalesce((
      select jsonb_agg(jsonb_build_object('ref', 'T' || rn, 'meal_type_id', id, 'name', name)
             order by rn)
      from (select id, name, row_number() over (order by sort_order, created_at, id) rn
            from meal_types
            where mess_id = p_mess and enabled) t
    ), '[]'::jsonb)
  )
  where is_mess_member(p_mess);
$$;
