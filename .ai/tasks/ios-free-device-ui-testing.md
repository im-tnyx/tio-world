# iOS free physical-device UI testing foundation

**Status:** In progress
**Primary owner:** Flutter phone platform / repository CI
**Affected platforms:** iOS phone build tooling and GitHub Actions; existing Android runtime unchanged

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner supplied explicit `Go` on 2026-10-19 for the initial UI-only slice, then supplied the pasted request on 2026-10-19 explicitly authorizing an optional authenticated Supabase QA build mode within PR #608. The latest owner execution contract keeps the iOS workflow strictly `workflow_dispatch` only; no future automatic iOS runs are authorized.
**Approved product/UI/data-shape boundaries:** Keep the phone-only Runner and unsigned profile artifact; add opt-in `ui_only` (default) and `qa_login` modes. The QA mode may compile only the QA Supabase HTTPS URL and client-safe publishable key from GitHub Actions repository secrets via a temporary runner-local config file. Read those secrets only in the `qa_login`-gated step. Preserve existing Supabase initialization, email/password auth, session repository and router guards. Use an existing QA account only after local iPhone installation. Keep the workflow manual-only and resolve pre-merge dispatch through a separately reviewed one-file workflow bootstrap PR; do not add automatic triggers.
**Explicit non-changes:** No Flutter screen/layout/theme change; no Supabase schema/RLS/Auth implementation or provider change; no production endpoint/config, secret/service-role key, Apple credentials, Google OAuth credentials, account password, production signing, TestFlight, App Store, Apple Watch target, HealthKit, push, certificate, provisioning profile, device registration, hosted deployment, or release-readiness claim. Do not claim authenticated login works until physical-device evidence exists.

## Active Handoff

**Planning owner:** Current Codex task, based on the owner-approved manual-only iOS and optional QA-login extension.
**Implementation owner:** Current Codex task on `tnyx/ios-free-device-ui-testing`.
**Review owner:** Repository owner (`im-tnyx`) left a `COMMENTED` review on PR #608 that explicitly says `NOT APPROVED / HOLD`; IOS-001 remains open pending bootstrap/dispatch and exact-HEAD hosted macOS evidence.
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified before this handoff update:** 2026-10-19; `origin/main` is `a69bc82443201c66c8d34e3c346db362cc2e450d`, an ancestor of current PR head `f991e928b9ccb2119b2ad3e7e4112a717d2caff8`; divergence is 0 behind / 7 ahead.
**Branch:** `tnyx/ios-free-device-ui-testing`
**HEAD SHA last audited before this handoff update:** `f991e928b9ccb2119b2ad3e7e4112a717d2caff8`; branch matched origin and working tree was clean before this task-brief update.
**Observed working-tree state:** The authenticated QA extension is in progress on top of `f991e928`; the workflow, validator/tests and app handoff documentation are being updated. No commit or push has been made for this extension yet.
**PR / tracker:** Draft PR [#608](https://github.com/im-tnyx/tio-world/pull/608) is open, `MERGEABLE`, ahead 7 / behind 0 at `f991e928b9ccb2119b2ad3e7e4112a717d2caff8`. Latest PR body records Flutter CI [39162930656](https://github.com/im-tnyx/tio-world/actions/runs/39162930656) and attribution [39162929279](https://github.com/im-tnyx/tio-world/actions/runs/39162929279) as passing at this HEAD. Review decision remains empty; IOS-001 is unresolved and the review explicitly says `NOT APPROVED / HOLD`. The open P1 thread asks for the separate manual-only bootstrap; the P2 stale-handoff thread is resolved/outdated. GitHub issue searches for iOS/Supabase login returned no owning issue. No Linear connector/tool is available in this session, so live Linear state cannot be verified; do not invent ownership or update a Linear issue.
**Current implementation state:** The baseline workflow accepted no build-mode input and passed no Supabase defines. `apps/app/.runtime.qa.json` is ignored and contains the two expected key names (values not recorded); canonical docs say Android Studio/Flutter must explicitly pass `--dart-define-from-file`. Runtime source reads the compile-time defines, initializes one Supabase client, selects Supabase auth/session repositories when configured, uses existing email/password sign-in, and retains the existing route/session guards. The new implementation adds an optional, manual-only QA config path without changing those runtime/auth components. No Apple signing credentials are present.
**Relevant execution surface:** `apps/app/ios`, `.github/workflows/ios-ui-build.yml`, existing `SupabaseRuntimeConfig` and auth/session composition, a runner-local temporary define file, macOS unsigned profile build, Windows local signing/sideload instructions.
**Validation completed:** Flutter CI and attribution passed at `022bffec` (Flutter CI run [39162581162](https://github.com/im-tnyx/tio-world/actions/runs/39162581162), attribution run [39162579349](https://github.com/im-tnyx/tio-world/actions/runs/39162579349)). The one-time iOS build/artifact at source `8514ac5c` passed as recorded below. Manual-only YAML contract and `git diff --check` passed locally. At `06ab9564`, the older artifact had incorrect provenance and is historical only. Local static checks previously confirmed valid `Info.plist`, all asset references, iOS 15 targets, iPhone-only target families, and no signing credentials. Local Flutter 3.44.6 / Dart 3.12.2 is recorded in `bin/cache/flutter.version.json`; no local Xcode is available.
**Validation remaining:** Run helper tests, workflow static/manual-only contract, Python syntax, YAML parsing/actionlint where available, `git diff --check`, then publish the completed changes to PR #608 and verify exact-head Flutter CI/attribution. Do not run a macOS build now. After bootstrap and owner-configured Actions secrets, the owner manually triggers the `qa_login` build, verifies artifact/checksum/provenance/no signing material, then performs Windows AltServer install and physical email/password QA.
**Current blocker:** GitHub still cannot manually dispatch this workflow until it exists on the default branch. The one-time artifact at `8514ac5c` is prior UI-only evidence and is not manual-dispatch or authenticated QA proof. Linear current state is unavailable in this session. Use only owner-managed Actions secrets for the QA URL and publishable key; the compiled client values remain extractable, so they must point to an isolated QA Supabase project and must never be privileged credentials. Never place values in tracked files, logs, provenance, caches, or uploaded artifacts.
**Open review finding IDs:** `IOS-001` P1 — dispatch bootstrap and exact-head native evidence pending; `IOS-002` P2 — addressed/resolved on GitHub; `IOS-003` P2 — fixed to iPhone-only.
**Next exact action:** Finish the approved optional `qa_login` implementation and local validation on PR #608 without triggering macOS. Keep P1 IOS-001 open until the separate bootstrap is approved/merged and manual exact-head build evidence exists. Then the owner configures QA repository secrets and manually dispatches the desired mode. Do not merge PR #608 without explicit `Go merge`.

## Global UI / Design-System Guardrail

This slice changes platform/build infrastructure only. It does not modify Flutter production UI, rendered values, reusable components, theme/token contracts, navigation, or product-visible screen behavior.

## 1. Discovery

### User Outcome

The owner can build a device-targeted Flutter iOS UI artifact on standard GitHub-hosted macOS, download it on Windows, sign it locally with a free Apple ID through a trusted sideloading tool, and launch it on a physical iPhone. By explicitly selecting `qa_login`, the owner can also test the existing Supabase email/password flow and reach currently authorized product screens using an isolated QA project and account.

### Success Criteria

- `apps/app/ios` is a phone-only Flutter Runner compatible with current locked plugins.
- The native deployment target is iOS 15 or later.
- The custom callback `tio://login-callback` and camera/photo usage descriptions exist in the iOS app metadata.
- A manual-only, read-only-permission workflow creates an unsigned profile-mode `Payload/Runner.app` IPA container and provenance/checksum files without credentials.
- Documentation identifies the exact local signing point, free-provisioning limits, bundle-ID rewriting risk, and boundaries between UI-only and email/password QA login.
- Optional `qa_login` compiles only a validated client-safe QA URL/key from manual-only GitHub Actions secrets; the runtime config file stays runner-local and is removed after use.
- Android and Watch behavior is unchanged; no production endpoint/provider/release configuration is added.

### Scope

- `apps/app/ios/**`
- `.github/workflows/ios-ui-build.yml`
- `.github/scripts/ios_qa_runtime_config.py` and focused tests
- `apps/app/README.md`
- PR #608 description
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
| Keep `ui_only` as default and add opt-in email/password `qa_login` | Approved by pasted owner request | Allows protected product screens to be reached with existing Supabase Auth without changing auth/session/router behavior or activating deferred providers. | Owner |
| Read QA config from GitHub Actions Secrets only in the selected QA mode | Approved by pasted owner request | Secrets protect build-time inputs; runtime values compiled into the IPA are extractable and must be client-safe and QA-only. | Owner |
| Keep implementation tracked in existing PR #608; no separate issue | Confirmed by current ownership audit | GitHub issue searches found no separate iOS/Supabase QA issue; PR #608 owns this implementation. Live Linear state is unavailable in this session and is not claimed absent. | Owner / implementation |

## 4. Architecture Design

### Chosen Approach

```text
GitHub Actions standard macOS runner
  -> manual mode selection (`ui_only` default / `qa_login`)
  -> optional validated runner-local Supabase define file from gated Actions Secrets
  -> Flutter profile device .app without codesigning
  -> Payload/Runner.app packaged as unsigned .ipa
  -> checksum + source/toolchain provenance
  -> Windows download
  -> local free-Apple-ID signing and install
  -> physical iPhone UI smoke test
```

### Ownership and Data Flow

`apps/app/ios` owns only the iPhone Runner. `.github/workflows/ios-ui-build.yml` owns manual mode selection, conditional secret exposure, compilation and packaging. `.github/scripts/ios_qa_runtime_config.py` validates the client-safe config and writes it with restrictive permissions under `$RUNNER_TEMP`; cleanup runs after the build. The Windows sideloading tool owns local provisioning/signing outside the repository. Existing Flutter runtime owns Supabase initialization, auth/session repositories and route guards.

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
- [x] Add manual-only `ui_only` default and opt-in `qa_login` mode from gated GitHub Actions Secrets.
- [x] Validate and write client-safe runtime config under `$RUNNER_TEMP`; remove it after the build and exclude it from artifacts/provenance.
- [x] Add focused runtime-config and manual-only workflow contract tests.
- [x] Document Secrets setup, mode selection, artifact verification, AltServer install, and existing-account email/password smoke test.
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

**Current disposition:** IOS-001 remains **OPEN**. The optional `qa_login` input changes artifact configuration only; it does not add the workflow to the default branch or enable manual dispatch. Preserve the separate manual-only bootstrap gate. No finding is closed without review evidence.

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
- `.github/scripts/ios_qa_runtime_config.py`
- `.github/scripts/test_ios_qa_runtime_config.py`
- `apps/app/README.md`
- `docs/data/SUPABASE_RUNTIME_CONFIG.md`
- Existing `apps/app/ios/**` Runner remains unchanged.

### Actual Behavior

The repository now contains a phone-only iOS Runner at `apps/app/ios` with
the existing `com.tnyx.tio` application identifier, iOS 15 minimum, the
`tio://login-callback` scheme, and camera/photo-library purpose strings. It has
no team ID, provisioning profile, entitlement file, certificate, or production
signing credential. Its generated icon/launch PNG renditions use the
existing Tio brand asset.

The manual `iOS UI Build` workflow defaults to `ui_only`. When the owner
selects `qa_login`, one gated step reads only
`TIO_IOS_QA_SUPABASE_URL` and
`TIO_IOS_QA_SUPABASE_PUBLISHABLE_KEY` from GitHub Actions Secrets, validates
the HTTPS Supabase project endpoint and publishable key type, and writes the
two existing Flutter compile-time defines to a mode-0600 runner-local JSON
file. The build passes that file to `flutter build ios --profile
--no-codesign`; cleanup runs afterward. The file is not logged, cached,
committed, uploaded, or included in provenance. Provenance and artifact name
identify the mode, while the existing arm64, unsigned IPA, checksum, and
resolved `Podfile.lock` checks remain. The Windows signer remains the only
place where free Apple-ID credentials and provisioning occur.

### Known Limitations

GitHub Secrets protect the input values only until compilation. `SUPABASE_URL`
and `SUPABASE_PUBLISHABLE_KEY` are extractable from the resulting QA IPA, so
the owner must set an isolated QA project and client-safe publishable key; URL
syntax validation cannot prove that the endpoint is QA rather than production.
The email/password account is entered on the iPhone and is never part of build
configuration. No Apple/Google sign-in provider is activated. Authenticated
login remains unverified until the owner installs the artifact and tests it on
the physical iPhone. This does not establish production auth/data parity,
exhaustive RLS coverage, secure-storage durability, HealthKit, push,
associated-domain behavior or release readiness.

### Final Status

`REVIEW` — PR #608 remains open and draft, with no approval. The P1 manual
dispatch/bootstrap finding remains open; this QA-login implementation does
not resolve it. Exact-head Flutter CI/attribution, manual iOS build, Windows
AltServer signing/install, and physical email/password QA remain separate
gates. Do not merge without explicit `Go merge`.
