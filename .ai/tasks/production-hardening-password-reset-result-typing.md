# Production Hardening — Password Reset Result Typing

## Status

**COMPLETE / FROZEN.**

Audit head lineage:

```text
cc163758f5a1c3917b7417392bfadb38b116d74d
```

Accepted source/test checkpoint:

```text
38949e8d25aeed6c5387f3b825deac224717f12d
Flutter CI #1914 / run 32819604848 ✅
Android Native CI #326 / run 32819604927 ✅
```

Owner tracker: #5 P1 item 9. #34 remains authoritative for recovery routing, password policy, provider linking, and broader account-auth behavior.

## Goal

Remove the synthetic authenticated `SignInSuccess` previously used to represent a password-reset email request and replace it with a dedicated request-result contract that cannot be mistaken for an authenticated session.

## Accepted result

- [x] Added dedicated `PasswordResetRequestResult` hierarchy with request-accepted success and typed failure only.
- [x] `AuthSignInRepository.sendPasswordResetEmail()` now returns the dedicated result type.
- [x] `SendPasswordResetEmailUseCase` now returns the dedicated result type.
- [x] `SupabaseAuthSignInRepository` keeps `resetPasswordForEmail()` as the provider operation and never fabricates `AuthSession`.
- [x] Supabase `AuthException` message/code are preserved in `PasswordResetRequestFailure`.
- [x] `ForgotPasswordPage` consumes only reset-request result types.
- [x] Missing reset dependency fails closed instead of simulating success.
- [x] Success copy remains user-enumeration safe and does not claim account existence or guaranteed delivery.
- [x] Current repository test fakes were aligned without changing unrelated Login/Signup semantics.
- [x] Focused adapter/use-case/UI regressions cover accepted request, provider failure, privacy-safe copy, and missing dependency.
- [x] No DB/schema or Supabase Auth configuration change.
- [x] Full exact-head Flutter/Dart + Android CI green.

## Focused regression

```text
apps/features/auth/test/password_reset_result_typing_test.dart
```

## Acceptance

- [x] Password reset request cannot return `SignInSuccess` or an `AuthSession`.
- [x] Successful Supabase reset request returns `PasswordResetRequestAccepted`.
- [x] Failure returns a dedicated typed message/code result.
- [x] Forgot Password success state depends only on reset-request acceptance.
- [x] No fake sign-in/session state is produced, stored, or consumed.
- [x] User-enumeration-safe semantics are preserved.
- [x] Existing Login/Signup behavior remains unchanged.
- [x] No DB migration.
- [x] Exact-SHA CI green.

## Out of scope

- Recovery deep-link routing / `PASSWORD_RECOVERY` event handling.
- Change-password screen implementation.
- Password strength/policy changes.
- Email provider/template/SMTP configuration.
- Account/provider linking or uniqueness changes (#34).
- Auth source-of-truth and 401 concurrency (items 7/8 frozen).

## Guardrails

- Request acceptance does not prove the email belongs to an account.
- Do not broaden this frozen slice into recovery-link navigation or password-update UX.
- PR #50 remains Draft/open/unmerged unless separately authorized.
