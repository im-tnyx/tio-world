# iOS free physical-device UI testing foundation

**Status:** In progress
**Primary owner:** Flutter phone platform / repository CI
**Affected platforms:** iOS phone build tooling and GitHub Actions; existing Android runtime unchanged

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner supplied explicit `Go` on 2026-10-19 for the initial UI-only slice, then supplied the pasted request on 2026-10-19 explicitly authorizing an optional authenticated Supabase QA build mode within PR #608. The latest owner execution contract keeps the iOS workflow strictly `workflow_dispatch` only; no future automatic iOS runs are authorized.
**Approved product/UI/data-shape boundaries:** Keep the phone-only Runner and unsigned profile artifact; add opt-in `ui_only` (default) and `qa_login` modes. The QA mode may compile only the QA Supabase HTTPS URL and client-safe publishable key from GitHub Actions repository secrets via a temporary runner-local config file. Read those secrets only in the `qa_login`-gated step. Preserve existing Supabase initialization, email/password auth, session repository and router guards. Use an existing QA account only after local iPhone installation. Keep the workflow manual-only. It becomes dispatchable after PR #608 merges it to `main`; the owner accepts native QA-login build and device validation as post-merge acceptance. Do not create a separate bootstrap PR or add automatic triggers.
**Explicit non-changes:** No Flutter screen/layout/theme change; no Supabase schema/RLS/Auth implementation or provider change; no production endpoint/config, secret/service-role key, Apple credentials, Google OAuth credentials, account password, production signing, TestFlight, App Store, Apple Watch target, HealthKit, push, certificate, provisioning profile, device registration, hosted deployment, or release-readiness claim. Do not claim authenticated login works until physical-device evidence exists.

## Active Handoff

**Planning owner:** Current Codex task, reflecting the owner-approved post-merge acceptance decision.
**Implementation owner:** Existing PR #608 implementation; this follow-up records final review/acceptance disposition only.
**Review owner:** Repository owner’s earlier `COMMENTED / NOT APPROVED / HOLD` review was at an older SHA. On 2026-10-19, the owner superseded only its dispatch-timing gate by directing merge before device acceptance. IOS-001 is explicitly deferred to post-merge acceptance; no tests are claimed passed by that decision.
**Implementation ownership state:** Review handoff
**Repository state at final source/config audit:** 2026-10-19; `main@a69bc82443201c66c8d34e3c346db362cc2e450d`; PR source/config HEAD `f5f81ea98040859beb452aae3af246c4eeb522a8`. Subsequent commits `eb6075a` and `86ccf1a` changed task handoff documentation only.
**Local checkout:** Local HEAD remains `f991e928b9ccb2119b2ad3e7e4112a717d2caff8`; local tracking refs remain `main@a69bc82443201c66c8d34e3c346db362cc2e450d` and PR branch `e814d70e63cbbe4151399c38b60be7752c0ea4f9` because fetch could not write `.git/FETCH_HEAD`. GitHub currently reports PR branch `8a71f2f62afb5a0f97ef92f0faf961c581f26f4b`. The local worktree remains dirty with five modified files and untracked `.github/scripts/`; it was preserved without reset, clean, checkout, or overwrite. The untracked helper files match the PR source. Preserve these local edits.
**PR / tracker:** PR [#608](https://github.com/im-tnyx/tio-world/pull/608) is open and draft at source HEAD `8a71f2f62afb5a0f97ef92f0faf961c581f26f4b`, based on `main@a69bc82443201c66c8d34e3c346db362cc2e450d`. Flutter CI run [39167870904](https://github.com/im-tnyx/tio-world/actions/runs/39167870904) passed all five jobs; attribution run [39167870007](https://github.com/im-tnyx/tio-world/actions/runs/39167870007) passed both checks at that exact source HEAD. Owner-provided Linear snapshot (2026-10-19): `TNYX-126` — Backlog; `TNYX-231` — Backlog; `Mobile App` — In Progress. These statuses were supplied by the owner; Linear issue details, dependencies, acceptance criteria, and links were not independently retrieved. No separate iOS QA GitHub issue was found in the prior repository audit. GitHub branch-protection access returned 403; an empty rulesets response does not prove classic protection is absent, so effective required-check and approval policy remain unverified. The repository-native `git diff --check` could not be run at the updated source: `git fetch` was denied at `.git/FETCH_HEAD`; exact blobs were compared and contain no trailing spaces.
**Current implementation state:** iOS workflow remains strictly `workflow_dispatch`, with `ui_only` default and opt-in `qa_login`. Only the selected QA step reads the two repository Actions Secrets, validates the Supabase HTTPS project endpoint and client-safe publishable key, writes a restricted temp JSON in `$RUNNER_TEMP`, and the always-run cleanup removes it. Upload paths exclude the JSON. The compiled IPA embeds client-safe URL/key values, so use only an isolated QA project and never privileged credentials.
**Validation completed:** At source HEAD `8a71f2f62afb5a0f97ef92f0faf961c581f26f4b`, exact-head Flutter CI passed 5/5, attribution passed 2/2, and `python -B .github/scripts/test_ios_qa_runtime_config.py` passed 8 tests. The three specified documentation blobs now contain LF line endings and no trailing spaces; exact-content comparison confirmed only newline conversion for those files. A normal repository `git diff --check` remains unexecuted because fetch failed with `.git/FETCH_HEAD` permission denied. No iOS workflow was dispatched; no current native macOS QA-login build or physical-device behavior is claimed.
**Post-merge acceptance (not yet run):** After PR #608 merges, the owner manually dispatches `qa_login`, verifies native build, checksum/provenance, arm64 and artifact contents, then performs Windows AltServer signing/install and physical iPhone launch/login/UI smoke. The owner explicitly accepts those as post-merge tasks. Do not auto-dispatch iOS or mark acceptance passed without evidence.
**IOS-001 disposition:** Resolved as a pre-merge dispatch-timing finding by explicit owner-approved deferral, with the post-merge acceptance tasks still pending/unverified. The workflow becomes available after this PR merges it to `main`; no separate bootstrap PR is required.
**Next exact action:** If all verifiable gates pass, mark PR #608 Ready for Review, keeping effective branch-protection/approval policy explicitly unverified if the 403 persists. No iOS CI dispatch is authorized. Physical-device QA remains post-merge acceptance; do not merge without the owner’s explicit `Go merge`.

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
| Keep implementation tracked in existing PR #608; no separate issue | Current owner-supplied tracker snapshot | `TNYX-126` is Backlog, `TNYX-231` is Backlog, and `Mobile App` is In Progress (owner-reported on 2026-10-19). PR #608 owns this implementation; no separate iOS QA GitHub issue was found in the prior audit. Linear issue details and links were not independently retrieved. | Owner / implementation |

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
| IOS-001 | P1 | Deferred by owner to post-merge acceptance | Owner explicitly directs merging the foundation before physical iPhone testing. The manual-only workflow becomes available on `main` after PR #608 merges; the `qa_login` macOS build, Windows AltServer signing/install, physical login and UI smoke remain unverified acceptance tasks. Prior UI-only native build at `8514ac5c` is historical and does not prove the QA-login mode. | Owner decision 2026-10-19; live PR #608 head `f5f81ea98040859beb452aae3af246c4eeb522a8` | No bootstrap PR. Preserve this P1 as an explicit post-merge acceptance gate; do not claim native QA-login or device testing passed.
| IOS-002 | P2 | Addressed; GitHub thread resolved/outdated | Task brief incorrectly named base SHA as HEAD and still said no PR / no current CI. | `2acc333d897470eb74b0470e15a699e6169a3b85` | This brief records the live PR, exact head, CI/review state, validation gap, and next action; the live review thread is resolved and outdated. |
| IOS-003 | P2 | Fixed and statically verified | Runner project enabled iPad family (`TARGETED_DEVICE_FAMILY = "1,2"`) despite the approved phone-only slice. | `2acc333d897470eb74b0470e15a699e6169a3b85` | All three Runner configurations now use iPhone-only target family; static check passed after the fix. |

**Current disposition:** Owner has dispositioned IOS-001 as **post-merge acceptance**, not a pre-merge blocker. After PR #608 merges the manual-only workflow to `main`, its dispatch becomes available. Native `qa_login` build, Windows AltServer signing/install, physical login and UI smoke remain **unverified** and must be recorded as post-merge acceptance. No separate bootstrap PR is required.

### IOS-001 Owner-Approved Post-Merge Acceptance

The owner’s 2026-10-19 decision is to merge the iOS build foundation before physical iPhone testing. The workflow is strictly `workflow_dispatch` only; it becomes available after PR #608 merges the workflow file to `main`. No separate bootstrap PR is required because this PR itself introduces the workflow to the default branch.

This disposition resolves the pre-merge dispatch timing conflict while keeping native/device evidence outstanding. The following are **not yet verified** and remain post-merge acceptance tasks:

1. Owner manually dispatches `iOS UI Build` against `main` and selects `qa_login` to validate macOS compilation, runtime config handling, artifact contents, checksum/provenance, arm64, and absence of signing material or the temporary JSON from artifacts.
2. Owner downloads the unsigned IPA on Windows, signs/installs it locally with AltServer using a free Apple ID, and records the exact build/artifact.
3. Owner tests physical iPhone launch, Supabase email/password login against the isolated QA project, and the agreed UI smoke checklist.

The QA URL and publishable key are client-safe inputs and are extractable from the compiled IPA. GitHub Secrets protect build-time inputs only. Never configure production or privileged credentials. No automatic iOS build is authorized; do not mark these acceptance items passed before evidence exists.

```yaml
on:
  workflow_dispatch:

permissions:
  contents: read
```

The macOS job uses standard `macos-15`, checkout `persist-credentials: false`, and no Apple signing credentials. Keep the pre-merge finding disposition transparent; no physical-device or QA-login success is claimed.

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

`REVIEW` — PR #608 remains open and draft. The owner-approved 2026-10-19 decision defers native QA-login and physical iPhone acceptance until after merge; these tasks remain unverified. The manual-only workflow becomes dispatchable after PR #608 merges it to `main`, so no bootstrap PR is required. The exact-head Flutter CI, attribution and config tests are recorded in the active handoff. Do not merge without explicit `Go merge`.
