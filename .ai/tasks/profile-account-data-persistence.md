# Profile & Account Data Persistence

**Status:** P1 schema dependency validated live; P1A account contact verification is NEXT  
**Primary owner:** `users` account root + `apps/features/profile` / `apps/features/settings` / auth adapter  
**Affected platforms:** Flutter phone app + Supabase  
**Tracking:** GitHub issue #8  
**Canonical sequencing task:** `account-profile-app-preferences-canonical-split.md`

## Outcome

Account data entered during signup/onboarding or edited later from Account Settings must persist truthfully without treating unverified contacts as verified.

Canonical account contact contract is now live:

```text
public.users.email
public.users.email_verified_at      ✅
public.users.mobile
public.users.mobile_verified_at     ✅
```

Common personal Profile fields are separately owned by `user_profiles`; contact identity and verification stay on the `users` account root.

## P1 schema dependency — VALIDATED ✅

Live migrations:

```text
20260821180908_split_account_profile_app_preferences
20260821181005_harden_profile_app_preference_grants
```

P1 added:

- `users.email_verified_at timestamptz`;
- `user_profiles`;
- `user_app_preferences`;
- client-side verification timestamp protection;
- automatic verification invalidation when an authenticated client changes email/mobile;
- exact-match backfill from trusted Supabase Auth confirmation timestamps only;
- least-privilege grants on the two new tables after existing-project automatic grants were detected.

Live affected row counts were zero, so data backfill was a no-op in the current environment.

## Trusted verification rule

Supabase Auth is the current trusted evidence adapter:

```text
auth.users.email_confirmed_at
→ current auth email verified

auth.users.phone_confirmed_at
→ current auth phone verified
```

Tio-world application state remains provider-neutral:

```text
users.email_verified_at
users.mobile_verified_at
```

Normal client roles cannot directly promote the verification timestamps. Contact changes invalidate the corresponding timestamp. Trusted backend/service reconciliation is required after actual verification.

## Current source gaps — P1A

- `SupabaseProfileAccountRepository.updateAccountSettings()` currently updates username/mobile and clears mobile verification when mobile changes.
- Account Settings router passes persisted mobile + phone verification.
- Account Settings email currently comes from `supabase.auth.currentUser.email`.
- Router does not pass a real email-verification state.
- `AccountSettingsPage` defaults `isEmailVerified = true`, which can display a false Verified badge.
- built-in email/phone OTP fallback dialogs are presentation simulations unless real callbacks are wired.
- phone-first accounts still need a real add/change + verify email flow.
- email-first accounts need a real add/change + verify phone flow tied to Auth.

## P1A — Account contact verification — NEXT

Phone-first:

```text
phone signup / OTP verified
→ verified mobile
→ email may be null
→ Account Settings: Add email
→ real Supabase Auth email verification
→ trusted reconciliation
→ users.email + email_verified_at
```

Email-first:

```text
email signup / verification
→ verified email
→ mobile may be null
→ Account Settings: Add mobile
→ real Supabase Auth phone verification
→ trusted reconciliation
→ users.mobile + mobile_verified_at
```

P1A checklist:

- [ ] add backend-neutral account contact/verification state to account repository boundary;
- [ ] remove `isEmailVerified = true` production assumption;
- [ ] router passes actual email and mobile verified state;
- [ ] represent missing contact separately from unverified contact;
- [ ] phone-first user can add/change email;
- [ ] email-first user can add/change mobile;
- [ ] use real Supabase Auth contact update + verification flow;
- [ ] no local fake OTP success may mark a contact verified;
- [ ] reconcile application contacts/timestamps only from trusted confirmed Auth identity;
- [ ] changing one contact invalidates only that contact's verification;
- [ ] verifying one contact preserves the other verified contact;
- [ ] failed/expired verification remains unverified;
- [ ] bootstrap/sign-in reconciliation can repair stale application verification state;
- [ ] no false success Snackbar/pop on persistence failure;
- [ ] focused phone-first→email and email-first→phone regression tests;
- [ ] full relevant Flutter/Dart analysis/tests;
- [ ] record exact commit/CI and update #8/#44/master task before P2 starts.

## Related canonical ownership

```text
users
→ account identity/status + contacts + verified timestamps

user_profiles
→ common personal Profile only

user_app_preferences
→ App Mode + active navigation preferences
```

## Guardrails

- no anonymous-auth write fallback;
- no client-authoritative verified flag/timestamp;
- no false Verified badge;
- no applied migration edits;
- no unrelated Account Settings visual redesign;
- Auth is trusted verification evidence today, but `public.users` remains the provider-neutral application account projection;
- future backend/auth adapters must preserve the same `email_verified_at` / `mobile_verified_at` contract.

## Handoff

**Current validated slice:** P1 schema foundation.  
**Next implementation:** P1A account contact verification (#8).  
**After P1A validation:** P2 App Mode durability (#11).
