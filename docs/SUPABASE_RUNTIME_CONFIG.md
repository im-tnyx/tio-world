# Supabase Runtime Configuration

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

## Legacy compatibility

`SUPABASE_ANON_KEY` is accepted only as an explicit compatibility input for a legacy anon key. New build configuration should use `SUPABASE_PUBLISHABLE_KEY`.

## Failure policy

- release build with missing or partial Supabase configuration: startup fails closed;
- release Supabase initialization failure: error propagates instead of silently switching to an in-memory/no-backend session;
- debug/test build with no Supabase values: the existing no-Supabase local/test composition remains available;
- no build silently selects the production project when defines are omitted.
