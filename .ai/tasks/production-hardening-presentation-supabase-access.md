# Production Hardening — Presentation-layer Direct Supabase Access

## Status

**COMPLETE / FROZEN.**

Audit head:

```text
e874a17ef591b956d92f41ccce491c8259af24dc
```

Accepted source/test checkpoint:

```text
3579fec0fe056ab70bfc25f2ed514b3331b02485
Flutter CI #1889 / run 32811372682 ✅
Android Native CI #301 / run 32811372678 ✅
```

Owner tracker: #5 P1 item 6.

## Goal

Remove direct Supabase identity/database reads from presentation/router-facing orchestration where an established domain/repository boundary already exists, without broadening into the separate Auth source-of-truth lane (#5 item 7).

## Fresh audit findings

### 1. `apps/app/lib/app/router.dart` — reproduced and fixed

The router had captured `supabaseClientProvider` and directly read `supabaseClient.auth.currentUser` for Account Setup Phone identity, Product Onboarding auth readiness, post-signup checks, and post-onboarding user ID handoff.

Those product decisions now use the provider-neutral `AuthSessionRepository` / `authSessionStateProvider` boundary. Invocation-time auth checks use `AuthSessionRepository.currentSessionState`, and post-onboarding ready handoff uses `AuthSession.userId`.

### 2. `apps/app/lib/app/profile/profile_completion.dart` — reproduced and fixed

Profile completion previously read `supabaseClientProvider`, `auth.currentUser`, directly constructed a `SupabaseUserProfileRepository`, and queried `public.users`.

It now composes canonical `profileDataProvider` plus `authSessionStateProvider`. Reminder scope uses provider-neutral `AuthSession.userId` + `loginCycleId`.

### 3. Provider-neutral login-cycle identity

`AuthSession` now carries nullable `loginCycleId`. Supabase maps it from `lastSignInAt` with `createdAt` fallback; the Firebase adapter maps its available sign-in-cycle timestamp without changing auth authority. This preserves reminder dismissal per real login cycle while removing presentation ownership of SDK user objects.

### 4. Legitimate composition retained

Infrastructure composition in `network_providers.dart`, Account Setup providers, and Profile Settings repository factories remains intentionally Supabase-aware. Dependency injection is not a presentation bypass.

### 5. Deferred to #5 item 7

`OnboardingAuthDraftHandoff` and the broader Supabase/Firebase/custom-backend auth authority remain item 7. This slice does not claim they are solved.

## Implementation scope

- [x] Remove `supabaseClientProvider` capture/read from `router.dart` product decisions.
- [x] Use `AuthSessionRepository.currentSessionState` for invocation-time auth readiness after signup and before finalization.
- [x] Use provider-neutral `AuthSession` Phone for Account Setup trusted-phone identity.
- [x] Use provider-neutral `AuthSession.userId` for post-onboarding ready handoff.
- [x] Rewrite `profileCompletionSummaryProvider` to compose canonical `profileDataProvider` + `authSessionStateProvider`.
- [x] Replace reminder-scope direct Supabase user read with provider-neutral Auth session data.
- [x] Add provider-neutral `loginCycleId` and map it in current adapters.
- [x] Preserve canonical username repository/use-case behavior unchanged.
- [x] Add focused router/profile-completion regressions.
- [x] Full exact-head Flutter/Dart + Android CI green.

## Acceptance

- [x] `router.dart` contains no direct `supabaseClientProvider` / `SupabaseClient.auth.currentUser` product-decision read.
- [x] Profile completion contains no direct Supabase query/current-user read or concrete Supabase repository construction.
- [x] Account Setup trusted-phone decision remains correct.
- [x] Product Onboarding auth checkpoint/finalization still requires a real authenticated session.
- [x] Post-onboarding ready handoff uses the authenticated domain session user ID.
- [x] Profile completion fields remain canonical and reminder dismissal remains login-cycle scoped.
- [x] Username availability/claim semantics unchanged.
- [x] No DB migration.
- [x] Exact-SHA CI green.

## Focused regression

```text
apps/app/test/app/production_hardening_presentation_supabase_access_test.dart
```

The regression prevents direct Supabase access from returning to the audited presentation paths and proves Profile completion/reminder composition from canonical Profile + `AuthSession` data.

## Guardrails

- #5 item 7 remains separate and pending its own bounded implementation.
- No client-authoritative contact verification was introduced.
- No schema ownership or DB migration change.
- PR #50 remains Draft/open/unmerged unless separately authorized.
