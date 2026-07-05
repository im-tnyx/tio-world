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

## Flutter Setup

Check Flutter environment:

```bash
flutter doctor
```

From repo root:

```bash
flutter pub get
```

If Melos is configured:

```bash
dart pub global activate melos
melos bootstrap
```

## Mobile App

The Flutter mobile app lives in:

```text
apps/mobile
```

Run commands from that folder when working only on the app:

```bash
cd apps/mobile
flutter pub get
flutter analyze
flutter test
flutter run
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

Backend workspace will live under:

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

## Common Validation

For Flutter mobile changes:

```bash
cd apps/mobile
flutter analyze
flutter test
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
