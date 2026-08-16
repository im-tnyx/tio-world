# Roadmap

This roadmap is practical and intentionally staged. Do not build future areas before the current slice needs them.

## App Mode System

App Mode is the first-class product contract for selecting the phone experience:

```dart
enum AppMode { workout, nutrition, hybrid }
```

The implemented `AppMode` enum, guided destination mapping, and preference boundary belong in `apps/shared` so every Flutter feature package can read pure-Dart contracts without violating module ownership. Onboarding starts with mode selection and Settings changes the same selection. The common Profile section now exists as an in-memory typed onboarding slice; Workout, Nutrition, review, persistence, and finish remain planned and conditional on mode.

The first slice persists the confirmed mode device-locally through the shared preference boundary and defers Supabase account sync until an approved profile contract exists. Missing or invalid local data returns to mode selection.

The phone shell keeps stable registered `go_router` `StatefulShellRoute` branches and derives the visible guided layout and route eligibility from the active mode:

| App mode | Guided default tabs |
| :--- | :--- |
| `workout` | Home, Workout, Progress |
| `nutrition` | Home, Nutrition, Progress |
| `hybrid` | Home, Workout, Nutrition, Progress |

Workout Library remains a Workout route, and Meal Plan remains deferred until after the first nutrition MVP. Neither is a guided default tab. A later custom-navigation phase may promote an implemented feature route as a shortcut without changing ownership. Coach becomes eligible only when Phase 7 begins.

## Phase 0: Repository Foundation

Goal: make the public repo clean, understandable, and safe.

- [x] Root README
- [x] Contributing guide
- [x] Code of Conduct
- [x] License
- [x] GitHub templates
- [x] `.ai` orientation
- [x] AGENTS.md
- [x] `.gitignore`
- [x] Initial docs folder
- [x] Flutter modular structure docs

## Phase 1: Flutter Workspace Foundation

Goal: create the modular Flutter workspace that mirrors the native `:app`, `:shared`, `:core`, and `:features:*` structure.

- [x] Create root `pubspec.yaml`
- [x] Create root `melos.yaml`
- [x] Create `apps/app` Flutter phone app shell
- [x] Create `apps/shared` pure Dart package
- [x] Create `apps/core` Flutter package for design system, shell, and route contracts
- [x] Create initial feature packages:
  - [x] `apps/features/auth`
  - [x] `apps/features/onboarding`
  - [x] `apps/features/workout`
  - [x] `apps/features/nutrition`
  - [x] `apps/features/profile`
  - [x] `apps/features/settings`
  - [x] `apps/features/progress`
  - [x] `apps/features/coaching`
  - [x] `apps/features/splash`
  - [x] `apps/features/welcome`
- [x] Add analyzer and test setup per package
- [x] Add Melos validation commands

## Phase 2: Flutter Mobile App Shell

Goal: create the first usable Android+iOS phone shell.

- [x] Add app bootstrap
- [x] Add routing with `go_router`
- [x] Add state management with Riverpod
- [x] Add base theme and design tokens in `apps/core`
- [x] Add app shell and base navigation
- [x] Add placeholder feature routes through feature package contracts
- [x] Keep `apps/app` thin and free of feature business logic
- [x] Add the shared App Mode contract and device-local preference boundary
- [x] Add the mode-first onboarding selection and Settings mode editor
- [x] Derive visible guided tabs and route eligibility from App Mode
- [x] Define the Material 3 Expressive token and component migration plan in `apps/core`, including touch feedback, high contrast, reduced motion, dark mode, and phone-versus-Wear boundaries; theme/navigation/avatar/social buttons implemented with soft haptic feedback
- [x] Extract reusable `TioAvatar` in `apps/core` with compact, small, medium, large, and extra-large sizes plus a screen-selected shape
- [x] Extract reusable `TioSocialButton` in `apps/core` (Google, Truecaller, Email, Phone)
- [ ] Move from basic route constants to typed `go_router` routes when screens mature

Guided tabs are mode-dependent as defined in [App Mode System](#app-mode-system). The five registered branches are internal route identity, not a fixed five-item bottom bar.

Profile should launch from avatar or account entry, not as a main bottom tab.

Settings should launch from Profile or an approved feature-owned entry, not from
a separate Home top-bar icon or a main bottom tab.

## Phase 3: Core Product MVP

Goal: first usable health and fitness app flow.

- [x] Confirm Supabase Auth sign-in methods and the first authenticated vertical slice
- [x] Complete the single-route, mode-conditional onboarding flow on top of the implemented App Mode selection:
  - [x] Add stable step identity and pure Workout/Nutrition/Hybrid flow plans
  - [x] Route one parent screen with a top-bar-free unnumbered App Mode chooser, fixed Back/progress on later children, changing child content, and a unified bottom bar hosting drum wheels dynamically
  - [x] Add the typed in-memory common Profile section with nine child screens (Name, Gender, Goals, DOB with Today default & Underage popup guard, Height with 5'6"/170.0cm dual toggle, Weight with live BMI, Activity, Health), centralized validation, internal Back/Continue, and mode-derived exit
  - [x] Separate draft mode, confirmed App Mode, and onboarding-completion status
  - [x] Add approved Profile, Workout, Nutrition, Targets, and Review child steps
  - [x] Add mid-flow Auth checkpoint (`AuthLandingPage` "Let's get you in") with 1-Tap Google Sign-In and dedicated Email Sign Up (`EmailSignupPage` "Create Account")
  - [x] Add validated save/resume and idempotent completion persisting canonical owner data (`height_cm`, `current_weight_kg`, `date_of_birth: DATE`) to Supabase Postgres
- [x] User profile basics & Account deletion RPC (`delete_user_account`)
- [ ] Routine Library and Program browse/select flow in `apps/features/workout`; start an active workout only from the selected Routine or Program session
- [ ] Add nested Exercise Search backed first by a validated, versioned local JSON catalog in `apps/features/workout`
- [ ] Add Workout history views backed by recorded data: muscle heatmap, accessible training radar map, and training calendar
- [ ] Nutrition diary MVP
- [ ] Progress overview MVP
- [ ] Decide Recovery's first user outcome, data source, privacy/sync boundary, and non-medical scope before creating `apps/features/recovery`
- [ ] Coach placeholder with clear backend boundary

Feature implementation should happen inside owning packages:

```text
apps/features/auth
apps/features/onboarding
apps/features/workout
apps/features/nutrition
apps/features/profile
apps/features/settings
apps/features/progress
apps/features/coaching
```

See [Onboarding Flow Architecture](ONBOARDING_ARCHITECTURE.md) and the
[mode-conditional onboarding task](../.ai/tasks/onboarding-flow.md) before starting
that slice.

## Phase 4: Supabase Data, Storage, Offline, And Sync

Goal: move real app data behind repositories and make core flows offline-first.

- [x] Create the root `supabase/` migrations for user accounts, profile biometrics, and onboarding drafts
- [x] Add canonical Supabase Auth/Postgres/RLS contracts (`height_cm`, `current_weight_kg`, `target_weight_kg`, `date_of_birth: DATE`)
- [x] Define private module Storage bucket policy (`avatars`) with owner-scoped RLS
- [ ] Define repository contracts for workout, nutrition, profile, progress, and coaching
- [ ] Add Riverpod repository providers in owning feature packages
- [ ] Add `freezed` + `json_serializable` models/DTOs where generated value types are needed
- [ ] Choose local persistence for the first real data slice: Drift, Isar, or similar
- [ ] Implement local data source behind repository interfaces
- [ ] Add pending sync queue for workout events
- [ ] Add Meal Plan after the nutrition diary MVP: create, schedule, and reuse plans in `apps/features/nutrition` for nutrition and hybrid modes
- [ ] Add last successful sync metadata
- [ ] Add Supabase remote data source only behind repositories
- [ ] Add conflict handling rules for idempotent events

Recovery contracts, health permissions, wearable data, or sync are intentionally excluded until the Phase 3 Recovery decision is approved. Gemini, service-role operations, and custom backend code are also excluded from this phase.

Do not let database rows, remote DTOs, or backend table shapes leak into widgets.

## Phase 5: Wear OS MVP

Goal: extend the existing Flutter Wear OS companion with workout controls and nutrition quick actions.

- [x] Retain the existing `apps/wear` Flutter package
- [ ] Add workout start screen
- [ ] Add active workout screen
- [ ] Add set input screen
- [ ] Add rest timer screen
- [ ] Add basic heart rate display if available
- [ ] Add nutrition quick actions: food or meal add, water add, and today's nutrition summary
- [ ] Show next planned meal status only after Meal Plan is available on phone; do not add full Meal Plan editing to watch
- [ ] Add phone/backend sync placeholder
- [ ] Test on emulator and physical watch

Keep Wear OS Flutter UI watch-first, lightweight, and independent from phone screens. Reuse shared contracts and lightweight design primitives where useful; do not copy phone screens onto the watch.

## Phase 6: Protected Backend Upgrade

Goal: add a separate protected backend only when Supabase functions and repository boundaries no longer cover the approved product need.

- [ ] Define upgrade criteria and API contracts
- [ ] Add backend workspace
- [ ] Add authenticated/authorized integration boundary using Supabase identity
- [ ] Add Gemini/provider adapter only for an approved AI use case
- [ ] Add repository implementations backed by protected APIs only where needed
- [ ] Keep phone app pointed at repositories rather than raw backend endpoints
- [ ] Keep private keys and privileged database mutations out of client apps

## Phase 7: AI Coach Foundation

Goal: introduce server-side Gemini coaching after data and workout flows are stable.

- [ ] Add protected backend service in `backend/ai-coach`
- [ ] Keep prompt templates, Gemini credentials, and tool definitions server-side
- [ ] Add client contract in `apps/features/coaching`
- [ ] Stream coaching responses into Flutter UI
- [ ] Add workout recommendation use case
- [ ] Add nutrition adjustment use case
- [ ] Add safety and guardrail validations before returning recommendations
- [ ] Add prompt regression tests against standard persona scenarios

Coach is an additive intelligence layer over user-recorded and user-planned data. It is not an alternative storage path, offline fallback, or authentication provider.
