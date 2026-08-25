# Production Hardening — Presentation-layer Direct Supabase Access

## Status

**AUDIT COMPLETE / IMPLEMENTATION REQUIRED.**

Audit head:

```text
e874a17ef591b956d92f41ccce491c8259af24dc
```

Owner tracker: #5 P1 item 6.

## Goal

Remove current direct Supabase identity/database reads from presentation/router-facing orchestration where an established domain/repository boundary already exists, without broadening into the separate Auth source-of-truth lane (#5 item 7).

## Fresh current-head findings

### 1. `apps/app/lib/app/router.dart` — reproducible boundary violation

`goRouterProvider` captures `supabaseClientProvider` and directly reads `supabaseClient.auth.currentUser` for product decisions:

- Account Setup `hasTrustedPhoneIdentity` derives directly from `currentUser.phone`.
- Product Onboarding `onAuthRequired` checks direct Supabase current-user readiness.
- Product Onboarding `onFinishRequested` checks direct Supabase current user before/after signup.
- completion handoff reads direct Supabase current user ID.

These reads bypass the already established provider-neutral `AuthSessionRepository` / `authSessionStateProvider` boundary. `AuthSession` already carries `userId`, Email, Phone and verification state, and `AuthSessionRepository.currentSessionState` can provide an invocation-time snapshot.

### 2. `apps/app/lib/app/profile/profile_completion.dart` — reproducible direct query

`profileCompletionSummaryProvider`:

- reads `supabaseClientProvider` directly;
- reads `client.auth.currentUser` directly;
- constructs `SupabaseUserProfileRepository` directly;
- executes a direct `public.users` query for `username,mobile`.

This duplicates data already composed by canonical `profileDataProvider` and trusted Auth data already exposed by `authSessionStateProvider`.

`profileCompletionReminderScopeProvider` also reads Supabase `currentUser.lastSignInAt/createdAt` directly to create a login-cycle reminder key.

### 3. Legitimate composition — do not remove mechanically

The following are infrastructure/composition boundaries, not presentation queries by themselves:

- `apps/app/lib/app/network_providers.dart` creating Supabase-backed repositories;
- `apps/app/lib/app/account_setup/account_setup_providers.dart` constructing `SupabaseAccountSetupRepository`;
- `apps/app/lib/app/profile/profile_settings_route.dart` composition provider constructing canonical repositories before passing domain/use-case boundaries.

Do not replace normal dependency injection merely to eliminate the string `Supabase`.

### 4. Deferred to #5 item 7 — Auth source-of-truth alignment

`apps/app/lib/app/onboarding/onboarding_auth_draft_handoff.dart` directly subscribes to Supabase Auth because its current responsibility is identity/session handoff, not a presentation database query. Moving that owner requires deciding the broader provider-neutral auth event contract and belongs to item 7.

Likewise `network_providers.dart` still contains Firebase/custom-backend capability fallbacks and Supabase-specific readiness composition. Do not redesign auth-provider authority inside item 6.

### 5. Username boundary

Current Account Setup/username presentation already receives `ProfileAccountRepository` and uses the server-owned username availability/claim contract. No current evidence justifies bypassing or replacing that contract. Preserve it.

## Implementation scope

- [ ] Remove `supabaseClientProvider` capture/read from `router.dart` product decisions.
- [ ] Use `AuthSessionRepository.currentSessionState` for invocation-time auth readiness after signup and before finalization.
- [ ] Use provider-neutral `AuthSession` Phone for Account Setup trusted-phone identity.
- [ ] Use provider-neutral `AuthSession.userId` for post-onboarding ready handoff.
- [ ] Rewrite `profileCompletionSummaryProvider` to compose canonical `profileDataProvider` + `authSessionStateProvider`, with no direct Supabase query/concrete repository construction.
- [ ] Replace `profileCompletionReminderScopeProvider` direct Supabase user read with provider-neutral Auth session data while preserving the existing per-real-login-cycle behavior.
- [ ] Add the minimum provider-neutral session field needed for reminder cycle identity if required; map it in Supabase/Firebase adapters without changing auth authority.
- [ ] Preserve canonical username repository/use-case behavior unchanged.
- [ ] Add focused router/profile-completion regressions proving no direct Supabase dependency is required for these product decisions.
- [ ] Full exact-head Flutter/Dart + Android CI before freeze.

## Out of scope

- Auth provider switch or removal of Firebase/custom backend fallbacks.
- `OnboardingAuthDraftHandoff` auth-event ownership rewrite.
- 401/token refresh behavior.
- Password reset/change-password/linking.
- Avatar storage lifecycle.
- Profile realtime subscription redesign.
- Account deletion.
- Product Onboarding flow/schema changes.
- Supabase schema/DDL changes.

## Acceptance

- [ ] `router.dart` contains no direct `supabaseClientProvider` / `SupabaseClient.auth.currentUser` product-decision read.
- [ ] Profile completion contains no direct Supabase query/current-user read or concrete Supabase repository construction.
- [ ] Account Setup trusted-phone decision remains correct.
- [ ] Product Onboarding auth checkpoint/finalization still requires a real authenticated session.
- [ ] Post-onboarding ready handoff uses the authenticated domain session user ID.
- [ ] Profile completion fields remain canonical and reminder dismissal remains login-cycle scoped.
- [ ] Username availability/claim semantics unchanged.
- [ ] No DB migration.
- [ ] Exact-SHA CI green.

## Guardrails

- Do not mark #5 item 7 complete from this work.
- Do not reintroduce direct client-authoritative contact verification.
- Do not broaden into schema ownership changes.
- PR #50 remains Draft/open/unmerged unless separately authorized.
