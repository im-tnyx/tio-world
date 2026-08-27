# Auth Email Confirmation Return

Issue: #137
Parent: #118
Hosted smoke: #125
Implementation PR: #138
Stack base: Draft PR #134 / `agent/auth-phone-first-test-alignment`
Branch: `agent/auth-email-confirmation-return`

## Status

**SOURCE + REPOSITORY CI PASS / HOSTED CALLBACK RETEST PENDING**

Validated source commit:

`921adc25370e2338da944cda22b178a900cd82c0`

## Problem

Initial Email + Password Signup created the correct pending Supabase Auth user and sent the confirmation mail, but did not pass the mobile callback redirect. Successful confirmation therefore fell back to the project Site URL and showed a localhost browser failure even though the backend account was confirmed. The Signup page also rendered `email_confirmation_required` through destructive error styling.

## Implemented behavior

```text
Email Signup accepted
→ dedicated Tio "Please verify your email" state
→ confirmation link uses tio://login-callback
→ Supabase establishes the confirmed session on callback
→ existing app-session bootstrap becomes the single progress/navigation owner
→ Account Setup / Username when required
```

The verification state does not display the submitted identifier and preserves enumeration-safe duplicate behavior. `Resend email` uses the real Supabase signup-resend path with the same app callback. Actual failures remain separate from the expected pending state.

## Architecture decision

Do not add duplicate direct Username navigation inside `EmailSignupPage`.

`AppSessionBootstrapController` already listens to authoritative Auth session transitions. Once the confirmation callback establishes an authenticated Supabase session, the existing bootstrap resolves account state and `app_session_route_policy.dart` routes incomplete accounts to Account Setup. This keeps post-auth progress/navigation under the existing canonical owner.

A hosted device retest must still prove that the callback is received correctly and that the user reaches the expected Account Setup / Username step.

## Invariants

- Supabase Auth remains verification/session authority.
- Same canonical UUID before/after confirmation.
- No implicit provider merge.
- No canonical Email admission weakening.
- Pending confirmation remains enumeration-safe.
- No production Supabase schema/data mutation in this source slice.
- Site URL is not changed by this fix.
- Existing allowed `tio://login-callback` contract is reused.

## Implementation checklist

- [x] Initial Email Signup passes `emailRedirectTo: tio://login-callback`.
- [x] `email_confirmation_required` becomes an expected pending verification state, not an error banner.
- [x] Pending verification UI is dedicated and accessible while actual failures remain separate.
- [x] Pending view does not expose the submitted Email identifier.
- [x] `Resend email` delegates to Supabase `auth.resend(type: signup)` with the mobile callback.
- [x] Existing Auth session stream/bootstrap remains the single confirmed-session navigation owner.
- [x] Repeated post-auth routing remains under the existing idempotent bootstrap policy rather than page-local navigation.
- [x] Focused repository/widget tests cover redirect, resend, pending presentation, and actual-error separation.
- [x] Repository-wide Flutter analyze passes.
- [x] Repository-wide Dart analyze passes.
- [x] Repository-wide serialized Flutter tests pass.
- [x] Repository-wide Dart tests pass.
- [x] Phone Android debug APK builds.
- [x] Wear Android debug APK builds.
- [ ] Hosted #125 follow-up proves callback no longer falls back to localhost and reaches Account Setup / Username.

## Executable validation

Validation-only Draft PR #139 targeted `main` so the stacked source could exercise repository workflows.

Final exact source under validation:

`921adc25370e2338da944cda22b178a900cd82c0`

Green runs:

- Flutter CI #2090, run `33055694097`
  - Flutter analyze PASS
  - Dart analyze PASS
  - serialized Flutter tests PASS
  - Dart tests PASS
- Android Native CI #502, run `33055694770`
  - Phone Android debug APK PASS
  - Wear Android debug APK PASS

The first validation run on the preceding source checkpoint exposed only a local Dart type-promotion error plus one const lint; both were corrected before the final green source above. No production runtime behavior was widened to fix those validation findings.

## Runtime evidence before source change

Sanitized hosted checkpoint after the earlier owner-confirmed Email confirmation:

```text
auth users = 1
auth identities = 1
public roots = 1
confirmed auth users = 1
verified email projections = 1
canonical verified-email collision groups = 0
```

The backend confirmation succeeded; the demonstrated defect was post-confirm redirect/presentation handling.

## PR state rule

PR #138 remains Draft/open/unmerged. Do not mark Ready or merge without explicit owner authorization. Validation-only PR #139 should close without merge after evidence sync.
