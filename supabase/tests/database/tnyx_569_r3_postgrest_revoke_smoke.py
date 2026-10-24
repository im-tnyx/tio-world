#!/usr/bin/env python3
"""#569 R3: isolated HTTP/PostgREST grant, revoke, and regrant acceptance.

Uses ONLY disposable Supabase Database CI at the exact guarded local URL.
Invokes three existing functions with missing Routine IDs: a successfully
authorized RPC must execute the owner guard and return its own not_found
error, without inserting/moving/deleting any Routine or Program. All writes
are limited to two disposable Auth fixture users and function EXECUTE ACLs.

This exercises real HTTP, HS256 JWT, PostgREST role switching, committed
REVOKE, and immediate post-revoke calls (not just a rolled-back SQL test).
"""
import base64
import hashlib
import hmac
import json
import os
import subprocess
import sys
import time
import urllib.error
import urllib.request
import uuid

DB_URL = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
API_URL = "http://127.0.0.1:3022"
TEST_JWT_SECRET = "r3-ci-only-move-revoke-smoke-secret-20261024"
PERMANENT_ID = "f569a311-0000-4000-8000-000000000001"
GUEST_ID = "f569a311-0000-4000-8000-000000000002"
MISSING_ROUTINE_ID = "f569a311-0000-4000-8000-000000000010"
SOURCE_ID = "f569a311-0000-4000-8000-000000000011"
DEST_ID = "f569a311-0000-4000-8000-000000000012"
MOVE_MUTATION_ID = "f569a311-0000-4000-8000-000000000013"
UNDO_MUTATION_ID = "f569a311-0000-4000-8000-000000000014"
CONTAINER = "tnyx-569-r3-pgrst-" + uuid.uuid4().hex[:12]
SPECS = (
    (
        "move_user_workout_routine",
        "public.move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)",
        {
            "p_routine_id": MISSING_ROUTINE_ID,
            "p_source_program_id": SOURCE_ID,
            "p_destination_program_id": DEST_ID,
            "p_expected_revision": 0,
            "p_client_mutation_id": MOVE_MUTATION_ID,
        },
        "routine_move_not_found",
        "routine_move_registered_account_required",
    ),
    (
        "create_user_workout_program_and_move_routine",
        "public.create_user_workout_program_and_move_routine(uuid,uuid,uuid,text,bigint,uuid)",
        {
            "p_routine_id": MISSING_ROUTINE_ID,
            "p_source_program_id": SOURCE_ID,
            "p_new_program_id": DEST_ID,
            "p_new_program_name": "R3 Missing Destination",
            "p_expected_revision": 0,
            "p_client_mutation_id": MOVE_MUTATION_ID,
        },
        "routine_create_move_not_found",
        "routine_create_move_registered_account_required",
    ),
    (
        "undo_create_user_workout_program_and_move_routine",
        "public.undo_create_user_workout_program_and_move_routine(uuid,uuid,uuid,uuid,bigint,uuid)",
        {
            "p_routine_id": MISSING_ROUTINE_ID,
            "p_original_program_id": SOURCE_ID,
            "p_created_program_id": DEST_ID,
            "p_original_move_mutation_id": MOVE_MUTATION_ID,
            "p_expected_revision": 1,
            "p_undo_mutation_id": UNDO_MUTATION_ID,
        },
        "routine_create_move_undo_not_found",
        "routine_create_move_undo_registered_account_required",
    ),
)


def psql(query):
    proc = subprocess.run(
        ["psql", DB_URL, "--set=ON_ERROR_STOP=1", "--tuples-only",
         "--no-align", "--command=" + query],
        check=True, capture_output=True, text=True,
    )
    return proc.stdout.strip()


def require_disposable():
    if os.getenv("GITHUB_ACTIONS") != "true" or os.getenv("DATABASE_URL") != DB_URL:
        raise RuntimeError("Refuse API ACL test outside exact disposable Database CI")
    if psql("""
      select current_database()='postgres'
         and current_user='postgres'
         and to_regclass('supabase_migrations.schema_migrations') is not null
         and (select count(*) from supabase_migrations.schema_migrations
              where version='20261024120000')=1
         and (select count(*) from auth.users
              where id in ('%s'::uuid,'%s'::uuid))=0
    """ % (PERMANENT_ID, GUEST_ID)) != "t":
        raise RuntimeError("Disposable CI identity/migration or fixture isolation failed")
    for _, signature, _, _, _ in SPECS:
        if psql("select has_function_privilege('authenticated','%s','EXECUTE')" % signature) != "t":
            raise RuntimeError("R3 migrated grant missing: " + signature)


def auth_fixture():
    psql("""
      insert into auth.users (id,email,is_anonymous) values
        ('%s'::uuid,'r3-pgrst-owner@example.test',false),
        ('%s'::uuid,'r3-pgrst-guest@example.test',true);
    """ % (PERMANENT_ID, GUEST_ID))
    if psql("""
      select (select count(*) from public.users
              where id in ('%s'::uuid,'%s'::uuid))=2
    """ % (PERMANENT_ID, GUEST_ID)) != "t":
        raise RuntimeError("Expected Auth trigger/owner fixture rows were not created")


def b64(value):
    return base64.urlsafe_b64encode(value).decode("ascii").rstrip("=")


def token(uid):
    head = {"alg": "HS256", "typ": "JWT"}
    claims = {
        "sub": uid, "role": "authenticated", "aud": "authenticated",
        "exp": int(time.time()) + 600, "iat": int(time.time())
    }
    header = b64(json.dumps(head, separators=(",", ":")).encode())
    payload = b64(json.dumps(claims, separators=(",", ":")).encode())
    signed = (header + "." + payload).encode()
    signature = b64(hmac.new(TEST_JWT_SECRET.encode(), signed, hashlib.sha256).digest())
    return header + "." + payload + "." + signature


def request(name, payload, jwt=None):
    data = json.dumps(payload).encode()
    headers = {"Content-Type": "application/json", "Accept": "application/json"}
    if jwt:
        headers["Authorization"] = "Bearer " + jwt
    req = urllib.request.Request(
        API_URL + "/rpc/" + name, data=data, headers=headers, method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as result:
            status, raw = result.status, result.read()
    except urllib.error.HTTPError as exc:
        status, raw = exc.code, exc.read()
    try:
        obj = json.loads(raw)
    except (ValueError, UnicodeDecodeError):
        raise AssertionError("Unexpected non-JSON HTTP response (%d)" % status)
    if not isinstance(obj, dict):
        raise AssertionError("Unexpected RPC response shape (%d)" % status)
    return status, str(obj.get("code", "")), str(obj.get("message", ""))


def assert_stage(stage, who, jwt):
    for name, _, body, missing_error, guest_error in SPECS:
        status, code, message = request(name, body, jwt)
        if stage == "enabled" and who == "owner":
            # A verified owner with a nonexistent Routine must REACH the RPC.
            ok = status == 404 and message == missing_error
        elif stage == "enabled" and who == "guest":
            # A real Auth anonymous account has the authenticated SQL role.
            ok = message == guest_error and status in (401, 403)
        else:
            # After committed REVOKE, JWT must no longer reach an RPC body.
            ok = status in (401, 403, 404) and code in ("42501", "PGRST202")
        if not ok:
            raise AssertionError(
                "%s/%s/%s: got HTTP %d code=%s message=%s" %
                (stage, who, name, status, code, message)
            )
        print("PASS %s/%s/%s -> HTTP %d code=%s" %
              (stage, who, name, status, code), flush=True)


def set_auth_exec(granted):
    sql = "\n".join(
        ("%s execute on function %s %s authenticated;" %
         ("grant" if granted else "revoke",
          sig, "to" if granted else "from"))
        for _, sig, _, _, _ in SPECS
    )
    psql(sql)
    # PostgREST schema cache can retain function visibility after ACL changes.
    # HTTP assertions must validate the newly committed database privileges.
    psql("select pg_notify('pgrst','reload schema')")
    for _, sig, _, _, _ in SPECS:
        if psql(
            "select has_function_privilege('authenticated','%s','EXECUTE')" % sig
        ) != ("t" if granted else "f"):
            raise AssertionError("Committed ACL restoration mismatch: " + sig)


def launch_postgrest():
    proc = subprocess.run(
        [
            "docker", "run", "--rm", "-d", "--network=host",
            "--name", CONTAINER,
            "-e", "PGRST_DB_URI=" + DB_URL,
            "-e", "PGRST_DB_ANON_ROLE=anon",
            "-e", "PGRST_DB_SCHEMAS=public",
            "-e", "PGRST_SERVER_PORT=3022",
            "-e", "PGRST_JWT_SECRET=" + TEST_JWT_SECRET,
            "postgrest/postgrest:v12.2.12",
        ], capture_output=True, text=True, check=True,
    )
    print("Started disposable PostgREST v12.2.12 " + proc.stdout.strip()[:16])
    for _ in range(80):
        try:
            with urllib.request.urlopen(API_URL + "/", timeout=2) as result:
                if result.status == 200:
                    return
        except (urllib.error.URLError, TimeoutError):
            pass
        time.sleep(0.5)
    raise RuntimeError("Disposable PostgREST HTTP readiness timeout")


def main():
    require_disposable()
    fixture_created = False
    container_started = False
    try:
        auth_fixture()
        fixture_created = True
        launch_postgrest()
        container_started = True
        assert_stage("enabled", "owner", token(PERMANENT_ID))
        assert_stage("enabled", "guest", token(GUEST_ID))
        assert_stage("enabled", "anon", None)
        set_auth_exec(False)  # committed emergency rollback simulation
        assert_stage("revoked", "owner", token(PERMANENT_ID))
        set_auth_exec(True)  # restore the reviewed R3 CI baseline
        assert_stage("enabled", "owner", token(PERMANENT_ID))
        print("PASS: all three HTTP RPC ACL revocations + regrant, no Routine/Program writes")
    finally:
        try:
            # A failure should not leave the disposable DB in an unintended ACL.
            set_auth_exec(True)
        except Exception as exc:
            print("CRITICAL: disposable ACL restore failed: %s" % exc, file=sys.stderr)
            raise
        finally:
            if fixture_created:
                psql("delete from auth.users where id in ('%s'::uuid,'%s'::uuid)" %
                     (PERMANENT_ID, GUEST_ID))
                if psql("select count(*) from auth.users where id in ('%s'::uuid,'%s'::uuid)" %
                        (PERMANENT_ID, GUEST_ID)) != "0":
                    raise AssertionError("Auth fixture cleanup left rows behind")
            if container_started:
                subprocess.run(["docker", "rm", "-f", CONTAINER],
                               check=False, capture_output=True)


if __name__ == "__main__":
    main()
