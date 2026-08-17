# Flutter CI Foundation

**Status:** In progress — workflow active; legacy-workspace bootstrap run in progress
**Primary owner:** apps/core / repository CI
**Affected platforms:** Flutter phone app, Wear OS Flutter app, shared/core/features packages
**Tracking:** GitHub issue #6, Slice 0 before design-token implementation

## 1. Discovery

### User Outcome

Every push/PR can be checked on GitHub without relying only on a local machine. Theme/token refactors should receive an automatic analyze/test signal before review.

### Success Criteria

- GitHub Actions workflow exists under `.github/workflows/`.
- Workflow runs on pushes to `codex/onboarding-mode-migration` and `main`, PRs targeting `main`, and manual dispatch.
- Flutter packages use `flutter analyze` / `flutter test`.
- Pure Dart packages use `dart analyze` / `dart test`.
- Workspace bootstrap uses the Melos version compatible with the checked-in workspace format.
- Workflow has read-only repository permissions and no production secrets.
- First complete GitHub baseline reaches analyze/tests and any pre-existing failures are reported rather than hidden.

### Scope

- CI quality gate only: bootstrap, analyze, unit/widget tests.
- Use the repository's stable-channel Flutter convention.
- Keep the workflow monorepo-aware.

### Non-Goals

- Android APK/AAB build or signing.
- iOS archive/TestFlight.
- Supabase migrations or production secrets.
- Integration/emulator/device tests.
- Branch-protection changes in this slice.
- Melos Pub Workspace migration in this slice.
- Theme/token source changes before CI baseline is understood.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `AGENTS.md`, `docs/DEVELOPMENT_SETUP.md`, `melos.yaml`, root `pubspec.yaml`, `apps/shared/pubspec.yaml`, `.github/`.
- Existing pattern to follow: repository validation prefers Melos for monorepo changes.
- `.github/` had no workflow before this slice.
- `melos.yaml` uses the legacy workspace format with explicit package globs.
- Root `pubspec.yaml` does not declare a local `melos` dev dependency and does not use Dart Pub Workspaces.
- `melos.yaml` currently exposes a generic `test` script using `flutter test` for every package with a test directory.
- `apps/shared` is a pure Dart package, so CI must not blindly use the generic Flutter-only test command for every package.
- Melos supports `--flutter`, `--no-flutter`, and `--dir-exists` package filters.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Add CI before #6 token refactor | Made | Establish a remote green/red baseline before cross-package design-system edits | Project |
| Separate Flutter and pure-Dart validation | Made | Workspace contains both package types | Architecture |
| Use Flutter stable channel initially | Made | Matches checked-in development setup; exact SDK pin can be a follow-up | Project |
| Use Melos 2.9.0 for this baseline | Made | Current repo still uses legacy `melos.yaml` without local Melos dependency; newer Melos requires workspace migration | Architecture |
| Defer Melos 7+/Pub Workspace migration | Made | Cross-package toolchain migration is not required to start #6 safely | Architecture |
| Do not add build/signing jobs yet | Made | Analyze/test is the smallest useful quality gate and needs no secrets | Project |

## 4. Architecture Design

### Chosen Approach

```text
GitHub push / PR / manual dispatch
        ↓
checkout
        ↓
Flutter stable toolchain
        ↓
Melos 2.9.0 legacy workspace bootstrap
        ↓
Flutter packages: flutter analyze + flutter test
Pure Dart packages: dart analyze + dart test
        ↓
GitHub status check
```

### Ownership and Data Flow

```text
.github/workflows/flutter-ci.yml
        ↓
Melos package filtering
        ↓
apps/app + apps/wear + apps/core + apps/features/*
apps/shared and any future pure-Dart packages
```

### Alternative Rejected

- Running `melos test` unchanged was rejected because its current script executes `flutter test` for every package with a `test` directory while the workspace contains at least one pure-Dart package.
- Melos 8.2.2 was rejected for this baseline because current Melos 7+ expects Dart Pub Workspaces in root `pubspec.yaml`, while this repository still uses `melos.yaml`.
- Melos 6.3.3 was rejected for this baseline because Melos 3+ requires a local Melos dependency next to `melos.yaml`; the root package does not currently declare one.

### Failure and Accessibility States

- CI failure must remain visible; no `continue-on-error` for analyze/tests.
- A pre-existing failing package is evidence to triage, not a reason to hide the job.
- No credentials are required for this quality gate.

## 5. Implementation Plan

- [x] Audit existing GitHub workflow state.
- [x] Verify monorepo package/test command split.
- [x] Add `.github/workflows/flutter-ci.yml`.
- [x] Verify committed YAML content.
- [x] Inspect initial GitHub Actions runs.
- [x] Diagnose Melos 8 workspace-format mismatch.
- [x] Diagnose Melos 6 local-dependency requirement.
- [x] Switch baseline workflow to Melos 2.9.0 for the current checked-in workspace format.
- [ ] Confirm legacy-workspace bootstrap completes on GitHub.
- [ ] Confirm Flutter/Dart analyze steps execute.
- [ ] Confirm Flutter/Dart test steps execute.
- [ ] Record final baseline result and any pre-existing package failures.
- [ ] After CI baseline is understood, start #6 design-token inventory/refactor slice.

## 6. Quality Review

### Validation Run

```text
GitHub Actions run #1 / commit f4e14a2
- checkout: PASS
- Flutter stable install: PASS
- Melos 8.2.2 install: PASS
- bootstrap: FAIL
- reason: Melos 7+ no longer treats legacy melos.yaml as current workspace config

GitHub Actions run #3 / commit b1917ff
- checkout: PASS
- Flutter stable install: PASS
- Melos 6.3.3 install: PASS
- bootstrap: FAIL
- reason: Melos 3+ requires local Melos dependency in root pubspec next to melos.yaml

GitHub Actions run #5 / commit aebd18a
- checkout: PASS
- Flutter stable install: PASS
- Flutter version observed: 3.47.0 / Dart 3.13.0
- Melos 2.9.0 install: PASS
- bootstrap: IN PROGRESS at latest inspection
```

### Review Findings and Resolution

- Initial CI intentionally avoids build/signing and production secrets.
- Flutter SDK is stable-channel rather than exact-version pinned because the repository currently documents `stable` and has no checked-in Flutter version file. Exact SDK pinning is a follow-up toolchain decision.
- The repository's Melos configuration is legacy relative to current Melos. CI is deliberately matching the repository instead of silently forcing a monorepo migration into the design-system slice.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/flutter-ci-foundation.md`
- `.github/workflows/flutter-ci.yml`

### Actual Behavior

- GitHub automatically starts `Flutter CI` on pushes to the working branch and main, PRs targeting main, and manual dispatch.
- Current baseline separates Flutter and pure-Dart analyze/test commands.
- Third bootstrap attempt is using Melos 2.9.0, compatible with the repository's legacy workspace model.

### Known Limitations

- First complete analyze/test baseline is still pending.
- No Android/iOS build artifact validation yet.
- No integration/device tests yet.
- Stable-channel Flutter can move over time until the repo adopts an exact SDK pin.
- Melos workspace modernization remains a separate future infrastructure task.

### Final Status

`PARTIAL`
