# GitHub #699 — Library Programs single refresh cue and compact chevron/title
**Status:** In progress
**Primary owner:** apps/features/workout presentation
**Affected platforms:** Flutter Android/iOS, Library Programs surface

## Owner Approval and Scope Boundary
**Trigger:** Product-visible UI/UX change.
**Approval status:** Approved. One later visual tweak still needs an owner Android re-check.
**Approval evidence:** Owner Santosh, stated in chat on 2026-10-27:
- Chevron and title share one expand/collapse tap area. Open Program appears only in the Program 3-dot sheet.
- Library pull-to-refresh that matches the Progress physical reveal is approved.
- The two-bar Routine overflow mark is approved in place of the 3-dot icon. A later same-day decision keeps the top bar at 20×2dp, shortens the bottom bar to 14×2dp, and right-aligns both bars with the existing pill ends. That geometry matches an owner-provided visual reference. The reference image is not committed.
- The Routine overflow interactive hit target stays 32×32dp. This is an explicit owner-approved deviation from the Discovery 48dp criterion for this control. The chevron+title expand area stays at least 48dp high.
- Owner Android visual QA of the UI before the shorter bottom bar confirmed that UI correct. The shorter right-aligned bottom bar still needs an owner Android re-check.
**Approved boundaries:** Single Programs-level refresh indicator; Progress-style Library pull-to-refresh; owner-safe retained rows with stable card/action geometry; one combined chevron+title expand/collapse target at least 48dp high; Open Program as the first action in the existing Program 3-dot sheet, whose own hit target stays 48×48dp; Routine overflow is the approved two-bar mark (top 20×2dp, bottom 14×2dp, right edges aligned, pill ends) inside a 32×32dp hit target. Existing Edit/Add remain; no Delete.
**Explicit non-changes:** No backend, auth, RPC, migrations, feature flags, Program Delete, Move/Undo server semantics, unrelated UI, Core token changes, or production release activation.

## Active Handoff
**Planning owner:** GitHub #699 / Linear TNYX-267 (W6B).
**Implementation owner:** Current Cursor cloud agent on the existing branch, continuing the approved #699 slice. Source edits in this pass are only the shorter Routine overflow bar and the two refresh semantics labels.
**Review owner:** Independent GitHub review on the final head is still required. `im-tio` review `5666160152` is `CHANGES_REQUESTED` on `ec90c65f` for the 32dp target.
**Implementation ownership state:** Active
**Ownership transition:** Prior implementation owner im-tnyx → this cloud agent for the 2026-10-27 owner-decision, bar, label, and handoff pass. Same approved slice.
**Repository state last verified:** `origin/main` `d1b373db0bff77c5d2b9bd447eb1489e21887643` is an ancestor of this branch. Local checkout inspected.
**Branch:** `tnyx/issue-699-library-refresh-chevron-20261027`
**HEAD SHA:** This docs commit is the HEAD it introduces. It sits on source commit `8906c430385e562712163a6e13ca2a4fd1e7efec` (`fix(workout): label library refresh indicators for screen readers`), which sits on `4ef05fb5c2a62217b402c2fc7933ae22ae054c10` (`fix(workout): shorten lower bar of routine overflow mark`), which sits on `ec90c65f98ea74c2e76ec4c3a279451fe2ba703a`. This docs commit changes HEAD. CI for `ec90c65f` does not validate it, and CI for this docs commit was not run when this paragraph was written.
**Observed working-tree state:** Branch checkout with unrelated dirty `pubspec.lock` files left unstaged.
**Observed uncommitted/dirty files:** `apps/app/pubspec.lock`, `apps/core/pubspec.lock`, `apps/features/*/pubspec.lock`, and `apps/wear/pubspec.lock`. Not part of this slice.
**PR / tracker:** https://github.com/im-tnyx/tio-world/pull/703 (open, not merged), https://github.com/im-tnyx/tio-world/issues/699, https://linear.app/tnyx/issue/TNYX-267. Linear was not updated in this pass.
**Current implementation state:** Library pull-to-refresh matches Progress and is owner-approved. Chevron and title are one expand/collapse target at least 48dp high. Open Program stays in the Program 3-dot `TioEditorSheet` (`programs_surface.dart` `_openProgramActions`). That Program overflow control stays 48×48dp. The Routine mark is the owner-approved two-bar glyph: top 20×2dp, bottom 14×2dp, physical right edges aligned, pill ends, 32×32dp hit target (`routine_metadata_card.dart`). Do not restore a 48dp Routine menu or a 3-dot Routine icon. The Program sheet uses the same session guard as Routine options. Existing Edit/Add remain. No backend or release flags. Refresh spinners use `semanticsLabel` `Refreshing Programs` and `Refreshing Routines`. No existing l10n key was found; the strings follow the inline Library loader convention (`Loading exercises`, `Loading Routine`).
**Relevant execution surface:** `programs_surface.dart`, `program_detail_page.dart`, `inline_program_routines.dart`, `routine_metadata_card.dart`, `library_page.dart`, owner-scoped presentation controllers, and focused tests.
**Validation completed at SHA:** On exact `ec90c65f98ea74c2e76ec4c3a279451fe2ba703a` only: [Commit attribution guard run 40491635604](https://github.com/im-tnyx/tio-world/actions/runs/40491635604) success; [Flutter CI run 40491639724](https://github.com/im-tnyx/tio-world/actions/runs/40491639724) success (Analyze Flutter and Dart / test Dart, Test Flutter app-workout, Test Flutter nutrition-onboarding, Test Flutter core-wear, aggregate Analyze and test); [Docs Hygiene run 40491639709](https://github.com/im-tnyx/tio-world/actions/runs/40491639709) success; Cursor Bugbot success; Cursor Security Agent: Security Reviewer success. Those runs do not validate `4ef05fb5`, `8906c430`, or this docs commit. Local, on the combined source tree that those two fix commits contain: `flutter test test/presentation/program_detail_page_test.dart test/presentation/library_page_test.dart` passed (74 tests) and `dart analyze` on the five touched Dart files reported no issues. `git diff --check` on this docs diff passed before the docs commit (exit 0).
**Validation remaining:** CI on the exact HEAD after this docs commit (attribution guard, Flutter CI, Docs Hygiene, Bugbot, Security agent). Formal independent GitHub review of that head. Owner Android re-check of the shorter right-aligned bottom bar. Then merge only through `.github/POST_MERGE_SYNC.md`. Do not treat `ec90c65f` CI as proof for the new head.
**Current blocker:** None for the source tweak. Merge is blocked on new-head CI, independent review, and the owner visual re-check of the shorter bar.
**Open review finding IDs:** Threads below were not resolved by this pass.
- Codex P1 `#4386182151` (outdated, unresolved): fixed in current source. `inline_program_routines.dart` keeps `actionsEnabled: !refreshing` while the card still builds the overflow slot when callbacks exist. `library_page_test.dart` (`shared Programs header is the only Routine refresh spinner`) asserts card rectangles stay put and the menu remains. `im-tio` review `5666160152` also says the geometry finding appears fixed. The thread stays unresolved.
- Codex `#4386731352` (live, unresolved): Program Detail refresh cue is present at current source. `program_detail_page.dart` paints `program-detail-refreshing` while `ProgramRoutinesStatus.refreshing` (the indicator sits above `_body()`, not inside the switch the comment anchors). `program_detail_page_test.dart` (`Program Detail keeps rows and shows one refresh cue`) asserts the key and one indicator during a same-owner move-refresh signal. `8906c430` adds `semanticsLabel: 'Refreshing Routines'`.
- Codex `#4387181605` and `im-tio` `#4387995963` (live, unresolved): 32×32dp target remains. Owner-approved deviation from the 48dp Discovery criterion, dated 2026-10-27. Pending re-review. This is not a GitHub `APPROVED`.
- Bugbot `#4386727699`: two-bar mark versus 3-dot. Owner approved the two-bar mark on 2026-10-27, including the shorter right-aligned bottom bar in `4ef05fb5`. The thread was already resolved before this pass. This pass replies and does not change resolution.
- `im-tnyx` `#4388027648` (live, unresolved): stale `12300121` / pending-CI handoff. This docs commit replaces that snapshot and itself needs new CI.
- `im-tnyx` `#4388095986` and `#4388095996` (live, unresolved): refresh `semanticsLabel` gaps. Fixed in `8906c430`. Threads left unresolved.
**Next exact action:** Push this docs commit, wait for CI on its exact SHA, then obtain formal independent GitHub review. Owner re-checks the shorter bottom bar on Android. Do not merge until those gates pass. After merge, follow `.github/POST_MERGE_SYNC.md`.

## 1. Discovery
**User outcome:** Avoid a spinner under every expanded Program and eliminate needless arrow-title visual gap.
**Success criteria:** One Programs-level refresh cue; same-owner cards stable in size and location during background reads; strict owner-cycle invalidation; one at-least-48dp-high chevron+title expand/collapse action; Program overflow stays a separate 48×48dp control whose sheet contains Open Program, Edit, and Add where capabilities exist; correct Move fanout. The old Routine-overflow criterion of an independent 48×48dp 3-dot control is superseded by the owner decision dated 2026-10-27: the Routine overflow hit target stays 32×32dp, and the mark is two right-aligned bars (top 20×2dp, bottom 14×2dp, pill ends) instead of a 3-dot icon.

## 2. Codebase Exploration
The bullets below are the pre-implementation exploration snapshot, not the current head.
**Verified source:** `ProgramsSurface._routineRefreshVersion` broadcast refreshes each `InlineProgramRoutines`; `ProgramRoutinesController.load` currently publishes empty `loading`; `ProgramsController.load` also clears list. `_LibraryProgramRow` uses 48dp `centerStart` chevron next to title. `LibraryPage` currently has no pull-to-refresh.
**Existing pattern:** Existing single section heading, existing Core `TioSpacing`/`TioSize`/`TioStroke`, owner/cycle checks in Routine controller, existing Move fan-out widget tests.
**Docs:** root `AGENTS.md`, feature `AGENTS.md`, Core Theme README, `.ai/workflow.md`, Core design-system task, Workout module-ownership docs.

## 3. Clarification
- Owner-approved **one Programs-header loading cue** rather than blinking/replacing overflow.
- Owner revision supersedes earlier separate actions: **chevron and title form ONE expand/collapse selection**. Open Program is a separate item inside existing Program 3-dot sheet; use the existing Program Detail callback and refresh on return.
- Retain only same-owner/cycle verified rows while a *background* read is pending; no cached prior owner rows; write controls disabled during refresh.
- Keep startup loading, error/retry, stale UNKNOWN, and existing refresh correctness fail-closed.

## 4. Architecture Design
`LibraryPage → ProgramsSurface / InlineProgramRoutines → existing ProgramsController / ProgramRoutinesController → repository`.
- Controllers own loading/refresh data semantics, not new UI repository truth.
- Library composition aggregates current per-Program load activity only for displaying one spinner; no new persistence.
- No new Core component: one-off section cue consumes public Core visual tokens.
- Alternatives rejected: hiding spinners while blanking cards (flicker), blinking/removing overflow actions during background reread (geometry shifts), narrowing Move fanout (stale destination). Owner explicitly approved a single large header tap area and a full-height at-least-48dp expand target. The Program 3-dot stays a separate 48×48dp control. The earlier Routine-overflow 48dp/3-dot target is superseded by the 2026-10-27 owner decision recorded above.

## 5. Implementation Plan
- [x] Preserve validated records in refreshing controller states with owner/cycle safety.
- [x] Aggregate loading from expanded Routine controllers to single Library Programs section.
- [x] Align chevron at Library's leading edge; combine chevron + title under one accessible >=48dp-height tap target, RTL-aware; move Open Program into existing 3-dot sheet.
- [x] Add widget/controller regression tests for loading, Move fan-out, session invalidation and layout (not yet CI-verified).
- [ ] CI on the docs-commit HEAD, formal independent review of that head, and owner Android re-check of the shorter bottom bar. Prior `ec90c65f` CI and the earlier Android QA do not close this item.

## 6. Quality Review
### Validation Run
`ec90c65f` GitHub CI listed in Active Handoff succeeded and applies only to that SHA. Local `flutter test` of `program_detail_page_test.dart` and `library_page_test.dart` passed (74 tests) on the source tree of `8906c430`, and `dart analyze` of the five touched Dart files reported no issues. This docs commit has no CI result yet.
### Acceptance Evidence
PR #703 source plus the two fix commits above. Owner Android QA on 2026-10-27 confirmed the UI before the shorter bottom bar. That bar still needs a device re-check.
### Review Provenance
`im-tio` GitHub review `5666160152` is `CHANGES_REQUESTED` on exact `ec90c65f` because the Routine overflow hit target is 32×32dp. Disposition: owner-approved deviation dated 2026-10-27, pending re-review on the new head. It is not an approval. Codex and Bugbot reviews on this PR are `COMMENTED`, not `APPROVED`. Chat-only bot verdicts are not GitHub approvals. No self-review is treated as approval.
### Review Findings and Resolution
Codex P1 #4386182151: during read-only refresh, removing callback-based Routine overflow collapsed card height. Current source keeps `actionsEnabled` and the menu slot. The widget test compares pre-/during-refresh rectangles. The thread is outdated and still unresolved. See Active Handoff for the other live threads.

## 7. Final Handoff
**Changed Files:** `.ai/tasks/issue-699-library-refresh-chevron.md`, `.ai/tasks/README.md`, `apps/app/test/app/workout_exercises_route_test.dart`, `apps/features/workout/lib/src/presentation/library/library_page.dart`, `apps/features/workout/lib/src/presentation/library/programs/program_detail_page.dart`, `apps/features/workout/lib/src/presentation/library/programs/programs_controller.dart`, `apps/features/workout/lib/src/presentation/library/programs/programs_surface.dart`, `apps/features/workout/lib/src/presentation/library/routines/inline_program_routines.dart`, `apps/features/workout/lib/src/presentation/library/routines/program_routines_controller.dart`, `apps/features/workout/lib/src/presentation/library/routines/routine_metadata_card.dart`, `apps/features/workout/test/presentation/library_page_test.dart`, `apps/features/workout/test/presentation/program_detail_page_test.dart`, `apps/features/workout/test/presentation/program_routines_controller_test.dart`, `apps/features/workout/test/presentation/programs_controller_test.dart`, `docs/screens/library.md`.
**Actual Behavior:** Implemented on the branch, including the shorter right-aligned bottom bar and labeled refresh indicators. Exact CI for the docs-commit HEAD is still unverified.
**Known Limitations:** Owner Android QA before the shorter bar passed. The shorter bar itself is not yet re-checked on a device. Future protected-API compatibility review is N/A: no persisted-data, Auth, RLS, RPC, or sync-contract change.
**Final Status:** REVIEW — new-head CI, independent review, and the shorter-bar visual re-check are still open. Do not merge.
