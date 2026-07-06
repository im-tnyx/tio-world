# Roadmap

This roadmap is practical and intentionally staged. Do not build future areas before the current slice needs them.

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

- [ ] Create root `pubspec.yaml`
- [ ] Create root `melos.yaml`
- [ ] Create `apps/app` Flutter phone app shell
- [ ] Create `apps/shared` pure Dart package
- [ ] Create `apps/core` Flutter package for design system, shell, and route contracts
- [ ] Create initial feature packages only when needed:
  - [ ] `apps/features/auth`
  - [ ] `apps/features/onboarding`
  - [ ] `apps/features/workout`
  - [ ] `apps/features/nutrition`
  - [ ] `apps/features/profile`
  - [ ] `apps/features/settings`
  - [ ] `apps/features/progress`
  - [ ] `apps/features/coaching`
- [ ] Add analyzer and test setup
- [ ] Add Melos validation commands

## Phase 2: Flutter Mobile App Shell

Goal: create the first usable Android+iOS phone shell.

- [ ] Add app bootstrap
- [ ] Add routing with `go_router`
- [ ] Add state management with Riverpod
- [ ] Add base theme and design tokens in `apps/core`
- [ ] Add app shell and primary tabs
- [ ] Add placeholder feature routes through feature package contracts
- [ ] Keep `apps/app` thin and free of feature business logic

Primary tabs:

```text
Dashboard
Workout
Nutrition
Coach
Progress
```

Profile should launch from avatar or account entry, not as a main bottom tab.

Settings should launch from gear/menu entry, not as a main bottom tab.

## Phase 3: Core Product MVP

Goal: first usable health and fitness app flow.

- [ ] Auth placeholder or real auth provider decision
- [ ] Onboarding basics
- [ ] User profile basics
- [ ] Workout logging MVP
- [ ] Nutrition diary MVP
- [ ] Progress overview MVP
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

## Phase 4: Wear OS MVP

Goal: native watch companion for workout flow.

- [ ] Generate `apps/wear` native Wear OS app
- [ ] Add workout start screen
- [ ] Add active workout screen
- [ ] Add set input screen
- [ ] Add rest timer screen
- [ ] Add basic heart rate display if available
- [ ] Add phone/backend sync placeholder
- [ ] Test on emulator and physical watch

Watch app should stay native. Do not force Flutter UI onto Wear OS production fitness flows.

## Phase 5: Backend And Persistence

Goal: move real data behind repositories and backend APIs.

- [ ] Define API contracts
- [ ] Add backend workspace
- [ ] Add database schema incrementally
- [ ] Add repository implementations
- [ ] Add auth-aware data access
- [ ] Add seed/demo data
- [ ] Add test path for critical flows

Backend folders:

```text
backend/api
backend/ai-coach
backend/jobs
backend/db
```

## Phase 6: AI Coach

Goal: add useful coaching without bloating mobile/watch clients.

- [ ] Define coaching input model
- [ ] Define coaching response model
- [ ] Add backend AI coach runtime
- [ ] Add safety and confidence boundaries
- [ ] Add mobile coach UI in `apps/features/coaching`
- [ ] Keep watch coaching limited to short insights only

## Phase 7: Apple Watch

Goal: add watchOS only after Wear OS and mobile MVP are stable.

- [ ] Create `apps/watchos`
- [ ] Add SwiftUI watch app shell
- [ ] Add workout quick actions
- [ ] Add HealthKit integration plan
- [ ] Add phone sync via WatchConnectivity

## Not Now

Do not build these until core slices are working:

- community
- challenges
- rewards
- full social feed
- complex analytics
- full AI chat on watch
- advanced subscription system
- multiple wearable vendor integrations

## Roadmap Rule

Each phase should produce a working, testable slice before the next phase grows.
