# Watch Strategy

`tio-world` treats smartwatch support as a core product surface, not an afterthought.

## Decision

Use Flutter for Wear OS and Swift/SwiftUI for Apple Watch:

| Watch platform | Stack |
| :--- | :--- |
| Wear OS | Flutter |
| Apple Watch | Swift + SwiftUI when introduced |

`apps/wear` is an existing Flutter package and remains the Wear OS companion. It owns watch-first UI and may reuse lightweight design primitives and shared contracts from `apps/core` and `apps/shared`; it must not reuse phone screens directly. Apple Watch stays native (SwiftUI) for its platform-specific health and sensor integrations.

## Current Folder

Wear OS lives in:

```text
apps/wear
```

Do not rename this folder without updating docs, scripts, CI, and future app config.

## Watch Product Scope

Watch should focus on two fast-action lanes.

Workout:

- start workout
- pause, resume, and finish workout
- active exercise and set view
- reps, weight, and RPE quick input
- rest timer
- heart rate display
- offline active workout snapshot

Nutrition:

- add food or meal quick action
- add water
- today's calories and macro summary
- next planned meal status after Meal Plan exists on phone

Both lanes may show steps, calories, and quick sync state with phone/backend.

## Avoid On Watch

Avoid putting these on watch unless a strong product reason exists:

- full phone home surface
- long onboarding
- full food database search
- full nutrition diary or Meal Plan editing
- complex analytics
- large charts
- long AI coaching conversations
- heavy image assets
- deep settings flows

## Wear OS Architecture

Current Flutter Wear OS structure:

```text
apps/wear/
├─ lib/
│  ├─ main.dart
│  ├─ wear_app.dart
│  └─ src/
│     ├─ home/
│     ├─ live_workout/
│     ├─ nutrition/
│     └─ sync/
├─ android/
├─ test/
└─ pubspec.yaml
```

## Phone And Watch Sync

Start simple:

1. Watch records current active workout snapshot.
2. Phone receives and reconciles workout events.
3. Supabase becomes the Auth/data source of truth once the approved first slice is ready; a protected backend is a later upgrade.
4. Sync conflicts are resolved using clear timestamps and event IDs.

## Data Rules

Watch should store only the minimum needed for offline continuity:

- current workout session
- current exercise
- recent set events
- rest timer state
- pending nutrition quick actions
- last successful sync timestamp

Do not keep full long-term history on watch unless required.

## Performance Rules

- Keep startup fast.
- Keep screens shallow.
- Minimize background work.
- Prefer small local payloads.
- Avoid large images and animation-heavy UI.
- Test on real watch hardware before considering a watch flow production-ready.
