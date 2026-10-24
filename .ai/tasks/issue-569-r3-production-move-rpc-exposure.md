# GitHub #569 R3 — Production Move RPC authenticated exposure PR

**Status:** Source and disposable API-level revoke/rollback acceptance **VALIDATED**; human security, role-wide owner exposure, hosted deploy and Flutter release gates still **BLOCKED**.
**Primary owner:** Supabase/PostgreSQL implementation `im-tnyx`.
**Affected platforms:** Supabase function EXECUTE ACL, disposable Database CI/PostgREST test; Flutter production gate unchanged.
**PR:** https://github.com/im-tnyx/tio-world/pull/674

## Owner Approval and Scope Boundary

**Trigger:** Continuation of approved #569 Move Routine feature, with security-sensitive role-wide API exposure as a separate deployment decision.
**Owner approval verified:** User authorized R3 PR preparation with "start kare", subsequent review/CI remediation, and explicitly requires **API-level revoke/rollback verification evidence before production exposure**. This does **not** authorize merging, granting `authenticated` EXECUTE on hosted, or turning on the Flutter production flag.
**Exact future exposure proposal:** Grant EXECUTE for three existing protected Move / Create & Move / Full Undo RPC signatures to the PostgreSQL `authenticated` role. Supabase Auth anonymous signed-in users also use this role but must fail server-side `auth.users.is_anonymous is false`. All eligible permanent accounts could invoke the API irrespective of Flutter UI release flag.
**Explicit non-changes:** No hosted SQL/apply, schema shape, function-body replacement, table UPDATE/DELETE grants, app UI/flag, production build, or #567 general Delete Program.

## Active Handoff

**Planning owner:** GitHub #569 OPEN; #567 separate. Linear TNYX-81 and TNYX-267 Backlog with broader blockers.
**Implementation owner:** `im-tnyx` R3 bounded PR.
**Review owner:** Genuine independent human security reviewer required; `im-tio` connected-account review is assistant-operated COMMENT and **not human sign-off**.
**Implementation ownership:** Active; branch `tnyx/569-r3-production-move-rpc-access`.
**Repository state last verified:** GitHub `main@c0c90caa9a092ebd1572e7ad96f76aeac39eed34` (PR #673 squash merge). Latest verified **implementation-source** HEAD before this docs-only reconciliation: `72cc7543502106d999be9c5f7084434b36ce5eb5`. Its Database/Docs/Attribution CI succeeded, including the HTTP smoke. The PR HEAD changes with documentation commits; recheck exact HEAD and required branch checks at merge gate. User's Windows checkout was not accessed from this remote session.
**PR / tracking:** https://github.com/im-tnyx/tio-world/pull/674; GitHub #569 OPEN.
**Review threads:** Previous P2 fail-closed mutation body-drift finding **resolved**, zero unresolved review threads at last verified GitHub audit. Human review remains pending.
**Current blocker:** No verified independent human security sign-off or exact role-wide production exposure approval. Explicit hosted migration deploy GO separately required.
**Next exact action:** Obtain independent **human** security sign-off and explicit owner decision about role-wide permanent-account API exposure; final PR merge eligibility remains gated. Do not deploy hosted grants until a separate exact-project/migration approval and rollout/rollback authorization.

## 1. Discovery and Outcome

Production goal: owner-safe Routine Move A → existing B with five-second Undo, or atomic new Program B Create & Move with full Undo. The existing Flutter implementation and protected PostgreSQL RPCs are merged behind an OFF production flag. R3 reviews the smallest **authorization surface**, not the UI or #567 Delete Program.

### Success Criteria

- Exact three RPC identities and approved complete function-body fingerprints survive preflight; schema RLS and direct-write denials stay unchanged.
- After forward migration on disposable CI: only `authenticated` gets function EXECUTE; `PUBLIC`, `anon`, `service_role` remain denied.
- Real anonymous signed-in Auth users cannot use the RPCs even though their DB role is `authenticated`.
- Owner, CAS, idempotency, provenance, concurrency and full Undo existing matrices pass.
- **Before hosted exposure**, independent disposable PostgREST HTTP test verifies all three RPCs with JWT role switching: permanent-owner requests reach protected function logic (without altering Program/Routine records), `anon` and guest requests fail closed, **committed** revoke blocks subsequent `authenticated` HTTP calls, re-grant restores expected behavior, credentials/fixtures/ACLs are cleaned.
- A true independent human security review, unambiguous owner role-wide exposure decision and separately authorized hosted deployment remain required even when CI is green.

## 2. Codebase Exploration

Verified `main` includes #569 Move/Create & Move and M5B full Undo backend functions. PR #674 adds `20261024120000_grant_move_routine_rpc_execute_to_authenticated.sql`, the migrated authenticated-only ACL gate, transaction rollback drill and CI invocation. P2 reviewer found the original preflight checked only auth text snippets; updated preflight now pins **complete normalized SHA-256 function-body fingerprints** for all three exact RPC definitions. Hosted definitions used CRLF while clean CI replay uses LF, so CRLF/CR → LF normalization is applied **only before digest comparison**. Last successful Database CI verified 70-migration replay and this P2 remediation.

**PostgREST acceptance gap found:** Existing `supabase/tests/database/tnyx_569_r3_grant_rollback.test.sql` uses `BEGIN ... ROLLBACK`. That verifies catalog privileges inside one transaction but not a committed revoke as observed through PostgREST HTTP. No prior GitHub evidence was found for that stronger acceptance.

**New isolated acceptance implementation in PR #674:** `supabase/tests/database/tnyx_569_r3_postgrest_revoke_smoke.py`, run by `.github/workflows/supabase-db-ci.yml`. It requires `GITHUB_ACTIONS=true`, the **exact** local PostgreSQL URL `postgresql://postgres:postgres@127.0.0.1:54322/postgres`, full R3 migration ledger and a disposable empty fixture namespace. It boots a temporary PostgREST v12.2.12 container using CI-only JWT signing material and performs HTTP RPC calls for all three functions before revoke, after committed revoke and after restore. It verifies owner/guest/anon behavior, preserves Program/Routine data, and has cleanup for temporary Auth identities and the PostgREST container. The isolated test is **not hosted production evidence**. It passed on implementation-source HEAD `72cc7543` in [Database CI #40099768691](https://github.com/im-tnyx/tio-world/actions/runs/40099768691), including explicit loopback-only PostgREST bind and checks for zero fixture-owned Workout records.

## 3. Architecture / Authority Decisions

| Decision | State | Boundary |
| --- | --- | --- |
| Prepare and review R3 guarded grant PR | Authorized | No hosted deployment |
| Three-RPC `authenticated` role-wide exposure for all permanent users | Owner decision pending | Flutter OFF does not block direct RPC |
| Genuine independent human security sign-off | Pending | Assistant-operated GitHub COMMENT does not qualify |
| Hosted forward migration apply | NOT authorized | Separate project/migration hash, backup/rollback readiness and exact GO |
| Flutter production flag ON | NOT authorized | Later R4/R5 and release-build QA |
| #567 Delete Program | Separate OPEN issue | No general Program delete granted |

## 4. Validation Evidence and Remaining Tests

**Verified current implementation-source checkpoint:**
- **Source HEAD `72cc7543502106d999be9c5f7084434b36ce5eb5`:** [Supabase Database CI #40099768691](https://github.com/im-tnyx/tio-world/actions/runs/40099768691) **SUCCESS**, including 70-version disposable migration replay; existing owner/guest/RLS/CAS/idempotency, grant/rollback, full Undo, two-session race and lint matrices; and the **new real HTTP/PostgREST committed-revoke/regrant step SUCCESS**. [Docs Hygiene #40099768590](https://github.com/im-tnyx/tio-world/actions/runs/40099768590) and [Attribution #40099767615](https://github.com/im-tnyx/tio-world/actions/runs/40099767615) also reported SUCCESS on this SHA.
- P2 full function-body fingerprint drift finding resolved with exact three normalized SHA-256 checks; zero unresolved inline threads at latest source review. GitHub `im-tio` account's reviews are assistant-operated COMMENT, **not** independent human approval.
- Historical SQL test quoting and CRLF/LF fingerprint issues were corrected before this successful run; they are not current failures.

**API-level revoke/rollback acceptance: PASS (disposable, non-production).** Exact step `Verify #569 R3 real PostgREST HTTP grant, committed revoke and regrant` finished **SUCCESS** in GitHub run [#40099768691](https://github.com/im-tnyx/tio-world/actions/runs/40099768691) at `72cc7543`. All three RPCs: permanent owner JWT reached server RPC and received deliberate missing-routine **HTTP 500 / SQLSTATE P0002** (function executed, not a successful business mutation); real anonymous Auth user received **403/28000**; anon role received **401/42501**; after **committed** authenticated EXECUTE revoke, previously valid owner JWT received **403/42501**; after exact-grant restoration owner again reached the RPC (**500/P0002**). Test verified zero fixture-owned Routine/Program rows, Auth fixture cleanup and restored ACL, and removed the temporary loopback-only PostgREST container. It uses isolated CI-only JWT signing material, not hosted credentials.

**Scope of this evidence:** Tests permission toggling and authenticated PostgREST fail-closed calls, **not** a successful production Move/Undo or a hosted grant rollback. The previously passing SQL/RLS/mutation/concurrency tests cover underlying business invariants. The hosted post-apply acceptance remains a later separately authorized gate.

**Not yet evidenced:** Real hosted production PostgREST acceptance (forbidden before deploy approval), physical Android/iOS release-build QA, human security sign-off, owner policy approval, authorized hosted GRANT, or Flutter ON.

### API-level revoke/rollback gate — disposable evidence PASS; hosted activation remains BLOCKED

Disposable committed-revoke HTTP acceptance is **verified** by CI #40099768691 on source SHA `72cc7543`; a SQL-only transaction rollback result is no longer being substituted for HTTP evidence. This does **not** approve production exposure. Before any hosted apply, independently verify exact target project, migration source/hash and pending ledger, recovery/rollback procedure, the current 69-migration baseline, true independent human security sign-off and unambiguous owner approval for all permanent signed-in accounts. After **separately authorized** hosted apply, perform live read-only ACL/role verification plus separately authorized bounded non-destructive HTTP smoke **before** turning Flutter Move ON. Revoking EXECUTE blocks new API calls, not already-in-flight transactions; reconcile UNKNOWN receipts.

## 5. Implementation Plan / Release Sequence

- [x] R2 merged access-contract groundwork (#673).
- [x] Prepare reviewed exact three-signature grant migration and fail-closed body fingerprint preflight.
- [x] Update current-state ACL migration test and add BEGIN/ROLLBACK revoke drill.
- [x] Verify current implementation source `72cc7543` Database/Docs/Attribution CI SUCCESS.
- [x] Address P2 finding; GitHub inline thread resolved.
- [x] Add isolated PostgREST committed revoke/regrant test with explicit zero-data-change assertions, loopback-only HTTP and disposable guards.
- [x] Confirm GitHub CI #40099768691 PASS at source HEAD `72cc7543`, including named HTTP step.
- [x] Verify three-RPC JWT owner/guest/anon matrix, committed revoke 403/42501, regrant recovery, no Routine/Program mutation and fixture/ACL/container cleanup.
- [ ] Recheck branch-head required checks after this docs-only commit before any merge.
- [ ] Genuine independent human security sign-off.
- [ ] Explicit owner approval for all permanent signed-in users to access the three protected RPCs.
- [ ] Separate hosted migration apply approval and post-apply verification.
- [ ] Later R4 Flutter ON and Android/iOS release QA.

## 6. Final Handoff

**Changed files (R3 PR):** Guarded grant migration, central ACL contract, transaction SQL rollback drill, permanent-owner/guest test, Database CI workflow, new PostgREST smoke, this handoff/index.
**Actual hosted behavior:** R3 has **not** been deployed; last verified hosted count 69 through `20261024090000`, and three Move RPCs `authenticated EXECUTE=false`. Nothing in this PR documentation approves production grants.
**Review provenance:** GitHub `im-tio` review is assistant-operated `COMMENTED`, not a human APPROVED review. P2 source finding closed. Codex review attempt was quota-limited and Cursor checks neutral.
**Known limitations:** Disposable API-level revoke proof PASS; genuine independent human security sign-off, explicit role-wide exposure approval, hosted deploy/post-apply validation and device release QA remain outstanding.
**Final status:** **REVIEW / SECURITY-GATED**. Never infer production readiness from a green SQL CI run or from PR being GitHub-mergeable.
