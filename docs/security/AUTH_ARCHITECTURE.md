# Authentication Architecture

## Status

**Canonical architecture — Supabase Auth is the identity authority.**

This document supersedes older Firebase-oriented architecture text in the repository. Firebase-named adapters or historical references may still exist in source/history for compatibility or migration context, but they do **not** define the target Tio authentication or backend contract.

No backend runtime implementation is introduced by this document.

## Canonical Identity Contract

```text
Supabase Auth
  -> auth.users.id
  -> canonical Tio user UUID
  -> public.users.id uses the same UUID as the application/domain root
```

Rules:

- Supabase Auth owns authentication and session issuance.
- `auth.users.id` is the canonical authenticated user identity.
- `public.users.id` is the matching application/domain root and must not become a second identity authority.
- Email, Phone, Google, and future sign-in methods may attach to the same canonical Supabase Auth user according to the approved identity-linking rules.
- The application must never silently merge or switch canonical UUIDs based only on identifier equality.
- Client-provided user IDs, emails, phone numbers, provider metadata, or booleans are not authentication proof.

## Current Client Responsibility

The phone/watch client is responsible for:

1. authenticating through approved Supabase Auth flows;
2. maintaining the Supabase session through the supported client SDK;
3. obtaining the current Supabase access token when a protected Tio API exists;
4. sending that token as a Bearer credential over TLS;
5. treating `401` as unauthenticated and never inventing local authenticated state;
6. never shipping server/service-role secrets.

The client does **not** verify its own token as proof of identity and does not choose the authoritative user UUID sent to a protected backend.

## Planned Protected API Contract

Backend implementation is intentionally deferred. When a protected Tio API is introduced, the canonical flow is:

```text
Tio client
  -> Supabase Auth session
  -> Supabase access token
  -> Authorization: Bearer <access-token>
  -> Tio API authentication middleware
  -> cryptographically verify token against the configured Supabase project
  -> validate required claims/expiry/issuer/audience as defined by the implementation contract
  -> derive canonical user identity from token subject (`sub`)
  -> authorize the requested resource/action
```

Conceptually:

```text
Supabase Auth -> access token -> Tio API -> verified user identity
```

The future API must derive identity from the verified token. It must not accept a request-body/header `user_id` as a substitute for authentication.

## Server Responsibility

When backend work is explicitly authorized, server-side authentication should:

- verify the Supabase access token using the approved Supabase verification mechanism for that runtime;
- reject invalid, expired, malformed, wrong-project, or otherwise untrusted tokens;
- derive the user UUID from the verified token subject;
- separate authentication from resource authorization;
- never expose Supabase `service_role`/secret credentials to mobile/watch clients;
- avoid logging raw Bearer tokens, authorization headers, refresh tokens, or private identity claims;
- keep privileged service credentials in server-only secret management;
- use least-privilege database/service access for the operation being performed.

Exact middleware/library choices belong to the future backend implementation slice and must be verified against current Supabase documentation at that time.

## Firebase References

Firebase Auth / Firebase Admin is **not** the canonical Tio identity architecture.

Any existing repository references such as:

- `FirebaseAuthSessionRepository`
- `FirebaseAuthTokenProvider`
- Firebase ID-token examples
- Firebase Admin token-verification diagrams
- legacy Google -> Firebase -> custom-backend onboarding descriptions

must be interpreted as historical/compatibility implementation context unless a separately approved migration task explicitly proves a current runtime dependency.

Do not build new backend authentication around Firebase Admin. Do not add a Firebase token-verification dependency to the planned Tio API merely because legacy adapters remain in source.

## Supabase Auth vs Application Projections

Supabase Auth is also the trusted confirmation-evidence authority for current contact verification:

```text
auth.users.email_confirmed_at
  -> trusted evidence for current Auth Email

auth.users.phone_confirmed_at
  -> trusted evidence for current Auth Phone
```

Application fields such as `public.users.email_verified_at` and `mobile_verified_at` are provider-neutral projections, not independent authentication authorities.

## Security Boundary

Authentication answers **who is the caller?**

Authorization answers **may that caller perform this operation on this resource?**

A valid Supabase token does not automatically authorize access to every row or privileged operation. Supabase RLS, server authorization policy, and owner-specific service boundaries remain required.

## Backend Implementation Gate

Backend code is not started by this architecture decision.

Until a separately approved implementation task begins:

- no Fastify/server scaffold is required;
- no API authentication middleware is required;
- no Firebase Admin replacement package is required;
- no deployment/runtime infrastructure is required;
- no Supabase schema mutation is required solely for this document.

This document exists so future backend work starts from the correct identity contract rather than stale Firebase architecture.

## Acceptance for TNYX-21

- [x] Supabase Auth is documented as the canonical identity provider.
- [x] Canonical protected-API flow is documented as Supabase Auth -> access token -> Tio API -> verified user identity.
- [x] Client and future server authentication responsibilities are separated.
- [x] Firebase Admin token verification is explicitly rejected as the target backend architecture.
- [x] Legacy Firebase-named references are classified as historical/compatibility context, not authority.
- [x] No backend runtime implementation is introduced by this documentation slice.
