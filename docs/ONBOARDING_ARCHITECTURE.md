# Onboarding Flow Architecture

## Status

**Target architecture; not implemented.** The current runtime implements only the
first App Mode selection page and persists the confirmed mode device-locally. The
parent flow shell, conditional child steps, full draft, resume behavior, and
completion coordinator described here remain planned.

## Outcome

Tio onboarding uses one full-screen parent route. The parent keeps progress and
actions stable while only the child content changes. A selected `AppMode`
determines the ordered step plan.

```text
/onboarding
└─ OnboardingFlowPage
   ├─ OnboardingTopBar
   │  ├─ exit/save affordance when allowed
   │  └─ OnboardingProgressIndicator
   ├─ Expanded OnboardingContentHost
   │  └─ one child step keyed by OnboardingStepId
   └─ OnboardingBottomBar
      ├─ Back, when a previous step exists
      └─ Continue / Review / Finish primary action
```

The top region and bottom action region do not scroll away. The content host is
the only scrolling region. When the keyboard opens, the parent resizes so the
active field and primary action remain reachable.

## Current Runtime Boundary

Verified source behavior on 2026-08-11:

- `AppModeOnboardingPage` is a standalone `StatefulWidget`.
- It owns selection, saving, and error state locally.
- Confirming a mode writes through `AppModeController` and immediately opens
  Home.
- Router guards currently treat a non-null stored `AppMode` as enough to leave
  onboarding.
- `apps/features/onboarding/src/domain` and `src/data` contain no production
  contracts yet.
- No onboarding-specific widget, controller, flow-planner, resume, or completion
  tests exist yet.
- Supabase and a structured local database are not implemented.

Runtime source remains the truth until the planned slices below are delivered.

## Durable Decisions

### One Route, One Parent Shell

`go_router` opens one `/onboarding` route. Individual onboarding steps are not
independent app routes. `OnboardingController` selects the current child by stable
`OnboardingStepId`.

This keeps progress, keyboard handling, back behavior, loading lockout, draft
saves, and completion behavior in one place. Child widgets render fields and emit
typed updates; they do not navigate or persist directly.

### Mode-Derived Step Plan

The initial target step vocabulary is:

```text
mode
profileBasics
workoutIntro
workoutPreferences
nutritionIntro
nutritionPreferences
targets
review
```

The exact personal fields, target formulas, consent copy, and feature settings
must be approved by their owning feature tasks before implementation.

| App Mode | Ordered target steps |
| :--- | :--- |
| `workout` | mode, profileBasics, workoutIntro, workoutPreferences, targets, review |
| `nutrition` | mode, profileBasics, nutritionIntro, nutritionPreferences, targets, review |
| `hybrid` | mode, profileBasics, workoutIntro, workoutPreferences, nutritionIntro, nutritionPreferences, targets, review |

`targets` is a presentation step for prepared module-owned recommendations. It
does not own Nutrition target formulas or Workout defaults. Optional acquisition
source, marketing, notification, or device-connection steps are not part of this
MVP plan and must never silently block completion.

### Draft Mode Is Not Completion

The full flow must separate these concepts:

```text
draft.selectedMode        # choice inside unfinished onboarding
confirmed AppMode         # active product mode after completion
OnboardingStatus          # notStarted | inProgress | completed
```

Selecting a mode on step one updates the draft and rebuilds the step plan. It must
not publish the confirmed App Mode or redirect to Home. The router leaves
onboarding only after completion succeeds.

This requires evolving the current mode-only route guard. Existing installations
that already contain a confirmed mode need an explicit migration policy before
the completion flag is introduced. The compatibility-first default is to preserve
their Home access and offer missing setup later, but that policy remains an
implementation decision gate.

`OnboardingEntryPath` distinguishes why the parent opened:

| Entry path | Meaning |
| :--- | :--- |
| `firstRun` | No usable draft or completed state exists |
| `resumeDraft` | A version-compatible unfinished draft was restored |
| `legacyModeOnly` | Migration path for an installation that stored App Mode before full completion state existed |

Settings does not use an onboarding entry path; it opens module-owned editors after
completion.

## Target Module Shape

Create files only as their implementation slice begins.

```text
apps/features/onboarding/lib/src/
├─ domain/
│  ├─ models/
│  │  ├─ onboarding_draft.dart
│  │  ├─ onboarding_entry_path.dart
│  │  ├─ onboarding_flow_plan.dart
│  │  ├─ onboarding_status.dart
│  │  ├─ onboarding_step_definition.dart
│  │  └─ onboarding_step_id.dart
│  ├─ repositories/
│  │  └─ onboarding_repository.dart
│  ├─ usecases/
│  │  ├─ build_onboarding_flow_use_case.dart
│  │  ├─ complete_onboarding_use_case.dart
│  │  ├─ initialize_onboarding_use_case.dart
│  │  └─ save_onboarding_draft_use_case.dart
│  └─ validation/
│     └─ onboarding_validator.dart
├─ data/
│  ├─ datasources/
│  │  └─ onboarding_local_data_source.dart
│  ├─ dto/
│  │  └─ onboarding_draft_dto.dart
│  ├─ mappers/
│  │  └─ onboarding_draft_mapper.dart
│  └─ repositories/
│     └─ onboarding_repository_impl.dart
└─ presentation/
   ├─ controllers/
   │  └─ onboarding_controller.dart
   ├─ state/
   │  └─ onboarding_state.dart
   ├─ pages/
   │  └─ onboarding_flow_page.dart
   ├─ steps/
   │  ├─ app_mode_step.dart
   │  ├─ nutrition_intro_step.dart
   │  ├─ nutrition_preferences_step.dart
   │  ├─ profile_basics_step.dart
   │  ├─ review_step.dart
   │  ├─ targets_step.dart
   │  ├─ workout_intro_step.dart
   │  └─ workout_preferences_step.dart
   └─ widgets/
      ├─ onboarding_bottom_bar.dart
      ├─ onboarding_content_host.dart
      ├─ onboarding_progress_indicator.dart
      └─ onboarding_top_bar.dart
```

Do not create all target files as empty placeholders. Each delivery slice adds the
smallest working set with tests.

## Contract Responsibilities

| Contract | Responsibility | Must not own |
| :--- | :--- | :--- |
| `OnboardingStepId` | Stable identity used by flow, progress, resume, and analytics | Widget instances or route paths |
| `OnboardingStepDefinition` | Pure metadata such as ID, owner, required status, and progress title | Callbacks, Flutter widgets, or mutable answers |
| `OnboardingFlowPlan` | Ordered eligible steps for one draft and entry path | Mutable field state |
| `OnboardingDraft` | Versioned unfinished answers and current-step identity | Remote DTO shape or UI controllers |
| `OnboardingState` | Current draft, plan, active step, validation and save status | Database/API objects |
| `BuildOnboardingFlowUseCase` | Produce a deterministic plan from mode and feature availability | Flutter widgets |
| `OnboardingController` | Apply typed updates, validate transitions, save, resume, back and complete | Target calculations or direct APIs |
| `OnboardingRepository` | Hide approved local/remote persistence | Navigation or feature presentation |
| `OnboardingFlowPage` | Compose the fixed parent shell | Feature calculations or persistence |
| Child step widgets | Render prepared state and emit typed edits | Route changes, repositories, or global mode publication |

Use one Riverpod `OnboardingController`; do not add a parallel generic `ViewModel`.
Use controller methods for next/back behavior rather than one use case per button.
Use `BuildOnboardingFlowUseCase` for conditional-plan rules because those rules
must remain pure and exhaustively testable.

## State And Actions

The target `OnboardingState` contains at least:

- the versioned `draft`
- the current `flowPlan`
- the current `stepId`
- completed step IDs
- validation errors for the active step
- `initializing`, `saving`, `completing`, and retryable-error status
- `canGoBack`, `canContinue`, and current primary-action label

The controller exposes intent-focused methods:

```text
initialize
selectMode
updateProfileBasics
updateWorkoutPreferences
updateNutritionPreferences
previous
next
saveAndExit
retry
complete
```

An `OnboardingAction` union is unnecessary for the first slice. Add one only if a
real reducer, replay, or analytics pipeline needs typed action objects.

## Parent And Child UI Contract

### Parent Responsibilities

- Own `Scaffold`, `SafeArea`, keyboard resize, system-back interception, content
  replacement, and route-exit confirmation.
- Keep progress visible above the changing content.
- Keep the primary bottom action visible and locked while saving/completing.
- Render retryable initialization and persistence errors without discarding the
  in-memory draft.
- Use `TioButton`, semantic theme tokens, and shared reduced-motion behavior from
  `apps/core`.
- Replace child content with a step-ID-keyed `AnimatedSwitcher` or equivalent
  non-swipe host. User swipes must not bypass validation.

### Child Responsibilities

- Render one approved step from `OnboardingState`.
- Own only ephemeral field focus and text-editing mechanics.
- Emit typed values to the controller.
- Use the parent bottom action; do not create competing Continue/Finish buttons.
- Keep its content scrollable and include bottom breathing room supplied by the
  host.
- Never call `go_router`, local storage, Supabase, or another feature's private
  presentation implementation.

### Progress Rules

- Before mode selection, announce `Choose mode` without inventing a final total.
- After mode selection, derive current and total from `OnboardingFlowPlan`.
- Announce both position and title, for example `Step 3 of 6, Workout setup`.
- Rebuilding the plan must preserve the current stable step when it remains
  eligible; otherwise move to the nearest previous valid step.
- Progress, content transition, and button transition consume
  `context.tioMotion`; reduced motion uses zero-duration state changes.
- Progress must not rely on color alone.

### Bottom Action Rules

- Primary action labels are step-aware: `Continue`, `Review`, or `Finish`.
- Back is hidden or disabled when no previous internal step exists.
- First-step route exit is a separate explicit action and must not masquerade as
  internal Back.
- Invalid steps keep the primary action disabled and expose field-level guidance.
- Saving/completing disables duplicate taps and announces its loading state.
- On compact screens and with the keyboard open, actions remain reachable without
  covering the active input.

## Ownership Boundary

| Area | Owner |
| :--- | :--- |
| Parent flow, conditional step order, draft progress, and onboarding UI | `apps/features/onboarding` |
| `AppMode` and existing guided destination mapping | `apps/shared` |
| Reusable buttons, fields, progress primitives, tokens, motion, and accessibility defaults | `apps/core` |
| `/onboarding` route composition and provider injection | `apps/app` |
| Personal and fitness profile truth | `apps/features/profile` |
| Workout settings, defaults, and validation | `apps/features/workout` |
| Nutrition targets, overrides, and validation | `apps/features/nutrition` |
| Auth, RLS-protected records, and approved remote draft storage | future `supabase/` |

Onboarding may coordinate stable domain contracts from Profile, Workout, and
Nutrition. It must not copy their formulas, repositories, or presentation state.
`SleepCalculator`, nutrition target calculation, water conversion, workout
normalization, and similar rules stay with their owning domains.

## Data And Persistence Boundary

### First Shell Slice

The parent shell and pure flow planner can ship without a new persistence
technology. They may use an in-memory draft while retaining the already approved
device-local App Mode adapter only for the currently implemented mode-only flow.

### Before Sensitive Draft Persistence

Approve all of the following before storing profile or health answers across app
restarts:

1. Whether Supabase sign-in occurs before or after sensitive fields.
2. Which fields are required, optional, or intentionally not collected.
3. The encrypted local-store choice and deletion/retention behavior, if an
   unauthenticated draft must survive restart.
4. Draft schema versioning and migration behavior.
5. Remote ownership, RLS, conflict, retry, and account-switch behavior.

Do not store body metrics, health answers, or nutrition/workout preferences as
plain JSON in `SharedPreferences`. Supabase Storage is not a structured onboarding
record store.

### Save And Resume

Target behavior:

```text
Controller update
  -> validate changed field/step
  -> update in-memory OnboardingDraft
  -> save approved draft at step transition or lifecycle checkpoint
  -> retain in-memory state if persistence fails
  -> expose retry or safe exit
```

Resume loads and migrates the draft before building the plan. Unknown step IDs,
unsupported versions, invalid modes, account changes, and removed feature steps
must resolve safely instead of crashing or skipping required consent.

### Completion

Completion is idempotent and ordered:

```text
validate every required eligible step
  -> persist Profile-owned context through its contract
  -> persist Workout-owned setup when eligible
  -> persist Nutrition-owned setup when eligible
  -> publish confirmed AppMode
  -> mark OnboardingStatus.completed
  -> clear only the safely committed draft
  -> navigate to Home
```

The exact cross-owner transaction/coordinator and remote schema require a later
approved data task. If any required write fails, the user stays in onboarding with
their draft and can retry. A partial write must not produce a false completed
state.

## Analytics Boundary

Use one optional `OnboardingAnalytics` port rather than separate logger, tracker,
and manager layers. A no-op adapter is valid until an analytics provider is
approved.

Allowed event context includes step ID, mode, entry path, success/failure category,
and elapsed bucket. Never send entered values, body metrics, free text, tokens,
email, or health details. Analytics failure never blocks onboarding.

## Failure, Exit, And Recovery States

The implementation must define and test:

- initial draft loading
- no draft / first run
- valid draft resume
- unsupported or corrupt draft version
- current step removed after a mode change
- active-step validation failure
- local save failure and retry
- completion failure after one owner write
- offline behavior
- app pause/termination during a save
- system Back and explicit exit with unsaved changes
- account switch or sign-out during an authenticated draft
- duplicate Continue/Finish taps

## Alternatives Rejected

- **One `go_router` route per step:** rejected because route history, fixed chrome,
  dynamic step removal, and resume reconciliation would become coupled.
- **A swipeable `PageView`:** rejected for the initial flow because swipes can
  bypass validation and make conditional-plan changes fragile.
- **A giant `SectionRenderer` with business rules:** rejected because it mixes
  flow planning, UI selection, validation, and feature ownership.
- **One class per click (`NextStepUseCase`, `PreviousStepUseCase`):** rejected
  because navigation over an already-built plan is controller behavior.
- **`RetrofitClient` plus `OnboardingApi` now:** rejected because Supabase is the
  planned first data boundary and no remote onboarding contract exists.
- **Putting target calculators in onboarding:** rejected because Nutrition and
  Workout own their calculations and overrides.

## Delivery Slices

1. **Pure flow foundation:** step IDs, flow plan, mode matrix, state, planner, and
   exhaustive unit tests.
2. **Parent shell:** fixed top progress, child host, fixed bottom actions,
   keyboard/system-back behavior, and widget/accessibility tests.
3. **Mode integration:** migrate the current mode card UI into `AppModeStep`, keep
   mode as draft state, and evolve router gating without adding sensitive fields.
4. **Common Profile slice:** add only approved fields and Profile-owned validation
   contracts.
5. **Workout and Nutrition branches:** add each independently behind owner
   contracts; hybrid composes both without duplicate fields.
6. **Targets and review:** render prepared recommendations, overrides, consent,
   and final validation without moving formulas into onboarding.
7. **Persistence and resume:** add the approved secure local/remote repository,
   migrations, offline behavior, and account handling.
8. **Completion:** add idempotent cross-owner finalization, route transition, and
   end-to-end tests.

Each slice must be usable and testable before the next grows.

## Validation Plan

| Layer | Required coverage |
| :--- | :--- |
| Pure domain | Exact step order for all three modes; mode switches; stable step reconciliation; corrupt draft handling |
| Controller | initialize, edit, next/back, save failure, retry, duplicate action lockout, and completion failure |
| Widget | fixed parent regions, changing child only, keyboard, compact width, text scale, dark/OLED/high contrast, and reduced motion |
| Accessibility | progress announcements, focus order, error association, disabled/loading semantics, and screen-reader traversal |
| Router | incomplete flow stays on `/onboarding`; only completed state opens Home; legacy migration behavior |
| Integration | process restart, offline resume, account switch, partial completion retry, and all mode paths |

## Related

- [Onboarding screen specification](screens/onboarding.md)
- [ADR-0006: Single-Route Onboarding Parent Flow](adr/0006-single-route-onboarding-parent-flow.md)
- [App Mode architecture](ARCHITECTURE.md#app-mode-navigation-layout-and-surface-composition)
- [Module ownership](MODULE_OWNERSHIP.md)
- [Data and sync](DATA_AND_SYNC.md)
- [Security](SECURITY.md)
- [Supabase strategy](SUPABASE_STRATEGY.md)
- [Onboarding implementation task](../.ai/tasks/onboarding-flow.md)
