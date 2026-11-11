#!/usr/bin/env python3
"""TNYX-81 disposable HTTP qualification for the Routine Notes Data API gate.

This test is intentionally limited to the exact disposable Supabase Database
CI identity. It starts a throwaway PostgREST container against that loopback
database, uses synthetic Auth users/fixtures, and restores the gate state and
PostgREST configuration before exit.
"""

import base64
import hashlib
import hmac
import json
import os
import re
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import uuid


CI_DB_URL = "postgresql://postgres:postgres@127.0.0.1:54322/postgres"
DB_URL = os.getenv("TNYX_81_DATABASE_URL", CI_DB_URL)
POSTGREST_DB_URI = os.getenv("TNYX_81_POSTGREST_DB_URI", DB_URL)
API_URL = os.getenv("TNYX_81_API_URL", "http://127.0.0.1:3023")
DISPOSABLE_MODE = os.getenv("TNYX_81_DISPOSABLE_MODE", "ci")
PSQL_CONTAINER = os.getenv("TNYX_81_PSQL_CONTAINER", "")
API_PORT = str(urllib.parse.urlparse(API_URL).port or 3023)
TEST_JWT_SECRET = "tnyx-81-routine-notes-gate-ci-only-20261101"
OWNER_ID = "a8100000-0000-4000-8000-000000000001"
GUEST_ID = "a8100000-0000-4000-8000-000000000002"
OWNER_PROGRAM_ID = "a8100000-0000-4000-8000-000000000011"
GUEST_PROGRAM_ID = "a8100000-0000-4000-8000-000000000012"
OWNER_ROUTINE_ID = "a8100000-0000-4000-8000-000000000021"
GUEST_ROUTINE_ID = "a8100000-0000-4000-8000-000000000022"
OWNER_NOTE_ID = "a8100000-0000-4000-8000-000000000101"
CONTAINER = "tnyx-81-routine-notes-gate-" + uuid.uuid4().hex[:12]

NOTE_PATH = "/user_workout_routine_notes?select=id,user_id&user_id=eq."
EMBEDDED_NOTE_PATH = (
    "/user_workout_routines?select=id,user_workout_routine_notes(*)&id=eq."
)
EMBEDDED_FILTERED_NOTE_PATH = (
    "/user_workout_routines?select=id,user_workout_routine_notes(id,user_id,body)"
    "&id=eq."
)
RPC_PATHS = (
    "/rpc/mutate_user_workout_routine_note",
    "/rpc/mutate_user_workout_routine_note_legacy",
    "/rpc/reconcile_user_workout_routine_note_mutation",
)
STAGE = os.getenv("TNYX_81_STAGE", "")
STAGE_MIGRATION = os.getenv("TNYX_81_STAGE_MIGRATION", "20261028120000")
STAGES = {
    "baseline",
    "pre_notes_gate",
    "first_notes",
    "after_20261030065649",
    "after_20261030074635",
    "after_20261030081321",
    "after_20261031100000",
    "after_20261031110000",
    "after_20261031130000",
    "after_20261031142025",
}


def psql(query):
    command = [
        "psql",
        DB_URL,
        "--set=ON_ERROR_STOP=1",
        "--tuples-only",
        "--no-align",
        "--command=" + query,
    ]
    if PSQL_CONTAINER:
        command = [
            "docker",
            "exec",
            PSQL_CONTAINER,
            "psql",
            "-U",
            "postgres",
            "-d",
            "postgres",
            "--set=ON_ERROR_STOP=1",
            "--tuples-only",
            "--no-align",
            "--command=" + query,
        ]
    proc = subprocess.run(
        command,
        check=True,
        capture_output=True,
        text=True,
    )
    return proc.stdout.strip()


def require_disposable():
    if DISPOSABLE_MODE == "ci":
        if os.getenv("GITHUB_ACTIONS") != "true" or DB_URL != CI_DB_URL:
            raise RuntimeError("Refuse Routine Notes gate test outside exact disposable Database CI")
    elif DISPOSABLE_MODE == "local":
        parsed_db = urllib.parse.urlparse(DB_URL)
        if parsed_db.hostname not in ("127.0.0.1", "localhost") or parsed_db.port in (None, 54322):
            raise RuntimeError("Local mode requires a non-Supabase loopback disposable database port")
        if not API_URL.startswith("http://127.0.0.1:"):
            raise RuntimeError("Local mode requires a loopback disposable PostgREST URL")
        if not PSQL_CONTAINER:
            raise RuntimeError("Local mode requires an explicit disposable psql container")
    else:
        raise RuntimeError("Unknown Routine Notes disposable mode")
    if STAGE and STAGE not in STAGES:
        raise RuntimeError("Unknown Routine Notes staged checkpoint: " + STAGE)
    if STAGE_MIGRATION and not re.fullmatch(r"[0-9]{14}", STAGE_MIGRATION):
        raise RuntimeError("Invalid Routine Notes staged migration version")
    migration_check = (
        "true"
        if STAGE == "baseline"
        else "(select count(*) from supabase_migrations.schema_migrations "
             "where version='%s')=1" % STAGE_MIGRATION
    )
    notes_fixture_check = (
        "true"
        if STAGE in ("baseline", "pre_notes_gate")
        else "(select count(*) from public.user_workout_routine_notes "
             "where id='%s'::uuid)=0" % OWNER_NOTE_ID
    )
    identity = psql(
        """
        select current_database()='postgres'
           and current_user='postgres'
           and to_regclass('supabase_migrations.schema_migrations') is not null
           and %s
           and (select count(*) from auth.users
                where id in ('%s'::uuid,'%s'::uuid))=0
           and (select count(*) from public.user_workout_programs
                where id in ('%s'::uuid,'%s'::uuid))=0
           and (select count(*) from public.user_workout_routines
                where id in ('%s'::uuid,'%s'::uuid))=0
           and %s
        """
        % (
            migration_check,
            OWNER_ID,
            GUEST_ID,
            OWNER_PROGRAM_ID,
            GUEST_PROGRAM_ID,
            OWNER_ROUTINE_ID,
            GUEST_ROUTINE_ID,
            notes_fixture_check,
        )
    )
    if identity != "t":
        raise RuntimeError("Disposable CI identity, migration, or fixture isolation failed")


def auth_fixture():
    fixture_sql = """
        insert into auth.users (id,email,is_anonymous) values
          ('%s'::uuid,'tnyx-81-owner@example.test',false),
          ('%s'::uuid,'tnyx-81-guest@example.test',false);
        insert into public.user_workout_programs (id,user_id,name) values
          ('%s'::uuid,'%s'::uuid,'TNYX-81 Owner Program'),
          ('%s'::uuid,'%s'::uuid,'TNYX-81 Guest Program');
        insert into public.user_workout_routines (id,user_id,program_id,name) values
          ('%s'::uuid,'%s'::uuid,'%s'::uuid,'TNYX-81 Owner Routine'),
          ('%s'::uuid,'%s'::uuid,'%s'::uuid,'TNYX-81 Guest Routine');
        """
    if notes_exist():
        fixture_sql += """
        insert into public.user_workout_routine_notes
          (id,user_id,routine_id,note_type,body)
        values
          ('%s'::uuid,'%s'::uuid,'%s'::uuid,'pinned_routine','TNYX-81 owner fixture');
        """ % (OWNER_NOTE_ID, OWNER_ID, OWNER_ROUTINE_ID)
    psql(
        fixture_sql
        % (
            OWNER_ID,
            GUEST_ID,
            OWNER_PROGRAM_ID,
            OWNER_ID,
            GUEST_PROGRAM_ID,
            GUEST_ID,
            OWNER_ROUTINE_ID,
            OWNER_ID,
            OWNER_PROGRAM_ID,
            GUEST_ROUTINE_ID,
            GUEST_ID,
            GUEST_PROGRAM_ID,
        )
    )
    if psql(
        "select (select count(*) from public.users where id in ('%s'::uuid,'%s'::uuid))=2"
        % (OWNER_ID, GUEST_ID)
    ) != "t":
        raise RuntimeError("Expected Auth trigger/owner fixture rows were not created")


def b64(value):
    return base64.urlsafe_b64encode(value).decode("ascii").rstrip("=")


def token(uid):
    header = b64(json.dumps({"alg": "HS256", "typ": "JWT"}, separators=(",", ":")).encode())
    claims = {
        "sub": uid,
        "role": "authenticated",
        "aud": "authenticated",
        "exp": int(time.time()) + 600,
        "iat": int(time.time()),
    }
    payload = b64(json.dumps(claims, separators=(",", ":")).encode())
    signed = (header + "." + payload).encode()
    signature = b64(hmac.new(TEST_JWT_SECRET.encode(), signed, hashlib.sha256).digest())
    return header + "." + payload + "." + signature


def request(path, method="GET", payload=None, jwt=None):
    data = None if payload is None else json.dumps(payload).encode()
    headers = {"Accept": "application/json"}
    if data is not None:
        headers["Content-Type"] = "application/json"
    if jwt:
        headers["Authorization"] = "Bearer " + jwt
    req = urllib.request.Request(API_URL + path, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=10) as result:
            status, raw = result.status, result.read()
    except urllib.error.HTTPError as exc:
        status, raw = exc.code, exc.read()
    try:
        obj = json.loads(raw) if raw else None
    except (ValueError, UnicodeDecodeError):
        obj = {"_raw": raw.decode("utf-8", errors="replace")}
    if isinstance(obj, dict):
        code = str(obj.get("code", ""))
        message = str(obj.get("message", ""))
    else:
        code, message = "", ""
    return status, code, message, obj


def print_result(label, result):
    status, code, message, _ = result
    print("PASS %s -> HTTP %d code=%s message=%s" % (label, status, code, message), flush=True)


def expect(label, result, predicate):
    if not predicate(result):
        status, code, message, obj = result
        raise AssertionError(
            "%s: got HTTP %d code=%s message=%s body=%r" %
            (label, status, code, message, obj)
        )
    print_result(label, result)


def expect_code(label, result, status, code):
    expect(label, result, lambda value: value[0] == status and value[1] == code)


def expect_status(label, result, status):
    expect(label, result, lambda value: value[0] == status)


def expect_embedded_notes_empty(label, result):
    expect(
        label,
        result,
        lambda value: value[0] == 200
        and isinstance(value[3], list)
        and len(value[3]) == 1
        and all(
            isinstance(row, dict)
            and row.get("user_workout_routine_notes") == []
            for row in value[3]
        ),
    )


def set_gate(state):
    if state == "missing":
        psql("delete from private.routine_notes_data_api_gate_state where gate_key='routine_notes'")
    elif state is None:
        psql(
            "update private.routine_notes_data_api_gate_state "
            "set gate_state=null where gate_key='routine_notes'"
        )
    else:
        psql(
            "update private.routine_notes_data_api_gate_state "
            "set gate_state='%s' where gate_key='routine_notes'" % state
        )


def restore_gate():
    psql(
        "insert into private.routine_notes_data_api_gate_state(gate_key,gate_state) "
        "values ('routine_notes','disabled') "
        "on conflict (gate_key) do update set gate_state='disabled'"
    )


def notify_config():
    psql("select pg_notify('pgrst','reload config')")


def set_hook(name):
    psql(
        "alter role authenticator set pgrst.db_pre_request='%s'" % name
    )
    notify_config()


def notes_exist():
    return psql(
        "select to_regclass('public.user_workout_routine_notes') is not null"
    ) == "t"


def launch_postgrest(pre_request="private.routine_notes_data_api_gate"):
    command = [
        "docker",
        "run",
        "--rm",
        "-d",
    ]
    if DISPOSABLE_MODE == "local":
        command.extend(["-p", API_PORT + ":" + API_PORT])
    else:
        command.append("--network=host")
    command.extend([
        "--name",
        CONTAINER,
        "-e",
        "PGRST_DB_URI=" + POSTGREST_DB_URI,
        "-e",
        "PGRST_DB_ANON_ROLE=anon",
        "-e",
        "PGRST_DB_SCHEMAS=public",
        # CI connects PostgREST with the disposable postgres URI for
        # fixture isolation; local mode uses an explicit host-gateway URI.
        # The migration's authenticator role setting is asserted separately
        # in the catalog test and remains the hosted configuration path.
        "-e",
        "PGRST_SERVER_HOST=0.0.0.0" if DISPOSABLE_MODE == "local" else "PGRST_SERVER_HOST=127.0.0.1",
        "-e",
        "PGRST_SERVER_PORT=" + API_PORT,
        "-e",
        "PGRST_JWT_SECRET=" + TEST_JWT_SECRET,
        "--add-host",
        "host.docker.internal:host-gateway",
    ])
    if pre_request:
        command.extend(["-e", "PGRST_DB_PRE_REQUEST=" + pre_request])
    command.append("postgrest/postgrest:v12.2.12")
    proc = subprocess.run(
        command,
        capture_output=True,
        text=True,
        check=True,
    )
    print("Started disposable PostgREST v12.2.12 " + proc.stdout.strip()[:16], flush=True)
    for _ in range(80):
        try:
            with urllib.request.urlopen(API_URL + "/", timeout=2) as result:
                if result.status != 503:
                    return
        except urllib.error.HTTPError as exc:
            if exc.code != 503:
                return
        except (urllib.error.URLError, TimeoutError):
            pass
        time.sleep(0.5)
    raise RuntimeError("Disposable PostgREST HTTP readiness timeout")


def stop_postgrest():
    result = subprocess.run(
        ["docker", "rm", "-f", CONTAINER],
        check=False,
        capture_output=True,
        text=True,
    )
    if result.returncode and "No such container" not in result.stderr:
        raise RuntimeError("Disposable PostgREST cleanup failed: " + result.stderr.strip())


def assert_disabled(owner_jwt):
    expect_code(
        "disabled owner Notes table",
        request(NOTE_PATH + OWNER_ID, jwt=owner_jwt),
        403,
        "routine_notes_data_api_disabled",
    )
    expect_code(
        "disabled owner Notes HEAD",
        request(NOTE_PATH + OWNER_ID, method="HEAD", jwt=owner_jwt),
        403,
        "",
    )
    expect_code(
        "disabled anonymous Notes table",
        request(NOTE_PATH + OWNER_ID),
        403,
        "routine_notes_data_api_disabled",
    )
    payload = {
        "p_operation": "create",
        "p_note_id": "a8100000-0000-4000-8000-000000000102",
        "p_routine_id": OWNER_ROUTINE_ID,
        "p_exercise_ref": None,
        "p_note_type": "pinned_routine",
        "p_body": "disabled path",
        "p_expected_revision": None,
        "p_mutation_id": "a8100000-0000-4000-8000-000000000202",
    }
    for path in RPC_PATHS[:2]:
        expect_code(
            "disabled %s" % path,
            request(path, method="POST", payload=payload, jwt=owner_jwt),
            403,
            "routine_notes_data_api_disabled",
        )
    expect_code(
        "disabled reconcile RPC",
        request(
            RPC_PATHS[2],
            method="POST",
            payload={"p_mutation_id": "a8100000-0000-4000-8000-000000000201"},
            jwt=owner_jwt,
        ),
        403,
        "routine_notes_data_api_disabled",
    )
    expect_embedded_notes_empty(
        "disabled parent-resource Notes embedding",
        request(EMBEDDED_NOTE_PATH + OWNER_ROUTINE_ID, jwt=owner_jwt),
    )
    expect_embedded_notes_empty(
        "disabled filtered parent-resource Notes embedding",
        request(
            EMBEDDED_FILTERED_NOTE_PATH
            + OWNER_ROUTINE_ID
            + "&user_workout_routine_notes.id=eq."
            + OWNER_NOTE_ID,
            jwt=owner_jwt,
        ),
    )
    for path in (
        "/user_nutrition_profiles?select=user_id&user_id=eq." + OWNER_ID,
        "/user_workout_programs?select=id&user_id=eq." + OWNER_ID,
        "/user_profiles?select=user_id&user_id=eq." + OWNER_ID,
    ):
        expect_status("disabled non-Notes %s" % path.split("?")[0], request(path, jwt=owner_jwt), 200)


def assert_staged_disabled(owner_jwt):
    if notes_exist():
        expect_code(
            "staged disabled direct Notes table",
            request(NOTE_PATH + OWNER_ID, jwt=owner_jwt),
            403,
            "routine_notes_data_api_disabled",
        )
        expect_embedded_notes_empty(
            "staged disabled parent-resource Notes embedding",
            request(EMBEDDED_NOTE_PATH + OWNER_ROUTINE_ID, jwt=owner_jwt),
        )
    else:
        expect(
            "staged pre-Notes direct Notes table is unavailable",
            request(NOTE_PATH + OWNER_ID, jwt=owner_jwt),
            lambda value: value[0] != 200,
        )
        expect(
            "staged pre-Notes Notes embedding is unavailable",
            request(EMBEDDED_NOTE_PATH + OWNER_ROUTINE_ID, jwt=owner_jwt),
            lambda value: value[0] != 200,
        )
    for path in (
        "/user_nutrition_profiles?select=user_id&user_id=eq." + OWNER_ID,
        "/user_workout_programs?select=id&user_id=eq." + OWNER_ID,
        "/user_profiles?select=user_id&user_id=eq." + OWNER_ID,
    ):
        expect_status("staged non-Notes %s" % path.split("?")[0], request(path, jwt=owner_jwt), 200)


def assert_enabled(owner_jwt, guest_jwt):
    owner_result = request(NOTE_PATH + OWNER_ID, jwt=owner_jwt)
    expect(
        "enabled owner Notes table",
        owner_result,
        lambda value: value[0] == 200
        and isinstance(value[3], list)
        and len(value[3]) == 1
        and value[3][0].get("id") == OWNER_NOTE_ID,
    )
    expect(
        "enabled owner parent-resource Notes embedding",
        request(EMBEDDED_NOTE_PATH + OWNER_ROUTINE_ID, jwt=owner_jwt),
        lambda value: value[0] == 200
        and isinstance(value[3], list)
        and len(value[3]) == 1
        and isinstance(value[3][0].get("user_workout_routine_notes"), list)
        and len(value[3][0]["user_workout_routine_notes"]) == 1
        and value[3][0]["user_workout_routine_notes"][0].get("id") == OWNER_NOTE_ID,
    )
    expect(
        "enabled owner filtered parent-resource Notes embedding",
        request(
            EMBEDDED_FILTERED_NOTE_PATH
            + OWNER_ROUTINE_ID
            + "&user_workout_routine_notes.id=eq."
            + OWNER_NOTE_ID,
            jwt=owner_jwt,
        ),
        lambda value: value[0] == 200
        and isinstance(value[3], list)
        and len(value[3]) == 1
        and len(value[3][0].get("user_workout_routine_notes", [])) == 1,
    )
    guest_result = request(NOTE_PATH + OWNER_ID, jwt=guest_jwt)
    expect(
        "enabled guest owner-scoped Notes table",
        guest_result,
        lambda value: value[0] == 200
        and isinstance(value[3], list)
        and len(value[3]) == 0,
    )
    expect_code(
        "enabled anonymous Notes table remains unauthenticated",
        request(NOTE_PATH + OWNER_ID),
        401,
        "42501",
    )

    create_payload = {
        "p_operation": "create",
        "p_note_id": "a8100000-0000-4000-8000-000000000102",
        "p_routine_id": OWNER_ROUTINE_ID,
        "p_exercise_ref": None,
        "p_note_type": "pinned_routine",
        "p_body": "enabled path",
        "p_expected_revision": None,
        "p_mutation_id": "a8100000-0000-4000-8000-000000000202",
    }
    expect_status(
        "enabled owner current mutation RPC",
        request(RPC_PATHS[0], method="POST", payload=create_payload, jwt=owner_jwt),
        200,
    )
    expect_status(
        "enabled owner reconciliation RPC",
        request(
            RPC_PATHS[2],
            method="POST",
            payload={"p_mutation_id": create_payload["p_mutation_id"]},
            jwt=owner_jwt,
        ),
        200,
    )
    expect_code(
        "enabled legacy RPC remains ACL denied after migration #6",
        request(RPC_PATHS[1], method="POST", payload=create_payload, jwt=owner_jwt),
        403,
        "42501",
    )

    cross_owner_update = dict(create_payload)
    cross_owner_update.update(
        {
            "p_operation": "update",
            "p_note_id": OWNER_NOTE_ID,
            "p_routine_id": None,
            "p_exercise_ref": None,
            "p_note_type": None,
            "p_expected_revision": 0,
            "p_mutation_id": "a8100000-0000-4000-8000-000000000203",
            "p_body": "cross owner attempt",
        }
    )
    expect(
        "enabled guest cross-owner mutation",
        request(RPC_PATHS[0], method="POST", payload=cross_owner_update, jwt=guest_jwt),
        lambda value: value[0] == 500
        and value[1] == "P0002"
        and value[2] == "routine_note_not_found",
    )

    for path in (
        "/user_nutrition_profiles?select=user_id&user_id=eq." + OWNER_ID,
        "/user_workout_programs?select=id&user_id=eq." + OWNER_ID,
        "/user_profiles?select=user_id&user_id=eq." + OWNER_ID,
    ):
        expect_status("enabled non-Notes %s" % path.split("?")[0], request(path, jwt=owner_jwt), 200)


def assert_fail_closed(owner_jwt):
    for state in ("unknown", None, "missing"):
        set_gate(state)
        expect_code(
            "fail-closed gate state %r" % state,
            request(NOTE_PATH + OWNER_ID, jwt=owner_jwt),
            403,
            "routine_notes_data_api_disabled",
        )
        expect_embedded_notes_empty(
            "fail-closed embedded gate state %r" % state,
            request(EMBEDDED_NOTE_PATH + OWNER_ROUTINE_ID, jwt=owner_jwt),
        )
    restore_gate()
    expect_code(
        "restored disabled state",
        request(NOTE_PATH + OWNER_ID, jwt=owner_jwt),
        403,
        "routine_notes_data_api_disabled",
    )


def assert_exact_path_behavior(owner_jwt):
    for path in (
        "/user_workout_routine_notes/",
        "/USER_WORKOUT_ROUTINE_NOTES?select=id",
        "/user_workout_routine_notes%2F?select=id",
    ):
        result = request(path, jwt=owner_jwt)
        expect(
            "non-exact Notes path %s" % path,
            result,
            lambda value: value[0] != 200,
        )


def assert_config_failure_and_recovery(owner_jwt):
    set_hook("private.missing_routine_notes_data_api_gate")
    notify_config()
    # The CI harness connects with the disposable postgres role, so its
    # explicit PGRST_DB_PRE_REQUEST environment value is changed by restarting
    # only this throwaway PostgREST process. The migration's authenticator role
    # setting remains separately asserted in the catalog test.
    stop_postgrest()
    launch_postgrest("private.missing_routine_notes_data_api_gate")
    result = request("/user_workout_programs?select=id&user_id=eq." + OWNER_ID, jwt=owner_jwt)
    expect_code("missing hook fails closed for non-Notes Data API", result, 404, "42883")

    set_hook("private.routine_notes_data_api_gate")
    restore_gate()
    recovered = None
    notify_config()
    stop_postgrest()
    launch_postgrest()
    recovered = request("/user_workout_programs?select=id&user_id=eq." + OWNER_ID, jwt=owner_jwt)
    expect_status("restored hook and config reload", recovered, 200)
    expect_code(
        "restored hook preserves disabled Notes denial",
        request(NOTE_PATH + OWNER_ID, jwt=owner_jwt),
        403,
        "routine_notes_data_api_disabled",
    )


def main():
    require_disposable()
    fixture_created = False
    try:
        fixture_created = True
        auth_fixture()
        launch_postgrest(None if STAGE == "baseline" else "private.routine_notes_data_api_gate")
        owner_jwt = token(OWNER_ID)
        guest_jwt = token(GUEST_ID)

        if STAGE:
            if STAGE != "baseline":
                restore_gate()
            assert_staged_disabled(owner_jwt)
        else:
            restore_gate()
            assert_disabled(owner_jwt)

        if not STAGE:
            set_gate("enabled")
            assert_enabled(owner_jwt, guest_jwt)
            set_gate("disabled")
            assert_fail_closed(owner_jwt)
            assert_exact_path_behavior(owner_jwt)
            assert_config_failure_and_recovery(owner_jwt)
        print("PASS: TNYX-81 disposable Routine Notes gate HTTP matrix", flush=True)
    finally:
        try:
            if STAGE != "baseline":
                restore_gate()
                set_hook("private.routine_notes_data_api_gate")
        except Exception as exc:
            print("CRITICAL: gate/config restore failed: %s" % exc, file=sys.stderr)
            raise
        finally:
            try:
                stop_postgrest()
            finally:
                if fixture_created:
                    psql(
                        "delete from auth.users where id in ('%s'::uuid,'%s'::uuid)"
                        % (OWNER_ID, GUEST_ID)
                    )
                    if psql(
                        "select count(*) from auth.users where id in ('%s'::uuid,'%s'::uuid)"
                        % (OWNER_ID, GUEST_ID)
                    ) != "0":
                        raise AssertionError("Auth fixture cleanup left rows behind")


if __name__ == "__main__":
    main()
