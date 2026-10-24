# GitHub #569 R3 — Production Move RPC authenticated exposure PR

**Status:** In progress — implementation source and database security verified at prior exact HEAD; API rollback acceptance and release approvals gated.
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
**Repository state last verified:** GitHub `main@c0c90caa9a092ebd1572e7ad96f76aeac39eed34` (PR #673 squash merge). Remote source HEAD at the start of this handoff reconciliation: `2c71bf7b24869928db58c341aa19261ea37d4a7f`. This docs-only update changes the PR HEAD; always recheck the current remote SHA and exact-head CI before a gate decision. User's Windows checkout was not accessed from this remote session.
**PR / tracking:** https://github.com/im-tnyx/tio-world/pull/674; GitHub #569 OPEN.
**Review threads:** Previous P2 fail-closed mutation body-drift finding **resolved**, zero unresolved review threads at last verified GitHub audit. Human review remains pending.
**Current blocker:** No verified independent human security sign-off or exact role-wide production exposure approval. Explicit hosted migration deploy GO separately required.
**Next exact action:** Verify the newly added disposable PostgREST API-level grant/revoke smoke on final PR HEAD, inspect any failures, and collect exact CI run/step evidence. Keep exposure blocked until successful.

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

**New isolated acceptance implementation in PR #674:** `supabase/tests/database/tnyx_569_r3_postgrest_revoke_smoke.py`, run by `.github/workflows/supabase-db-ci.yml`. It requires `GITHUB_ACTIONS=true`, the **exact** local PostgreSQL URL `postgresql://postgres:postgres@127.0.0.1:54322/postgres`, full R3 migration ledger and a disposable empty fixture namespace. It boots a temporary PostgREST v12.2.12 container using CI-only JWT signing material and performs HTTP RPC calls for all three functions before revoke, after committed revoke and after restore. It verifies owner/guest/anon behavior, preserves Program/Routine data, and has cleanup for temporary Auth identities and the PostgREST container. The test is **not hosted production evidence** and **must not be marked PASS without the successful exact-head run**.

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

**Last fully verified database code checkpoint, BEFORE new API smoke addition:**
- **Source HEAD `f44fa2d28cb5ad821159205d626257b993e532d3`**: [Supabase Database CI #40096935495](https://github.com/im-tnyx/tio-world/actions/runs/40096935495) **SUCCESS**, including complete 70-version disposable migration replay, SQL grant/rollback matrix, Move/Create/Full-Undo and two-session race tests, and lint.
- [Docs Hygiene CI #40096935473](https://github.com/im-tnyx/tio-world/actions/runs/40096935473) **SUCCESS**; [attribution #40096934318](https://github.com/im-tnyx/tio-world/actions/runs/40096934318) **SUCCESS** at that SHA.
- Prior CI failures and fixes are historical: Full Undo SQL-dollar-quoting corrected; initial body-fingerprint mismatch traced to CRLF/LF formatting and fixed with normalization. Do not present those runs as current failures.
- Previous P2 inline thread source correction independently verified as code via connected-account COMMENT, then resolved. Human security sign-off is not established.

**New API acceptance:** The first PostgREST HTTP smoke check is newly authored and wired at source HEAD `2c71bf7b24869928db58c341aa19261ea37d4a7f`; **result not verified yet**. Final exact-HEAD run must show SUCCESS for the named `Verify #569 R3 real PostgREST HTTP grant, committed revoke and regrant` step, with owner/guest/anon and post-revoke three-RPC response evidence. A failing run is a blocker and must be fixed rather than recorded as PASS. This documentation reconciliation itself changes the PR SHA; recheck latest GitHub checks.

**Not yet evidenced:** Real hosted production PostgREST acceptance (forbidden before deploy approval), physical Android/iOS release-build QA, human security sign-off, owner policy approval, authorized hosted GRANT, or Flutter ON.

### API-level revoke/rollback acceptance gate (hard BLOCKER)

Before production exposure require a successful, referenced **disposable** API run proving all three RPCs deny new permanent-account HTTP requests after **committed** revoke (not just SQL transaction rollback), with no Routine/Program mutation, fixture cleanup and regrant restoring legitimate access. Prior to any hosted apply, verify target project, reviewed SQL migration version/source hash, release/rollback plan, hosted 69-migration baseline, and owner plus human security approvals. After explicitly authorized hosted apply, do *read-only hosted* role/ACL verification and authorized bounded non-destructive smoke before turning Flutter Move ON. SQL catalog privilege checks alone do not close the HTTP gate.

## 5. Implementation Plan / Release Sequence

- [x] R2 merged access-contract groundwork (#673).
- [x] Prepare reviewed exact three-signature grant migration and fail-closed body fingerprint preflight.
- [x] Update current-state ACL migration test and add BEGIN/ROLLBACK revoke drill.
- [x] Verify reviewed database code at `f44fa2d2` (Database/Docs/Attribution CI SUCCESS).
- [x] Address P2 finding; GitHub inline thread resolved.
- [x] Add isolated HTTP PostgREST committed revoke/regrant test and wire into disposable CI (**code only; acceptance pending**).
- [ ] Exact-current-HEAD CI success with explicit HTTP test step result.
- [ ] Verify fixture cleanup and no data/role permission leaks; resolve any CI failures.
- [ ] Genuine independent human security sign-off.
- [ ] Explicit owner approval for all permanent signed-in users to access the three protected RPCs.
- [ ] Separate hosted migration apply approval and post-apply verification.
- [ ] Later R4 Flutter ON and Android/iOS release QA.

## 6. Final Handoff

**Changed files (R3 PR):** Guarded grant migration, central ACL contract, transaction SQL rollback drill, permanent-owner/guest test, Database CI workflow, new PostgREST smoke, this handoff/index.
**Actual hosted behavior:** R3 has **not** been deployed; last verified hosted count 69 through `20261024090000`, and three Move RPCs `authenticated EXECUTE=false`. Nothing in this PR documentation approves production grants.
**Review provenance:** GitHub `im-tio` review is assistant-operated `COMMENTED`, not a human APPROVED review. P2 source finding closed. Codex review attempt was quota-limited and Cursor checks neutral.
**Known limitations:** HTTP smoke CI proof pending at handoff update; no independent human sign-off; no hosted exposure/rollback drill; no device release QA.
**Final status:** **REVIEW / SECURITY-GATED**. Never infer production readiness from a green SQL CI run or from PR being GitHub-mergeable.
