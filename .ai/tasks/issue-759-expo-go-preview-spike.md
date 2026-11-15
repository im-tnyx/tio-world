# Issue #759 — Flutter Web → Expo Go QR preview feasibility

**Status:** In progress — isolated experiment; NOT accepted for merge
**Primary owner:** Tio-world mobile developer experience / owner
**Affected platforms:** Dev-only Windows workflow, browser preview and Expo Go (Android/iOS). No Flutter native production change.

## Owner Approval and Scope Boundary
**Trigger:** New independently scoped test spike
**Approval status:** Approved for testing only (2026-11-15 chat). **No merge/adoption approval.**
**Approved product/UI/data-shape boundaries:** Retain Flutter as sole product implementation; optionally show the *same Flutter Web rendering* in Expo Go through a private WebView/QR. Testing-only tools on issue #759 branch.
**Explicit non-changes:** Do not modify `apps/app`, `apps/features`, `apps/core`, `apps/shared`, `apps/wear`, native Flutter QA, visual geometry or routing; no product React Native port; no Supabase/Auth schema or credentials; no production hosting; no deployment; no merge without a new owner decision.

## Active Handoff
- **Planning owner:** ChatGPT (GitHub issue #759)
- **Implementation owner:** ChatGPT (GitHub connector; scoped test-only files)
- **Previous agent:** Not applicable
- **Last commit agent:** Not applicable at creation
- **Last commit SHA:** Not applicable at creation
- **Review owner:** Unassigned; owner to review real device result
- **Implementation ownership state:** Active
- **Ownership transition:** Not applicable
- **Repository state last verified:** 2026-11-15 via GitHub; local Windows worktree not accessible in this chat
- **Branch:** `tnyx/issue-759-expo-go-preview-spike`
- **HEAD SHA:** `3de52946a73d5b2db025a58c9b0928f5f814ffd5` before first issue-759 commit
- **Observed working-tree state:** Remote branch identical to `main` at preflight; local status unknown
- **Observed uncommitted/dirty files:** Unknown on owner Windows machine; GitHub compare returned zero changed files
- **PR / tracker:** [GitHub #759](https://github.com/im-tnyx/tio-world/issues/759). Linear mirror blocked by workspace free issue limit.
- **Current implementation state:** Prepared branch-only Expo Go wrapper, private-LAN guard, disposable Web runner and CI. Expo wrapper passed on SHA bfd477f; native JS and --wasm Web builds failed on four unsafe 64-bit literals, so a temporary conservative browser-only snapshot guard is being tested in isolated checkout.
- **Relevant execution surface:** A *temporary detached Git worktree* generates Flutter Web runner; `tools/expo-go-preview` is a dev-only Expo Go shell. No production screens rewritten.
- **Validation completed at SHA:** None at creation
- **Validation remaining:** Flutter Web compile, Expo dependency resolve/Metro, physical Expo Go QR, private-LAN networking, actual UI parity, regressions and device acceptance.
- **Current blocker:** GitHub native JS and Wasm builds fail because of four int64 literals; testing a strict disposable-only browser guard. Owner physical device is unavailable to this chat.
- **Open review finding IDs:** Not applicable; no review yet
- **Next exact action:** Commit only test-owned files on issue branch, run dependency-free Node validation, trigger draft-PR experimental CI, inspect compile logs, and hand off precise physical-device steps. Never merge.

## 1. Discovery
**User outcome:** QR launch in Expo Go for an optional mobile UI preview while all normal coding/testing continues in Flutter.
**Success:** Real Flutter Web UI (not a React Native recreation) loads on a physical device through Expo Go QR; limitations documented; no changes to Flutter native app or protected data.
**Non-goals:** Native parity; OAuth/device health/plugin functionality validation; production release; live health data; React Native port.

## 2. Codebase Exploration
- `AGENTS.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/TEMPLATE.md`, `docs/architecture/ARCHITECTURE.md`, `docs/development/DEVELOPMENT_SETUP.md`, `.github/PUSH_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE.md` inspected.
- `apps/app/pubspec.yaml` and `apps/app/lib/main.dart` use Flutter, Supabase/Firebase and device plugins.
- `apps/app/web/` missing in initial GitHub directory listing. Generating in a **throwaway** checkout does not change tracked Flutter sources.
- `apps/features/auth/lib/src/data/device/flutter_device_identity_provider.dart` imports `dart:io` and invokes `Platform.isAndroid`/`Platform.isIOS`; Web portability is **unproven**, especially authenticated device-sync. Do not alter this code as part of this spike.
- Native Flutter CI uses Flutter 3.47.9 on GitHub, so the experimental Web compile should pin 3.47.9 too.
- Official docs: [Flutter Web](https://docs.flutter.dev/platform-integration/web/building), [Expo Go](https://docs.expo.dev/get-started/start-developing/), [Expo SDK 57 WebView](https://docs.expo.dev/versions/v57.0.0/sdk/webview/).

## 3. Decisions
- Expo Go cannot run Flutter/Dart binary; a WebView can only display Flutter **Web**.
- Choose Expo SDK 57 for initial real-device compatibility per Expo's current creation guidance; Expo Go installed version must be checked by tester.
- Web preview launched without Supabase defines, explicitly **unauthenticated** and limited to non-sensitive UI smoke.
- Local HTTP private-LAN URL is acceptable for *no-account/no-private-data* development smoke only; a tunnel of the Expo Metro server does not make the Flutter Web server remotely accessible. Block external URLs.
- Use a fresh temporary worktree so `flutter create --platforms=web .` never touches normal checkout. No automatic cleanup of local work unless the owner chooses.

## 4. Architecture
```text
Existing Flutter native app (unchanged)
              |
 Disposable Git worktree of this test branch
              | flutter create --platforms=web . (throwaway)
              | flutter run -d web-server --web-hostname 0.0.0.0
              v
   Local dev HTTP private IP:7357 (no login/credentials)
              |
    Expo Go QR → minimal RN WebView (dev-only)
              v
     Flutter Web UI (not native Flutter)
```
**Rejected:** duplicating Flutter screens/controllers in React Native. Also reject adding Flutter native module to Expo Go (custom native code not supported in stock Expo Go).
**Failure states:** invalid private LAN URL, unreachable server, web compile failure, incompatible plugin, WebView HTTP access issues, device/account restrictions; fail closed without credentials.

## 5. Implementation Plan
- [ ] Prepare isolated README, PowerShell launcher, small Expo Go wrapper and node URL validation tests.
- [x] Implement branch-only feasibility CI without secrets and without modifying tracked Flutter platform files.
- [ ] Run Web build on actual SDK/CI and record source errors verbatim.
- [ ] Run Expo Go on physical device; compare to existing Flutter app and record UI/browser/plugin differences.
- [ ] Owner accepts or rejects adoption. **Leave unmerged unless explicitly approved.**

## 6. Quality Review
**CI evidence (2026-11-15):** `expo-wrapper` SUCCESS at `bfd477fe` (21/21 private URL tests; Expo SDK 57 package check; Android Metro bundle success, workflow run 43695876823). Flutter Web dart2js FAIL at run 43695663171: four 9223372036854775807 literal errors in existing Workout Move source. Flutter Web `--wasm` FAIL at run 43696044461 because it also compiles dart2js fallback. Next isolated run checks **test-only conservative JS-safe-limit substitution** in the temporary worktree; main source unchanged. Physical Expo Go/browser parity **NOT tested**.
**Security:** No `SUPABASE_URL`/`SUPABASE_PUBLISHABLE_KEY` injected, no session credentials or health data, no external Web URL, and no public preview hosting.
**Acceptance disposition:** NOT ACCEPTED — browser snapshot compilation and device QR/visual checks pending. Even a successful preview is not native behavioral/Move parity. No merge.
