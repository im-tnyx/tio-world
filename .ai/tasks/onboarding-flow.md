# Mode-Conditional Onboarding Flow

**Status:** In progress — Slices 1–2 and AppModeStep extraction implemented; Slice 3 routing migration is next
**Primary owners:** `apps/features/onboarding`, with stable contracts from Profile, Workout, Nutrition, `apps/shared`, and app-level provider/route composition
**Affected platforms:** Flutter phone app

## 1. Discovery

### User Outcome

A new user completes one calm, resumable setup flow. Progress remains visible at
the top, the primary action remains reachable at the bottom, and only the child
content changes. Workout and Nutrition users see only relevant steps; Hybrid users
complete both branches without duplicate profile questions.

### Success Criteria

- `/onboarding` renders one parent `OnboardingFlowPage`.
- The App Mode chooser has no top chrome and is excluded from progress. On later
  steps, top Back/progress and the bottom primary action remain fixed while the
  child changes.
- `workout`, `nutrition`, and `hybrid` produce the documented ordered plans.
- The first App Mode choice remains draft state until final completion.
- Next, Back, system Back, retry, save/exit, and duplicate-tap behavior are explicit.
- Profile, Workout, and Nutrition retain their domain calculations and persistence.
- A failed save or completion does not discard the in-memory draft or falsely open Home.
- Keyboard, compact width, large text, dark/OLED/high contrast, reduced motion, and
  screen-reader behavior pass the documented validation matrix.

### Scope

- Pure step identity, draft, flow-plan, status, validation, and repository contracts.
- Riverpod controller/state for the onboarding flow.
- Fixed parent shell with progress, child host, and bottom actions.
- Migration of the existing App Mode cards into the first child step.
- Common Profile, conditional Workout/Nutrition, targets, review, and completion
  slices after their inputs/contracts are approved.
- Approved local draft/resume and later Supabase sync behind repositories.
- Tests for every mode, transition, failure path, and accessibility contract.

### Non-Goals

- Adding new `AppMode` values.
- Building Workout/Nutrition calculations inside onboarding.
- Creating a full Supabase schema, Storage bucket, Retrofit client, protected
  backend, or Gemini integration.
- Collecting unapproved body, health, consent, attribution, notification, or device
  data.
- Reopening the full onboarding flow from Settings; Settings launches module-owned
  editors after completion.
- Creating every target file as an empty scaffold.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
  - `apps/features/onboarding/lib/src/presentation/pages/app_mode_onboarding_page.dart`
  - `apps/features/onboarding/lib/src/presentation/navigation/onboarding_navigation.dart`
  - `apps/features/onboarding/pubspec.yaml`
  - `apps/app/lib/app/router.dart`
  - `apps/app/lib/app/app_mode/app_mode_controller.dart`
  - `apps/shared/lib/src/app_mode/app_mode_contract.dart`
  - current App Mode controller, route-policy, router, and preference tests
- Existing pattern to follow:
  - Riverpod for state ownership
  - `go_router` for app route composition
  - `TioButton`, theme tokens, and reduced-motion behavior from `apps/core`
  - repository/data-source boundaries from `docs/DATA_AND_SYNC.md`
- Tests or validation already present:
  - App Mode parsing, persistence, queued writes, failure behavior, guided tab
    mapping, and route eligibility have focused coverage.
  - No onboarding parent-shell, conditional-flow, child-step, resume, or completion
    tests exist yet.

### Observed Constraint

The current route guard treats a non-null stored `AppMode` as onboarding complete.
Calling `AppModeController.select` on the first future step would therefore redirect
to Home before later steps render. The full flow must introduce a separate draft
mode and completion status before migrating that behavior.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
| :--- | :--- | :--- | :--- |
| One `/onboarding` route with one parent shell | Approved | Preserves fixed progress/actions and makes step history controller-owned | Onboarding + `apps/app` |
| Top progress, one changing child, fixed bottom primary action | Approved | Matches the intended stable setup experience | Onboarding |
| Step plan derived from draft `AppMode` | Approved | Avoids separate mode-specific parent flows | Onboarding + `apps/shared` |
| Stable step ID, not route/index identity | Approved | Required for resume, migration, analytics, and mode changes | Onboarding |
| Draft App Mode separate from confirmed App Mode and completion | Approved | Prevents premature Home redirect | Onboarding + `apps/app` |
| Exact Profile fields and consent copy | Needs decision before Profile slice | Sensitive collection needs purpose and ownership | Product + Profile |
| Auth before or after sensitive fields | Needs decision before persistent draft | Controls privacy, resume, and remote ownership | Product + Auth/Profile |
| Encrypted local draft technology and retention | Needs decision before persistent draft | Plain preferences are not suitable for health answers | Architecture + Security |
| Existing mode-only installation migration | Needs decision before router migration | Must preserve or deliberately change current Home access | Product + `apps/app` |
| Cross-owner completion transaction/coordinator | Needs decision before completion slice | Partial writes must not claim completion | Architecture + affected features |
| Analytics provider | Deferred | A no-op port is sufficient until observability is approved | Product/Platform |

The parent-shell and pure-flow slices may start without resolving the later
persistence and field-level decisions.

## 4. Architecture Design

### Chosen Approach

Use one pure `BuildOnboardingFlowUseCase`, one Riverpod
`OnboardingController`, and one parent `OnboardingFlowPage`.

```text
go_router /onboarding
  -> OnboardingFlowPage
     -> fixed OnboardingTopBar + progress
        -> Back (previous internal step or approved route exit)
     -> OnboardingContentHost(current StepId)
     -> fixed OnboardingBottomBar
        -> primary Continue / Review / Finish action
        -> OnboardingController
           -> use cases
              -> OnboardingRepository
                 -> approved local/remote data sources
```

Detailed contracts, mode matrices, target folders, failure rules, and alternatives
are canonical in [Onboarding Flow Architecture](../../docs/ONBOARDING_ARCHITECTURE.md)
and [ADR-0006](../../docs/adr/0006-single-route-onboarding-parent-flow.md).

### Ownership And Data Flow

```text
Child step UI
  -> typed controller update
  -> OnboardingDraft
  -> step validator / owner contract
  -> save checkpoint through OnboardingRepository

Finish
  -> validate all eligible steps
  -> Profile / Workout / Nutrition owner contracts
  -> publish confirmed AppMode
  -> mark onboarding completed
  -> clear committed draft
  -> Home
```

### Alternative Rejected

- Separate `go_router` route per step.
- Swipeable `PageView` as the flow engine.
- Separate parent screens for Workout, Nutrition, and Hybrid.
- Parallel `ViewModel`, `FlowEngine`, and `OnboardingStateMachine` layers.
- One use case per Next/Previous button.
- Retrofit/remote-config scaffolding before an approved remote contract.
- Target calculators or normalization rules owned by onboarding.

### Failure And Accessibility States

- initialization, no-draft, resume, corrupt/unsupported draft, validation error,
  saving, retryable save error, completion error, offline, and safe exit
- keyboard-visible action reachability and compact-width scrolling
- semantic progress position/title, logical focus order, associated field errors,
  non-color-only state, loading announcements, high contrast, and reduced motion
- system Back uses the same controller transition as the visible Back action and
  confirms route exit when unsaved work would otherwise be lost

## 5. Implementation Plan

### Slice 1: Pure Flow Foundation

- [x] Add `OnboardingStepId`, `OnboardingStepDefinition`, `OnboardingStatus`,
  `OnboardingEntryPath`, `OnboardingDraft`, and `OnboardingFlowPlan` as pure contracts.
- [x] Add `BuildOnboardingFlowUseCase` with exact mode matrices.
- [x] Add exhaustive unit tests for every mode and current-step reconciliation.

### Slice 2: Parent Shell

- [x] Add `OnboardingState` and Riverpod `OnboardingController`.
- [x] Add `OnboardingFlowPage`, hide top chrome for the unnumbered mode chooser,
  keep Back/progress fixed for later children, and keep the bottom primary action
  fixed.
- [x] Keep child transitions non-swipeable and token/reduced-motion driven.
- [x] Cover system Back, duplicate taps, compact width, large text, and semantics
  with widget tests.
- [ ] Add field-backed keyboard coverage when the first approved input step lands.

### Slice 3: Mode Migration

- [x] Move current mode cards and intro copy into reusable `AppModeStep`; preserve
  selection, confirmation, error, semantics, and reduced-motion behavior while the
  active standalone compatibility page consumes the same section.
- [ ] Run manual light/dark device visual comparison before active-route migration.
- [x] Verify parent-shell integration keeps the selected mode in `OnboardingDraft`,
  derives the eligible path, and does not publish it on first-step Continue.
- [ ] Register the parent flow on `/onboarding` only when every routed step has a
  usable child or an explicitly approved incremental rollout state.
- [ ] Evolve router/bootstrap gating to read explicit `OnboardingStatus`.
- [ ] Implement and test the approved legacy mode-only migration.

### Slice 4: Common Profile

- [ ] Approve required/optional fields, purpose, consent, editability, and owner contracts.
- [ ] Add `ProfileBasicsStep` with field-level validation and accessible input behavior.
- [ ] Keep Profile truth and normalization outside onboarding presentation.

### Slice 5: Conditional Feature Branches

- [ ] Add Workout intro/preferences using Workout-owned settings contracts.
- [ ] Add Nutrition intro/preferences using Nutrition-owned target contracts.
- [ ] Verify Hybrid composes both branches without duplicate profile data.
- [ ] Preserve irrelevant branch draft values when mode changes, but never require
  them for completion.

### Slice 6: Targets And Review

- [ ] Render prepared module-owned recommendations and explicit overrides.
- [ ] Show mode, collected settings, privacy/consent summary, and editable links.
- [ ] Validate every required eligible step before enabling Finish.

### Slice 7: Persistence And Resume

- [ ] Approve Auth ordering, encrypted local technology, schema version, retention,
  account switch, offline, and conflict behavior.
- [ ] Add repository, local data source, DTO/mapper, and migrations only for the
  approved draft contract.
- [ ] Add Supabase remote data source only after Auth/schema/RLS approval.
- [ ] Test process restart, corrupt draft, migration, offline save, and retry.

### Slice 8: Completion

- [ ] Implement idempotent cross-owner finalization with partial-failure recovery.
- [ ] Publish confirmed App Mode and completed status only after required writes succeed.
- [ ] Clear only safely committed draft data and route to the correct Home layout.
- [ ] Add end-to-end tests for Workout, Nutrition, Hybrid, restart, and retry paths.

## 6. Quality Review

### Validation Run

```text
repository: git diff --check -> PASS
onboarding package: flutter analyze --no-pub -> PASS
onboarding package: flutter test --no-pub -> PASS (28 tests)
phone app: flutter analyze --no-pub -> PASS
phone app: flutter test --no-pub -> PASS (61 tests)
```

### Review Findings And Resolution

- The original class list contained overlapping abstractions. The plan consolidates
  them into one flow planner, one controller, four meaningful use cases, and one
  repository boundary.
- Current mode persistence doubles as a completion gate. The plan explicitly
  separates draft selection from confirmed mode and completion.
- Sensitive draft storage is intentionally gated rather than assigned to plain
  preferences or an unimplemented remote API.

## 7. Final Handoff

### Changed Files

- Added pure onboarding models and `BuildOnboardingFlowUseCase` under
  `apps/features/onboarding/lib/src/domain`.
- Added `OnboardingState`, the Riverpod-compatible `OnboardingController`, and
  fixed parent-shell widgets under `apps/features/onboarding/lib/src/presentation`.
- Added reusable `AppModeStep`; both the standalone compatibility page and
  parent-shell tests consume the same intro and mode-card section.
- Added focused domain/controller/widget tests under
  `apps/features/onboarding/test`.
- Updated implementation-status and onboarding documentation to preserve the
  runtime truth boundary.

### Actual Behavior

The reusable flow, parent-shell foundation, and first-child App Mode section are
implemented and tested. The active `/onboarding` route still provides the standalone
compatibility page and immediate Home navigation after confirmation.

### Known Limitations

- Exact Profile fields, consent, Auth ordering, secure local storage, legacy
  migration, and cross-owner completion transaction remain decision-gated.
- The parent shell is not routed yet. Router/completion migration, conditional owner
  steps, persisted draft/resume, and safe completion remain pending.

### Final Status

`PARTIAL` — flow and parent-shell foundation implemented and validated; runtime
mode migration and later sensitive slices remain gated.
