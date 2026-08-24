# Production Hardening — Router / Database Orchestration Boundary

## Status

ACTIVE implementation slice under #5.

Audit source head: `98a035ecf0891bc09812e61f0a22d721b0ebb0f7`

## Fresh audit findings

`apps/app/lib/app/router.dart` still performs infrastructure/business composition that should not live in route declaration glue:

1. Account deletion directly invokes `supabase.rpc('delete_user_account')`, swallows failures, then signs out/navigates. This is a direct database/RPC boundary violation and can create false-success semantics.
2. Measurement Units route directly constructs `SupabaseMeasurementUnitPreferencesRepository` in the router instead of consuming an app composition provider.
3. Product Onboarding finalization constructs `CompleteOnboardingUseCase`, `PersistOnboardingOwnerDataUseCase`, and their repository graph inside `onFinishRequested` instead of consuming an app-level use-case provider.

## In scope

- Add a narrow typed account-deletion repository/use case boundary in the Auth domain/data layer and compose it through Riverpod.
- Router must not call `supabase.rpc(...)` directly.
- Deletion backend failure must propagate; router must not swallow it or sign out/navigate as if deletion succeeded.
- Add a `MeasurementUnitPreferencesRepository` provider so the router does not construct a concrete Supabase repository.
- Add an app-level Product Onboarding completion use-case provider so the router does not construct the completion/persistence graph.
- Preserve current route paths, redirect behavior, page geometry, copy, and visual state.
- Add focused regression coverage for the new boundaries.

## Explicit non-goals

- Do not deploy/reconcile the historical `delete_user_account` database RPC in this slice. Live DB deletion contract/lifecycle remains #5 Account deletion lane.
- Do not redesign `TioDeleteAccountOverlay` or change its hold/close/back lifecycle here.
- Do not change Auth source-of-truth semantics or replace router reads of Supabase current user/email/phone in this slice; coordinate those with #8/#34 and P1 Auth source-of-truth alignment.
- Do not change Product Onboarding flow policy, canonical ownership, or persistence semantics.
- Do not change Measurement Units UI or schema.
- Do not change avatar picker/storage lifecycle.

## Acceptance

- `router.dart` contains no direct `rpc('delete_user_account')` call.
- Account deletion RPC is owned by a typed Supabase repository behind a domain use case/provider.
- Backend deletion errors are not swallowed before sign-out/navigation.
- `router.dart` no longer constructs `SupabaseMeasurementUnitPreferencesRepository`.
- `router.dart` no longer constructs `CompleteOnboardingUseCase` / `PersistOnboardingOwnerDataUseCase`.
- Existing Product Onboarding completion behavior remains unchanged.
- Focused tests cover account deletion success/failure forwarding and provider/use-case composition where practical.
- Exact-head Flutter/Dart + Android CI green before freezing.
