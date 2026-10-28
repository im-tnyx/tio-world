# GitHub #567 Gate D — Flutter Program Delete UI Wiring

**Status:** Implementation & Validation Complete (Ready for Owner Review / PR)
**Primary owner:** Antigravity (Implementation Owner)
**Affected platforms:** Flutter `apps/features/workout` and `apps/app`

## Owner Approval and Scope Boundary

**Trigger:** Internal implementation subtask of approved #567 lifecycle slice (Gate D: source UI wiring after verified Gate A, Gate B, and Gate C sign-off).
**Approval status:** Approved by User/Owner in prompt 10.
**Approval evidence:** "Go — Issue #567 Gate D source implementation. Approved scope: programs_surface.dart, library_page.dart, shell_route.dart, focused widget/composition tests."
**Approved product/UI/data-shape boundaries:**
- `apps/features/workout/lib/src/presentation/library/programs/programs_surface.dart`: Wire `Delete Program` action in `_openProgramActions` exclusively for non-default Programs (`!program.isDefault && widget.onDeleteProgram != null`).
- `apps/features/workout/lib/src/presentation/library/library_page.dart`: Pass `onDeleteProgram` callback through to `ProgramsSurface.library`.
- `apps/app/lib/app/composition/workout_providers.dart`: Expose `programDeleteFlowProvider`.
- `apps/app/lib/app/routing/shell/shell_route.dart`: Session-guarded wiring using `ProgramDeleteFlow`, `programDeleteControllerProvider(program.id)`, and `programDeleteRepositoryProvider` with strict `sameSession()` checks (user ID, login cycle ID, Supabase current user, auth state).
- `apps/features/workout/test/presentation/programs_surface_delete_action_test.dart`: Focused widget test suite for UI action sheet, non-default inclusion, default exclusion, null callback suppression, cancel behavior, and refresh dispatching.
**Explicit non-changes & hard stops:**
- Zero hosted database mutations, migrations, or privilege modifications.
- Default canonical Program (`isDefault: true` / `My Program`) must NEVER display `Delete Program` and must fail closed.
- Zero unrelated visual redesign or token modifications.
- Do NOT merge branch into main; provide merge-gate recommendation.

## Active Handoff

**Planning owner:** Antigravity
**Implementation owner:** Antigravity
**Review owner:** Independent Reviewer / Product Owner
**Repository state last verified:** `G:/projects/Tio-World` at branch `tnyx/567-d4-flutter-program-delete-ui-wiring`
**Branch:** `tnyx/567-d4-flutter-program-delete-ui-wiring`
**Base SHA:** `780fb56d1fd47d55666ed5d0a6d881992f314ff2` (main)
**Observed working-tree state:** Clean implementation files + task tracking files
**PR / tracker:** GitHub #567 OPEN; Linear TNYX-81 / TNYX-267
**Validation completed:**
- `flutter analyze` in `apps/features/workout`: PASS (0 issues)
- `flutter analyze` in `apps/app`: PASS (0 issues)
- `flutter test test/presentation/programs_surface_delete_action_test.dart`: PASS (7/7 tests)
- `flutter test test/presentation/programs_page_test.dart ...`: PASS (39/39 tests)
- `flutter test test/data/supabase_program_delete_repository_test.dart`: PASS (19/19 tests)
- `flutter test` across all of `apps/app`: PASS (469/469 tests)
- `git diff --check`: PASS (0 errors)
**Current blocker:** None
**Next exact action:** Submit final Gate D implementation report and merge-gate recommendation to owner.
