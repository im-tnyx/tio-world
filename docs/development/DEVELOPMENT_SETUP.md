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

## Move Routine debug UI preview (opt-in)

The #569 Move Routine flow is intentionally release-OFF until protected backend
capabilities and full mutation/refresh gates have passed. For **visual QA only**,
the phone app can opt into the existing Routine action/Program destination
sheets on a **debug build**. This debug-only option is disabled by default and
cannot be enabled in profile/release builds, even if a define is supplied.

```bash
cd apps/app
flutter build apk --debug --dart-define=TIO_MOVE_ROUTINE_UI_PREVIEW=true
```

Use your existing approved local Supabase runtime configuration when building.
**Do not check credentials or APK outputs into the repository.** Install the
resulting debug APK on the test device using your normal Android tooling.

Only signed-in, verified owners of persisted Routines can open the existing
selector; it uses owner-scoped Program reads. The existing/new Program
confirmation UI is preview-only: **neither Move nor Create+Move writes run,
no new Program is saved, and the Routine stays in its original Program**.
The UI reports that no change was made. Clearing the define restores the
default hidden action. This opt-in does not turn on
`routineMoveReleaseEnabledProvider`, Supabase RPC grants, or production Move.

## Move Routine real-write debug QA (isolated environment, not released)

The #569 existing-Program Move and atomic Create & Move implementation can
be exercised in an explicitly opted-in **debug** app without enabling the
production `routineMoveReleaseEnabledProvider`. This is **not** the
zero-write preview above. A confirmed QA action uses the existing live,
owner-bound Move RPC adapter and **can change workout data if the
connected Supabase database has separately authorized EXECUTE**.

```bash
cd apps/app
flutter run --debug --dart-define=TIO_MOVE_ROUTINE_QA=true
```

**Architecture & Security Decision (Option A — Isolated QA Environment):**
Per explicit owner approval on 2026-10-23 (Option A), real-write QA for Move
Routine is restricted to **isolated Supabase environments** (local Docker-based
Supabase CLI or a dedicated disposable staging project). Hosted Tio-world
Move RPCs remain **EXECUTE-denied** (`authenticated = false`) to completely
prevent exposure to ordinary users before M5B full Create & Move Undo and
#567 Program Delete reparenting features are implemented and approved (M5A real five-second Undo for existing Program moves is merged in source via PR #661, while M5B full atomic Undo and #567 remain pending).
A Flutter debug flag is a client UI gate, **not** a database security boundary;
granting EXECUTE on hosted would expose PostgREST endpoints to all signed-in
accounts.

### Isolated Local Supabase QA Execution Runbook

1. **Start local Supabase runtime:**
   ```bash
   supabase start
   ```
2. **Apply the isolated Move RPC grant in the local container:**
   ```sql
   -- Run ONLY against isolated local/disposable QA database:
   grant execute on function public.move_user_workout_routine(
     uuid, uuid, uuid, bigint, uuid
   ) to authenticated;

   grant execute on function public.create_user_workout_program_and_move_routine(
     uuid, uuid, uuid, text, bigint, uuid
   ) to authenticated;
   ```
3. **Run debug app against local Supabase runtime:**
   Launch the app with local runtime configuration and `--dart-define=TIO_MOVE_ROUTINE_QA=true`.
   Verify A→B, B→A, new Program atomicity, cancel, idempotency/UNKNOWN, stale
   revision CAS, owner switch, cross-device races, and Program/Exercise/Set
   stability with isolated test accounts.
4. **Tested rollback / revoke procedure:**
   When testing concludes or to verify fail-closed behavior, execute:
   ```sql
   -- Tested revocation rollback:
   revoke execute on function public.move_user_workout_routine(
     uuid, uuid, uuid, bigint, uuid
   ) from authenticated;

   revoke execute on function public.create_user_workout_program_and_move_routine(
     uuid, uuid, uuid, text, bigint, uuid
   ) from authenticated;
   ```
   PostgREST immediately returns SQLSTATE `42501` (`insufficient_privilege`)
   to any subsequent Move attempt while routine/program records remain unharmed.

**Current hosted security prerequisite:** both Move RPCs remain EXECUTE-denied
to `authenticated` in hosted Tio-world. Do not work around it with direct
`UPDATE(program_id)`, a service-role client, an unreviewed SQL GRANT, or a
source-level production flag change. No deployable forward migration granting
broad authenticated EXECUTE will be added to `supabase/migrations/` without
a separate owner exposure decision.

If `TIO_MOVE_ROUTINE_UI_PREVIEW=true` and `TIO_MOVE_ROUTINE_QA=true`
are both supplied, the preview takes precedence and performs **zero writes**.
Neither flag works in profile/release builds. Production Move release, M5B full Create & Move Undo,
and #567 Program Delete remain separate review/release gates (M5A existing-Program Undo is merged in source via PR #661).

## First-Routine debug-only hosted QA (opt-in, REAL writes)

The #568 direct Library **Create Routine** uses the existing canonical composer
and owner/login-cycle-bound atomic `create_user_workout_routine_in_my_program`
RPC. The hosted RPC is now `authenticated EXECUTE=true` for eligible permanent
accounts, but **production is not released**. An explicit **debug-only** build
opt-in exposes this flow for separately approved QA with dedicated consenting
test accounts; unlike the Move preview above, **Save here can write to the
connected Supabase project**. Cancel before Save still performs zero writes.

```bash
cd apps/app
flutter run --debug --dart-define=TIO_FIRST_ROUTINE_QA=true
```

Supply the already governed local QA Supabase runtime configuration separately.
Keep secrets and testers' credentials out of Git, CLI logs and artifacts. Only
distribute the debug build to authorized testers. Removing the define or running
profile/release makes this QA-only UI capability false; the independent
`myProgramRoutineCreateReleaseEnabledProvider` remains hard false. On a
signed-in debug QA build, bootstrap owner, Auth login-cycle, SDK current user,
repository and pending-UNKNOWN gates still apply. A compile-time flag is **NOT**
server authorization, a tester allowlist, a permission kill switch, or proof
of a staging backend. The hosted RPC remains directly callable by eligible
permanent accounts. Do not point a QA build at real users' data.

The checked-in iOS GitHub workflow currently produces an **unsigned profile**
artifact, which does not enable this debug-only capability and does not prove
installation on a physical iPhone. A signed, authorized debug-device workflow,
test-account consent, actual-write Android/iOS evidence, A/B isolation, race,
UNKNOWN readback and rollback review remain separate pre-release gates.
Do not enable #569 Move permissions or confuse its zero-write preview with
this actual-write first-Routine QA path.

## Flutter Feature Packages

Feature packages live in:

```text
apps/features/<feature>
```

Examples:

```text
apps/features/account_setup
apps/features/auth
apps/features/coaching
apps/features/home
apps/features/nutrition
apps/features/onboarding
apps/features/profile
apps/features/progress
apps/features/settings
apps/features/splash
apps/features/welcome
apps/features/workout
```

For a focused feature check:

```bash
cd apps/features/workout
flutter analyze
flutter test
```

These feature packages use Flutter SDK / `flutter_test`; use `dart analyze` / `dart test` only for packages intentionally classified as non-Flutter (`--no-flutter`) by the workspace.

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
flutter analyze
flutter test
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
