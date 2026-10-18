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
**Review owner:** Pending independent review.
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-10-19; local and GitHub `main` both at `a69bc82443201c66c8d34e3c346db362cc2e450d` before branching.
**Branch:** `tnyx/ios-free-device-ui-testing`
**HEAD SHA:** `a69bc82443201c66c8d34e3c346db362cc2e450d`
**Observed working-tree state:** Clean before this task brief.
**Observed uncommitted/dirty files:** `.ai/tasks/README.md`, this task brief, `.github/workflows/ios-ui-build.yml`, `apps/app/README.md`, and `apps/app/ios/**`; all belong to this bounded slice.
**PR / tracker:** No dedicated GitHub or Linear issue found. Related but broader/deferred trackers: Linear `TNYX-126`, `TNYX-231`, and `TNYX-161`.
**Current implementation state:** Current Flutter-template iOS Runner, iOS 15 deployment target, local-only signing boundary, manual artifact workflow, and owner instructions are implemented. Hosted macOS compilation and device launch remain pending.
**Relevant execution surface:** `apps/app/ios`, manual GitHub Actions macOS build, Windows local signing/sideload instructions.
**Validation completed at SHA:** Uncommitted implementation worktree based on `a69bc82443201c66c8d34e3c346db362cc2e450d`: static native/project/workflow checks, 18 valid PNG asset signatures, whitespace/conflict scan, and `git diff --check` passed.
**Validation remaining:** Hosted manual macOS build, Xcode/CocoaPods resolution, downloaded artifact checksum/provenance inspection, local free signing, and physical-iPhone launch/UI smoke. Flutter analyze/tests did not run locally because the available Flutter SDK cannot write `G:\dev\flutter-sdk\bin\cache\libimobiledevice.stamp`; the SDK/cache was not modified.
**Current blocker:** Local Windows host cannot compile the iOS target, and its shared Flutter SDK cache is write-protected; hosted macOS and physical-device acceptance remain external validation gates.
**Open review finding IDs:** None.
**Next exact action:** Review the complete diff, then commit/push/open a PR only if separately authorized; after push, manually dispatch the macOS workflow and complete the local signing/device acceptance path.

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
- [x] Add required URL scheme and camera/photo purpose strings without enabling OAuth providers or entitlements.
- [x] Add manual unsigned profile build/package workflow with checksum/provenance and finite artifact retention.
- [x] Document Windows local-signing steps and capability limitations.
- [x] Run available local static validation and record macOS/device validation as pending where it cannot run.

## 6. Quality Review

### Validation Run

```text
PASS — static native/project/workflow contract check:
- `Info.plist` XML and required callback/permission keys present.
- Every AppIcon manifest reference resolves, and 18 generated PNG assets have valid PNG signatures.
- Runner and Podfile deployment target is iOS 15.0.
- No `DEVELOPMENT_TEAM`, provisioning profile, signing entitlement, secret, or Apple credential reference appears in the native project/workflow.
- Manual workflow contains only `contents: read`, `workflow_dispatch`, `--profile --no-codesign`, arm64 verification, checksum/provenance, Podfile resolution capture, and seven-day artifact retention.
- `git diff --check` and whitespace/conflict-marker scan pass.

BLOCKED LOCALLY — `flutter analyze --no-pub` could not start because the available Flutter SDK attempts to write `G:\dev\flutter-sdk\bin\cache\libimobiledevice.stamp`; shared SDK/cache state was preserved. No Xcode, CocoaPods, hosted workflow, signing, install, or device test has run.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

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

This first slice can prove compilation, local free signing, installation, launch, and reachable UI behavior. It cannot establish production signing, distribution, provider auth, HealthKit, push, associated domains, secure-storage durability, or complete authenticated product behavior without separate configuration and validation.

### Final Status

`REVIEW` — source/static boundary is ready for independent review; hosted macOS
build and physical-device acceptance are still required.
