# GitHub #521 — W4A Program-scoped Routine metadata UI

**Status:** In progress
**Primary owner:** `apps/features/workout` (Program/Routine presentation + feature domain), `apps/app` only for provider/navigation composition
**Affected platforms:** Flutter phone; no Wear/Watch/supabase runtime change

## Owner Approval and Scope Boundary
**Trigger:** New bounded user-visible UI slice
**Approval status:** Approved
**Approval evidence:** 2026-10-11 owner “@Linear @Supabase @Supabase Go” responding to W4A Program Detail + Program-owned Routine List/Create/Rename proposal; see [GitHub #521](https://github.com/im-tnyx/tio-world/issues/521) and [Linear TNYX-81](https://linear.app/tnyx/issue/TNYX-81).
**Approved product/UI boundaries:** Library persisted Program name → selected Program Detail. Owner-only Routine list/read/retry, generated nonblank create name editable before save, owner-bound create, persisted rename. Preserve existing Library geometry/chevron/overflow and Core UI.
**Explicit non-changes:** No full Routine/Exercise/Set builder, picker, workout start, default `My Program`/Library quick actions, provenance/adoption, media, archive/delete, TrainingPlan, Favorites/Folders, Supabase schema/RPC/production writes or app release.

## Active Handoff
**Planning owner:** Project CTO audit via current GitHub/Linear/Supabase connectors
**Implementation owner:** Current W4A GitHub-connector implementation session
**Review owner:** Independent GitHub reviewer/Codex (if available); no self-approval claims
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-10-11, remote `main@12ea77880b1382a6e74b5a3c4a9083b06b9a5d87`; owner's earlier local `main@dfe9cee7` is stale. This tool session has no owner-local checkout and cannot claim local `git status`.
**Branch:** `tnyx/issue-521-w4a-program-routine-metadata-ui`
**HEAD SHA:** Initially `12ea77880b1382a6e74b5a3c4a9083b06b9a5d87`; update after commits.
**Observed working-tree state:** Remote Git branch clean at base; owner's local working tree not inspected.
**Observed uncommitted/dirty files:** Cannot inspect owner's Windows filesystem from GitHub connector.
**PR / tracker:** GitHub #521, Linear TNYX-81 (broad W4 remains Backlog, blocked by TNYX-78/W1 and TNYX-80/W3). Linear child issue creation attempted but rejected by workspace free issue limit.
**Current implementation state:** Approved bounded slice; source implementation being prepared.
**Relevant execution surface:** `LibraryPage` → existing `ProgramsSurface.library` selected Program → new feature-owned `ProgramDetailPage` and `ProgramRoutinesController` backed by `RoutineRepository` / existing Supabase gateway. App shell composes nullable RoutineRepository without memory fallback. Reuse `TioEditorSheet` / `TioButton` / `TioInput`.
**Validation completed at SHA:** None for this slice. Older Routine composition CI is not W4A test evidence.
**Validation remaining:** Flutter analyze/test and focused widget/app navigation, static checks, CI and review.
**Current blocker:** No local Flutter/Dart toolchain in connected session; CI must be inspected and repairs handled without claiming local test runs.
**Open review finding IDs:** None yet.
**Next exact action:** Implement smallest approved vertical slice, focused tests; open one PR and STOP before merge.

## Design and risk
- Library only passes a Program selected from canonical owner-scoped persisted Program list. ProgramDetail queries `RoutineRepository.list(program.id)` and validates Routine→Program relationship at feature boundary; database RLS and `(program_id,user_id)` FK protect storage.
- Create a Routine with stable UUID and immutable owning `ProgramId`; uncertain POST response must reconcile by owner-scoped re-read and keep a pending UUID across retries rather than create duplicates.
- Rename remains `RoutineRepository.rename` with list re-read to confirm uncertain responses. Never offer phantom successful state.
- Do not bind Library quick-create to `My Program` by mutable name. Reuse existing route/presentation patterns.
- Alternative rejected: repurpose `ProgramsSurface` or add a separate Library-owned Routine repository/model; ownership remains Workout capability.

## Tests and rollout
Controller tests: list with selected Program, loading/error/retry, first unused name, owner association, stable UUID on retries, ambiguous write reconciliation, rename reconciliation, no false success.
Widget/app tests: no other Library row visual/actions changed; selected Program name navigates to real detail, null provider disables action; create/rename sheets remain on errors; back behavior; non-W4 capabilities remain hidden.
No migrations, hosted data writes, app release or merge during this slice.
