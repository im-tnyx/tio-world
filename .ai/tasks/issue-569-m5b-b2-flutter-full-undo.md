# GitHub #569 M5B-B2 — Flutter Full Create & Move Undo

**Status:** In progress
**Primary owner:** Flutter Workout feature implementation
**Affected platforms:** Flutter phone app, Workout feature, task/docs handoff

## Owner Approval and Scope Boundary

**Trigger:** Existing approved #569 product behavior; no new data shape.
**Approval status:** Approved within the existing bounded #569 UX contract.
**Approval evidence:** GitHub #569 owner UX correction dated 2026-10-23 approves one-action `Save & Move`, five-second actionable Undo, and atomic restoration plus removal of only the unchanged empty Program created by that exact operation. User supplied the M5B-B2 GO request in this task.
**Approved boundaries:** Add Flutter Workout domain/repository/presentation wiring and focused tests for the existing M5B-B1 RPC `undo_create_user_workout_program_and_move_routine`; preserve M5A, preview/debug gates, and `routineMoveReleaseEnabledProvider = false`.
**Explicit non-changes:** No Supabase schema/migration/RLS/grant edits, hosted writes/deployment, release activation, #567 Delete Program work, merge, or unrelated visual redesign.

## Active Handoff

**Planning owner:** GitHub #569 / Linear TNYX-81 and TNYX-267
**Implementation owner:** `im-tnyx`
**Review owner:** Pending exact-head review
**Implementation ownership state:** Active
**Repository state last verified:** `main@9805ee1b58f38d04e5b692aa049ef9e280bcf850`, clean; GitHub search confirms this is current `main` and PR #664 merge SHA.
**Branch:** `tnyx/m5b-b2-full-undo-flutter`
**Base SHA:** `9805ee1b58f38d04e5b692aa049ef9e280bcf850`
**PR / tracker:** [PR #665 OPEN](https://github.com/im-tnyx/tio-world/pull/665); GitHub #569 OPEN; PR #664 MERGED; Linear TNYX-81 and TNYX-267 remain Backlog; TNYX-78 In Progress; TNYX-80 In Progress.
**Current implementation state:** B1 SQL RPC exists in merged source; B2 Flutter receipt, one-RPC adapter, five-second Undo, exact UNKNOWN receipt verification, and owner-guarded refresh are implemented on PR #665. At head `5e1a892f`, Docs Hygiene CI passed and Flutter CI is pending; no independent review is recorded yet.
**Hosted evidence limitation:** No Supabase MCP or CLI is available in this session. Historical checked-in handoff says hosted is 68/68 through 20261021130000, with Move RPC EXECUTE denied; B1 migration and Undo RPC hosted status were not freshly verified.
**Next exact action:** Monitor exact-head Flutter CI/review, reconcile any findings, and stop before merge.

## 1. Discovery

### User Outcome

After a confirmed New Program `Save & Move`, the five-second floating feedback offers a real Undo. One tap invokes the protected atomic RPC to restore the same Routine to its original Program and remove only the operation-created eligible empty Program.

### Success Criteria

- Freeze routine/program IDs, original Create & Move mutation UUID, confirmed post-Move revision, owner, login cycle, and source display name in an immutable receipt.
- Dispatch one `undo_create_user_workout_program_and_move_routine` RPC only; never use client-side parent UPDATE or Program DELETE.
- Reuse the shared Move attempt/cross-operation gates, timeout classification, session checks, and exact-token UNKNOWN receipt verification.
- Show restored feedback only after direct RPC confirmation or exact latest-mutation receipt readback.
- Refresh owner-scoped Program and Routine surfaces after dispatched Undo without crossing account/login-cycle boundaries.
- Preserve existing-Program M5A Undo, zero-write preview behavior, and production release flag OFF.

### Non-Goals

Existing Program UX changes, general Program deletion (#567), schema/migration/grant/deployment, production activation, and device/release claims.

## 2. Codebase Exploration

### Verified Evidence

- GitHub #569 current owner correction (2026-10-23) supersedes the earlier “keep B” Undo rule and approves atomic return-to-A plus removal of exact eligible B.
- PR #664 is MERGED at `9805ee1b58f38d04e5b692aa049ef9e280bcf850`; migration `20261024090000_m5b_atomic_create_move_full_undo.sql` defines the six-argument protected RPC and durable Routine mutation/hash receipt.
- `routine_move_flow.dart` currently shows actionable Undo only for existing-destination moves; New Program confirmation shows no Undo.
- `SupabaseRoutineMoveRepository` already owns Move/Create & Move, its shared attempt gate, owner/login-cycle checks, and latest mutation receipt readback; extend this Workout-owned boundary.
- `routineMoveReleaseEnabledProvider` is hard-coded `false`; shell capability remains release/debug/preview gated.
- GitHub search found no open M5B-B2 PR. Linear agent skill/field-note list returned empty.

### Relevant Source

- `apps/features/workout/lib/src/domain/repositories/routine_move_repository.dart`
- `apps/features/workout/lib/src/data/repositories/supabase_routine_move_repository.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_move_flow.dart`
- `apps/app/lib/app/composition/workout_providers.dart`
- `apps/app/lib/app/routing/shell/shell_route.dart`
- Existing `routine_move_flow_test.dart` and `supabase_routine_move_repository_test.dart`

## 3. Clarification and Decisions

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Add a new table/column/RPC? | Rejected | B1 already supplies the exact protected Undo RPC; B2 is adapter/presentation integration only. | Owner contract |
| Reuse ordinary `move()` then delete Program B? | Rejected | Not atomic and unsafe; use only the B1 protected full-Undo RPC. | Owner contract |
| UNKNOWN proof | Chosen | Exact Undo token + original Program A + expected post-Undo revision + existing Routine hash receipt; absence of B or membership alone is insufficient. | Implementation |
| Refresh after dispatched UNKNOWN | Chosen | Invalidate current owner’s Program/Routine readers, without claiming deletion or success. | Existing app-shell pattern |

## 4. Architecture Design

Workout-owned immutable receipt → shared Move repository → one protected B1 RPC. The repository performs session and shared-gate checks, classifies definite failures versus transport UNKNOWN, and offers exact-token owner-scoped readback. Presentation reuses the M5A floating pill and owns tap/expiry feedback. App shell supplies session-guarded cross-surface invalidation. Preview never receives an Undo write path.

### Alternative Rejected

Two calls (`move_user_workout_routine`, then Program DELETE) are rejected because they allow partial completion and broaden destructive client access.

### Failure and Accessibility States

Ignore duplicate/late taps and stale sessions; report conflict/forbidden/UNKNOWN truthfully; never render `Restored` without the exact server receipt. Keep Core geometry and semantics unchanged.

## 5. Implementation Plan

- [x] Add immutable receipt and Workout-owned undo repository/verifier contracts.
- [x] Add one-RPC Supabase adapter with shared attempt gates and UNKNOWN handling.
- [x] Wire New Program five-second actionable Undo through the existing floating feedback component and owner-guarded refresh.
- [x] Add focused repository/widget tests for dispatch, expiry, conflicts, sessions, UNKNOWN receipt, and zero-write preview; retain M5A regression coverage.
- [x] Update task index and canonical status docs to describe B2 accurately and preserve hosted/release gates.
- [x] Run final analyze and diff checks; record exact results. `dart format` formatted the touched Dart files, but its command exited 1 after attempting to write a protected user telemetry file.
- [ ] Create focused PR linked to #569; verify exact-head checks/review; stop before merge.

## 6. Quality Review

### Validation Run

```text
PASS: flutter test test/presentation/routine_move_flow_test.dart test/data/supabase_routine_move_repository_test.dart test/data/routine_move_delete_attempt_gate_test.dart (170 tests; source commit `65177c75`).
PASS: Workout package flutter analyze (No issues found; source commit `65177c75`).
PASS: apps/app flutter analyze lib/app/routing/shell/shell_route.dart (No issues found; 59.2s; source commit `65177c75`).
PASS: git diff --check origin/main...HEAD.
PASS: Docs Hygiene CI on PR head `5e1a892f`.
PENDING: Flutter CI on PR head `5e1a892f`.
REVIEW: dart format changed the touched Dart files, then exited 1 after attempting a protected user telemetry write; no repository telemetry file was touched.
```

### Acceptance Evidence

| Criterion | Changed behavior / file | Test or manual evidence + result | SHA / environment | Remaining risk |
|---|---|---|---|---|
| Real New Program Undo | Implemented in PR #665 | Confirmed actionable snackbar, one Undo dispatch, and five-second expiry tests pass | local Windows Flutter; source commit `65177c75` | Hosted RPC remains unverified and release dormant |
| Atomic RPC params and frozen revision | Implemented in PR #665 | Exact six-argument RPC payload and post-Move revision tests pass | local Windows Flutter; source commit `65177c75` | B1 hosted state was not freshly verified |
| UNKNOWN receipt and no false success | Implemented in PR #665 | Exact token/revision confirmation and unconfirmed readback tests pass | local Windows Flutter; source commit `65177c75` | Session-local gate is process-local |
| Refresh both surfaces safely | Implemented in app shell | `shell_route.dart` targeted analyze passed; refresh callback is owner/cycle guarded | local Windows Flutter; source commit `65177c75` | Device QA not run |
| M5A and preview unchanged | Regression coverage passes | Existing M5A and preview cases pass in the focused widget suite | local Windows Flutter; source commit `65177c75` | Hosted/runtime release remains OFF |

### Review Provenance

**Review source / link:** [PR #665](https://github.com/im-tnyx/tio-world/pull/665); independent review pending
**Reviewer / relation to implementer:** Pending
**Diff or commit SHA actually reviewed:** Pending
**Review result and finding IDs/dispositions:** Pending
**Independent review?** Unknown / unavailable
**Limitations and unmet required gates:** Hosted Supabase state is not readable in this session; do not deploy or enable grants.

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

Hosted B1 migration/RPC/grants and Security Advisor not freshly checked; production release remains OFF; no device validation until explicitly run in the isolated QA scope.

### Final Status

`REVIEW`
