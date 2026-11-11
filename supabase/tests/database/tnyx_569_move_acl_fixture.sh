#!/usr/bin/env bash
# Shared cleanup for #569 disposable CI races and the denied/granted regression.
# Source this file; functions refuse writes outside the exact CI local database.

tnyx_569_require_disposable_db() {
  local expected_url='postgresql://postgres:postgres@127.0.0.1:54322/postgres'
  if [[ "${GITHUB_ACTIONS:-}" != true || "${DATABASE_URL:-}" != "$expected_url" ]]; then
    echo '#569 ACL fixture requires the exact disposable CI database URL.' >&2
    return 1
  fi
  local identity
  identity="$(psql "$DATABASE_URL" --set=ON_ERROR_STOP=1 -At --command="
    select current_database() = 'postgres'
      and current_user = 'postgres'
      and to_regclass('supabase_migrations.schema_migrations') is not null
      and to_regclass('public.user_workout_routines') is not null
  " | tr -d '[:space:]')" || return 1
  if [[ "$identity" != t ]]; then
    echo '#569 ACL fixture database identity check failed.' >&2
    return 1
  fi
}

tnyx_569_require_signature() {
  case "$1" in
    'public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)' | \
    'public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)' | \
    'public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)') ;;
    *) echo "Unexpected #569 RPC signature: $1" >&2; return 1 ;;
  esac
}

tnyx_569_auth_acl() {
  local signature="$1"
  tnyx_569_require_disposable_db || return 1
  tnyx_569_require_signature "$signature" || return 1
  psql "$DATABASE_URL" --set=ON_ERROR_STOP=1 -At --command="
    select has_function_privilege('authenticated','$signature','EXECUTE')
  " | tr -d '[:space:]'
}

tnyx_569_assert_acl() {
  local signature="$1" expected="$2" actual
  tnyx_569_require_disposable_db || return 1
  tnyx_569_require_signature "$signature" || return 1
  case "$expected" in t|f) ;; *) return 1 ;; esac
  actual="$(psql "$DATABASE_URL" --set=ON_ERROR_STOP=1 -At --command="
    select has_function_privilege('authenticated', p.oid, 'EXECUTE') = ('$expected' = 't')
      and not has_function_privilege('anon', p.oid, 'EXECUTE')
      and not has_function_privilege('service_role', p.oid, 'EXECUTE')
      and not exists (
        select 1 from aclexplode(coalesce(p.proacl, acldefault('f', p.proowner))) as acl
        where acl.grantee = 0 and acl.privilege_type = 'EXECUTE'
      )
      and p.proowner = 'postgres'::regrole
      and p.prosecdef
      and p.proconfig @> array['search_path=\"\"']::text[]
      and (select relrowsecurity from pg_class
           where oid = 'public.user_workout_programs'::regclass)
      and (select relrowsecurity from pg_class
           where oid = 'public.user_workout_routines'::regclass)
      and not has_column_privilege('authenticated',
        'public.user_workout_routines','program_id','UPDATE')
      and not has_table_privilege('authenticated',
        'public.user_workout_programs','DELETE')
    from pg_proc as p where p.oid = '$signature'::regprocedure
  " | tr -d '[:space:]')" || return 1
  if [[ "$actual" != t ]]; then
    echo "#569 RPC ACL/security boundary mismatch: $signature (authenticated=$expected)" >&2
    return 1
  fi
}

tnyx_569_restore_acl() {
  local signature="$1" initial="$2"
  tnyx_569_require_disposable_db || return 1
  tnyx_569_require_signature "$signature" || return 1
  case "$initial" in t|f) ;; *) return 1 ;; esac
  psql "$DATABASE_URL" --set=ON_ERROR_STOP=1 \
    --command="revoke all on function $signature from public,anon,authenticated,service_role" || return 1
  if [[ "$initial" == t ]]; then
    psql "$DATABASE_URL" --set=ON_ERROR_STOP=1 \
      --command="grant execute on function $signature to authenticated" || return 1
  fi
  tnyx_569_assert_acl "$signature" "$initial"
}
