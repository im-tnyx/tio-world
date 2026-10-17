# #569 M3A — Existing-Owned-Program Move Repository Adapter

**Status:** Ready for Review — bounded Flutter Move repository and tests; source+docs exact-HEAD CI PASS at `1e14aacc2c25c9deb745464c1a5ee8a53ac830f8` (5/5 Flutter jobs + 2 attribution checks). Subsequent P3 task-handoff-only correction requires its own fresh HEAD checks.
**Primary owner:** Workout domain/data implementation (one remote branch).
**Affected platforms:** Flutter Workout feature package; no UI/runtime activation.

## Owner Approval and Scope Boundary

**Trigger:** None — #569 owner-approved Move capability; this is a bounded implementation subtask.
**Approval status:** Approved in #569 and current user instruction (2026-10-17).
**Approval evidence:** GitHub #569, Linear TNYX-81 and user go-next Work request.
**Approved behavior:** Move existing saved Routine to an existing same-owner Program via atomic M1 RPC without duplicating Routine/child IDs.
**Explicit non-changes:** No new database tables/columns, hosted GRANT change, authentication backend, UI geometry, selector or confirmation, +New Program/Create & Move, canonical My Program #568, Delete Program #567, or deployment.

## Active Handoff

- **Planning owner:** GitHub #569; Linear TNYX-81 W4 Backlog (broad scope; blockers retained).
- **Implementation owner:** `tnyx/issue-569-m3-existing-program-move-adapter` only; no parallel implementation.
- **Review owner:** GitHub manual/CI gate.
- **Implementation ownership state:** Active
- **Repository state last verified:** GitHub `main@20c1d21efe1760109b28daffa8990a9e77b4aca0`; 0 open PR at start.
- **Branch:** `tnyx/issue-569-m3-existing-program-move-adapter`
- **Validated PR HEAD before this docs-only review correction:** `1e14aacc2c25c9deb745464c1a5ee8a53ac830f8` (source/test commit `b56f389b6d3aed7875adf943776a9901a98068e9`). Do not transfer earlier checks to the new docs-only commit.
- **Observed working-tree state:** Local Windows `G:\projects\Tio-World` unavailable to this GitHub connector; owner previously posted clean `main` sync but cannot infer current local edits.
- **PR / tracker:** #569, TNYX-81.
- **Current implementation state:** Feature-owned optional Move RPC repository/gateway and process-shared attempt gate implemented; 15 focused security/SDK test cases confirmed PASS in Workout CI logs. No app Move callback; hosted EXECUTE still revoked.
- **Validation completed at SHA:** Flutter CI [#39052702429](https://github.com/im-tnyx/tio-world/actions/runs/39052702429) **COMPLETED SUCCESS** on exact prior PR HEAD `1e14aacc2c25c9deb745464c1a5ee8a53ac830f8`: Analyze Flutter/Dart, Workout tests (714 passed, incl. 15 new Move cases), Core/Wear, Nutrition/Onboarding, aggregate 5/5 plus both attribution checks. Source-only prior CI #39052169662 also PASS.
- **Validation remaining:** Fresh CI/attribution for this P3 docs-only correction HEAD; explicit owner merge authorization and any independent APPROVED review remain separate. Bounded manual COMMENTED reviews found no confirmed P1/P2. No physical-device or live authenticated Move test: hosted EXECUTE remains denied.
- **Current blocker:** Hosted `authenticated` Move EXECUTE intentionally revoked; UI adapter+controller/selector must be reviewed before distinct activation.
- **Next exact action:** Verify new docs-only HEAD CI and reply/resolve PR #595 P3 thread `PRRT_kwDOTOXwB86tioRj`; hold merge until explicit `Go merge` owner gate. Then separately plan M3B app-owned Move selector, confirmation and owner-scoped refresh. Coordinate #568 identity / Create & Move separately; only later review explicit Move EXECUTE activation.

## Discovery, Evidence and Design

GitHub source at the verified SHA: M1 Move RPC `move_user_workout_routine(uuid,uuid,uuid,bigint,uuid)` deployed by owner's Supabase CLI. Hosted Supabase 64/64 migrations applied, `UPDATE(name)` and direct `UPDATE(program_id)` denied, authenticated Move EXECUTE denied, protected Rename available. Runtime `SupabaseRoutineRepository` provides owner/cycle-bound metadata reads and Rename; `RoutineDeleteRepository` supplies separate optional inspect/one-use CAS gateway and process-lifetime uncertain-outcome guard. Existing 3-dot sheet has Move placeholder only. My Program stable owner identity #568 unresolved.

**Chosen:** Follow separate Workout domain/data optional Move capability, not add a direct Program UPDATE. Freeze target at owner-read with source Program/revision/name/account/login cycle. Consume one-use target on RPC dispatch, validate destination differs, require exact numeric ACK expected revision+1 for success. No retries after uncertain errors. Lock per owner/Routine across feature repos with an app-supplied attempt gate and block conflicting unconfirmed revision until a later strictly higher revision read. Transport opt-in RPC `retry(enabled:false)`. Keep outcome exceptions sanitized; no raw provider/health data exposed.

**UI/Design:** No rendered UI changes. App composition will later create one process-lived gate and conditionally pass a Move callback only after separately approved Move EXECUTE grant and destination UX/security integration.

## Quality Review

Verified exact prior PR HEAD `1e14aacc`: GitHub Flutter CI #39052702429 SUCCESS all five jobs plus both attribution checks. Manual COMMENTED reviews found no new P1/P2; no independent APPROVED review is claimed. An earlier `f58ec01c` analyzer found a missing named-parameter `)` and braces lint, corrected; intermediate runs were superseded, not counted as passes. No production SQL/Flutter runtime activation. P3 review correction only updates governance handoff, not Flutter source. Preserve old CI evidence only at its exact SHA until current HEAD reruns.

## Handoff

**Current:** Source+tests validated, PR #595 open/Ready for Review; no merge or Move EXECUTE. Next owner: M3B app-shell guarded callback and feature-owned Program selector/confirmation after approval/review. The prior `1e14aacc` docs-only handoff was exact-head CI-confirmed; this separate P3 correction requires its own new HEAD checks before the separately approved merge.
