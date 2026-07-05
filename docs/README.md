# tio-world Documentation

This folder is the source of truth for product architecture, module ownership, setup, validation, and future implementation direction.

`tio-world` is a Flutter-first health, fitness, workout, nutrition, progress, coaching, and wearable monorepo.

## Start Here

| Document | Purpose |
| :--- | :--- |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Repository shape, architecture principles, app boundaries, and dependency direction. |
| [`MODULE_OWNERSHIP.md`](MODULE_OWNERSHIP.md) | Ownership rules for mobile, watch, packages, backend, and product features. |
| [`DEVELOPMENT_SETUP.md`](DEVELOPMENT_SETUP.md) | Local setup, required tools, bootstrap commands, and validation flow. |
| [`WATCH_STRATEGY.md`](WATCH_STRATEGY.md) | Wear OS and Apple Watch strategy, including why watch UI stays native. |
| [`DATA_AND_SYNC.md`](DATA_AND_SYNC.md) | Repository pattern, offline-first direction, sync boundaries, and backend expectations. |
| [`SECURITY.md`](SECURITY.md) | Secrets, health data, auth, privacy, and public-repo safety rules. |
| [`TESTING_GUIDE.md`](TESTING_GUIDE.md) | Testing expectations for Flutter, native watch apps, packages, and backend. |
| [`ROADMAP.md`](ROADMAP.md) | Practical MVP and phased product roadmap. |
| [`POST_MERGE_SYNC.md`](POST_MERGE_SYNC.md) | Post-merge local sync workflow. |
| [`PUSH_TEMPLATE.md`](PUSH_TEMPLATE.md) | Push and PR checklist for humans and AI agents. |

## Current Repository Shape

```text
tio-world/
├─ apps/
│  ├─ mobile/      # Flutter Android + iOS phone app
│  ├─ wear/        # Native Wear OS app
│  └─ design/      # Design references and exported assets
├─ packages/       # Reusable Dart packages when introduced
├─ backend/        # API, AI coach, jobs, and database when introduced
├─ docs/           # Canonical documentation
├─ .github/        # GitHub workflow, templates, CODEOWNERS
├─ .ai/            # Short AI/contributor orientation
└─ README.md
```

## Documentation Rules

- Runtime source/config wins for actual behavior.
- `docs/` wins for architecture and ownership decisions.
- `.ai/` is only a short orientation layer.
- Update docs when module boundaries, data flow, navigation, security, or platform strategy changes.
- Keep docs practical. Avoid future modules until a real product slice needs them.

## Naming Decision

The Wear OS app folder is intentionally:

```text
apps/wear
```

Do not rename it to `apps/wear-os` unless the repo config, docs, CI, and ownership references are updated together.
