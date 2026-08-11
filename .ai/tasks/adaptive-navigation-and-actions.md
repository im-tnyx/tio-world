# Adaptive Navigation And Action Entry

**Status:** Ready
**Primary owners:** `apps/shared`, `apps/core`, `apps/app`, Settings, affected feature packages
**Affected platforms:** Flutter phone; responsive behavior for compact and wide phone/tablet layouts

Implementation is intentionally deferred to Roadmap Phase 9, after the guided App Mode layout and core feature workflows are stable.

## 1. Discovery

### User Outcome

Let the user keep one of three App Modes while manually choosing three to six eligible destinations. Home stays fixed, screen sections adapt without duplication, and Workout/Nutrition actions remain available from the most useful entry point.

### Success Criteria

- App Mode and navigation personalization remain separate concepts.
- Home is first and required; the selected destination count stays between three and six.
- Home and feature surfaces adapt section prominence through a prepared composition model.
- Workout start/resume and meal logging reuse one owner-controlled workflow regardless of entry surface.
- A mode/layout change never loses an active workout, stored data, or a valid route.

### Scope

- Stable destination identity and eligibility rules.
- Guided defaults plus later custom layout persistence and Settings UI.
- Root destinations, promoted shortcuts, responsive overflow behavior, and route reconciliation.
- Home surface composition and feature action-entry placement.
- Focused contract, navigation, state, accessibility, and representative-layout tests.

### Non-Goals

- Implementing unfinished Workout, Nutrition, Meal Plan, Coach, You, or Social features.
- Moving feature business logic into `apps/app` or `apps/core`.
- Changing `AppMode` beyond `workout`, `nutrition`, and `hybrid`.
- Changing the approved device-local App Mode persistence boundary or prematurely adding account sync.

## 2. Codebase Exploration

### Verified Evidence

- `apps/app/lib/app/router.dart` keeps five stable registered `StatefulShellRoute.indexedStack` branches and derives visible guided tabs from App Mode.
- The shell uses explicit stable branch identity; visible destination position is not treated as the registered branch index.
- Settings implements App Mode editing, while Home, Workout, Nutrition, Progress, and most related feature content remain placeholders or documented targets.
- `AppMode`, guided `AppDestination` mappings, and device-local mode persistence exist. Navigation-layout preference, a complete eligible destination registry, surface composition, and action-entry registries do not.

## 3. Clarification

| Decision | Status | Rationale | Owner |
| :--- | :--- | :--- | :--- |
| App Mode values remain three | Decided | Product scope stays separate from navigation preference. | Product/architecture |
| Custom selection range is three to six, including fixed Home | Decided | Supports focused and expanded layouts. | Product/UX |
| Compact-phone presentation for six selections | Needed before implementation | Must preserve label, touch-target, and reachability quality. | Design/Flutter |
| Layout persistence and account sync | Needed before implementation | Must align with App Mode/profile persistence. | Product/data |
| Exact root and promoted-shortcut catalog | Needed per released feature | Do not expose placeholder features in Settings. | Product/feature owner |

## 4. Architecture Design

### Chosen Approach

```text
AppMode + FeatureAvailability + NavigationPreference
  -> EligibleNavigationLayout
  -> Route/destination mapping

AppMode + EligibleNavigationLayout + PreparedFeatureState
  -> Home/feature SurfaceComposition

SurfaceComposition + Feature-owned action descriptors
  -> primary, secondary, contextual, and persistent entry points
```

Root destinations own primary navigation state. Promoted shortcuts reuse a canonical feature route. The active destination uses stable identity and route matching rather than a raw visible index.

### Ownership And Data Flow

- `apps/shared`: pure-Dart mode, destination identity, layout, and eligibility contracts when approved.
- `apps/core`: generic navigation, section, action-slot, and persistent-activity UI.
- `apps/app`: route registration and composition only.
- Settings: mode and Navigation & Tabs preference UI.
- Workout/Nutrition/other features: command availability, context, validation, controller, repository, and workflow state.

### Alternative Rejected

Separate screens or duplicated start/log workflows for every tab combination are rejected because they multiply behavior and create inconsistent user state.

### Failure And Accessibility States

Handle invalid saved layouts, missing/unreleased destinations, mode changes, six-item compact overflow, deep links, active-session preservation, keyboard/focus order, screen-reader labels, text scaling, and restore-to-default behavior.

## 5. Implementation Plan

- [x] Complete and automatically validate the initial App Mode guided-layout foundation; later onboarding steps remain outside this task.
- [ ] Approve stable destination and layout contracts plus persistence ownership.
- [ ] Replace numeric visible-tab identity with destination-key mapping.
- [ ] Add route registry and mode/availability eligibility resolver.
- [ ] Add Home section composition contracts using prepared feature summaries.
- [ ] Add feature-owned action descriptors and generic action slots.
- [ ] Add persistent active-workout resume projection without moving session ownership.
- [ ] Add Settings selection, reorder, preview, confirmation, and reset flow.
- [ ] Add responsive three-to-six destination rendering.
- [ ] Add reconciliation, deep-link, back-stack, representative-layout, and accessibility tests.

## 6. Quality Review

### Validation Run

```text
Not run. Documentation-only future task.
```

### Review Findings And Resolution

Confirm every promoted shortcut maps to one canonical feature route and every action maps to one feature-owned workflow before implementation is accepted.

## 7. Final Handoff

### Changed Files

Documentation only when this task was created.

### Actual Behavior

This future task has not changed runtime behavior. The prerequisite App Mode foundation now provides guided layouts and stable branch mapping; custom layout, adaptive surfaces, and action-entry behavior remain unimplemented.

### Known Limitations

Persistence, compact six-selection presentation, final destination catalog, and released feature availability remain future implementation decisions.

### Final Status

`REVIEW`
