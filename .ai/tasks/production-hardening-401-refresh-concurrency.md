# Production Hardening — 401 Token Refresh Concurrency

## Status

**AUDIT COMPLETE / IMPLEMENTATION REQUIRED.**

Audit head lineage:

```text
691c719415525df8b726b4da7e3a07cd25a91f76
```

Owner tracker: #5 P1 item 8.

## Goal

Ensure simultaneous protected HTTP 401 responses share one forced auth-token refresh while preserving the existing one-retry-per-request contract and provider-neutral `AuthTokenProvider` boundary.

## Fresh findings

### Current retry behavior

`AuthInterceptor` currently:

- attaches the token from `AuthTokenProvider.getIdToken()`;
- on 401, checks `_tio_auth_retried`;
- calls `getIdToken(forceRefresh: true)`;
- retries the original request once with the refreshed token;
- does not retry a second 401 indefinitely;
- does not refresh on non-401 responses.

Existing tests already cover single-request refresh, retry-401 termination, missing token, 403 behavior, and error mapping.

### Reproduced concurrency gap

There is no shared refresh mutex/future. Each concurrent request entering `onError` with a first 401 independently calls:

```text
getIdToken(forceRefresh: true)
```

Therefore simultaneous 401 responses can trigger duplicate provider refreshes. With rotating refresh-token systems this is unnecessary and can amplify auth races.

### Provider boundary

Item 7 already aligned active production session/token authority: Supabase is production-first, Firebase is fallback. Item 8 must remain provider-neutral and coordinate only through `AuthTokenProvider`; it must not call Supabase/Firebase SDKs directly.

## Implementation scope

- [ ] Add one interceptor-instance shared in-flight refresh future/mutex.
- [ ] First 401 starts `getIdToken(forceRefresh: true)`.
- [ ] Concurrent 401 handlers await the same in-flight refresh.
- [ ] Clear the in-flight future after success, null result, or exception so later independent 401s can retry refresh normally.
- [ ] Preserve one retry per original request through `_tio_auth_retried`.
- [ ] Preserve per-request retry with the shared refreshed token.
- [ ] Preserve non-401 behavior and error mapping unchanged.
- [ ] Add focused simultaneous-401 regression proving one forced refresh and one successful retry per request.
- [ ] Add failed/shared-refresh regression proving all waiting requests fail without an infinite retry and a later request may attempt a new refresh.
- [ ] Full exact-head Flutter/Dart + Android CI before freeze.

## Out of scope

- Auth provider/source-of-truth selection (#5 item 7, frozen).
- Refresh-token storage/rotation policy changes.
- Password/reset/linking work.
- Session revocation/account deletion.
- API endpoint changes.
- DB/schema changes.

## Acceptance

- [ ] Two or more simultaneous first-401 responses cause exactly one `forceRefresh` provider call while it is in flight.
- [ ] Each original request retries at most once.
- [ ] All concurrent waiters receive/use the shared refreshed token when refresh succeeds.
- [ ] Refresh null/failure does not fabricate credentials or loop.
- [ ] The shared refresh slot is released after completion/failure.
- [ ] Later independent 401 can start a new refresh.
- [ ] Existing single-request/non-401 contracts remain green.
- [ ] No DB migration.
- [ ] Exact-SHA CI green.

## Guardrails

- Keep `AuthInterceptor` provider-neutral.
- Do not serialize all HTTP requests; only coalesce forced refresh work.
- Do not cache bearer tokens beyond the in-flight refresh coordination needed here.
- Never log auth tokens.
- PR #50 remains Draft/open/unmerged unless separately authorized.
