# Production Hardening — Router / Database Orchestration Boundary

## Status

COMPLETE / FROZEN under #5.

Audit source head: `98a035ecf0891bc09812e61f0a22d721b0ebb0f7`

Accepted implementation checkpoint:

```text
e690f90ecfb8a7c598d095744a3e9d700a30e775
Flutter CI #1852 / run 32763682355 ✅
Android Native CI #264 / run 32763682383 ✅
```

## Fresh audit findings

`apps/app/lib/app/router.dart` still performed infrastructure/business composition that should not live in route declaration glue:

1. Account deletion directly invoked `supabase.rpc('delete_user_account')`, swallowed failures, then signed out/navigated. This was a direct database/RPC boundary violation and could create false-success semantics.
2. Measurement Units route directly constructed `SupabaseMeasurementUnitPreferencesRepository` in the router instead of consuming an app composition provider.
3. Product Onboarding finalization constructed `CompleteOnboardingUseCase`, `PersistOnboardingOwnerDataUseCase`, and their repository graph inside `onFinishRequested` instead of consuming an app-level use-case provider.

## Accepted implementation

- Added `AccountDeletionRepository` and `DeleteCurrentAccountUseCase` in the Auth domain.
- Added `SupabaseAccountDeletionRepository` as the infrastructure owner of `delete_user_account` RPC invocation.
- Added app-level Riverpod providers for account deletion and Measurement Unit persistence composition.
- Router no longer calls `supabase.rpc('delete_user_account')` directly.
- Router no longer swallows permanent-deletion backend failure before sign-out/navigation.
- Router no longer constructs `SupabaseMeasurementUnitPreferencesRepository`.
- Added an app-level Product Onboarding completion use-case factory so the router no longer constructs `CompleteOnboardingUseCase` / `PersistOnboardingOwnerDataUseCase` and the owner-repository graph.
- Completion factory is evaluated at finalization time so post-signup Supabase auth readiness retains the previous behavior.
- Product Onboarding flow/persistence semantics, routes, page geometry, copy, and visual state were unchanged.
- Focused account-deletion use-case tests prove delegation and failure forwarding.
- Flutter analyze, Dart analyze, Flutter tests, Dart tests, and Android debug/native compile are green on the exact accepted SHA.

## Explicit retained boundaries / non-goals

- Live `public.delete_user_account()` was rechecked during this slice and remains absent. No delete-account DDL/RPC was deployed here. Database contract reconciliation and destructive lifecycle acceptance remain the dedicated #5 Account deletion lane.
- `TioDeleteAccountOverlay` hold/close/back lifecycle was not redesigned in this slice.
- Router reads of Supabase current user/email/phone remain intentionally deferred to Auth source-of-truth alignment and #8/#34.
- Product Onboarding flow policy, canonical ownership, Measurement Units UI/schema, and avatar storage lifecycle were not changed.

## Acceptance

- [x] `router.dart` contains no direct `rpc('delete_user_account')` call.
- [x] Account deletion RPC is owned by a typed Supabase repository behind a domain use case/provider.
- [x] Backend deletion errors are not swallowed before sign-out/navigation.
- [x] `router.dart` no longer constructs `SupabaseMeasurementUnitPreferencesRepository`.
- [x] `router.dart` no longer constructs `CompleteOnboardingUseCase` / `PersistOnboardingOwnerDataUseCase`.
- [x] Existing Product Onboarding completion behavior remains unchanged.
- [x] Focused account deletion success/failure forwarding regression coverage added.
- [x] Exact-head Flutter/Dart + Android CI green.
