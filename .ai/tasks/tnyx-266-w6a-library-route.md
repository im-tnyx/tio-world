# TNYX-266 — W6A Canonical Library route & capability-gated root

**Status:** In progress
**Primary owner:** `apps/features/workout` (Library page, Workout Home entry), with the route contract in `apps/core` and router wiring in `apps/app`
**Affected platforms:** Phone (Android + iOS). Wear OS / watchOS: none.

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice (product-visible UI + route)
**Approval status:** Approved
**Approval evidence:** On 2026-09-25 the owner asked for a Library screen reached from the Workout tab. After reviewing the proposed design, with the Tnyx-hub Library as reference, the owner replied "NEXT GO". The approved design is the one proposed: a Library card on Workout Home, and a Library screen with only the Exercises row, without sub-tabs.
**Approved product/UI/data-shape boundaries:**

- Workout Home: one Library entry below the calendar, a `TioGroupCard` holding a `TioSettingsNavigationRow` (folder icon, `Library`, `Browse exercises`, chevron).
- Library screen at `/workout/library` (`AppRoutes.workoutLibrary`), nested in the Workout branch; AppBar with back and the title `Library`; bottom navigation hidden; deep link follows `/workout` gating.
- The Library root shows only ready sections. Today that is one `Exercises` row (fitness icon, `Browse all exercises`, chevron) that opens `/workout/exercises`. There are no Programs/Routines/Plans placeholders, sub-tabs, grid/list toggle, Create/Favorites/Custom rows, or catalog list on the root.
- Library → Exercises pushes onto the Workout stack, so back from Exercises returns to Library.

**Explicit non-changes:** No Programs/Routines/Plans sections (W6B/W6C), no configurable bottom-nav Library (TNYX-131), no Exercise Detail, no Exercises screen changes, no Supabase, no Wear OS/watchOS UI, and no new core component or token.

## Active Handoff

**Planning owner:** Current task agent
**Implementation owner:** Current task agent
**Review owner:** Codex review on the PR; owner final review
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-25, local `main` = `origin/main` = GitHub `main` = `d916d820`
**Branch:** `tnyx/tnyx-266-w6a-canonical-library-route-capability-gated-root` (from `d916d820`)
**HEAD SHA:** see PR head (committed on top of `d916d820`)
**Observed working-tree state:** clean
**Observed uncommitted/dirty files:** none
**PR / tracker:** Linear TNYX-266 (In Progress); Draft PR (see Final Handoff)
**Current implementation state:** Implementation and local validation complete; Draft PR handoff
**Relevant execution surface:** `apps/features/workout/lib/src/presentation/{library,pages}/`, `apps/core/lib/src/routing/routes/app_routes.dart`, `apps/app/lib/app/router.dart`
**Validation completed at SHA:** working tree = committed head (see Validation Run)
**Validation remaining:** GitHub CI on the PR head; owner review
**Current blocker:** none
**Open review finding IDs:** none
**Next exact action:** owner review of the Draft PR; Ready/merge only on a separate owner instruction

## Global UI / Design-System Guardrail

Read `apps/core/lib/src/theme/README.md` and `apps/features/AGENTS.md`. Reuse the public Settings-row family: `TioGroupCard`, `TioSettingsNavigationRow` and `TioSettingsLeadingIcon`. The README directs features to use it when its contract matches rather than rebuild card/row geometry. Use the AppBar pattern of existing feature pages. No feature token bag and no new core component.

## 1. Discovery

### User Outcome

From the Workout tab, a phone user opens Library and then Exercises, and reaches the Exercises screen through normal navigation for the first time.

### Success Criteria

- Workout Home shows the Library entry below the calendar; tapping it opens `/workout/library`.
- The Library root lists only ready sections (Exercises today); tapping Exercises opens `/workout/exercises`, and back returns to Library.
- The bottom navigation is hidden on Library; a direct deep link lands with `/workout` beneath it and follows `/workout` gating.
- The existing calendar behavior and the Exercises screen are unchanged.

### Scope

Route contract; Library page; Workout Home entry; router wiring; tests; docs.

### Non-Goals

See Explicit non-changes above.

## 2. Codebase Exploration

### Verified Evidence

- Linear TNYX-266: Backlog → In Progress. Its blocker TNYX-261 is Done (closed 2026-09-25 with W3A2 complete). It blocks W6B (TNYX-267) and W6C (TNYX-268). No TNYX-266 branch, PR or GitHub issue existed; the docs-only IA reconciliation was merged earlier in PR #331.
- `docs/screens/library.md`: planned only; it specifies route and ownership and gives no visual design. Sections are capability-gated, and the Library root never renders the Exercise list.
- Workout Home (`WorkoutHomePage`) renders only `TioDateCalendar` inside `Align(topCenter)`. Meal Diary lays out content below its calendar in a scroll view with `TioSpacing.lg` side padding.
- Router: Workout branch child routes come from `_shellBranchChildRoutes` (added in TNYX-272). `appModeRedirect` already gates nested tab paths.
- Reference: the Tnyx-hub Workout Home Library card has a folder icon, title, subtitle and chevron. Its Library screen has sub-tabs and grid/list views; those are excluded here.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Entry and rows reuse `TioGroupCard` + `TioSettingsNavigationRow` + `TioSettingsLeadingIcon` | Made | Documented reusable navigation-row contract, so no local card geometry | Engineering |
| Navigation callbacks are passed into feature pages; `apps/app` owns the paths | Made | Existing pattern (`MealDiaryMoreMenu.onMealDiarySettingsPressed`); features do not import routing paths | Engineering |
| `push` is used for Home → Library and Library → Exercises | Made | Back from Exercises returns to Library; a deep link to `/workout/exercises` still lands on `/workout` beneath it | Engineering |
| Workout Home body becomes scrollable (calendar + entry) | Made | Month mode plus the entry must not overflow on compact heights | Engineering |
| The entry has no top padding and does not overlap the calendar | Made | The calendar reserves a 42dp transparent band for its expansion-handle hit target; interactive content must not overlap it (the same rule as Meal Diary) | Engineering |
| Tests assert rendered pages and chrome after `push`, not the reported URL | Made | go_router keeps the reported URL at the branch root for imperative pushes (default `optionURLReflectsImperativeAPIs`), while the shell still hides the bottom navigation on the pushed pages | Engineering |

## 4. Architecture Design

```text
WorkoutHomePage(onLibraryPressed)  ──push──▶  /workout/library  LibraryPage(onExercisesPressed)
                                                        │ push
                                                        ▼
                                              /workout/exercises  ExercisesPage (TNYX-272)
```

The Library page is stateless, and its section list is a fixed "ready capabilities" list in the feature (Exercises only); later W6B/W6C slices extend it. It owns no domain truth.

### Alternative Rejected

- A Library route outside the Workout branch (root navigator), which would lose the Workout back stack and the tab context.
- Sub-tabs with a single tab, which the owner did not approve and which would read as placeholder structure.

## 5. Implementation Plan

- [x] `AppRoutes.workoutLibrary` + core test
- [x] `LibraryPage` + widget tests
- [x] Workout Home Library entry + tests
- [x] Router wiring + app route tests
- [x] Docs (`library.md`, `exercise-search.md`, `workout.md`, `MODULE_OWNERSHIP.md`, `ROADMAP.md`)
- [x] Validation + visual render check

## 6. Quality Review

### Validation Run

Local, Windows, repository Flutter SDK, on the committed tree (2026-09-25); per-package commands matching CI:

```text
apps/features/workout     flutter analyze --no-pub → No issues found; flutter test --no-pub → 154 passed
apps/core                 flutter analyze --no-pub → No issues found; flutter test --no-pub → 325 passed
apps/app                  flutter analyze --no-pub → No issues found; flutter test --no-pub → 377 passed
apps/features/onboarding  flutter analyze --no-pub → No issues found; flutter test --no-pub → 450 passed
git diff --check                                  → clean
```

Visual check: a temporary, uncommitted render test produced PNGs of Workout Home (calendar plus Library entry) and the Library page, in light and dark at 390dp and 320dp. The gap between the calendar and the entry is the calendar's own handle band. No goldens were committed; the repository has no golden pattern.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `apps/core/lib/src/routing/routes/app_routes.dart`, `apps/core/test/app_routes_test.dart`: `AppRoutes.workoutLibrary`.
- `apps/features/workout/lib/src/presentation/library/` (`library_page.dart`, `library.dart`), `presentation/presentation.dart` export, `test/presentation/library_page_test.dart`.
- `apps/features/workout/lib/src/presentation/pages/workout_home_page.dart` (Library entry, scrollable body, required `onLibraryPressed`), `test/presentation/workout_home_page_test.dart`.
- `apps/app/lib/app/router.dart`: Library child route, Home/Library push callbacks, chrome policy entry.
- `apps/app/test/app/workout_exercises_route_test.dart`: Library chrome, gating parity, the Home → Library → Exercises → back flow, Library deep link, mode gating, and no direct Exercises entry.
- `docs/screens/library.md`, `docs/screens/exercise-search.md`, `docs/screens/workout.md`, `docs/MODULE_OWNERSHIP.md`, `docs/ROADMAP.md`, this brief, `.ai/tasks/README.md`.

### Actual Behavior

- The Workout tab shows the Library entry below the calendar, and tapping it opens Library.
- Library shows one `Exercises` row, which opens the Exercises screen; back returns to Library, then to Workout Home.
- The bottom navigation is hidden on Library and Exercises.
- `/workout/library` deep links follow `/workout` gating.

### Known Limitations

- The reported URL stays `/workout` after the imperative pushes (go_router default). Deep links to `/workout/library` and `/workout/exercises` still work.
- Programs, Routines and Plans sections await W6B/W6C. The entry subtitle reads `Browse exercises` until more sections exist.

### Final Status

`REVIEW`: implementation and local validation are complete; the Draft PR awaits CI and owner review.
