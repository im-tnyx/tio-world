# Profile & Account Data Persistence

**Status:** Ready — account/contact verification audit recorded; implementation sequenced after canonical P1 schema foundation  
**Primary owner:** `users` account root + `apps/features/profile` / `apps/features/settings` / auth adapter  
**Affected platforms:** Flutter phone app + Supabase  
**Tracking:** GitHub issue #8  
**Canonical sequencing task:** `account-profile-app-preferences-canonical-split.md`

## Outcome

Account data entered during signup/onboarding or edited later from Account Settings must persist truthfully without treating unverified contacts as verified.

Canonical account contact contract:

```text
public.users.email
public.users.email_verified_at      ← missing today, add in P1
public.users.mobile
public.users.mobile_verified_at     ← exists today
```

Common personal Profile fields move separately to `user_profiles`; contact identity and verification stay on the `users` account root.

## Verified current state

Live `tio-world` Supabase:

```text
public.users.email               nullable
public.users.mobile              nullable
public.users.mobile_verified_at  nullable timestamptz
public.users.email_verified_at   ABSENT

auth.users.email_confirmed_at    nullable timestamptz
auth.users.phone_confirmed_at    nullable timestamptz
```

No current trigger synchronizes Auth verification timestamps into `public.users`.

Current source findings:

- `SupabaseProfileAccountRepository.updateAccountSettings()` updates username/mobile and clears `mobile_verified_at` when the mobile changes.
- Account Settings router passes persisted mobile and phone-verification state.
- Account Settings reads email from `supabase.auth.currentUser.email`.
- Router does **not** pass an actual email verification state.
- `AccountSettingsPage` currently defaults `isEmailVerified = true`; this can display a false Verified state.
- the built-in email/phone verify fallback dialogs are presentation stubs unless a real callback is supplied; they are not durable auth verification.
- current Account Settings email is display-oriented; a phone-first account still needs a real add/change-email flow.

## Canonical verification rule

Supabase Auth is the current trusted verification evidence source:

```text
auth.users.email_confirmed_at
→ current auth email has been verified

auth.users.phone_confirmed_at
→ current auth phone has been verified
```

Tio-world application/domain state is provider-neutral:

```text
users.email_verified_at
users.mobile_verified_at
```

Rules:

- never accept a client boolean/timestamp as proof of verification;
- never set `*_verified_at` merely because a contact string exists;
- changing a contact invalidates its old verification until the new contact is confirmed;
- email and mobile verification are independent;
- future auth/backend adapters must reconcile their trusted provider claims into the same account-root fields.

## Phone-first account flow

```text
Phone signup / OTP verified
→ auth phone identity confirmed
→ users.mobile + mobile_verified_at reconciled
→ users.email may remain null

Later Account Settings
→ Add email
→ Supabase Auth sends email verification
→ user completes verification
→ trusted auth state confirms email
→ users.email + email_verified_at reconciled
```

## Email-first account flow

```text
Email signup / verification completed
→ auth email identity confirmed
→ users.email + email_verified_at reconciled
→ users.mobile may remain null

Later Account Settings
→ Add mobile
→ Supabase Auth phone OTP verification
→ trusted auth state confirms phone
→ users.mobile + mobile_verified_at reconciled
```

Verification of the newly added contact must not clear the already verified other contact.

## Execution slices

### P1 dependency — schema foundation

Owned by `account-profile-app-preferences-canonical-split.md`.

Before this task's runtime verification slice:

- [ ] add `public.users.email_verified_at timestamptz null` in a new forward migration;
- [ ] preserve existing `mobile_verified_at`;
- [ ] never edit applied migrations;
- [ ] verify RLS/grants/security before runtime cutover.

### P1A — Account contact verification

- [ ] remove `isEmailVerified = true` as a production assumption;
- [ ] add backend-neutral account contact/verification read state;
- [ ] Account Settings renders email verified/unverified/missing from actual state;
- [ ] Account Settings renders mobile verified/unverified/missing from actual state;
- [ ] phone-first account can add/change email;
- [ ] email-first account can add/change mobile;
- [ ] use real Supabase Auth update/verification flow, not local OTP success simulation;
- [ ] reconcile contact + verified timestamp only from trusted confirmed Auth identity;
- [ ] reject/avoid arbitrary client promotion to verified state;
- [ ] contact change invalidates previous verification until new confirmation;
- [ ] bootstrap/sign-in reconciliation repairs stale application verification state from trusted Auth state;
- [ ] add phone-first → email verified regression test;
- [ ] add email-first → phone verified regression test;
- [ ] failed/expired verification remains unverified;
- [ ] account save failure never shows false success;
- [ ] full relevant Flutter/Dart tests + analysis.

## Related canonical ownership

```text
users
→ account identity/status + contacts + verified timestamps

user_profiles
→ common personal Profile only

user_app_preferences
→ App Mode + active navigation preferences
```

Do not move email/mobile verification into `user_profiles`.

## Guardrails

- no anonymous-auth write fallback;
- no client-authoritative verified flag/timestamp;
- no false Verified badge;
- no applied migration edits;
- no unrelated Account Settings visual redesign in this persistence slice;
- no permanent duplicate contact authority between `auth.users` and `public.users`: Auth supplies current trusted verification evidence, while `public.users` is the provider-neutral application account projection;
- future backend must preserve the same provider-neutral application contract.

## Handoff

**Next schema step:** P1 adds `users.email_verified_at` together with `user_profiles` + `user_app_preferences`.  
**Then:** P1A implements real Account Settings email/mobile verification and trusted reconciliation.  
**Then:** P2 App Mode durability continues according to the master sequencing task.
