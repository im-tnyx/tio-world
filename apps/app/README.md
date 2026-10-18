# Tio App

Flutter Android and iOS phone app shell.

## Free physical-iPhone UI testing

The repository can create an **unsigned** iPhone artifact for the first
physical-device UI-testing lane. It is deliberately separate from production
release, TestFlight, App Store, Apple Watch, provider activation, and Supabase
deployment.

1. For `qa_login`, configure these **repository Actions secrets** under
   **Settings → Secrets and variables → Actions → Repository secrets**:

   - `TIO_IOS_QA_SUPABASE_URL`: the isolated QA project's HTTPS endpoint, such
     as `https://<project-ref>.supabase.co`.
   - `TIO_IOS_QA_SUPABASE_PUBLISHABLE_KEY`: that QA project’s `sb_publishable_`
     client key.

   Do not use production project values. The workflow reads these secrets only
   when `qa_login` is selected, validates them before building, writes a
   temporary file under `$RUNNER_TEMP` with restrictive permissions, and
   removes it after the build. It does not log, cache, commit, or upload that
   file. Never configure a `sb_secret_`, service-role, or other privileged
   key. GitHub Secrets protect the build-time inputs; values compiled into the
   client IPA remain extractable, so only client-safe QA values are allowed.
   The workflow validates endpoint syntax but cannot identify whether a
   project is QA or production; ensure the secret points to an isolated QA
   project.

   Skip this step for `ui_only`.

2. Ensure the manual-only **iOS UI Build** workflow is available on the default
   branch, then select the intended branch and manually dispatch it. Choose
   `ui_only` (the default) or `qa_login`.
3. Download the artifact named
   `tio-ios-<build-mode>-unsigned-profile-<run number>`. On Windows, verify it
   before use:

   ```powershell
   Get-FileHash .\Tio-unsigned-profile.ipa -Algorithm SHA256
   Get-Content .\Tio-unsigned-profile.ipa.sha256
   Get-Content .\provenance.txt
   Get-Content .\Podfile.lock
   ```

4. Install a current trusted Windows sideloading tool that supports local free
   Apple-ID provisioning, such as AltServer's **Sideload .ipa** action. Connect
   and trust the iPhone, enable Developer Mode when iOS requires it, and sign
   the IPA locally. Enter the Apple ID and any two-factor authentication only
   in that local tool; never put them in GitHub, repository files, workflow
   inputs, logs, or issue comments.
5. Open the installed app and perform the UI smoke checks below. For `qa_login`,
   use an existing QA account through the app's email/password form; type the
   password on the iPhone and keep it out of workflow inputs, logs, artifacts,
   chat, and repository files. Re-sign or refresh the app before free
   provisioning expires (normally seven days).

The downloaded IPA is not installable by itself. GitHub's macOS runner compiles
the iPhone `Runner.app` but intentionally does not sign it. The local
sideloading tool supplies the provisioning profile, re-signs the app and its
embedded Flutter/plugin binaries, then installs it on the iPhone. Renaming an
`.app` to `.ipa` or sending the unsigned IPA directly to iOS will not work.
`Podfile.lock` in the artifact records the exact CocoaPods resolution used by
that build; it is provenance for the downloaded artifact, not a signing file.

### Scope and limitations

- This is a profile-mode AOT UI artifact. It can launch without a Flutter
  debugger, but it does not support the Windows-to-iPhone hot-reload workflow.
- `ui_only` omits Supabase configuration and reaches the existing
  unauthenticated UI path. `qa_login` supplies only the existing compile-time
  `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` inputs, then uses the current
  Supabase client, email/password auth, session repository and router guards.
  It adds no login bypass or provider integration.
- A `qa_login` build can exercise sign-in and reachable protected screens on
  the configured QA backend, but does not establish production auth/data
  parity, exhaustive RLS coverage, secure-storage durability, or physical-device
  success until the iPhone test is actually performed. Use only test accounts
  and QA data.
- A free Apple provisioning profile expires quickly and has Apple-imposed app,
  device and App-ID limits. Refreshing changes the signed artifact; compare the
  checksum only to the unsigned download before local signing.
- The local signer can rewrite the installed bundle identity. Do not treat this
  lane as Google Sign-In, Firebase, deep-link, Keychain, associated-domain,
  push-notification, HealthKit or Apple Sign-In validation. Those capabilities
  need their own platform configuration, entitlement audit and real-device
  acceptance slice. This app currently has no HealthKit or push implementation.
- Do not enable Apple/Google providers, add `GoogleService-Info.plist`, add
  entitlements, or create production signing/release infrastructure for this
  manual QA workflow.

### Device smoke checklist

- [ ] Artifact checksum and provenance match the selected GitHub run.
- [ ] Local signing/install succeeds and the app appears on the Home Screen.
- [ ] Cold launch reaches the expected existing session/auth flow without a
      crash.
- [ ] For `qa_login`, email/password sign-in succeeds with an existing QA
      account and reaches only screens allowed by the current session/router
      state; record the result without recording credentials.
- [ ] Safe areas, keyboard, text input, scrolling, sheets and back navigation
      work on the physical device.
- [ ] Light/dark appearance, larger text and VoiceOver receive a focused smoke
      check for the reachable screens.
- [ ] Kill/relaunch behavior is recorded separately; it is not proof that
      secure storage or any authenticated session is valid on iOS.
