# GitHub #569 — M1 Existing-Program Routine Move (DB)

**Status:** M1 dormant-stage exact-code CI PASS; independent review / merge-gate checks pending. Legacy Rename P2 remains activation-blocking; Draft PR #588 unmerged, hosted Supabase unchanged.
**Primary owner:** GitHub-connected implementation session (single implementation owner).
**Affected platforms:** Supabase Postgres/RLS. No Flutter, Watch, service/API, UI, or deployed database changes.

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product feature slice.
**Approval status:** Approved by owner in GitHub #569 and 2026-10-17 conversation: “Go start @Supabase @Linear @GitHub Follow agent.md” after fresh audit.
**Approved scope:** M1 only: atomic owner-checked move of one persisted Routine between two already persisted owner-owned Programs, preserving its UUID, Exercise/Set child IDs and order. Add one least-privilege RPC, SQL negative tests, review handoff. **Merge-stage security amendment:** keep new Move RPC installed but EXECUTE denied to `PUBLIC`, `anon`, `authenticated` and `service_role` until the unsafe legacy name-writing path is retired. Activation requires a separate reviewed grant migration; CI temporarily grants only in disposable database.
**Explicit non-changes:** No Supabase table/column/constraint shape change, no direct client UPDATE(program_id) grant; no canonical My Program resolution (#568), quota numeric ceilings (#554), Create & Move, Program Delete (#567), Flutter provider/3-dot UI activation, UI redesign, production deployment or new services/api.

## Active Handoff

**Planning owner:** GitHub #569; Linear TNYX-81 broader W4 and TNYX-267 W6B.
**Implementation owner:** GitHub-connected implementation session.
**Review owner:** Independent reviewer pending.
**Implementation ownership state:** Active; isolated branch, not deployed.
**Repository state last verified:** 2026-10-17 via GitHub API.
**Branch:** `tnyx/issue-569-m1-existing-program-move-db`
**Base/main HEAD SHA:** `acd74a618234127e675cdedef8f9a0c2d2201ea5`
**Observed working-tree state:** GitHub repository API branch only. Local Windows working tree and `git status -sb` not accessible from this session. No local files modified.
**PR / tracker:** Draft PR #588; GitHub #569; TNYX-81 remains Backlog.
**Relevant execution surface:** `supabase/migrations/` and `supabase/tests/database/`.
**Validation completed:** Read-only hosted Supabase unchanged at 62 migrations with Move RPC absent and authenticated direct program_id UPDATE denied/legacy name UPDATE granted. **Exact dormant code HEAD `0887bdad1dc21e30e8199fd02fa54ec4bb000e48`: Supabase Database CI #39024657322 SUCCESS, all 45 steps**: replay full migrations, assert Move EXECUTE initially denied to client roles, temporary GRANT only inside rolled-back SQL transaction/CI disposable race fixture followed by REVOKE and denied-grant assertion, all prior SQL suites, source-cleanup retry, Move/Delete, 4 cross-operation two-session races and database lint. Known unsafe-legacy-Rename regression intentionally demonstrates exposure only with CI test-grant. Native P2 #1 resolved; P2 #2 awaiting reviewer dormant-stage disposition and separately required activation remediation.
**Validation remaining:** Independent exact-head security review, native P2 dormant-stage review disposition, branch protection / required-check evidence (branch-protection API currently HTTP 403 and visible rulesets list empty), and explicit user instruction before merging. Hosted advisor is baseline-only until a separately authorized deploy. Before any Move activation, owner approval for legacy Rename/client-version sunset, protected current-client Rename/Create reconciliation and server-side grant retirement is mandatory. Supabase CLI migration-name generator unavailable in connector-only runtime; CI verification applies to **code HEAD 0887bdad**, before docs-only handoff updates.
**Current blocker:** PR #588 P2 #1 resolved. P2 #2 remains **activation-blocking**, not bypassable by Flutter capability flags: old Data API `UPDATE(name)` lacks source/revision. New M1 function EXECUTE is denied to every client role, so a code-only merge cannot invoke Move through the new RPC. Reviewer must acknowledge this dormant merge-stage mitigation before P2 thread closure. Any future grant requires approved compatibility cutoff and old-Rename retirement. Independently verified review and merge instruction remain outstanding.
**Next exact action:** Complete exact-head independent dormant-stage SQL/security review and ruleset/required-check visibility, reconcile PR native thread and Linear issue, then STOP at merge gate for explicit owner merge instruction. Legacy Rename activation work requires separate owner compatibility approval; never deploy/grant as part of a code-only merge.

## Merge-Gate Safety Disposition: Dormant RPC

After fresh owner-directed merge-gate audit, active legacy Data API `UPDATE(name)` for authenticated clients remained confirmed in read-only live Tio-world. `public.move_user_workout_routine` is now **staged dormant**: the SQL function is defined but its migration explicitly REVOKEs EXECUTE from all client roles (PUBLIC/anon/authenticated/service_role), **without a replacement grant**. The current metadata-only Rename and post-unknown-Create fallback continue to work because their existing `UPDATE(name)` grant is left untouched; no UI action or protected Move capability is enabled.

- **Why this unlocks safe code-only review:** production clients cannot perform any Move through the new RPC even after a future *separately authorized* migration deployment. Thus stale legacy Rename cannot operate on a Routine *moved through this disabled capability* yet. This is a mitigation by non-activation, **not** a fix to the legacy Rename P2. Other movement mechanisms remain out of scope.
- **CI contract:** full migration replay asserts Move is denied to all API client roles. SQL matrix grants authenticated EXECUTE inside a `BEGIN…ROLLBACK` fixture only. Existing two-session race scripts receive a guarded temporary `GRANT` on exact disposable GitHub CI Postgres and `REVOKE` afterward, with negative permission assertion; no hosted writes. Core cross-owner, idempotency, concurrency and existing unsafe-legacy-Rename repro stay covered.
- **Activation/release gate:** before any `GRANT EXECUTE` for `authenticated`, migrate current Flutter `ProgramRoutinesController.rename()` and `_reconcileCreate()` to safe owner+Program+revision-checked paths, determine supported old-app deprecation/upgrade contract (docs are policy-only, no deployed min-version gate), and server-enforce closing the old `UPDATE(name)` bypass. Reviewer and owner must expressly approve that separate compatibility/activation step.
- **Merge authority:** code-only PR #588 may progress to **merge-gate review** if latest exact-head CI is green, scope and governance gates verified and P2's disposition as activation-only accepted by reviewer. No automatic merge, prod DB apply, client rollout, or activation is authorized by reaching this gate. Keep P2 native review thread open until latest branch's reviewer disposition is recorded.

## Verified Discovery

- `AGENTS.md`, `apps/features/AGENTS.md`, canonical architecture/ownership/Supabase docs, `.ai/FEATURE_DEVELOPMENT.md`, task protocol, push/PR templates were read.
- Live Tio-world `ACTIVE_HEALTHY`; 62 applied migrations through `20261016220000`; no Move RPC; existing aggregate `composition_revision`, `last_composition_mutation_id`, `last_routine_update_request_hash`.
- Existing `delete_user_workout_routine` takes account key-share, parent Program key-share, private routine UUID lock and routine row FOR UPDATE. New M1 RPC maintains compatible lock ordering and deterministic ordering of both Program locks.
- Existing Edit checks parent Program ID and revision. A->B->A without revision increment would allow ABA stale edits; M1 bumps aggregate revision on *every* move and overwrites most-recent mutation marker/hash.
- Child Exercises/Sets are keyed to stable Routine UUID and owner, so a parent-only reparent operation preserves composition rather than copying or deleting.
- Supabase Security Advisor before this code lists nine existing callable SECURITY DEFINER functions. After deployment, the new intentional authenticated RPC may be an additional WARN that requires scoped authorization justification, not blanket removal.

## Contract and Failure Semantics

`public.move_user_workout_routine(p_routine_id uuid, p_source_program_id uuid, p_destination_program_id uuid, p_expected_revision bigint, p_client_mutation_id uuid) returns bigint`.

- Signed-in owner only; account + BOTH parent Programs verified and locked; foreign/deleted/missing concealed via P0002; same destination or invalid input 22023.
- UUID identity lock serializes with permanent Delete anti-resurrection; routine row lock serializes with Edit, legacy Rename and composition Save.
- Revision compare-and-swap prevents stale writes and ABA. One transaction updates only the parent Routine's Program, revision and existing protected replay fields; no child modification.
- Frozen exact-request retry returns committed revision only if latest marker/hash, destination and revision match. It may succeed after its formerly owned source Program is deleted; a NEW move still requires owned source and destination. After a different aggregate mutation, never infer success.
- Different same-token requests, stale revisions, unavailable/deleted destination and auth failures fail closed. Unknown-result recovery in future Flutter adapter must re-read authoritative owner/program/revision and NEVER generate a new token automatically.
- Read committed required for visibility after lock waits, matching existing Routine retirement guard.
- No numeric quota invented; #554 policy must be reconciled before full UX release.
- Rejected design: copy Routine into target then delete source; violates stable identity/child reference preservation. Rejected: broad authenticated UPDATE(program_id) permission; bypasses authorization/CAS/atomic retry.

## Legacy Rename P2: Release Compatibility Gate (2026-10-17)

**Current behavior proven:** the signed-in legacy Data API UPDATE(name) accepts owner+Routine UUID only. A stale Program A screen can therefore rename Routine R after the M1 RPC moves R from A to B. The added disposable M1 SQL regression records this **known exposure** (post-Move stale Rename still succeeds, aggregate revision increments, latest Move retry proof is invalidated) rather than treating the test as a safety PASS. This regression is expected to pass until a separately approved write-contract change replaces the unsafe behavior. NEVER treat a green CI result as resolution of this P2.

**Additional current-app compatibility impact:** `SupabaseRoutineRepository.rename(id, name)` and `SupabaseRoutineTableGateway.renameRow(userId, routineId, name)` still issue that direct Data API UPDATE. `ProgramRoutinesController.rename()` uses it for legacy metadata rename, and `_reconcileCreate()` uses it when a metadata Create may have committed before the response was lost. The newer Edit Routine composer uses the protected 7-arg RPC, but that alone does not retire all callers of the old privilege. Unconditional REVOKE UPDATE(name) today would also break still-connected source and any installed older clients.

**Required gate (no owner-approved cutoff yet):**
1. Choose and explicitly approve a compatibility cutoff for supported phone/watch/client builds and old direct Rename clients; record deprecation, adoption evidence and a safe upgrade path. Existing `docs/backend/API_LIFECYCLE.md` and `docs/planning/FEATURE_ROLLOUT.md` define policy only; **no runtime minimum-client/capability enforcement is deployed**.
2. Move supported current-client metadata Rename and post-unknown Create reconciliation to owner+Program+revision-checked protected server contracts without creating duplicate Routine IDs or silently retrying unknown mutations. Reuse existing Workout repositories/RPC semantics and separately review any newly required behavior.
3. At the separately authorized enforcement point, close the authenticated direct UPDATE(name) bypass server-side and demonstrate it is denied for stale/outdated callers while current supported Edit/Create paths still succeed. Do NOT trust a client-sent app-version header, visible Move button, or solely an in-app feature flag as authority.
4. For future activation, re-run the disposable SQL regression with **expected denial**, cross-owner, concurrent Move/Edit/Delete, old-token replay and supported-client tests. P2 may be dispositioned for **dormant code merge review** only because Move remains uncallable; it cannot be treated as solved for activation before those tests and the safe client rollout.

**Decision status:** Dormant server function and tested logic may advance to code-only merge gate without breaking current clients. It is NOT an enabled Move feature. Owner approval remains required before changing legacy UPDATE(name) or granting new Move EXECUTE. No new table/column, service, API, or UI flow.

## Implemented Branch Files

- `supabase/migrations/20261017100000_move_user_workout_routine_between_owned_programs.sql`
- `supabase/tests/database/tnyx_569_existing_program_routine_move.test.sql`
- `supabase/tests/database/tnyx_569_existing_program_routine_move_concurrency.sh`
- `supabase/tests/database/tnyx_569_routine_move_cross_races.sh` (four two-session interleavings, validated with guarded CI-only grant #39024657322)
- `.github/workflows/supabase-db-ci.yml` registers the new SQL matrix and both two-session race harnesses in disposable GitHub CI.
- This task brief. No live migration, direct client grants or Flutter Move capability changes.

## Quality and Handoff Status

**PASS for dormant-code disposable SQL and concurrency validation at HEAD `0887bdad`; pending independent merge review; client activation BLOCKED.** CI #39024657322 passed 45/45 including CI-only authorization and known-Rename exposure fixture. Source-deleted exact retry P2 resolved on verified evidence. Legacy stale Rename P2 remains open and needs owner-approved compatibility/rollout disposition. PR remains Draft; no production migration or Flutter activation. No physical device or Flutter QA claimed. Do not claim the Move UX is enabled. The preexisting task-index #526 Slice B status is stale versus verified merged PR #587; that unrelated documentation reconciliation remains its own task.
