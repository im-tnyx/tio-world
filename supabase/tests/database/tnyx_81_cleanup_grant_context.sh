#!/usr/bin/env bash
set -euo pipefail

# Disposable PostgreSQL 17 proof for the CLI 2.114.0 linked-login ledger failure.
# CLI 2.116.0 re-asserts the migration role before its own insert, so this script
# reproduces the 2.114.0 batch itself: step down, run the role switches, then the
# appended ledger INSERT with no extra role restore. No hosted URL and no network.
source_file="$(dirname "$0")/../../migrations/20261031130000_routine_note_receipt_scheduled_cleanup.sql"

grep -F -A1 'set role postgres;' "$source_file" |
  grep -Fq 'grant routine_note_receipt_cleanup_scheduler to postgres with set true;'

reset_count="$(grep -Eic '^[[:space:]]*reset role[[:space:]]*;[[:space:]]*$' "$source_file")"
if [[ "$reset_count" -ne 1 ]]; then
  echo "expected the pre-owner RESET ROLE to remain once, found ${reset_count}" >&2
  exit 1
fi

tail_stmt="$(grep -Eiv '^[[:space:]]*(--|$)' "$source_file" | tail -n 1 | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
if [[ "$tail_stmt" != 'setrolepostgres;' ]]; then
  echo "migration must finish as postgres, found: ${tail_stmt}" >&2
  exit 1
fi

container="tnyx81-grant-${GITHUB_RUN_ID:-local}-$$"
docker run --rm -d --name "$container" --network none \
  -e POSTGRES_HOST_AUTH_METHOD=trust postgres:17 >/dev/null
trap 'docker stop "$container" >/dev/null' EXIT

for attempt in {1..30}; do
  if docker exec "$container" pg_isready -U postgres -q; then break; fi
  sleep 1
done
docker exec "$container" pg_isready -U postgres -q

docker exec -i "$container" psql -U postgres -d postgres \
  -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
create role cli_login_postgres login noinherit nosuperuser nocreatedb nocreaterole;
grant postgres to cli_login_postgres with inherit false, set true, admin false;
create schema supabase_migrations authorization postgres;
revoke all on schema supabase_migrations from public;
create table supabase_migrations.schema_migrations (
  version text primary key,
  name text,
  statements text[]
);
revoke all on table supabase_migrations.schema_migrations from public;
grant usage on schema supabase_migrations to postgres;
grant insert on table supabase_migrations.schema_migrations to postgres;
SQL

docker exec -i "$container" psql -U postgres -d postgres \
  -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
select 1 / (
  not has_schema_privilege('cli_login_postgres', 'supabase_migrations', 'USAGE')
  and not has_table_privilege(
    'cli_login_postgres', 'supabase_migrations.schema_migrations', 'INSERT')
  and has_schema_privilege('postgres', 'supabase_migrations', 'USAGE')
  and has_table_privilege(
    'postgres', 'supabase_migrations.schema_migrations', 'INSERT')
  and not has_schema_privilege('public', 'supabase_migrations', 'USAGE')
)::integer;
SQL

# Non-superuser grantor, matching hosted postgres more closely than the
# bootstrap superuser. The explicit membership must allow SET only.
docker exec -i "$container" psql -U postgres -d postgres \
  -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
create role migration_principal login createrole noinherit;
create role linked_login login noinherit;
grant migration_principal to linked_login with set true, inherit false, admin false;
SQL

docker exec -i "$container" psql -U linked_login -d postgres \
  -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
set role migration_principal;
create role cleanup_owner nologin noinherit nobypassrls;
create role cleanup_scheduler login noinherit nobypassrls;
grant cleanup_owner to migration_principal with set true;
set role cleanup_owner;
reset role;
select 1 / (current_user = 'linked_login')::integer;
set role cleanup_owner;
set role migration_principal;
grant cleanup_scheduler to migration_principal with set true;
set role cleanup_scheduler;
select 1 / (current_user = 'cleanup_scheduler')::integer;
SQL

docker exec -i "$container" psql -U postgres -d postgres \
  -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
select 1 / (
  count(*) = 2 and bool_and(m.set_option and not m.inherit_option
                           and not m.admin_option)
)::integer
from pg_auth_members m
join pg_roles granted on granted.oid = m.roleid
join pg_roles member on member.oid = m.member
where granted.rolname in ('cleanup_owner', 'cleanup_scheduler')
  and member.rolname = 'migration_principal'
  and m.grantor = member.oid;
SQL

fail_log="$(mktemp)"
set +e
docker exec -i "$container" psql -U cli_login_postgres -d postgres \
  -v ON_ERROR_STOP=1 >"$fail_log" 2>&1 <<'SQL'
\set VERBOSITY verbose
set role postgres;
reset all;
select 1 / (current_user = 'postgres' and session_user = 'cli_login_postgres')::integer;
begin;
create role ledger_owner nologin nosuperuser nocreatedb nocreaterole noinherit nobypassrls;
create role ledger_scheduler login nosuperuser nocreatedb nocreaterole noinherit nobypassrls;
grant ledger_owner to postgres with set true;
set role ledger_owner;
reset role;
set role ledger_owner;
set role postgres;
grant ledger_scheduler to postgres with set true;
create table public.tnyx81_ledger_marker (id integer);
set role ledger_scheduler;
reset role;
insert into supabase_migrations.schema_migrations(version, name, statements)
values ('20261031130000', 'original_reset_role', array['select 1']);
SQL
fail_status=$?
set -e
if [[ "$fail_status" -eq 0 ]] || ! grep -F '42501' "$fail_log" >/dev/null; then
  echo 'expected original RESET ROLE ledger insert to fail with SQLSTATE 42501' >&2
  cat "$fail_log" >&2
  exit 1
fi
rm -f "$fail_log"

docker exec -i "$container" psql -U postgres -d postgres \
  -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
select 1 / (
  to_regclass('public.tnyx81_ledger_marker') is null
  and not exists (select 1 from pg_roles where rolname = 'ledger_owner')
  and not exists (select 1 from pg_roles where rolname = 'ledger_scheduler')
  and (select count(*) = 0 from supabase_migrations.schema_migrations)
)::integer;
SQL

docker exec -i "$container" psql -U cli_login_postgres -d postgres \
  -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
set role postgres;
reset all;
select 1 / (current_user = 'postgres' and session_user = 'cli_login_postgres')::integer;
begin;
create role ledger_owner nologin nosuperuser nocreatedb nocreaterole noinherit nobypassrls;
create role ledger_scheduler login nosuperuser nocreatedb nocreaterole noinherit nobypassrls;
grant ledger_owner to postgres with set true;
set role ledger_owner;
reset role;
select 1 / (current_user = 'cli_login_postgres')::integer;
set role ledger_owner;
set role postgres;
grant ledger_scheduler to postgres with set true;
set role ledger_scheduler;
select 1 / (current_user = 'ledger_scheduler')::integer;
set role postgres;
select 1 / (current_user = 'postgres' and session_user = 'cli_login_postgres')::integer;
insert into supabase_migrations.schema_migrations(version, name, statements)
values (
  '20261031130000',
  'routine_note_receipt_scheduled_cleanup',
  array['set role postgres']
);
commit;
SQL

docker exec -i "$container" psql -U postgres -d postgres \
  -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
select 1 / (
  count(*) = 1
)::integer
from supabase_migrations.schema_migrations
where version = '20261031130000'
  and name = 'routine_note_receipt_scheduled_cleanup';

-- This image's bootstrap superuser records INHERIT true for an unqualified
-- SET grant. ADMIN stays false. Hosted non-superuser postgres is covered by
-- the migration_principal assertion above.
select 1 / (
  count(*) = 2
  and bool_and(m.set_option and m.inherit_option and not m.admin_option)
  and bool_and(m.grantor = member.oid)
)::integer
from pg_auth_members m
join pg_roles granted on granted.oid = m.roleid
join pg_roles member on member.oid = m.member
where granted.rolname in ('ledger_owner', 'ledger_scheduler')
  and member.rolname = 'postgres';

select 1 / (
  m.set_option and not m.inherit_option and not m.admin_option
)::integer
from pg_auth_members m
join pg_roles granted on granted.oid = m.roleid
join pg_roles member on member.oid = m.member
where granted.rolname = 'postgres'
  and member.rolname = 'cli_login_postgres';

select 1 / (
  (select not rolcanlogin and not rolsuper and not rolcreatedb
          and not rolcreaterole and not rolinherit and not rolbypassrls
   from pg_roles where rolname = 'ledger_owner')
  and (select rolcanlogin and not rolsuper and not rolcreatedb
              and not rolcreaterole and not rolinherit and not rolbypassrls
       from pg_roles where rolname = 'ledger_scheduler')
  and (select count(*) = 0
       from pg_auth_members membership
       join pg_roles granted on granted.oid = membership.roleid
       join pg_roles member on member.oid = membership.member
       where granted.rolname in ('ledger_owner', 'ledger_scheduler')
         and member.rolname <> 'postgres')
)::integer;
SQL

# The direct postgres session used by local replay must also finish as postgres.
docker exec -i "$container" psql -U postgres -d postgres \
  -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
begin;
set role ledger_scheduler;
set role postgres;
select 1 / (current_user = 'postgres' and session_user = 'postgres')::integer;
rollback;
SQL

# The login role stays unable to write the ledger after the corrected commit.
denied_log="$(mktemp)"
set +e
docker exec -i "$container" psql -U cli_login_postgres -d postgres \
  -v ON_ERROR_STOP=1 >"$denied_log" 2>&1 <<'SQL'
\set VERBOSITY verbose
insert into supabase_migrations.schema_migrations(version, name, statements)
values ('denied', 'denied', array['select 1']);
SQL
denied_status=$?
set -e
if [[ "$denied_status" -eq 0 ]] || ! grep -F '42501' "$denied_log" >/dev/null; then
  echo 'expected bare linked login to remain denied on the ledger' >&2
  cat "$denied_log" >&2
  exit 1
fi
rm -f "$denied_log"

docker exec -i "$container" psql -U postgres -d postgres \
  -v ON_ERROR_STOP=1 >/dev/null <<'SQL'
select 1 / (count(*) = 1)::integer from supabase_migrations.schema_migrations;
SQL

echo 'PASS: linked-login ledger insert, rollback, corrected postgres role, and least-privilege flags'
