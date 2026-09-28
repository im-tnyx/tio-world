# Security

Document Status: Canonical Live Doc
Last Verified: 2026-09-28
Owner: repository security governance
Truth Boundary: Authoritative for baseline repository/product security and secret-handling rules; not evidence that every control has been independently audited.

`tio-world` is a health and fitness product. Treat privacy, safety, and trust as product requirements.

Cross-cutting data classification, minimization, retention, deletion/export, AI/provider, and environment-separation policy lives in [Data & Privacy Governance](DATA_PRIVACY_GOVERNANCE.md).

Canonical client-safe/server-secret classification, environment isolation, rotation/revocation, and credential-exposure response lives in [Secrets & Environment Strategy](SECRETS_AND_ENVIRONMENTS.md).

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

Server-only operations and privileged credentials belong only in an approved trusted server/runtime boundary.

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

Supabase Auth is the canonical identity authority. See [Authentication Architecture](AUTH_ARCHITECTURE.md).

Canonical first-party protected-service direction:

```text
UI
  ↓
Auth controller / repository
  ↓
Supabase Auth session
  ↓
Supabase access token
  ↓
Authenticated API client (`Authorization: Bearer <token>`)
  ↓
Future Tio API authentication middleware
  ↓
Verify Supabase token and derive canonical user identity from verified `sub`
  ↓
Resource authorization
```

Delegated external connectors use a separate Tio-controlled authentication path and do not require or receive the user's Supabase session as their public credential:

```text
External connector
  ↓
Validated Tio connector credential
  ↓
Connector client + user-owned grant
  ↓
Canonical Tio user resolved from the validated grant
  ↓
Effective scopes + domain/resource authorization
  ↓
Bounded Tio capability
```

The connector credential's own subject/client identifier is not the canonical Tio user identity. See [Authentication Architecture](AUTH_ARCHITECTURE.md), [Connector Trust Boundary](../integrations/CONNECTOR_TRUST_BOUNDARY.md), and [ADR-0012](../adr/0012-delegated-external-connector-trust-boundary.md).

Firebase Admin token verification is not the target Tio backend architecture. Any Firebase-named auth adapters or historical diagrams remaining elsewhere in the repository are legacy/compatibility context unless a separately approved migration task proves an active dependency.

Rules:

- Never persist raw access or refresh tokens manually in `SharedPreferences`, SQLite plaintext, or custom unencrypted storage.
- Never log `Authorization` headers, Supabase access tokens, refresh tokens, or Bearer credentials. Authorization data must be sanitized/redacted in logs.
- Sensitive request bodies (DOB, current weight, health conditions, workout concerns, nutrition targets) must never be printed to stdout or debug logs.
- Mobile/watch clients must never contain Supabase `service_role` or other server-secret credentials.
- A first-party protected API caller using a Supabase session must derive user identity from the cryptographically verified Supabase token `sub`, not from a client-supplied `user_id`, Email, Phone, or provider payload.
- A delegated connector caller must derive the canonical Tio user from the validated user-owned connector grant after client/grant/scope resolution; the connector credential's own subject/client identifier is not a substitute for that grant-to-user mapping.
- Authentication and authorization remain separate: a valid token does not grant access to every user/resource.
- Exact first-party Supabase token-verification libraries/claim rules and delegated connector credential/grant-verification mechanics must be verified in their separately authorized implementation slices.
- If an API client implements token refresh after a `401`, retries must be bounded; repeated rejection must fail fast without infinite loops.
- `403 Forbidden` must not trigger authentication-refresh loops.

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
