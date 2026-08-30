# tio-world Documentation

This folder is the source of truth for product architecture, module ownership, setup, validation, and future implementation direction.

`tio-world` is a Flutter-first health, fitness, workout, nutrition, progress, coaching, and wearable monorepo with a Flutter Wear OS companion, a future native Apple Watch app, an active Supabase Auth/data foundation, and a future protected `services/api` server workspace.

## Start Here

| Document | Purpose |
| :--- | :--- |
| [`ARCHITECTURE.md`](ARCHITECTURE.md) | Repository shape, architecture principles, app boundaries, and dependency direction. |
| [`AUTH_ARCHITECTURE.md`](AUTH_ARCHITECTURE.md) | Canonical Supabase Auth identity authority and future protected-service token boundary. |
| [`SUPABASE_STRATEGY.md`](SUPABASE_STRATEGY.md) | Supabase Auth, Postgres/RLS, Storage, AI-provider, and future-backend boundaries. |
| [`SUPABASE_SERVER_ACCESS.md`](SUPABASE_SERVER_ACCESS.md) | User-scoped vs privileged Supabase server access policy and no-escalation rules. |
| [`SECRETS_AND_ENVIRONMENTS.md`](SECRETS_AND_ENVIRONMENTS.md) | Client-safe vs server-secret classification, environment isolation, rotation/revocation, and leak-response policy. |
| [`OBSERVABILITY.md`](OBSERVABILITY.md) | Structured logs, metrics, OpenTelemetry readiness, request/job correlation, dependency signals, and safe telemetry boundaries. |
| [`QUEUE_STRATEGY.md`](QUEUE_STRATEGY.md) | Supabase Queues/pgmq first-choice boundary, queue use/non-use cases, versioned messages, visibility, acknowledgement, and technology escalation triggers. |
| [`ASYNC_RELIABILITY.md`](ASYNC_RELIABILITY.md) | Job idempotency, retry classification/backoff, terminal/dead-letter handling, replay, and scheduled-vs-event-driven reliability rules. |
| [`WORKER_ARCHITECTURE.md`](WORKER_ARCHITECTURE.md) | Future `services/worker` lifecycle, queue-consumer loop, bounded concurrency, graceful shutdown, restart safety, and API/worker deployment boundary. |
| [`SCALING_READINESS.md`](SCALING_READINESS.md) | Evidence-based API/database/queue/worker/Storage/provider capacity triggers, scale ladder, cache boundary, and sharding-last policy. |
| [`DEPLOYMENT_AND_ROLLBACK.md`](DEPLOYMENT_AND_ROLLBACK.md) | Provider-neutral API/worker deployment, readiness gates, rollback boundaries, release provenance, and reproducible infrastructure/configuration policy. |
| [`DATA_PRIVACY_GOVERNANCE.md`](DATA_PRIVACY_GOVERNANCE.md) | Data classification, minimization, logging/analytics, AI/provider, deletion/export, retention, and environment-separation policy. |
| [`DATABASE_BACKUP_RECOVERY.md`](DATABASE_BACKUP_RECOVERY.md) | Backup/PITR readiness, RPO/RTO, restore ownership, Storage recovery, and migration-safety policy. |
| [`API_LIFECYCLE.md`](API_LIFECYCLE.md) | `/v1` compatibility, deprecation, minimum-client, capability negotiation, and generated-client traceability policy. |
| [`FEATURE_ROLLOUT.md`](FEATURE_ROLLOUT.md) | Provider-neutral capability rollout, safe defaults, cohorting, cache/offline behavior, and emergency kill-switch policy. |
| [`ONBOARDING_ARCHITECTURE.md`](ONBOARDING_ARCHITECTURE.md) | Single-route parent shell, mode-derived child flow, state, persistence gates, and delivery slices for onboarding. |
| [`screens/README.md`](screens/README.md) | Per-screen product specifications, module owners, state rules, and implementation order. |
| [`FLUTTER_MODULAR_STRUCTURE.md`](FLUTTER_MODULAR_STRUCTURE.md) | Flutter apps-based module structure matching the native `:app`, `:shared`, `:core`, and `:features:*` pattern. |
| [`MODULE_OWNERSHIP.md`](MODULE_OWNERSHIP.md) | Ownership rules for app shell, core, shared, feature packages, watch, future services, and product areas. |
| [`DEVELOPMENT_SETUP.md`](DEVELOPMENT_SETUP.md) | Local setup, required tools, bootstrap commands, and validation flow. |
| [`WATCH_STRATEGY.md`](WATCH_STRATEGY.md) | Flutter Wear OS and native Apple Watch strategy. |
| [`DATA_AND_SYNC.md`](DATA_AND_SYNC.md) | Repository pattern, offline-first direction, sync boundaries, and backend expectations. |
| [`adr/README.md`](adr/README.md) | Durable architecture decision records and their status. |
| [`UX_UI_SYSTEM.md`](UX_UI_SYSTEM.md) | Phone and Wear UI/UX ownership, Material 3 Expressive direction, accessibility, and shell rules. |
| [`MVP_ACCEPTANCE.md`](MVP_ACCEPTANCE.md) | Acceptance gates for the first product vertical slices; not a claim that they are implemented. |
| [`SECURITY.md`](SECURITY.md) | Health data, auth, privacy, public-repo safety, and baseline secret-handling rules. |
| [`TESTING_GUIDE.md`](TESTING_GUIDE.md) | Testing expectations for Flutter phone/Wear OS, native watchOS, packages, and future backend. |
| [`ROADMAP.md`](ROADMAP.md) | Practical MVP and phased product roadmap. |
| [`POST_MERGE_SYNC.md`](POST_MERGE_SYNC.md) | Post-merge local sync workflow. |
| [`PUSH_TEMPLATE.md`](PUSH_TEMPLATE.md) | Push and PR checklist for humans and AI agents. |

## Target Repository Shape

The current checkout contains the Flutter workspace and the active `supabase/` workspace that owns applied schema migrations and approved Supabase platform configuration. The future protected server destination is `services/api`; it remains unimplemented and must be created only with its first explicitly authorized server-side implementation slice.

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
│     ├─ home/
│     ├─ workout/
│     ├─ nutrition/
│     ├─ profile/
│     ├─ settings/
│     ├─ progress/
│     └─ coaching/
├─ supabase/        # ACTIVE config, migrations, policies, and approved functions
├─ services/        # Future runnable protected server processes
│  ├─ api/          # Future Node.js + TypeScript + Fastify modular monolith
│  └─ worker/       # Future only when a real async workload requires it
├─ packages/        # Future reusable code only when a real extraction boundary exists
├─ docs/            # Canonical documentation
├─ .github/         # GitHub workflow, templates, CODEOWNERS
├─ .ai/             # Short AI/contributor orientation
└─ README.md
```

The tree above documents accepted destinations. Do not create empty `services/`, `worker/`, or package folders just to match it.

## Documentation Rules

- Runtime source/config wins for actual behavior.
- `docs/` wins for architecture and ownership decisions.
- `.ai/` is only a short orientation layer.
- Update docs when module boundaries, data flow, navigation, security, or platform strategy changes.
- Keep docs practical. Avoid future modules until a real product slice needs them.
- Do not convert documentation-only backend planning into runtime/backend implementation without explicit authorization.

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

The accepted future protected API path is:

```text
services/api
```

Do not introduce `backend/api` as an alternate canonical path. Do not rename existing folders unless repo config, docs, CI, workspace config, and ownership references are updated together.
