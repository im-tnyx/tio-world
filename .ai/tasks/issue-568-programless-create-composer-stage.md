# #568-A — Dormant programless Create using the canonical Routine composer

**Status:** In review — PR #644 / exact-head Flutter CI and independent review gate (2026-10-21)
**Primary owner:** Workout feature domain/presentation; app-shell and Supabase activation separate
**Affected platforms:** Flutter Workout package (shared Android/iOS UI contract)
**Owner authorization:** Explicit 2026-10-21 "go merge gate tak ... merge nahi" on previously recommended #568-A staged composer slice; GitHub #568 approved 2026-10-15 first Routine UX. This is a bounded implementation subtask, not authorization for release/UI activation.

## Scope and source audit

Protected base: `main@fc5e51f9b830199da05671b60760c25654b579c9` (PR #643 docs merge). Branch: `tnyx/issue-568-programless-composer-stage-20261021`; [PR #644](https://github.com/im-tnyx/tio-world/pull/644) OPEN/NOT MERGED.
Read root `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/FEATURE_DEVELOPMENT.md`, `apps/core/lib/src/theme/README.md`, design-system token brief, #568/#569, Linear TNYX-78/TNYX-81, ADR-0015 and current Workout repositories/controllers/tests. Remote GitHub source, not the owner's Windows working tree, is inspected.

Verified source at base:
- `CreateRoutinePage` / `RoutineCreateController` require an existing `Program` and publish only Program-bound `RoutineCreateCommand`.
- Already-merged `MyProgramRoutineCreateCommand` and `SupabaseMyProgramRoutineCreateRepository` call the one atomic `create_user_workout_routine_in_my_program` RPC. No client-side Program INSERT is valid.
- `RoutinePendingCreateGate` supports owner/login-cycle scoped `retainMyProgram`, `releaseMyProgram`, `releaseDefiniteMyProgramForOwner`, `verifyMyProgram`, preserving unconfirmed commands across auth cycles without cross-owner disclosure.
- Server-owned `is_default` identity and positive read-back predicate are already implemented. Hosted migration ledger/ACL baseline is 66/66 applied with authenticated first-Routine RPC EXECUTE withheld (last verified before this slice; **not** independently re-queried by this Flutter-only task).
- App shell still enters Create through an existing Program; `routineMoveReleaseEnabledProvider` is hard `false`. Existing direct Library root entry for zero Programs is **not** activated by this slice.

## Decision and exact implementation

Reuse the same in-memory Routine Exercise/Set draft, Custom Exercise preflight, validation, and visual composer for both modes.
- Program-scoped path keeps the existing `RoutineCreateRepository`, callback types and `ProgramId`.
- Programless path is an explicitly named dormant `CreateRoutinePage.forMyProgram` → `RoutineCreateController.forMyProgram` mode with no `Program`/placeholder. It sends a frozen `MyProgramRoutineCreateCommand` to the existing atomic RPC abstraction.
- New typed **required** programless callbacks expose pre-dispatch, verified ACK, definite failure and UNKNOWN exit to the existing owner/login-cycle gate when app-shell integration is separately approved. A programless controller refuses dispatch without an explicit live-session check. No captured command is automatically retried after an uncertain result.
- Programless UNKNOWN verifies the one true `isDefault` Program, matching Routine name/ID/owner Program relation, and exact composition mutation. Absent/ambiguous reads preserve UNKNOWN. `canWrite` must be bound by the eventual app-shell caller to live bootstrap/SDK auth/login cycle.
- Existing visual geometry and Program-owned Create behavior are not redesigned. This entry is not wired to a production route/provider.

Rejected alternative: client-create a fake `My Program` row or a two-phase Program INSERT + Routine Create (non-atomic, duplicates/orphans); rejected duplicate Create editor as competing source of truth.

## Acceptance and validation

| Criterion | Evidence / verification still needed |
|---|---|
| No ProgramId in first Create; nonempty Exercise+Set | New programless composer widget test and typed command |
| Exactly one server RPC; no separate Program writes | Existing staged adapter plus fake program repository throwing on mutation; widget/controller tests |
| UNKNOWN result cannot auto-retry or silently fabricate success | Controller and negative/positive readback test |
| Canonical `isDefault` identity even after rename | Controller positive readback; no name matching |
| Definite failure vs lost ACK and login-cycle revocation | Focused controller tests, typed definite callback |
| Existing Program-specific Create unchanged | Existing `create_routine_page_test.dart` and `routine_create_controller_test.dart` via Flutter CI |

**Pending at exact-head gate:** Flutter CI and independent `im-tio` GitHub review, owner-local `git diff --check`, applicable repository merge rules. GitHub connector cannot execute Windows/Flutter commands locally. Do not label unrun tests PASS.

## Release/security and non-goals

**Never in this slice:** app-shell direct Library root action, production visibility, Supabase GRANT/migration/deploy/RLS changes, live authenticated writes, OS device QA, Move Routine activation, real 5-second Undo, Program/Exercise schema shape, second composer, unrelated UI/design overhaul. The existing server EXECUTE denial makes this dormant client path non-releasable. Any later user-visible activation needs its own reviewed RPC grant, owner/live-session wiring, prior pending verification, cross-device/legacy/UNKNOWN QA and owner approval.

## Handoff

Implementation owner: this GitHub-connected assistant acting via `im-tnyx` on the bounded branch. Review owner: independent `im-tio` requested on PR #644 (latest review verdict not presumed). No implementation ownership transfer. Parent #568 remains OPEN, TNYX-78 In Progress; #569 remains OPEN and Move OFF. **Do not merge without a new explicit owner command.**

**Next:** inspect actual exact-head Flutter CI, independent review findings and thread state; address scoped findings, obtain owner Windows exact-head native diff receipt; only then report merge gate status. No background CI/review outcome is presumed.
