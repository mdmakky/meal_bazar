-- Meal-off posts read as the member's own chat message ("আজ রাতের মিল বন্ধ
-- করলাম।"), not a third-person system notice. Same collapse rule: a second
-- switch of the same meal within 2 minutes replaces the previous post.
create or replace function public.post_meal_off_notice(
  p_mess uuid, p_member uuid, p_date date, p_meal_type uuid, p_off boolean
) returns void
language plpgsql security definer set search_path = public as $$
declare
  v_uid    uuid := auth.uid();
  v_thread uuid;
  v_name   text;
  v_meal   text;
  v_diff   int := p_date - (now() at time zone 'Asia/Dhaka')::date;
  v_day    text;
begin
  if coalesce(platform_default('features', 'messages'), 'true') = 'false'::jsonb
     or coalesce(platform_default('features', 'mess_group'), 'true') = 'false'::jsonb then
    return;
  end if;
  v_thread := ensure_mess_group(p_mess);
  select display_name into v_name from mess_members where id = p_member;
  select name into v_meal from meal_types where id = p_meal_type;
  v_day := case v_diff when 0 then 'আজ' when 1 then 'কাল' when -1 then 'গতকাল'
             else translate(to_char(p_date, 'DD/MM'), '0123456789', '০১২৩৪৫৬৭৮৯') end;

  delete from messages
  where thread_id = v_thread and sender_id = v_uid and hidden_at is null
    and created_at > now() - interval '2 minutes'
    and meta ->> 't' = 'meal_off' and meta ->> 'member' = p_member::text
    and meta ->> 'date' = p_date::text and meta ->> 'meal' = p_meal_type::text;

  insert into messages (thread_id, mess_id, sender_id, body, kind, meta)
  values (v_thread, p_mess, v_uid,
          v_day || ' ' || bn_genitive(v_meal) || ' মিল '
            || case when p_off then 'বন্ধ করলাম।' else 'আবার চালু করলাম।' end,
          'user',
          jsonb_build_object('t', 'meal_off', 'member', p_member, 'name', v_name,
                             'date', p_date, 'meal', p_meal_type, 'meal_name', v_meal,
                             'off', p_off));
  update message_threads set last_message_at = now() where id = v_thread;
end $$;
revoke execute on function public.post_meal_off_notice(uuid, uuid, date, uuid, boolean)
  from public, anon, authenticated;

-- Existing third-person notices become first-person messages too.
update messages
set kind = 'user',
    body = regexp_replace(regexp_replace(body, 'আবার চালু করেছেন$', 'আবার চালু করলাম।'), 'বন্ধ করেছেন$', 'বন্ধ করলাম।')
where kind = 'system' and meta ->> 't' = 'meal_off';
