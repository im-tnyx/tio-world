# Architecture Summary

Document Status: Canonical Live Doc
Last Verified: 2026-09-27
Owner: repository AI governance
Truth Boundary: Concise AI-facing orientation to current repository architecture; canonical architecture docs/ADRs and runtime source/config override this summary.

`tio-world` uses a Flutter-first monorepo architecture with a Flutter Wear OS companion, a native Apple Watch app, and feature-owned vertical slices.

The target shape is modular, practical, and easy to grow without leaking business logic into UI.

## Core Rules

- Mobile app UI lives in `apps/app` using Flutter.
- Wear OS companion app lives in `apps/wear` using Flutter.
- Wear OS owns lightweight workout controls and nutrition quick actions, not full phone workflows.
- Future Apple Watch UI belongs in `apps/watchos` using native Swift + SwiftUI when that app is introduced.
- Shared Dart models, entities, repository contracts, and use cases live in `apps/shared`.
- Shared Flutter design tokens, shell components, and route contracts live in `apps/core`.
- Feature-owned mobile UI and workflows live in `apps/features/*`.
- Supabase is the active Auth, Postgres/RLS, Storage, migration, and approved server-function boundary. Future protected application work belongs under `services/api`; add `services/worker` only when a separately approved asynchronous/background workload requires it. Do not introduce `backend/*`.
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

Workout Library remains a Workout route, and Meal Plan remains a future Nutrition route after diary MVP. Neither is a guided default tab. Pre-auth App Mode selection and the Settings mode editor are implemented. Product Onboarding's single parent flow and multiple owner-backed sections are live, while remaining compatibility owner sections/final acceptance stay separately gated. Coach becomes eligible only when Phase 7 begins.

Current Product Onboarding uses one `/onboarding` parent screen. Top progress and
bottom actions stay fixed while one mode-derived child changes. Stable step IDs and
one Riverpod controller own the internal flow. Durable draft autosave/resume is
implemented through the Supabase-backed draft repository, while draft mode,
confirmed App Mode, and completion status remain separate; see
[Onboarding Flow Architecture](../docs/architecture/ONBOARDING_ARCHITECTURE.md).

A final-stage custom navigation layer keeps Home first, supports three to six eligible destinations, and may promote implemented feature routes such as Workout Library or Meal Plan as shortcuts. Home sections and feature action entries adapt through shared layout/composition contracts while business logic remains feature-owned.

Profile should open from avatar/account entry.

Settings should open from the Profile launcher; Home chrome should not expose a separate Settings icon.

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
