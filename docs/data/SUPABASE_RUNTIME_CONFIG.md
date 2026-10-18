# Supabase Runtime Configuration

Document Status: Canonical Live Doc
Last Verified: 2026-10-19
Owner: `apps/app` startup + Supabase platform
Truth Boundary: Authoritative for client-safe Supabase runtime configuration requirements; source/config prove actual bootstrap behavior and release values.

The Flutter phone app does not embed a default Supabase project. Backend selection is explicit at build time.

## Required release values

Provide both values when building or running a backend-connected release:

```text
SUPABASE_URL
SUPABASE_PUBLISHABLE_KEY
```

Use the client-safe publishable key (`sb_publishable_...`). Never place a Supabase secret/service-role key in the Flutter client.

Example with placeholders:

```bash
cd apps/app
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=sb_publishable_YOUR_KEY
```

Apply the same defines to `flutter build apk`, `flutter build appbundle`, or the store/release build command.

## Android Studio QA run

Keep the local QA values in the ignored `apps/app/.runtime.qa.json` file. The
Flutter run configuration must pass that file explicitly; Flutter does not
discover or load it automatically.

In **Run > Edit Configurations > Flutter Run -> 'tio_app'**, set **Additional
run args** to:

```text
--dart-define-from-file=.runtime.qa.json
```

The Flutter plugin runs this configuration from the `apps/app` package root,
so the relative path above resolves to `apps/app/.runtime.qa.json`. This applies
to Android Studio **Run/Debug**, which builds and installs the app on the chosen
device. Android Studio's standalone APK build action does not inherit a run
configuration; for an installable QA APK, build explicitly from `apps/app`:

```bash
flutter build apk --debug --dart-define-from-file=.runtime.qa.json
```

## Manual iOS physical-device QA build

The **iOS UI Build** workflow remains `workflow_dispatch` only and defaults to
`ui_only`, which does not require Supabase configuration. For an authenticated
QA artifact, the owner manually selects `qa_login` and configures these GitHub
repository Actions secrets:

```text
TIO_IOS_QA_SUPABASE_URL
TIO_IOS_QA_SUPABASE_PUBLISHABLE_KEY
```

The workflow reads them only in the `qa_login`-gated step, validates an HTTPS
Supabase project endpoint and the `sb_publishable_` key type, rejects
privileged/service-role values, then creates a restrictive temporary
`--dart-define-from-file` JSON under `$RUNNER_TEMP`. It removes the file after
the build and does not log, cache, commit, or upload it. The ignored local
`apps/app/.runtime.qa.json` file is not available to GitHub Actions and is not
used by this iOS workflow.

GitHub Secrets protect the build-time inputs; the URL and publishable key are
embedded in the app and can be extracted from the compiled IPA. Configure only
an isolated QA Supabase project and a client-safe publishable key. The workflow
can validate endpoint syntax but cannot infer whether a project is truly QA or
production, so the owner must ensure the secret points to the QA project. Never
configure a service-role, `sb_secret_`, Apple, OAuth, or account credential.
Enter the existing QA account's email/password only on the iPhone during the
manual smoke test.

The workflow file must first exist on the default branch for GitHub to offer
manual dispatch. After PR #608 is merged, select the
`tnyx/ios-free-device-ui-testing` branch in the Run workflow selector and
manually dispatch the workflow.

## Legacy compatibility

`SUPABASE_ANON_KEY` is accepted only as an explicit compatibility input for a legacy anon key. New build configuration should use `SUPABASE_PUBLISHABLE_KEY`.

## Failure policy

- release build with missing or partial Supabase configuration: startup fails closed;
- release Supabase initialization failure: error propagates instead of silently switching to an in-memory/no-backend session;
- debug/test build with no Supabase values: the existing no-Supabase local/test composition remains available;
- no build silently selects the production project when defines are omitted.
