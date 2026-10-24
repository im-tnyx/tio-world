# #567 D1 — Atomic owner-safe Delete Program backend (source only)

**Status:** In review — [draft PR #678](https://github.com/im-tnyx/tio-world/pull/678); source-only, NOT deployed / NOT merged
**Primary owner:** Connected agent, backend/Supabase scoped implementation owner
**Affected platforms:** Supabase migration and disposable database CI only
**Tracking:** [GitHub #567](https://github.com/im-tnyx/tio-world/issues/567), [Linear TNYX-81](https://linear.app/tnyx/issue/TNYX-81), TNYX-267

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
- [x] Actual disposable two-session Delete-first vs Move-first races: source delete and membership CAS prevent data loss. Additional Create/Edit races are not separately exercised and remain residual review scope.
- [x] Supabase Database CI #40120111307 SUCCESS on source HEAD 521c4761 including SQL matrix, both two-session races and migration replay. Final handoff-only HEAD still requires green exact-head recheck.
- [ ] GitHub exact-base compare: only scoped files; independent review/security findings disposition; do not merge or deploy on this instruction.

## Active handoff

**Branch:** `tnyx/567-d1-atomic-program-delete`, based on `cf73c051e85b17d5e38c83569f4c164da5d60f02`.
**Implementation state:** Active, one backend-only slice.
**Validation:** GitHub [Supabase Database CI #40120111307](https://github.com/im-tnyx/tio-world/actions/runs/40120111307) SUCCESS at 521c476142497365fab3aa5572277174b813dddc; GitHub docs hygiene and required attribution SUCCESS there. Database CI includes rollback-only owner A/B, guest, two-Routine child-ID preservation, renamed default, empty/no-default, stale snapshot, revision overflow rollback, exact retry fail-closed, and two real Delete/Move order races. Hosted security advisor read-only: 13 existing authenticated SECDEF warnings (including #569) plus leaked-password WARN; this new RPC is not deployed and remains client-denied in disposable DB. No local Windows toolchain/diff was run.
**Review provenance:** Connected assistant manually reviewed own branch (self-review, NOT independent); detected and corrected PostgreSQL COALESCE qualification at 521c4761. No formal independent review yet. Residual: D2 client UNKNOWN readback, source+new Create concurrency coverage before public activation, release rollout/security acceptance. **Next:** Verify CI at final documentation HEAD, request separate im-tio review, leave PR unmerged until explicit owner Go merge; hosted deployment remains separate.