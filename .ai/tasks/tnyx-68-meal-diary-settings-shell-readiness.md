# TNYX-68 — Minimal Meal Diary Settings Shell Readiness

**Status:** Implemented; owner UI approved; final exact-head CI and Codex review pending
**Primary owner:** `apps/features/nutrition` presentation with `apps/core` route contracts and `apps/app` composition
**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice and product-visible navigation/UI
**Approval status:** Implementation approved and complete for this shell. Owner UI is APPROVED, and re-check is pending only for the top-bar action ordering changed during review. Merge is gated on review resolution, exact-head CI, and explicit owner merge authorization — not on UI approval.
**Approval evidence:** Owner instruction dated 2026-09-08 explicitly authorizes the minimum TNYX-68 shell, routes/navigation, Meal Diary More menu, only the Meal Categories row and approved child boundary, focused tests, one implementation branch, and one review PR.
**Approved readiness boundary:** `Meal Diary -> More / vertical ellipsis -> Meal Diary Settings -> Meal Categories` with the minimal child navigation boundary recorded below, plus the owner-approved `Settings -> Nutrition Settings -> Meal Diary Settings` entry into the same route.
**Explicit non-changes:** No Meal Categories management UI, shared `MealLogActionFooter` category-selector activation, Quick Add or Meal Editor change, MealLog persistence, Slice C/D implementation, Supabase mutation, `services/api` change, TNYX-66 status change, or dependency-relation change.

This slice does change Flutter production source, routes and tests — that is what the owner authorized. An earlier revision of this brief listed those among the non-changes, which contradicted both the authorization above and the committed work; the line is corrected rather than carried forward.

## Active Handoff

**Planning owner:** Codex `/root`
**Implementation owner:** Codex `/root`
**Review owner:** None
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-08 after fresh Git/GitHub/Linear read-only verification and the authorized shell implementation
**Base SHA:** `9be00dcb1a3a8e3707a811a29f783dfd21c04d46` (`main == origin/main` at branch creation)
**Branch:** `tnyx/tnyx-68-meal-diary-settings-shell`
**Observed working-tree state:** Only the files listed in section 10 are part of this slice
**Preserved local-only state:** root `pubspec.lock` SHA-256 `004DE1A093C1F04F684B39DF072C2F2E37B1CD21046BFEE01E628E7F77300B1C` is unchanged and deliberately uncommitted; `.ai/tasks/tnyx-54-nutrition-ia-readiness.md` belongs to the completed TNYX-54 and is not carried by this branch; `docs/supabase-android-studio-qa-run` @ `7fe896820c8f176b5049df4fe84fc9acea5933b1` is untouched
**PR / tracker:** PR [#226](https://github.com/im-tnyx/tio-world/pull/226), Draft. Head `90f9bef1adb5b1431132c71e4d6082d07e8e7c67` passed exact-head CI run `34200265358` (SUCCESS: Analyze Flutter, Analyze Dart, Test Flutter, Test Dart). This reconciliation commit moves the head past that run, so `34200265358` is historical evidence and the new head needs its own run. TNYX-54 is `Done`; TNYX-67 is `In Progress`; TNYX-68 moved to `In Progress` on 2026-09-08; TNYX-66 remains `Backlog`. Existing relations are unchanged.
**Current implementation state:** The owner-authorized minimum shell is implemented, green locally and green on CI, and the owner has approved its rendered UI. Implementation scope is unchanged since that approval — only governance and documentation have moved. TNYX-67 Slice C and the shared `MealLogActionFooter` Meal Category selector activation remain unstarted.
**Relevant execution surface:** Core route contracts and shell top-bar slot, app route/action composition, Nutrition-owned Meal Diary menu and settings presentation
**Validation completed:** See section 10; Core/Nutrition/App analyze and test suites are green and `git diff --check` is clean
**Validation remaining:** CI on the new reconciled head, and a Codex review on that head
**Current blocker:** None on UI. Merge is gated on explicit owner merge authorization; the branch is not to be merged before that.
**Open review finding IDs:** None. Codex review is pending on the reconciled head; no findings have been raised on any earlier head.
**Next exact action:** Confirm CI on the reconciled head, obtain the Codex review, then stop and wait for explicit owner merge authorization.

## 1. Discovery

### User Outcome

Establish the smallest safe Meal Diary-owned settings navigation foundation before Meal Categories management and before Quick Add consumes Meal Category state.

### Success Criteria

- canonical entry is `Meal Diary -> More / vertical ellipsis -> Meal Diary Settings`;
- the first settings page exposes only `Meal Categories >`;
- the row reaches a minimal child route/destination boundary without implementing category management;
- the existing Today action, centred visible-month context, streak treatment, selected date, and back behavior remain intact;
- TNYX-67 remains the only owner of Meal Categories management behavior and state;
- no Supabase or Quick Add behavior changes.

### Scope

Future implementation may add only route contracts, the feature-owned More menu semantics, app-owned route/action composition, one Nutrition-owned Meal Diary Settings page, a minimal Meal Categories child destination boundary, and focused tests.

### Non-Goals

Show meal times, Meal Notes, note preview, reminders, notification scheduling, category load/list/edit/add/archive/reactivate/reorder/max-eight UI, Restore Defaults, shared `MealLogActionFooter` category selector activation, Meal Editor, MealLog, or Supabase changes.

## 2. Codebase Exploration

### Verified Evidence

- `AppRoutes` owns route identities under `apps/core/lib/src/routing/routes/app_routes.dart`; current Nutrition settings routes use `/settings/nutrition/...` and `ChromePolicy.fullScreen`.
- `apps/app/lib/app/router.dart` owns `GoRoute` registration, root navigator placement, shell composition, and the current conditional Meal Diary Today action.
- `MealDiaryPage` and `MealDiaryDateController` are Nutrition-owned. The date controller is `autoDispose`, but the indexed shell remains mounted beneath a pushed root settings route; future navigation tests must prove selected-date preservation rather than assume it.
- `TioShellStatusTopBar` owns title/center/streak geometry and accepts one generic `Widget? leadingAction`. The app can supply one compact `Row(mainAxisSize: MainAxisSize.min)` containing conditional Today plus the Meal Diary More action. No Core API/theme change is required.
- No production popup/overflow menu precedent exists under `apps/`; the future feature-owned menu should use standard Flutter menu semantics and governed Core visual values without creating a feature token bag.
- `TioGroupCard`, `TioSettingsNavigationRow`, and `TioSettingsLeadingIcon` already own the required settings grouping/row treatment.
- `NutritionSettingsPage` intentionally exposes implemented capabilities only, so the Meal Diary Settings row was added there the moment the destination became real rather than as an inert placeholder.
- `mealCategoriesRepositoryProvider` already composes the single Meal Categories repository owner. TNYX-68 must not read it because this shell renders no category state.
- Quick Add currently labels the disabled control `Meal type. Not available yet.` and has no category callback. It remains unchanged.
- GitHub has no open PR and no TNYX-68 branch. The only TNYX-67 remote branch is the stale preserved documentation branch already visible from Git.

### Existing Pattern to Follow

- Core route contract plus app-level `GoRoute` registration;
- feature widget receives navigation callbacks from app composition;
- full-screen Settings page uses `Scaffold`, `AppBar`, `BackButton`, theme-aware colors, `TioGroupCard`, and `TioSettingsNavigationRow`;
- shell feature action is supplied through the generic top-bar action slot rather than teaching Core about Meal Diary.

### Tests or Validation Already Present

- `apps/core/test/app_routes_test.dart` for route contract assertions;
- `apps/app/test/app/app_mode_router_test.dart` for Nutrition shell, Today, visible month, and streak/top-bar behavior;
- `apps/app/test/app/nutrition_settings_route_test.dart` for full-screen Nutrition route/chrome/navigation patterns;
- `apps/features/nutrition/test/meal_diary/meal_diary_page_test.dart` for date/Today preservation;
- `apps/features/nutrition/test/presentation/nutrition_settings_page_test.dart` for grouped settings rows and theme/compact-width behavior.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Canonical entry | Chosen | `Meal Diary -> More / vertical ellipsis -> Meal Diary Settings` is the owner-preferred contextual path | TNYX-68 |
| Secondary Nutrition Settings shortcut | Included in this slice | Owner addendum of 2026-09-08 approved it here: Settings -> Nutrition Settings -> Meal Diary Settings is the discoverable path, the Diary More menu is the contextual shortcut, and both push the same route so no second page or preference store exists | TNYX-68 |
| Parent route | Chosen direction | `AppRoutes.mealDiarySettings` at `/settings/nutrition/meal-diary`, full-screen | Core contract / app registration |
| Child route boundary | Chosen direction | `AppRoutes.mealCategoriesSettings` at `/settings/nutrition/meal-diary/categories`; first slice may supply only title/back destination structure, with no category state/content | TNYX-68 navigation; TNYX-67 content |
| Top-bar coexistence | Chosen | App composes conditional Today then More inside the existing generic action slot; centred month and rightmost streak remain unchanged | App composition |
| More menu semantics | Chosen | Nutrition owns menu copy/action; app injects navigation callback | Nutrition + app |
| Category state | Excluded | TNYX-68 shell does not read, cache, or duplicate `mealCategoriesRepositoryProvider` | TNYX-67 |
| Archived presentation | Not reopened | Exact Archived layout belongs to TNYX-67 Slice C and does not block this shell | TNYX-67 |
| Restore Defaults | Excluded | Historical-safe reset semantics remain deferred and do not block this shell | TNYX-67 follow-up |

## 4. Architecture Design

### Chosen Approach

```text
Meal Diary shell
  -> feature-owned More menu action
  -> app callback pushes AppRoutes.mealDiarySettings
  -> Nutrition MealDiarySettingsPage
  -> Meal Categories navigation row
  -> app callback pushes AppRoutes.mealCategoriesSettings
  -> minimal destination boundary only

TNYX-67 Slice C later
  -> supplies the Meal Categories management body/controller
  -> reads mealCategoriesRepositoryProvider through app composition
```

The child destination boundary proves route ownership without adding category management, Supabase reads, or duplicate state. It must not present fake categories or editable controls.

### Ownership and Data Flow

```text
Core AppRoutes contracts
  -> app GoRouter registration and top-bar callback composition
  -> Nutrition-owned menu/settings presentation
  -> no repository/data flow in this slice
```

### Alternatives Rejected

- direct `Nutrition Settings -> Meal Categories`: skips the canonical Meal Diary Settings hierarchy;
- replacing Today with More: regresses existing Diary navigation;
- changing the Core shell API: unnecessary because the existing generic widget slot can hold the action cluster;
- reading Meal Categories in the shell: duplicates TNYX-67 responsibility and creates premature loading/error/state behavior;
- enabling Quick Add first: creates a consumer before management/owner-approved UI exists.

### Failure and Accessibility States

- menu and navigation actions require explicit tooltips/semantic labels and standard tap targets;
- no loading/error state exists because this slice reads no data;
- back navigation must return to the same Diary controller state;
- long text and compact widths must not overflow in all supported theme modes.

## 5. Proposed Implementation Plan

- [x] Add `mealDiarySettings` and `mealCategoriesSettings` route contracts in Core.
- [x] Add Nutrition-owned `MealDiaryMoreMenu` with one `Meal Diary Settings` action.
- [x] Add Nutrition-owned `MealDiarySettingsPage` containing only the `Meal Categories` navigation row.
- [x] Add the minimal child destination route shell with no category content or repository access.
- [x] Export the new Nutrition presentation surfaces through the existing Meal Diary barrels.
- [x] Register both full-screen routes and callbacks in app composition.
- [x] Compose Today and More through the existing top-bar generic action slot; preserve centre/streak geometry.
- [x] Add focused contract/widget/router/regression/theme/accessibility tests.
- [x] Add the owner-approved `Meal Diary Settings` row to the Nutrition Settings hub, pointing at the same route as the Diary More menu.

### Likely Future File Surface

- `apps/core/lib/src/routing/routes/app_routes.dart`
- `apps/core/test/app_routes_test.dart`
- `apps/app/lib/app/router.dart`
- `apps/app/test/app/app_mode_router_test.dart`
- a focused app route test, likely `apps/app/test/app/meal_diary_settings_route_test.dart`
- `apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_settings_page.dart`
- a minimal child destination page/shell under the same Meal Diary presentation boundary
- `apps/features/nutrition/lib/src/meal_diary/presentation/widgets/meal_diary_more_menu.dart`
- `apps/features/nutrition/lib/src/meal_diary/presentation/presentation.dart`
- focused Nutrition widget tests under `apps/features/nutrition/test/meal_diary/`

No `apps/app/lib/app/network_providers.dart`, category controller, Supabase, or Quick Add source change is required for this first shell.

## 6. Quality Review

### Proposed Future Validation

- More action is visible on Meal Diary and opens its one-item menu;
- selecting Meal Diary Settings opens the full-screen parent route;
- Meal Categories row is visible and delegates/navigates to the child destination boundary;
- child and parent back navigation return correctly;
- historical selected date and visible range are preserved;
- conditional Today remains present and functional when required;
- centred month label and rightmost streak remain unchanged with Today absent/present;
- Light, Dark, OLED, System-dark, compact width, large text, semantics, keyboard/focus, and tap targets;
- no repository call, Supabase write, category mutation, or Quick Add activation.

### Readiness Validation Run

```text
git fetch --prune
git status --short --branch
git branch -a
git rev-parse main
git rev-parse origin/main
GitHub open PR and branch searches
Linear fresh pre/post status and relation reads
Supabase get_project, list_migrations, and read-only catalog/count SELECT
git diff --check
```

## 7. Hosted Supabase Boundary

Read-only verification on `oykupyiitspujzpwwvuj` returned `ACTIVE_HEALTHY`, 40 migrations with latest `20260907065602_add_meal_categories_config`, two preserved `user_nutrition_profiles` rows, one expected JSONB column, one CHECK, one validator, one retained-ID function, one enabled trigger, RLS enabled, authenticated owner SELECT/INSERT/UPDATE policies, and zero standalone DELETE policy.

TNYX-68 shell requires zero Supabase migration, schema/RLS/RPC/index/storage change, read, or write.

## 8. Settings-First Sequence

```text
TNYX-68 minimal Meal Diary Settings shell
  -> TNYX-67 Slice C Meal Categories management UI
  -> owner UI approval
  -> shared MealLogActionFooter Meal Category selector activation
```

The consumer slice is not Quick Add-specific. `MealLogActionFooter` is the Nutrition-owned reusable footer that carries the Meal category control, the date/time control, and the primary action; Quick Add is only its first runtime consumer, and the future full Meal Editor reuses the same footer. Activating the selector therefore belongs to that shared footer, not to a Quick Add-local dropdown.

The future selector must resolve active items from `mealCategoriesRepositoryProvider`; it must not hard-code Breakfast/Lunch/Dinner/Snacks. Archived layout and Restore Defaults remain TNYX-67 decisions and are not TNYX-68 blockers.

## 9. Final Classification

`IMPLEMENTED — the TNYX-68 shell is built, validated and owner-UI-approved.`

The delivered slice is the canonical Meal Diary More menu, the Meal Diary Settings shell, the Meal Categories navigation row, the minimal child destination boundary, and the owner-approved Nutrition Settings entry into the same route. It carries no category state, no Quick Add or Meal Editor change, no Core API expansion, and no Supabase mutation.

Implementation no longer requires authorization — it has it, and it is done. What remains before merge is review-thread resolution, exact-head CI, an owner re-check of the top-bar action ordering changed during review, and explicit owner merge authorization.

## 10. Implementation Truth

### Base and branch

```text
base SHA   9be00dcb1a3a8e3707a811a29f783dfd21c04d46
branch     tnyx/tnyx-68-meal-diary-settings-shell
```

### Exact changed files

```text
added
  apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_diary_settings_page.dart
  apps/features/nutrition/lib/src/meal_diary/presentation/pages/meal_categories_destination_page.dart
  apps/features/nutrition/lib/src/meal_diary/presentation/widgets/meal_diary_more_menu.dart
  apps/features/nutrition/test/meal_diary/meal_diary_settings_shell_test.dart
  .ai/tasks/tnyx-68-meal-diary-settings-shell-readiness.md

modified
  apps/core/lib/src/routing/routes/app_routes.dart
  apps/core/lib/src/theme/README.md
  apps/core/test/app_routes_test.dart
  apps/app/lib/app/router.dart
  apps/app/test/app/app_mode_router_test.dart
  apps/app/test/app/nutrition_settings_route_test.dart
  apps/features/nutrition/lib/src/presentation/pages/nutrition_settings_page.dart
  apps/features/nutrition/test/presentation/nutrition_settings_page_test.dart
  apps/features/nutrition/lib/src/meal_diary/presentation/presentation.dart
  apps/features/nutrition/lib/src/meal_diary/presentation/widgets/widgets.dart
```

The two deletions are intentional: the top bar's trailing padding becomes conditional, and one Nutrition route test title no longer says "both" now that four routes are asserted. No formatter churn is carried — the local SDK's `dart format` disagrees with the repo baseline on 73 pre-existing files, so it was not run across the tree, and the reformatting it had introduced in `router.dart` and `app_mode_router_test.dart` was reverted by hand.

### Navigation entries

```text
Settings -> Nutrition Settings -> Meal Diary Settings     discoverable path
Meal Diary -> More / vertical ellipsis -> Meal Diary Settings   contextual shortcut
```

Both push `AppRoutes.mealDiarySettings.path`. There is one page, one route and one future preference state; the hub row is a link, not a second surface. `apps/app/test/app/nutrition_settings_route_test.dart` walks both doors in one test and asserts the resolved path from the second equals the path captured from the first.

### Top-bar composition

```text
[Today?]  [More]  [streak]
```

One Core slot, one caller-composed `Row(mainAxisSize: MainAxisSize.min)`. Tests assert geometry rather than presence at both 390 px and 320 px: the streak's right edge is identical whether or not the conditional Today action is showing, More sits before the status, and Today sits before More.

### Route ownership

```text
apps/core .../app_routes.dart        contracts only
  mealDiarySettings      /settings/nutrition/meal-diary
  mealCategoriesSettings /settings/nutrition/meal-diary/categories
  both ChromePolicy.fullScreen

apps/app/lib/app/router.dart          registration and composition
  both added to shellChromePolicyForPath's full-screen set
  both registered with parentNavigatorKey: rootNavigatorKey
  navigation callbacks are supplied by app composition, not by the feature
```

No second navigation system was introduced and no unrelated settings route was added.

### More menu implementation

Core is unchanged. An earlier revision of this branch added a second `statusTopBarTrailingAction` slot, which pushed the streak left by roughly an `IconButton` whenever an action appeared and contradicted the Core README's canonical contract. Review caught both; the slot was removed and the app composes Today and More into the one existing `statusTopBarLeadingAction` as a compact `Row`, so the rendered order is `[Today?] [More] [streak]` and the status keeps its original right edge. Core still learns nothing about Meal Diary routes or settings semantics.

`MealDiaryMoreMenu` is Nutrition-owned and built from `MenuAnchor` plus `TioCard.elevated`. Because the trigger sits near the right edge of the bar, the framework clamped the menu panel flush against the screen and the card's rounded corner read as clipped; the panel now carries a small symmetric padding, which is the card's margin rather than decoration. Device capture found this, and a test pins it: with the padding removed the card's right edge lands at 390 on a 390-wide screen and the assertion fails.

`consumeOutsideTap: true` is set because the default lets the tap that dismisses the menu also press whatever is underneath — on the Diary, a date cell or the logging action, so closing the menu would silently change the selected day. The test asserts the negative: after the dismissing tap the underlying callback count is unchanged, with a baseline tap first so a zero is a real result rather than a dead target. Its trigger is wrapped in `MergeSemantics(Semantics(expanded: controller.isOpen, ...))` — the framework's own `SubmenuButton` treatment — because `IconButton` exposes no expanded flag and a screen reader would otherwise never learn the menu is open. Menu chrome uses `TioPalette.transparent` so the card, not the raw Material surface, paints the menu.

### Settings shell visible content

```text
Meal Diary Settings

  [icon]  Meal Categories            >
          Manage meal categories
```

One `TioGroupCard` holding one `TioSettingsNavigationRow`. `Show meal times`, `Meal Notes`, `Show note preview`, `Meal Reminders` and `Restore Defaults` are absent, and a test asserts each one is absent rather than merely disabled.

### Child destination treatment

`MealCategoriesDestinationPage` renders a themed title and a back affordance over an empty body. It reads no provider, holds no state, and contains no editable control. TNYX-67 Slice C owns the management body.

### Exclusions honoured

```text
TNYX-67 Slice C category management        not implemented
category load/list/rename/add/archive      not implemented
reorder / max-eight / Archived / defaults  not implemented
shared MealLogActionFooter category selector  not activated
Quick Add / Meal Editor                    unchanged
MealLog persistence                        unchanged
Supabase migration, schema, RLS, mutation  none
services/api                               untouched
apps/app/lib/app/network_providers.dart    unchanged
mealCategoriesRepositoryProvider           unchanged; overridden in one test only, to prove zero calls
Nutrition Settings secondary shortcut      IN SCOPE as of the owner addendum
Show meal times / Notes / Reminders        deliberately absent
```

No production-only debug or evidence entrypoint ships: the harness that briefly existed under `apps/app/lib/` was removed, and the repo has no golden or dev-harness convention to extend.

### Test coverage

`apps/features/nutrition/test/meal_diary/meal_diary_settings_shell_test.dart` — 9 tests: the More trigger's tap target, tooltip and expanded/collapsed semantics; the menu exposing exactly one action; the settings shell's single row, its merged semantics label and the absence of every later preference; the child destination holding no rows, text fields or reorderable list; the open menu staying inside a 390 px screen instead of sitting flush against the right edge; a dismissing outside tap leaving the underlying control's callback count unchanged; and Light, Dark, OLED and System-dark each resolving at 320 px width under 1.6x text scale.

`apps/app/test/app/app_mode_router_test.dart` — the full route journey through the real router: More is present alongside the streak, the menu item navigates to the parent route, the row navigates to the child route, both back hops land correctly, the historical selected date survives the round trip, the conditional Today action returns, and the injected `MealCategoriesRepository` records zero reads and zero writes.

`apps/app/test/app/nutrition_settings_route_test.dart` — chrome-policy registration for both new routes, and the shared-destination test that walks Settings -> Nutrition -> Meal Diary Settings, then returns to the Diary and walks More -> Meal Diary Settings, asserting the second resolved path equals the first and that exactly one `MealDiarySettingsPage` is mounted.

`apps/features/nutrition/test/presentation/nutrition_settings_page_test.dart` — the hub's new row, its supporting copy, its upward delegation, and the continued absence of the preferences that page owns.

`apps/core/test/app_routes_test.dart` — route contract registration.

### Validation run

```text
flutter analyze  apps/core                No issues found
flutter analyze  apps/features/nutrition  No issues found
flutter analyze  apps/app                 No issues found
flutter test     apps/core                266 passed
flutter test     apps/features/nutrition  323 passed
flutter test     apps/app                 295 passed
git diff --check                          clean
```

`melos` is not installed on this machine, so the documented per-package equivalents were run. Exact-head GitHub CI is the authoritative full validation.

### UI evidence

Captured from the real `TioApp` through the real router at 390x844 and 320x640, with Roboto and MaterialIcons loaded so the render is readable rather than the test font's boxes. The capture harness was temporary and is not in the branch: nothing ships under `lib/`, and no golden baseline was committed, because the repo has no golden convention to extend.

```text
1  Meal Diary top bar with More        Light / Dark / OLED
2  More menu open                      Light / Dark / OLED
3  Meal Diary Settings                 Light / Dark / OLED
4  Meal Categories destination         Light / Dark / OLED
5  Nutrition Settings hub with the new row   Light
6  Meal Diary Settings at 320 px       Light
```

### Owner UI status

`OWNER UI APPROVED` — the owner reviewed the captured evidence on 2026-09-08 and reported no UI issue.

The approval covers this shell only:

```text
Settings -> Nutrition Settings -> Meal Diary Settings
Meal Diary -> More / vertical ellipsis -> the same Meal Diary Settings
the Meal Categories navigation row
the minimal empty Meal Categories destination boundary
```

It does not approve the TNYX-67 Slice C category-management UI, which remains unbuilt and unapproved. Merge still requires explicit owner merge authorization.
