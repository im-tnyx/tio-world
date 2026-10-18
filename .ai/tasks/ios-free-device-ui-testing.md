# iOS free physical-device UI testing foundation

**Status:** In progress
**Primary owner:** Flutter phone platform / repository CI
**Affected platforms:** iOS phone build tooling and GitHub Actions; existing Android runtime unchanged

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner supplied explicit `Go` on 2026-10-19 after the read-only audit and accepted the proposed single-PR first slice.
**Approved product/UI/data-shape boundaries:** Add the minimum iOS phone Runner and a manual unsigned profile-build workflow so a Windows owner can locally free-sign and sideload the artifact for UI testing.
**Explicit non-changes:** No Flutter screen/layout/theme change; no production signing, TestFlight, App Store, Apple Watch target, HealthKit, push, provider activation, Supabase change, secrets, certificate, provisioning profile, device registration, hosted deployment, or release-readiness claim.

## Active Handoff

**Planning owner:** Current Codex task, based on the owner-approved audit boundary.
**Implementation owner:** Current Codex task on `tnyx/ios-free-device-ui-testing`.
**Review owner:** Repository owner (`im-tnyx`) left a `COMMENTED` review on PR #608 that explicitly says `NOT APPROVED / HOLD`; two inline threads were open at the last live review query.
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-10-19; `origin/main` is `a69bc82443201c66c8d34e3c346db362cc2e450d` and is an ancestor of the task branch.
**Branch:** `tnyx/ios-free-device-ui-testing`
**HEAD SHA last fully audited before review remediation:** `2acc333d897470eb74b0470e15a699e6169a3b85`.
**Observed working-tree state:** Clean at audit start; this review is changing only the phone target-family setting and this handoff record.
**PR / tracker:** Draft PR [#608](https://github.com/im-tnyx/tio-world/pull/608) is open, `MERGEABLE` / `CLEAN`, ahead 1 / behind 0 before review remediation. No dedicated GitHub issue was found. The Linear connector is unavailable in this session, so current Mobile App project / `TNYX-126` state could not be re-read; the prior audit linked `TNYX-126` as broader release-readiness work and `TNYX-231` / `TNYX-161` as deferred auth-provider / watch work.
**Current implementation state:** iOS Runner and manual unsigned profile artifact workflow are present. Flutter CI passed at the last reviewed PR head; CI for the review-remediation commit must run after it is pushed. The iOS-specific macOS build, artifact inspection, signing, install, and device launch remain unverified. The Runner target is now restricted to iPhone, matching the approved phone-only scope.
**Relevant execution surface:** `apps/app/ios`, manual GitHub Actions macOS build, Windows local signing/sideload instructions.
**Validation completed at last reviewed SHA:** Exact-head PR #608 Flutter/Dart analysis and all Flutter test jobs passed; both attribution checks passed. Fresh local static checks confirmed valid Info.plist XML, all 22 asset catalog references resolve to 18 valid PNG files, all three Runner deployment targets are iOS 15.0, and workflow remains manual-only/profile/no-codesign with read-only contents permission and no signing secrets. Local Flutter 3.44.6 / Dart 3.12.2 is recorded in `bin/cache/flutter.version.json`; no local Xcode is available.
**Validation remaining:** CI for the remediation commit; an approved hosted macOS iOS build, Xcode/CocoaPods resolution, artifact SHA/provenance and recursive profile/credential inspection, local free signing, and physical-iPhone install/launch/UI smoke. The last reviewed Flutter CI head does not include a native iOS compile.
**Current blocker:** GitHub `workflow_dispatch` does not expose this workflow before its file is on the default branch. A pre-merge `pull_request` trigger would solve that but changes the owner-approved manual-only contract; no trigger change is authorized. Keep signing credentials outside GitHub and the repository.
**Open review finding IDs:** `IOS-001` P1 — pre-merge macOS build trigger decision, unresolved; `IOS-002` P2 — stale task handoff, corrected in this handoff update; `IOS-003` P2 — Xcode target included iPad despite the approved phone-only scope, corrected to iPhone-only.
**Next exact action:** Owner decision: approve a path-filtered `pull_request` build trigger for pre-merge macOS validation, or retain manual-only and move iOS build acceptance to a post-merge gate. Do not change the trigger or merge PR #608 before that decision.

## Global UI / Design-System Guardrail

This slice changes platform/build infrastructure only. It does not modify Flutter production UI, rendered values, reusable components, theme/token contracts, navigation, or product-visible screen behavior.

## 1. Discovery

### User Outcome

The owner can build a device-targeted Flutter iOS UI artifact on standard GitHub-hosted macOS, download it on Windows, sign it locally with a free Apple ID through a trusted sideloading tool, and launch it on a physical iPhone.

### Success Criteria

- `apps/app/ios` is a phone-only Flutter Runner compatible with current locked plugins.
- The native deployment target is iOS 15 or later.
- The custom callback `tio://login-callback` and camera/photo usage descriptions exist in the iOS app metadata.
- A manual, read-only-permission workflow creates an unsigned profile-mode `Payload/Runner.app` IPA container and provenance/checksum files without credentials.
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
- Workflow remains `workflow_dispatch`, `macos-15`, Flutter 3.44.6, profile/no-codesign, arm64 check, IPA container packaging, SHA-256/provenance, captured resolved `Podfile.lock`, read-only `contents`, and seven-day artifact retention.

BLOCKED — hosted native build/artifact validation:
- GitHub does not list the new workflow on `main`; the manual dispatch attempt returned `could not find any workflows named iOS UI Build`.
- No macOS/Xcode/CocoaPods build, IPA, checksum, provenance output, embedded-profile scan, local signing, install, or device test exists yet.
- Local Windows Flutter 3.44.6 / Dart 3.12.2 is installed, but the earlier local analyze attempt could not write `G:\dev\flutter-sdk\bin\cache\libimobiledevice.stamp`; shared SDK/cache state was preserved.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| IOS-001 | P1 | Open — owner decision required | Manual-only workflow cannot be dispatched before merge because the workflow file is absent from the default branch. Official GitHub docs confirm the default-branch requirement. | `2acc333d897470eb74b0470e15a699e6169a3b85` | Owner must approve a narrowly path-filtered `pull_request` trigger or accept post-merge native-build validation; no trigger edit is included. |
| IOS-002 | P2 | Addressed in this handoff update | Task brief incorrectly named base SHA as HEAD and still said no PR / no current CI. | `2acc333d897470eb74b0470e15a699e6169a3b85` | This brief now records PR #608, exact reviewed SHA, live CI and review state, validation gap, and next action. Resolve the inline thread after this update is pushed. |
| IOS-003 | P2 | Fixed in this review | Runner project enabled iPad family (`TARGETED_DEVICE_FAMILY = "1,2"`) despite the approved phone-only slice. | `2acc333d897470eb74b0470e15a699e6169a3b85` | All three Runner configurations are changed to iPhone family only and must be rechecked in the outgoing diff. |

### IOS-001 Owner Decision Gate

GitHub documents that `workflow_dispatch` only runs when its workflow file is
on the default branch. This file exists on PR #608 but not `main`, so this
manual-only workflow cannot produce pre-merge macOS evidence. The documented
`pull_request` event executes the workflow from the PR merge commit and is the
smallest pre-merge path; that would change the owner-approved manual-only
contract, so the following is a proposal only and is not implemented:

```yaml
on:
  workflow_dispatch:
  pull_request:
    branches: [main]
    paths:
      - .github/workflows/ios-ui-build.yml
      - apps/app/**
      - apps/core/**
      - apps/shared/**
      - apps/features/**
      - melos.yaml

permissions:
  contents: read
```

Keep the macOS build credential-free, retain `contents: read`, set
`actions/checkout` to `persist-credentials: false`, and do not use
`pull_request_target`. The repo is public; standard GitHub-hosted `macos-15`
runners are documented as free for public repos, while the live fork policy
requires approval for first-time contributors and the default workflow token is
read-only. A paths filter limits routine runner use to iOS-relevant changes.
References: [workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_dispatch),
[GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners),
[workflow security](https://docs.github.com/en/actions/reference/security/secure-use).

The alternative that preserves the currently approved trigger is to accept
that macOS build and artifact acceptance happen only after merge. That does
not meet the current pre-merge native-build review gate. Await the owner's
choice before changing triggers or moving the acceptance gate.

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
