# Architecture

`tio-world` is a Flutter-first product monorepo with a Flutter Wear OS companion, a future native Apple Watch app, an active Supabase Auth/data foundation, and a future protected TypeScript/Fastify server workspace.

This document is the canonical repository-shape and ownership reference. Runtime source/config remains the truth for what is actually implemented today.

## Core Promise

Move fast on product, but keep boundaries clean.

- `apps/app` owns the Flutter Android and iOS phone app shell.
- `apps/wear` owns the Flutter Wear OS companion app.
- `apps/shared` owns pure Dart shared models, entities, repository contracts, use cases, results, errors, and utilities.
- `apps/core` owns the Flutter design system, route contracts, shell components, reusable UI, tokens, constants, and extensions.
- `apps/features/*` owns product feature packages such as home, workout, nutrition, onboarding, auth, profile, settings, progress, and coaching.
- `supabase/` is active and owns Supabase project configuration, database migrations, RLS/policies, approved Edge Functions, and related platform assets.
- future `services/api/` is the canonical protected server application path when backend implementation is explicitly authorized.
- future `services/worker/` is reserved for real asynchronous/background processing needs and must not be scaffolded speculatively.
- `packages/` is reserved for reusable code only when a real extraction/reuse boundary exists.
- `docs/` owns canonical architecture and policy.
- `.ai/` is a short orientation layer, not an alternate architecture source.

## Current And Future Repository Shape

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
│     ├─ home/
│     ├─ workout/
│     ├─ nutrition/
│     ├─ profile/
│     ├─ settings/
│     ├─ progress/
│     └─ coaching/
├─ supabase/                       # ACTIVE Auth/data/Storage/functions/migrations owner
├─ services/                       # Future runnable protected server processes
│  ├─ api/                         # Future Node.js + TypeScript + Fastify modular monolith
│  └─ worker/                      # Future only when async workload needs it
├─ packages/                       # Future reusable TS/Dart code only when justified
├─ docs/                           # Canonical architecture/product/operations docs
├─ .github/
└─ .ai/
```

Important current-state rule:

- `supabase/` already exists and is active.
- `services/api/` is a locked future destination, not a statement that backend code has started.
- Do not create empty future folders merely to match the conceptual tree.

## Platform Strategy

| Platform | Stack | Status / note |
| :--- | :--- | :--- |
| Android phone | Flutter | Active product app surface. |
| iPhone | Flutter | Shared mobile UI. |
| Wear OS | Flutter | Existing watch-first companion package. |
| Apple Watch | Swift + SwiftUI | Future native watchOS app when approved. |
| Auth, data, migrations | Supabase | Active canonical foundation. |
| Protected API | Node.js + TypeScript + Fastify | Architecture locked; implementation deferred until explicitly authorized. |
| Async worker | TypeScript process under `services/worker` | Future only when a real durable async workload requires it. |

## Supabase Boundary

Supabase is the current canonical Auth/data platform.

Current direction:

```text
Flutter / Wear clients
        ↓
Supabase Auth
        ↓
Supabase Postgres + RLS
        ↓
approved Storage / Edge Function paths where required
```

Rules:

- Supabase Auth is the identity authority.
- `auth.users.id` is the canonical auth UUID.
- `public.users.id` is the matching app/domain root UUID.
- `supabase/migrations/` is the sole Tio database-schema/RLS migration owner.
- Client code uses only client-safe configuration.
- Privileged/service-role access is reserved for explicit trusted server workflows and must not be used to bypass RLS denial.
- Private/sensitive media follows the data/privacy and Storage ownership policies; bucket existence alone does not make a media model production-ready.

See:

- [Auth Architecture](AUTH_ARCHITECTURE.md)
- [Supabase Strategy](SUPABASE_STRATEGY.md)
- [Supabase Server Access](SUPABASE_SERVER_ACCESS.md)
- [Data & Privacy Governance](DATA_PRIVACY_GOVERNANCE.md)

## Future Protected Server Boundary

The first protected backend implementation, when explicitly authorized, belongs at:

```text
services/api/
```

The runtime/framework decision is already locked:

```text
Node.js
+ TypeScript
+ Fastify
+ modular monolith
```

The first scaffold must remain minimal. The canonical starting shape is:

```text
services/api/
├─ src/
│  ├─ app/
│  │  ├─ create-app.ts
│  │  ├─ register-plugins.ts        # add when needed
│  │  └─ register-routes.ts         # add when needed
│  ├─ config/
│  │  ├─ env.ts
│  │  └─ schema.ts
│  └─ server.ts
├─ test/
├─ package.json
├─ tsconfig.json
└─ README.md
```

As real modules appear, the locked internal ownership model is:

```text
services/api/src/
├─ app/              # Fastify composition only
├─ modules/          # business use cases + domain authorization
├─ infrastructure/   # auth, Supabase, providers, logging, telemetry, queue adapters
├─ shared/           # small cross-cutting primitives only
├─ config/
└─ server.ts         # process startup/shutdown only
```

Rules:

- `services/api` starts as one modular monolith, not microservices.
- Fastify-specific code stays at HTTP/composition boundaries.
- Domain/business rules must not depend directly on Fastify.
- `services/worker` is not created until a real queue/background use case exists.
- No Kafka, Kubernetes, service mesh, GraphQL federation, Redis, or extra service is introduced without a concrete requirement and evidence.
- Backend implementation remains deferred until separately authorized; architecture documentation does not grant permission to scaffold it.

See the accepted Linear B0 decisions for repository namespaces, Fastify baseline, and `services/api` internal ownership.

## Client ↔ Future API Auth Contract

The canonical future protected-service auth flow is:

```text
Supabase Auth
→ access token
→ Tio API (`services/api`)
→ verify Supabase token
→ derive verified user identity
→ authorize operation
```

Firebase Admin token verification is not part of the target backend auth architecture.

Historical Firebase-named classes, adapters, tests, or migration-era code may still exist in source. Their existence is not evidence that Firebase remains an approved auth provider or future backend target.

Use [Auth Architecture](AUTH_ARCHITECTURE.md) for the canonical identity contract.

## Future HTTP Adapter Preservation Rule

The repository contains some Remote*/HTTP/backend transport abstractions created before the current Supabase composition was finalized.

Do not delete a generic future HTTP/repository abstraction solely because it is inactive today. Removal should follow an explicit source audit so useful contract/mapper work is not accidentally lost.

However, this preservation rule does **not** protect stale provider-specific architecture:

- Firebase-specific Auth behavior is not canonical future architecture.
- A class name or historical implementation mentioning Firebase does not override `AUTH_ARCHITECTURE.md`.
- Provider-specific code may be retired, rewritten, or isolated when its owning cleanup task proves it is obsolete.
- Generic Remote*/HTTP adapters, if retained, must target the current future boundary: `services/api`, Supabase Auth tokens, and Tio-owned API contracts.

Conceptual future path:

```text
Flutter
→ feature-owned repository contract
→ approved Remote*/HTTP adapter
→ services/api
→ trusted server integrations / Supabase server access
```

## Flutter Module Mapping

| Conceptual module | Workspace path | Responsibility |
| :--- | :--- | :--- |
| `:app` | `apps/app` | Phone bootstrap, route composition, provider wiring. |
| `:wear` | `apps/wear` | Wear OS companion app. |
| `:shared` | `apps/shared` | Pure Dart models/contracts/use cases/utilities. |
| `:core` | `apps/core` | Design system, tokens, shell, route contracts, shared widgets. |
| `:features:home` | `apps/features/home` | Home presentation and Home-owned workflows. |
| `:features:workout` | `apps/features/workout` | Workout feature. |
| `:features:nutrition` | `apps/features/nutrition` | Nutrition feature. |
| `:features:onboarding` | `apps/features/onboarding` | Onboarding feature. |
| `:features:auth` | `apps/features/auth` | Auth/session entry flows. |
| `:features:profile` | `apps/features/profile` | Profile/account launcher and profile flows. |
| `:features:settings` | `apps/features/settings` | App/account settings. |
| `:features:progress` | `apps/features/progress` | Progress, measurements, photos, streaks, analytics UI. |
| `:features:coaching` | `apps/features/coaching` | Coaching UI and backend-facing coaching contracts. |
| future recovery | future `apps/features/recovery` | Create only with its first approved product/data/privacy slice. |

## Flutter Feature Package Pattern

Each large feature remains a complete Flutter/Dart package under `apps/features/<feature>`.

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

Dependency direction:

```text
apps/app
  ↓
apps/features/*
  ↓
apps/core + apps/shared
```

Rules:

- `apps/app` wires composition; it should not own feature business logic.
- `apps/core` must not import feature packages.
- `apps/shared` stays pure Dart and must not import Flutter UI.
- Feature presentation layers must not import another feature's presentation layer.
- Cross-feature reads/actions use stable contracts, repositories, or use cases.
- Supabase table shapes and future API payloads must not leak directly into widgets.

## App Mode And Navigation Ownership

`AppMode` is the implemented shared product contract:

```dart
enum AppMode { workout, nutrition, hybrid }
```

The pure-Dart contract belongs in `apps/shared`. Onboarding and Settings use the same underlying product-mode model.

The routed onboarding flow uses one `/onboarding` parent route with mode-derived child steps. Stable step IDs own progress/resume identity. See [Onboarding Architecture](ONBOARDING_ARCHITECTURE.md) and [ADR-0006](adr/0006-single-route-onboarding-parent-flow.md).

The phone shell uses `go_router` with a `StatefulShellRoute.indexedStack`; route registration stays at the app composition boundary while each feature owns its internal screens/actions.

Guided navigation defaults:

| App mode | Default root destinations |
| :--- | :--- |
| `workout` | Home, Workout, Progress |
| `nutrition` | Home, Nutrition, Progress |
| `hybrid` | Home, Workout, Nutrition, Progress |

Future navigation personalization must not change feature ownership. See [ADR-0005](adr/0005-adaptive-navigation-and-action-entry.md).

## Profile-Derived Defaults

Profile owns approved personal/fitness context. Feature domains own their own confirmed settings and calculations.

- Nutrition owns Nutrition Targets.
- Workout owns workout-specific settings, routines/programs, and training behavior.
- A profile value may seed a feature default through a stable contract.
- A profile change must not silently replace a user-confirmed feature override.

## Design System Direction

`apps/core` owns reusable UI primitives and Material 3 Expressive direction through semantic tokens/components.

Shared components such as `TioAvatar` and `TioButton` belong in `apps/core`; feature packages provide intent/state rather than recreating common interaction behavior.

Flutter Material 3 remains the implementation baseline. Do not assume a separate stable Flutter “Material 3 Expressive API” exists; expressiveness is delivered through Tio-owned tokens/components and verified accessibility behavior.

## Watch Rules

Watch apps stay compact, battery-aware, and watch-first.

Good watch responsibilities include:

- workout start/pause/resume/finish;
- active set input and rest timer;
- heart-rate/steps/calorie summaries where supported;
- offline active-workout snapshot;
- food/water quick add;
- today's nutrition summary;
- quick sync and appropriate tiles/complications.

Avoid full phone home surfaces, long forms, large analytics flows, full AI chat, or image-heavy editing on watches.

## Architecture Decision Records

Durable architecture decisions live in [Architecture Decision Records](adr/README.md).

The current Supabase + future `services/api` cutover supersedes the original workspace assumptions in ADR-0003; see ADR-0007 for the current durable boundary.

ADRs preserve historical decisions. This file represents current architecture truth and may be updated as accepted decisions evolve.

## Naming Rules

Canonical current/future paths include:

```text
apps/app
apps/wear
supabase/
services/api/       # future; not implemented yet
services/worker/    # future; only when justified
```

Do not introduce `backend/api` as the canonical protected API path. Do not rename existing Flutter paths only for symmetry.

## Related

- [Documentation index](README.md)
- [Auth Architecture](AUTH_ARCHITECTURE.md)
- [Supabase Strategy](SUPABASE_STRATEGY.md)
- [Supabase Server Access](SUPABASE_SERVER_ACCESS.md)
- [API Lifecycle](API_LIFECYCLE.md)
- [Feature Rollout](FEATURE_ROLLOUT.md)
- [ADR index](adr/README.md)
