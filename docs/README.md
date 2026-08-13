# tio-world Documentation

This folder is the source of truth for product architecture, module ownership, setup, validation, and future implementation direction.

`tio-world` is a Flutter-first health, fitness, workout, nutrition, progress, coaching, and wearable monorepo with a Flutter Wear OS companion, a future native Apple Watch app, and a planned server-side backend workspace.

## Start Here

| Document | Purpose |
| :--- | :--- |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Repository shape, architecture principles, app boundaries, and dependency direction. |
| [`ONBOARDING_ARCHITECTURE.md`](ONBOARDING_ARCHITECTURE.md) | Single-route parent shell, mode-derived child flow, state, persistence gates, and delivery slices for onboarding. |
| [`screens/README.md`](screens/README.md) | Per-screen product specifications, module owners, state rules, and implementation order. |
| [`FLUTTER_MODULAR_STRUCTURE.md`](FLUTTER_MODULAR_STRUCTURE.md) | Flutter apps-based module structure matching the native `:app`, `:shared`, `:core`, and `:features:*` pattern. |
| [`MODULE_OWNERSHIP.md`](MODULE_OWNERSHIP.md) | Ownership rules for app shell, core, shared, feature packages, watch, backend, and product areas. |
| [`DEVELOPMENT_SETUP.md`](DEVELOPMENT_SETUP.md) | Local setup, required tools, bootstrap commands, and validation flow. |
| [`WATCH_STRATEGY.md`](WATCH_STRATEGY.md) | Flutter Wear OS and native Apple Watch strategy. |
| [`DATA_AND_SYNC.md`](DATA_AND_SYNC.md) | Repository pattern, offline-first direction, sync boundaries, and backend expectations. |
| [`SUPABASE_STRATEGY.md`](SUPABASE_STRATEGY.md) | Planned Supabase Auth, Postgres/RLS, Storage, Gemini, and future-backend boundaries. |
| [`adr/README.md`](adr/README.md) | Durable architecture decision records and their status. |
| [`UX_UI_SYSTEM.md`](UX_UI_SYSTEM.md) | Phone and Wear UI/UX ownership, Material 3 Expressive direction, accessibility, and shell rules. |
| [`MVP_ACCEPTANCE.md`](MVP_ACCEPTANCE.md) | Acceptance gates for the first product vertical slices; not a claim that they are implemented. |
| [`SECURITY.md`](SECURITY.md) | Secrets, health data, auth, privacy, and public-repo safety rules. |
| [`TESTING_GUIDE.md`](TESTING_GUIDE.md) | Testing expectations for Flutter phone/Wear OS, native watchOS, packages, and backend. |
| [`ROADMAP.md`](ROADMAP.md) | Practical MVP and phased product roadmap. |
| [`POST_MERGE_SYNC.md`](POST_MERGE_SYNC.md) | Post-merge local sync workflow. |
| [`PUSH_TEMPLATE.md`](PUSH_TEMPLATE.md) | Push and PR checklist for humans and AI agents. |

## Target Repository Shape

The current checkout contains the Flutter workspace. Supabase is the planned Auth/data/Storage foundation, but no `supabase/` workspace exists yet. The separate `backend/` directory is a later protected-service upgrade and must be introduced only with its first approved server-side vertical slice.

The current feature packages include `home`, `auth`, `onboarding`, `workout`, `nutrition`, `profile`, `settings`, `progress`, and `coaching`.

```text
tio-world/
├─ apps/
│  ├─ app/          # Flutter Android + iOS phone app shell
│  ├─ wear/         # Flutter Wear OS app
│  ├─ watchos/      # Future native Swift + SwiftUI Apple Watch app
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
├─ supabase/        # Future Auth, Postgres/RLS, Storage, and migrations
├─ backend/         # Future protected AI/integration/job services
├─ docs/            # Canonical documentation
├─ .github/         # GitHub workflow, templates, CODEOWNERS
├─ .ai/             # Short AI/contributor orientation
└─ README.md
```

## Documentation Rules

- Runtime source/config wins for actual behavior.
- `docs/` wins for architecture and ownership decisions.
- `.ai/` is only a short orientation layer.
- Update docs when module boundaries, data flow, navigation, security, or platform strategy changes.
- Keep docs practical. Avoid future modules until a real product slice needs them.

## Naming Decisions

The Flutter phone app shell folder is intentionally:

```text
apps/app
```

The Flutter Wear OS app folder is intentionally:

```text
apps/wear
```

Feature packages live under:

```text
apps/features/<feature>
```

Do not rename these folders unless repo config, docs, CI, Melos workspace config, and ownership references are updated together.
