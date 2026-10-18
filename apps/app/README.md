# Tio App

Flutter Android and iOS phone app shell.

## Free physical-iPhone UI testing

The repository can create an **unsigned** iPhone artifact for the first
physical-device UI-testing lane. It is deliberately separate from production
release, TestFlight, App Store, Apple Watch, provider activation, and Supabase
deployment.

1. In GitHub Actions, manually run **iOS UI Build** for the intended commit and
   download `tio-ios-unsigned-profile-<run number>`.
2. On Windows, verify the artifact before use:

   ```powershell
   Get-FileHash .\Tio-unsigned-profile.ipa -Algorithm SHA256
   Get-Content .\Tio-unsigned-profile.ipa.sha256
   Get-Content .\provenance.txt
   Get-Content .\Podfile.lock
   ```

3. Install a current trusted Windows sideloading tool that supports local free
   Apple-ID provisioning, such as AltServer's **Sideload .ipa** action. Connect
   and trust the iPhone, enable Developer Mode when iOS requires it, and sign
   the IPA locally. Enter the Apple ID and any two-factor authentication only
   in that local tool; never put them in GitHub, repository files, workflow
   inputs, logs, or issue comments.
4. Open the installed app and perform the UI smoke checks below. Re-sign or
   refresh the app before free provisioning expires (normally seven days).

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
- With no `SUPABASE_URL` or publishable key, profile mode reaches the existing
  unauthenticated UI path. It is evidence for startup, safe areas, input,
  scrolling, sheets, navigation, light/dark rendering, text scaling and
  VoiceOver smoke checks. It is not evidence for authenticated flows, data
  writes, persistence, or backend parity.
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
  UI-only workflow.

### Device smoke checklist

- [ ] Artifact checksum and provenance match the selected GitHub run.
- [ ] Local signing/install succeeds and the app appears on the Home Screen.
- [ ] Cold launch reaches the existing unauthenticated flow without a crash.
- [ ] Safe areas, keyboard, text input, scrolling, sheets and back navigation
      work on the physical device.
- [ ] Light/dark appearance, larger text and VoiceOver receive a focused smoke
      check for the reachable screens.
- [ ] Kill/relaunch behavior is recorded separately; it is not proof that
      secure storage or any authenticated session is valid on iOS.
