# Architecture Summary

`tio-world` uses a Flutter-first monorepo architecture with native watch apps and feature-owned vertical slices.

The target shape is modular, practical, and easy to grow without leaking business logic into UI.

## Core Rules

- Mobile app UI lives in `apps/app` using Flutter.
- Wear OS companion app lives in `apps/wear` using Flutter.
- Apple Watch UI lives in `apps/watchos` using Swift + SwiftUI.
- Shared mobile logic lives in `packages/*` only when it is reused or clearly reusable.
- Backend, AI, migrations, and privileged operations live under `backend/*`.
- Feature logic stays inside the owning feature or package.
- UI remains dumb and renders immutable state.
- Business rules belong in controllers/notifiers/use cases/domain services/repositories.
- Do not move feature business logic into app bootstrap, routing glue, or global shell code.

## Flutter Mobile Pattern

Use this shape for feature slices:

```text
features/<feature>/
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

## Main Mobile Navigation

Primary mobile tabs:

- Home
- Workout
- Nutrition
- Coach
- Progress

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
