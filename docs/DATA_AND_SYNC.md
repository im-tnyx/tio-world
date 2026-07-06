# Data And Sync

This document defines the direction for data ownership, repositories, offline behavior, local persistence, code generation, and sync.

## Data Principles

- The app should be offline-first for core fitness flows.
- UI should not know database table shape.
- UI should not call remote APIs directly.
- Feature controllers call repositories or use cases.
- Repositories hide local and remote data sources.
- Backend becomes the durable source of truth for signed-in user data.
- Watch apps keep only minimal local state needed for fast offline workflows.

## Repository Pattern

Recommended flow:

```text
Page / Widget
  ↓
Riverpod controller / notifier
  ↓
Use case / domain service
  ↓
Repository contract
  ↓
Local data source + remote data source
```

Rules:

- Repository contracts live in the owning feature package or `apps/shared` when reused across features.
- Local persistence details stay behind repository implementations.
- Remote API DTOs should not leak into widgets.
- Feature packages own their data mapping from local rows, DTOs, and domain entities.

## Local Persistence Direction

Use local persistence soon for offline-first product flows.

Preferred candidates:

```text
Drift
Isar
similar local-first persistence layer if it better fits the product slice
```

Decision rules:

- Start with the smallest persistence layer that supports the MVP slice.
- Workout logging should be offline-capable early.
- Nutrition diary and progress entries should be cacheable and syncable.
- Keep database APIs behind repositories so Drift, Isar, or another store can be swapped before production hardening.

Minimum local tables/collections when persistence starts:

```text
workout_sessions
workout_events
nutrition_entries
progress_entries
sync_queue
sync_metadata
```

## State Management

Use Riverpod for app and feature state.

Guidelines:

- Feature state should live inside the owning feature package.
- App-level providers stay in `apps/app` only when they wire global concerns.
- Repository providers should expose contracts, not raw database/API clients.

## Navigation

Use `go_router` for app navigation.

Direction:

- Use typed routes as route surfaces mature.
- Keep route composition in `apps/app`.
- Keep feature route contracts inside owning feature packages.
- Do not import feature internals from another feature.

## Code Generation

Use `freezed` and `json_serializable` for immutable models, DTOs, and value types.

Guidelines:

- Domain entities should be stable and explicit.
- DTOs should be mapped into domain models before entering presentation code.
- Generated files are allowed when source files are committed with their corresponding part directives.
- Keep codegen dependencies in the package that owns the generated types.

## Feature Data Ownership

| Data | Owner |
| :--- | :--- |
| User identity | Auth/Profile |
| Onboarding answers | Onboarding/Profile repository |
| Workout sessions | Workout |
| Exercises and routines | Workout |
| Nutrition diary | Nutrition |
| Foods and meals | Nutrition |
| Weight and measurements | Progress |
| Coaching insights | Coaching + backend AI coach |
| Watch active workout snapshot | Watch app + Workout sync |

## Offline Direction

MVP can start with placeholders, but core product data should move toward offline-first before production.

Minimum offline support:

- active workout session
- set events
- rest timer state
- pending sync queue
- last successful sync timestamp
- cached nutrition entries
- cached progress entries

## Sync Event Shape

Prefer event-style sync for workout actions:

```json
{
  "id": "event-id",
  "type": "set_completed",
  "sessionId": "workout-session-id",
  "createdAt": "2026-07-05T16:00:00Z",
  "payload": {}
}
```

Events should be idempotent where possible.

## Conflict Handling

Start simple:

- accepted server event wins once synced
- duplicate event IDs are ignored
- client retries pending events
- user-visible edits should be explicit

Do not implement complex sync until real product flows demand it.

## Backend Direction

Backend will eventually own:

- user data APIs
- coaching orchestration
- health integration processing
- scheduled jobs
- database migrations
- seed data

## Public Repo Safety

Do not commit real user exports, health records, production logs, local database dumps, or screenshots containing personal data.
