# Mode-Conditional Onboarding Flow

**Status:** PARTIAL (UI & Architecture Ready; Durable Completion Blocked) — App Mode, common Profile section, Workout Intro gate, Workout Preferences (W1/W2/W3), Nutrition Intro, Targets (Bridge, Step Target, Sleep Target, Water Target, Goal Pace, Nutrition Target Recommendation), Review, and Atomic Owner Persistence architecture (`ProfileSetupRepository`, `WorkoutPreferencesRepository`, `TargetsSetupRepository`) with confirmed App Mode & completion transactions are fully implemented and verified. Durable production completion is safely BLOCKED pending client auth & HTTP network infrastructure.
**Primary owners:** `apps/features/onboarding`, with stable contracts from Profile, Workout, Nutrition, `apps/shared`, and app-level provider/route composition
**Affected platforms:** Flutter phone app

## Runtime And Reference Boundary

`tnyx-hub` Android is the behavioral reference; this task implements Flutter
responsibilities in `tio-world`, not Android framework structure. Its verified
reference chain is `OnboardingRoute -> OnboardingContainer -> SectionRenderer ->
Section -> individual screen`; sections may dispatch their own step screens.

Current Flutter source routes `/onboarding` to `OnboardingFlowPage`.
`OnboardingContentHost` now defaults to `OnboardingSectionRenderer`, which derives
the current typed section from step metadata and dispatches a section widget.
The runtime path now supports `AppModeSection`, `ProfileSection`,
`WorkoutIntroSection`, `WorkoutSection`, `NutritionIntroSection`,
`NutritionSection`, `TargetsSection` (all 6 Targets children including real GoalPaceScreen and authoritative NutritionTargetScreen),
and `ReviewSection`. See `docs/ONBOARDING_ARCHITECTURE.md`
for the durable architecture and status boundary.
A new user completes one calm, resumable setup flow. Progress remains visible at
the top, the primary action remains reachable at the bottom, and only the child
content changes. Workout and Nutrition users see only relevant steps; Hybrid users
complete both branches without duplicate profile questions.

### Success Criteria

- `/onboarding` renders one parent `OnboardingFlowPage`.
- The App Mode chooser shows Back-only fixed-height chrome and is excluded from
  progress. On later steps, top Back/progress and the bottom primary action
  remain fixed while the child changes.
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
- [x] Add `OnboardingSectionId`, attach it to every active step definition, and
  derive current section from the active stable step.
- [x] Add `BuildOnboardingFlowUseCase` with exact mode matrices.
- [x] Add exhaustive unit tests for every mode and current-step reconciliation.

### Slice 2: Parent Shell

- [x] Add `OnboardingState` and Riverpod `OnboardingController`.
- [x] Add `OnboardingFlowPage`, keep Back-only fixed top chrome with hidden
  progress for the unnumbered mode chooser, keep Back/progress fixed for later
  children, and keep the bottom primary action fixed.
- [x] Keep child transitions non-swipeable and token/reduced-motion driven.
- [x] Cover system Back, duplicate taps, compact width, large text, and semantics
  with widget tests.
- [x] Add field-backed keyboard coverage with the typed Profile inputs.

### Slice 3: Mode Migration

- [x] Move current mode cards and intro copy into canonical `AppModeScreen`; route
  it through `OnboardingSectionRenderer -> AppModeSection`, while the inactive
  compatibility page reuses the same screen.
- [x] Default production `OnboardingContentHost` to the typed section renderer and
  retain optional builder injection only for focused shell tests.
- [ ] Run manual light/dark device visual comparison of the active routed flow.
- [x] Verify parent-shell integration keeps the selected mode in `OnboardingDraft`,
  derives the eligible path, and does not publish it on first-step Continue.
- [x] Register the parent flow on `/onboarding` with the approved incremental
  rollout state and compatibility child previews.
- [ ] Evolve router/bootstrap gating to read explicit `OnboardingStatus`.
- [ ] Implement and test the approved legacy mode-only migration.

### Slice 4: Common Profile

- [x] Add onboarding-local typed contracts for Name, Gender, Goal, Age, Height,
  Current Weight, Target Weight, Activity, and Health Conditions in the approved
  child order. A durable Profile owner contract and final consent copy remain open.
- [x] Add `ProfileSection`, `ProfileStepRenderer`, nine separate screens,
  field-level validation, accessible subprogress, and typed callbacks.
- [x] Reuse one theme-backed header hierarchy across App Mode, Profile, and
  compatibility screens; associate text-entry errors with their `TioInput`.
- [x] Use semantic strong-outline and motion tokens for interactive cards,
  fade-through transitions, and smooth progress, including reduced-motion
  fallbacks.
- [x] Keep child navigation and validation in `OnboardingController`/domain logic;
  screens only render state and emit values.
- [x] Keep sensitive Profile answers in memory only; add no persistence, Auth,
  Supabase, backend, or Profile storage.
- [x] Verify internal Back, final-child mode branching, completion marking only at
  the child boundary, and Profile data preservation across mode changes.

### Slice 5: Conditional Feature Branches

- [x] Add the real Hybrid-only Workout Intro gate and branch-aware progress/path behavior.
- [x] Add Workout preferences using Workout-owned settings contracts.
- [~] Add Nutrition Intro and the typed Nutrition section boundary. Keep
  Nutrition preference fields blocked until owner-backed local contracts exist;
  Android onboarding is not authoritative here because it has no dedicated
  Nutrition onboarding section.
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

Current Profile section slice validation:

```text
onboarding package: dart format lib test -> PASS
onboarding package: flutter analyze -> PASS
onboarding package: flutter test -> PASS (53 tests)
phone app: flutter analyze -> PASS
phone app: flutter test -> PASS (65 tests)
```

Current typed-section slice validation:

```text
repository: git diff --check -> PASS
dart format -> PASS (37 files checked)
onboarding package: flutter analyze --no-pub -> PASS
onboarding package: flutter test --no-pub -> PASS (32 tests)
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

### 2026-08-14 completion-boundary update

- `OnboardingStatus` now persists through an explicit repository boundary with
  stable string serialization and corrupt-value fail-safe parsing.
- The app bootstraps a dedicated onboarding-status controller before routing and
  no longer treats confirmed App Mode alone as completion truth.
- Existing confirmed-mode installs with missing completion status now migrate
  once through `legacyModeOnly` to explicit `completed`.
- `ReviewSection -> ReviewScreen` is now real and summarizes only real captured
  data.
- `CompleteOnboardingUseCase` validates completion eligibility, writes confirmed
  App Mode, then writes `OnboardingStatus.completed`.
- Finish remains blocked while required Nutrition Preferences/Targets owner
  sections are still compatibility previews, so overall onboarding product
  status remains `PARTIAL`.
- Secure sensitive draft persistence and resume are still pending.

### 2026-08-14 Nutrition N1 update

- Audited local Nutrition ownership before implementation:
  `apps/features/nutrition`, `apps/features/onboarding`, `apps/shared`, and
  `apps/core`.
- Verified that the Android onboarding reference does not contain a dedicated
  Nutrition onboarding section, so Nutrition onboarding in Tio-World cannot be
  filled by parity assumptions.
- Added the real `NutritionIntroSection -> NutritionIntroScreen` path.
- Added `NutritionOnboardingDraft` as an in-memory typed foundation and wired it
  into `OnboardingDraft`.
- Added `NutritionSection -> NutritionStepRenderer` as the typed
  `nutritionPreferences` boundary.
- Kept Nutrition preference UI explicitly compatibility-blocked because no
  canonical owner-backed preference fields were found in the current local
  source.
- Kept Targets separate; no calories, macros, water, or pace logic moved into
  Nutrition preferences.
- Kept sensitive Nutrition answers non-persistent in this slice.

### 2026-08-14 WorkoutPreferences W1 update

- `WorkoutSection -> WorkoutStepRenderer` now owns the global
  `OnboardingStepId.workoutPreferences` step through section-local
  `WorkoutStepId` children.
- `BuildWorkoutFlowPlanUseCase` now drives the dynamic child order:
  Gym/unset access -> 8 steps, Home -> 9 steps with Equipment inserted.
- Real W1 screens are implemented for Gym Access, Equipment, Experience Level,
  and Focus Areas.
- Focus Areas now centralizes Android-reference `full_body` semantics in domain
  logic.
- Back/Next remain controller-owned; changing gym access reconciles the child
  plan safely and preserves Equipment draft answers in memory.
- `TrainingDays`, `WorkoutDuration`, `WorkoutSplit`, `HealthConcerns`, and
  `SpecialEvent` were still pending at the end of the W1 slice, so Workout
  Preferences was not yet product-complete there.

### 2026-08-14 WorkoutPreferences W2 update

- Added source-grounded typed contracts for `WorkoutTrainingDay`,
  `WorkoutDuration`, and `WorkoutSplit` using the Android-reference IDs:
  `monday` through `sunday`, `auto`/`30_min`/`60_min`/`90_min`/`120_min`, and
  `auto`/`full_body`/`upper_lower`/`ppl`/`body_part`.
- `WorkoutOnboardingDraft` now stores typed W2 state, and
  `OnboardingController` now owns typed update APIs for Training Days, Workout
  Duration, and Workout Split.
- `WorkoutSection -> WorkoutStepRenderer` now renders real W2 screens for
  Training Days, Workout Duration, and Workout Split while keeping
  `HealthConcerns` and `SpecialEvent` as the only pending W3 children.
- `WorkoutStepValidator` now enforces all required W2 answers and exposes
  `hasRequiredSelections` so required Workout readiness is explicit without
  claiming optional W3 completeness.
- Workout child order is unchanged:
  Gym Access -> Equipment? -> Experience Level -> Focus Areas -> Training Days
  -> Workout Duration -> Workout Split -> Health Concerns -> Special Event.

### 2026-08-14 validation

```text
onboarding package: flutter analyze --no-pub -> PASS
onboarding package: flutter test --no-pub -> PASS (94 tests)
phone app: flutter analyze --no-pub -> PASS
phone app: flutter test --no-pub -> PASS (87 tests)
```

### Changed Files

- Added pure onboarding models and `BuildOnboardingFlowUseCase` under
  `apps/features/onboarding/lib/src/domain`.
- Added `OnboardingState`, the Riverpod-compatible `OnboardingController`, and
  fixed parent-shell widgets under `apps/features/onboarding/lib/src/presentation`.
- Added typed `OnboardingSectionId` metadata and derived current-section state.
- Added `OnboardingSectionRenderer`, `AppModeSection`, canonical `AppModeScreen`,
  and an honest compatibility section/screen for pending owner slices.
- Added `ProfileSection`, `ProfileStepRenderer`, a grouped typed Profile draft,
  centralized validation, and nine production Profile child screens.
- Added `WorkoutSection`, `WorkoutStepRenderer`, a grouped typed Workout draft,
  dynamic Workout child planning, centralized W1/W2 validation with explicit
  required-readiness checks, real W1/W2 Workout screens, and internal
  continuation toward the later W3 children.
- Added focused domain/controller/widget tests under
  `apps/features/onboarding/test`.
- Updated implementation-status and onboarding documentation to preserve the
  runtime truth boundary.

### Actual Behavior

The reusable flow, parent-shell foundation, typed section dispatch, first-child
App Mode section/screen, nine-screen in-memory common Profile section, and the
real Hybrid-only Workout Intro gate are implemented in source. Workout
Preferences now has a fully real typed W1/W2/W3 child flow for Gym Access,
conditional Equipment, Experience Level, Focus Areas, Training Days, Workout
Duration, Workout Split, optional Health Concerns, and optional Special Event.
The active `/onboarding` route defers confirmed mode publication until Finish.
Choosing `later` at Workout Intro skips Workout Preferences and continues to
Nutrition Intro while preserving correct Back/progress behavior. Focused
package and phone-app checks pass.

### Known Limitations

- Durable Profile ownership/consent, Auth ordering, secure local storage, legacy
  migration, and cross-owner completion transaction remain decision-gated.
- Workout Preferences is fully real. Nutrition Intro is real, but Nutrition
  Preferences and Targets remain compatibility-blocked owner slices.
- Persisted sensitive draft/resume and safe cross-owner completion remain pending.

### Final Status

`PARTIAL` — App Mode, Profile, Workout Intro, Workout Preferences, and Review
are implemented and validated; later Nutrition, Targets, persistence, and
completion slices remain pending.

### 2026-08-14 WorkoutPreferences W3 update

- Added real `HealthConcernsScreen` and `SpecialEventScreen` under
  `WorkoutSection -> WorkoutStepRenderer`.
- `WorkoutOnboardingDraft` now carries in-memory `healthConcerns` and
  `specialEvent` string fields.
- `OnboardingController` now owns typed update APIs for both optional W3 text
  fields.
- `WorkoutStepValidator` keeps both W3 steps optional and leaves
  `hasRequiredSelections` unchanged.
- `OnboardingCompletionValidator` no longer treats Workout Preferences as a
  compatibility blocker. For workout mode, `Targets` is now the remaining
  required blocker; hybrid still blocks on Nutrition plus Targets.
- Review keeps privacy-safe behavior by not exposing raw workout health text.
- `WorkoutCompatibilityScreen` was removed because Workout no longer uses it.
