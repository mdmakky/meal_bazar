-- Test helpers: act as a user, assert, expect an error.
create schema test;
grant usage on schema test to authenticated, anon;

-- Switch the session to the given user (null = back to superuser).
create function test.act_as(p_user uuid) returns void language plpgsql as $$
begin
  if p_user is null then
    perform set_config('request.jwt.claim.sub', '', false);
    reset role;
  else
    perform set_config('request.jwt.claim.sub', p_user::text, false);
    set role authenticated;
  end if;
end $$;

create function test.check(p_ok boolean, p_msg text) returns void language plpgsql as $$
begin
  if p_ok is not true then raise exception 'FAIL: %', p_msg; end if;
end $$;

-- Runs p_sql and asserts it fails with a message containing p_expect.
create function test.expect_error(p_sql text, p_expect text) returns void language plpgsql as $$
begin
  execute p_sql;
  raise exception 'FAIL: expected error % from: %', p_expect, p_sql;
exception when others then
  if sqlerrm like 'FAIL:%' or position(p_expect in sqlerrm) = 0 then
    raise exception 'FAIL: expected % but got "%" from: %', p_expect, sqlerrm, p_sql;
  end if;
end $$;

-- Runs p_sql (an UPDATE/DELETE) and returns the affected row count.
create function test.rows(p_sql text) returns int language plpgsql as $$
declare n int;
begin
  execute p_sql;
  get diagnostics n = row_count;
  return n;
end $$;
grant execute on all functions in schema test to authenticated, anon;
