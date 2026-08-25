# Production Hardening — 401 Token Refresh Concurrency

## Status

**COMPLETE / FROZEN.**

Audit head lineage:

```text
691c719415525df8b726b4da7e3a07cd25a91f76
```

Accepted source/test checkpoint:

```text
701a0627fe2c0d71338facde875b27d7836b9131
Flutter CI #1900 / run 32818123295 ✅
Android Native CI #312 / run 32818123288 ✅
```

Owner tracker: #5 P1 item 8.

## Goal

Ensure simultaneous protected HTTP 401 responses share one forced auth-token refresh while preserving the existing one-retry-per-request contract and provider-neutral `AuthTokenProvider` boundary.

## Accepted result

### Shared forced-refresh owner

`AuthInterceptor` now keeps one interceptor-instance `_inFlightRefresh` future.

```text
first 401
→ AuthTokenProvider.getIdToken(forceRefresh: true)
→ store in-flight future

concurrent first 401s
→ await the same future

refresh completes / returns null / throws
→ clear in-flight slot
```

Only forced refresh work is coalesced. Normal HTTP requests remain parallel.

### Retry semantics preserved

- `_tio_auth_retried` still limits each original request to one retry.
- A successful shared refresh supplies the same refreshed token to every waiting request, and each request retries independently once.
- A retry that returns 401 is not refreshed/retried again.
- Non-401 behavior is unchanged.
- No bearer token is cached beyond the in-flight coordination future.

### Failure behavior

A null or failed refresh does not fabricate credentials. All waiting requests continue through the existing failure path. The shared refresh slot is cleared in `finally`, so a later independent 401 can start a new provider refresh.

### Provider boundary preserved

The interceptor still coordinates exclusively through `AuthTokenProvider`. It does not call Supabase, Firebase, or another auth SDK directly. Item 7's production-first Supabase authority remains unchanged.

## Implementation scope

- [x] Add one interceptor-instance shared in-flight refresh future/mutex.
- [x] First 401 starts `getIdToken(forceRefresh: true)`.
- [x] Concurrent 401 handlers await the same in-flight refresh.
- [x] Clear the in-flight future after success, null result, or exception.
- [x] Preserve one retry per original request through `_tio_auth_retried`.
- [x] Preserve per-request retry with the shared refreshed token.
- [x] Preserve non-401 behavior and error mapping unchanged.
- [x] Add focused simultaneous-401 regression proving one forced refresh and one successful retry per request.
- [x] Add failed/shared-refresh regression proving all waiters fail closed and a later request may attempt a new refresh.
- [x] Full exact-head Flutter/Dart + Android CI green.

## Focused regressions

```text
apps/shared/test/network/api_client_test.dart
```

Coverage includes:

- simultaneous initial 401s share exactly one forced refresh;
- both requests retry once with the shared refreshed token;
- shared refresh failure produces no credential or infinite retry;
- refresh slot releases after failure;
- a later independent 401 can refresh successfully;
- existing single-request 401, retry-401 termination, missing token, 403, and transport mapping remain green.

## Acceptance

- [x] Two or more simultaneous first-401 responses cause exactly one `forceRefresh` provider call while it is in flight.
- [x] Each original request retries at most once.
- [x] All concurrent waiters receive/use the shared refreshed token when refresh succeeds.
- [x] Refresh null/failure does not fabricate credentials or loop.
- [x] The shared refresh slot is released after completion/failure.
- [x] Later independent 401 can start a new refresh.
- [x] Existing single-request/non-401 contracts remain green.
- [x] No DB migration.
- [x] Exact-SHA CI green.

## Guardrails

- `AuthInterceptor` remains provider-neutral.
- Only forced refresh work is serialized/coalesced; HTTP requests themselves are not serialized.
- No bearer token logging or long-lived interceptor token cache was introduced.
- Password/reset/linking work remains outside this slice.
- PR #50 remains Draft/open/unmerged unless separately authorized.
