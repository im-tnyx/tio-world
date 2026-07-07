# Contributing to tio-world

Welcome to **tio-world**. This repo is the TNYX / Tio product workspace for a Flutter-first health, fitness, workout, nutrition, progress, coaching, and watch-connected experience.

We care about clean architecture, clear module ownership, predictable reviews, privacy-safe engineering, and a contributor experience that feels calm and practical.

This guide explains how to set up the workspace, choose the right module, create branches, open pull requests, and keep code aligned with the project direction.

## Project Overview

`tio-world` is organized as an apps-based modular product monorepo:

```text
tio-world/
├─ apps/
│  ├─ app/          # Flutter Android + iOS phone app shell
│  ├─ wear/         # Native Wear OS app
│  ├─ shared/       # Pure Dart shared models/contracts/use cases
│  ├─ core/         # Flutter design system, shell, route contracts
│  └─ features/     # Feature packages
│     ├─ auth/
│     ├─ onboarding/
│     ├─ workout/
│     ├─ nutrition/
│     ├─ profile/
│     ├─ settings/
│     ├─ progress/
│     └─ coaching/
├─ backend/
│  ├─ api/
│  ├─ ai-coach/
│  ├─ jobs/
│  └─ db/
├─ docs/
├─ tools/
├─ melos.yaml
├─ pubspec.yaml
├─ package.json
├─ pnpm-workspace.yaml
└─ README.md
```

Create missing paths only when a real implementation slice needs them.

## Product Areas

- `auth`
- `onboarding`
- `dashboard`
- `workout`
- `nutrition`
- `coaching`
- `progress`
- `profile`
- `settings`
- `watch-sync`

Agar doubt ho ki code kahan jaana chahiye, first read the nearby feature pattern, then update docs if a boundary changes.

## Development Setup

### Required tools

Install the tools needed for the parts you are working on.

#### Flutter mobile app

- Flutter SDK, stable channel
- Dart SDK bundled with Flutter
- Android Studio or VS Code
- Android SDK and platform tools
- Xcode on macOS for iOS work
- Git

#### Monorepo tooling

- Melos for Dart/Flutter package management
- Node.js LTS if backend or repo scripts are used
- pnpm if backend/workspace scripts are used

#### Smartwatch apps

For Wear OS:
- Standard Flutter toolchain setup (Wear OS is a Flutter package under `apps/wear`)

For Apple Watch:

- macOS
- Xcode
- watchOS simulator or Apple Watch device

## First-Time Setup

From the repository root:

```bash
git clone https://github.com/im-tnyx/tio-world.git
cd tio-world
```

After Flutter workspace files are configured:

```bash
dart pub global activate melos
flutter pub get
melos bootstrap
```

If backend/workspace packages are used:

```bash
pnpm install
```

Create a local environment file only when a feature needs runtime configuration:

```bash
cp .env.example .env
```

Never commit `.env`, secrets, keystores, API private keys, service-role keys, production tokens, or signing files.

## Running The Apps

### Flutter phone app

```bash
cd apps/app
flutter run
```

Run on a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

### Feature package checks

```bash
cd apps/features/workout
dart analyze
dart test
```

With Melos from repo root:

```bash
melos analyze
melos test
```

### Wear OS app

Wear OS is a standalone Flutter application located at:

```text
apps/wear
```

To run the Wear OS app:
```bash
cd apps/wear
flutter run
```

Recommended watch direction:

```text
Wear OS UI: Flutter (tio_wear)
Watch logic/API contracts: shared where practical via tio_shared & tio_core
Heavy AI/analytics: backend
```

### Apple Watch app

When introduced, open the Xcode project:

```text
apps/watchos
```

Recommended watch direction:

```text
Apple Watch UI: Swift + SwiftUI
Health data: HealthKit
Phone bridge: WatchConnectivity
Heavy AI/analytics: backend
```

## Common Commands

From the repository root after Melos is configured:

```bash
melos bootstrap
melos analyze
melos test
melos format
```

For mobile app only:

```bash
cd apps/app
flutter analyze
flutter test
flutter build apk --debug
```

For Android release builds, prefer app bundles where applicable:

```bash
flutter build appbundle
```

For iOS release work, use Xcode and CI signing configuration. Do not commit signing secrets.

## Documentation First

Before changing architecture, module ownership, routing, persistence, sync, watch behavior, security, or testing strategy, update or read the relevant docs.

Recommended docs:

| Area | Read first |
| :--- | :--- |
| Architecture | `docs/ARCHITECTURE.md` |
| Flutter modular structure | `docs/FLUTTER_MODULAR_STRUCTURE.md` |
| Module ownership | `docs/MODULE_OWNERSHIP.md` |
| Mobile app | `apps/app/README.md` when introduced |
| Watch strategy | `docs/WATCH_STRATEGY.md` |
| API/backend | `docs/API.md` |
| Security | `docs/SECURITY.md` |
| Testing | `docs/TESTING_GUIDE.md` |
| Release | `docs/RELEASE.md` |
| ADRs | `docs/adr/README.md` |

Rule simple hai: architecture behavior badalta hai to docs bhi update honge.

## Branching Guidelines

Use focused branches:

```text
feature/<short-description>
fix/<short-description>
docs/<short-description>
refactor/<short-description>
test/<short-description>
chore/<short-description>
```

Examples:

```text
feature/workout-active-session
feature/nutrition-meal-editor
fix/mobile-router-auth-guard
docs/flutter-modular-structure
refactor/workout-feature-package
test/nutrition-calorie-calculator
```

Branch rules:

- One branch should solve one meaningful problem.
- Avoid mixing unrelated docs, refactors, and feature work.
- Keep PRs reviewable. Chhota PR fast review hota hai.
- Do not commit generated outputs, local IDE files, `.env`, APK/AAB artifacts, `.ipa`, archives, keystores, provisioning profiles, or private keys.

## Pull Request Process

Before opening a PR:

1. Sync with the target branch.
2. Run the most relevant checks.
3. Confirm module boundaries are respected.
4. Update docs if behavior or architecture changed.
5. Check that no secrets, local files, generated apps, or signing assets are committed.

Suggested PR template:

```markdown
## Summary
- What changed.

## Why
- Why this change is needed.

## Architecture Notes
- Module boundaries, routing, persistence, sync, watch, or backend notes.

## Tests
- [ ] `flutter analyze`
- [ ] `flutter test`
- [ ] `melos analyze` if applicable
- [ ] `melos test` if applicable
- [ ] Manual UI check completed

## Screenshots / Recordings
Add screenshots or videos for UI changes.

## Follow-ups
Known remaining work, if any.
```

## Architecture Boundaries

### Flutter phone app shell

`apps/app` should stay thin.

Allowed:

- app startup
- bootstrap
- provider composition
- route composition
- platform entry configuration
- global app shell wiring

Not allowed:

- workout calculations
- nutrition macro logic
- onboarding question logic
- profile repository logic
- progress analytics
- AI coaching orchestration
- direct database table shape dependencies

### Feature packages

Feature packages should follow:

```text
apps/features/<feature>/
├─ lib/
│  ├─ <feature>.dart
│  └─ src/
│     ├─ domain/
│     ├─ data/
│     └─ presentation/
├─ test/
└─ pubspec.yaml
```

### Shared package

`apps/shared` should stay pure Dart.

It can contain:

- entities
- models
- repository contracts
- use cases
- result/error types
- validation helpers
- sync payload contracts

It must not import Flutter UI or platform-specific client code.

### Core package

`apps/core` owns reusable Flutter UI and app-level presentation primitives.

It can contain:

- theme tokens
- common widgets
- shell components
- route contracts
- constants
- extensions

It must not import feature packages.

### Watch apps

Wear OS is built using Flutter (`apps/wear`) to share state, routing, and design system components. Apple Watch remains native (SwiftUI) for close iOS integration.

Recommended approach:

```text
Phone app: Flutter
Wear OS app: Flutter
Apple Watch app: Swift + SwiftUI
Shared data contracts: API + lightweight models
Heavy AI/analytics: backend
```

Watch screens should stay fast and small:

- start/pause/resume workout
- active set input
- rest timer
- heart rate
- steps
- quick sync status
- offline active workout fallback

Heavy charts, long history, AI chat, nutrition editor complexity, and large analytics belong on phone/backend, not watch.

## Flutter Standards

Recommended stack:

- State management: `Riverpod`
- Routing: `go_router`
- Networking: `dio`
- Models: `freezed` + `json_serializable`
- Local database: `drift` or `isar`, based on product need
- Secure storage: `flutter_secure_storage`
- Monorepo: `melos`
- Crash reporting: Firebase Crashlytics or Sentry

General rules:

- Prefer immutable state.
- Keep widgets small and readable.
- Keep business decisions out of widgets.
- Keep async and persistence inside repositories/services.
- Prefer typed routes and typed DTO/model boundaries.
- Do not let UI depend directly on backend table shape.
- Do not hardcode random colors, spacing, radius, typography, or shadows in production UI.
- Use design-system tokens and reusable components.

## State And Presentation Pattern

Use a predictable flow:

```text
Page/Widget -> Controller/Notifier -> UseCase -> Repository -> DataSource
```

Role clarity:

| Layer | Responsibility |
| :--- | :--- |
| `Page` | Compose screen layout and connect state/actions. |
| `Widget` | Small reusable UI pieces with explicit inputs and callbacks. |
| `Controller/Notifier` | Own UI state, handle user actions, call use cases. |
| `UseCase` | Business action or calculation boundary. |
| `Repository` | Abstract data source and persistence details. |
| `DataSource` | API, local DB, cache, or platform-specific implementation. |

Hard rule:

```text
Widget business logic nahi karega. Business decision controller/domain layer mein rahegi.
```

## Security

Temporary hardcoded data is allowed only as UI scaffolding.

Target direction:

1. Define domain entity and repository contract.
2. Keep DTO mapping separate from UI.
3. Add backend/Supabase implementation behind repository boundaries.
4. Keep screens rendering state, not table structures.
5. Add validation, RLS, seed data, and migration notes when persistence becomes real.
6. Keep server-only keys on the server.

Never put service-role keys, admin keys, private API keys, production secrets, signing files, real health data, screenshots containing personal information, or local machine paths into Flutter, Wear OS, Apple Watch, public web code, logs, or committed docs.
