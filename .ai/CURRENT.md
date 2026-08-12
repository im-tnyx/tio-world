# Current State

Last verified from runtime source and canonical documentation: 2026-08-11.

This file is a concise handoff for the next agent. It is not a replacement for runtime source, root documentation, or feature ownership rules.

## Read Order

1. Read this file for the current snapshot.
2. Read [DECISIONS.md](DECISIONS.md) for durable choices.
3. Read the relevant file in [tasks/](tasks/README.md) before implementation.
4. Verify the affected runtime source and canonical docs before changing behavior.

## Verified Runtime Facts

- The phone app is Flutter in `apps/app` and uses `go_router` with `StatefulShellRoute.indexedStack`.
- `apps/shared` exposes the pure-Dart `AppMode` (`workout`, `nutrition`, `hybrid`), `AppDestination`, guided destination mapping, and mode-preference contract.
- The app loads the confirmed mode from device-local `SharedPreferencesAsync` storage before rendering the router. Missing or invalid data routes to mode selection.
- The shell keeps stable registered branches but derives the visible guided tabs from App Mode: Home/Workout/Progress, Home/Nutrition/Progress, or Home/Workout/Nutrition/Progress. Coach remains unavailable before Phase 7.
- Onboarding implements the first App Mode selection screen. Settings reads and changes the same stored selection from the Home gear entry. Later profile, Workout, Nutrition, review, and completion onboarding steps are not implemented.
- The shell top bar still uses an inline `CircleAvatar`; a shared `TioAvatar` component does not exist yet.
- `apps/wear` is an active Flutter Wear OS package. Its home screen presents Workout and Nutrition quick-action tiles, but selecting a tile currently shows a `coming soon` message.

## Documented Targets, Not Runtime Behavior

- A final-stage custom navigation upgrade will keep Home first and allow three to six eligible destinations. Home/feature sections and action entry prominence may adapt; destination identity must not rely on raw numeric tab indexes.
- Workout is Routine/Program-first: an active session starts from a selected Routine or Program session, not a standalone Quick Start. Exercise Search is a nested Routine/Program editor screen planned around a validated versioned local JSON catalog. Workout Library remains a Workout route and may become a future promoted shortcut after implementation. Meal Plan remains a deferred Nutrition route with the same future promotion boundary.
- Workout start/resume and Nutrition meal logging remain single feature-owned workflows even when Home, a root tab, or a promoted shortcut launches them. Active Workout must remain resumable independently from the selected layout.
- Recovery is a future independent feature, not a primary tab. Its initial outcome, data source, privacy/sync boundary, and non-medical scope are undecided; do not create a package or health integration yet.
- `apps/core` will own the reusable `TioAvatar` with semantic sizes `compact`, `small`, `medium`, and `large`; it defaults to circular and can use a rounded Profile treatment.
- Material 3 Expressive is the phone design direction. `apps/core` will implement it through owned tokens and reusable components; it is not a separate stable Flutter API assumption.
- Wear OS remains Flutter. Its future scope is lightweight workout controls and nutrition quick actions; full food search, diary editing, and Meal Plan editing remain on phone.
- Apple Watch remains a future native Swift + SwiftUI app.
- Supabase is the documented future Auth, Postgres/RLS, and private Storage foundation. No Supabase workspace, project, client, bucket, migration, or credential exists yet. A protected Gemini/backend layer is a later upgrade.

## Active Implementation Boundary

The App Mode foundation is implemented and covered by focused controller, route-policy, and shell-widget tests. Its current boundary is:

- Persist the confirmed selection device-locally through a pure-Dart preference contract and an app-composed `SharedPreferencesAsync` adapter.
- Return to mode selection when local data is missing or invalid; reconcile unavailable guided routes to Home.
- Defer account sync until an approved Supabase profile contract exists. Do not add a Supabase schema/bucket, backend endpoint, or cross-device merge behavior in this slice.
- Complete the mode-conditional later onboarding steps in a separate profile/Workout/Nutrition setup slice; do not treat the current selection page as completed onboarding.

See [tasks/app-mode-foundation.md](tasks/app-mode-foundation.md) for the scoped plan.

Custom navigation, adaptive Home composition, and action-entry placement are a later task. See [tasks/adaptive-navigation-and-actions.md](tasks/adaptive-navigation-and-actions.md).

See [the screen catalog](../docs/screens/README.md) before starting a screen or module vertical slice.

## Guardrails

- Runtime source/config is the behavior truth; canonical docs are the intended product truth.
- Label any future capability as target, planned, or scaffolded. Do not imply it is live.
- Keep feature ownership in its owning package. Profile and Settings may launch other domains but do not own their business logic.
- Do not record secrets, credentials, local paths, build output, or transient task chatter in `.ai/`.
