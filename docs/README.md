# tio-world Documentation

This folder is the source of truth for product architecture, module ownership, setup, validation, and future implementation direction.

`tio-world` is a Flutter-first health, fitness, workout, nutrition, progress, coaching, and wearable monorepo with native watch apps and a root-level backend workspace.

## Start Here

| Document | Purpose |
| :--- | :--- |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Repository shape, architecture principles, app boundaries, and dependency direction. |
| [`FLUTTER_MODULAR_STRUCTURE.md`](FLUTTER_MODULAR_STRUCTURE.md) | Flutter apps-based module structure matching the native `:app`, `:shared`, `:core`, and `:features:*` pattern. |
| [`MODULE_OWNERSHIP.md`](MODULE_OWNERSHIP.md) | Ownership rules for app shell, core, shared, feature packages, watch, backend, and product areas. |
| [`DEVELOPMENT_SETUP.md`](DEVELOPMENT_SETUP.md) | Local setup, required tools, bootstrap commands, and validation flow. |
| [`WATCH_STRATEGY.md`](WATCH_STRATEGY.md) | Wear OS and Apple Watch strategy, including why watch UI stays native. |
| [`DATA_AND_SYNC.md`](DATA_AND_SYNC.md) | Repository pattern, offline-first direction, sync boundaries, and backend expectations. |
| [`SECURITY.md`](SECURITY.md) | Secrets, health data, auth, privacy, and public-repo safety rules. |
| [`TESTING_GUIDE.md`](TESTING_GUIDE.md) | Testing expectations for Flutter, native watch apps, packages, and backend. |
| [`ROADMAP.md`](ROADMAP.md) | Practical MVP and phased product roadmap. |
| [`POST_MERGE_SYNC.md`](POST_MERGE_SYNC.md) | Post-merge local sync workflow. |
| [`PUSH_TEMPLATE.md`](PUSH_TEMPLATE.md) | Push and PR checklist for humans and AI agents. |

## Current Target Repository Shape

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
├─ backend/         # API, AI coach, jobs, and database
├─ docs/            # Canonical documentation
├─ tools/           # Scripts, CI helpers, and release helpers
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

The native Wear OS app folder is intentionally:

```text
apps/wear
```

Feature packages live under:

```text
apps/features/<feature>
```

Do not rename these folders unless repo config, docs, CI, Melos workspace config, and ownership references are updated together.
