# ADR-0006: Single-Route Onboarding Parent Flow

- **Status:** Accepted
- **Date:** 2026-08-11

## Context

When this decision was made, `/onboarding` rendered one App Mode selection page
and opened Home as soon as that mode was persisted. The current routed foundation
now keeps App Mode in `OnboardingDraft` until its temporary Finish boundary, but
it does not yet persist `OnboardingStatus.completed` or collect owner-backed
profile, Workout, or Nutrition data. The target product needs common profile
setup, mode-conditional sections, target review, draft resume, and final
completion.

Implementing every step as a separate route would duplicate progress and action
chrome, complicate conditional branch removal, and make system Back behavior part
of router history rather than onboarding state. Persisting the first mode choice as
the active product mode would also end the route before later steps can render.

## Decision

- Keep `/onboarding` as one full-screen `go_router` route.
- Add one onboarding-owned parent page with one changing child-content region and
  a fixed bottom primary-action region. Hide top chrome on the unnumbered App Mode
  chooser; after it, keep Back/progress fixed.
- Derive an ordered `OnboardingFlowPlan` from the draft `AppMode` and approved
  feature availability.
- Identify steps by stable `OnboardingStepId`, not route path or list index.
- Let one Riverpod controller own draft state, active-step transitions,
  validation, save/resume, and completion status.
- Keep individual child steps presentation-only: they render state and emit typed
  edits, but they do not navigate, persist, or calculate feature targets.
- Separate the unfinished draft mode, the confirmed product `AppMode`, and
  `OnboardingStatus`. Selecting mode on the first step must not redirect to Home.
- Publish the confirmed App Mode and completed status only after required eligible
  steps have been validated and safely committed.
- Keep Profile, Workout, and Nutrition calculations and persistence with their
  owning domain contracts. Onboarding coordinates those contracts without copying
  their logic.
- Do not choose sensitive local-draft storage, Supabase schema, remote DTOs, or
  analytics provider in this ADR. Those require approved implementation tasks.

## Consequences

### Positive

- The App Mode chooser stays visually clean, while later steps keep consistent
  top Back/progress and a fixed bottom primary action.
- A mode switch can rebuild the eligible step list without rewriting route history.
- Back, validation, retry, loading lockout, and exit confirmation have one owner.
- Hybrid reuses the Workout and Nutrition child steps instead of duplicating a
  separate Hybrid screen tree.
- Stable step identity supports resume, migration, testing, and privacy-safe
  analytics.

### Constraints

- Router guards can no longer infer onboarding completion from a non-null App Mode.
- Existing mode-only installations need an explicit compatibility migration before
  the new completion flag ships.
- Child widgets must keep editable values in controller-owned draft state rather
  than depending on widget lifetime.
- Steps cannot be freely swiped because transitions must pass validation and save
  gates.
- Sensitive answers must not be persisted in plain `SharedPreferences` or logged.
- A completion failure must keep the user in onboarding and must not publish a
  false completed state.

## Implementation Status

The accepted architecture is partially implemented: `/onboarding` mounts
`OnboardingFlowPage`, and the first child updates only draft App Mode. The current
content host still dispatches compatibility previews directly by
`OnboardingStepId`; a dedicated section renderer, section widgets, individual
owner-backed screens, secure draft resume, and explicit completion-status gating
remain pending. This ADR describes the durable decision, while
`docs/ONBOARDING_ARCHITECTURE.md` records the detailed current-runtime versus
target boundary.

## Alternatives Rejected

- **One route per step:** rejected because router history would become the flow
  engine and conditional mode changes would leave invalid routes behind.
- **A swipeable `PageView`:** rejected because it allows validation bypass and is
  brittle when the step count changes.
- **Separate Workout, Nutrition, and Hybrid parent screens:** rejected because it
  duplicates shell, draft, progress, and completion behavior.
- **A generic ViewModel plus a separate state machine and flow engine:** rejected
  because one Riverpod controller plus one pure flow planner provides clearer
  ownership.
- **Persisting confirmed App Mode at step one:** rejected because it conflicts with
  the multi-step completion gate.

## Related

- [Onboarding flow architecture](../ONBOARDING_ARCHITECTURE.md)
- [Onboarding screen specification](../screens/onboarding.md)
- [ADR-0002: Shared App Mode And Dynamic Navigation](0002-shared-app-mode-and-dynamic-navigation.md)
- [Module ownership](../MODULE_OWNERSHIP.md)
- [Onboarding implementation task](../../.ai/tasks/onboarding-flow.md)
