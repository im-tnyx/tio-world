# Watch Strategy

`tio-world` treats smartwatch support as a core product surface, not an afterthought.

## Decision

Use Flutter for Wear OS and Swift/SwiftUI for Apple Watch:

| Watch platform | Stack |
| :--- | :--- |
| Wear OS | Flutter |
| Apple Watch | Swift + SwiftUI when introduced |

The Wear OS app is built with Flutter (`apps/wear`) to share design systems and logic, while the Apple Watch app stays native (SwiftUI) for iOS-specific health/sensor integrations.

## Current Folder

Wear OS lives in:

```text
apps/wear
```

Do not rename this folder without updating docs, scripts, CI, and future app config.

## Watch Product Scope

Watch should focus on fast actions:

- start workout
- pause, resume, and finish workout
- active exercise and set view
- reps, weight, and RPE quick input
- rest timer
- heart rate display
- steps and calories summary
- offline active workout snapshot
- quick sync with phone/backend

## Avoid On Watch

Avoid putting these on watch unless a strong product reason exists:

- full dashboard
- long onboarding
- full food database search
- complex analytics
- large charts
- long AI coaching conversations
- heavy image assets
- deep settings flows

## Wear OS Architecture

Expected Wear OS structure when generated:

```text
apps/wear/
├─ src/main/
│  ├─ AndroidManifest.xml
│  ├─ kotlin/com/tnyx/wear/
│  │  ├─ MainActivity.kt
│  │  ├─ app/
│  │  ├─ navigation/
│  │  ├─ screens/
│  │  │  ├─ workout/
│  │  │  ├─ health/
│  │  │  └─ sync/
│  │  ├─ components/
│  │  ├─ healthservices/
│  │  ├─ phonebridge/
│  │  ├─ tiles/
│  │  └─ complications/
│  └─ res/
└─ build.gradle.kts
```

## Phone And Watch Sync

Start simple:

1. Watch records current active workout snapshot.
2. Phone receives and reconciles workout events.
3. Backend becomes source of truth once auth and persistence are ready.
4. Sync conflicts are resolved using clear timestamps and event IDs.

## Data Rules

Watch should store only the minimum needed for offline continuity:

- current workout session
- current exercise
- recent set events
- rest timer state
- last successful sync timestamp

Do not keep full long-term history on watch unless required.

## Performance Rules

- Keep startup fast.
- Keep screens shallow.
- Minimize background work.
- Prefer small local payloads.
- Avoid large images and animation-heavy UI.
- Test on real watch hardware before considering a watch flow production-ready.
