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

## Move Routine R4 internal release-candidate opt-in (default OFF)

**Current source / backend (2026-10-24):** PR #674 is merged and the owner
applied R3 migration `20261024120000` to the linked hosted Supabase project.
Read-only verification recorded **70 applied migrations** and `authenticated`
EXECUTE for three protected Move / Create+Move / Full Undo RPCs. This supersedes
the older **69-migration / hosted EXECUTE-denied** checkpoints retained below
as historical isolated-QA notes. The Flutter production Move capability is
**still OFF in normal builds**.

R4 can now prepare an **explicitly opted-in internal build** that exposes the
existing owner-approved Move/Undo UI *without redesigning it*:

```powershell
Set-Location "G:\projects\Tio-World\apps\app"
& "G:\dev\flutter-sdk\bin\flutter.bat" run --profile --dart-define=TIO_MOVE_ROUTINE_RELEASE=true
```

Only run against an **approved QA account/device** with known disposable
Program/Routine records. This option can change workout records in the
configured Supabase project. It is **not** a secret, account allowlist,
server authorization control, remote kill switch, or approval to distribute
a public release; hosted RPC endpoints are already separately reachable by
eligible authenticated callers. A normal build with no define remains OFF.
The older `TIO_MOVE_ROUTINE_QA` and `TIO_MOVE_ROUTINE_UI_PREVIEW` options
remain debug-only and independent.

Before a production/staged rollout, collect actual hosted negative owner/
guest/cross-account HTTP evidence, run Move A→B / reverse Undo and atomic
Save & Move / full Undo on isolated consenting QA data, exercise UNKNOWN and
session switches, check Android/iOS devices, and obtain the owner's **final
UI acceptance and release approval**. Deferred independent human security
reviews remain listed in GitHub #675 for consolidated public-launch audit;
known serious security problems still require immediate action.

## Move Routine R5 hosted API authorization QA gate (NOT YET PASSED)

**Current hosted ACL, 2026-10-24 read-only:** project `oykupyiitspujzpwwvuj`
has **70 applied migrations**, latest `20261024120000_grant_move_routine_rpc_execute_to_authenticated`.
The three exact `move_user_workout_routine`,
`create_user_workout_program_and_move_routine`, and
`undo_create_user_workout_program_and_move_routine` RPCs are
`postgres`-owned `SECURITY DEFINER` with empty `search_path`.
All three have `authenticated EXECUTE=true`,
`anon=false`, and `service_role=false`. This is live API exposure
to signed-in permanent users even if the app feature flag is OFF.
The Supabase Security Advisor's [authenticated-callable SECURITY DEFINER warning](https://supabase.com/docs/guides/database/database-linter?lint=0029_authenticated_security_definer_function_executable)
requires evidence-based disposition, not suppression. SQL ACL checks do
**not** prove cross-owner, guest or JWT HTTP authorization behavior.

**QA prerequisites:** obtain separate authorization for any actual hosted
test writes and use ONLY consenting/disposable QA accounts A and B and
disposable Program/Routine records. Check the intended Supabase project and
the tested client build, isolate relevant record IDs, confirm no real account
or history is touched, and define a cleanup plan. Use test-account JWTs only
in a secured local process/session; never paste tokens, raw HTTP headers,
profile/health data or user identifiers into GitHub, Linear, logs or this
runbook. Use the client-safe publishable key; never test with a
`service_role` key as the client. A POST to these RPCs can commit a real
write even when it is intended as a negative test. Without the prerequisites,
**stop at read-only verification and record HTTP QA as NOT RUN**.

| Gate | Test principal and action | Expected result / evidence to record |
| --- | --- | --- |
| R5-N1 | Unauthenticated request to all three Move RPCs | No callable write; redacted HTTP status/error category and unchanged fixture IDs |
| R5-N2 | Anonymous Auth session, if supported, calls all three | Permanent-account guard denies all writes; no new Program or changed Routine |
| R5-N3 | Account B attempts to move A's Routine into B's Program | Owner authorization denies, exact Routine identity/revision and A/B memberships unchanged |
| R5-N4 | Account A attempts to move its Routine into B's Program | Destination owner check denies; no cross-account membership or leaked details |
| R5-N5 | A uses a stale revision, stale source, replayed mutation or conflicting operation | Revision/idempotency contract fails closed; no overwrite or duplicate created Program |
| R5-P1 | A moves its own disposable Routine A→B, then reverses via 5-second Undo | Confirm committed new owner Program, same Routine/Exercise/Set IDs and verified reverse, not just UI feedback |
| R5-P2 | A runs `Save & Move` into a new disposable Program, then full Undo | Verify one atomic new Program+same Routine, then server-confirmed restoration and conditional deletion of only that new, still-empty Program |
| R5-N6 | Switch account/login cycle or expire the Undo window, and exercise UNKNOWN/timeout on disposable fixtures | No stale-session action, no duplicate retry or false success; record actual final server state and UI behavior |

For each gate, retain **restricted** request/response classifications,
test environment, client/PR SHA, reversible fixture reference, before/after
owner-scoped row counts/IDs, and an explicit PASS/FAIL/NOT RUN result.
The table documents the **required tests**, not executed results.
Unexpected authorized cross-owner write or privilege bypass is an immediate
security stop and issue escalation, not a prelaunch human-review-debt deferral.
Use [#569](https://github.com/im-tnyx/tio-world/issues/569) for the
release gate, [#675](https://github.com/im-tnyx/tio-world/issues/675)
for deferred human review, and TNYX-40 / TNYX-126 for final public-launch
security and owner go/no-go. Android and iOS build/device/visual acceptance
are additional independent gates. No public Move release or default ON build
is authorized by this runbook.

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
Supabase CLI or a dedicated disposable staging project). At the historical Option A decision point, hosted Tio-world Move RPCs
were **EXECUTE-denied**; this permission hold was superseded by R3's
authenticated-only hosted grant migration on 2026-10-24 (**70** applied
migrations). Treat this section strictly as the **isolated local** lab
procedure, not a current hosted ACL report or instruction to undo hosted R3.
M5A and M5B Undo source are merged; #567 Program Delete remains separate.
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
   **Grant scope:** These two isolated-only grants cover existing-Program Move
   and Create+Move, not the separate M5B full-Undo RPC. Full-Undo actual-write QA
   requires separately reviewed isolated-only EXECUTE and rollback handling for
   `undo_create_user_workout_program_and_move_routine`; do not copy these
   grants into hosted Tio-world or mistake debug UI opt-in for authorization.
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

**Current hosted security prerequisite (supersedes historical denial):**
all three Move/Create+Move/full-Undo RPCs have `authenticated EXECUTE=true`
on hosted Tio-world after R3; `anon` and `service_role` remain denied.
Do not work around authorization with direct `UPDATE(program_id)`, a
service-role client, an ad hoc SQL grant, or a source-level production flag
change. Follow the unexecuted R5 hosted HTTP negative-path gate above
before any public rollout; do not mistake a client presentation flag for an
API deny boundary.

If `TIO_MOVE_ROUTINE_UI_PREVIEW=true` and `TIO_MOVE_ROUTINE_QA=true`
are both supplied, the preview takes precedence and performs **zero writes**.
Neither flag works in profile/release builds. Public Move release, hosted HTTP owner/guest authorization acceptance,
Android/iOS QA and #567 Program Delete remain separate gates. The three
authenticated-only grants are **already hosted**, not a future prerequisite. M5A and M5B full Undo
source are merged and the M5B migration/Undo RPC are hosted; none of that
activates production Move.

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

The manual **Tio Mobile QA Build** iOS job produces an **unsigned profile**
artifact with QA login configuration, which does not enable this debug-only
capability and does not prove installation on a physical iPhone. A signed,
authorized debug-device workflow,
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
