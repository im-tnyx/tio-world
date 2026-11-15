# Issue #759 — Expo Go QR test of the existing Flutter app (EXPERIMENT ONLY)

This folder is a **minimal React Native/Expo Go WebView shell**. It does not reimplement Tio, change any Flutter code, or turn Expo Go into a Flutter runtime. It can display **the real Flutter Web compilation** only if the current Tio Flutter app compiles and runs on the web. It is **not** native Android/iOS parity.

**Status:** test-only; no device acceptance, no merge approval. Do not deploy or use real accounts or health data.

## Prerequisites

- Windows laptop with current Tio-world Git repository, existing Flutter SDK and Node.js 22.13+ / npm (Node 22.16+ is used by CI).
- Android phone (Expo Go supporting SDK 58) or compatible iPhone/Expo Go.
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

If the target directory already exists from the previous SDK 57 test, **do not run `git worktree add` again**. Stop the old Metro/Flutter terminals with Ctrl+C first, then safely refresh the existing *test-only detached worktree* (but only when its Git status is clean):

```powershell
Set-Location "G:\projects\Tio-World"
git fetch origin "refs/heads/tnyx/issue-759-expo-go-preview-spike:refs/remotes/origin/tnyx/issue-759-expo-go-preview-spike"
$testTree = "G:\projects\Tio-World-Expo759"
$changes = @(git -C $testTree status --porcelain)
if ($LASTEXITCODE -ne 0 -or $changes.Count -gt 0) {
    throw "Test checkout contains changes or could not be inspected. Preserve them; do not switch."
}
git -C $testTree switch --detach "refs/remotes/origin/tnyx/issue-759-expo-go-preview-spike"
```

If there are uncommitted changes, preserve them and inspect before switching; do not reset/clean. Keep normal Flutter work and builds in `G:\projects\Tio-World`.

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

### SDK 58 iPhone mismatch fixed in branch

The initial iPhone report showed **installed Expo Go SDK 58** rejecting this experiment's old **SDK 57** bundle. This branch now targets Expo SDK 58 with React Native 0.88, React 19.3, and Expo-supported WebView 14.0.1. This only fixes the `Expo Go SDK version mismatch` gate; whether iOS can reach/load Flutter Web still requires real-device testing.

If you still see SDK 57 after pulling this branch, close the old Metro terminal, check that you are running this test-only checkout's `tools/expo-go-preview` (not a stale SDK 57 folder), run `npm install`, and use the launcher again. The launcher starts Metro with `--clear` to invalidate its previous cache. No iPhone Expo Go downgrade is required for the reported SDK 58 install.

## 4. Physical device test receipt (send back in issue #759)

| Gate | Result / proof |
| --- | --- |
| Windows Flutter SDK version / commit | Not tested |
| Flutter Web compile/run (Terminal A) | Not tested |
| Flutter URL in phone browser | Not tested |
| Node/npm versions and Expo dependency check | Not tested |
| Expo Go SDK 58 / QR loads RN wrapper | Not tested |
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
- If SDK 58 Expo Go is no longer available on your phone, document it. Do not silently add a custom development build, alternate SDK or production configuration to this task.
- No API, database, cloud resource, signing identity, native Flutter code, or server change is included.

See [GitHub #759](https://github.com/im-tnyx/tio-world/issues/759) and `.ai/tasks/issue-759-expo-go-preview-spike.md`.

## 5. OPTIONAL: Existing local QA config + HTTPS-only iPhone login experiment

The default `http://PRIVATE_LAN_IP:7357` browser preview **must remain UI-only**. **Never enter a password, session token or health data there.** QA login requires a tester-controlled, trusted **HTTPS** server at `https://PRIVATE_LAN_IP:7358`; this is a separate opt-in mode and still may hit unsupported Flutter Web Auth/device plugin paths.

**Local input:** The established Git-ignored `G:\projects\Tio-World\apps\app\.runtime.qa.json`, with ONLY the two original Flutter compile-time keys `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`. Existing native builds use exactly the same file contract. Do not paste values into chat, Git, a QR URL, or an Expo `EXPO_PUBLIC_*` variable. Validate manually that it selects the **isolated QA project**, not production. The publishable key is *client-safe* but embedded in compiled Web assets (therefore extractable). The QA email/password is never in the config file; enter it **only on your device after trusted HTTPS is confirmed**.

**One-time local TLS prerequisite:** Use [mkcert](https://github.com/FiloSottile/mkcert) on your own PC, from a trusted package source. Generate TLS files **outside the repository** using your real LAN IP. For example:

```powershell
$qaTls = Join-Path $env:LOCALAPPDATA "Tio-World-Expo759-TLS"
New-Item -ItemType Directory -Force -Path $qaTls | Out-Null
mkcert -install
mkcert -cert-file "$qaTls\qa-preview.pem" -key-file "$qaTls\qa-preview-key.pem" 192.168.1.12
mkcert -CAROOT
```

The command `mkcert -CAROOT` prints the directory containing **`rootCA.pem`**. Transfer **only** `rootCA.pem` (NEVER `rootCA-key.pem` or the preview private key) privately to the QA iPhone. Install the CA profile from iOS Settings → Profile Downloaded / General → VPN & Device Management, then enable Full Trust in Settings → General → About → Certificate Trust Settings. This trusts a local development CA **system-wide on that phone**, so do this only on a controlled test iPhone and **remove that CA from iPhone trust after testing**. You can skip QA HTTPS mode entirely rather than install a trusted CA.

Terminal A (new QA HTTPS server; do **not** run the normal HTTP preview on port 7357 at the same time):

```powershell
Set-Location "G:\projects\Tio-World-Expo759"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\tools\expo-go-preview\start-qa-web.ps1" `
  -LanIPv4 "192.168.1.12" `
  -CertFile "$qaTls\qa-preview.pem" `
  -KeyFile "$qaTls\qa-preview-key.pem"
```

This script performs a disposable Flutter Web build with `--dart-define-from-file` pointing at the **existing ignored local QA config**, then serves only that built output on private-LAN HTTPS port 7358. It does not modify the original Flutter app or start an HTTP QA login server. It preserves temporary QA build files for manual review/cleanup; compiled assets contain the client-safe key/URL, so **do not upload the build folder**. Keep Terminal A open.

**Before any credentials:** Visit `https://192.168.1.12:7358` from the iPhone's **Safari** and confirm the page loads with no certificate warning. If certificate trust, TLS, hostname or network fails, stop; do not bypass errors.

Terminal B (Expo QR, separate):

```powershell
Set-Location "G:\projects\Tio-World-Expo759\tools\expo-go-preview"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\start-expo-go.ps1" -LanIPv4 "192.168.1.12" -QaHttps
```

Scan the new QR with Expo Go SDK 58 and first confirm this HTTPS page loads there. Use **only a disposable QA account with no real health data** for a first email/password login test. OAuth, Google identity, device sync and protected app flows are **not** validated by this wrapper. Do not perform Move/Undo write tests; the browser-only integer guard prevents claiming behavior parity.

### Existing GitHub Actions QA secret reuse

The default-branch `Tio Mobile QA Build` workflow already consumes the existing `TIO_IOS_QA_SUPABASE_URL` and `TIO_IOS_QA_SUPABASE_PUBLISHABLE_KEY` secrets for Android/iOS **native** QA builds. That workflow remains unchanged.

This experimental branch's `expo-preview-spike.yml` runs an ordinary PR **synthetic** QA Web compile with test placeholders through the same shared Python validator and `--dart-define-from-file` path. Its optional `workflow_dispatch` `qa_web_compile` job is **strictly manual**, reuses the same two GitHub secrets, makes a non-uploaded QA Web build and removes its temp JSON after execution. **It cannot be run from GitHub Actions while the workflow file exists only on this unmerged branch**; GitHub requires registration of workflow_dispatch workflows on the default branch. Do not merge just to unlock it: user approval and separate security review are still required. Any real-secret CI Web build, local HTTPS iPhone login, auth persistence and RLS smoke remain **NOT VERIFIED** until separately executed.

**Security:** Never pass secrets into Expo bundler, public URLs or user messages, and never use service_role/secret keys or production projects. No new Supabase resources/credentials are introduced.
