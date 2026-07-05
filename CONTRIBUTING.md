# Contributing to tio-world

Welcome to **tio-world**. This repo is the TNYX / Tio product workspace for a Flutter-first health, fitness, workout, nutrition, progress, coaching, and watch-connected experience.

We care about clean architecture, clear module ownership, predictable reviews, privacy-safe engineering, and a contributor experience that feels calm and practical.

This guide explains how to set up the workspace, choose the right module, create branches, open pull requests, and keep code aligned with the project direction.

---

## Project Overview

tio-world is organized as a product monorepo:

```text
tio-world/
├── apps/
│   ├── mobile/      # Flutter Android + iOS phone app
│   ├── wear-os/     # Native Wear OS app: Kotlin + Compose for Wear OS
│   └── watchos/     # Native Apple Watch app: Swift + SwiftUI
│
├── packages/
│   ├── api_client/
│   ├── core_models/
│   ├── design_system/
│   ├── workout_engine/
│   ├── nutrition_engine/
│   └── sync_core/
│
├── backend/
│   ├── api/
│   ├── ai-coach/
│   ├── jobs/
│   └── db/
│
├── docs/
├── tools/
├── melos.yaml
├── pubspec.yaml
├── package.json
├── pnpm-workspace.yaml
├── turbo.json
└── README.md
```

### Product areas

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

---

## Development Setup

### Prerequisites

Install the tools needed for the parts you are working on.

#### Mobile Flutter app

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

#### Native watch apps

For Wear OS:

- Android Studio
- JDK 21
- Android SDK and Wear OS emulator/device
- Kotlin + Compose for Wear OS support

For Apple Watch:

- macOS
- Xcode
- watchOS simulator or Apple Watch device

---

## First-time Setup

From the repository root:

```bash
git clone https://github.com/im-tnyx/tio-world.git
cd tio-world
```

Install Flutter dependencies:

```bash
flutter pub get
```

If Melos is configured:

```bash
dart pub global activate melos
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

---

## Running the Apps

### Flutter mobile app

```bash
cd apps/mobile
flutter run
```

Run on a specific device:

```bash
flutter devices
flutter run -d <device-id>
```

### Wear OS app

Open the native project in Android Studio and run the Wear OS configuration:

```text
apps/wear-os
```

Recommended watch direction:

```text
Wear OS UI: Kotlin + Compose for Wear OS
Watch logic/API contracts: keep lightweight and shared where practical
Heavy AI/analytics: backend
```

### Apple Watch app

Open the Xcode project:

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

---

## Common Commands

From the repository root:

```bash
flutter analyze
flutter test
dart format .
```

With Melos:

```bash
melos bootstrap
melos analyze
melos test
melos format
```

For mobile only:

```bash
cd apps/mobile
flutter analyze
flutter test
flutter build apk --debug
```

For Android release builds, prefer app bundles where applicable:

```bash
flutter build appbundle
```

For iOS release work, use Xcode and CI signing configuration. Do not commit signing secrets.

---

## Documentation First

Before changing architecture, module ownership, routing, persistence, sync, watch behavior, security, or testing strategy, update or read the relevant docs.

Recommended docs:

| Area | Read first |
| :--- | :--- |
| Architecture | `docs/ARCHITECTURE.md` |
| Mobile app | `apps/mobile/README.md` |
| Watch strategy | `docs/WATCH_STRATEGY.md` |
| API/backend | `docs/API.md` |
| Security | `docs/SECURITY.md` |
| Testing | `docs/TESTING.md` |
| Release | `docs/RELEASE.md` |
| ADRs | `docs/adr/README.md` |

Rule simple hai: architecture behavior badalta hai to docs bhi update honge.

---

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
docs/watch-strategy
refactor/workout-engine-package
test/nutrition-calorie-calculator
```

Branch rules:

- One branch should solve one meaningful problem.
- Avoid mixing unrelated docs, refactors, and feature work.
- Keep PRs reviewable. Chhota PR fast review hota hai.
- Do not commit generated outputs, local IDE files, `.env`, APK/AAB artifacts, `.ipa`, archives, keystores, provisioning profiles, or private keys.

---

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

Review expectations:

- Respond respectfully.
- Prefer small follow-up commits during review.
- Explain architecture decisions using module ownership and docs.
- If you disagree, explain tradeoffs calmly.

---

## Commit Message Style

Use clear, direct commits:

```text
docs: align contributing guide with flutter monorepo
fix: keep workout timer state after app resume
feature: add nutrition meal editor
refactor: move workout calculations into package
test: cover nutrition macro calculator
chore: configure melos workspace
```

Avoid vague commits:

```text
update
final changes
bug fix
misc
new
```

---

## Architecture Boundaries

### Flutter mobile app

The Flutter app should follow feature-first Clean Architecture:

```text
apps/mobile/lib/
├── app/
├── core/
├── shared/
└── features/
    ├── auth/
    ├── onboarding/
    ├── dashboard/
    ├── workout/
    ├── nutrition/
    ├── coaching/
    ├── progress/
    ├── profile/
    └── settings/
```

Feature structure:

```text
features/<feature>/
├── data/
│   ├── datasources/
│   ├── dto/
│   ├── mappers/
│   └── repositories/
│
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
│
└── presentation/
    ├── pages/
    ├── widgets/
    ├── controllers/
    └── state/
```

### Reusable packages

Move reusable logic into packages when it is useful beyond one feature:

- `packages/core_models`
- `packages/api_client`
- `packages/design_system`
- `packages/workout_engine`
- `packages/nutrition_engine`
- `packages/sync_core`

Do not make packages too early for one-screen-only code. Extract when reuse or boundary clarity is real.

### Watch apps

Do not force Flutter UI onto watch apps for production fitness flows.

Recommended approach:

```text
Phone app: Flutter
Wear OS app: Kotlin + Compose for Wear OS
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

---

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

---

## State and Presentation Pattern

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

---

## API, Data, and Supabase Strategy

Temporary hardcoded data is allowed only as UI scaffolding.

Target direction:

1. Define domain entity and repository contract.
2. Keep DTO mapping separate from UI.
3. Add backend/Supabase implementation behind repository boundaries.
4. Keep screens rendering state, not table structures.
5. Add validation, RLS, seed data, and migration notes when persistence becomes real.
6. Keep server-only keys on the server.

Never put service-role keys, admin keys, private API keys, or production secrets in Flutter, Wear OS, Apple Watch, public web code, screenshots, logs, or committed docs.

---

## Testing Guidelines

Testing depth should match risk:

- **Docs-only:** No code tests required. Mention `docs-only` in PR.
- **UI-only:** Run analyze, manually verify screens, add screenshots.
- **Controller/domain logic:** Add focused unit tests for state transitions and error paths.
- **Repository/API work:** Add contract-level tests or mocked data-source tests.
- **Sync/watch work:** Test offline, reconnect, duplicate event, and failure cases.
- **Security-sensitive work:** Confirm no secrets are logged, stored insecurely, or committed.

Recommended checks:

```bash
flutter analyze
flutter test
dart format .
```

With Melos:

```bash
melos analyze
melos test
melos format
```

---

## Security Guidelines

Never commit:

- `.env` files
- keystores
- provisioning profiles
- private signing keys
- Supabase service-role keys
- Firebase private credentials
- production secrets
- generated APKs, AABs, IPAs, archives, or app bundles
- user health data exports
- screenshots/logs containing tokens, emails, phone numbers, or private health data

Mobile clients may use publishable/anon keys only when the architecture requires it. Server-only keys stay server-only.

Health and fitness data should be treated as sensitive user data. Keep logs minimal and avoid storing more than the product needs.

---

## Accessibility and UX Standards

tio-world is a health product, so UX should feel calm, reliable, and respectful.

- Keep touch targets usable.
- Provide meaningful labels for icons and controls.
- Do not rely only on color to communicate state.
- Respect reduced motion options.
- Keep screens scannable.
- Avoid stressful copy around body, weight, nutrition, or progress.
- Watch flows should be glanceable and low-friction.

---

## Definition of Done

A change is done when:

1. It solves the stated problem.
2. It compiles or analyzes without errors.
3. Tests were added or consciously scoped out.
4. Module ownership is correct.
5. UI is separated from business logic.
6. Routing remains typed and maintainable.
7. Design-system tokens are used for production UI.
8. Docs are updated if architecture or behavior changed.
9. No secrets, generated outputs, local files, or signing assets are committed.
10. PR description explains the change clearly.

---

## Getting Help

If you are unsure where a change belongs:

1. Check `README.md`.
2. Check `docs/ARCHITECTURE.md`.
3. Check the nearest feature implementation.
4. Ask in the PR with the options you considered.

Good contribution is not just code likhna. Sahi boundary ke saath code likhna is the real quality bar.

Thank you for contributing to tio-world.
