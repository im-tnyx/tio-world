# GitHub #569 / Linear TNYX-81: Atomic Create+Move Expanded Source Program Routine Refresh

**Status:** Validated
**Primary owner:** `im-tnyx`
**Affected platforms:** Flutter mobile (`apps/features/workout`)

## Owner Approval and Scope Boundary

**Trigger:** None (scoped bug fix discovered during live Android debug E2E QA under approved #569 scope)
**Approval status:** Not required
**Approval evidence:** Normal implementation subtask / bug fix within approved #569 scope.
**Approved product/UI/data-shape boundaries:** Fix `ProgramsSurface._onMoveRefresh` to increment `_routineRefreshVersion` on atomic Create+Move events (`programsMayHaveChanged == true`), so expanded source programs reload routines and do not retain moved routine items.
**Explicit non-changes:** No schema changes, no migration changes, no backend RPC changes, no visual/design tokens changes.

## Active Handoff

**Planning owner:** `im-tnyx`
**Implementation owner:** `im-tnyx`
**Review owner:** `im-tio`
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** `main@588e5a1c6fb055a7cd6424af5111dd4d7115410e`
**Branch:** `tnyx/issue-569-atomic-move-expanded-source-refresh-20261023`
**Observed working-tree state:** 4 changed files (1 source, 2 tests, 1 task brief)
**Observed uncommitted/dirty files:** None outside scope
**PR / tracker:** GitHub #569 / Linear TNYX-81
**Current implementation state:** Fixed `_onMoveRefresh` in `apps/features/workout/lib/src/presentation/library/programs/programs_surface.dart`, wrapped `unawaited` in `routine_move_flow_test.dart`, and added widget regression test in `apps/features/workout/test/presentation/library_page_test.dart`.
**Relevant execution surface:** `apps/features/workout`
**Validation completed at HEAD:**
- Live Android E2E QA verified Move Routine flow across Library and Program Detail surfaces against isolated local Supabase.
- Identified and fixed stale routine retention in expanded source program cards on atomic Create+Move.
- `flutter analyze` on `apps/features/workout`: 0 issues.
- `flutter test` on `apps/features/workout`: 923 passed, 0 failed.
- `git diff --check`: 0 issues.
**Validation remaining:** Push branch, open PR, exact-head CI, Codex & independent review.
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Commit, push task branch, and open PR.
