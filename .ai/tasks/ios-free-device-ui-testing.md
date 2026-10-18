# iOS free physical-device UI testing foundation

**Status:** In progress
**Primary owner:** Flutter phone platform / repository CI
**Affected platforms:** iOS phone build tooling and GitHub Actions; existing Android runtime unchanged

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner supplied explicit `Go` on 2026-10-19 after the read-only audit and accepted the first slice. The later temporary approval for a credential-free `pull_request` trigger is superseded by the latest owner decision: the iOS workflow must be strictly manual-only. The already-started run at `8514ac5c2837c7f2f95b712fd8496f191b67bbe5` may finish once; no future automatic iOS runs are authorized.
**Approved product/UI/data-shape boundaries:** Add the minimum iOS phone Runner and a credential-free, unsigned profile-build workflow triggered only by `workflow_dispatch`, so a Windows owner can locally free-sign and sideload the artifact for UI testing. Resolve pre-merge dispatch through a separately reviewed one-file workflow bootstrap PR; do not add automatic triggers.
**Explicit non-changes:** No Flutter screen/layout/theme change; no production signing, TestFlight, App Store, Apple Watch target, HealthKit, push, provider activation, Supabase change, secrets, certificate, provisioning profile, device registration, hosted deployment, or release-readiness claim.

## Active Handoff

**Planning owner:** Current Codex task, based on the owner-approved audit boundary.
**Implementation owner:** Current Codex task on `tnyx/ios-free-device-ui-testing`.
**Review owner:** Repository owner (`im-tnyx`) left a `COMMENTED` review on PR #608 that explicitly says `NOT APPROVED / HOLD`; IOS-001 remains open pending bootstrap/dispatch and exact-HEAD hosted macOS evidence.
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified before this handoff update:** 2026-10-19; `origin/main` is `a69bc82443201c66c8d34e3c346db362cc2e450d`, an ancestor of PR head `022bffec77ab2575e10d97b6146c5d9102427d8c`; divergence is 0 behind / 6 ahead.
**Branch:** `tnyx/ios-free-device-ui-testing`
**HEAD SHA last audited before this handoff update:** `022bffec77ab2575e10d97b6146c5d9102427d8c`; the remote branch workflow is manual-only and the working tree was clean.
**Observed working-tree state:** Clean at `022bffec`; this handoff update records that verified state.
**PR / tracker:** Draft PR [#608](https://github.com/im-tnyx/tio-world/pull/608) is open at `022bffec77ab2575e10d97b6146c5d9102427d8c`, `MERGEABLE`, ahead 6 / behind 0; review decision is empty and P1 `IOS-001` remains open. The owner review is `COMMENTED` and explicitly `NOT APPROVED / HOLD`. No dedicated GitHub issue was found; issue search returned only unrelated #342. No Linear connector is available in this session, so the live Mobile App project / `TNYX-126` state could not be re-read; prior audit notes identified `TNYX-126` as broader release-readiness work. Reconcile Linear when access is available.
**Current implementation state:** iOS Runner remains phone-only. The pushed workflow has only `workflow_dispatch`, `contents: read`, `macos-15`, checkout `persist-credentials: false`, and no Apple signing credentials. The one-time authorized run [39161809889](https://github.com/im-tnyx/tio-world/actions/runs/39161809889) passed at source HEAD `8514ac5c2837c7f2f95b712fd8496f191b67bbe5`; its artifact passed checksum (`2e461cce4920ab0a82b691114a71424974ac7218e0dd65ea9f4f512ad2898432`), `Podfile.lock`, IPA structure, arm64 Mach-O, and absence of embedded provisioning/signing material. It used the then-authorized `pull_request` trigger and is not manual-dispatch proof. No automatic iOS run was created after restoring the trigger.
**Relevant execution surface:** `apps/app/ios`, manual GitHub Actions macOS build, CocoaPods dependency resolution for this Flutter 3.44.6 Runner, Windows local signing/sideload instructions.
**Validation completed:** Flutter CI and attribution passed at `022bffec` (Flutter CI run [39162581162](https://github.com/im-tnyx/tio-world/actions/runs/39162581162), attribution run [39162579349](https://github.com/im-tnyx/tio-world/actions/runs/39162579349)). The one-time iOS build/artifact at source `8514ac5c` passed as recorded below. Manual-only YAML contract and `git diff --check` passed locally. At `06ab9564`, the older artifact had incorrect provenance and is historical only. Local static checks previously confirmed valid `Info.plist`, all asset references, iOS 15 targets, iPhone-only target families, and no signing credentials. Local Flutter 3.44.6 / Dart 3.12.2 is recorded in `bin/cache/flutter.version.json`; no local Xcode is available.
**Validation remaining:** Manually dispatch on `tnyx/ios-free-device-ui-testing` after the workflow bootstrap is approved/merged; then prepare the Windows AltServer handoff and wait for physical-iPhone smoke evidence. The one-time run at `8514ac5c` passed the native build and artifact checks but is not a `workflow_dispatch` run and predates restoring the required manual-only trigger.
**Current blocker:** `workflow_dispatch` is unavailable until this workflow file exists on the default branch. The older artifact at `06ab9564` has incorrect source provenance; the `8514ac5c` artifact has verified provenance and structure but is not manual-dispatch evidence. Keep signing credentials outside GitHub and the repository.
**Open review finding IDs:** `IOS-001` P1 — dispatch bootstrap and exact-head native evidence pending; `IOS-002` P2 — addressed/resolved on GitHub; `IOS-003` P2 — fixed to iPhone-only.
**Next exact action:** Owner authorizes creation of a separate bootstrap PR containing only a byte-identical copy of `.github/workflows/ios-ui-build.yml` with `workflow_dispatch` only. After that PR passes its own approval gate and is merged by explicit owner authorization, select `tnyx/ios-free-device-ui-testing` in the Actions branch dropdown and manually dispatch `iOS UI Build`. Keep P1 open until that manual run and physical-iPhone smoke evidence are complete. Do not merge PR #608 without explicit `Go merge`.

## Global UI / Design-System Guardrail

This slice changes platform/build infrastructure only. It does not modify Flutter production UI, rendered values, reusable components, theme/token contracts, navigation, or product-visible screen behavior.

## 1. Discovery

### User Outcome

The owner can build a device-targeted Flutter iOS UI artifact on standard GitHub-hosted macOS, download it on Windows, sign it locally with a free Apple ID through a trusted sideloading tool, and launch it on a physical iPhone.

### Success Criteria

- `apps/app/ios` is a phone-only Flutter Runner compatible with current locked plugins.
- The native deployment target is iOS 15 or later.
- The custom callback `tio://login-callback` and camera/photo usage descriptions exist in the iOS app metadata.
- A manual-only, read-only-permission workflow creates an unsigned profile-mode `Payload/Runner.app` IPA container and provenance/checksum files without credentials.
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
- Workflow uses `macos-15`, Flutter 3.44.6, profile/no-codesign, arm64 check, IPA container packaging, SHA-256/provenance, captured resolved `Podfile.lock`, read-only `contents`, seven-day artifact retention, and checkout credential persistence disabled. The temporary path-filtered `pull_request` trigger is being removed per the superseding owner decision.

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

PASS — hosted iOS UI Build run [39161024536](https://github.com/im-tnyx/tio-world/actions/runs/39161024536) at PR head `06ab95643eb6c40a95c141ddb6693069d5e902a7`:
- Flutter CI [39161024526](https://github.com/im-tnyx/tio-world/actions/runs/39161024526) and attribution [39161024635](https://github.com/im-tnyx/tio-world/actions/runs/39161024635) passed.
- Flutter 3.44.6 CocoaPods-only device build completed; packaging and upload succeeded. The arm64 and embedded-profile checks in the workflow passed.
- Artifact `tio-ios-unsigned-profile-2` (ID `12149265672`) has SHA-256 `bdf614abf058eb0fac875c6c6170dea4af6c63078b9380ffe2146af111c41c7d`; `Podfile.lock`, `Payload/Runner.app/Runner`, arm64 Mach-O, absence of `embedded.mobileprovision`, and absence of certificate/key/profile files all passed inspection. Its provenance `source_sha` was `20bab62c7de1ad94cb1c84f58378f2a36a402f7f` (the PR merge SHA) rather than PR source head `06ab95643eb6c40a95c141ddb6693069d5e902a7`; therefore provenance verification failed and this artifact is not accepted as final evidence. The workflow now writes PR head as `source_sha` and `GITHUB_SHA` as `build_sha`. Re-run and re-verify before resolving IOS-001.

PASS — one-time owner-authorized iOS UI Build run [39161809889](https://github.com/im-tnyx/tio-world/actions/runs/39161809889) at PR source `8514ac5c2837c7f2f95b712fd8496f191b67bbe5`:
- macOS 15 / Xcode 16.4 / Flutter 3.44.6 profile device compilation, arm64 check, unsigned IPA packaging, checksum/provenance creation, and artifact upload passed.
- Artifact `tio-ios-unsigned-profile-3` (ID `12148764473`) SHA-256: `2e461cce4920ab0a82b691114a71424974ac7218e0dd65ea9f4f512ad2898432`; provenance records `source_sha=8514ac5c2837c7f2f95b712fd8496f191b67bbe5`, `build_sha=4a2e523adff170a9ae695c34b33b961433e1ec87`, `event=pull_request`, and `signing=none`.
- Inspection passed: `Podfile.lock` (7,005 bytes), `Payload/Runner.app/Runner`, arm64 Mach-O, no embedded mobile provisioning profile, and no certificate/private-key/signing profile files. This was the one already-running automatic build the owner allowed to finish; it is not evidence of a manual dispatch.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| IOS-001 | P1 | Bootstrap/manual dispatch pending | Manual-only workflow cannot be dispatched until it exists on the default branch. A temporary path-filtered `pull_request` trigger was later authorized and validated once, but the owner superseded that decision and restored manual-only execution. The one-time `8514ac5c` build and artifact passed; manual dispatch on the current trigger contract has not run. | Finding at `643b95a8207b5f5251822b73704bb8b9125270b`; temporary trigger at `9c89e5d138f8599645f2844196a84d4f74b50498`; one-time build at `8514ac5c2837c7f2f95b712fd8496f191b67bbe5` | Use an independently reviewed, one-file bootstrap PR; after it is merged, select this PR branch in the Actions branch dropdown and manually dispatch. Keep this finding open until manual exact-head artifact validation. |
| IOS-002 | P2 | Addressed; GitHub thread resolved/outdated | Task brief incorrectly named base SHA as HEAD and still said no PR / no current CI. | `2acc333d897470eb74b0470e15a699e6169a3b85` | This brief records the live PR, exact head, CI/review state, validation gap, and next action; the live review thread is resolved and outdated. |
| IOS-003 | P2 | Fixed and statically verified | Runner project enabled iPad family (`TARGETED_DEVICE_FAMILY = "1,2"`) despite the approved phone-only slice. | `2acc333d897470eb74b0470e15a699e6169a3b85` | All three Runner configurations now use iPhone-only target family; static check passed after the fix. |

### IOS-001 Trigger Decision And Validation Gate

GitHub requires a `workflow_dispatch` workflow to exist on the default branch
before the Run workflow control is available. The owner requires strict
manual-only execution; the temporary path-filtered `pull_request` trigger
shown below is historical and has been superseded. Recommended resolution is
a separate, one-file bootstrap PR that adds byte-identical workflow content to
`main`, followed by a manual dispatch against the PR #608 branch. This keeps
all macOS execution opt-in and avoids parallel workflow definitions.

```yaml
on:
  workflow_dispatch:

permissions:
  contents: read
```

The macOS build remains credential-free, keeps `contents: read`, sets
`actions/checkout` to `persist-credentials: false`, and does not use
`pull_request_target`. GitHub documents that the workflow file must be on the
default branch and allows selecting another branch for a manual run. No
bootstrap PR has been created or merged.
References: [workflow events](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows#workflow_dispatch),
[GitHub-hosted runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners),
[workflow security](https://docs.github.com/en/actions/reference/security/secure-use).

The temporary automatic run has been authorized to finish once. After it
completes, the workflow will again be manual-only. The owner still performs
Windows signing and physical-device acceptance; no Apple credentials are
entered into GitHub or this repository.

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

Earlier hosted execution proved a Flutter iOS profile build and unsigned IPA packaging at `06ab9564`, but not the current provenance fix or current exact HEAD. After the one-time `8514ac5c` run passes artifact verification and the bootstrap workflow is merged through its own approval gate, the owner can manually rebuild this PR branch and locally free-sign/install it. Physical launch and reachable UI behavior remain unverified. This cannot establish production signing, distribution, provider auth, HealthKit, push, associated domains, secure-storage durability, or complete authenticated product behavior without separate configuration and validation.

### Final Status

`REVIEW` — PR #608 is open and mergeable but has no approval. Flutter CI and
the one-time macOS build/artifact checks passed. The bootstrap PR, manual
branch dispatch under the manual-only workflow, Windows AltServer
signing/install, and physical-iPhone smoke evidence remain pending. Do not
merge without explicit owner authorization.
