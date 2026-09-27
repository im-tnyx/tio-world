# Development Setup

Document Status: Canonical Live Doc
Last Verified: 2026-09-27
Owner: repository developer experience
Truth Boundary: Authoritative for repository developer setup and validation guidance; not production runtime configuration.

This guide explains how to set up `tio-world` locally.

## Required Tools

Install these first:

- Git
- Flutter SDK stable channel
- Dart SDK included with Flutter
- Android Studio
- Android SDK Platform Tools
- Xcode for iOS/watchOS work on macOS
- Supabase CLI for work on the active root `supabase/` workspace
- A future `services/api` runtime/toolchain only when a separately approved protected-service slice starts it
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

Supabase is the active Auth, data, RLS, Storage, migration, and approved server-function foundation. The root `supabase/` workspace is present in this checkout and contains project configuration, migrations, functions, and tests. Deployment secrets and privileged credentials remain outside tracked client configuration.

The separate protected service is a later upgrade for orchestration, advanced integrations, and long-running work when approved Supabase server functions are no longer the right boundary. Its canonical future application path is:

```text
services/api
```

A future `services/worker` process is reserved only for a real asynchronous/background workload. Neither future service path should be scaffolded until its first separately approved implementation slice.

Until then, server-only provider credentials and privileged operations stay in approved Supabase server functions. Select a future service runtime's validation commands only after that service implementation is authorized.

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
