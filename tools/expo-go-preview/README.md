# Issue #759 — Expo Go QR test of the existing Flutter app (EXPERIMENT ONLY)

This folder is a **minimal React Native/Expo Go WebView shell**. It does not reimplement Tio, change any Flutter code, or turn Expo Go into a Flutter runtime. It can display **the real Flutter Web compilation** only if the current Tio Flutter app compiles and runs on the web. It is **not** native Android/iOS parity.

**Status:** test-only; no device acceptance, no merge approval. Do not deploy or use real accounts or health data.

## Prerequisites

- Windows laptop with current Tio-world Git repository, existing Flutter SDK and Node.js 22.13+ / npm.
- Android phone (Expo Go supporting SDK 57) or compatible iPhone/Expo Go.
- Phone and Windows PC on the same **trusted private Wi-Fi/LAN**; no public/hotel/shared network and no port forwarding.
- Current source branch `tnyx/issue-759-expo-go-preview-spike`.
- For an iPhone, Expo Go and the Expo CLI may need the same Expo account.

## 1. Check out the experiment without modifying your normal Flutter checkout

PowerShell:

```powershell
Set-Location "G:\projects\Tio-World"
git status --short --branch
git fetch origin "refs/heads/tnyx/issue-759-expo-go-preview-spike:refs/remotes/origin/tnyx/issue-759-expo-go-preview-spike"
git worktree add --detach "G:\projects\Tio-World-Expo759" "refs/remotes/origin/tnyx/issue-759-expo-go-preview-spike"
Set-Location "G:\projects\Tio-World-Expo759"
```

If the target directory already exists, inspect it first. Do not reset or overwrite any existing worktree. Keep normal Flutter work and builds in `G:\projects\Tio-World`.

## 2. Terminal A — start the **real Flutter Web** from a disposable checkout

```powershell
Set-Location "G:\projects\Tio-World-Expo759"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tools\expo-go-preview\start-flutter-web.ps1"
```

The script fetches branch #759, creates a uniquely named **temporary detached worktree**, generates `apps/app/web/` only there, resolves the original Flutter dependencies and attempts `flutter run -d web-server --web-hostname=0.0.0.0 --web-port=7357`. This may **FAIL** if native plugins or `dart:io` paths do not support web. Capture exact errors and stop; do not change Flutter product code as part of this spike.

There are **no Supabase defines or QA secrets** in this run. Accordingly, only unauthenticated / non-sensitive UI smoke is in scope.

Find the PC's **private IPv4 address**, e.g. `192.168.1.25`, with `Get-NetIPAddress -AddressFamily IPv4` or `ipconfig`. On the phone's regular browser, first open `http://192.168.1.25:7357` (replace with your LAN IP). If it fails, check the terminal, same Wi-Fi, Windows Firewall private-network port rules, and client isolation. Do not expose this service to the internet.

### Why this preview has a browser-only compatibility shim

The exact Flutter 3.47.9 GitHub compilation on 2026-11-15 failed because Dart-to-JavaScript cannot represent the integer literal `9223372036854775807` at four Routine Move guard comparisons (three in `supabase_routine_move_repository.dart`, one in `routine_move_repository.dart`). The `--wasm` build also fails when building its JavaScript fallback.

The launcher uses `prepare-web-snapshot.js` **only in the detached temporary worktree**. It first checks the expected four original comparisons and then tightens those checks to reject revisions above JS's exact integer range (`> 9007199254740991`). This is deliberately conservative browser-only scaffolding and cannot claim native business-logic parity. The repository's Flutter source, native builds and real credentials are unchanged. If the exact assertions stop matching later Flutter code, compilation stops instead of applying an unknown patch. **Do not test Routine Move, Undo or protected data in this preview.**

## 3. Terminal B — launch the minimal Expo Go wrapper QR

```powershell
Set-Location "G:\projects\Tio-World-Expo759\tools\expo-go-preview"
node --version
powershell -NoProfile -ExecutionPolicy Bypass -File ".\start-expo-go.ps1" -LanIPv4 "192.168.1.25"
```

**Replace `192.168.1.25` with your actual Windows PC LAN IPv4.** Open Expo Go on Android and scan the QR from Terminal B (on iPhone use the camera/Expo Go flow per its current SDK instructions). The QR connects the phone to **Expo Metro**; the wrapper then loads the **separate Flutter Web URL** on port 7357. If the QR works but WebView fails, verify the Flutter URL in the phone browser. `--tunnel` for Expo does **not** automatically tunnel Flutter Web.

If `npm install`, `expo install --check`, Expo bundling, or Flutter Web compile fails, note the error. No existing product source should be modified to conceal failure. Expo SDK / installed Expo Go version mismatch must be recorded as a failed environment gate.

## 4. Physical device test receipt (send back in issue #759)

| Gate | Result / proof |
| --- | --- |
| Windows Flutter SDK version / commit | Not tested |
| Flutter Web compile/run (Terminal A) | Not tested |
| Flutter URL in phone browser | Not tested |
| Node/npm versions and Expo dependency check | Not tested |
| Expo Go SDK version / QR loads RN wrapper | Not tested |
| Flutter Web visible in WebView (not placeholder UI) | Not tested |
| Existing splash/first reachable screen vs native Flutter | Not tested |
| Tap/navigation/back/scroll/safe areas/light-dark | Not tested |
| Refresh and subsequent Flutter UI edit visibility | Not tested |
| Native-only features and Auth / device-sync limitations | Not tested; **not authorized for real-data QA** |
| Owner acceptance to use / merge | **Not approved** |

Useful screenshots should be redacted and contain no account details or health data. If the goal fails, leave the branch unmerged. If it succeeds, still obtain the owner's **separate explicit merge/adoption approval**.

## Security and limitations

- The WebView accepts only `http://PRIVATE_IPV4:7357` (10/8, 172.16/12, 192.168/16) with **no user/password/query/fragment**. Remote/public URL is rejected. No credentials/secrets in Expo, QR, URLs, Git or CI.
- Unencrypted local HTTP is acceptable **only for unauthenticated, non-sensitive UI smoke on trusted isolated Wi-Fi**; it cannot be used to validate or enter private data.
- The Expo Go WebView is a browser engine: OAuth, storage, secure keychain, camera, Google sign-in, Health Connect, native plugin semantics, deep links and back handling may differ or fail.
- If SDK 57 Expo Go is no longer available on your phone, document it. Do not silently add a custom development build, alternate SDK or production configuration to this task.
- No API, database, cloud resource, signing identity, native Flutter code, or server change is included.

See [GitHub #759](https://github.com/im-tnyx/tio-world/issues/759) and `.ai/tasks/issue-759-expo-go-preview-spike.md`.
