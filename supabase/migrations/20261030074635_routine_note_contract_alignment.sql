-- TNYX-81 review remediation
-- Align SQL body normalization with Dart String.trim() and bound total active
-- Notes per owner without changing the existing table shape or RPC surface.

create or replace function private.normalize_user_workout_routine_note_body(
  p_body text
)
returns text
language sql
immutable
strict
set search_path = ''
as $$
  select pg_catalog.btrim(
    p_body,
    U&'\0009\000A\000B\000C\000D\0020\0085\00A0\1680\2000\2001\2002\2003\2004\2005\2006\2007\2008\2009\200A\2028\2029\202F\205F\3000\FEFF'
  );
$$;

revoke all on function private.normalize_user_workout_routine_note_body(text)
  from public, anon, authenticated, service_role;

update public.user_workout_routine_notes
set body = private.normalize_user_workout_routine_note_body(body)
where body is distinct from private.normalize_user_workout_routine_note_body(body);

do $$
begin
  if exists (
    select 1
    from public.user_workout_routine_notes
    where body = '' or pg_catalog.char_length(body) > 500
  ) then
    raise exception 'routine_note_existing_body_contract_violation';
  end if;
end;
$$;

alter table public.user_workout_routine_notes
  drop constraint user_workout_routine_notes_body_check;

alter table public.user_workout_routine_notes
  add constraint user_workout_routine_notes_body_check
  check (
    body = private.normalize_user_workout_routine_note_body(body)
    and body <> ''
    and pg_catalog.char_length(body) <= 500
  );

create function private.normalize_user_workout_routine_note_body_trigger()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.body is null then
    raise exception 'invalid_routine_note_body' using errcode = '22023';
  end if;

  new.body := private.normalize_user_workout_routine_note_body(new.body);
  if new.body = '' or pg_catalog.char_length(new.body) > 500 then
    raise exception 'invalid_routine_note_body' using errcode = '22023';
  end if;
  return new;
end;
$$;

revoke all on function private.normalize_user_workout_routine_note_body_trigger()
  from public, anon, authenticated, service_role;

create trigger aaa_user_workout_routine_notes_normalize_body
before insert or update of body
on public.user_workout_routine_notes
for each row
execute function private.normalize_user_workout_routine_note_body_trigger();

create function private.enforce_user_workout_routine_note_total_quota()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_count bigint;
begin
  perform pg_catalog.pg_advisory_xact_lock(
    pg_catalog.hashtextextended(
      new.user_id::text || ':routine-note-user-quota',
      0
    )
  );

  select count(*) into v_count
  from public.user_workout_routine_notes as note
  where note.user_id = new.user_id;

  if v_count >= 50 then
    raise exception 'routine_note_quota_exceeded' using errcode = 'P0001';
  end if;

  return new;
end;
$$;

revoke all on function private.enforce_user_workout_routine_note_total_quota()
  from public, anon, authenticated, service_role;

create trigger zzz_user_workout_routine_notes_total_quota
before insert
on public.user_workout_routine_notes
for each row
execute function private.enforce_user_workout_routine_note_total_quota();
