# Onboarding Flow Architecture

## Status

**Typed-section routing, common Profile, the real Hybrid-only Workout Intro
gate, real Workout Preferences, real Nutrition Intro, real Daily Targets (Bridge, Steps, Sleep, Water, Goal Pace, Nutrition Target Recommendation), canonical owner-backed domain persistence architecture, remote repository adapters (`RemoteProfileSetupRepository`, `RemoteWorkoutPreferencesRepository`, `RemoteTargetsSetupRepository`), remote finalizer (`RemoteOnboardingFinalizer`), Google authentication chain (`GoogleAuthUseCase`, `GoogleSignInProvider`, `FirebaseAuthSessionRepository`, `FirebaseAuthTokenProvider`), Device identity contract (`DeviceIdentity`, `DeviceIdentityProvider`, `FlutterDeviceIdentityProvider`), and Backend user synchronization (`BackendUserSyncRepository`, `RemoteBackendUserSyncRepository`, `BackendUserSyncRemoteDataSource`) are fully implemented and validated.**

**Durable Persistence Readiness: BLOCKED (PARTIAL A)**.
Auth timing is verified as `BEFORE_ONBOARDING` (from reference `AuthNavGraph.kt`). The Google authentication chain (`GoogleSignIn` -> Google ID Token -> `FirebaseAuth.signInWithCredential()` -> Firebase User -> `getIdToken()` -> `POST /api/v1/auth/google-sync` -> Backend DB user) is implemented and verified. Device identity generation with SHA-256 fingerprinting is in place.
However, `Tio-World` currently lacks live Firebase client options/credentials in source (using `UnavailableAuthTokenProvider` and `AuthCapabilityUnavailable` by default). Consequently, `AuthProductState.isReadyForProtectedBackendCalls` remains safely false, and `OnboardingStatus.completed` publication remains blocked until live Firebase client authentication is wired.

### Verified Backend Contracts (Source-grounded from `Tnyx-hub`):
- **Profile:**
  - Endpoint: `PATCH /api/v1/onboarding/profile`
  - Request DTO: `{ data: { name: string, gender: "male"|"female"|"other", goals: string[], dob: "YYYY-MM-DD", height: number, currentWeight: number, activityLevel: string, healthConditions?: string[], otherHealthCondition?: string }, isCompleted: true }`
  - Auth: Private (`Bearer <Firebase ID Token>`)
  - Adapter: `RemoteProfileSetupRepository` with `ProfileSetupDtoMapper` & `HttpProfileSetupRemoteDataSource`.
- **Workout:**
  - Endpoint: `PATCH /api/v1/onboarding/workout`
  - Request DTO: `{ data: { gymAccess: "home"|"gym", equipment?: string[], experienceLevel: "fresh"|"beginner"|"intermediate"|"advanced", focusAreas: string[], trainingDays: string[], workoutDuration: string, workoutSplit: string, healthConcerns?: string, specialEvent?: string }, isCompleted: true }`
  - Auth: Private (`Bearer <Firebase ID Token>`)
  - Mode-awareness: Only persisted when `workoutPreferences` was part of active flow.
  - Adapter: `RemoteWorkoutPreferencesRepository` with `WorkoutPreferencesDtoMapper` & `HttpWorkoutPreferencesRemoteDataSource`.
- **Targets:**
  - Endpoint: `PATCH /api/v1/onboarding/target`
  - Request DTO: `{ data: { stepTarget: number, sleepTarget: number (hours, decimal allowed, e.g. 7.5), sleepTime: "HH:mm", wakeTime: "HH:mm", waterTarget: number (ml, lossless), goalPaceKgPerWeek: number, targetWeight: number }, isCompleted: true }`
  - Precision: `sleepTarget` preserves half-hour precision (e.g. 450m -> 7.5h); `waterTarget` preserves exact ml (1000..8000 ml).
  - Adapter: `RemoteTargetsSetupRepository` with `TargetsSetupDtoMapper` & `HttpTargetsSetupRemoteDataSource`.
- **Server Finalizer:**
  - Endpoint: `POST /api/v1/onboarding/finalize`
  - Server Authority: `targetFinalizeService.ts` recomputes `MetabolicEngine` BMR/TDEE/macros server-side and atomically transfers onboarding records to user profile & targets.
  - Missing workout in Nutrition mode / Hybrid later: Server finalizer treats missing workout draft as valid, sets `workoutPayload = null` and `isWorkoutLocked = true`.
  - Adapter: `RemoteOnboardingFinalizer` executing `POST /api/v1/onboarding/finalize`.

The completion transaction coordinates atomic multi-owner persistence:
1. Validates full flow eligibility via `OnboardingCompletionValidator` (`hasDurableOwnerPersistence` required).
2. Persists active owner domain entities via `PersistOnboardingOwnerDataUseCase`:
   - `ProfileSetupRepository` (Profile owner)
   - `WorkoutPreferencesRepository` (Workout owner — mode-aware: skipped if workout was not in active flow)
   - `TargetsSetupRepository` (Nutrition / Targets owner)
3. Invokes server finalization via `OnboardingRemoteFinalizer.finalize()`.
4. Persists confirmed `AppMode` to `AppModePreference`.
5. Persists `OnboardingStatus.completed` to `OnboardingStatusRepository`.
6. Navigates to Home upon successful completion.

If any owner write or server finalization fails, confirmed AppMode and completed status are not written, duplicate submissions remain locked, and the user stays safely on Review with retry capability.

```text
App Router
  -> /onboarding
     -> OnboardingFlowPage
        -> OnboardingTopBar (Back-only for App Mode; progress hidden)
        -> OnboardingContentHost
           -> OnboardingSectionRenderer
              -> section widget
                 -> individual screen, keyed by OnboardingStepId
        -> OnboardingBottomBar

OnboardingController
  -> BuildOnboardingFlowUseCase
     -> draft AppMode: workout | nutrition | hybrid
     -> ordered OnboardingFlowPlan
```

The top region and bottom action region do not scroll away. The content host is
the only scrolling region. When the keyboard opens, the parent resizes so the
active field and primary action remain reachable.

## Android Reference And Flutter Translation

`im-tnyx/tnyx-hub` is the behavioral reference; `im-tnyx/tio-world` is the
Flutter implementation target. The reference is not a prescription to port
Compose, Hilt, Retrofit, integer step identity, or Android navigation classes.

Verified Android source uses this hierarchy:

```text
Navigation
  -> OnboardingRoute
     -> OnboardingContainer
        -> SectionRenderer
           -> Section
              -> individual screen
```

`SectionRenderer` selects `INTRO`, `DATA`, `MOBILE`, `WORKOUT_INTRO`, `WORKOUT`,
`TARGETS`, or `SOURCE`. A section may then dispatch a separate individual screen
by its current step; for example, the data section selects Name, Gender, Goal,
Age, Height, Weight, Target, Activity, or Health Condition screens. The checked-in
reference chain does not include an `OnboardingScreen` between
`OnboardingRoute` and `OnboardingContainer`.

Flutter translates those responsibilities, rather than mirroring Android class
names. The target Flutter hierarchy is:

```text
/onboarding
  -> OnboardingFlowPage
     -> OnboardingContentHost
        -> OnboardingSectionRenderer
           -> section widget
              -> individual step screen
```

`OnboardingSectionRenderer` now implements this dispatch responsibility. It
decides only which section renders; it does not plan flows, persist drafts, call
APIs, calculate targets, or navigate. `BuildOnboardingFlowUseCase` remains the
pure flow planner, and `OnboardingController` remains the Flutter
state/orchestration controller.

## Current Runtime Boundary

Verified source behavior in the current working tree:

- `AppModeOnboardingPage` remains in source as a standalone compatibility
  `StatefulWidget`, but the active `/onboarding` route now mounts
  `OnboardingFlowPage` and the same canonical `AppModeScreen` UI.
- Every active `OnboardingStepDefinition` has a typed `OnboardingSectionId`.
  `OnboardingState.currentSection` is derived from the active definition instead
  of stored as duplicate mutable state.
- `OnboardingContentHost` defaults to `OnboardingSectionRenderer`; its optional
  `stepBuilder` remains only as a focused test injection seam.
- `OnboardingSectionRenderer` dispatches `AppModeSection` for the first section,
  `ProfileSection` for common Profile input, `WorkoutIntroSection` for the real
  Hybrid gate, `WorkoutSection -> WorkoutStepRenderer` for Workout
  Preferences, `ReviewSection -> ReviewScreen` for the final user-visible
  checkpoint, and an explicitly labeled compatibility section/screen for later
  owner steps that are not implemented.
- `WorkoutSection` keeps the durable global identity
  `OnboardingStepId.workoutPreferences` while dispatching section-local
  `WorkoutStepId` children. The current real Workout children are Gym Access,
  conditional Equipment, Experience Level, Focus Areas, Training Days,
  Workout Duration, and Workout Split.
- `BuildWorkoutFlowPlanUseCase` is the single source of Workout child order.
  Gym or unset access currently uses an 8-child plan; Home inserts Equipment
  and expands the child total to 9.
- `WorkoutFocusAreaSelection` centralizes Android-reference `full_body`
  semantics, keeping that mutation rule out of widget callbacks.
- `ProfileSection` delegates to `ProfileStepRenderer`. The renderer switches on
  `ProfileStepId`; each child screen renders one field group and emits typed
  values to `OnboardingController`.
- `ProfileFlowPlan.orderedSteps` is the single source for Name, Gender, Goal,
  Age, Height, Current Weight, Target Weight, Activity, and Health Conditions.
- Profile data and the Hybrid workout-intro choice are held only in
  `OnboardingDraft` for this slice. They are not written to
  `SharedPreferences`, Supabase, a backend, or Profile storage.
- The routed flow keeps draft mode separate from confirmed App Mode;
  `AppModeScreen` owns only intro/mode-card presentation and emits selection.
- The app layer persists non-sensitive onboarding bootstrap metadata only:
  explicit `OnboardingStatus` plus schema/version metadata.
- `OnboardingStatus.notStarted`, `inProgress`, and `completed` use stable string
  serialization rather than enum indexes, and corrupt values fail safe.
- The app bootstraps a dedicated `OnboardingStatusController` before routing.
  Fresh installs with no confirmed mode stay `notStarted`; existing legacy
  installs with a confirmed mode and no stored status migrate once to
  `completed`.
- Router guards no longer treat confirmed mode alone as completion truth.
  Home/shell access now requires `OnboardingStatus.completed` plus a usable
  confirmed mode; `completed` without a confirmed mode fails safe back to
  onboarding.
- `CompleteOnboardingUseCase` validates completion eligibility, ensures status
  storage is initialized, writes confirmed App Mode, then writes
  `OnboardingStatus.completed`. A failed completion never routes Home.
- Review summarizes only real captured data and explicitly blocks Finish while
  required Nutrition Preferences/Targets owner sections remain compatibility
  previews.
- `apps/features/onboarding/lib/src/domain` owns stable step IDs, versioned draft
  and status models, exact mode plans, and safe current-step reconciliation.
- `OnboardingController` and `OnboardingFlowPage` provide the tested fixed progress,
  changing scrollable content, fixed actions, system-Back, duplicate-finish lock,
  compact-width, large-text, semantics, and reduced-motion foundation.
- Focused tests cover typed step-to-section mappings, all three mode plans,
  Profile child order/bounds/navigation, renderer dispatch, screen callbacks and
  errors, `AppModeScreen` draft selection, parent-shell behavior, and app-router
  integration.
- Parent-shell widget coverage verifies `AppModeScreen` updates `OnboardingDraft`,
  recalculates the eligible mode path, and does not publish confirmed App Mode.
- `WorkoutIntroScreen` emits a typed Hybrid choice only. `later` removes
  `workoutPreferences` from the rebuilt flow plan, reduces total progress by one
  step, and preserves Back to `workoutIntro` from `nutritionIntro`.
- Workout answers remain in-memory only. Centralized validation now enforces
  Gym Access, Equipment when Home is eligible, Experience Level, Focus Areas,
  Training Days, Workout Duration, and Workout Split. `HealthConcerns` and
  `SpecialEvent` are real optional text inputs that stay in-memory only.
  `WorkoutStepValidator.hasRequiredSelections` now distinguishes required
  Workout readiness from optional W3 text context, but overall onboarding
  completion remains blocked by remaining Nutrition/Targets compatibility
  owner sections.
- The parent shell is registered in `apps/app/lib/app/router.dart` on
  `/onboarding`, so it now changes current user-visible routing.
- A secure sensitive resume repository and cross-owner draft persistence still do
  not exist. Restarting during unfinished onboarding preserves the incomplete
  gate truth but may lose in-memory Profile data.
- Supabase and a structured local database are not implemented.

Runtime source remains the truth until the planned slices below are delivered.

## Durable Decisions

### One Route, One Parent Shell

`go_router` opens one `/onboarding` route. Individual onboarding steps are not
independent app routes. `OnboardingController` selects the current child by stable
`OnboardingStepId`.

### App Mode Intro Is The First Child

`AppModeSection` dispatches the single current `AppModeScreen`, which combines the
short onboarding introduction and the three App Mode cards. There is no separate
intro route or numbered progress step. Its top bar and progress are hidden.
Selection updates only `OnboardingDraft`; the resulting Workout, Nutrition, or
Hybrid plan determines the later children and progress total.

System Back remains active on this top-bar-free chooser. It invokes the approved
route-exit path; once persisted draft fields exist, that path must enforce the same
safe-exit confirmation policy as later steps.

This keeps progress, keyboard handling, back behavior, loading lockout, draft
saves, and completion behavior in one place. Child widgets render fields and emit
typed updates; they do not navigate or persist directly.

### Common Profile Is One Typed Section

The global plan keeps one stable `OnboardingStepId.profileBasics`. Inside that
macro step, `ProfileStepId` provides the exact child order:

```text
name -> gender -> goal -> age -> height -> currentWeight
     -> targetWeight -> activity -> healthConditions
```

`OnboardingController` owns internal Continue and Back transitions. Back from
Gender returns to Name; Back from Name returns to App Mode. The global Profile
step is marked complete only after Health Conditions validates. The following
global step still comes from `OnboardingFlowPlan`: Workout Preferences for
Workout, Workout Intro for Hybrid, and Nutrition Intro for Nutrition. Workout
Intro is the Android-reference “set up workout now or later” gate; it is not a
workout-data screen.

The single visible progress bar counts every actual visible user-facing screen after App Mode.
App Mode is the pre-progress entry screen: Back is visible, progress bar is hidden, and App Mode
is excluded from the denominator. Once the user enters the first Profile screen (Name), progress
starts at `1 / totalSteps` and advances continuously on every visible child screen transition.
The total denominator is derived dynamically by `BuildOnboardingProgressPlanUseCase` from the active
`OnboardingFlowPlan` and `WorkoutFlowPlan` (e.g. 24 for gym workout, 25 for home workout with Equipment,
17 for nutrition, 26/27 for hybrid setupNow, 18 for hybrid later). Review reaches exactly 1.0.
Progress is purely derived presentation/domain state and is never stored in drafts or database models.
Each Profile screen also announces deterministic `Profile step N of 9` semantics from `ProfileFlowPlan.orderedSteps`
through its screen header without a second visible progress bar.

Temporary onboarding-local field contracts match the verified Android reference:
name requires at least 3 trimmed characters, DOB spans 1950 through today,
height spans 100–250 cm, and current/target weight span 30–200 kg. Goal requires
exactly one primary choice while allowing supporting goals. Health Conditions is
optional; selecting Other requires a description. These rules do not imply a
persisted Profile schema or server contract.

### Workout Preferences Is One Typed Section

The global plan keeps one stable `OnboardingStepId.workoutPreferences`. Inside
that macro step, `WorkoutStepId` now provides the section-local child
vocabulary:

```text
gymAccess -> equipment? -> experienceLevel -> focusAreas
         -> trainingDays -> workoutDuration -> workoutSplit
         -> healthConcerns -> specialEvent
```

`BuildWorkoutFlowPlanUseCase` owns the dynamic Equipment insertion rule:

- `gym` or unset access -> 8 child steps, no Equipment child
- `home` -> 9 child steps, Equipment becomes required and visible

`OnboardingController` owns internal Continue and Back transitions exactly like
Profile. Back from Experience returns to Equipment for Home users and to Gym
Access for Gym users. Changing gym access preserves existing Equipment answers
in memory but removes Equipment from the active plan and from current
validation when it becomes ineligible.

The real Workout child screens are Gym Access, Equipment, Experience Level,
Focus Areas, Training Days, Workout Duration, Workout Split, Health Concerns,
and Special Event. Required Workout readiness is now source-backed through
typed W1/W2 validation, while W3 remains optional. Workout no longer uses
`WorkoutCompatibilityScreen`, and overall onboarding completion still stays
blocked until the remaining compatibility Nutrition/Targets slices are real.

### Mode-Derived Step Plan

The initial target step vocabulary is:

```text
mode
profileBasics
workoutIntro
workoutPreferences
nutritionIntro
targets
review
```

The current Profile child fields and temporary onboarding-local validation are
implemented above. Durable Profile ownership, final consent copy, target formulas,
and later feature settings still require their owning feature tasks.

| App Mode | Ordered target steps |
| :--- | :--- |
| `workout` | mode, profileBasics, workoutPreferences, targets, review |
| `nutrition` | mode, profileBasics, nutritionIntro, targets, review |
| `hybrid` | mode, profileBasics, workoutIntro, workoutPreferences, nutritionIntro, targets, review |

`targets` is a presentation step for prepared module-owned recommendations. It
does not own Nutrition target formulas or Workout defaults. `NutritionPreferences`
was audited against Android reference and local source; no approved owner domain contract
exists, so it is excluded from active MVP flow plans rather than inventing speculative
diet or allergy questionnaires. Optional acquisition
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

This now uses an explicit app-layer completion gate. Existing installations that
already contain a confirmed mode and no stored status migrate once through
`legacyModeOnly` to `OnboardingStatus.completed`, preserving Home access without
mistaking draft App Mode for completion.

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
   ├─ renderer/
   │  └─ onboarding_section_renderer.dart
   ├─ sections/
   │  ├─ app_mode_section.dart
   │  ├─ intro_section.dart
   │  ├─ profile_section.dart
   │  ├─ mobile_section.dart
   │  ├─ workout_intro_section.dart
   │  ├─ workout_section.dart
   │  ├─ nutrition_section.dart
   │  ├─ targets_section.dart
   │  ├─ source_section.dart
   │  └─ review_section.dart
   ├─ screens/
   │  ├─ app_mode/
   │  ├─ intro/
   │  ├─ profile/
   │  ├─ mobile/
   │  ├─ workout/
   │  ├─ nutrition/
   │  ├─ targets/
   │  ├─ source/
   │  └─ review/
   └─ widgets/
      ├─ onboarding_bottom_bar.dart
      ├─ onboarding_content_host.dart
      ├─ onboarding_progress_indicator.dart
      └─ onboarding_top_bar.dart
```

Do not create all target files as empty placeholders. Each delivery slice adds the
smallest working set with tests. `intro`, `mobile`, and `source` are named here
because the Android reference has those section responsibilities; a Flutter owner
slice must first establish that each is required before creating it. `profile` is
the Flutter target vocabulary for the reference `DATA` responsibility, not a copy
of Android's numeric-step implementation.

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
| `OnboardingContentHost` | Host the changing accessible, scrollable content region | Flow planning or business validation |
| `OnboardingSectionRenderer` | Select the current section from stable section/step identity | APIs, persistence, navigation, or target calculation |
| Section widgets | Group related screens and dispatch the current screen | Global flow planning or route changes |
| Individual screen widgets | Render prepared state and emit typed edits | Repositories or global mode publication |

Use one Riverpod `OnboardingController`; do not add a parallel generic `ViewModel`.
Use controller methods for next/back behavior rather than one use case per button.
Use `BuildOnboardingFlowUseCase` for conditional-plan rules because those rules
must remain pure and exhaustively testable.

`OnboardingSectionId` is the stable section identity on every
`OnboardingStepDefinition`. The stable `OnboardingStepId` remains the durable
resume/analytics identity; no route path, numeric index, or Flutter widget belongs
in the domain model.

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
- Replace child content with a step-ID-keyed, top-aligned non-swipe host. Its
  enter/exit motion mirrors the Android reference `AnimatedContent` fade-through:
  a delayed fade-and-scale enter, a short fade exit, and zero duration when
  reduced motion is enabled. User swipes must not bypass validation.

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

- Exclude `OnboardingStepId.mode` from both progress position and total; the
  chooser keeps Back-only chrome and hides the progress bar.
- After mode selection, derive current and total from the remaining eligible
  steps in `OnboardingFlowPlan`, expanding `profileBasics` through the canonical
  nine-step `ProfileFlowPlan` and `workoutPreferences` through the active
  `WorkoutFlowPlan`.
- Announce both position and title, for example `Step 3 of 6, Workout setup`.
- Rebuilding the plan must preserve the current stable step when it remains
  eligible; otherwise move to the nearest previous valid step.
- Progress, content transition, and button transition consume
  `context.tioMotion`; reduced motion uses zero-duration state changes.
- Progress must not rely on color alone.

### Navigation And Bottom Action Rules

- Primary action labels are step-aware: `Continue`, `Review`, or `Finish`.
- Visible Back belongs in `OnboardingTopBar`, never beside the bottom primary
  action. It moves to the previous internal step when one exists.
- On the first step, Back may invoke the approved route-exit flow; it is hidden
  when neither an internal previous step nor a safe exit callback exists.
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

1. **Pure flow foundation — implemented:** step IDs, flow plan, mode matrix, state,
   planner, and exhaustive unit tests.
2. **Parent shell — implemented foundation:** top chrome hidden for the mode
   chooser, fixed Back/progress for later children, changing child host, fixed
   bottom primary action, system-back behavior, and widget/accessibility tests.
   Field-backed keyboard validation starts with the first approved input step.
3. **Mode and typed-section integration — implemented and validated:** the
   active route uses `OnboardingSectionRenderer -> AppModeSection -> AppModeScreen`;
   every planned step maps to typed section metadata, and draft/path behavior has
   focused tests. Onboarding and phone app analyze/test checks pass. Explicit
   completion gating remains a later migration and this slice adds no sensitive
   fields.
4. **Common Profile slice — implemented and validated in memory:** typed child
   order, grouped draft, centralized validation, renderer, screens, Back/Continue,
   mode branching, and deterministic subprogress are implemented. Durable Profile
   ownership, consent finalization, and persistence remain later work.
   contracts.
5. **Workout Intro gate â€” implemented and validated in memory:** Hybrid renders a
   real typed choice screen, `setupNow` keeps Workout Preferences in the path,
   `later` skips directly to Nutrition Intro, and progress/Back behavior rebuilds
   safely around that gate. Durable Workout owner fields remain later work.
6. **Workout and Nutrition branches:** add each independently behind owner
   contracts; hybrid composes both without duplicate fields. Workout
   Preferences is now fully real for Gym Access, Equipment, Experience Level,
   Focus Areas, Training Days, Workout Duration, Workout Split, optional
   Health Concerns, and optional Special Event. The Android onboarding
   reference does not provide a dedicated Nutrition onboarding section, so
   Tio-World Nutrition onboarding must come from Flutter/product owner
   contracts instead of Android parity. `NutritionIntroSection ->
   NutritionIntroScreen` is now real, while `NutritionSection ->
   NutritionStepRenderer` remains an explicit owner-contract block because no
   canonical local Nutrition preference fields were found.
7. **Targets T1 slice (Implemented):** `TargetsSection` -> `TargetStepRenderer`
   delivers real `BridgeScreen`, `StepTargetScreen`, `SleepTargetScreen`, and
   `WaterTargetScreen` with typed `TargetsOnboardingDraft`, pure `SleepScheduleHelper`,
   and `WaterUnitConverter`.
8. **Targets T2 slice (Implemented / Formula-Gated):**
   - **Formula Authority Audit:** Android reference contains conflicting formula families (`TargetCalculator.kt`, `GoalPaceScreen.kt`, `NutritionScreen.kt`), and no canonical local formula authority exists in `apps/features/nutrition` or `apps/shared` (Path C).
   - **GoalPace:** Delivered as real `GoalPaceScreen` with pure `GoalPaceResolver` (Loss, Gain, Maintenance mode derivation from profile weights; reference pace bounds 0.1..1.5 kg/week; aggressive pace warning thresholds $\ge 1.0$) and `GoalPaceTargetDateCalculator` with deterministic clock injection. Widget contains no BMR/TDEE calculations.
   - **NutritionTarget:** Explicitly calculation-blocked (`BLOCKED BY FORMULA AUTHORITY`) via `TargetsCompatibilityScreen` because nutrition macro recommendation requires owner-domain formula authority.
   - **Readiness:** Targets product readiness remains `PARTIAL` and `OnboardingCompletionValidator` separately models durable owner persistence readiness, preventing false completion.
9. **Secure persistence and resume:** implemented via `OnboardingDraftRepository`, `OnboardingDraftSnapshot`, `OnboardingDraftSnapshotDtoMapper`, and `SupabaseOnboardingDraftRepository` backed by `public.onboarding_drafts` with RLS (`auth.uid() = user_id`). Includes monotonic revision autosave, hydration race guards, step reconciliation, and post-completion draft cleanup.
10. **Owner-backed product completion:** replace compatibility Workout/Nutrition/
    Targets blockers with real owner writes, then keep the existing explicit
    completion boundary for end-to-end finalization.


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
