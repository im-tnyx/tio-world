-- GitHub #569 R3: guarded, least-privilege Move RPC exposure proposal.
-- This migration is source/review ONLY until a separate explicit hosted apply GO.
-- Once applied, every permanent signed-in account can invoke these RPCs through
-- PostgREST; the server's owner/identity/CAS guards—not Flutter—are authority.
-- Revoke in a separately approved operational rollback; do NOT place rollback
-- in the normal forward migration sequence.

do $r3_preflight$
declare
  v_signature text;
  v_expected_body_sha256 text;
  v_function oid;
  v_body text;
begin
  -- Pin the complete, security-reviewed function bodies, not snippets of
  -- auth checks. This must fail closed if owner validation, revision CAS,
  -- mutation hashes, provenance, or lock ordering drift before deployment.
  -- Digests are SHA-256(UTF8(pg_proc.prosrc)), checked against the existing
  -- 69-migration hosted baseline; R3 does not replace these RPC bodies.
  -- A later intentional body change requires a separate review of the new
  -- complete definition and a corresponding explicit digest update.
  for v_signature, v_expected_body_sha256 in
    select signature, expected_body_sha256 from (values
      ('public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)',
       '54ef34da88a532f6117d4a10a2345a4329f0887eb25a08a3d432d76d6278a757'),
      ('public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)',
       '6d52fb278798bc58073f2657ef310da37a191dc0e9c40e6360390f38e3956fbc'),
      ('public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)',
       '68ed1c4bf4d06e3b9a88dfea9739be96f4176c5f1b6c26a41275c2ea2ace9038')
    ) as exact_move_rpc(signature, expected_body_sha256)
  loop
    v_function := pg_catalog.to_regprocedure(v_signature);
    if v_function is null then
      raise exception 'R3 missing expected Move function: %', v_signature;
    end if;
    if not exists (
      select 1 from pg_catalog.pg_proc as p
      where p.oid = v_function
        and p.proowner = 'postgres'::regrole
        and p.prosecdef
        and p.proconfig @> array['search_path=""']::text[]
    ) then
      raise exception 'R3 function owner/security/search_path mismatch: %',
        v_signature;
    end if;
    select p.prosrc into v_body
    from pg_catalog.pg_proc as p where p.oid = v_function;
    if pg_catalog.encode(pg_catalog.sha256(
         pg_catalog.convert_to(v_body, 'UTF8')), 'hex')
       is distinct from v_expected_body_sha256 then
      raise exception 'R3 reviewed Move RPC body fingerprint drift: %',
        v_signature;
    end if;
    if pg_catalog.strpos(pg_catalog.lower(v_body), 'auth.uid()') = 0
      or pg_catalog.strpos(pg_catalog.lower(v_body), 'is_anonymous is false') = 0 then
      raise exception 'R3 permanent-account admission guard missing: %',
        v_signature;
    end if;
  end loop;

  if not (select c.relrowsecurity from pg_catalog.pg_class as c
          where c.oid = 'public.user_workout_programs'::regclass)
    or not (select c.relrowsecurity from pg_catalog.pg_class as c
            where c.oid = 'public.user_workout_routines'::regclass)
    or pg_catalog.has_column_privilege(
         'authenticated', 'public.user_workout_routines',
         'program_id', 'UPDATE')
    or pg_catalog.has_table_privilege(
         'authenticated', 'public.user_workout_programs', 'DELETE') then
    raise exception 'R3 RLS or direct-write privilege boundary changed';
  end if;
end;
$r3_preflight$;

revoke all on function public.move_user_workout_routine(
  uuid, uuid, uuid, bigint, uuid
) from public, anon, authenticated, service_role;
revoke all on function public.create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, text, bigint, uuid
) from public, anon, authenticated, service_role;
revoke all on function public.undo_create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, uuid, bigint, uuid
) from public, anon, authenticated, service_role;

grant execute on function public.move_user_workout_routine(
  uuid, uuid, uuid, bigint, uuid
) to authenticated;
grant execute on function public.create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, text, bigint, uuid
) to authenticated;
grant execute on function public.undo_create_user_workout_program_and_move_routine(
  uuid, uuid, uuid, uuid, bigint, uuid
) to authenticated;

-- Post-apply role checks are also enforced in disposable Database CI.
do $r3_assert$
declare
  v_signature text;
  v_function oid;
begin
  for v_signature in
    select signature from (values
      ('public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)'),
      ('public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)'),
      ('public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)')
    ) as exact_move_rpc(signature)
  loop
    v_function := pg_catalog.to_regprocedure(v_signature);
    if not pg_catalog.has_function_privilege(
         'authenticated', v_function, 'EXECUTE')
       or pg_catalog.has_function_privilege('anon', v_function, 'EXECUTE')
       or pg_catalog.has_function_privilege('service_role', v_function, 'EXECUTE')
       or exists (
         select 1 from pg_catalog.pg_proc as p,
           pg_catalog.aclexplode(coalesce(
             p.proacl, pg_catalog.acldefault('f', p.proowner))) as acl
         where p.oid = v_function
           and acl.grantee = 0
           and acl.privilege_type = 'EXECUTE'
       ) then
      raise exception 'R3 exact RPC ACL postcondition failed: %', v_signature;
    end if;
  end loop;
end;
$r3_assert$;
