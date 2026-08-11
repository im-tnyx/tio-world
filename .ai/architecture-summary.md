# Architecture Summary

`tio-world` uses a Flutter-first monorepo architecture with a Flutter Wear OS companion, a native Apple Watch app, and feature-owned vertical slices.

The target shape is modular, practical, and easy to grow without leaking business logic into UI.

## Core Rules

- Mobile app UI lives in `apps/app` using Flutter.
- Wear OS companion app lives in `apps/wear` using Flutter.
- Wear OS owns lightweight workout controls and nutrition quick actions, not full phone workflows.
- Apple Watch UI lives in `apps/watchos` using Swift + SwiftUI.
- Shared Dart models, entities, repository contracts, and use cases live in `apps/shared`.
- Shared Flutter design tokens, shell components, and route contracts live in `apps/core`.
- Feature-owned mobile UI and workflows live in `apps/features/*`.
- Supabase is the planned first Auth, Postgres/RLS, Storage, and migration boundary. Future `backend/*` owns privileged Gemini/AI orchestration, advanced integrations, and long-running jobs.
- Feature logic stays inside the owning feature or package.
- UI remains dumb and renders immutable state.
- Business rules belong in controllers/notifiers/use cases/domain services/repositories.
- Do not move feature business logic into app bootstrap, routing glue, or global shell code.

## Flutter Mobile Pattern

Use this shape for feature slices:

```text
apps/features/<feature>/
├─ data/
│  ├─ datasources/
│  ├─ dto/
│  ├─ mappers/
│  └─ repositories/
├─ domain/
│  ├─ entities/
│  ├─ repositories/
│  └─ usecases/
└─ presentation/
   ├─ pages/
   ├─ widgets/
   ├─ controllers/
   └─ state/
```

Preferred flow:

```text
Page -> Controller/Notifier -> Use Case -> Repository -> Data Source
```

Flutter widgets must not directly perform network calls, database writes, auth mutations, or sync decisions.

## App Mode And Mobile Navigation

The implemented architecture places the single `AppMode` enum, guided destination mapping, and preference boundary in `apps/shared`. Its active value determines the visible `go_router` `StatefulShellRoute` tabs:

| App mode | Guided default tabs |
| :--- | :--- |
| `workout` | Home, Workout, Progress |
| `nutrition` | Home, Nutrition, Progress |
| `hybrid` | Home, Workout, Nutrition, Progress |

Workout Library remains a Workout route, and Meal Plan remains a future Nutrition route after diary MVP. Neither is a guided default tab. Onboarding's first mode-selection screen and Settings mode editor are implemented; later conditional onboarding steps remain planned. Coach becomes eligible only when Phase 7 begins.

A final-stage custom navigation layer keeps Home first, supports three to six eligible destinations, and may promote implemented feature routes such as Routine Library or Meal Plan as shortcuts. Home sections and feature action entries adapt through shared layout/composition contracts while business logic remains feature-owned.

Profile should open from avatar/account entry.

Settings should open from the gear/settings entry.

## Future Modules

Create modules only when runtime code needs them.

Do not create empty future modules for:

- Recovery
- Billing
- Entitlement
- Community
- Challenges
- Learn / Resources
- Rewards
- Analytics
- Full health integrations

Document the owner first, then add the smallest useful vertical slice.
