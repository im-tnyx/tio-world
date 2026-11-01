# Routine Notes Production Deployment Approval Packet

**Status:** Final 81-migration architecture reconciled; production execution is not authorized
**Primary owner:** Product owner / Supabase database owner for approvals
**Implementation owner:** None; implementation and migrations are merged
**Affected platforms:** Supabase Postgres, deployment operations, task documentation

## Owner Approval and Scope Boundary

**Approval status:** Awaiting explicit owner decisions A–G below.
**Approval evidence:** This packet records the current read-only hosted review, historical disposable CLI `PGPASSFILE` qualification for 72→80, and the current disposable CLI 72→81 qualification using synthetic local credentials; none is production deployment evidence.
**R1 owner scope decision:** The owner states that the current hosted dataset is testing-only. Backup/recovery evidence is therefore deferred for this bounded test-data-only scope; this is not a recovery-readiness pass and the canonical recovery gate remains mandatory before real-user or production data is introduced.
**Approved scope:** Prepare an evidence-based deployment decision packet for the nine pending migrations: the pre-Notes gate followed by the eight merged Routine Notes persistence migrations.
**Explicit non-changes:** No hosted migration, extension, role, schedule, credential, authentication, or production-data change; no custom runner, CI change, issue/Linear status change, or protected-`main` mutation. This packet is being delivered through a separate documentation-only PR; its review does not authorize production operations.

## 1. Discovery

### User outcome

Make a safe, reviewable owner decision on deploying the nine pending Routine Notes migrations and their 30-day receipt cleanup to hosted Supabase project `tio-world` (`oykupyiitspujzpwwvuj`). This packet is not deployment authorization.

### Current verified state — 2026-11-01

| Area | Evidence |
|---|---|
| Repository | `G:\projects\Tio-World`; PR #720 merged at `main@b1b7722cf2cbcf45f90cca0a72da56669bb8e455` from final PR head `4008494063af25c238923810039ee5124d9b3d1e`. This packet is being reconciled on a dedicated documentation branch; disposable test artifacts were removed. |
| PR #717 | Merged at `58b5161879d40d2c44e749a61e078294304d2092`; final PR head `9516c4735be0ea4e99f5384bd50087c8aa406c8d`; independent `im-tio` approved that exact head; all 24 external review threads were resolved. |
| PR #717 checks | Exact-head evidence in the Linear merge handoff: Database CI `41217398025`, Flutter CI `41217398011` (three package shards), Docs Hygiene `41217397988`, attribution `41217397972` — passed. Cursor agents were neutral/unavailable, not passes. |
| PR #718 | Documentation-only PR merged at current `main` HEAD `22f465bf0c3b55fd99bc804e359a5047f4452e23`; exact PR head `5fbd25573e511340102e43573a41786ea3378824`. `im-tio` approved that head; Docs Hygiene run `41226124568` passed. Two review threads are resolved; one is outdated. |
| GitHub #716 | Closed as `completed` on 2026-10-31. Its original issue description still contains a pre-merge/local-branch report; use the post-merge closure comment `6546518502` and merged PR/archive evidence as the final checkpoint. |
| PR #719 documentation review | Merged before PR #720; retained as historical deployment-packet documentation context. |
| PR #720 security gate | Merged at `main@b1b7722cf2cbcf45f90cca0a72da56669bb8e455`; final PR head `4008494063af25c238923810039ee5124d9b3d1e`; independent `im-tio` approval, five resolved security threads, Supabase Database CI `41305474738`, Docs Hygiene CI `41305474867`. No hosted deployment or activation occurred. |
| Linear | [TNYX-81](https://linear.app/tnyx/issue/TNYX-81) remains **Backlog** for broader W4. It is blocked by TNYX-80 and TNYX-78 and blocks later W5/W6 work. No child issue could be created earlier because the workspace issue limit was reached; this packet creates no duplicate issue and changes no tracker status. Attached handoff: [PR #717 merge handoff](https://linear.app/tnyx/document/pr-717-routineexercise-notes-persistence-merge-handoff-6df1105cfb3f). |
| Hosted migrations | Read-only Supabase refresh returned exactly **72** applied migrations, ending at `20261028110000_grant_authenticated_program_delete_rpc`. The checked-in first 72 versions/names match; **nine** migrations are pending: the pre-Notes gate plus eight Notes migrations. Target ledger after the approved sequence is **81**. |
| Hosted database | Project is `ACTIVE_HEALTHY`, region `ap-south-1`, PostgreSQL `17.6.1.155` (engine 17). |
| Hosted `pg_cron` | Version `1.6.4` is available, not installed; no `cron` schema or jobs exist. `cron.host=localhost`, `cron.use_background_workers=off`, timezone `UTC`. `pg_cron` is present in `supautils.privileged_extensions`; this supports the managed `postgres` role's extension-creation path, but actual installation was not attempted. |
| Hosted roles | `postgres` is login, `CREATEROLE`, `CREATEDB`, `BYPASSRLS`, but not superuser; `supabase_admin` is superuser and is not the migration identity to use. The migration-created cleanup roles do not exist yet. |
| Hosted scheduler authentication | `postgres` cannot read `pg_hba_file_rules` (SQLSTATE `42501`); effective localhost authentication for the future scheduler LOGIN role is therefore **not verified**. The migration creates that role without a password. Local Docker trust-mode success is not hosted authentication evidence. |
| Hosted Security Advisor | Read-only refresh observed `2026-10-31T19:43:33Z`: INFO `rls_enabled_no_policy` count 1 for `private.deleted_user_workout_routine_ids`; WARN `authenticated_security_definer_function_executable` count 14; WARN `auth_leaked_password_protection` count 1. These predate Notes deployment and contain no Notes-specific findings. |
| Current main CI | GitHub Actions lookup for merge commit `22f465bf0c3b55fd99bc804e359a5047f4452e23` returned no PR-triggered workflow runs. PR #718 Docs Hygiene CI `41226124568` passed on its exact head; PR #717 Database/Flutter/Docs Hygiene checks passed on its exact PR head as listed above. No check result is inferred for the current main merge commit. |

The canonical Supabase strategy and schema inventory are reconciled by this
documentation closure to distinguish the read-only hosted 72-migration prefix
from the nine pending Notes migrations. No hosted write is implied.

### Pending migrations, in order

The hosted baseline is 72 migrations. The deployment target is 81: the
pre-Notes gate is applied first, followed by the eight Notes migrations below.
In the ordered procedure, `G0` means the pre-Notes gate and `#1`–`#8` retain
their meaning as the eight Notes migrations.

**G0.** `20261028120000_install_routine_notes_data_api_gate.sql`

1. `20261029120000_create_user_workout_routine_notes.sql` — restrictive
   Notes SELECT policy is installed atomically with the table, grant and
   owner-scoped RLS.
2. `20261030065649_routine_note_mutation_result_snapshot.sql`
3. `20261030074635_routine_note_contract_alignment.sql`
4. `20261030081321_routine_note_legacy_receipt_gate.sql`
5. `20261031100000_routine_note_rpc_normalization_and_user_index.sql`
6. `20261031110000_routine_note_receipt_retention.sql`
7. `20261031130000_routine_note_receipt_scheduled_cleanup.sql`
8. `20261031142025_routine_note_owner_scoped_identity.sql`

The current migration #7 is not an extension-only step: in one migration it creates/uses `pg_cron`, creates the cleanup owner and LOGIN scheduler roles, establishes narrowly scoped helper access, and registers both scheduled jobs. Its transaction cannot be split into “install now, schedule later” without changing the merged SQL, which is out of scope.

### Runtime behavior boundary

PR #717 adds durable persistence/repository/RPC behavior, not Notes UI or Routine Create/Edit integration. Deployment alone does not enable a visible Notes feature. Preserve the approved scope: personal Routine Notes by `RoutineId`; personal Exercise Notes by authenticated user plus canonical `ExerciseRef`, shared across that same user’s Routines; cross-user access denied. Limits are five active Notes per canonical scope and 50 active Notes per user. Full mutation snapshots are retained for 30 days from `created_at`; expiry redacts the Note body while preserving `mutation_id`, `request_hash` and the permanent tombstone.

## 2. Runner Decision

### Recommendation

The previously qualified Supabase CLI **v2.114.0 direct `db push` path using a passwordless URL and protected `PGPASSFILE` covered the 72→80 disposable workflow**. Separately, the current **v2.114.0 cumulative 72→81 CLI qualification passed on isolated disposable infrastructure**: one-migration dry-run/apply stages, retry/idempotency, rollback, interruption recovery and the Notes SQL/RLS/Data API gate tests all passed. The current 72→81 run used a synthetic local credential and local `sslmode=disable`; it does not qualify production endpoint authentication, TLS, `PGPASSFILE` delivery or deployment approval. The official release page marks **Supabase CLI v2.122.0** (released 2026-10-23) as Latest, but its exact path failed at Notes migration #2 with the transaction-block `LOCK TABLE` error. Do not implement a custom runner.

Qualified v2.114.0 Windows x64 artifact (production selection still pending):

```text
Version: 2.114.0
Release archive: supabase_2.114.0_windows_amd64.zip
Archive SHA256: 848d0eacc6f4f7722f9874eaa0498e0ac674236907e5f70b44f1dac059b27b68
Extracted supabase.exe SHA256: af90dcd1401f3f98bed6f9f5f3bf7b07e1ce2501a42265ce97007a2d1b026209
Release: https://github.com/supabase/cli/releases/tag/v2.114.0
```

The archive checksum is the official release asset checksum; the extracted executable hash was independently recomputed locally and matches the upstream v2.114.0 Windows binary record. Keep CLI versions side-by-side and verify both the release archive and extracted executable before an approved run; do not replace another CLI installation. See the [upstream Windows asset/hash record](https://github.com/supabase/cli/issues/6174). The [v2.122.0 release](https://github.com/supabase/cli/releases/tag/v2.122.0) includes TLS propagation fixes for linked `db push` and dump paths; this does not establish that it fixes the `LOCK TABLE` regression or that this repository's exact direct-URL migration path is qualified.

The release page dates v2.114.0 to 2026-08-12 and listed 899 commits to `develop` at review time. It is therefore an older candidate on 2026-11-01, not an automatically preferred long-term pin.

### Disposable qualification evidence

All tests below used isolated disposable databases and are not hosted deployment evidence:

- Minimal `CREATE TABLE` → `LOCK TABLE` → `ALTER TABLE` using CLI `2.114.0`: **PASS**, no SQLSTATE `25P01`.
- Previously qualified CLI `2.114.0` 72→80 disposable replay using passwordless direct URL plus ACL-restricted `PGPASSFILE`: **PASS**; this is historical runner evidence and does not cover the current G0+eight-Notes 81-migration sequence.
- Current PR #720 staged SQL/HTTP qualification: **PASS** across ten checkpoints and final 81-migration source replay; the harness uses disposable `psql` replay and ledger repair, not cumulative CLI `db push`.
- Exact cumulative 72→81 CLI `db push --dry-run`, one-pending-migration preview, apply, failure retry and interrupted retry qualification with CLI `2.114.0`: **PASS on isolated disposable infrastructure**. This does not qualify production endpoint authentication or TLS.
- CLI `2.114.0` ledger representation: **PASS**, expected Supabase `schema_migrations` records; no missing/duplicate version and no empty statement arrays.
- Historical schema parity between `supabase migration up --local` and CLI `2.114.0` `supabase db push --db-url`: **PASS** after normalizing random `pg_dump` restrict tokens; normalized hash `2CEED53D5CE940731E2E74D35BA41516EF01E847DDF7B49BC83571DC6DABC0DF`. This does not qualify the production endpoint, TLS or credential path.
- Notes SQL/RLS/receipt-retention matrix and both disposable concurrency harnesses: **PASS** against the `db push` replay database using temporary script copies with only the local disposable endpoint/credential guard adapted. Repository test scripts were not changed. Coverage included owner isolation, cross-owner denial, duplicate/expired retry, concurrent mutation, cleanup batching, concurrent cleanup/reconciliation, lock serialization and cleanup failure/recovery.
- Failed migration rollback and corrected retry with CLI `2.114.0` using a synthetic local credential: **PASS**; DDL and ledger entry rolled back together, corrected retry produced exactly one entry, and subsequent push was a no-op.
- Interrupted CLI `2.114.0` recovery using the same synthetic local path: **PASS**; Ctrl+C during a disposable migration left neither DDL nor ledger row, and a same-version retry completed once.
- Credential boundary: historical passwordless URL + ACL-restricted `PGPASSFILE` evidence remains limited to 72→80. The current 72→81 qualification used only synthetic disposable credentials and did not use a production credential, production endpoint, production TLS or production `PGPASSFILE`.
- Scheduler probe: the disposable cron expiry job recorded `succeeded`; local loopback trust authentication is not evidence of hosted scheduler authentication. Hosted LOGIN-role auth remains **unverified**.
- Initial fixture authentication mismatch was corrected only inside the disposable database through local socket SQL streamed via stdin; it was not a CLI limitation and did not involve a hosted credential.

Official references: [CLI migration deployment](https://supabase.com/docs/guides/deployment/database-migrations), [CLI reference](https://supabase.com/docs/reference/cli/global-flags), [CLI v2.114.0 release](https://github.com/supabase/cli/releases/tag/v2.114.0), [latest stable CLI v2.122.0 release](https://github.com/supabase/cli/releases/tag/v2.122.0), [CLI password authentication guidance](https://supabase.com/kb/troubleshooting/supabase-cli-failed-sasl-auth-or-invalid-scram-server-final-message), [Postgres connection methods](https://supabase.com/docs/guides/database/connecting-to-postgres), [pooling/connection limits](https://supabase.com/docs/guides/database/connecting-to-postgres/pooling-and-limits), [PostgreSQL 17 password-file guidance](https://www.postgresql.org/docs/17/libpq-pgpass.html), and [PostgreSQL 17 environment-variable guidance](https://www.postgresql.org/docs/17/libpq-envars.html).

### Why not simply use the current CI pin

`.github/workflows/supabase-db-ci.yml` pins CLI `2.116.0`, but its migration replay uses per-file `psql --single-transaction` and then repairs only the disposable CI ledger; it is not the production runner. CLI issue [#6347](https://github.com/supabase/cli/issues/6347) documents the LOCK TABLE transaction-block regression from 2.115 onward in the CLI's pipelined migration path. The repository’s CI method does not prove that `db push` at 2.116.0 is safe for this migration set. The newer stable v2.122.0 has not been tested against this repo's LOCK migrations or full replay in this qualification. No CI pin change is proposed.

CLI issue [#6236](https://github.com/supabase/cli/issues/6236) describes a v2.114 passwordless `--linked` login-role path that can fail after `RESET ROLE`; it closed through PR #6246. The disposable qualification used the direct `--db-url` password-authenticated path, not linked/passwordless production auth. Do not use a passwordless linked path without separately qualifying that exact path.

### Proposed connection, identity and commands

- Use the direct PostgreSQL endpoint for project `oykupyiitspujzpwwvuj` over TLS, not a transaction-mode pooler. Supabase direct connections require IPv6 unless the project has an IPv4 add-on. If the operator's network cannot reach the direct endpoint, a documented session-mode pooler can be considered only after separately qualifying that exact path; do not silently switch connection modes. The CLI accepts `--db-url`.
- The migration identity is the managed `postgres` role. It is not least-privilege in an absolute sense (`BYPASSRLS`, role creation and broad DDL); it is the least-privileged tested Supabase migration principal that can carry this migration’s role creation, ownership and extension work. Do not use `supabase_admin`, a service-role API key, or an application role.
- The required deployment capabilities include the existing managed `postgres` role’s schema/table/function DDL and grants, role creation/membership and `SET ROLE`, function ownership changes, plus the Supabase allowlisted `pg_cron` extension path. A narrower custom deployment role has not been qualified.
- Keep the password out of `--db-url`. The passwordless URL + ACL-restricted `PGPASSFILE` path passed the historical 72→80 disposable `db push` qualification; it does not qualify the current production endpoint path. `SUPABASE_DB_PASSWORD` was not honored by CLI v2.114.0 with explicit `--db-url`; PostgreSQL discourages `PGPASSWORD` for secret delivery. Production still requires an owner-approved endpoint, encrypted ephemeral file location, verified operator-only ACL, controlled `PGPASSFILE` injection and a production-compatible authentication check. The non-secret URL and passfile path remain visible to the process; neither contains the password.
- **Remaining production selection:** choose and explicitly pin a supported production CLI version after considering v2.114.0's age, the current official release and repository CI's v2.116.0 pin. v2.122.0's exact migration path failed for this repository. Production endpoint reachability, TLS certificate/identity behavior and deployment credential/authentication compatibility remain unverified. Do not use production credentials for disposable tests.

Run interactively, with a human present. The cumulative 72→81 CLI sequence is **qualified on disposable infrastructure with v2.114.0**, while hosted execution remains separately unauthorized. Before any production window, prepare `Stage-G0` for the pre-Notes gate, then `Stage-A1` through `Stage-A7` for Notes migrations #1–#7 and the final stage for Notes #8. Verify every included migration hash against the approved deployment SHA. Each `db push` must have exactly one intended pending migration, so the operator can verify the gate before and after each committed migration. Run the standard CLI command from the selected stage directory; this packages approved files for the official CLI and does not add a custom runner. The URL must be passwordless; set `PGPASSFILE` only to a verified operator-only temporary file:

```powershell
$Cli = '<versioned side-by-side supabase.exe>'
$DbUrl = 'postgresql://postgres@<approved-endpoint>:5432/postgres?sslmode=require'
$env:PGPASSFILE = '<operator-only encrypted temporary path>\pgpass.conf'
# File format: <endpoint-host>:5432:postgres:postgres:<secret password>
& $Cli --version
& $Cli migration list --db-url $DbUrl
# For G0 and each cumulative Notes stage, require exactly the intended migration pending.
& $Cli db push --db-url $DbUrl --dry-run --skip-vault
# Apply only that one pending migration, then verify the server-side Notes gate.
& $Cli db push --db-url $DbUrl --skip-vault
# After Notes migration #7, stop and verify scheduler authentication and a successful expiry-job run.
# After scheduler gates pass, obtain separate explicit owner authorization for Notes migration #8.
# Then select the final stage and require only Notes migration #8 pending.
& $Cli db push --db-url $DbUrl --dry-run --skip-vault
# Apply Notes #8, then verify the access gate and security acceptance before any release.
& $Cli db push --db-url $DbUrl --skip-vault
```

Never echo password-file contents or include them in diagnostics. Verify the file's explicit operator-only ACL and encrypted volume before use; clear `PGPASSFILE` and remove the temporary file after the process exits. The disposable test showed `SUPABASE_DB_PASSWORD` is not honored by CLI v2.114.0 when an explicit `--db-url` is supplied; do not use that combination. Do not run the final command from this packet. The disposable `db push` run displayed an interactive `[Y/n]` prompt; inspect the target and prompt rather than making this unattended. Do not use `migration repair` to fake deployment history.

### Mandatory Notes API access gate — hard precondition

PR #720 implements the approved server-side gate in source, but it is not
deployed to hosted Supabase. The pre-Notes migration `G0` installs the private
default-disabled PostgREST hook; the first Notes migration installs the
restrictive SELECT policy atomically with the table. The canonical [Feature
Rollout policy](../../docs/planning/FEATURE_ROLLOUT.md) still correctly says a
client/UI flag is not an authorization boundary. Hosted deployment must verify
the gate immediately after `G0`, before allowing Notes migration #1, after every
subsequent committed migration, and before any separate Notes activation.

**Do not allow Notes migration #1 until G0 is separately owner-approved, applied and verified effective.** G0 itself is preceded by baseline, owner-approval, backup, credential, operator and deployment-window checks. The gate must block direct Notes table/API and RPC access for authenticated clients, remain effective across every committed intermediate migration (especially Notes migrations #1 and #6), and remain in force through Notes #8 plus the post-migration security acceptance. Recheck the effective gate after each migration commit and stop immediately if it is absent or uncertain. Re-enabling Notes access is a separate explicitly approved release operation after acceptance.

This packet does not activate the control. Its hosted scope, blast radius,
verification method, activation/deactivation steps and recovery still require
the A–G owner decision gates below. A UI flag, an assumption that clients will
not call the RPCs, or a check performed only after all migrations is not a
substitute. No production Notes RPC probe is authorized by this requirement.

## 3. Scheduler and Extension Gate

### Verified architecture

Migration #7 schedules:

- `routine-note-receipt-expiry`: every five minutes; redacts at most 500 expired receipt snapshots per run using `FOR UPDATE SKIP LOCKED`.
- `routine-note-receipt-history`: daily at `03:17` database time (hosted timezone currently UTC); prunes at most 500 successful run-history records older than 90 days and retains failures.

The scheduler has no receipt-table privileges. It gets `USAGE` on `private`/`cron` and EXECUTE on only the cleanup, history-prune, schedule and unschedule functions. The cleanup owner is `NOLOGIN`, non-superuser, non-`BYPASSRLS`; cleanup is `SECURITY DEFINER` with empty `search_path`. The history function is `SECURITY INVOKER` with empty `search_path`. Role membership is intended to be restricted to `postgres` and `SET ROLE`.

### Hosted enablement and first execution plan

Supabase documents enabling Cron through Dashboard → Integrations → Cron Postgres Module; its SQL install path is also documented. Current hosted read-only settings show `pg_cron` on `supautils.privileged_extensions`, so the `postgres` role is expected to be permitted to create it. The actual `CREATE EXTENSION` has not been tested on hosted. [Cron installation](https://supabase.com/docs/guides/cron/install), [Supabase role privileges](https://supabase.com/docs/guides/database/postgres/roles-superuser).

Do not separately create a production probe role/job in this task. The narrow controlled verification is the approved migration deployment itself: `Stage-G0` then Notes #1–#7; Notes #7 creates the real scheduler role and both jobs atomically. Before Notes #8 is made available to the CLI, verify exact owner/name/schedule/command rows in `cron.job`, then observe `cron.job_run_details` for the expiry job’s first `succeeded` row, timestamps and return message. The first expiry run can redact up to 500 actually expired snapshots. Verify history-prune job registration; its scheduled execution is daily. Do not manually invoke cleanup against production receipts as a test. If auth fails or no successful expiry run is observed, stop with the hosted ledger at the actual prefix, deactivate both jobs using the authorized recovery steps below, and keep Notes unavailable; do not select the final Notes #8 stage.

**Unresolved auth:** the future scheduler role is `LOGIN` but migration supplies no password. Hosted `cron.host=localhost` with background workers off indicates the libpq job-connection path; the actual hosted authentication method remains unverified. Hosted HBA rules are not readable to the migration role; local Docker trust-mode success is not evidence. Do not enable broad `trust`, add a password to migration SQL, or expose a credential. No read-only preflight can prove this role will authenticate because the role and jobs do not yet exist. The minimum production verification necessarily includes applying Notes migration #7, which installs the extension, creates roles and registers both real jobs in one transaction; that is a production write and immediately activates cleanup. Before that step, the owner must approve the combined checkpoint and establish a documented, narrow hosted auth path through Supabase's supported controls. After Notes #7 commits, verify effective job identity and first run in `cron.job_run_details`; if authentication fails, stop before Notes #8, deactivate both jobs through `cron.unschedule` using the approved `postgres` operator path, preserve run evidence, and keep Notes access gated. If no narrow supported path is confirmed, do not apply Notes #7; return for separately approved architecture remediation. Do not edit merged migration #7 here.

### Failure monitoring, deactivation and recovery

- Monitor `cron.job_run_details` for failures and missed/late runs; the migration retains failed history. Assign an on-call owner and an alert/check cadence before deploy—no external alerting integration is implemented by this migration.
- Check expired-receipt backlog and oldest eligible `created_at`. At one successful run per five minutes and 500 records per run, nominal drain time is approximately `ceil(backlog / 500) × 5 minutes`; failures, locks and long runs increase it. The migration does not establish a hard maximum expiry lag under arbitrary backlog.
- After authorized deployment, inspect jobs and execution evidence using read-only queries such as:

```sql
select jobid, jobname, username, schedule, command, active
from cron.job
where jobname in ('routine-note-receipt-expiry', 'routine-note-receipt-history')
order by jobname;

select jobid, status, return_message, start_time, end_time
from cron.job_run_details
where jobid in (
  select jobid from cron.job
  where jobname in ('routine-note-receipt-expiry', 'routine-note-receipt-history')
)
order by start_time desc
limit 20;
```

- If deactivation is approved and needed, use the scheduler API, not direct table writes:

```sql
set role routine_note_receipt_cleanup_scheduler;
select cron.unschedule('routine-note-receipt-expiry');
select cron.unschedule('routine-note-receipt-history');
reset role;
```

  Record both return values and verify both rows are absent/inactive. If role authentication prevents this, use a separately authorized `postgres` session with the granted role membership; never broaden Cron/table ACLs to recover.
- If deployment stops after Notes migration #7 but before Notes #8, or a scheduled job fails, stop the deploy, record the actual ledger prefix, inspect the job result and safely deactivate by job name with the granted `cron.unschedule(text)` function under an authorized role. Do not write directly to `cron.job`; Supabase has changed hosted Cron permissions and its supported job API is the cron functions/Dashboard.
- If jobs were unscheduled, a normal `db push` retry will not recreate them because Notes migration #7 is already in the ledger. After a separately approved control-plane change restores scheduler authentication, prove the scheduler `LOGIN` role can establish its supported database session before re-registering anything. Inspect `cron.job` first and register only each missing job from that authenticated scheduler session. The following names, schedules and commands match migration #7; capture each returned job ID, verify the job row, and observe a successful expiry run in `cron.job_run_details` before reopening Notes or proceeding to Notes #8. Do not use `SET ROLE` from `postgres` as a substitute for testing scheduler authentication, and do not register a duplicate when the named job already exists.

```sql
-- Check cron.job first; execute each schedule call only if that job name is absent.
-- Run as the authenticated routine_note_receipt_cleanup_scheduler LOGIN role.
select cron.schedule(
  'routine-note-receipt-expiry',
  '*/5 * * * *',
  'select private.cleanup_expired_user_workout_routine_note_receipts()'
);
select cron.schedule(
  'routine-note-receipt-history',
  '17 3 * * *',
  'select private.prune_routine_note_cleanup_job_history()'
);
```

If the scheduler role still cannot authenticate, do not use these statements as a credential workaround. Preserve failed-run evidence, keep Notes gated, and obtain a separately approved supported authentication remediation. Do not drop `pg_cron` as rollback while jobs exist; disabling the extension deletes all jobs. Dropping the extension is not part of ordinary recovery.
- If schema/data integrity is at risk, stop application access to the affected feature, preserve evidence, and use the approved PITR/restore plan. These are forward-only migrations; do not delete ledger rows or hand-edit production schema as rollback.

## 4. Ordered Nine-Migration Deployment Plan

1. Freeze the deployment SHA, verify the hosted 72-entry baseline, confirm owner approvals and all backup, network, credential, operator and low-traffic prerequisites. Do not require a hosted gate before it is installed.
2. Apply only pre-Notes gate migration `G0` (`20261028120000_install_routine_notes_data_api_gate.sql`) after explicit deployment authorization. Do not apply Notes migration #1 in the same step.
3. Reload PostgREST configuration and verify the hosted hook configuration, private default-disabled state and deterministic disabled-state enforcement. Stop and recover if hook installation, reload or fail-closed behavior is not confirmed.
4. Allow Notes migration #1 only after G0 verification succeeds. Thereafter preserve the stop/recovery gate after every subsequent migration, especially Notes #1 and #6 grants.
5. Confirm recent backup/PITR coverage, retention, RPO/RTO, restore operator and restore rehearsal evidence. Decide how a restored pre-expiry receipt snapshot is kept from becoming visible; run expiry reconciliation/cleanup before reopening Notes reads after restore.
6. Verify low-traffic window, active sessions/long transactions and database health. Notes migrations #2 and #4 issue `LOCK TABLE ... ACCESS EXCLUSIVE` on the newly created private receipt table; inspect lock waits and have a stop/timeout decision.
7. Treat the completed disposable 72→81 CLI qualification as technical evidence only. The ten-checkpoint SQL/HTTP harness is evidence for staged schema/security behavior, not production authorization. Verify the selected CLI binary/version/hash, direct TLS endpoint/project identity, `postgres` deployment identity, protected `PGPASSFILE` delivery and interactive operator availability before any production command.
8. With explicit A–G approval, the G0 verification evidence and the exact CLI qualification complete, apply G0 and each cumulative Notes stage through official CLI `db push`, one migration per invocation. Notes migration #7 activates both schedules as part of its own transaction. Verify the #7 ledger prefix, exact `cron.job` rows, scheduler authentication and at least one successful expiry run. If any scheduler or access-gate check fails, do not apply Notes #8; record the actual ledger and use authorized recovery.
9. Only after scheduler authentication and the first successful scheduled expiry execution are verified, and the Notes access gate remains effective, obtain separate explicit owner authorization for Notes migration #8. Require exactly `20261031142025` pending, apply it with the selected CLI and PGPASSFILE, and verify the access gate again.
10. Verify hosted ledger is exactly **81** entries, unique and ordered, latest `20261031142025`; compare all version/name pairs and critical catalog objects/grants against the approved source. Do not repair history to force a green result.
11. Perform production authorization verification using read-only catalog, ACL, RLS-policy, role-membership and `SECURITY DEFINER`/`search_path` inspection. Do not call behavioral Note RPCs against real users; behavioral tests remain disposable-only with synthetic fixtures.
12. Capture post-deploy Supabase Security Advisor output and compare it with the dated baseline below. Disposition each new Notes-related warning; a green CI result is not a hosted security pass.
13. Observe the actual expiry job’s first successful run and subsequent cadence; inspect result history and expiry backlog. Confirm the history job is registered and later runs at 03:17 UTC.
14. After Notes #8 and all security acceptance pass, obtain separate owner authorization before disabling the server-side Notes access gate. Assign ongoing monitoring, failure escalation, backlog recovery and restore ownership. Record exact deployment SHA, CLI hash, migration ledger, job IDs/owners, advisor diff and first-run evidence in the approved tracker after separate authorization.

## 5. Security and Acceptance Matrix

| Boundary | Source/disposable evidence | Production requirement |
|---|---|---|
| Anonymous / authenticated access | SQL matrix passes; `anon` denied; authenticated access is owner-bound. | Read-only production grant/RLS inspection only; behavioral owner/foreign-owner checks use synthetic principals in disposable PostgreSQL, never real production Notes. |
| Note ownership and scope | Routine scope is `RoutineId`; Exercise scope is `(user_id, canonical ExerciseRef)`; cross-user isolation passes. | Read-only production catalog/policy inspection; behavioral isolation tests only against disposable synthetic fixtures. |
| RPC trust boundary | Public mutation/reconciliation RPCs use `SECURITY DEFINER`, empty `search_path`, authenticated EXECUTE only, and derive ownership from `auth.uid()`. | Inspect definitions/ACLs read-only; do not call mutating RPCs against production records. |
| Receipt privacy / idempotency | Private receipt table has no client grants; immutable snapshots, 30-day redaction, explicit `expired`, permanent mutation tombstones and retry prevention pass local SQL/concurrency tests. | Inspect private ACL/RLS and schema read-only; prove behavior only in disposable tests. Scheduled expiry itself changes eligible receipt snapshots and is observed through its job result history. |
| Cron roles / ACL | Disposable role membership, narrow function EXECUTE, no direct receipt access, concurrent cleanup/reconciliation and recovery pass. | Verify role flags/membership, job owner and `cron.job` ACL; resolve localhost scheduler authentication before activation. |
| Extension privilege | Hosted `supautils.privileged_extensions` includes `pg_cron`; hosted default 1.6.4 available but absent. | Actual extension install occurs only through approved migration/control-plane flow; verify installed version and schema. |
| Backup / lock / availability | CLI rollback/interruption pass in disposable DB. | Verify PITR/backup and recovery ownership, lock/activity preflight, approved low-traffic window and stop criteria. |
| Security Advisor baseline | Hosted Advisor observed `2026-10-31T19:43:33Z`: INFO count 1 (`private.deleted_user_workout_routine_ids` has RLS without policy); WARN count 14 authenticated-callable `SECURITY DEFINER`; WARN count 1 leaked-password protection disabled. This is the same snapshot recorded in the discovery table above. | Re-run after deploy, compare by function/object, and disposition new Notes RPC warnings. Current baseline is not Notes validation. |

## 6. Explicit Owner Approval Checklist

Reply with an explicit decision for every item. Approval of this packet alone does not authorize running any command.

| ID | Operation / justification | Risks and preconditions | Verification and recovery | Status / explicit owner authorization |
|---|---|---|---|---|
| A | Select and pin an official CLI for the production window. v2.114.0 has a current disposable 72→81 qualification PASS and separate historical 72→80 `PGPASSFILE` evidence. Official v2.122.0 is newer but failed this migration path at Notes migration #2. | v2.114.0 is older; repository CI pins v2.116.0 but uses a different replay method; v2.122.0 is not usable for this path without remediation and requalification. Re-check current release/security advisories before the window. | Verify the selected binary/archive/executable hashes and migration order. If selecting a different version or connection mode, qualify that exact binary/path on disposable infrastructure; stop on mismatch. | **Disposable 72→81 qualification PASS; production CLI pin requires owner approval.** |
| B | Use managed `postgres` over TLS with passwordless `--db-url` and `PGPASSFILE`; no narrower migration principal is qualified. | High privilege (`BYPASSRLS`, role/DDL permissions). Historical v2.114.0 `PGPASSFILE` apply is qualified only for 72→80; current 72→81 used synthetic local credentials. Direct route needs IPv6 or IPv4 add-on. Never use `supabase_admin`, service-role API key, password-bearing argv, `PGPASSWORD`, repo secret or logs. | Approve production identity/secret-delivery method; verify endpoint TLS/identity, operator-only encrypted file ACL, no password in argv/logs/history, and the expected predeploy ledger. | **BLOCKED:** production endpoint, TLS, operator `PGPASSFILE` and authentication compatibility unverified. Explicit approval required. |
| C | Let Notes migration #7 install hosted `pg_cron` (available 1.6.4, allowlisted, absent) as part of its SQL transaction. | Production schema/extension write; scheduler jobs and roles are created by the same migration. No separate extension-only operation is authorized. | Verify extension version/schema and exact role/function ACLs. If migration fails, inspect ledger and catalog before retry; no blind repair/drop. | **Pending.** Explicit owner approval required. |
| D | Verify the G0 hook/configuration and disabled-state enforcement after applying G0, then verify real scheduler authentication after cumulative Notes #1…#7 deployment, with exactly one migration per CLI invocation. Notes #7 registers the jobs; Notes #8 remains a separate, explicitly authorized next step. | Each migration is a production write. Do not require a gate before G0 exists; after G0 commits, the server-side Notes gate must be effective after every committed migration. No dummy job, broad trust auth, or credential/config change is approved. | After G0, verify PostgREST reload/configuration and deterministic disabled denial before allowing Notes #1. After Notes #7, verify `cron.job` owner and exact command, scheduler LOGIN authentication, and at least one successful scheduled expiry execution. If any gate fails, stop before the next migration, preserve evidence, use the approved operator path to unschedule both jobs, keep Notes unavailable, then restore only missing jobs under the authorized scheduler role after auth is fixed. | **G0 sequencing and hosted scheduler auth unverified.** Explicit authorization required. |
| E | Activate expiry job every five minutes (up to 500 receipt bodies per run) and history-prune job daily 03:17 UTC; both are atomically registered by migration #7. | Immediate cleanup can change production receipt snapshots once eligible; there is no independent “install but do not schedule” path in merged SQL. Require monitoring and auth evidence plan. | Verify job owner/schedule/command and first successful run; inspect backlog and failures. `cron.unschedule` is the operational stop; preserve failed records and recover forward. | **Pending.** Explicit owner approval required; cannot be approved independently from #7 and C/D. |
| F | Approve the deployment window/operator and recovery posture for G0 plus cumulative Notes #1…#7, with exactly one migration per CLI invocation, followed by Notes #8 only after its separate authorization. | The disposable 72→81 CLI workflow is qualified, but production endpoint/credential compatibility is not. Per the R1 owner scope decision, backup/recovery evidence is deferred only for the testing-only dataset; it remains mandatory before real-user/production data. Confirm low-traffic window, lock stop criteria and the gate after G0. | Apply G0 only after baseline and owner approvals; verify hook reload and disabled enforcement before Notes #1. After Notes #7, verify scheduler authentication and a first successful scheduled expiry execution, then obtain explicit owner authorization before Notes #8. On any failure stop at the actual ledger prefix, keep Notes gated, preserve evidence, use the approved Cron deactivation/re-registration recovery if #7 committed, and prefer a reviewed forward fix. | **Owner-approved deferral for testing-only scope; not a production recovery pass.** Production TLS/PGPASSFILE, window and named operator remain pending. |
| G | Assign accountable operator for security comparison and continuing cron/retention monitoring. | Existing advisor warnings are baseline, not clearance; deployment does not itself prove new RPC authorization or the 30-day sweep. | Capture before/after Advisor by object, verify anon/owner/cross-owner/RPC/RLS/receipt ACLs, inspect first scheduled runs and backlog, define alert cadence/escalation and recovery contact. | **Pending named owner and acceptance criteria.** Explicit approval required. |

## 7. Remaining Deployment Blockers

The approval packet is ready for owner review; production is **blocked** until all of these are resolved:

1. The PR #720 server-side Notes API/RPC access gate is explicitly approved for hosted deployment. It is installed by G0 and must be verified after G0 before Notes #1, then after every committed Notes migration. A UI/release flag does not satisfy this requirement.
2. A–G are explicitly approved; owner selects/pins an operationally supported CLI version. The disposable v2.114.0 72→81 qualification is PASS, but production endpoint/TLS and credential compatibility must be verified; and a supported hosted auth path for the scheduler LOGIN role is identified.
3. C/D/E are treated as one staged production checkpoint: applying Notes #7 is the first real scheduler-auth test and immediately registers both jobs. Separate owner approval must explicitly authorize this write and the potential first cleanup effects.
4. For the owner-declared testing-only dataset, backup/recovery evidence is explicitly deferred in R1. Before real-user or production data, the canonical backup/PITR state, restore readiness, RPO/RTO, deployment window, lock stop criteria, gate monitoring, named monitoring owner and alert/escalation process must be confirmed.
5. The exact cumulative 72→81 CLI `db push` preview/apply/retry qualification is complete on disposable infrastructure with v2.114.0. Immediately before any production execution, refresh the hosted 72-version prefix, project identity, allowlist/settings and network connectivity, then dry-run `Stage-G0`, each `Stage-A1…Stage-A7` directory and the final Notes #8 stage, requiring exactly the intended single migration at each gate. This read-only snapshot can become stale.

## 8. Final Handoff

### Changed files

- This approval packet and its `.ai/tasks/README.md` index entry are reconciled
  with the final 81-migration architecture. The implementation handoff is
  archived separately at
  `../archive/2026-11-routine-notes-server-side-data-api-gate.md`.

### Validation and limits

- Historical CLI `2.114.0` passwordless URL + ACL-restricted `PGPASSFILE` qualification on disposable Postgres covered the 72→80 workflow. The current CLI `2.114.0` cumulative 72→81 disposable qualification is separately **PASS** for stage preview/apply, rollback, interruption, retry/idempotency and Notes SQL/RLS/Data API checks, using synthetic local credentials. It does not qualify production endpoint/TLS/PGPASSFILE compatibility. `SUPABASE_DB_PASSWORD` was not honored with explicit `--db-url`; no production credential was used. CLI v2.122.0 failed at Notes migration #2 with the transaction-block `LOCK TABLE` error.
- Current PR #720 SQL/HTTP staged qualification covered ten checkpoints and the final 81-migration source replay; it is not CLI deployment qualification.
- Hosted refresh: migrations, project/version, extension availability/allowlist, cron settings, role flags and Security Advisor were read-only. Reading `pg_hba_file_rules` returned permission denied (`42501`); scheduler authentication remains unknown.
- No hosted migration, extension, role, schedule, credential or data change; no production deployment or Linear status change. The documentation-only branch/commit/PR and current review/CI state are reported separately in the task completion report.
- Documentation-only validation: `git diff --check`, migration count/order checks, stale-reference searches and packet whitespace/final-newline checks. Exact-head executable evidence is recorded in the archived implementation handoff and PR #720. Disposable database tests are summarized above and are not production evidence. No executable SQL, migration, hosted write, test/build artifact or CLI change is included in this PR.

### Final status

**BLOCKED — READY FOR OWNER REVIEW ONLY** — the disposable CLI qualification is reconciled. For the owner-declared testing-only dataset, backup/recovery is deferred as an explicit scope decision, not marked ready. Production deployment remains unauthorized pending endpoint/TLS/PGPASSFILE compatibility, scheduler authentication, deployment-window/operator approval and the remaining A–G decisions; the full recovery gate returns before real-user/production data.
