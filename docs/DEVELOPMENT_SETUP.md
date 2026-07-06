# Development Setup

This guide explains how to set up `tio-world` locally.

## Required Tools

Install these first:

- Git
- Flutter SDK stable channel
- Dart SDK included with Flutter
- Android Studio
- Android SDK Platform Tools
- Xcode for iOS/watchOS work on macOS
- Node.js LTS for backend and tooling
- pnpm
- Melos for Flutter/Dart monorepo management
- GitHub CLI optional but recommended

## Clone

```bash
git clone https://github.com/im-tnyx/tio-world.git
cd tio-world
```

## Flutter Workspace Setup

Check Flutter environment:

```bash
flutter doctor
```

Install Melos if needed:

```bash
dart pub global activate melos
```

From repo root after `pubspec.yaml` and `melos.yaml` are configured:

```bash
flutter pub get
melos bootstrap
```

## Flutter Mobile App

The Flutter phone app shell lives in:

```text
apps/app
```

Run commands from that folder when working only on the phone app:

```bash
cd apps/app
flutter pub get
flutter analyze
flutter test
flutter run
```

## Flutter Feature Packages

Feature packages live in:

```text
apps/features/<feature>
```

Examples:

```text
apps/features/workout
apps/features/nutrition
apps/features/onboarding
apps/features/auth
apps/features/profile
apps/features/settings
apps/features/progress
apps/features/coaching
```

For a focused feature check:

```bash
cd apps/features/workout
dart analyze
dart test
```

With Melos from repo root:

```bash
melos analyze
melos test
```

## Shared And Core Packages

Shared contracts and pure Dart logic live in:

```text
apps/shared
```

Flutter design system, reusable UI, route contracts, and shell components live in:

```text
apps/core
```

Validation:

```bash
cd apps/shared
dart analyze
dart test
```

```bash
cd apps/core
flutter analyze
flutter test
```

## Wear OS App

The native Wear OS app lives in:

```text
apps/wear
```

Use Android Studio for Wear OS development. Open the relevant Android project once the Wear app is generated.

Expected direction:

```text
Kotlin
Compose for Wear OS
Health Services API
Data Layer / phone sync
Tiles and complications when needed
```

## Backend

Backend workspace lives under:

```text
backend
```

When introduced, prefer:

```bash
pnpm install
pnpm lint
pnpm test
pnpm dev
```

Backend should own server-only secrets, AI orchestration, analytics jobs, database migrations, and protected integrations.

## Common Validation

For Flutter mobile app changes:

```bash
cd apps/app
flutter analyze
flutter test
```

For Flutter package changes:

```bash
cd apps/features/<feature>
dart analyze
dart test
```

For monorepo changes after Melos is configured:

```bash
melos bootstrap
melos analyze
melos test
```

For backend changes after backend is introduced:

```bash
pnpm lint
pnpm test
```

For docs-only changes:

```bash
git diff --check
```

## Windows Notes

PowerShell is fine. If a command is not recognized, check PATH first.

For ADB:

```powershell
& "G:\dev\android-sdk\platform-tools\adb.exe" version
```

If `adb` should be globally available, add this folder to Windows PATH:

```text
G:\dev\android-sdk\platform-tools
```

## Public Repo Safety

This repository is public. Before every commit, check:

```bash
git status -sb
git diff --stat
git diff --check
```

Do not commit local credentials, device logs containing private data, build outputs, APK/AAB files, IPA files, keystores, signing files, or local machine paths.
