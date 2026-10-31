# Routine Notes Production Deployment Approval Packet

**Status:** Documentation review in progress; production execution is not authorized
**Primary owner:** Product owner / Supabase database owner for approvals
**Implementation owner:** None; implementation and migrations are merged
**Affected platforms:** Supabase Postgres, deployment operations, task documentation

## Owner Approval and Scope Boundary

**Approval status:** Awaiting explicit owner decisions A–G below.
**Approval evidence:** This packet records the current read-only hosted review and the completed disposable CLI `PGPASSFILE` qualification; neither is production deployment evidence.
**Approved scope:** Prepare an evidence-based deployment decision packet for the eight merged Routine Notes persistence migrations.
**Explicit non-changes:** No hosted migration, extension, role, schedule, credential, authentication, or production-data change; no custom runner, CI change, issue/Linear status change, or protected-`main` mutation. This packet is being delivered through a separate documentation-only PR; its review does not authorize production operations.

## 1. Discovery

### User outcome

Make a safe, reviewable owner decision on deploying the already-merged Routine/Exercise Notes persistence foundation and its 30-day receipt cleanup to hosted Supabase project `tio-world` (`oykupyiitspujzpwwvuj`). This packet is not deployment authorization.

### Current verified state — 2026-11-01

| Area | Evidence |
|---|---|
| Repository | `G:\projects\Tio-World`; PR #719 is based on `main@22f465bf0c3b55fd99bc804e359a5047f4452e23`. This packet is being corrected on `tnyx/routine-notes-production-approval`; disposable test artifacts were removed. |
| PR #717 | Merged at `58b5161879d40d2c44e749a61e078294304d2092`; final PR head `9516c4735be0ea4e99f5384bd50087c8aa406c8d`; independent `im-tio` approved that exact head; all 24 external review threads were resolved. |
| PR #717 checks | Exact-head evidence in the Linear merge handoff: Database CI `41217398025`, Flutter CI `41217398011` (three package shards), Docs Hygiene `41217397988`, attribution `41217397972` — passed. Cursor agents were neutral/unavailable, not passes. |
| PR #718 | Documentation-only PR merged at current `main` HEAD `22f465bf0c3b55fd99bc804e359a5047f4452e23`; exact PR head `5fbd25573e511340102e43573a41786ea3378824`. `im-tio` approved that head; Docs Hygiene run `41226124568` passed. Two review threads are resolved; one is outdated. |
| GitHub #716 | Closed as `completed` on 2026-10-31. Its original issue description still contains a pre-merge/local-branch report; use the post-merge closure comment `6546518502` and merged PR/archive evidence as the final checkpoint. |
| PR #719 documentation review | At the checkpoint before this packet amendment, PR was OPEN at `2d1543495341289ef9a5702e0760c4a18e92f841`, based on `main@22f465bf0c3b55fd99bc804e359a5047f4452e23`. Docs Hygiene and both attribution checks passed; three Cursor checks were neutral. Independent reviewer `im-tio` remained requested without a submitted review; Copilot returned `COMMENTED` because its quota was exhausted; no inline review threads existed. GitHub branch-protection/ruleset APIs were unavailable (integration 403; CLI API connectivity failed), so required-context policy was not independently verified. |
| Linear | [TNYX-81](https://linear.app/tnyx/issue/TNYX-81) remains **Backlog** for broader W4. It is blocked by TNYX-80 and TNYX-78 and blocks later W5/W6 work. No child issue could be created earlier because the workspace issue limit was reached; this packet creates no duplicate issue and changes no tracker status. Attached handoff: [PR #717 merge handoff](https://linear.app/tnyx/document/pr-717-routineexercise-notes-persistence-merge-handoff-6df1105cfb3f). |
| Hosted migrations | Read-only Supabase refresh returned exactly **72** applied migrations, ending at `20261028110000_grant_authenticated_program_delete_rpc`. The checked-in first 72 versions/names match; eight Notes migrations are pending. |
| Hosted database | Project is `ACTIVE_HEALTHY`, region `ap-south-1`, PostgreSQL `17.6.1.155` (engine 17). |
| Hosted `pg_cron` | Version `1.6.4` is available, not installed; no `cron` schema or jobs exist. `cron.host=localhost`, `cron.use_background_workers=off`, timezone `UTC`. `pg_cron` is present in `supautils.privileged_extensions`; this supports the managed `postgres` role's extension-creation path, but actual installation was not attempted. |
| Hosted roles | `postgres` is login, `CREATEROLE`, `CREATEDB`, `BYPASSRLS`, but not superuser; `supabase_admin` is superuser and is not the migration identity to use. The migration-created cleanup roles do not exist yet. |
| Hosted scheduler authentication | `postgres` cannot read `pg_hba_file_rules` (SQLSTATE `42501`); effective localhost authentication for the future scheduler LOGIN role is therefore **not verified**. The migration creates that role without a password. Local Docker trust-mode success is not hosted authentication evidence. |
| Hosted Security Advisor | Read-only refresh observed `2026-10-31T19:43:33Z`: INFO `rls_enabled_no_policy` count 1 for `private.deleted_user_workout_routine_ids`; WARN `authenticated_security_definer_function_executable` count 14; WARN `auth_leaked_password_protection` count 1. These predate Notes deployment and contain no Notes-specific findings. |
| Current main CI | GitHub Actions lookup for merge commit `22f465bf0c3b55fd99bc804e359a5047f4452e23` returned no PR-triggered workflow runs. PR #718 Docs Hygiene CI `41226124568` passed on its exact head; PR #717 Database/Flutter/Docs Hygiene checks passed on its exact PR head as listed above. No check result is inferred for the current main merge commit. |

`docs/data/SUPABASE_STRATEGY.md` still labels its last verification as 69/69 migrations on 2026-10-24. That canonical snapshot is stale; this packet records the refreshed 72/72 hosted prefix without modifying the broader strategy document.

### Merged migrations, in order

1. `20261029120000_create_user_workout_routine_notes.sql`
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

Official Supabase CLI **v2.114.0 is now qualified for the tested direct `db push` path using a passwordless URL and protected `PGPASSFILE` on disposable infrastructure**, including full 72-to-80 replay and recovery tests below. This is technical qualification only; it does not select v2.114.0 as the production pin or approve deployment. The official release page marks **Supabase CLI v2.122.0** (released 2026-10-23) as Latest, so its age and the repository CI pin at v2.116.0 remain version-selection considerations. Do not implement a custom runner. Neither CLI version is automatically approved for production.

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
- Full hosted-prefix replay (72) plus eight pending Notes migrations using CLI `2.114.0`, passwordless direct URL plus ACL-restricted `PGPASSFILE`: **PASS**; exactly 80 unique, correctly ordered migration entries before temporary failure/interruption probes.
- CLI `2.114.0` ledger representation: **PASS**, expected Supabase `schema_migrations` records; no missing/duplicate version and no empty statement arrays.
- Schema parity between `supabase migration up --local` and CLI `2.114.0` `supabase db push --db-url`: **PASS** after normalizing random `pg_dump` restrict tokens; normalized hash `2CEED53D5CE940731E2E74D35BA41516EF01E847DDF7B49BC83571DC6DABC0DF`.
- Notes SQL/RLS/receipt-retention matrix and both disposable concurrency harnesses: **PASS** against the `db push` replay database using temporary script copies with only the local disposable endpoint/credential guard adapted. Repository test scripts were not changed. Coverage included owner isolation, cross-owner denial, duplicate/expired retry, concurrent mutation, cleanup batching, concurrent cleanup/reconciliation, lock serialization and cleanup failure/recovery.
- Failed migration rollback and corrected retry with CLI `2.114.0` + passwordless URL + `PGPASSFILE`: **PASS**; DDL and ledger entry rolled back together, corrected retry produced exactly one entry, and subsequent push was a no-op.
- Interrupted CLI `2.114.0` recovery using the same credential path: **PASS**; Ctrl+C during a disposable migration left neither DDL nor ledger row, and a same-version retry completed once.
- Secret handling: **PASS** for the disposable run. Synthetic password was kept in temporary ACL-restricted host files and a mode-`600` container passfile; it was absent from process arguments, URL, shell command, logs and Git changes. TLS was requested with `sslmode=require`. No production credential was used. Test credentials/artifacts and disposable database are removed after validation.
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
- Keep the password out of `--db-url`. The passwordless URL + ACL-restricted `PGPASSFILE` path passed the full disposable `db push` qualification listed above. `SUPABASE_DB_PASSWORD` was not honored by CLI v2.114.0 with explicit `--db-url`; PostgreSQL discourages `PGPASSWORD` for secret delivery. Production still requires an owner-approved endpoint, encrypted ephemeral file location, verified operator-only ACL, controlled `PGPASSFILE` injection and a production-compatible authentication check. The non-secret URL and passfile path remain visible to the process; neither contains the password.
- **Remaining qualification/selection:** choose and explicitly pin a supported production CLI version after considering v2.114.0's age, the current official release and repository CI's v2.116.0 pin. v2.122.0's exact migration path remains unqualified. Production endpoint reachability, TLS certificate/identity behavior and deployment credential/authentication compatibility remain unverified. Do not use production credentials for disposable tests.

Run interactively, with a human present. The URL must be passwordless; set `PGPASSFILE` only to a verified operator-only temporary file:

```powershell
$Cli = '<versioned side-by-side supabase.exe>'
$DbUrl = 'postgresql://postgres@<approved-endpoint>:5432/postgres?sslmode=require'
$env:PGPASSFILE = '<operator-only encrypted temporary path>\pgpass.conf'
# File format: <endpoint-host>:5432:postgres:postgres:<secret password>
& $Cli --version
& $Cli migration list --db-url $DbUrl
& $Cli db push --db-url $DbUrl --dry-run --skip-vault
# Only after all gates are approved and the dry-run lists exactly the eight pending migrations:
& $Cli db push --db-url $DbUrl --skip-vault
```

Never echo password-file contents or include them in diagnostics. Verify the file's explicit operator-only ACL and encrypted volume before use; clear `PGPASSFILE` and remove the temporary file after the process exits. The disposable test showed `SUPABASE_DB_PASSWORD` is not honored by CLI v2.114.0 when an explicit `--db-url` is supplied; do not use that combination. Do not run the final command from this packet. The disposable `db push` run displayed an interactive `[Y/n]` prompt; inspect the target and prompt rather than making this unattended. Do not use `migration repair` to fake deployment history.

## 3. Scheduler and Extension Gate

### Verified architecture

Migration #7 schedules:

- `routine-note-receipt-expiry`: every five minutes; redacts at most 500 expired receipt snapshots per run using `FOR UPDATE SKIP LOCKED`.
- `routine-note-receipt-history`: daily at `03:17` database time (hosted timezone currently UTC); prunes at most 500 successful run-history records older than 90 days and retains failures.

The scheduler has no receipt-table privileges. It gets `USAGE` on `private`/`cron` and EXECUTE on only the cleanup, history-prune, schedule and unschedule functions. The cleanup owner is `NOLOGIN`, non-superuser, non-`BYPASSRLS`; cleanup is `SECURITY DEFINER` with empty `search_path`. The history function is `SECURITY INVOKER` with empty `search_path`. Role membership is intended to be restricted to `postgres` and `SET ROLE`.

### Hosted enablement and first execution plan

Supabase documents enabling Cron through Dashboard → Integrations → Cron Postgres Module; its SQL install path is also documented. Current hosted read-only settings show `pg_cron` on `supautils.privileged_extensions`, so the `postgres` role is expected to be permitted to create it. The actual `CREATE EXTENSION` has not been tested on hosted. [Cron installation](https://supabase.com/docs/guides/cron/install), [Supabase role privileges](https://supabase.com/docs/guides/database/postgres/roles-superuser).

Do not separately create a production probe role/job in this task. The narrow controlled verification is the approved migration deployment itself: #7 creates the real scheduler role and both jobs atomically; the first expiry run can redact up to 500 actually expired snapshots. After the full migration sequence, verify exact owner/name/schedule/command rows in `cron.job`, then observe `cron.job_run_details` for the expiry job’s first `succeeded` row, timestamps and return message. Verify history-prune job registration; its scheduled execution is daily. Do not manually invoke cleanup against production receipts as a test.

**Unresolved auth:** the future scheduler role is `LOGIN` but migration supplies no password. Hosted `cron.host=localhost` with background workers off indicates the libpq job-connection path; the actual hosted authentication method remains unverified. Hosted HBA rules are not readable to the migration role; local Docker trust-mode success is not evidence. Do not enable broad `trust`, add a password to migration SQL, or expose a credential. No read-only preflight can prove this role will authenticate because the role and jobs do not yet exist. The minimum production verification necessarily includes applying merged migration #7, which installs the extension, creates roles and registers both real jobs in one transaction; that is a production write and immediately activates cleanup. Before that step, the owner must approve the combined checkpoint and establish a documented, narrow hosted auth path through Supabase's supported controls. After #7 commits, verify effective job identity and first run in `cron.job_run_details`; if authentication fails, stop before #8, deactivate both jobs through `cron.unschedule` using the approved `postgres` operator path, preserve run evidence, and keep Notes access gated. If no narrow supported path is confirmed, do not apply #7; return for separately approved architecture remediation. Do not edit merged migration #7 here.

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
- If deployment stops after migration #7 but before #8, or a scheduled job fails, stop the deploy, record the actual ledger prefix, inspect the job result and safely deactivate by job name with the granted `cron.unschedule(text)` function under an authorized role. Do not write directly to `cron.job`; Supabase has changed hosted Cron permissions and its supported job API is the cron functions/Dashboard.
- Correct the authentication/configuration cause through an approved control plane; verify job execution before scheduling/re-activating. Preserve failed run evidence. Do not drop `pg_cron` as rollback while jobs exist; disabling the extension deletes all jobs. Dropping the extension is not part of ordinary recovery.
- If schema/data integrity is at risk, stop application access to the affected feature, preserve evidence, and use the approved PITR/restore plan. These are forward-only migrations; do not delete ledger rows or hand-edit production schema as rollback.

## 4. Ordered Eight-Migration Deployment Plan

1. Freeze the deployment SHA and verify `main`, the eight local filenames and hashes, the hosted 72-entry migration prefix, and no unexpected remote-only/local-only migrations. `migration list` compares timestamps; independently verify names and prefix before proceeding.
2. Confirm recent backup/PITR coverage, retention, RPO/RTO, restore operator and restore rehearsal evidence. Decide how a restored pre-expiry receipt snapshot is kept from becoming visible; run expiry reconciliation/cleanup before reopening Notes reads after restore.
3. Verify low-traffic window, active sessions/long transactions and database health. Migrations #2 and #4 issue `LOCK TABLE ... ACCESS EXCLUSIVE` on the newly created private receipt table. It is expected to be empty because all Notes migrations are pending, but still inspect lock waits and have a stop/timeout decision.
4. Verify approved CLI binary/version/hash, direct TLS endpoint/project identity (IPv6 or IPv4 add-on), `postgres` deployment identity, full-replay-qualified `PGPASSFILE` delivery with operator-only ACL, and interactive operator availability. Never print credentials; the URL itself must be passwordless.
5. Confirm `pg_cron` remains available at 1.6.4 and on the privileged extension allowlist; confirm the scheduler authentication decision and monitoring/on-call owner. The migration itself creates the extension and jobs; do not claim those steps are independent.
6. Run `supabase migration list --db-url ...` and `supabase db push --db-url ... --dry-run --skip-vault`; require exactly the eight versions above, in order. Any mismatch, unexpected migration, auth prompt/target mismatch or unsupported CLI output is a stop condition. Confirm the password is absent from process arguments and captured logs.
7. With approval A–G, apply the pending sequence through official CLI `db push`. Each migration file is committed in its own transaction; the eight-file push is not one atomic transaction. Migration #7 activates both schedules as part of its own transaction. If #8 or a later step fails after #7, earlier files and jobs remain committed; stop Notes release/use, record the actual ledger, and use the authorized deactivation/forward-recovery procedure before any retry.
8. Verify hosted ledger is exactly 80 entries, unique and ordered, latest `20261031142025`; compare all version/name pairs and critical catalog objects/grants against the approved source. Do not repair history to force a green result.
9. Run read-only authorization checks: anon denied, authenticated owner reads/mutates only own scope, foreign-owner IDs denied, correct Routine/Exercise scope, RPC grants, role memberships, `SECURITY DEFINER` owners and empty `search_path`, private receipt access denied to clients, and tombstone/hash preservation.
10. Capture post-deploy Supabase Security Advisor output and compare it with the dated baseline below. Disposition each new Notes-related warning; a warning is not automatically a vulnerability, and a green CI result is not a hosted security pass.
11. Observe the actual expiry job’s first successful run and subsequent cadence; inspect result history and expiry backlog. Confirm the history job is registered and later runs at 03:17 UTC. Do not claim the 30-day policy is operational until actual scheduler authentication and execution are proven.
12. Assign ongoing monitoring, failure escalation, backlog recovery and restore ownership. Record exact deployment SHA, CLI hash, migration ledger, job IDs/owners, advisor diff and first-run evidence in the approved tracker after separate authorization.

## 5. Security and Acceptance Matrix

| Boundary | Source/disposable evidence | Production requirement |
|---|---|---|
| Anonymous / authenticated access | SQL matrix passes; `anon` denied; authenticated access is owner-bound. | Verify grants and behavior after deploy with safe test principals; no anonymous access. |
| Note ownership and scope | Routine scope is `RoutineId`; Exercise scope is `(user_id, canonical ExerciseRef)`; cross-user isolation passes. | Read-only catalog and authorized owner/foreign-owner test; no cross-user data disclosure. |
| RPC trust boundary | Public mutation/reconciliation RPCs use `SECURITY DEFINER`, empty `search_path`, authenticated EXECUTE only, and derive ownership from `auth.uid()`. | Verify exact definitions/ACLs and current advisor findings; no client-supplied owner authorization. |
| Receipt privacy / idempotency | Private receipt table has no client grants; immutable snapshots, 30-day redaction, explicit `expired`, permanent mutation tombstones and retry prevention pass local SQL/concurrency tests. | Confirm private ACL/RLS, snapshot redaction and stable `mutation_id`/`request_hash`; validate access-time behavior and schedule. |
| Cron roles / ACL | Disposable role membership, narrow function EXECUTE, no direct receipt access, concurrent cleanup/reconciliation and recovery pass. | Verify role flags/membership, job owner and `cron.job` ACL; resolve localhost scheduler authentication before activation. |
| Extension privilege | Hosted `supautils.privileged_extensions` includes `pg_cron`; hosted default 1.6.4 available but absent. | Actual extension install occurs only through approved migration/control-plane flow; verify installed version and schema. |
| Backup / lock / availability | CLI rollback/interruption pass in disposable DB. | Verify PITR/backup and recovery ownership, lock/activity preflight, approved low-traffic window and stop criteria. |
| Security Advisor baseline | Hosted Advisor observed `2026-10-31T19:15:15Z`: INFO count 1 (`private.deleted_user_workout_routine_ids` has RLS without policy); WARN count 14 authenticated-callable `SECURITY DEFINER`; WARN count 1 leaked-password protection disabled. | Re-run after deploy, compare by function/object, and disposition new Notes RPC warnings. Current baseline is not Notes validation. |

## 6. Explicit Owner Approval Checklist

Reply with an explicit decision for every item. Approval of this packet alone does not authorize running any command.

| ID | Operation / justification | Risks and preconditions | Verification and recovery | Status / explicit owner authorization |
|---|---|---|---|---|
| A | Select and pin an official CLI for the production window. v2.114.0 is technically qualified for the tested direct `db push` + protected `PGPASSFILE` path; official v2.122.0 was Latest when checked on 2026-11-01 but is unqualified against this migration set. | v2.114.0 is older; v2.122.0 exact migration path is untested; repository CI pins v2.116.0 but uses a different replay method. Re-check current release/security advisories before the window. | The disposable v2.114.0 evidence below establishes only the tested path. If selecting a different version or connection mode, qualify that exact binary/path on disposable infrastructure; stop on mismatch. | **Technical v2.114.0 qualification PASS; production version selection and owner approval pending.** Explicit approval required. |
| B | Use managed `postgres` over TLS with passwordless `--db-url` and `PGPASSFILE`; no narrower migration principal is qualified. | High privilege (`BYPASSRLS`, role/DDL permissions). v2.114.0 full disposable credentialed apply is qualified. Direct route needs IPv6 or IPv4 add-on. Never use `supabase_admin`, service-role API key, password-bearing argv, `PGPASSWORD`, repo secret or logs. | Approve production identity/secret-delivery method; verify endpoint TLS/identity, operator-only encrypted file ACL, no password in argv/logs/history, and the expected predeploy ledger. | **Disposable v2.114.0 path qualified; production identity, authentication compatibility and owner approval pending.** Explicit approval required. |
| C | Let merged migration #7 install hosted `pg_cron` (available 1.6.4, allowlisted, absent) as part of its SQL transaction. | Production schema/extension write; scheduler jobs and roles are created by the same migration. No separate extension-only operation is authorized. | Verify extension version/schema and exact role/function ACLs. If migration fails, inspect ledger and catalog before retry; no blind repair/drop. | **Pending.** Explicit owner approval required. |
| D | Verify real scheduler auth by applying #7 and observing the real scheduled jobs; no safe read-only preflight can test a role/job that does not exist. | This is a production write and inherently activates cleanup. No dummy job, broad trust auth, or credential/config change is approved. Require owner-confirmed narrow supported auth and maintenance-window controls first. | Verify `cron.job` owner and exact command; capture `cron.job_run_details` first success/failure. On failure, stop before #8, preserve evidence, use approved `postgres` role to `cron.unschedule` both jobs, keep Notes unavailable, then resolve/retry only by approval. | **Unverified and coupled to C/E.** Separate explicit authorization for the #7 checkpoint required. |
| E | Activate expiry job every five minutes (up to 500 receipt bodies per run) and history-prune job daily 03:17 UTC; both are atomically registered by migration #7. | Immediate cleanup can change production receipt snapshots once eligible; there is no independent “install but do not schedule” path in merged SQL. Require monitoring and auth evidence plan. | Verify job owner/schedule/command and first successful run; inspect backlog and failures. `cron.unschedule` is the operational stop; preserve failed records and recover forward. | **Pending.** Explicit owner approval required; cannot be approved independently from #7 and C/D. |
| F | Choose window/operator and recovery posture for the eight-file deployment. | Lock waits/availability risk; per-file atomicity only; PITR restore may lose writes after restore point and is not a schema-only rollback. Confirm backup/PITR, RPO/RTO, restore rehearsal and feature gate. | Dry-run exact eight; monitor locks; on failure stop at actual ledger prefix, deactivate jobs if #7 committed, preserve logs, prefer reviewed forward fix. PITR only under separately approved data-loss/downtime decision. | **Pending recovery evidence, window and owner.** Explicit authorization required. |
| G | Assign accountable operator for security comparison and continuing cron/retention monitoring. | Existing advisor warnings are baseline, not clearance; deployment does not itself prove new RPC authorization or the 30-day sweep. | Capture before/after Advisor by object, verify anon/owner/cross-owner/RPC/RLS/receipt ACLs, inspect first scheduled runs and backlog, define alert cadence/escalation and recovery contact. | **Pending named owner and acceptance criteria.** Explicit approval required. |

## 7. Remaining Deployment Blockers

The approval packet is ready for owner review; production is **blocked** until all of these are resolved:

1. A–G are explicitly approved; owner selects/pins an operationally supported CLI version (v2.114.0's tested protected path is technically qualified but older than the latest stable release verified on 2026-11-01); production endpoint/TLS and credential compatibility are verified; and a supported hosted auth path for the scheduler LOGIN role is identified.
2. C/D/E are treated as one staged production checkpoint: applying #7 is the first real scheduler-auth test and immediately registers both jobs. Separate owner approval must explicitly authorize this write and the potential first cleanup effects.
3. Backup/PITR state, restore readiness, deployment window, lock stop criteria, Notes feature access gate, named monitoring owner and alert/escalation process are confirmed.
4. Immediately before execution, refresh the hosted 72-version prefix, project identity, allowlist/settings, network connectivity and pending-eight dry run; this read-only snapshot can become stale.

## 8. Final Handoff

### Changed files

- This approval packet and its `.ai/tasks/README.md` index entry only.

### Validation and limits

- CLI `2.114.0` passwordless URL + ACL-restricted `PGPASSFILE` qualification on disposable Postgres: minimal LOCK, 72→80 full replay, exact ledger, schema/ledger consistency, Notes SQL/RLS/retention/concurrency, failed rollback/retry, interrupted execution/retry, duplicate no-op and secret checks all passed. Temporary probes brought the isolated ledger to 82 only after the exact-80 checkpoint; the disposable project is removed. `SUPABASE_DB_PASSWORD` was not honored with explicit `--db-url`; no production credential was used. CLI v2.122.0 remains unqualified for this repository.
- Hosted refresh: migrations, project/version, extension availability/allowlist, cron settings, role flags and Security Advisor were read-only. Reading `pg_hba_file_rules` returned permission denied (`42501`); scheduler authentication remains unknown.
- No hosted migration, extension, role, schedule, credential or data change; no production deployment or Linear status change. The documentation-only branch/commit/PR and current review/CI state are reported separately in the task completion report.
- Documentation-only validation: `git diff --check` and packet whitespace/final-newline checks; the pre-amendment PR head `2d1543495341289ef9a5702e0760c4a18e92f841` passed Docs Hygiene and both attribution checks. The final packet-correction head and its CI are reported in the task completion record. Disposable database tests are summarized above and are not production evidence. No executable SQL, migration, hosted write, test/build artifact or CLI change is included in this PR.

### Final status

**READY FOR OWNER DEPLOYMENT APPROVAL** — this means the decision packet is ready for owner review only. Production deployment remains unauthorized and blocked by the exact prerequisites above.
