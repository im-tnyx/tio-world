# Data And Sync

This document defines the direction for data ownership, repositories, offline behavior, and sync.

## Data Principles

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
Controller / Notifier
  ↓
Use case / Domain service
  ↓
Repository
  ↓
Local cache + Remote API
```

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

MVP can start online-first, but workout flows should become offline-capable early.

Minimum offline support:

- active workout session
- set events
- rest timer state
- pending sync queue
- last successful sync timestamp

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
