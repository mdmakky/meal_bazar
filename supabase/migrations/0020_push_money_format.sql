-- Push amounts read like the app: Indian digit grouping (১,২৩,৪৫৬) and two
-- decimals only when there are paisa (৳1,250.50, ৳6,900).
create or replace function public.push_money(p_amount numeric, p_bn boolean) returns text
language plpgsql immutable as $$
declare
  v    numeric := round(abs(p_amount), 2);
  i    text    := trunc(v)::text;
  frac text    := case when v = trunc(v) then '' else '.' || lpad(((v - trunc(v)) * 100)::int::text, 2, '0') end;
  s    text;
begin
  if length(i) > 3 then
    i := regexp_replace(left(i, length(i) - 3), '(\d)(?=(\d\d)+$)', '\1,', 'g') || ',' || right(i, 3);
  end if;
  s := case when p_amount < 0 then '-' else '' end || i || frac;
  return '৳' || case when p_bn then translate(s, '0123456789', '০১২৩৪৫৬৭৮৯') else s end;
end $$;
