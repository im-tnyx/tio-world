# Tio Wear OS

Native Wear OS companion app scaffold.

This app should stay native for fast workout controls, watch sensors, tiles, complications, phone-watch sync, and battery-sensitive flows.

## Ownership

- Wear UI belongs here.
- Shared contracts come from `apps/shared` when Gradle wiring is introduced.
- Phone Flutter UI must not be reused directly on Wear OS.
- Backend sync and protected operations stay server-side.

## Planned structure

```text
apps/wear/
├─ build.gradle.kts
└─ src/main/
   ├─ AndroidManifest.xml
   └─ kotlin/com/tnyx/wear/
      └─ WearMainActivity.kt
```
