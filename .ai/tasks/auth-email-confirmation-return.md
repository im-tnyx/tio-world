# Auth Email Confirmation Return

Issue: #137
Parent: #118
Hosted smoke: #125
Stack base: Draft PR #134 / `agent/auth-phone-first-test-alignment`
Branch: `agent/auth-email-confirmation-return`

## Problem

Initial Email + Password Signup creates the correct pending Supabase Auth user and sends the confirmation mail, but does not pass the mobile callback redirect. Successful confirmation therefore falls back to the project Site URL and can show a localhost browser failure even though the backend account is confirmed. The Signup page also renders `email_confirmation_required` through destructive error styling.

## Target behavior

```text
Email Signup accepted
→ dedicated pending verification state
→ confirmation link uses tio://login-callback
→ Tio receives/restores the authenticated confirmed session
→ Email verified / Setting up your account progress state
→ canonical app session bootstrap continues
```

Manual app resume after confirmation must also re-check the authoritative Auth session so the page cannot stay stuck on the pending state after the callback has already established a verified session.

## Invariants

- Supabase Auth remains verification/session authority.
- Same canonical UUID before/after confirmation.
- No implicit provider merge.
- No canonical Email admission weakening.
- Pending confirmation remains enumeration-safe.
- No production Supabase schema/data mutation in this source slice.
- Site URL is not changed by this fix.
- Existing allowed `tio://login-callback` contract is reused.

## Implementation plan

- [ ] Initial Email Signup passes `emailRedirectTo: tio://login-callback`.
- [ ] `email_confirmation_required` becomes an expected pending verification state, not an error banner.
- [ ] Pending verification UI is dedicated, accessible, and keeps actual failures separate.
- [ ] Auth session stream/resume snapshot can detect confirmed matching Email.
- [ ] Confirmed state shows success/progress before handing control to app session bootstrap.
- [ ] Repeated auth events/resume checks are idempotent.
- [ ] Focused repository/widget tests cover redirect and state transition.
- [ ] Affected analyze/tests pass.
- [ ] Hosted #125 follow-up proves callback no longer falls back to localhost.

## Runtime evidence before source change

Sanitized hosted checkpoint after the owner-confirmed Email confirmation:

```text
auth users = 1
auth identities = 1
public roots = 1
confirmed auth users = 1
verified email projections = 1
canonical verified-email collision groups = 0
```

The backend confirmation succeeded; the demonstrated defect is post-confirm redirect/presentation handling.

## PR state rule

Implementation PR must remain Draft/open/unmerged. Do not mark Ready or merge without explicit owner authorization.