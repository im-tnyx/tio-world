# Screen Catalog And Module Plan

**Status:** Ready
**Primary owners:** `apps/app`, `apps/core`, `apps/shared`, and the affected feature packages
**Affected platforms:** Flutter phone, Flutter Wear OS

## 1. Discovery

### User Outcome

Plan every known app screen and product module independently so future work can proceed in small, owner-safe slices. The plan must start with App Mode, use Home as the phone summary screen, include independent Workout, Nutrition, Progress, and Recovery planning, and document Routine/Program-first workouts plus muscle heatmap, radar map, and calendar expectations.

### Success Criteria

- Each known current route, Wear home, and identified nested Workout/Nutrition screen has a source-based screen specification.
- Every planned screen has an owner, visible content, actions, data boundary, states, and acceptance criteria.
- App Mode, profile-derived Nutrition Targets/Workout Settings, and future Recovery boundaries are explicit.
- No Flutter/Dart runtime code, storage, health integration, or backend system is introduced by this planning work.

### Scope

- Screen catalog under `docs/screens/`.
- Canonical ownership and roadmap updates needed to recognize Recovery as a future independent feature.
- A recommended implementation sequence, with App Mode as the gate.

### Non-Goals

- Implementing any screen, package, route, persistence, sync, sensor, Health API, authentication, or backend contract.
- Creating an empty `apps/features/recovery` package.
- Treating current placeholders as working product features.

## 2. Codebase Exploration

### Verified Evidence

- `apps/app/lib/app/router.dart` keeps five registered `StatefulShellRoute.indexedStack` branches, derives visible tabs from App Mode, and still uses placeholders for Home and core feature content.
- `apps/core/lib/src/ui/shell/presentation/widgets/tio_shell_bottom_nav.dart` renders the supplied guided destination list rather than assuming all registered branches are visible.
- `apps/features/splash`, `apps/features/welcome`, `apps/features/auth`, App Mode onboarding, and App Mode Settings contain the current phone screen UI in this catalog.
- `apps/wear/lib/src/home/presentation/wear_home_screen.dart` shows seven static action tiles and a `coming soon` snack bar for each.
- Canonical documentation establishes `AppMode`, guided target navigation, future adaptive personalization, future Meal Plan, Material 3 Expressive direction, and Flutter Wear OS ownership.

## 3. Clarification

### Decisions Required Or Made

| Decision | Status | Rationale | Owner |
| :--- | :--- | :--- |
| App Mode persistence | Decided | Device-local first; account sync is deferred until an approved Supabase profile contract exists. | Product/architecture owner |
| Recovery's first data source and scope | Needs decision | Required before creating Recovery source code, health permissions, or calculations. | Product/architecture owner |
| Workout Routines/Programs, Exercise Search, muscle heatmap, radar map, and calendar | Target | Workout starts only from a selected Routine or Program session. Exercise Search is nested and uses a versioned local JSON catalog first. Visuals use recorded workout history; Recovery context is later and conditional. | Workout owner |
| Nutrition Targets and Workout Settings | Target | Profile supplies context; each feature owns its calculations, overrides, and UI. | Nutrition and Workout owners |

## 4. Architecture Design

### Chosen Approach

Use one source-based specification per screen under [docs/screens](../../docs/screens/README.md). Keep feature implementations independent behind their documented owners. Share only pure-Dart contracts through `apps/shared` and reusable UI through `apps/core`.

### Ownership And Data Flow

```text
Profile context -> stable shared contract -> Nutrition / Workout defaults
Workout / Nutrition / Progress summaries -> stable contract -> Home / Coach / Recovery presentation
AppMode in apps/shared -> onboarding + settings preference boundary -> app shell guided-layout model
Navigation preference + feature availability -> future eligible layout -> Home/feature surface composition
```

### Alternative Rejected

Putting every screen and its data logic in `apps/app` was rejected because it would make independent Workout, Nutrition, Progress, and Recovery work conflict and violate the existing ownership rules.

### Failure And Accessibility States

Every eventual data screen needs loading, empty, error, offline/stale, and permission states. Charts, heatmaps, and calendar cells require text equivalents; colour cannot be the only meaning.

## 5. Implementation Plan

- [x] Confirm device-local App Mode persistence for the first slice and defer account sync.
- [x] Implement the App Mode contract, first onboarding selection, Settings mode change, and guided shell mapping as one foundation slice.
- [ ] Complete later mode-conditional onboarding steps and manually verify device-restart persistence.
- [ ] Define the smallest approved profile-context contract needed by the first Workout or Nutrition slice.
- [ ] Start Workout, Nutrition, Home, and Progress as separate scoped tasks, linking their screen specifications.
- [ ] Keep the Phase 9 adaptive-navigation task deferred until the guided layout and core workflows are stable.
- [ ] Decide Recovery's first source/scope before creating its package.
- [ ] Start Wear tiles only after their corresponding phone/shared contracts exist.

## 6. Quality Review

### Validation Run

```text
Documentation link and whitespace validation to be recorded with this documentation change.
```

### Review Findings And Resolution

- Guided phone navigation now matches App Mode while retaining stable registered branch identity.
- Coach/Tio remains registered for future routing but is hidden and redirected to Home before Phase 7.

## 7. Final Handoff

### Changed Files

The screen specifications, documentation index, architecture/ownership/roadmap references, and this task brief.

### Actual Behavior

This is documentation-only planning. Runtime behavior is unchanged.

### Known Limitations

Recovery source/scope still requires an explicit decision before Recovery source implementation.

### Final Status

`READY`
