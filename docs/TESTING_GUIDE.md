# Testing Guide

Testing depth should match product risk.

## Test Pyramid

Prefer:

1. Pure unit tests for domain and calculation logic.
2. Controller/notifier tests for state transitions.
3. Widget tests for important UI behavior.
4. Integration tests for critical flows.
5. Manual device checks for watch flows.

## Flutter Mobile

For mobile changes:

```bash
cd apps/app
flutter analyze
flutter test
```

When integration tests exist:

```bash
flutter test integration_test
```

## Dart Packages

For package changes:

```bash
cd packages/<package-name>
dart analyze
dart test
```

When Melos is configured:

```bash
melos analyze
melos test
```

## Wear OS

For `apps/wear`, validate with Android Studio and the appropriate Gradle tasks once the Wear project exists.

Expected checks:

```bash
./gradlew :wear:assembleDebug
./gradlew :wear:testDebugUnitTest
```

Manual checks should include:

- real watch or emulator launch
- startup time sanity check
- workout start/pause/resume
- rest timer behavior
- sync state behavior
- screen readability on round display
- battery/background behavior where relevant

## Backend

For backend changes once introduced:

```bash
pnpm lint
pnpm test
```

## Docs Only

Docs-only changes do not require app builds, but should run:

```bash
git diff --check
```

## What To Test By Area

| Area | Minimum validation |
| :--- | :--- |
| README/docs | `git diff --check` |
| Flutter UI | `flutter analyze`, widget/manual check |
| Flutter state | controller/notifier unit tests |
| Workout engine | calculation unit tests |
| Nutrition engine | calculation unit tests |
| API client | mapping and error handling tests |
| Sync | queue and retry behavior tests |
| Wear OS | compile + manual watch/emulator check |
| Backend | lint + unit/integration tests |

## Definition Of Done

A change is ready when:

- it solves the stated problem
- ownership boundaries are respected
- validation was run or intentionally scoped out
- docs are updated if behavior or architecture changed
- no unrelated files are included
- no generated artifacts are committed
