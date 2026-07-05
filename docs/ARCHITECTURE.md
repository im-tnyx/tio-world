# Architecture

`tio-world` is a Flutter-first product monorepo with native smartwatch apps.

## Core Promise

Move fast on product, but keep boundaries clean.

- `apps/mobile` owns the Flutter Android and iOS phone app.
- `apps/wear` owns the native Wear OS app.
- `apps/design` owns design references and exported design assets.
- `packages/*` owns reusable Dart logic when reuse is real.
- `backend/*` owns API, jobs, AI coach runtime, and database work when introduced.
- `docs/` owns architecture and implementation direction.
- `.ai/` owns short AI orientation files.

## Current Shape

```text
tio-world/
├─ apps/
│  ├─ mobile/
│  ├─ wear/
│  └─ design/
├─ packages/
├─ backend/
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
| Wear OS | Kotlin + Compose for Wear OS | Native watch performance and platform APIs. |
| Apple Watch | Swift + SwiftUI | Native watchOS experience. |
| Backend | Server-side workspace | API, sync, coaching, database, and jobs. |

## Mobile Feature Pattern

Inside `apps/mobile`, prefer feature-first structure:

```text
lib/
├─ app/
├─ core/
├─ shared/
└─ features/
   ├─ auth/
   ├─ onboarding/
   ├─ workout/
   ├─ nutrition/
   ├─ coaching/
   ├─ progress/
   ├─ dashboard/
   └─ profile/
```

Each feature should use this shape when it grows beyond a simple screen:

```text
feature/
├─ data/
├─ domain/
└─ presentation/
```

## Dependency Direction

```text
apps/mobile
  ↓
mobile features
  ↓
packages/*
  ↓
backend contracts and API boundaries
```

Rules:

- Pages and widgets render state and emit actions.
- Controllers/notifiers handle UI actions.
- Domain/use cases hold business rules.
- Data/repositories hide remote and local data details.
- Feature-specific logic stays with the owning feature.
- Reusable logic moves into `packages/*` only after reuse is real.

## Recommended Flutter Stack

```text
Riverpod
go_router
dio
freezed
json_serializable
melos
```

## Watch Rules

Watch apps should stay small and fast.

Good watch responsibilities:

- workout start, pause, resume, finish
- active set input
- rest timer
- heart rate display
- steps and calories summary
- offline active workout snapshot
- quick sync

Avoid putting heavy dashboards, long forms, full AI chat, or large analytics flows on watches.

## Naming Rule

The Wear OS folder is:

```text
apps/wear
```

Keep this name consistent across docs, CI, scripts, and future app config.
