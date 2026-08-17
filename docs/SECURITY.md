# Security

`tio-world` is a health and fitness product. Treat privacy, safety, and trust as product requirements.

## Public Repository Rule

This repository is public. Assume anything committed here can be seen by other people.

Before every commit, check:

```bash
git status -sb
git diff --stat
git diff --check
```

## Never Commit

Do not commit:

- `.env` files
- signing files
- private certificates
- local machine paths
- production logs
- real user exports
- health records
- local database dumps
- APK, AAB, IPA, or archive artifacts
- screenshots containing personal information

## Environment Files

Keep local environment files out of Git.

Allowed pattern:

```text
.env.example
```

Not allowed:

```text
.env
.env.local
.env.production
```

## Client Safety

Mobile and watch apps should only contain values safe for client distribution.

Server-only operations should stay in backend code.

## Health Data

Health and fitness data can be sensitive.

Rules:

- collect only what the feature needs
- show clear user intent for connected services
- avoid logging personal health details
- keep screenshots clean before sharing in issues or PRs
- avoid putting real user data in test fixtures
- do not persist onboarding body/health answers as plain JSON in
  `SharedPreferences`; unfinished drafts are stored exclusively in RLS-protected
  PostgreSQL (`public.onboarding_drafts`) using authenticated user identity (`auth.uid() = user_id`)
- keep onboarding analytics limited to step/status metadata and never include
  entered values, body metrics, free text, email, or tokens
- cleared automatically upon successful onboarding finish; stale draft clean-up
  failure does not compromise or rollback completed status

## Supabase Storage

The planned `profile`, `nutrition`, `workout`, and `progress` buckets are private user-media boundaries, not general file dumps or structured-data stores. Each bucket must have owner-specific Storage RLS policies, authenticated user-ID object paths, constrained content type/size, and explicit deletion/retention behavior before it is created.

Do not expose health/fitness media through public buckets or public URLs by default. Supabase secret/service-role credentials remain server-only and are never used to bypass user access from a client.

## Authentication & Token Security

Auth flows should avoid leaking implementation details into UI.

Recommended direction:

```text
UI
  ↓
Auth controller
  ↓
AuthSessionRepository
  ↓
AuthTokenProvider / Identity Provider
  ↓
AuthenticatedApiClient (with AuthInterceptor & Bearer Token)
  ↓
Backend (Firebase Admin verifies token -> resolves firebase_uid)
```

Rules:
- Never persist raw ID tokens manually in `SharedPreferences`, SQLite plaintext, or custom unencrypted storage.
- Never log `Authorization` headers, Firebase ID tokens, or Bearer credentials. `AuthInterceptor` sanitizes/redacts all Authorization headers to `Bearer [REDACTED]` in logs.
- Sensitive request bodies (DOB, current weight, health conditions, workout concerns, nutrition targets) must never be printed to stdout or debug logs.
- 401 response forces a single token refresh attempt; if the refreshed token is also rejected with 401, the client fails fast with a typed `UnauthenticatedException` without infinite loops.
- 403 Forbidden responses never trigger token refresh loops.

## Watch Security

Watch apps should store minimum local data.

Recommended watch local state:

- current workout session
- current set input
- rest timer state
- pending sync metadata

Avoid storing long-term history on watch unless required.

## Review Checklist

Before merging security-sensitive work:

- [ ] No local environment files are included.
- [ ] No real user data is included.
- [ ] No build artifacts are included.
- [ ] Logs are clean.
- [ ] Screenshots are clean.
- [ ] Data access is behind repository/API boundaries.
- [ ] Backend-only behavior is not implemented in client code.
