#!/usr/bin/env bash
set -euo pipefail

# Isolated PostgreSQL 17 role-context reproduction. No network port or hosted URL.
source_file="$(dirname "$0")/../../migrations/20261031130000_routine_note_receipt_scheduled_cleanup.sql"
grep -F -A1 'set role postgres;' "$source_file" |
  grep -Fq 'grant routine_note_receipt_cleanup_scheduler to postgres with set true;'

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
create role migration_principal login createrole noinherit;
create role linked_login login noinherit;
grant migration_principal to linked_login with set true;
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

# The resulting membership must permit SET, but not inherit or re-grant.
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

echo 'PASS: linked-login cleanup role grant context and least-privilege flags'
