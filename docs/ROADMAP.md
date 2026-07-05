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

## Phase 1: Flutter Mobile Foundation

Goal: create the phone app shell.

- [ ] Create `apps/mobile` Flutter app
- [ ] Add app bootstrap
- [ ] Add routing with `go_router`
- [ ] Add state management with Riverpod
- [ ] Add base theme and design tokens
- [ ] Add app shell and primary tabs
- [ ] Add placeholder feature routes
- [ ] Add analyzer and test setup

Primary tabs:

```text
Dashboard
Workout
Nutrition
Coach
Progress
```

Profile should launch from avatar or account entry, not as a main bottom tab.

## Phase 2: Core Product MVP

Goal: first usable health and fitness app flow.

- [ ] Auth placeholder or real auth provider decision
- [ ] Onboarding basics
- [ ] User profile basics
- [ ] Workout logging MVP
- [ ] Nutrition diary MVP
- [ ] Progress overview MVP
- [ ] Coach placeholder with clear backend boundary

## Phase 3: Wear OS MVP

Goal: native watch companion for workout flow.

- [ ] Generate `apps/wear` native Wear OS app
- [ ] Add workout start screen
- [ ] Add active workout screen
- [ ] Add set input screen
- [ ] Add rest timer screen
- [ ] Add basic heart rate display if available
- [ ] Add phone/backend sync placeholder
- [ ] Test on emulator and physical watch

## Phase 4: Backend And Persistence

Goal: move real data behind repositories and backend APIs.

- [ ] Define API contracts
- [ ] Add backend workspace
- [ ] Add database schema incrementally
- [ ] Add repository implementations
- [ ] Add auth-aware data access
- [ ] Add seed/demo data
- [ ] Add test path for critical flows

## Phase 5: AI Coach

Goal: add useful coaching without bloating mobile/watch clients.

- [ ] Define coaching input model
- [ ] Define coaching response model
- [ ] Add backend AI coach runtime
- [ ] Add safety and confidence boundaries
- [ ] Add mobile coach UI
- [ ] Keep watch coaching limited to short insights only

## Phase 6: Apple Watch

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
