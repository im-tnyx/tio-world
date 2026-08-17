# Current State

Last verified from runtime source and canonical documentation: 2026-08-14.

This file is a concise handoff for the next agent. It is not a replacement for runtime source, root documentation, or feature ownership rules.

## Read Order

1. Read this file for the current snapshot.
2. Read [DECISIONS.md](DECISIONS.md) for durable choices.
3. Read the relevant file in [tasks/](tasks/README.md) before implementation.
4. Verify the affected runtime source and canonical docs before changing behavior.

## Verified Runtime Facts

- The phone app is Flutter in `apps/app` and uses `go_router` with `StatefulShellRoute.indexedStack`.
- `apps/shared` exposes the pure-Dart `AppMode` (`workout`, `nutrition`, `hybrid`), `AppDestination`, guided destination mapping, and mode-preference contract.
- Flutter renders the initial Splash frame before `AppModeBootstrap` loads the confirmed mode from device-local `SharedPreferencesAsync` storage and refreshes routing. Missing or invalid data routes to mode selection.
- The shell keeps stable registered branches but derives the visible guided tabs from App Mode: Home/Workout/Progress, Home/Nutrition/Progress, or Home/Workout/Nutrition/Progress. Coach remains unavailable before Phase 7.
- Home chrome renders uppercase `TIO` at the left inset, a true-centered
  display-only plan pill, and the shared 36dp Profile avatar. Back, Settings, and
  streak are absent. Workout and Nutrition roots own icon-only Workout streak and
  Meal Log streak status until their feature data supplies real positive counts.
- Onboarding routes one parent flow whose first child is
  `OnboardingSectionRenderer -> AppModeSection -> AppModeScreen`, followed by
  `ProfileSection -> ProfileStepRenderer` for nine typed Profile child screens,
  then a real Hybrid-only `WorkoutIntroSection -> WorkoutIntroScreen` gate,
  `WorkoutSection -> WorkoutStepRenderer` for Workout Preferences,
  `NutritionIntroSection -> NutritionIntroScreen` for the Nutrition intro,
  `TargetsSection -> TargetStepRenderer` for the complete Targets section (real Bridge,
  StepTarget, SleepTarget, WaterTarget, GoalPace, and NutritionTarget screens),
  and finally `ReviewSection -> ReviewScreen`. Choosing `setupNow` keeps Workout Preferences
  in the path; choosing `later` skips directly to Nutrition Intro.
  Workout Preferences now has a fully real typed W1/W2/W3 child flow.
  Targets collects typed Daily Steps, Sleep Schedule, Water Target, Goal Pace, and
  authoritative NutritionTarget recommendations (Mifflin-St Jeor BMR, activity-factored TDEE,
  goal-pace adjusted calories, protein, carbs, fat, fiber) into `TargetsOnboardingDraft` with pure
  `SleepScheduleHelper`, `WaterUnitConverter`, `GoalPaceResolver`, `GoalPaceTargetDateCalculator`,
  and canonical `CalculateNutritionTargetRecommendationUseCase` backed by `apps/features/nutrition/domain`.
  Durable Owner Persistence architecture is fully implemented with canonical owner repositories:
  `ProfileSetupRepository` (`apps/features/profile`), `WorkoutPreferencesRepository` (`apps/features/workout`),
  and `TargetsSetupRepository` (`apps/features/nutrition`), orchestrated atomically via `PersistOnboardingOwnerDataUseCase`
  in `CompleteOnboardingUseCase`. Mode-aware persistence guarantees inactive workout selections are never stored.
  Real remote repository adapters (`RemoteProfileSetupRepository`, `RemoteWorkoutPreferencesRepository`, `RemoteTargetsSetupRepository`),
  DTO mappers (`ProfileSetupDtoMapper`, `WorkoutPreferencesDtoMapper`, `TargetsSetupDtoMapper`), server finalizer (`RemoteOnboardingFinalizer` for `POST /api/v1/onboarding/finalize`),
  Google authentication chain (`GoogleAuthUseCase`, `GoogleSignInProvider`, `FirebaseAuthSessionRepository`, `FirebaseAuthTokenProvider`), Device identity contract (`DeviceIdentity`, `DeviceIdentityProvider`, `FlutterDeviceIdentityProvider`),
  and Backend user sync (`BackendUserSyncRepository`, `RemoteBackendUserSyncRepository`, `BackendUserSyncRemoteDataSource` for `POST /api/v1/auth/google-sync`) are fully implemented and tested.
  Because client runtime currently lacks live Firebase client options/credentials, `authTokenProvider` defaults to `UnavailableAuthTokenProvider`,
  `authCapabilityProvider` defaults to `AuthCapabilityUnavailable`, `authProductState.isReadyForProtectedBackendCalls` remains `false`, and onboarding completion remains safely `BLOCKED` until live Firebase client auth is wired.
  All 164 onboarding tests, 11 nutrition tests, 8 profile tests, 5 workout tests, 23 auth tests, 11 shared network/device tests, and 90 phone-app tests pass (312 total tests across all 7 packages).
- The shell uses a 36dp shared avatar and Profile uses 80dp. Tapping the Profile
  avatar opens `/profile/avatar`, whose 1:1 preview uses the 160dp `extraLarge`
  fallback when no image exists. Edit, delete, and download remain disabled until
  Profile media handlers and private Storage are implemented.
- `TioAvatarFrame` supports no frame for Free, a theme-semantic circular gradient
  ring for Plus, and a theme-semantic hexagon crop/frame for Pro. The full-screen
  `extraLarge` fallback always suppresses plan framing. Current runtime entitlement
  remains Free until a Billing/Entitlement owner is implemented.
- The centered plan pill is display-only while no subscription route or billing
  owner exists; it must not behave like a dead CTA.
- Shared `TioButton` primary, secondary, and ghost variants now use core tokens for dimensions, spacing, state layers, outlines, disabled behavior, and loading presentation. Loading blocks duplicate actions, exposes live semantics, and becomes static under reduced motion.
- Pixel 9 emulator validation found and fixed Welcome contrast drift: image controls remain white, feature summaries use a semantic surface, and the entrance animation consumes reduced-motion tokens. Light and dark phone captures plus a compact-width widget check pass.
- The first Material 3 Expressive slice restores Material touch feedback, applies high-contrast and reduced-motion theme behavior, and uses token-driven `NavigationBar`, `TioAvatar`, and `TioButton` contracts. Manual device and accessibility checks remain open.
- `apps/wear` is an active Flutter Wear OS package. Its home screen presents Workout and Nutrition quick-action tiles, but selecting a tile currently shows a `coming soon` message.

## Documented Targets, Not Runtime Behavior

- The routed `/onboarding` parent screen keeps the unnumbered App Mode chooser
  free of top chrome; later children use fixed Back/progress, one changing
  scrollable child, and a fixed bottom primary action. A pure mode-derived flow
  plan uses stable step IDs. Draft mode, confirmed App Mode, and onboarding
  completion remain separate so the first choice cannot open Home prematurely.
- A final-stage custom navigation upgrade will keep Home first and allow three to six eligible destinations. Home/feature sections and action entry prominence may adapt; destination identity must not rely on raw numeric tab indexes.
- Workout is Routine/Program-first: an active session starts from a selected Routine or Program session, not a standalone Quick Start. Exercise Search is a nested Routine/Program editor screen planned around a validated versioned local JSON catalog. Workout Library remains a Workout route and may become a future promoted shortcut after implementation. Meal Plan remains a deferred Nutrition route with the same future promotion boundary.
- Workout start/resume and Nutrition meal logging remain single feature-owned workflows even when Home, a root tab, or a promoted shortcut launches them. Active Workout must remain resumable independently from the selected layout.
- Recovery is a future independent feature, not a primary tab. Its initial outcome, data source, privacy/sync boundary, and non-medical scope are undecided; do not create a package or health integration yet.
- Material 3 Expressive remains the phone design direction through `apps/core`; later shared components and screen migrations build on the implemented theme/navigation/avatar/button foundation rather than a separate Flutter API assumption.
- Wear OS remains Flutter. Its future scope is lightweight workout controls and nutrition quick actions; full food search, diary editing, and Meal Plan editing remain on phone.
- Apple Watch remains a future native Swift + SwiftUI app.
- Supabase is the active production persistence, Auth, and Storage platform. Workspace `supabase/` contains initial migrations for `users`, `user_workout_preferences`, `user_targets`, `onboarding_drafts`, and `avatars` bucket with strict RLS (`auth.uid() = user_id`). Concrete adapters `SupabaseProfileSetupRepository`, `SupabaseWorkoutPreferencesRepository`, `SupabaseTargetsSetupRepository`, `SupabaseOnboardingDraftRepository`, `SupabaseAuthSignInRepository`, and `SupabaseAuthSessionRepository` are implemented and wired in app composition.
- Future HTTP/backend adapters (`Remote*Repository`, `ApiClient`, `DioApiClient`, `GoogleAuthUseCase`, etc.) remain 100% preserved for a future protected backend upgrade.
- Three persistence lifecycles are strictly maintained: (1) Unfinished onboarding draft in `public.onboarding_drafts` (RLS-protected, versioned, temporary), (2) Canonical owner data in `public.users`, `public.user_workout_preferences`, `public.user_targets`, and (3) Non-sensitive metadata (`OnboardingStatus`, `AppMode`) in `SharedPreferences`.

## Active Implementation Boundary

The App Mode foundation, Supabase Auth architecture, owner data persistence, and secure draft persistence/resume are implemented and covered by focused controller, route-policy, persistence, mapper, router, and shell-widget tests. Their current boundary is:

- Persist the confirmed selection device-locally through a pure-Dart preference contract and an app-composed `SharedPreferencesAsync` adapter.
- Persist non-sensitive onboarding bootstrap metadata only: explicit `OnboardingStatus` plus schema/version metadata.
- Unfinished draft state is stored exclusively in `public.onboarding_drafts` behind `OnboardingDraftRepository` with monotonic revision autosave and hydration race protection. Never stored in plaintext local files or SharedPreferences.
- Keep draft App Mode, confirmed App Mode, and onboarding completion as separate concepts.
- Onboarding completion writes canonical owner entities, publishes completed status, and cleans up obsolete draft records.
- Stale draft cleanup failure does not undo or compromise successful completion.
- Return to mode selection when local data is missing or invalid; reconcile unavailable guided routes to Home.
- Keep onboarding on Review when required compatibility owner sections remain
  active, and never route Home on failed completion.
- Defer account sync until an approved Supabase profile contract exists. Do not add a Supabase schema/bucket, backend endpoint, or cross-device merge behavior in this slice.
- Treat Android onboarding as non-authoritative for Nutrition because it has no
  dedicated Nutrition onboarding section. Real Nutrition fields must come from
  local owner-backed contracts, and none were found yet in the current source.
- Complete the later Nutrition Preferences/Targets owner-backed onboarding
  steps in a separate slice; do not treat the current Review boundary as
  product-complete onboarding while compatibility owner steps remain.

See [tasks/app-mode-foundation.md](tasks/app-mode-foundation.md) for the implemented
mode foundation and [tasks/onboarding-flow.md](tasks/onboarding-flow.md) for the
implemented flow/completion foundation and remaining owner-backed work.

Custom navigation, adaptive Home composition, and action-entry placement are a later task. See [tasks/adaptive-navigation-and-actions.md](tasks/adaptive-navigation-and-actions.md).

See [the screen catalog](../docs/screens/README.md) before starting a screen or module vertical slice.

## Guardrails

- Runtime source/config is the behavior truth; canonical docs are the intended product truth.
- Label any future capability as target, planned, or scaffolded. Do not imply it is live.
- Keep feature ownership in its owning package. Profile and Settings may launch other domains but do not own their business logic.
- Do not record secrets, credentials, local paths, build output, or transient task chatter in `.ai/`.
