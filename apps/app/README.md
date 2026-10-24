# Tio App

Flutter Android and iOS phone app shell.

## Manual Android and iPhone QA builds

The **Tio Mobile QA Build** GitHub Actions workflow creates a phone debug APK
or unsigned profile IPA only when manually dispatched. Both builds include the
existing Supabase email/password login configuration for the isolated QA
project; neither build proves login or physical-device behavior until tested.

1. Configure these **repository Actions secrets** under
   **Settings → Secrets and variables → Actions → Repository secrets**:

   - `TIO_IOS_QA_SUPABASE_URL`: the isolated QA project's HTTPS endpoint, such
     as `https://<project-ref>.supabase.co`.
   - `TIO_IOS_QA_SUPABASE_PUBLISHABLE_KEY`: that QA project’s `sb_publishable_`
     client key.

   These historical iOS-prefixed secret names are shared by both platform
   jobs, so no new secret values are required. The workflow validates them,
   writes only `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` to a restricted
   temporary file under `$RUNNER_TEMP`, and removes it after the build. It does
   not log, cache, commit or upload that file. Never configure a production
   project, `sb_secret_`, service-role key, or QA account password. GitHub
   Secrets protect build-time inputs only: the URL and publishable key can be
   extracted from the APK or IPA. The workflow checks syntax, not whether the
   endpoint really belongs to the isolated QA project.

2. In **GitHub → Actions → Tio Mobile QA Build → Run workflow**, select the
   intended branch and choose `android` or `ios`. The workflow is available
   after it is merged into the default branch. Only the selected platform job
   runs; there is no automatic QA build trigger and no `ui_only` choice.
3. Open that workflow run and download its seven-day artifact:

   - Android: `tio-android-qa-login-debug-apk-<run number>-<attempt>`.
   - iOS: `tio-ios-qa-login-unsigned-profile-<run number>-<attempt>`.

   Check `provenance.txt` for the selected platform, `qa_mode=qa_login`, source
   and build commit, run number, toolchain and signing status. Verify the
   downloaded file against its `.sha256` before installation. On Windows:

   ```powershell
   Get-FileHash .\Tio-qa-debug.apk -Algorithm SHA256
   Get-Content .\Tio-qa-debug.apk.sha256
   Get-FileHash .\Tio-unsigned-profile.ipa -Algorithm SHA256
   Get-Content .\Tio-unsigned-profile.ipa.sha256
   Get-Content .\provenance.txt
   ```

   Run only the hash pair for the platform you downloaded. The iOS artifact
   also includes `Podfile.lock` as CocoaPods resolution evidence.
4. For Android, enable normal test-device installation and use
   `adb install .\Tio-qa-debug.apk` from the extracted artifact folder. A
   GitHub-hosted runner creates an ephemeral debug-signing certificate. If a
   previously installed APK has the same package ID but a different signing
   certificate, Android will reject an over-the-top upgrade; preserve needed
   local test data before replacing that installation.
5. For iOS, install a current trusted Windows sideloading tool that supports local free
   Apple-ID provisioning, such as AltServer's **Sideload .ipa** action. Connect
   and trust the iPhone, enable Developer Mode when iOS requires it, and sign
   the IPA locally. Enter the Apple ID and any two-factor authentication only
   in that local tool; never put them in GitHub, repository files, workflow
   inputs, logs, or issue comments.
6. Open the installed phone app and use an existing QA account through its
   email/password form. Enter the password on the device only; keep it out of
   workflow inputs, logs, artifacts, chat and repository files. For iOS,
   re-sign or refresh before free provisioning expires (normally seven days).

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
- Both QA artifacts supply only the existing compile-time `SUPABASE_URL` and
  `SUPABASE_PUBLISHABLE_KEY` inputs, then use the current
  Supabase client, email/password auth, session repository and router guards.
  It adds no login bypass or provider integration.
- A QA build can exercise sign-in and reachable protected screens on
  the configured QA backend, but does not establish production auth/data
  parity, exhaustive RLS coverage, secure-storage durability, or physical-device
  success until the selected phone test is actually performed. Use only test accounts
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
- [ ] Android debug install or local iOS signing/install succeeds and the app appears on the Home Screen.
- [ ] Cold launch reaches the expected existing session/auth flow without a
      crash.
- [ ] Email/password sign-in succeeds with an existing QA
      account and reaches only screens allowed by the current session/router
      state; record the result without recording credentials.
- [ ] Safe areas, keyboard, text input, scrolling, sheets and back navigation
      work on the physical device.
- [ ] Light/dark appearance, larger text and TalkBack/VoiceOver receive a
      focused smoke check for the reachable screens.
- [ ] Kill/relaunch behavior is recorded separately; it is not proof that
      secure storage or any authenticated session is valid on either platform.
