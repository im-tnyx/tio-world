# Production Hardening — Auth Source-of-Truth Alignment

## Status

**COMPLETE / FROZEN.**

Audit head lineage:

```text
427f217d8c71c1df1cf76349e2bd1139ec420e38
```

Accepted source/test checkpoint:

```text
7e971590c6bb8106ef01095aedba8fc4d022929b
Flutter CI #1896 / run 32812159586 ✅
Android Native CI #308 / run 32812159562 ✅
```

Owner tracker: #5 P1 item 7. #8/#34 remain authoritative for contact verification, linking, password, recovery, and uniqueness.

## Goal

Make the active production auth session and protected-HTTP bearer token use the same authority, while preserving current fallback adapters and keeping 401 refresh concurrency as the separate #5 item 8 lane.

## Accepted result

### Production session + token authority are aligned

Runtime selection is now:

```text
Supabase client available
→ SupabaseAuthSessionRepository
→ SupabaseAuthTokenProvider

else Firebase capability available
→ FirebaseAuthSessionRepository
→ FirebaseAuthTokenProvider

else
→ InMemoryAuthSessionRepository
→ UnavailableAuthTokenProvider
```

Production Supabase Auth therefore owns both session truth and the bearer token used by protected HTTP calls.

### Supabase bearer-token adapter

`SupabaseAuthTokenProvider` implements shared `AuthTokenProvider`:

- normal reads use `supabase.auth.currentSession?.accessToken`;
- `forceRefresh: true` calls `supabase.auth.refreshSession()` and returns the refreshed session access token;
- empty/missing token, missing session behavior, and SDK/network failures fail closed with `null`;
- token normalization trims accidental whitespace;
- no service-role/secret credential is introduced.

Official current Supabase Flutter/Dart documentation was checked before implementation; the current session and `refreshSession()` APIs are supported, and no relevant current Auth breaking change invalidates this integration.

### Compatibility paths retained intentionally

Firebase/custom-backend code remains as fallback compatibility. Current Login Google behavior already prioritizes the Supabase `SignInWithGoogleUseCase` when Supabase is available, so no broad provider-removal change was justified.

`AuthCapability` / `AuthProductState` retain legacy Firebase-centric helpers because current call-site audit found no active production decision that requires broad semantic churn after session/token authority was aligned. This does not redefine Supabase production authority.

### 401 concurrency explicitly deferred

`AuthInterceptor` still owns one retry on 401 and calls `getIdToken(forceRefresh: true)`. It still has no shared refresh mutex/future for simultaneous 401 responses. That is intentionally **not** claimed complete here and remains #5 item 8.

## Implementation scope

- [x] Add `SupabaseAuthTokenProvider` implementing shared `AuthTokenProvider`.
- [x] Normal token read uses the active Supabase session access token.
- [x] `forceRefresh: true` delegates to `SupabaseAuth.refreshSession()` and returns the refreshed session access token.
- [x] Missing/failed token access fails safely with `null`.
- [x] Compose `authTokenProvider` Supabase-first, then Firebase fallback, then unavailable.
- [x] Add focused current-token, missing-token, forced-refresh, and refresh-failure tests.
- [x] Add app composition regression proving Supabase wins when configured.
- [x] Re-audit `AuthProductState` call sites; no additional production semantic correction was required in this bounded slice.
- [x] Preserve Supabase-first session repository and frozen Account verification behavior.
- [x] Preserve current Google/Firebase/custom-backend fallback code.
- [x] Full exact-head Flutter/Dart + Android CI green.

## Focused regressions

```text
apps/features/auth/test/data/supabase_auth_token_provider_test.dart
apps/app/test/app/production_hardening_auth_source_of_truth_test.dart
```

## Acceptance

- [x] One active production Supabase session yields a Supabase bearer-token adapter for protected HTTP calls.
- [x] Forced token refresh uses Supabase Auth and returns the refreshed bearer token.
- [x] Missing/failed Supabase token access does not fabricate a token.
- [x] Firebase remains fallback only when Supabase is unavailable and Firebase capability is available.
- [x] Session authority and protected-HTTP token authority select the same production provider.
- [x] Existing Account Email/Mobile verification authority remains Supabase Auth.
- [x] No 401 concurrency implementation is falsely claimed here.
- [x] No DB migration.
- [x] Exact-SHA Flutter/Dart + Android CI green.

## Guardrails

- Supabase Auth remains the current canonical production auth provider per #34.
- Never derive auth/authorization from user metadata.
- Never expose service-role/secret credentials in Flutter.
- Protected token failure remains fail-closed.
- PR #50 remains Draft/open/unmerged unless separately authorized.
