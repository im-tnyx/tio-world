# iOS free physical-device UI testing foundation

**Status:** In progress
**Primary owner:** Flutter phone platform / repository CI
**Affected platforms:** iOS phone build tooling and GitHub Actions; existing Android runtime unchanged

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner supplied explicit `Go` on 2026-10-19 after the read-only audit and accepted the proposed single-PR first slice. In the follow-up request, owner explicitly authorized a credential-free, path-filtered `pull_request` trigger while preserving manual dispatch, plus a scoped build fix if hosted execution exposed a confirmed in-scope failure.
**Approved product/UI/data-shape boundaries:** Add the minimum iOS phone Runner and an unsigned profile-build workflow with manual dispatch and a narrowly path-filtered pre-merge trigger so a Windows owner can locally free-sign and sideload the artifact for UI testing.
**Explicit non-changes:** No Flutter screen/layout/theme change; no production signing, TestFlight, App Store, Apple Watch target, HealthKit, push, provider activation, Supabase change, secrets, certificate, provisioning profile, device registration, hosted deployment, or release-readiness claim.

## Active Handoff

**Planning owner:** Current Codex task, based on the owner-approved audit boundary.
**Implementation owner:** Current Codex task on `tnyx/ios-free-device-ui-testing`.
**Review owner:** Repository owner (`im-tnyx`) left a `COMMENTED` review on PR #608 that explicitly says `NOT APPROVED / HOLD`; IOS-001 remains open pending successful hosted macOS validation and updated review evidence.
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-10-19; after `git fetch --prune origin`, `origin/main` is `a69bc82443201c66c8d34e3c346db362cc2e450d`, is an ancestor of the task branch, and branch divergence is 2 ahead / 0 behind.
**Branch:** `tnyx/ios-free-device-ui-testing`
**HEAD SHA last audited before this remediation:** `9c89e5d138f8599645f2844196a84d4f74b50498`.
**Observed working-tree state at fresh audit:** Clean before remediation edits; only `.github/workflows/ios-ui-build.yml` and this task brief are in scope.
**PR / tracker:** Draft PR [#608](https://github.com/im-tnyx/tio-world/pull/608) is open at `9c89e5d138f8599645f2844196a84d4f74b50498`, `MERGEABLE`, ahead 3 / behind 0. No dedicated GitHub issue was found. No Linear connector is available in this session, so the live Mobile App project / `TNYX-126` state could not be re-read; the previous audit identified `TNYX-126` as broader release-readiness work and `TNYX-231` / `TNYX-161` as deferred auth-provider / watch work. This limitation must be reconciled with Linear when access is available.
**Current implementation state:** iOS Runner remains phone-only. The workflow preserves `workflow_dispatch`, adds the owner-approved path-filtered `pull_request` trigger, keeps read-only `contents` permission, and disables checkout credential persistence. At `9c89e5d1`, exact-head Flutter CI and attribution passed, but macOS iOS run [39160381592](https://github.com/im-tnyx/tio-world/actions/runs/39160381592) failed at Xcode build with `The sandbox is not in sync with the Podfile.lock`; no artifact was uploaded. The Flutter 3.44.6 log also showed Swift Package Manager integration being added before CocoaPods ran. A workflow-scoped opt-out of SwiftPM is now added to keep this first slice on its existing CocoaPods/Podfile.lock contract; its hosted result is pending. Signing, install, and device launch remain unverified.
**Relevant execution surface:** `apps/app/ios`, manual and path-filtered GitHub Actions macOS build, CocoaPods dependency resolution for this Flutter 3.44.6 Runner, Windows local signing/sideload instructions.
**Validation completed at last reviewed SHA:** At `9c89e5d1`, exact-head Flutter/Dart analysis, all Flutter test shards, and attribution passed. The first hosted macOS run exposed a CocoaPods sandbox/lockfile failure after Flutter 3.44.6 added SwiftPM integration. Local static checks previously confirmed valid `Info.plist`, all asset references, iOS 15 targets, iPhone-only target families, read-only permissions, and no signing credentials. Local Flutter 3.44.6 / Dart 3.12.2 is recorded in `bin/cache/flutter.version.json`; no local Xcode is available.
**Validation remaining:** Commit/push the CocoaPods/SwiftPM workflow workaround; verify exact-head Flutter CI and attribution; verify the `iOS UI Build` PR run succeeds; inspect artifact SHA/provenance, IPA contents/arm64, embedded profile absence, and credential absence; then hand off Windows free signing and physical-iPhone install/launch/UI smoke to the owner. The previously passing Flutter CI does not compile iOS.
**Current blocker:** Exact-head native build failed on mixed SwiftPM/CocoaPods state with a Podfile.lock sandbox mismatch. The workflow now disables Flutter SwiftPM for the ephemeral macOS build environment; confirm this exact fix with a rerun. Keep signing credentials outside GitHub and the repository.
**Open review finding IDs:** `IOS-001` P1 — trigger change passes dispatchability but remains open until successful hosted build and artifact evidence; `IOS-002` P2 — addressed and resolved/outdated on GitHub; `IOS-003` P2 — fixed to iPhone-only on the prior branch commit.
**Next exact action:** Run YAML/static checks and `git diff --check`, commit and push the two scoped files to PR #608, then inspect exact-head CI, the hosted iOS rerun, and its artifact. Do not merge.

## Global UI / Design-System Guardrail

This slice changes platform/build infrastructure only. It does not modify Flutter production UI, rendered values, reusable components, theme/token contracts, navigation, or product-visible screen behavior.

## 1. Discovery

### User Outcome

The owner can build a device-targeted Flutter iOS UI artifact on standard GitHub-hosted macOS, download it on Windows, sign it locally with a free Apple ID through a trusted sideloading tool, and launch it on a physical iPhone.

### Success Criteria

- `apps/app/ios` is a phone-only Flutter Runner compatible with current locked plugins.
- The native deployment target is iOS 15 or later.
- The custom callback `tio://login-callback` and camera/photo usage descriptions exist in the iOS app metadata.
- A manual and path-filtered pre-merge, read-only-permission workflow creates an unsigned profile-mode `Payload/Runner.app` IPA container and provenance/checksum files without credentials.
- Documentation identifies the exact local signing point, free-provisioning limits, bundle-ID rewriting risk, and UI-only validation boundary.
- Android, Watch, production auth/provider and release paths are untouched.

### Scope

- `apps/app/ios/**`
- `.github/workflows/ios-ui-build.yml`
- `apps/app/README.md`
- this task brief and task index
- `.gitignore` only if a narrow iOS generated-file rule is required

### Non-Goals

- Production distribution, Store submission, TestFlight, certificates, profiles, Apple Developer Program setup, Fastlane, or App Store Connect.
- Apple Watch/watchOS scaffolding.
- Enabling Apple/Google sign-in, HealthKit, push notifications, associated domains, universal links, or production Supabase configuration.
- A debug/JIT workflow, Windows-side iOS compilation, or device automation.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root and applicable task instructions, `apps/app`, Flutter/Melos config, existing workflows, platform docs/ADRs, auth/startup/runtime code, GitHub and Linear trackers.
- Existing pattern to follow: current Flutter 3.44.6 iOS application template plus repository CI conventions (`contents: read`, manual dispatch, toolchain evidence).
- Tests or validation already present: existing Flutter CI covers Dart/Flutter source; there is no iOS compile or physical-device lane.
- Runtime truth: `apps/app/ios` and `apps/watchos` were absent at the verified base; docs intend iOS phone support and separately defer native Apple Watch work.
- Tracker truth: `TNYX-126` owns production release readiness, `TNYX-231` defers provider activation, and `TNYX-161` prohibits Apple Watch scaffolding; none owns this narrow UI-test build lane.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Use profile AOT for the first device artifact | Approved | It launches standalone without a Flutter debugger and avoids release-mode runtime-config failure when no Supabase values are supplied. | Owner / implementation |
| Sign only on the Windows owner's machine | Approved | Free provisioning requires the owner's Apple ID/device relationship; credentials and profiles must never enter GitHub or the repository. | Owner / implementation |
| Keep the first acceptance unauthenticated/UI-only | Approved | Provider configuration and signed-bundle identity are separate deferred concerns. | Owner / implementation |
| Create a new dedicated tracker | Pending external authorization | A dedicated issue is still required for durable ownership, but this slice does not mutate GitHub or Linear without a separate instruction. | Owner |

## 4. Architecture Design

### Chosen Approach

```text
GitHub Actions standard macOS runner
  -> Flutter profile device .app without codesigning
  -> Payload/Runner.app packaged as unsigned .ipa
  -> checksum + source/toolchain provenance
  -> Windows download
  -> local free-Apple-ID signing and install
  -> physical iPhone UI smoke test
```

### Ownership and Data Flow

`apps/app/ios` owns only the iPhone Runner. `.github/workflows/ios-ui-build.yml` owns credential-free compilation and packaging. The Windows sideloading tool owns local provisioning/signing outside the repository. Existing Flutter runtime owns all rendered UI.

### Alternative Rejected

- Unsigned IPA direct installation: iOS rejects it; provisioning and signing must occur before device installation.
- TestFlight/App Store path: requires paid production infrastructure outside this UI-test need.
- Web target: absent today and does not validate native iOS rendering, permissions, secure storage, or device behavior.
- Apple Watch target: separate product/runtime owner and explicitly gated.

### Failure and Accessibility States

The workflow must fail if the device app is missing, its Mach-O slice is not `arm64`, packaging is invalid, or signing material is present. Device acceptance must cover safe areas, keyboard/input, scrolling/sheets/navigation, light/dark mode, text scaling and VoiceOver smoke behavior where reachable.

## 5. Implementation Plan

- [x] Add current-template iOS Runner with iOS 15 minimum and no explicit team/profile/signing credential.
- [x] Restrict the iOS Runner's supported device family to iPhone, consistent with `apps/app` phone ownership.
- [x] Add required URL scheme and camera/photo purpose strings without enabling OAuth providers or entitlements.
- [x] Add manual unsigned profile build/package workflow with checksum/provenance and finite artifact retention.
- [x] Document Windows local-signing steps and capability limitations.
- [x] Run available local static validation and record macOS/device validation as pending where it cannot run.

## 6. Quality Review

### Validation Run

```text
PASS — fresh exact-head GitHub CI for `2acc333d897470eb74b0470e15a699e6169a3b85`:
- Flutter/Dart analysis and all Flutter test jobs passed; both attribution checks passed.
- `git diff --check origin/main...HEAD` passed; parent ancestry is valid and the pre-remediation delta is one task commit / 45 scoped files.

PASS — fresh local static native checks:
- `Info.plist` parses as XML; callback scheme and camera/photo purpose keys are present.
- All 22 asset catalog references resolve to 18 PNG files with valid PNG signatures.
- Runner configurations use iOS 15.0; iPhone-only target family is now set in all three Runner configurations.
- `AppDelegate` uses `FlutterImplicitEngineDelegate` and registers generated plugins; `SceneDelegate` subclasses `FlutterSceneDelegate`.
- No explicit team ID, provisioning profile, signing entitlement, secret, or Apple credential appears in the app target/workflow. Xcode's generic `iPhone Developer` identity remains template configuration; the workflow passes `--no-codesign`.
- Workflow remains manual and path-filtered, `macos-15`, Flutter 3.44.6, profile/no-codesign, arm64 check, IPA container packaging, SHA-256/provenance, captured resolved `Podfile.lock`, read-only `contents`, and seven-day artifact retention.

BLOCKED — initial audit before the approved PR trigger was added:
- GitHub does not list the new workflow on `main`; the manual dispatch attempt returned `could not find any workflows named iOS UI Build`.
- Local Windows Flutter 3.44.6 / Dart 3.12.2 is installed, but the earlier local analyze attempt could not write `G:\dev\flutter-sdk\bin\cache\libimobiledevice.stamp`; shared SDK/cache state was preserved.
```

PASS — exact-head checks at `9c89e5d138f8599645f2844196a84d4f74b50498`:
- Flutter CI run [39160381437](https://github.com/im-tnyx/tio-world/actions/runs/39160381437) passed all analysis and test shards.
- Attribution guard run [39160380965](https://github.com/im-tnyx/tio-world/actions/runs/39160380965) passed.

FAIL — hosted iOS UI Build run [39160381592](https://github.com/im-tnyx/tio-world/actions/runs/39160381592):
- macOS 15, Flutter 3.44.6, Xcode toolchain recording, package resolution, and Xcode build invocation completed.
- Xcode failed with `The sandbox is not in sync with the Podfile.lock`; IPA packaging and upload were skipped.
- Flutter also logged automatic SwiftPM integration followed by CocoaPods execution. The workflow now explicitly disables SwiftPM on its ephemeral runner to keep dependency resolution consistent with the existing Podfile and required `Podfile.lock` artifact. This workaround is unverified until the next hosted run.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| IOS-001 | P1 | Trigger validated; build/artifact validation pending | Manual-only workflow could not be dispatched before merge because the workflow file is absent from the default branch. Owner approved the smallest credential-free, path-filtered `pull_request` trigger while retaining manual dispatch. The trigger ran on PR #608. | Finding at `643b95a8207b5f5251822b73704bb8b9125270b2`; triggered run at `9c89e5d138f8599645f2844196a84d4f74b50498` | Do not resolve until the exact PR head starts and passes the hosted macOS build and artifact checks; then reply with run and artifact evidence. |
| IOS-002 | P2 | Addressed; GitHub thread resolved/outdated | Task brief incorrectly named base SHA as HEAD and still said no PR / no current CI. | `2acc333d897470eb74b0470e15a699e6169a3b85` | This brief records the live PR, exact head, CI/review state, validation gap, and next action; the live review thread is resolved and outdated. |
| IOS-003 | P2 | Fixed and statically verified | Runner project enabled iPad family (`TARGETED_DEVICE_FAMILY = "1,2"`) despite the approved phone-only slice. | `2acc333d897470eb74b0470e15a699e6169a3b85` | All three Runner configurations now use iPhone-only target family; static check passed after the fix. |

### IOS-001 Trigger Decision And Validation Gate

GitHub documents that `workflow_dispatch` only runs when its workflow file is
on the default branch. This file exists on PR #608 but not `main`, so this
manual-only workflow cannot produce pre-merge macOS evidence. The owner
approved the smallest credential-free pre-merge path while retaining manual
dispatch. The workflow implements:

```yaml
on:
  workflow_dispatch:
  pull_request:
    branches:
      - main
    paths:
      - ".github/workflows/ios-ui-build.yml"
      - "apps/app/**"
      - "apps/core/**"
      - "apps/shared/**"
      - "apps/features/**"
      - "melos.yaml"

permissions:
  contents: read
```

The macOS build remains credential-free, keeps `contents: read`, sets
`actions/checkout` to `persist-credentials: false`, and does not use
`pull_request_target`. The repo is public; standard GitHub-hosted `macos-15`
runners are documented as free for public repos, while the live fork policy
requires approval for first-time contributors and the default workflow token is
read-only. A paths filter limits routine runner use to iOS-relevant changes.
References: [workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_dispatch),
[GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners),
[workflow security](https://docs.github.com/en/actions/reference/security/secure-use).

The trigger change is implemented but not yet validated. The owner still
performs Windows signing and physical-device acceptance; no Apple credentials
are entered into GitHub or this repository.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/ios-free-device-ui-testing.md`
- `.ai/tasks/README.md`
- `.github/workflows/ios-ui-build.yml`
- `apps/app/README.md`
- `apps/app/ios/**`

### Actual Behavior

The repository now contains a phone-only iOS Runner at `apps/app/ios` with
the existing `com.tnyx.tio` application identifier, iOS 15 minimum, the
`tio://login-callback` scheme, and camera/photo-library purpose strings. It has
no team ID, provisioning profile, entitlement file, certificate, or production
signing credential. Its generated icon/launch PNG renditions use the
existing Tio brand asset.

The manual `iOS UI Build` workflow builds an unsigned profile-mode iPhone app,
checks for an arm64 Runner without an embedded provisioning profile, packages
`Payload/Runner.app` as an IPA, and uploads the IPA with checksum, toolchain
provenance and resolved `Podfile.lock`. The Windows signer remains the only
place where free Apple-ID credentials and provisioning occur.

### Known Limitations

This first slice is not yet proven to compile as an iOS app. After a successful hosted build, local free signing, installation, launch, and reachable UI behavior can be tested. This cannot establish production signing, distribution, provider auth, HealthKit, push, associated domains, secure-storage durability, or complete authenticated product behavior without separate configuration and validation.

### Final Status

`REVIEW` — Flutter CI passes at the last reviewed head and confirmed scoped
handoff/config findings are addressed in this branch update. CI for the new
head and native build evidence remain pending; the native build path depends on
the owner's workflow-trigger decision. Physical-device acceptance remains
pending.
