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
- Supabase CLI when the first approved Auth/data/Storage slice begins
- A future backend runtime/toolchain only when the protected-backend upgrade is approved
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
flutter doctor --verbose
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
flutter pub outdated
flutter analyze
flutter test
flutter run
```

A healthy dependency check can still show older transitive packages when they are pinned by Flutter SDK or test package constraints. Focus on direct and dev dependencies first.

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

## Flutter Wear OS App

The Flutter Wear OS companion app lives in:

```text
apps/wear
```

Use Android Studio for Wear OS development and run Flutter validation from this package.

Current direction:

```text
Flutter
Riverpod
go_router
watch-first UI
shared contracts and lightweight design primitives where useful
```

## Supabase And Future Backend

Supabase is the planned Auth, data, RLS, and private Storage foundation. No Supabase workspace, project configuration, or credential is present in this checkout.

When the first approved slice requires it, the root Supabase workspace will be:

```text
supabase
```

The separate protected backend is a later upgrade. It will be used for Gemini/provider orchestration, advanced integrations, and long-running jobs—not initial Auth or database migrations.

The planned backend workspace will live under:

```text
backend
```

Select its toolchain and validation commands only when its first approved service slice is defined. Backend should own server-only Gemini/provider secrets, AI orchestration, analytics jobs, and protected integrations; Supabase owns the initial Auth/data/migration boundary.

## Common Validation

For Flutter mobile app changes:

```bash
cd apps/app
flutter pub get
flutter pub outdated
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

For protected backend changes after that workspace is introduced, run its documented validation commands. For Supabase changes, run the project-specific migration/RLS/security validation defined by the approved feature task.

For docs-only changes:

```bash
git diff --check
```

## Windows Notes

PowerShell is fine. If a command is not recognized, check PATH first.

Recommended PATH entries:

```text
<flutter-sdk>\bin
<android-sdk>\platform-tools
```

If `flutter doctor` says Flutter or Dart is not on PATH, add the Flutter SDK `bin` folder to the user PATH and restart the terminal or IDE.

If Android command-line tools are missing, install Android Studio command-line tools from Android Studio SDK Manager:

```text
Android Studio > Settings > Languages & Frameworks > Android SDK > SDK Tools > Android SDK Command-line Tools
```

Then accept Android licenses:

```bash
flutter doctor --android-licenses
```

Visual Studio is only required for Windows desktop builds. It is not required for Android, web, or basic Flutter package validation.

## Public Repo Safety

This repository is public. Before every commit, check:

```bash
git status -sb
git diff --stat
git diff --check
```

Do not commit local credentials, device logs containing private data, build outputs, APK/AAB files, IPA files, keystores, signing files, or local machine paths.
