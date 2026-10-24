# Manual Mobile QA Build

**Status:** In progress
**Primary owner:** Flutter phone app and repository CI
**Affected platforms:** Android phone, iPhone

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped mobile QA artifact slice.
**Approval status:** Approved by the owner request of 2026-10-23.
**Approved boundary:** One `workflow_dispatch`-only `Tio Mobile QA Build` with `android` or `ios` selection, mandatory QA Supabase email/password-capable configuration, a debug APK or unsigned profile IPA, checksums, provenance and seven-day artifacts. Retire the old iOS workflow after parity review.
**Explicit non-changes:** Existing Android Native CI, Flutter CI, Wear/backend/database CI, auth/session/router behavior, providers, feature flags, release signing, stores, hosted Supabase and physical-device acceptance.

## Active Handoff

**Planning owner:** Owner / repository CI
**Implementation owner:** Codex in this task branch
**Review owner:** `im-tio` submitted an independent `COMMENTED` review at implementation SHA `435b0ea8fc83d9d453962a6457b6b59412105d12`; follow-up review of the corrected head remains pending. This is not a GitHub `APPROVED` review.
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-10-24; `main` and freshly fetched `origin/main` both `0bc9dd0c85fd2d266f227256397e59c33ce059d0`, clean; one primary worktree.
**Branch:** `tnyx/mobile-qa-build`
**Base/branch-creation SHA (historical):** `0bc9dd0c85fd2d266f227256397e59c33ce059d0`. Read [PR #663](https://github.com/im-tnyx/tio-world/pull/663) for its live HEAD; do not use this base receipt as the current HEAD.
**Observed working-tree state:** Clean before this brief.
**Observed uncommitted/dirty files:** None before this brief.
**PR / tracker:** [PR #663](https://github.com/im-tnyx/tio-world/pull/663) OPEN. Implementation commit `435b0ea8fc83d9d453962a6457b6b59412105d12` was reviewed against `main@0bc9dd0c85fd2d266f227256397e59c33ce059d0`. PR #608 merged as `4dba419f8181cf739832ae556472f91fe87a92a4`; GitHub #568 / Linear TNYX-78 own separate first-Routine real-device QA, while TNYX-126 owns release readiness and TNYX-231 owns future providers. Mobile App project is In Progress.
**Current implementation state:** One platform-gated manual workflow implemented in the task branch; old iOS workflow retired after parity review. PR #663 is in review, not merged.
**Relevant execution surface:** `.github/workflows`, `.github/scripts`, `apps/app` build configuration and QA documentation.
**Validation completed at implementation SHA `435b0ea8fc83d9d453962a6457b6b59412105d12`:** 10 focused Python tests PASS; PyYAML parses one `workflow_dispatch` and both jobs; `flutter analyze --no-pub` in `apps/app` PASS; `git diff --check origin/main...HEAD` PASS. [Required Commit attribution guard](https://github.com/im-tnyx/tio-world/actions/runs/40005791962) SUCCESS, [Flutter CI](https://github.com/im-tnyx/tio-world/actions/runs/40005792004) SUCCESS (five jobs), and [Docs Hygiene CI](https://github.com/im-tnyx/tio-world/actions/runs/40005792153) SUCCESS. Dedicated `actionlint` unavailable locally. Cursor Bugbot and Cursor review agents returned NEUTRAL, not passing review evidence.
**Validation remaining:** Recheck exact-head CI after this docs-only handoff correction, complete follow-up independent review, and keep native/device build acceptance separate.
**Current blocker:** Manual workflow cannot be dispatched until it exists on the default branch; actual Android/iOS QA build and device login remain unverified by this PR.
**Open review finding IDs:** [P3 handoff provenance/final-status finding](https://github.com/im-tnyx/tio-world/pull/663#discussion_r4363224496) from independent `im-tio` review, corrected in this follow-up edit pending reviewer verification. No P0/P1/P2 was reported in that review. Codex's code review at implementation SHA completed with no findings; the separately requested Codex security review has no reported result yet.
**Next exact action:** Commit and push this handoff-only correction, then recheck exact new HEAD CI and the P3 thread/review disposition. Do not dispatch QA builds or merge.

## 1. Discovery

The owner needs downloadable, installable-development QA artifacts for both phone platforms, built only after explicit manual dispatch. Android uses a debug-signed APK; iOS uses an unsigned profile IPA requiring local signing before installation.

## 2. Codebase Exploration

- `apps/app/android` and `apps/app/ios` both exist. Android `com.tnyx.tio` uses Java 17, Gradle 8.14, Android Gradle Plugin 8.11.1 and Kotlin 2.2.20. No production signing configuration is present in `apps/app/android/app/build.gradle.kts`.
- Existing `ios-ui-build.yml` is manual-only on `macos-15`, pins Flutter 3.44.6, disables Swift Package Manager, resolves CocoaPods, builds `--profile --no-codesign`, checks arm64 and absence of an embedded provisioning profile, uploads IPA/checksum/`Podfile.lock`/provenance for seven days. `git log` and `git diff` show no iOS workflow or helper changes since merged PR #608.
- Existing `android-native-ci.yml` builds phone and Wear debug APKs but does not deliver QA artifacts; `flutter-ci.yml` owns Flutter analysis/tests. Neither should change.
- `SupabaseRuntimeConfig` already reads `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` from compile-time defines. The debug app may continue its existing no-backend fallback if initialization fails; a configured build does not prove successful login.
- The GitHub repository currently has only the two relevant QA secret **names** `TIO_IOS_QA_SUPABASE_URL` and `TIO_IOS_QA_SUPABASE_PUBLISHABLE_KEY`. Values were not read. Reuse these for both platform jobs, documenting the historical prefix; no secret migration is required.
- `ios_qa_runtime_config.py` validates HTTPS `*.supabase.co` endpoints and `sb_publishable_` keys and writes mode-0600 JSON. Its existing tests cover missing, invalid and privileged inputs. The old `ui_only` branch is outside the new workflow contract.
- The old iOS task handoff and runtime-config docs still describe PR #608 as open and direct manual dispatch to its deleted branch. This is stale historical status and will be reconciled in this slice.
- Live Linear on 2026-10-24: TNYX-126 Backlog, TNYX-231 Backlog, TNYX-78 In Progress, Mobile App project In Progress. A dedicated Mobile QA build issue was not found in the focused GitHub search. Linear shared agent-context lookup was unavailable (`get_agent_context not found`); live issue reads succeeded.

## 3. Architecture and Security Decision

- Use one manual workflow with two platform-gated jobs. Each job uses only `contents: read`; no automatic event or QA build is added.
- Reuse the existing two QA repository Secrets for both jobs so current iOS configuration remains usable. The variable names are historical; no secret values enter source, logs, provenance or uploads.
- Reuse the validated URL/key checks in a platform-neutral helper. Write the two Dart defines under `$RUNNER_TEMP` with restrictive permissions, and remove the file on success, failure or cancellation where runner steps can execute.
- Restrict uploads to explicit APK/IPA, checksum, provenance and iOS `Podfile.lock` files. Debug APK signing uses the runner's ephemeral debug key; no keystore is uploaded. iOS signing remains local to the owner's Windows sideloading tool.
- Reject a second iOS workflow or a selectable `ui_only` mode in the new workflow. Delete the old workflow only after reviewing equivalent packaging and guardrails.
- Client-safe values remain extractable from compiled artifacts; the owner must verify the configured Secrets target the isolated QA project. RLS and Supabase Auth remain the access boundary.

## 4. Validation Plan

- Run focused Python config/workflow tests, workflow YAML lint, `git diff --check`, source/secret artifact inspection and applicable inexpensive Flutter/Android checks.
- Check selected-job gating, mandatory QA config, invalid/missing/privileged rejection, cleanup, artifact existence/checksums/naming/provenance and manual-only trigger.
- Do not dispatch Android or iOS jobs in this implementation. Their native artifact and physical-device login evidence remain post-merge acceptance.

## 5. Final Handoff

- Added `.github/workflows/mobile-qa-build.yml` with selected-platform jobs and mandatory `qa_login`; removed `.github/workflows/ios-ui-build.yml` only after retaining the pinned Flutter/CocoaPods/arm64/unsigned IPA/checksum/Podfile/provenance behavior in the new iOS job.
- Renamed the validated iOS configuration helper to `.github/scripts/mobile_qa_runtime_config.py` and removed its old `ui_only` path; extended focused tests in `.github/scripts/test_mobile_qa_runtime_config.py`.
- Updated `apps/app/README.md`, `docs/data/SUPABASE_RUNTIME_CONFIG.md`, `docs/development/DEVELOPMENT_SETUP.md`, and task index/historical iOS handoff. No Flutter Auth, Android package, release signing, ordinary CI, hosted Supabase or device state changed.
- The runtime JSON is written under `$RUNNER_TEMP` with mode 0600 and explicit upload paths exclude it. Existing GitHub Secrets supply client-safe QA values; their contents were not read. QA account credentials are never workflow inputs.
- Native QA APK/IPA generation, Windows signing, physical login and UI smoke remain **NOT RUN**. The new workflow will be manually dispatchable only after merging it to the default branch. Do not mark device QA, login, CI artifacts or merge as passed without actual evidence.

### Final Status

**Final Status: REVIEW.** Implementation and implementation-HEAD CI passed, but the handoff correction requires new-HEAD checks and independent reviewer disposition. Manual native artifacts and physical-device acceptance remain post-merge, **NOT RUN**.
