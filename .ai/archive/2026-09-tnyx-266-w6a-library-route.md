# TNYX-266 — W6A Canonical Library route & capability-gated root

**Status:** Validated
**Completion date:** 2026-09-25
**Primary owner:** `apps/features/workout` (Library page, Workout Home entry), with the route contract in `apps/core` and router wiring in `apps/app`
**Affected platforms:** Phone (Android + iOS). Wear OS / watchOS: none.

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice (product-visible UI + route)
**Approval status:** Approved
**Approval evidence:** On 2026-09-25 the owner asked for a Library screen reached from the Workout tab. After reviewing the proposed design, with the Tnyx-hub Library as reference, the owner replied "NEXT GO". The approved design is the one proposed: a Library card on Workout Home, and a Library screen with only the Exercises row, without sub-tabs. Owner addition (2026-09-25, after the first Draft PR commit): the Library top bar has a search icon that opens Exercises with the search field focused. After the owner's "ab pr check kare", the instruction "go follow agent.md" (with `POST_MERGE_SYNC.md`) authorized the merge, the post-merge sync and this archive.
**Approved product/UI/data-shape boundaries:**

- Workout Home: one Library entry below the calendar, a `TioGroupCard` holding a `TioSettingsNavigationRow` (folder icon, `Library`, `Browse exercises`, chevron).
- Library screen at `/workout/library` (`AppRoutes.workoutLibrary`), nested in the Workout branch; AppBar with back and the title `Library`; bottom navigation hidden; deep link follows `/workout` gating.
- The Library root shows only ready sections. Today that is one `Exercises` row (fitness icon, `Browse all exercises`, chevron) that opens `/workout/exercises`. There are no Programs/Routines/Plans placeholders, sub-tabs, grid/list toggle, Create/Favorites/Custom rows, or catalog list on the root.
- Library → Exercises pushes onto the Workout stack, so back from Exercises returns to Library.
- The Library top bar has a search icon (`Search exercises`). It opens Exercises with the search field active and focused (`/workout/exercises?search=true`).

**Explicit non-changes:** No Programs/Routines/Plans sections (W6B/W6C), no configurable bottom-nav Library (TNYX-131), no Exercise Detail, no Exercises screen changes, no Supabase, no Wear OS/watchOS UI, and no new core component or token.

## Active Handoff

**Planning owner:** Current task agent
**Implementation owner:** Current task agent
**Review owner:** Exact-head self-review by the task agent (not independent). After Ready, Codex gave 👍 (no suggestions) on the final head `a67bacb5` (15:31Z). No owner-account review was posted before merge.
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-25 after the PR #349 post-merge sync; GitHub `main`, `origin/main` and local `main` all at `a98bce82b3962fd927c2bf49e349360dd2676ae3`
**Branch:** `tnyx/tnyx-266-w6a-canonical-library-route-capability-gated-root` (merged; retained, deletion not requested)
**HEAD SHA:** merged PR head `a67bacb586c9319e96cf2386a3614b48cee02015` on base `d916d820`; squash merge commit on `main` `a98bce82b3962fd927c2bf49e349360dd2676ae3` (merge tree `3e3a4cd6` identical to the reviewed head)
**Observed working-tree state:** Not applicable (slice complete)
**Observed uncommitted/dirty files:** Not applicable (slice complete)
**PR / tracker:** [PR #349](https://github.com/im-tnyx/tio-world/pull/349) merged 2026-09-25T15:41:07Z (squash, `--match-head-commit`). CI at the head: Analyze and test, Attribution guard runner and Commit attribution guard all passed; 0 unresolved threads, no reviews or comments. Linear TNYX-266 went In Progress → In Review (at Ready) → Done (GitHub integration on merge). Follow-ups: universal top-bar title spacing token → GitHub #350 (no Linear issue; workspace limit); Exercises folder move `presentation/explore/exercises` → `presentation/library/exercises` (owner suggestion, pending decision); Explore scope and Coaches direction recorded on TNYX-82.
**Current implementation state:** Validated. On `main`, the path is Workout Home → Library → Exercises, and the Library search icon opens Exercises with its search field focused.
**Relevant execution surface:** `apps/features/workout/lib/src/presentation/{library,pages,explore/exercises}/`, `apps/core/lib/src/routing/routes/app_routes.dart`, `apps/app/lib/app/router.dart`
**Validation completed at SHA:** local runs on the committed tree (see Validation Run); CI green on `a67bacb5`
**Validation remaining:** None
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** None for this slice.

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
| Library search opens Exercises via the `?search=true` query parameter; the `exercisesControllerProvider` family argument starts the controller in search mode, so the field is focused from the first frame without flicker | Made | The query parameter is deep-linkable; opening search after the first frame would flash the title and notify during build | Engineering |
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
apps/features/workout     flutter analyze --no-pub → No issues found; flutter test --no-pub → 157 passed (rerun after the Library search addition)
apps/core                 flutter analyze --no-pub → No issues found; flutter test --no-pub → 325 passed
apps/app                  flutter analyze --no-pub → No issues found; flutter test --no-pub → 379 passed (rerun after the Library search addition)
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
- The Library top-bar search icon opens Exercises with its search field focused.
- The bottom navigation is hidden on Library and Exercises.
- `/workout/library` deep links follow `/workout` gating.

### Known Limitations

- The reported URL stays `/workout` after the imperative pushes (go_router default). Deep links to `/workout/library` and `/workout/exercises` still work.
- Programs, Routines and Plans sections await W6B/W6C. The entry subtitle reads `Browse exercises` until more sections exist.

### Final Status

`PASS`: merged via PR #349 (`a98bce82`) after green CI, a clean Codex review at the exact head, 0 unresolved threads and a matching head.
