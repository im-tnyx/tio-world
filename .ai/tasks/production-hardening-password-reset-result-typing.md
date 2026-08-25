# Production Hardening — Password Reset Result Typing

## Status

**AUDIT COMPLETE / IMPLEMENTATION REQUIRED.**

Audit head lineage:

```text
cc163758f5a1c3917b7417392bfadb38b116d74d
```

Owner tracker: #5 P1 item 9. Coordinate with #34 without absorbing provider linking/password-policy/recovery-routing scopes.

## Goal

Remove the synthetic authenticated `SignInSuccess` used to represent a password-reset email request and replace it with a dedicated request-result contract that cannot be mistaken for an authenticated session.

## Fresh findings

### Current repository contract is semantically wrong

`AuthSignInRepository.sendPasswordResetEmail()` currently returns `Future<SignInResult>` and documents success as `SignInSuccess` with an empty session.

`SupabaseAuthSignInRepository.sendPasswordResetEmail()` currently calls `resetPasswordForEmail()` and fabricates:

```text
SignInSuccess(AuthSession(userId: ''))
```

No authenticated session is established by that operation.

### Current use case and UI inherit the wrong type

`SendPasswordResetEmailUseCase` returns `SignInResult`.

`ForgotPasswordPage` switches on `SignInSuccess`, `SignInCancelled`, and `SignInFailure` even though a reset-email request has no sign-in cancellation/success semantics.

### Current Supabase contract verified

Official current Supabase Auth documentation confirms:

- `resetPasswordForEmail()` sends/requests the recovery email flow; it does not itself establish authenticated sign-in success;
- the password is updated later after the recovery link returns to the app and the authenticated recovery context calls `updateUser(password: ...)`;
- to prevent user enumeration, a reset request may return without error even when no account exists for that email, so request success must not claim account existence or guaranteed delivery.

No current relevant Auth breaking change was found that changes these semantics.

## Implementation scope

- [ ] Add a dedicated password-reset request result hierarchy with request-accepted success and failure only.
- [ ] Change `AuthSignInRepository.sendPasswordResetEmail()` to return the dedicated result type.
- [ ] Change `SendPasswordResetEmailUseCase` to return the dedicated result type.
- [ ] Change `SupabaseAuthSignInRepository` success to the dedicated request-accepted result; never fabricate `AuthSession`.
- [ ] Preserve Supabase `AuthException` message/code in the dedicated failure result.
- [ ] Update `ForgotPasswordPage` to switch only on reset-request result types.
- [ ] Keep success copy privacy-safe: it may say a reset request was sent/accepted, but must not prove account existence.
- [ ] Update current test fakes implementing `AuthSignInRepository` to the new method signature without changing their unrelated sign-in behavior.
- [ ] Add focused repository/use-case/UI regressions proving no synthetic sign-in session is created or consumed.
- [ ] Full exact-head Flutter/Dart + Android CI before freeze.

## Out of scope

- Recovery deep-link routing / `PASSWORD_RECOVERY` event handling beyond current typing correction.
- Change-password screen implementation.
- Password strength/policy changes.
- Email provider/template/SMTP configuration.
- Account/provider linking or uniqueness changes (#34).
- Auth source-of-truth or 401 concurrency (items 7/8 frozen).
- DB/schema changes.

## Acceptance

- [ ] Password reset request cannot return `SignInSuccess` or an `AuthSession`.
- [ ] Successful Supabase reset request returns a dedicated request-accepted result.
- [ ] Failure returns a dedicated typed message/code result.
- [ ] Forgot Password success state depends only on reset-request success.
- [ ] No fake sign-in/session state is produced, stored, or consumed.
- [ ] User-enumeration-safe semantics are preserved.
- [ ] Existing login/signup behavior remains unchanged.
- [ ] No DB migration.
- [ ] Exact-SHA CI green.

## Guardrails

- Do not claim that request acceptance proves the email belongs to an account.
- Do not change Supabase Auth provider configuration in this slice.
- Do not broaden into recovery-link navigation or password-update UX.
- PR #50 remains Draft/open/unmerged unless separately authorized.
