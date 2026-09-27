# tio-world Documentation

This folder is the source of truth for product architecture, module ownership, setup, validation, and future implementation direction.

`tio-world` is a Flutter-first health, fitness, workout, nutrition, progress, coaching, and wearable monorepo with a Flutter Wear OS companion, a future native Apple Watch app, an active Supabase Auth/data foundation, and a future protected `services/api` server workspace.


## Documentation Authority

Use these layers to decide what is authoritative for a question:

1. **Checked-in source, configuration, migrations, and generated/runtime evidence** are executable truth for what the repository currently does.
2. **Canonical product and architecture docs under `docs/` plus accepted ADRs** define intended product rules, repository ownership, durable architecture direction, policy, and roadmap for their stated scopes. An ADR does not prove that implementation has landed.
3. **Module-local docs** under an owning app/package describe implementation details for that module only. They do not override repository-wide product or architecture governance.
4. **`.ai/`** is an execution, routing, and handoff layer. It points to canonical truth, records bounded task context, and must not become a parallel product-truth store.

When two sources disagree, do not average or silently choose between them. Use the authority boundary above for the specific question, call out the stale/conflicting source, and update that source in the appropriate bounded task.

## Conflict Resolution

Apply this order by question type:

- For **current runtime behavior**, source/config/migrations and validated runtime evidence win.
- For **approved architecture direction and durable architecture decisions**, accepted ADRs and canonical architecture docs win until implementation catches up.
- For **product status, repository ownership, policy, roadmap, and cross-module direction**, canonical `docs/` files win within their stated truth boundaries.
- For **module-specific implementation detail**, the owning module's source is primary and its local docs may summarize it.
- `.ai/` never overrides the layers above; if its handoff text disagrees, treat the `.ai/` text as stale and reconcile it.

## Document Status Labels

Documents that can drift use one of these canonical status labels:

| Label | Meaning |
| :--- | :--- |
| `Canonical Live Doc` | Current source of truth for the document's stated scope. |
| `Module Detail Doc` | Implementation detail owned by one app, package, platform, or module. |
| `Architecture Decision Record` | Accepted or proposed architecture direction with explicit decision status; it does not by itself prove implementation is live. |
| `Historical Snapshot` | Preserved audit, plan, or execution record from a point in time; useful for history but not current truth. |
| `Deprecated` | Retained only for transition/reference context and should identify the replacement when known. |
| `Planned/Future Doc` | Roadmap, proposal, or design intent that must not imply shipped behavior. |

P5 and P6 apply the four-line governance headers only after the separately gated P4A document-location normalization settles final document ownership/locations. P4 itself does not move documents or roll out headers repository-wide.

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

## Documentation Maintenance Rules

- Keep each document inside its stated truth boundary; do not duplicate canonical truth in another layer.
- Update the owning canonical doc when module boundaries, data flow, navigation, security, platform strategy, repository ownership, or durable product rules change.
- Preserve useful history by marking it `Historical Snapshot` or `Deprecated` instead of rewriting historical facts as if they were current.
- Keep planned/future documents explicit about what is not implemented.
- Document location is part of ownership. Actual relocation/classification work belongs to the separately gated P4A phase.
- Do not create future modules, folders, APIs, or backend runtime merely because documentation names an accepted future destination.
- Do not convert documentation-only planning into runtime implementation without the separately required task authorization.

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
