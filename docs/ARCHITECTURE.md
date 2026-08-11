# Architecture

`tio-world` is a Flutter-first product monorepo with a Flutter Wear OS companion, a future native Apple Watch app, and a planned server-side backend workspace.

## Core Promise

Move fast on product, but keep boundaries clean.

- `apps/app` owns the Flutter Android and iOS phone app shell.
- `apps/wear` owns the Flutter Wear OS companion app.
- `apps/shared` owns pure Dart shared models, entities, repository contracts, use cases, results, errors, and utilities.
- `apps/core` owns Flutter design system, route contracts, shell components, reusable UI, tokens, constants, and extensions.
- `apps/features/*` owns feature packages such as workout, nutrition, onboarding, auth, profile, settings, progress, coaching, and future recovery.
- future `supabase/*` will own Supabase Auth, Postgres/RLS, Storage, migrations, seed data, and approved server functions for the first data slices.
- future `backend/*` will own Gemini/AI coach orchestration, advanced integrations, and long-running server work when the Supabase-first foundation needs an upgrade.
- `docs/` owns architecture and implementation direction.
- `.ai/` owns short AI orientation files.

## Current Target Shape

```text
tio-world/
├─ apps/
│  ├─ app/                         # Flutter Android + iOS phone app shell
│  ├─ wear/                        # Flutter Wear OS companion app
│  ├─ watchos/                     # Future native Swift + SwiftUI Apple Watch app
│  ├─ shared/                      # Pure Dart shared models/contracts/use cases
│  ├─ core/                        # Flutter design system, shell, routing contracts
│  └─ features/
│     ├─ auth/
│     ├─ onboarding/
│     ├─ workout/
│     ├─ nutrition/
│     ├─ profile/
│     ├─ settings/
│     ├─ progress/
│     └─ coaching/
├─ supabase/                      # Future Auth, Postgres/RLS, Storage, migrations
├─ backend/                       # Future protected-service upgrade
│  ├─ api/
│  ├─ ai-coach/
│  └─ jobs/
├─ docs/
├─ .github/
└─ .ai/
```

Some folders may be created later. Do not create empty future modules unless a real feature slice needs them.

## Platform Strategy

| Platform | Stack | Note |
| :--- | :--- | :--- |
| Android phone | Flutter | Shared mobile UI. |
| iPhone | Flutter | Shared mobile UI. |
| Wear OS | Flutter | Existing Flutter Wear OS companion package with watch-first UI and shared contracts where useful. |
| Apple Watch | Swift + SwiftUI | Native watchOS experience when introduced. |
| Auth, data, and media | Supabase | Planned Auth, Postgres/RLS, private Storage, migrations, and approved server functions. |
| Protected backend upgrade | Server-side workspace | Future Gemini/AI coach orchestration, advanced integrations, and long-running jobs. |

## Native-Style To Flutter Module Mapping

The Flutter workspace mirrors the native modular structure used in `Tio-hub`.

| Native-style module | Flutter workspace path | Responsibility |
| :--- | :--- | :--- |
| `:app` | `apps/app` | Flutter Android + iOS phone app shell, bootstrap, route composition, provider wiring. |
| `:wear` | `apps/wear` | Flutter Wear OS companion app. |
| `:shared` | `apps/shared` | Pure Dart models, repository contracts, use cases, results, errors, and shared utilities. |
| `:core` | `apps/core` | Design system, tokens, shared widgets, shell, route contracts, constants, extensions. |
| `:features:workout` | `apps/features/workout` | Workout feature package and all workout screens/flows. |
| `:features:nutrition` | `apps/features/nutrition` | Nutrition feature package and all nutrition screens/flows. |
| `:features:onboarding` | `apps/features/onboarding` | Onboarding feature package and all onboarding screens/flows. |
| `:features:auth` | `apps/features/auth` | Auth feature package and session entry flows. |
| `:features:profile` | `apps/features/profile` | Profile launcher, account, and fitness hub package. |
| `:features:settings` | `apps/features/settings` | App settings and account controls package. |
| `:features:progress` | `apps/features/progress` | Progress, measurements, photos, streaks, and analytics package. |
| `:features:coaching` | `apps/features/coaching` | Coaching UI package and backend-facing coaching contracts. |
| `:features:recovery` | future `apps/features/recovery` | Recovery, readiness, and rest context after its first approved vertical slice. |
| `supabase/` | future root `supabase/` | Auth, Postgres migrations, RLS, private Storage buckets, seed data, and approved functions. |
| `backend/` | future root `backend/` | Protected Gemini/AI orchestration, advanced APIs/integrations, and long-running jobs after the upgrade gate. |

## Flutter Feature Package Pattern

Each large product feature should be a complete Flutter/Dart package under `apps/features/<feature>`.

This keeps features manageable when workout, nutrition, onboarding, progress, coaching, or recovery grow to 20+ screens.

```text
apps/features/<feature>/
├─ lib/
│  ├─ <feature>.dart
│  └─ src/
│     ├─ domain/
│     │  ├─ entities/
│     │  ├─ repositories/
│     │  └─ usecases/
│     ├─ data/
│     │  ├─ datasources/
│     │  ├─ dto/
│     │  ├─ mappers/
│     │  └─ repositories/
│     └─ presentation/
│        ├─ routes/
│        ├─ navigation/
│        ├─ controllers/
│        ├─ state/
│        ├─ pages/
│        └─ widgets/
├─ test/
└─ pubspec.yaml
```

## Dependency Direction

Use one-way dependencies.

```text
apps/app
  ↓
apps/features/*
  ↓
apps/core + apps/shared
```

Rules:

- `apps/app` wires app bootstrap, route composition, providers, and platform entry configuration.
- `apps/app` should not own feature business logic.
- Feature packages can depend on `apps/core` and `apps/shared`.
- `apps/core` must not import feature packages.
- `apps/shared` must stay pure Dart and must not import Flutter UI.
- Feature presentation layers must not import another feature's presentation layer.
- Cross-feature reads should go through stable contracts, repositories, or use cases.
- Backend API/table shapes must not leak directly into widgets or screens.
- Supabase is the planned first Auth/data/Storage platform. A separate backend is a future protected-service upgrade, not the owner of initial database migrations.

## App Mode, Navigation Layout, And Surface Composition

`AppMode` is the implemented product contract for selecting the phone app experience:

```dart
enum AppMode { workout, nutrition, hybrid }
```

The enum, guided destination mapping, and preference boundary live in `apps/shared`. They are pure Dart and can therefore be read by every Flutter feature package without violating ownership boundaries or duplicating mode rules.

Onboarding now begins with App Mode selection, and Settings changes the same selection later. The common-profile, Workout, Nutrition, review, and finish steps remain planned and must be shown conditionally for the chosen mode when implemented. App Mode remains a product-scope contract; it is not replaced by future tab personalization.

The first App Mode slice persists the confirmed selection on the device. The pure-Dart preference contract belongs in `apps/shared`, while a `SharedPreferencesAsync` adapter is wired at the `apps/app` composition boundary and loaded before router composition. Missing or invalid values return to mode selection. Account-backed sync is deferred until an approved Supabase profile contract exists; this slice does not add a Supabase schema, bucket, backend endpoint, or cross-device merge behavior.

The app shell uses `go_router` `StatefulShellRoute.indexedStack`. It keeps stable registered branches for route/state preservation, while the visible guided layout and route eligibility are derived from the active mode:

| App mode | Guided default tabs |
| :--- | :--- |
| `workout` | Home, Workout, Progress |
| `nutrition` | Home, Nutrition, Progress |
| `hybrid` | Home, Workout, Nutrition, Progress |

After the core product screens are stable, a separate Navigation & Tabs setting may let the user choose three to six eligible destinations. Home remains required and first. Eligibility is the intersection of App Mode, implemented feature availability, and release-stage policy. The exact compact-phone presentation for six selections requires responsive and accessibility validation; an overflow/More treatment may represent part of the selected layout without changing the saved preference.

Navigation destinations are not synonymous with screens. Root destinations such as Home, Workout, Nutrition, Progress, future You, Coach, and future Social own primary navigation surfaces. Workout Library and Meal Plan remain canonical feature routes; a future custom layout may promote either as a shortcut after the owning feature exists. Promotion changes entry placement, not module ownership, data rules, or workflow implementation.

Home and other feature surfaces use prepared composition inputs rather than raw tab-index checks:

```text
AppMode + NavigationLayout + FeatureAvailability + UserDataState
  -> SurfaceComposition
  -> visible sections, section prominence, and action entry placement
```

Feature actions have one canonical command/workflow and may appear through multiple entry points. For example, Workout owns start/resume behavior and Nutrition owns meal logging; Home or a promoted shortcut only launches those owned actions with approved context. An active workout must remain resumable even when the Workout destination is not directly visible.

Profile and Settings are launch surfaces, not primary bottom tabs.

```text
Profile  -> avatar/account entry
Settings -> gear/menu entry
```

The implemented App Mode foundation delivers guided defaults only. Future personalization and adaptive action placement are tracked separately in [ADR-0005](adr/0005-adaptive-navigation-and-action-entry.md) and the [adaptive navigation task](../.ai/tasks/adaptive-navigation-and-actions.md).

## Feature Boundaries For Profile-Derived Defaults

Profile is the source of approved personal and fitness context. Nutrition owns Nutrition Targets—including calculation, explicit overrides, and validation—and Workout owns Workout Settings, Routines, Programs, muscle heatmap, radar map, calendar, and training behavior. A profile value may seed a feature default through a stable pure-Dart contract, but it must never silently replace a user-confirmed feature override.

Recovery is a future independent `apps/features/recovery` feature. It is not an App Mode tab and must not be created until its first data source, privacy/sync model, and non-medical user outcome are approved. Home, Workout, Progress, and Coach may consume a prepared Recovery summary through a contract; they must not calculate it themselves.

See the [screen catalog](screens/README.md) for per-screen content, actions, states, and acceptance criteria.

## Supabase And Future Backend Boundary

The first authenticated data slices use Supabase Auth, Postgres with explicit RLS, and private module Storage. The future `supabase/` workspace owns migrations and policies. Gemini and any privileged provider integration remain outside mobile/watch clients and are introduced only through an approved protected function or future backend upgrade. The exact custom-backend framework is intentionally undecided.

See [Supabase-first platform strategy](SUPABASE_STRATEGY.md) for the module bucket and security contract.

## Architecture Decision Records

Durable platform, navigation, data-boundary, and design-system choices are recorded in [Architecture Decision Records](adr/README.md). ADRs explain the decision and trade-offs; this document remains the canonical repository shape and ownership reference.

## Reusable Profile Avatar

`apps/core` will own one reusable `TioAvatar` component for shell, list, card, and Profile use. Its API will use four semantic sizes—`compact`, `small`, `medium`, and `large`—and a standard shape option: circular by default with a rounded profile treatment where the owning screen requires it. Screens select a semantic size and shape instead of defining avatar dimensions or clipping locally.

## Material 3 Expressive Direction

The phone design system adopts Material 3 Expressive as its product direction. `apps/core` owns the implementation through semantic color, typography, shape, spacing, motion, and accessibility tokens plus reusable components. Flutter's baseline Material 3 is already enabled; do not assume a separate Flutter Material 3 Expressive API is stable or available.

Apply the direction incrementally: migrate shared phone components such as navigation and buttons only when their interaction, accessibility, and dark-mode states are verified. Preserve visible touch feedback, honor reduced-motion and high-contrast preferences, and avoid hardcoded expressive values in feature packages. Wear OS remains watch-first and compact; it may share tokens where useful but must not inherit phone-sized layouts or motion.

## Recommended Flutter Stack

```text
State: Riverpod
Navigation: go_router with typed routes
Data: offline-first repository pattern
Local persistence: Drift, Isar, or similar after the first real data slice is chosen
Code generation: freezed + json_serializable
HTTP/API: dio when remote APIs are introduced
Workspace: melos
```

Use feature-owned routes and navigation registration. Keep app-level routing composition in `apps/app`, and keep feature internals inside the owning feature package.

Local persistence should stay behind repository implementations so the database choice can evolve before production hardening.

## Watch Rules

Watch apps should stay small and fast.

Good watch responsibilities:

- workout start, pause, resume, finish
- active set input
- rest timer
- heart rate display
- steps and calories summary
- offline active workout snapshot
- food and water quick add
- today's nutrition summary
- next planned meal status after Meal Plan is available on phone
- quick sync
- tiles and complications where useful

Avoid putting heavy phone home surfaces, long forms, full AI chat, large analytics flows, or image-heavy UI on watches.

## Naming Rules

The Flutter phone app folder is:

```text
apps/app
```

The Wear OS folder is:

```text
apps/wear
```
