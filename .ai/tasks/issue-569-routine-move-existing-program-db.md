# GitHub #569 — M1 Existing-Program Routine Move (DB)

**Status:** M1 backend validated in disposable GitHub CI, release BLOCKED by one unresolved P2 legacy Rename compatibility decision; Draft PR #588, not deployed.
**Primary owner:** GitHub-connected implementation session (single implementation owner).
**Affected platforms:** Supabase Postgres/RLS. No Flutter, Watch, service/API, UI, or deployed database changes.

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product feature slice.
**Approval status:** Approved by owner in GitHub #569 and 2026-10-17 conversation: “Go start @Supabase @Linear @GitHub Follow agent.md” after fresh audit.
**Approved scope:** M1 only: atomic owner-checked move of one persisted Routine between two already persisted owner-owned Programs, preserving its UUID, Exercise/Set child IDs and order. Add one least-privilege RPC, SQL negative tests, review handoff.
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
**Validation completed:** Live read-only Supabase still has 62 migrations, no deployed Move RPC, authenticated program_id UPDATE denied and legacy name UPDATE granted. **Exact code HEAD `5dab58b69d8f2a2c20fc87cbc3caf921d1bdf92d`: Supabase Database CI #39022276556 SUCCESS 46/46**, including all migration replays/old SQL matrices, M1 ownership/replay/ABA and source-cleanup idempotency matrix, original Move/Delete two-session harness, four new two-session races (Edit→Move, Move→Edit, Move→Move, disappearing target) and db lint comparison. P2 #1 review thread resolved after verified test; #2 unresolved.
**Validation remaining:** Owner-approved minimum-supported-client / legacy Rename write-contract decision before any rollout, final independent latest-head review and branch/ruleset required-check verification at merge gate, hosted post-deployment advisor check only after authorized deployment. SQL migration filename generator was not available in connector-only runtime. CI verification applies to **code HEAD 5dab58b6**, not to later docs-only handoff commits.
**Current blocker:** PR #588 review **P2 #1 resolved** by corrected exact Move retry after source cleanup, validated in CI #39022276556. **P2 #2 remains release blocking**: legacy authenticated Data API `UPDATE(name)` uses only `user_id + id`, not source/revision CAS; after Move a stale original-Program UI can rename the Routine at destination. Server cannot distinguish stale vs fresh legacy Rename without new request context. Silently removing/breaking legacy grants is not approved. Owner must decide minimum-version/compatibility sunset; do not resolve thread or activate Move until a safe rollout is reviewed.
**Next exact action:** Obtain explicit owner compatibility direction for legacy `UPDATE(name)`, implement only its bounded approved remediation, independently review exact diff, then evaluate merge/deployment. Keep PR Draft and hosted production unchanged.

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
4. Re-run the disposable SQL regression with **expected denial**, cross-owner, concurrent Move/Edit/Delete, old-token replay and supported-client tests; only then resolve P2 #2, consider PR merge/deployment and later Flutter Move activation.

**Decision status:** Awaiting product-owner authorization for a potentially breaking client compatibility change. The M1 PR remains Draft; do not add an unapproved grant revocation, new table/column, service or UI flow. Preserving the old unrestricted Rename grant and shipping Move together is **not** the safe default.

## Implemented Branch Files

- `supabase/migrations/20261017100000_move_user_workout_routine_between_owned_programs.sql`
- `supabase/tests/database/tnyx_569_existing_program_routine_move.test.sql`
- `supabase/tests/database/tnyx_569_existing_program_routine_move_concurrency.sh`
- `supabase/tests/database/tnyx_569_routine_move_cross_races.sh` (four additional real two-session interleavings; latest CI not yet verified)
- `.github/workflows/supabase-db-ci.yml` registers the new SQL matrix and both two-session race harnesses in disposable GitHub CI.
- This task brief. No live migration, direct client grants or Flutter Move capability changes.

## Quality and Handoff Status

**PASS for M1 disposable SQL and concurrency validation at code HEAD `5dab58b6`; BLOCKED for release.** CI #39022276556 passed 46/46. Source-deleted exact retry P2 resolved on verified evidence. Legacy stale Rename P2 remains open and needs owner-approved compatibility/rollout disposition. PR remains Draft; no production migration or Flutter activation. No physical device or Flutter QA claimed. Do not claim the Move UX is enabled. The preexisting task-index #526 Slice B status is stale versus verified merged PR #587; that unrelated documentation reconciliation remains its own task.
