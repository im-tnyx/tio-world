# Flutter CI Foundation

**Status:** In progress
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
- Workspace bootstrap uses Melos.
- Workflow has read-only repository permissions and no production secrets.
- First GitHub run is inspected and any pre-existing failures are reported rather than hidden.

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
- Theme/token source changes before CI baseline is understood.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `AGENTS.md`, `docs/DEVELOPMENT_SETUP.md`, `melos.yaml`, root `pubspec.yaml`, `apps/shared/pubspec.yaml`, `.github/`.
- Existing pattern to follow: repository validation prefers Melos for monorepo changes.
- `.github/` currently has no `workflows/` directory.
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
| Pin Melos CLI version in CI | Made | Avoid CI behavior changing on every Melos release | Architecture |
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
Melos bootstrap
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

Running `melos test` unchanged was rejected for the first CI baseline because its current script executes `flutter test` for every package with a `test` directory while the workspace contains at least one pure-Dart package.

### Failure and Accessibility States

- CI failure must remain visible; no `continue-on-error` for analyze/tests.
- A pre-existing failing package is evidence to triage, not a reason to hide the job.
- No credentials are required for this quality gate.

## 5. Implementation Plan

- [x] Audit existing GitHub workflow state.
- [x] Verify monorepo package/test command split.
- [ ] Add `.github/workflows/flutter-ci.yml`.
- [ ] Verify committed YAML content.
- [ ] Inspect first GitHub Actions run.
- [ ] Record first-run result and any pre-existing failures.
- [ ] After CI baseline is understood, start #6 design-token inventory/refactor slice.

## 6. Quality Review

### Validation Run

```text
Not run yet. GitHub Actions first run is pending workflow commit.
```

### Review Findings and Resolution

- Initial CI intentionally avoids build/signing and production secrets.
- Flutter SDK is stable-channel rather than exact-version pinned because the repository currently documents `stable` and has no checked-in Flutter version file. Exact SDK pinning is a follow-up toolchain decision.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/flutter-ci-foundation.md`
- `.github/workflows/flutter-ci.yml` (planned)

### Actual Behavior

Pending first workflow run.

### Known Limitations

- No Android/iOS build artifact validation yet.
- No integration/device tests yet.
- Stable-channel Flutter can move over time until the repo adopts an exact SDK pin.

### Final Status

`PARTIAL`
