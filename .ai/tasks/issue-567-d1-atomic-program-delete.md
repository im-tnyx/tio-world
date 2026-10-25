# #567 D1 — Atomic owner-safe Delete Program backend (source only)

**Status:** Validated source slice — [PR #678](https://github.com/im-tnyx/tio-world/pull/678) merged; source-only, NOT hosted-deployed / NOT activated
**Primary owner:** Connected agent, backend/Supabase scoped implementation owner
**Affected platforms:** Supabase migration and disposable database CI only
**Tracking:** [GitHub #567](https://github.com/im-tnyx/tio-world/issues/567), [Linear TNYX-81](https://linear.app/tnyx/issue/TNYX-81), TNYX-267

## Post-merge reconciliation (2026-10-25)

- PR #678 merged at `main@37f738c4a6788e3e997f1ab3938a2f6541f3644c`; the older branch, pre-merge review state, and source-head references below are historical evidence, not current repository state.
- Current `main@86fd082515c8cb8cc1ded93fb1a59d360c2f4582` contains the merged D1 source. The hosted Supabase migration has not been applied and client `EXECUTE` remains denied; no UI or production caller is activated.
- The bounded Flutter follow-up is tracked in [D2A](issue-567-d2a-flutter-program-delete-repository.md). D2A is source-only and does not change this D1 migration, grants, hosted state, or #567 status.

## Owner approval and boundary

**Approval evidence:** Owner previously approved non-default Program Delete with all saved Routines atomically retained in canonical default My Program and source removal (#567, 2026-10-15); owner's 2026-10-24 “go” to proceed with D1 after read-only audit, and requested reuse of Move Routine code.
**In:** A distinct additive protected PostgreSQL RPC in a new migration; transactional, source-only test matrix; additive disposable Database CI invocation.
**Out:** No new table/column or identity source, no direct table DELETE or client EXECUTE grant, no real hosted apply/mutation/QA, no Flutter UI/confirmation/release flag, no #569 hosted JWT QA or #568 activation.
**Gate:** Any need for an additional table/column (durable deletion receipt etc.) requires separate exact-shape owner approval.

## Discovery and verified evidence (2026-10-24)

- Protected GitHub `main@cf73c051e85b17d5e38c83569f4c164da5d60f02`; #567 OPEN; TNYX-81/TNYX-267 Backlog with broader W4 dependencies. No separate #567 PR active.
- Live hosted 70 migrations through `20261024120000`, with no general Delete Program RPC. `user_workout_routines(program_id,user_id)` references Program `ON DELETE CASCADE`. Child Routine Exercises/Sets would be at risk from naive Program DELETE. Authenticated direct Program DELETE and Routine reparent UPDATE are denied.
- `ProgramRepository` supports list/create/rename only. Program sheet lacks Delete; this D1 explicitly does not expose an incomplete action.
- `user_workout_programs.is_default` + owner-partial unique index already exist. #568 lazy default uses owner `FOR NO KEY UPDATE` and existing Move #569 uses sorted Program locks, per-Routine UUID advisory identity lock then row lock; existing Routine mutation/hash fields allow invalidation of stale edits and moves.
- GitHub-only connector environment: Windows checkout `G:\\projects\\Tio-World` not mounted, cannot claim native `git status`, `git diff --check`, `psql` or local Supabase CLI execution. Use GitHub compare and exact-HEAD Database CI instead.

## Chosen contract

`public.delete_user_workout_program_preserving_routines(p_source_program_id uuid, p_expected_routine_ids uuid[], p_client_mutation_id uuid) returns jsonb`.

- Guard trusted permanent account; source must be authenticated owner's non-default Program.
- Expected Routine ID array is an immutable UI-confirmation membership snapshot, not authority. Reject missing/null/duplicate IDs, compare exactly against the locked owner-scoped source membership. A changed set requires refreshed confirmation.
- One transaction: acquire account default-resolution lock; conditionally resolve/create default only if source is nonempty; lock source/destination Programs in UUID order, all existing Routine UUID locks sorted; update each Routine parent, increment revision exactly once and replace mutation/hash fields, then remove source with a second empty-child check. No child identity replacement.
- Empty source: no default created. If the preliminary snapshot had children but concurrent operations emptied source before protected lock, roll back any provisional default creation and delete the now-empty source only if the original expected list still matches; otherwise fail stale with rollback.
- Deny direct client Program deletion and all RPC EXECUTE for `PUBLIC`, `anon`, `authenticated`, `service_role` until reviewed separate activation.
- Exact repeated call after source deletion is **not** claimed as authenticated success: no durable deleted-Program receipt is introduced in this no-shape slice. It fails closed with opaque not-found. Future client UNKNOWN recovery must use authoritative owner reads; no program resurrection or duplicate transfer. A stronger exact replay proof would need a separately approved durable receipt shape.
- Preflight owner-bound FK dependencies. New unknown FK children should fail rather than silently cascade.
- Reject `READ COMMITTED` drift, revision overflow, stale membership and identity/owner mismatch, without side effects.

**Rejected:** Reusing the single-Routine RPC N times followed by client table DELETE; deleting with child FK cascade; building a new receipt table without exact-shape approval; exposing an untested UI action.

## Acceptance / validation gate

- [x] Source-only new migration with secure owned locking/atomic write/deny grants and no table/column changes.
- [x] Disposable SQL: >1 Routine child UUID preservation, default rename, no default/empty source, source-without-default, owner A/B, guest, replay, wrong snapshot, direct client DELETE deny, rollback on forced failure.
- [x] Actual disposable two-session Delete-first vs Move-first races: source delete and membership CAS prevent data loss.
- [x] Independent reviewer confirmed original P2 Edit-lock contract **FIXED** at `affa5f51`; both Delete/Edit race orders and child IDs PASS in exact-head CI #40125787630. Reviewer COMMENT, not APPROVE.
- [x] Direct Create/Delete and old-client metadata INSERT in **both commit orders**: four real two-session scenarios, stale snapshot and FK denial, protected Create source-not-found, Exercise/Set identity and zero orphan. `#40161902564` job 121075075417 **SUCCESS** on `77968478`. Independent reviewer follow-up still pending.
- [x] Full [Supabase Database CI #40161902564](https://github.com/im-tnyx/tio-world/actions/runs/40161902564) **SUCCESS** at `77968478968b709535382bc237f047d80d9599c`, including migration replay, SQL matrix, Move/Delete, Edit/Delete, Create/Delete and legacy INSERT races. Final handoff-only HEAD must rerun checks.
- [x] GitHub compare at `77968478`: 8 D1-only paths, 21 ahead / 0 behind, same `main` merge base. Independent final reviewer disposition and owner `Go merge` still required; do not merge/deploy now.

## Active handoff

**Branch:** `tnyx/567-d1-atomic-program-delete`, based on `cf73c051e85b17d5e38c83569f4c164da5d60f02`.
**Implementation state:** Active, one backend-only slice.
**Validation:** Source/test current-head [Supabase Database CI #40161902564](https://github.com/im-tnyx/tio-world/actions/runs/40161902564) **SUCCESS at `77968478`**. Inspected job 121075075417 real log: `#567 direct Create/Delete and legacy INSERT: both orders, no loss or orphan.` Existing Delete/Move and Delete/Edit races PASS. Docs Hygiene/Attribution also SUCCESS on `77968478`. Latest post-handoff documentation head requires separate exact-head recheck. Hosted Supabase remains at 70; new RPC not applied and authenticated EXECUTE not granted. No local Windows native Git or deployment claims.

**2026-10-25 continuation:** `im-tio` independently re-reviewed `affa5f51`, confirmed old P2 fixed, but kept COMMENT/no approval because direct Create-versus-Delete race evidence was missing. Added `supabase/tests/database/tnyx_567_atomic_program_delete_create_concurrency.sh` and new CI hook; hosted untouched. Actual four-case latest source-head [Database CI #40161902564](https://github.com/im-tnyx/tio-world/actions/runs/40161902564) PASSED; independent re-review still pending.

**Review provenance:** `im-tio` independently reviewed `5fec974f9742f4c13e32338671ade1357f59f86a` (COMMENTED, no approval), opened [P2 review thread](https://github.com/im-tnyx/tio-world/pull/678) on the incorrect Edit/Program-lock claim. Implementation owner fixed only the documentation of lock behavior and added explicit Edit-vs-Delete opposite-order, revision and child-preservation two-session CI tests; new commit `23f1a96d` before this handoff. P2 awaits exact-head CI and independent re-review. Self-review also corrected the earlier PostgreSQL COALESCE syntax at `521c4761`. Residual: D2 client UNKNOWN readback, hosted authorization QA, rollout/security acceptance. **Next:** Reconfirm final documentation HEAD CI, obtain `im-tio` independent review on latest 8-file delta, and explicitly disposition original outdated/unresolved thread; keep PR unmerged until owner Go merge. Hosted deployment remains separate. Hosted deployment remains separate.
