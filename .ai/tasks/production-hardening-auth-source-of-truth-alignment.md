# Production Hardening — Auth Source-of-Truth Alignment

## Status

**AUDIT COMPLETE / IMPLEMENTATION REQUIRED.**

Audit head lineage:

```text
427f217d8c71c1df1cf76349e2bd1139ec420e38
```

Owner tracker: #5 P1 item 7. Coordinate with #8/#34 without absorbing their contact/linking/password scopes.

## Goal

Make the active production auth session and protected-HTTP bearer token use the same authority, while preserving current fallback adapters and keeping 401 refresh concurrency as the separate #5 item 8 lane.

## Fresh findings

### 1. Production session authority is already Supabase-first

`authSessionRepositoryProvider` currently resolves:

```text
Supabase client available
→ SupabaseAuthSessionRepository

else Firebase capability available
→ FirebaseAuthSessionRepository

else
→ InMemoryAuthSessionRepository
```

`AppSessionBootstrapController` receives this repository, so production bootstrap/session truth already follows Supabase when Supabase is configured.

### 2. Protected HTTP token authority is misaligned

`authTokenProvider` currently ignores the Supabase client and only checks the Firebase-centric `authCapabilityProvider`:

```text
Firebase capability available
→ FirebaseAuthTokenProvider

else
→ UnavailableAuthTokenProvider
```

Therefore a valid production Supabase session can coexist with an unavailable protected-HTTP bearer token provider.

This is a real source-of-truth mismatch.

### 3. Current Supabase API contract verified

Official current Supabase Flutter/Dart reference confirms:

- current bearer token is available from `supabase.auth.currentSession?.accessToken`;
- `supabase.auth.refreshSession()` force-refreshes and returns a new session whether or not the current session is expired;
- current v2 initialization can expose a locally restored session before refresh completes, so callers must remain fail-safe around missing/expired sessions and auth events.

No relevant current Auth breaking change was found that invalidates these APIs.

### 4. 401 concurrency remains item 8

`AuthInterceptor` already attempts one retry after a 401 and calls `getIdToken(forceRefresh: true)`, but there is no shared refresh mutex/future for simultaneous 401s.

Do not add the mutex in item 7. Item 7 only aligns token authority; item 8 owns refresh concurrency.

### 5. Firebase/custom-backend paths are fallback compatibility, not production authority

Current Login Google handling prioritizes `SignInWithGoogleUseCase` when Supabase is configured and only falls back to the legacy `GoogleAuthUseCase` when that path is unavailable.

Do not delete Firebase/custom-backend code mechanically in this slice. The goal is one active authority per runtime configuration, not a broad provider removal.

### 6. Firebase-centric capability naming is legacy debt

`AuthCapability` / `AuthProductState` comments and helpers still describe Firebase-specific readiness even though the production session owner is Supabase-first.

Only change semantics that are currently used for production decisions and can be made provider-neutral safely. Avoid broad API churn that is not required to fix the active authority mismatch.

## Implementation scope

- [ ] Add a `SupabaseAuthTokenProvider` implementing shared `AuthTokenProvider`.
- [ ] Normal token read uses the active Supabase session access token.
- [ ] `forceRefresh: true` delegates to `SupabaseAuth.refreshSession()` and returns the refreshed session access token.
- [ ] Missing session / refresh failure fails safely with `null`, matching the existing token-provider contract.
- [ ] Compose `authTokenProvider` Supabase-first, then Firebase fallback, then unavailable.
- [ ] Add focused token-provider tests for current token, missing session, forced refresh, and refresh failure.
- [ ] Add app composition regression proving Supabase token provider wins when a Supabase client is configured.
- [ ] Re-audit `AuthProductState` call sites and make only the minimum provider-neutral semantic correction required for current production decisions.
- [ ] Preserve Supabase-first `AuthSessionRepository` and current Account verification behavior.
- [ ] Preserve existing Google/Firebase/custom-backend fallback code unless a current consumer proves it dead and removal is separately justified.
- [ ] Full exact-head Flutter/Dart + Android CI before freeze.

## Out of scope

- Shared 401 refresh mutex/concurrency (#5 item 8).
- Password-reset result typing (#5 item 9 / #34).
- Provider linking, identifier uniqueness, password policy, or recovery (#34).
- Contact verification ownership/reconciliation (#8) beyond preserving the frozen contract.
- `OnboardingAuthDraftHandoff` redesign unless a direct source-of-truth contradiction remains after token alignment.
- Auth-provider migration/removal.
- DB/schema changes.

## Acceptance

- [ ] One active production Supabase session yields a Supabase bearer token for protected HTTP calls.
- [ ] Forced token refresh uses Supabase Auth and returns the refreshed bearer token.
- [ ] Missing/failed Supabase session does not fabricate a token.
- [ ] Firebase token provider remains a fallback only when Supabase is unavailable and Firebase capability is available.
- [ ] Session authority and protected-HTTP token authority select the same production provider.
- [ ] Existing Account Email/Mobile verification authority remains Supabase Auth.
- [ ] No 401 concurrency implementation is falsely claimed here.
- [ ] No DB migration.
- [ ] Exact-SHA Flutter/Dart + Android CI green.

## Guardrails

- Supabase Auth remains the current canonical production auth provider per #34.
- Never derive auth/authorization from user metadata.
- Never expose service-role/secret credentials in Flutter.
- Do not weaken token failures into anonymous protected requests.
- PR #50 remains Draft/open/unmerged unless separately authorized.
