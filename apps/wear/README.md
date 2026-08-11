# Tio Wear OS

## Architecture Status

This is the active Flutter Wear OS companion package. Retain it for Phase 5 and extend it with watch-first Flutter flows; do not replace it with a native Kotlin module.

## Current Scope

This package owns the watch-first UI. Phone screens from `apps/app` should not be reused directly on Wear OS. Shared contracts and models should come from `apps/shared`, while reusable design tokens and lightweight UI primitives can come from `apps/core`.

The future product scope has two compact lanes: Workout controls and Nutrition quick actions. Nutrition stays limited to food or meal add, water add, today's summary, and later the next planned meal status; full food search, diary management, and Meal Plan editing stay on phone.

## Current scope

The current Wear app starts with a simple Samsung-style action list on the main screen:

- Workout Routine
- Workout This Week
- Add Food
- Add Water
- View Summary
- Nutrition
- Settings

Each item is currently a placeholder action. Detailed watch flows will be added later.

## Structure

```text
apps/wear/
├─ lib/
│  ├─ main.dart
│  ├─ wear_app.dart
│  └─ src/
│     └─ home/
│        └─ presentation/
│           ├─ model/
│           │  └─ wear_home_tile.dart
│           ├─ widgets/
│           │  └─ wear_action_tile.dart
│           └─ wear_home_screen.dart
├─ android/
│  └─ app/
│     └─ src/main/
│        ├─ AndroidManifest.xml
│        └─ kotlin/com/tnyx/wear/MainActivity.kt
├─ pubspec.yaml
└─ analysis_options.yaml
```

## Future Flutter Layers

When live watch features are added, keep them layered:

```text
apps/wear/lib/src/live_workout/
├─ domain/          # workout session, BPM, calories, elapsed time contracts
├─ data/            # local storage, phone sync adapters, sensor adapters
└─ presentation/    # watch screens, controls, live workout UI
```

```text
apps/wear/lib/src/nutrition/
├─ domain/          # food, water, and summary quick-action contracts
├─ data/            # pending action storage and phone sync adapters
└─ presentation/    # short food, water, summary, and next-meal views
```

Planned future areas:

- live workout tracking
- BPM sync
- calorie burn estimation
- local workout save
- phone-watch sync
- nutrition quick actions
- hydration quick actions
- today's nutrition summary
- next planned meal status after mobile Meal Plan is available
- settings and device permissions

## Validation

```powershell
cd G:\Tio-World\apps\wear
G:\dev\flutter-sdk\bin\flutter.bat --no-color pub get
G:\dev\flutter-sdk\bin\flutter.bat --no-color analyze
G:\dev\flutter-sdk\bin\flutter.bat --no-color build apk
```
