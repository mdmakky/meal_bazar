#!/usr/bin/env bash
# Runs migrations + SQL tests against a throwaway local Postgres cluster.
set -euo pipefail
ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
export PGHOST=$TMP PGPORT=${PGPORT_TEST:-54329} PGUSER=postgres
initdb -D "$TMP/data" -U postgres --auth=trust -E UTF8 --locale=C >/dev/null
pg_ctl -D "$TMP/data" -o "-p $PGPORT -k $TMP -c listen_addresses=''" -l "$TMP/log" -w start >/dev/null
trap 'pg_ctl -D "$TMP/data" -m fast stop >/dev/null 2>&1; rm -rf "$TMP"' EXIT
createdb mb_test
psql_run() { psql -X -q -v ON_ERROR_STOP=1 -d mb_test "$@"; }
psql_run -f "$ROOT/tests/supabase_stub.sql"
for f in "$ROOT"/migrations/*.sql; do psql_run -f "$f"; done
psql_run -f "$ROOT/tests/grants.sql"
psql_run -f "$ROOT/tests/helpers.sql"
for t in "$ROOT"/tests/*_test.sql; do
  echo "• $(basename "$t")"
  psql_run -o /dev/null -f "$t"
done
echo "All SQL tests passed"
