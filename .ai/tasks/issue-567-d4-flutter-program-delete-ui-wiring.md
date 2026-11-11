# GitHub #567 Gate D — Flutter Program Delete UI Wiring

**Status:** Implementation & Review Remediation Complete (PR #709 Active)
**Primary owner:** Antigravity (Implementation Owner)
**Affected platforms:** Flutter `apps/features/workout` and `apps/app`, Supabase database tests

## Owner Approval and Scope Boundary

**Trigger:** Internal implementation subtask of approved #567 lifecycle slice (Gate D: source UI wiring after verified Gate A, Gate B, and Gate C sign-off).
**Approval status:** Approved by User/Owner in prompt 10 & 11.
**Approval evidence:** "Go — Issue #567 Gate D source implementation." and "Go — Issue #567: Continue from the verified Gate D commit/push to PR Merge Gate."
**Approved product/UI/data-shape boundaries:**
- `apps/features/workout/lib/src/presentation/library/programs/programs_surface.dart`: Wire `Delete Program` action in `_openProgramActions` exclusively for non-default Programs (`!program.isDefault && widget.onDeleteProgram != null`).
- `apps/features/workout/lib/src/presentation/library/library_page.dart`: Pass `onDeleteProgram` callback through to `ProgramsSurface.library`.
- `apps/app/lib/app/composition/workout_providers.dart`: Expose `programDeleteFlowProvider`.
- `apps/app/lib/app/routing/shell/shell_route.dart`: Session-guarded wiring using `ProgramDeleteFlow`, `programDeleteControllerProvider(program.id)`, and `programDeleteRepositoryProvider` with strict `sameSession()` checks (user ID, login cycle ID, Supabase current user, auth state) and retain `programDeleteControllerProvider` across the async flow using `ref.listenManual` + `try/finally` subscription cleanup.
- `apps/features/workout/test/presentation/programs_surface_delete_action_test.dart`: Focused widget test suite for UI action sheet, non-default inclusion, default exclusion, null callback suppression, cancel behavior, and refresh dispatching.
- `supabase/migrations/20261028110000_grant_authenticated_program_delete_rpc.sql`: Track Gate B migration file in Git repository history to align local and CI migration replay with the already-applied hosted Supabase ledger (72/72). Gate B (`grant execute ... to authenticated`) was previously deployed and verified on hosted Supabase prior to this PR; this PR only records that existing migration file in Git for CI replay parity and performs zero writes or deployments to the hosted database.
- `supabase/tests/database/tnyx_567_*`: Update database test assertions to verify the already-applied Gate B authenticated-only EXECUTE grant and preserve the migrated ACL during concurrency tests.
**Explicit non-changes & hard stops:**
- Zero hosted database mutations, writes, migrations, or privilege deployments in this PR slice (Gate B was already applied to hosted Supabase in a prior approved step; this PR purely records the migration file in Git for CI replay parity and performs no new hosted database modification or deployment).
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
**PR / tracker:** GitHub #567 OPEN; GitHub PR #709 OPEN; Linear TNYX-81 / TNYX-267
**Validation completed:**
- `flutter analyze` in `apps/features/workout`: PASS (0 issues)
- `flutter analyze` in `apps/app`: PASS (0 issues)
- `flutter test test/presentation/programs_surface_delete_action_test.dart`: PASS (7/7 tests)
- `flutter test test/app/program_delete_controller_provider_lifecycle_test.dart`: PASS (4/4 tests)
- `git diff --check`: PASS (0 errors)
**Current blocker:** None
**Next exact action:** Submit final PR audit and merge-gate recommendation to owner.
