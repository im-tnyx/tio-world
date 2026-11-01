# Routine Notes Server-Side Data API Gate

**Status:** Implementation in progress
**Primary owner:** Product owner / Supabase database owner
**Planning owner:** Codex (preflight and gate design)
**Implementation owner:** Codex (local implementation agent, current session)
**Review owner:** None
**Affected platforms:** Supabase Postgres, PostgREST Data API, disposable database security tests, deployment governance

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped server-side release/security gate and Supabase role configuration change
**Approval status:** `APPROVED` for repository-only gate implementation, disposable validation and focused PR review; hosted deployment, production activation and merge remain unauthorized.
**Approval evidence:** Product Owner approval was explicitly recorded in the 2026-11-01 implementation authorization. The existing Routine Notes deployment packet and PR #719 remain separate production gates and do not authorize hosted deployment.
**Approved gate mechanism:** A new pre-Notes migration, ordered after the hosted 72-migration prefix and before `20261029120000_create_user_workout_routine_notes.sql`, installs a private `SECURITY DEFINER` PostgREST pre-request hook with a fixed `search_path` and registers it through the Supabase-supported `pgrst.db_pre_request` setting on `authenticator`. The corrected design stores the operator-controlled state in one private, non-exposed gate-state table seeded to `disabled`; it does not use an arbitrary `app.*` role GUC, which failed on the qualified PostgreSQL 17 runtime. The hook reads only server-populated `request.path`, exact-matches the Notes table and three public Notes RPC paths, and permits them only when the state is exactly `enabled`; missing, null, malformed, unknown, or unreadable state remains denied. Non-Notes paths pass through. The controlled denial uses a valid PostgREST `PGRST` error payload with `status=403`, `headers`, and `status_text`.
**Proposed migration candidate:** `supabase/migrations/20261028120000_install_routine_notes_data_api_gate.sql`. The eight merged Routine Notes migrations would remain unchanged.
**Approved product/UI/data-shape boundaries:** No Notes product-contract change, no Flutter/UI change, no table/column change to the existing Notes objects, no change to RoutineId or `(authenticated user, canonical ExerciseRef)` ownership, no change to existing RLS/RPC authorization, `SECURITY DEFINER` `search_path`, ACL boundaries, receipt retention, or migration #7 scheduler behavior.
**Explicit non-changes:** No hosted migration or write, no hosted gate enablement, no Notes enablement, no service/scheduler/pg_cron addition, no broad role privilege, no GitHub/Linear mutation, no commit/push/merge/deploy.

## Active Handoff

**Planning owner:** Codex (preflight and gate design)
**Implementation owner:** Codex (local implementation agent, current session)
**Review owner:** None
**Implementation ownership state:** Active
**Ownership transition:** Planning owner → Codex implementation owner, authorized by the Product Owner approval above.
**Repository state last verified:** 2026-11-01; the dedicated branch `codex/routine-notes-data-api-gate` is based on `cd81393598b5f82606c10c38058296b9052e57f4`. Git fsmonitor still reports an IPC diagnostic in normal status; status and diff checks remain usable with `core.fsmonitor=false`. The worktree contains the pre-existing task-governance edits below plus this authorized implementation slice.
**Branch:** `codex/routine-notes-data-api-gate`
**HEAD SHA:** `cd81393598b5f82606c10c38058296b9052e57f4`
**Observed working-tree state:** Existing intentional task-governance edits are preserved.
**Observed uncommitted/dirty files:** `.ai/tasks/README.md` was pre-existing and is preserved; this brief, the candidate migration, catalog SQL assertion, disposable HTTP harness and CI workflow step are the authorized slice.
**PR / tracker:** Linear `TNYX-81` is `Backlog`, blocked by `TNYX-78` and `TNYX-80`; GitHub #716 is closed after PR #717 validation; PR #719 is merged into the observed `main` head. No child tracker or status mutation is authorized.
**Current implementation state:** Candidate gate migration, catalog assertions, disposable PostgREST harness and CI invocation have been added on the dedicated branch. The eight existing Notes migrations remain unchanged. The isolated 81-migration replay, catalog assertions, Routine Notes SQL matrix, HTTP matrix, lint and hosted read-only alternate-surface checks passed; repository CI and independent review remain open.
**Relevant execution surface:** `supabase/migrations/`, `supabase/tests/database/`, `.github/workflows/supabase-db-ci.yml`, `.ai/tasks/routine-notes-production-deployment-approval.md`
**Validation completed at SHA:** Read-only source/config inspection, live Linear/GitHub refresh, Supabase documentation lookup, eight-migration SQL/RPC/ACL inspection, Docker Desktop `4.97.0` / Engine `29.9.2`, clean isolated 81-migration replay with ledger repair, catalog assertions, existing Routine Notes persistence SQL, committed HTTP harness via a local published-port adapter, `supabase db lint`, hosted GraphQL/Realtime/Storage/Edge read-only checks, cleanup and recovery verification. The current slice also passed Python syntax and `git diff --check`.
**Validation remaining:** Repository-hosted CI, independent security review and PR checks. Production implementation/activation remains separately unauthorized.
**Current blocker:** None for the authorized repository slice. Hosted deployment, production activation, Notes enablement and merge remain explicitly blocked by scope.
**Open review finding IDs:** None assigned in this task.
**Next exact action:** Inspect the exact parent-to-head diff, create one focused PR, request independent security review and stop before merge, hosted writes or production activation.

## 1. Discovery

### User outcome

Keep authenticated Routine Notes unavailable until the Notes migration sequence and later security acceptance are released, while preserving ordinary non-Notes Data API traffic.

### Success criteria

- Default-deny before Notes objects exist and after every Notes migration, including migrations #1 and #6 that grant authenticated access.
- Deny authenticated direct reads of `public.user_workout_routine_notes` and calls to the public mutation/reconciliation RPCs without consulting client payload ownership fields or Flutter flags.
- Preserve ordinary non-Notes PostgREST requests.
- Prove controlled enable, disable, malformed/unknown-state failure-stop, and recovery in a disposable database with synthetic fixtures.
- Verify the gate is Data API-only and that Notes have no Realtime publication, Storage object/bucket surface, Edge Function route, or GraphQL exposure. Direct database connections remain an explicit unprotected operator/server surface and must not be treated as client release access.
- Do not apply any migration or write any hosted data/configuration.

### Scope

- One new pre-Notes migration, if approved.
- Focused SQL/catalog tests and a real disposable PostgREST HTTP test following existing `tnyx_569_r3_postgrest_revoke_smoke.py` isolation conventions.
- Required active handoff and exact validation evidence.

### Non-goals

- No Notes UI, Flutter capability, repository wiring, client release flag, or product-contract change.
- No edits to the eight merged Notes migrations.
- No hosted migration, hosted `ALTER ROLE`, hosted `NOTIFY`, hosted fixture, production RPC probe, deploy, or release.
- No new service, scheduler, extension, table/column shape, broad privilege, or speculative remote-config system.

## 2. Codebase Exploration

### Verified evidence

- `TNYX-81` remains `Backlog`, with blockers `TNYX-78` and `TNYX-80`; its 2026-10-31 owner decision preserves personal Routine Notes by `RoutineId` and personal Exercise Notes by authenticated `user_id` plus canonical `ExerciseRef`, and does not authorize implementation by itself.
- GitHub #716 is closed after PR #717 merged at `58b5161879d40d2c44e749a61e078294304d2092`; the eight Notes migrations and existing disposable SQL/concurrency coverage are merged source, not hosted deployment evidence.
- PR #719 is merged at `main@cd81393598b5f82606c10c38058296b9052e57f4`. Its deployment packet records the missing server-side Notes API/RPC gate as a hard precondition and keeps production unauthorized.
- Hosted Supabase project `oykupyiitspujzpwwvuj` is `ACTIVE_HEALTHY`, region `ap-south-1`, PostgreSQL 17.6.1.155, with exactly 72 applied migrations ending at `20261028110000_grant_authenticated_program_delete_rpc`. Read-only hosted catalog checks show Notes table/receipt/RPC objects absent, no Notes client table grants, and no `pgrst.db_pre_request` configuration on `authenticator`.
- Local `supabase/config.toml` enables the Data API with `public`, `storage`, and `graphql_public` schemas; `private` is not exposed. No existing Notes gate or `db_pre_request` hook was found in source/config/docs.
- Migration #1 grants `authenticated SELECT` on the public Notes table and `authenticated EXECUTE` on the public mutation/reconciliation RPCs. Later migrations recreate/regrant the canonical RPC ACLs; migration #7 installs and schedules `pg_cron` jobs. The proposed gate must not modify these migrations or scheduler behavior.
- Supabase's current `Securing your API` documentation supports `pgrst.db_pre_request`, `ALTER ROLE authenticator`, `NOTIFY pgrst, 'reload config'`, `request.path`, and `request.method`. The same documentation limits this hook to the PostgREST Data API and explicitly excludes Realtime, Storage, and other Supabase products.
- Existing PostgREST HTTP testing already proves that committed ACL changes are observable through disposable PostgREST; it does not prove this new gate until a dedicated stage test is added.

## 3. Clarification

### Decisions required or made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Use a server-side PostgREST `db_pre_request` hook as the Notes gate | Proposed; approval required | ACL revokes alone are overwritten by merged migrations #1/#6; RLS cannot be installed before a table exists; the supported hook can match Notes paths and survive later grants | Product/Supabase owner |
| Gate state is operator-controlled server configuration, default deny | Approved and implemented in repository slice | No client-supplied owner or Flutter flag; unset/false/malformed state fails closed for Notes; enable/disable remains separate from migration apply | Product/Supabase owner |
| Hook blast radius | Recorded | Function executes on every PostgREST request. Exact non-Notes pass-through and failure behavior are mandatory tests; hook/config failure may affect all Data API traffic and is a project-wide operational risk | Product/Supabase owner |
| GraphQL treatment | Accepted boundary for this slice | `graphql_public` is configured locally and `db_pre_request` does not cover GraphQL. Disposable and hosted read-only catalog checks found no Notes exposure; any future exposure requires a separate GraphQL control | Product/Supabase owner |
| Direct database, Realtime, Storage and Edge Function limits | Recorded | These surfaces are outside the hook. Notes must not be reachable through Realtime/Storage/Edge Function surfaces; direct DB remains privileged server/operator access and is not a client release gate | Product/Supabase owner |

## 4. Architecture Design

### Chosen approach (approved repository implementation)

Install one private, fixed-search-path `SECURITY DEFINER` pre-request function and one private gate-state table before Notes migration #1. Register the function as the PostgREST `db_pre_request` hook on `authenticator`. The function should:

1. read `request.path` and return immediately for all non-Notes paths;
2. exact-match the documented PostgREST paths `/user_workout_routine_notes`, `/rpc/mutate_user_workout_routine_note`, `/rpc/mutate_user_workout_routine_note_legacy`, and `/rpc/reconcile_user_workout_routine_note_mutation`; do not normalize case, decode path text, inspect request JSON, or trust client headers;
3. read only the private state row and allow exactly `enabled`; missing, null, malformed, unknown, or unreadable state remains disabled;
4. raise a deterministic valid PostgREST `PGRST` denial before table lookup or RPC execution when disabled, with HTTP `403`, `headers`, and `status_text='Forbidden'` in the `detail` JSON;
5. revoke `PUBLIC`/application control, enable RLS on the private state table with no client policy, and grant only private-schema `USAGE` plus hook `EXECUTE` to the PostgREST impersonated roles required by the runtime (`anon`, `authenticated`, and `service_role`); no state-table DML is granted;
6. leave existing Notes RLS, RPC owner derivation, `SECURITY DEFINER` declarations, empty `search_path`, grants, receipts and scheduler untouched.

Enable/disable/recovery commands must be limited to a separately authorized trusted operator path. The migration seeds `disabled`; a later operator state change must reload PostgREST configuration where required and verify both Notes denial and non-Notes recovery. A missing hook/function or failed configuration reload is a project-wide Data API stop, not an implicit enable. Notes activation remains outside this implementation slice.

### Project-wide PostgREST impact

The hook is invoked for every PostgREST request, including ordinary reads/writes and RPCs. The intended steady-state cost is a small exact-path check and no Notes-state lookup for non-Notes requests. A hook exception, missing function, failed config reload, or incompatible hosted role/configuration can produce a broader PostgREST outage; this is the principal blast-radius risk and must be included in review and recovery planning. No project-wide Data API disable, schema removal, or default-privilege change is proposed.

### Surface boundary and verification

| Surface | Protected by this hook? | Required disposable verification |
|---|---:|---|
| PostgREST Data API table/RPC paths | Yes | HTTP GET/HEAD/POST with anonymous, authenticated owner, cross-owner and unauthenticated synthetic cases; before objects, after #1, after #6, and after #8 |
| Realtime | No | Notes table absent from `pg_publication_tables` / realtime publication; no Notes channel or publication migration |
| Storage | No | No Notes bucket/object/policy; no Notes data in `storage.objects` |
| GraphQL / `graphql_public` | No | Query/introspection check; if Notes are visible, stop and obtain a separate approved control before claiming this gate is sufficient |
| Direct database connections | No | Verify no client connection string/credential is introduced and application roles cannot authenticate as a database login; document that a trusted privileged operator can bypass this HTTP gate |
| Edge Functions / other Supabase products | No | No Notes function/route or alternate privileged client path; document that future server code must enforce its own gate |

### Alternative rejected

- Revoke `authenticated` table/RPC grants in the pre-Notes migration: rejected because migrations #1 and #6 grant them again.
- RLS-only release flag: rejected because RLS is row authorization, cannot protect RPCs, and cannot be attached before a table exists without changing the Notes migration sequence.
- Flutter capability/release flag: rejected because client state is not authorization and does not stop direct PostgREST calls.
- Disable the complete Data API: rejected because it breaks unrelated product traffic and violates the non-Notes preservation requirement.
- New protected service or custom migration runner: rejected as outside scope and unnecessary for this narrow server-side Data API gate.

### Design qualification result — 2026-11-01

| Mechanism | Can deny before Notes migration #1? | Survives #1/#6 grants? | Protects table reads and RPCs? | Unrelated PostgREST impact | Result |
|---|---:|---:|---:|---|---|
| Scoped table/RPC `REVOKE` | No durable default: #1 grants table/RPC access | No; #1/#6 regrant | Yes only while revoked | Narrow | Not sufficient |
| RLS-only policy | No, table does not yet exist | Table policy can survive grants, but not RPC invocation itself | No for RPCs | Narrow | Not sufficient alone |
| Flutter/client capability flag | No | No | No; direct clients bypass it | None | Not authorization |
| Disable/remove whole Data API or exposed schema | Yes | Yes | Broadly | Breaks Nutrition, Workout, Profile and other PostgREST traffic | Unacceptable |
| `pgrst.db_pre_request` exact-path hook | Yes | Yes, independent of later Notes grants | Yes for PostgREST table/RPC paths | Hook executes on every PostgREST request; failure can affect all Data API traffic | Narrowest viable repository implementation; disposable-qualified |

**Conclusion:** Under the current requirement of one default-deny control installed before #1 and left effective through #6/#8 without editing the eight merged Notes migrations, the supported PostgREST hook is necessary. The repository candidate is disposable-qualified under the recorded Owner Approval; hosted apply, activation and merge remain separate gates.

### Exact matching, privilege and bypass qualification requirements

- Match only the documented PostgREST `request.path` forms for the Notes table and the three public mutation/reconciliation RPCs; test leading slash, case changes, URL encoding, trailing slash, query strings, `GET`/`HEAD`/`POST`, and unknown `rpc/*` paths. Do not derive authorization from `owner_id`, request JSON, headers supplied by the client, or Flutter state.
- Keep the hook in a non-exposed schema, use `SECURITY DEFINER` with an empty/fixed `search_path`, and grant only the execution path required by PostgREST configuration. `PUBLIC`, `anon`, `authenticated`, and ordinary application execution must not gain hook control.
- Treat an absent, malformed, stale, or unreadable operator setting as deny for Notes. A hook exception, missing function, failed `NOTIFY pgrst, 'reload config'`, or uncertain role configuration is a deployment stop; it must not be interpreted as Notes enabled.
- The hook protects only PostgREST. Realtime, Storage, GraphQL, Edge Functions, and direct database connections are bypass surfaces. The qualification must prove that Notes are absent from Realtime publications, Storage objects/buckets/policies, GraphQL exposure, and alternate Edge Function routes. A trusted direct database operator can bypass this HTTP gate by design; that is not client release access.
- Because the local API exposes `public`, `storage`, and `graphql_public`, GraphQL is an explicit go/no-go check. If Notes become queryable there, this gate cannot be recommended without a separately approved GraphQL control or exposure change.

### Required disposable test matrix and recovery

Use synthetic disposable users/fixtures only and a loopback PostgREST instance. Test: anonymous, authenticated owner, cross-owner, and unauthenticated access; table GET/HEAD and RPC POST; before Notes objects; after #1; after each grant-changing boundary including #6; after #7 and #8; exact enabled, disabled, absent, malformed and unknown settings; hook/config failure-stop; reload and recovery; and representative Nutrition, Workout, Profile/auth-related Data API paths. Confirm the same owner/RoutineId and `(user_id, canonical ExerciseRef)` protections remain enforced when the gate is enabled.

Rollback in the disposable environment is to stop the local PostgREST process, reset the temporary `authenticator` hook and gate settings, issue the supported config reload, verify Notes denial and non-Notes recovery, then recreate the disposable database if configuration state is uncertain. No hosted `ALTER ROLE`, `NOTIFY`, migration apply, fixture, or recovery write is authorized by this brief.

### Corrected qualification findings — 2026-11-01

The authorized normal-terminal qualification accessed Docker Desktop `4.97.0` / Engine `29.9.2` through `desktop-linux` and replayed the 72-migration prefix plus all eight Notes migrations in a disposable PostgreSQL/PostgREST runtime. It confirmed: arbitrary `app.*` gate-state GUC configuration is not supported by the qualified PostgreSQL 17 role; a private state table is required for this design; the hook must be executable after PostgREST role impersonation; malformed `PGRST` detail without `headers` is invalid; a missing hook function can fail unrelated Data API requests; and explicit configuration reload/recovery must be tested. The disposable runtime and synthetic fixtures were removed after testing.

**Runtime result:** `PASS for the corrected disposable repository mechanism; implementation validation is complete. Final slice status is ready for focused PR review, with merge/deployment still blocked.

### Failure and recovery states

| State | Expected result |
|---|---|
| Gate setting absent/false | Notes table/RPC paths denied; non-Notes paths continue |
| Exact enabled setting | Notes paths may reach existing grants/RLS/RPC authorization; no UI enablement implied |
| Malformed/unknown setting | Notes paths denied; no implicit enable |
| Hook/config failure | Stop deployment and treat Data API behavior as unverified; do not proceed to the next migration or release |
| Disable/recovery | Trusted operator disables setting, reloads PostgREST, verifies Notes denial and ordinary non-Notes recovery |

## 5. Implementation Plan (after approval only)

- [x] Record explicit owner approval for the exact mechanism and project-wide PostgREST impact.
- [x] Add one pre-Notes migration; do not modify the eight merged Notes migrations.
- [x] Add focused SQL/catalog assertions for function security, fixed `search_path`, exact ACLs, role config, default-deny state, path allowlist, and unchanged Notes grants/RLS/RPC definitions.
- [x] Add a disposable PostgREST HTTP stage harness with synthetic fixtures and strict environment/credential guards, following the existing #569 loopback-only pattern.
- [ ] Exercise baseline-before-Notes, migration #1, each grant-changing boundary including #6, migration #7/#8, enable, disable, malformed state, failure-stop and recovery.
- [ ] Verify ordinary non-Notes Data API requests and all required anonymous/authenticated owner/cross-owner/unauthenticated cases.
- [ ] Verify Realtime/Storage/GraphQL/direct-DB/Edge Function limits and stop if any alternate surface exposes Notes contrary to this brief.
- [ ] Run applicable migration, RPC/RLS/security suites, `supabase db lint` where available, and `git diff --check`.

## 6. Quality Review

### Validation run

```text
Read-only design audit and implementation-ownership check completed at `main@cd81393598b5f82606c10c38058296b9052e57f4`; authorized implementation and disposable validation completed on `codex/routine-notes-data-api-gate`.
Live GitHub: PR #719 is `MERGED`/`APPROVED` at this HEAD; issue #716 is `CLOSED`/`COMPLETED`; only unrelated draft PR #627 is currently open.
Live Linear: `TNYX-81` remains `Backlog`, with `TNYX-78` and `TNYX-80` blockers. Product Owner approval and local implementation ownership are recorded in the authorization and this brief; no Linear status mutation was authorized.
Source inspection covered all eight Notes migrations, their table/RLS/RPC/receipt/retention/scheduler/identity behavior, `supabase/config.toml`, CI replay conventions, and the existing PostgREST harness.
Previous disposable qualification executed Docker Desktop `4.97.0` / Engine `29.9.2`, Supabase CLI `2.121.0`, 72-migration replay, all eight Notes migrations, temporary hook/HTTP matrix, synthetic owner/guest/anonymous requests, non-Notes regression, malformed/missing state, configuration failure, recovery, GraphQL/catalog alternate-surface checks, `supabase db lint`, and the existing Routine Notes persistence SQL test. Temporary containers, fixtures, and files were cleaned up.
No hosted Supabase write, production migration/hook activation, existing Notes migration edit, commit, push or merge was performed. The authorized repository source slice is ready for commit/PR review; no production behavior changed.
```

### Acceptance evidence

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Gate mechanism and project-wide impact are recorded before implementation | This task brief | Corrected design records the private state-table requirement, exact path allowlist, role grants, valid 403 response, project-wide failure mode, recovery and alternate-surface boundaries; Product Owner approval is recorded | `cd813935`; repository + Supabase docs + disposable qualification | Production configuration and independent review remain open |
| Hosted Notes remain unreleased | Existing deployment packet; read-only hosted state | 72 migrations applied; Notes table/RPC objects absent; no gate config present | Hosted project `oykupyiitspujzpwwvuj`, 2026-11-01 | Refresh is read-only and can become stale |
| Existing Notes contract is preserved | Eight existing migrations | Source inspection confirms RoutineId and `(user_id, ExerciseRef)` ownership and existing ACL/RLS/RPC/receipt/scheduler boundaries; current diff does not modify those files | `cd813935` plus authorized branch | Disposable replay and independent review remain open |

### Review provenance

**Review source / link:** Supabase official docs, repository source, live Linear/GitHub/Supabase read-only refresh, and manual preflight
**Reviewer / relation to implementer:** Self-review of preflight; no implementation review yet
**Diff or commit SHA actually reviewed:** `cd81393598b5f82606c10c38058296b9052e57f4` plus this uncommitted brief
**Review result and finding IDs/dispositions:** Disposable findings are dispositioned in the corrected design. During implementation validation, the initial no-leading-slash allowlist was found to pass disabled Notes HTTP access (`200`) and was corrected to exact leading-slash paths; the corrected replay and HTTP matrix passed. Repository implementation self-review is complete; independent security review is required before merge. Owner Approval and Implementation ownership are recorded.
**Independent review?** No (self-review)
**Limitations and unmet required gates:** No independent security review, no hosted configuration/activation evidence and no merge authorization. The disposable runtime does not start full Realtime/Storage/Edge endpoint services; catalog/source checks remain the bounded alternate-surface evidence for this repository slice.

## 7. Final Handoff

### Changed files

- `.ai/tasks/routine-notes-server-side-data-api-gate.md`
- `supabase/migrations/20261028120000_install_routine_notes_data_api_gate.sql`
- `supabase/tests/database/tnyx_81_routine_notes_data_api_gate.test.sql`
- `supabase/tests/database/tnyx_81_routine_notes_data_api_gate_smoke.py`
- `.github/workflows/supabase-db-ci.yml`

### Actual behavior

The authorized repository slice installs a default-disabled private fail-closed PostgREST hook before the Notes migrations, asserts its security catalog contract, and exercises it only in the exact disposable CI database. Production behavior is unchanged because no hosted migration or activation was performed.

### Known limitations

- The gate is implemented in the repository candidate and remains disabled by default; it is not activated in production.
- Hosted Notes migration deployment remains blocked by the existing production approval packet.
- `db_pre_request` does not cover Realtime, Storage, GraphQL, Edge Functions, or direct database connections; alternate-surface verification is mandatory before a release claim.
- The corrected private state table is included only under the recorded Owner Approval for this repository slice; hosted apply remains separately unauthorized.
- The disposable qualification is not hosted or production evidence; `db_pre_request` still does not cover Realtime, Storage, GraphQL, Edge Functions, or direct database connections.
- No commit, merge, hosted write, production hook activation or Notes feature enablement was performed. PR creation and independent review remain after validation.

### Final status

`IN PROGRESS` — Owner Approval and Implementation ownership are recorded; the bounded repository implementation exists on `codex/routine-notes-data-api-gate`. Final disposition is pending disposable replay, CI/review evidence, focused PR and independent security review. Merge and deployment remain blocked.
