# Account Name + Contact Verification Ownership Hardening

## Status

AUDIT COMPLETE / IMPLEMENTATION REQUIRED.

Audit source head:

```text
6b10ea3a3f5ec739da4c5187de5ee312ecf4d31c
```

Live Supabase project:

```text
oykupyiitspujzpwwvuj
```

This task is intentionally split into two different ownership decisions:

1. remove the duplicate Account/bootstrap `users.name` column so user-entered Name has one canonical owner;
2. preserve trusted Email/Mobile verification evidence semantics while fixing the currently stale application projection.

Do not treat contact verification timestamps as the same kind of duplicate as Name.

---

## A. Name ownership audit — users.name retirement

### Current live state

```text
public.users rows                   4
public.users.name populated         4
public.user_profiles rows           0
public.user_profiles.name populated 0
```

All four current `users.name` values came from Google/Auth `full_name` bootstrap metadata.

Live `private.provision_tio_user_root()` currently creates the Account root with:

```text
full_name
→ display_name
→ metadata name
→ email local-part
→ "Tio User"
→ public.users.name
```

`public.users.name` is currently `NOT NULL` and has no default.

### Current canonical user-entered Name path

```text
Product Onboarding NameScreen
→ onboarding draft.profile.name
→ UserProfileMapper
→ UserProfileData.name
→ SupabaseUserProfileRepository.upsert()
→ public.user_profiles.name
```

Profile Settings edits follow the same canonical owner through `UserProfileRepository`; they do not write `users.name`.

Profile display/completion reads `user_profiles.name`. Account display reads from `users` only for Account-owned values such as username/avatar/plan/mobile; it intentionally does not use `users.name` as Profile truth.

No live view or index depends on `public.users.name`. The only confirmed live semantic dependency is the Auth-root provisioning function that must currently satisfy the column's `NOT NULL` constraint. Username RPCs use `users.username`, not the `name` column.

### Decision

Final user-entered Name must have one canonical owner:

```text
public.user_profiles.name
```

`public.users.name` is now compatibility/bootstrap debt and should be retired after the final current-head dependency check.

### Implementation scope

- [ ] Re-audit current-head code/Edge Functions/SQL for any remaining legitimate `users.name` consumer immediately before DDL.
- [ ] Add a forward-only migration that removes the `users.name` requirement and then drops `public.users.name` without `CASCADE`.
- [ ] Update `private.provision_tio_user_root()` so new Auth users create a minimal Account root without any bootstrap Name.
- [ ] Remove obsolete bootstrap-name metadata/fallback logic and its tests.
- [ ] Keep Product Onboarding NameScreen unchanged except for tests proving its only durable Name owner is `user_profiles.name`.
- [ ] Keep Profile Settings Name editable and persisted only through `user_profiles.name`.
- [ ] Do not copy provider/Google display name into `user_profiles.name` automatically.
- [ ] Do not dual-write or add a synchronization trigger between two Name columns.
- [ ] Verify fresh Google and Email account provisioning still creates exactly one `public.users` root.
- [ ] Verify onboarding/editing Name cannot mutate Account contact/root state.

---

## B. Email/Mobile verification audit — trusted Auth evidence + application projection

### Intended ownership

Trusted verification evidence:

```text
auth.users.email_confirmed_at
→ authoritative evidence for the current Auth email

auth.users.phone_confirmed_at
→ authoritative evidence for the current Auth phone
```

Provider-neutral Account projection:

```text
public.users.email
public.users.email_verified_at
public.users.mobile
public.users.mobile_verified_at
```

`user_profiles` must not own Email/Mobile verification.

The public timestamps are not independent proof. They may only reflect trusted Auth/backend evidence for the exact same normalized contact.

### Live audit result

```text
auth.users                          4
auth users with email               4
auth email_confirmed_at populated   4
public.users with email             4
public email_verified_at populated  0
confirmed email missing projection  4

Auth phone populated                0
Auth phone_confirmed_at populated   0
public mobile populated             0
public mobile_verified_at populated 0
```

All four current Auth identities are Google identities.

Therefore the live Email verification projection is stale for every current account even though Supabase Auth already has trusted confirmation evidence.

### Live database guard

`public.protect_user_contact_verification()` correctly prevents normal `authenticated` / `anon` writes from promoting verification timestamps:

- client INSERT forces both verification timestamps to NULL;
- changing Email clears `email_verified_at`;
- changing Mobile clears `mobile_verified_at`;
- direct client attempts to set either timestamp without changing the contact preserve the old trusted value.

This guard is correct and should remain conceptually intact.

### Confirmed missing reconciliation

No live function currently reconciles `auth.users.email_confirmed_at` / `phone_confirmed_at` into `public.users.email_verified_at` / `mobile_verified_at`.

The only custom `auth.users` trigger is currently the `AFTER INSERT` Account-root provisioning trigger. There is no verification reconciliation trigger on Auth updates.

### Current app gaps

- `AuthSession` currently carries email/phone but no verification state.
- `SupabaseAuthSessionRepository` does not map authoritative verification state.
- Account Settings gets Email directly from `supabase.auth.currentUser.email` but does not pass real Email verification state.
- `AccountSettingsPage` defaults `isEmailVerified = true`, which can show unknown/unverified Email as Verified.
- Phone verified state is currently read from the stale/provider-neutral public projection.
- Built-in Settings OTP dialogs can show local success without durable Supabase Auth verification when no real callback is wired.
- `SupabaseProfileAccountRepository.updateAccountSettings()` may update `public.users.mobile` and clear its verification, but it does not by itself perform the required Supabase Auth phone update/OTP verification flow.
- Email signup currently returns `SignInSuccess` from a returned user even when the required authenticated session may be absent pending Email confirmation; session-present vs session-absent must be typed distinctly.

### Decision

Do **not** remove `email_verified_at` / `mobile_verified_at` merely because Supabase Auth also has confirmation timestamps.

They serve a different boundary: application Account projection for the exact stored contact, while Supabase Auth remains the trusted evidence source. The fix is to make projection reconciliation deterministic and trusted.

Preferred invariant:

```text
public.users.email_verified_at IS NOT NULL
iff
public.users.email matches current auth.users.email
AND auth.users.email_confirmed_at IS NOT NULL

public.users.mobile_verified_at IS NOT NULL
iff
public.users.mobile matches current auth.users.phone after canonical normalization
AND auth.users.phone_confirmed_at IS NOT NULL
```

No client boolean or timestamp may establish verification.

### Implementation scope

- [ ] Add one trusted reconciliation owner for Auth contact confirmation → `public.users` projection; prefer database-owned reconciliation in the same Auth/Postgres boundary if it can be made fail-safe and fully tested.
- [ ] Reconcile on relevant Auth user changes, not only fresh signup.
- [ ] Backfill current exact-match trusted Email confirmations; current audit expects 4 Email projections to become verified.
- [ ] Never verify a public contact when it does not exactly match the trusted Auth contact after normalization.
- [ ] A changed Email clears only Email verification; a changed Mobile clears only Mobile verification.
- [ ] Verifying one contact must preserve the other contact's trusted verified state.
- [ ] Replace Account Settings `isEmailVerified = true` default with explicit authoritative state.
- [ ] Extend the Auth/account domain model so missing contact, unverified contact, and verified contact are distinct states.
- [ ] Wire real Supabase Auth Email add/change + verification and Phone add/change + OTP verification; remove fake local verification-success semantics.
- [ ] Email signup must distinguish `user created + authenticated session` from `user created + confirmation pending/no session`.
- [ ] Google Email is considered verified only from trusted Supabase/provider evidence; never from `user_metadata` alone.
- [ ] Add phone-first → add/verify Email and email-first → add/verify Phone regression coverage.
- [ ] Add stale-projection repair tests for login/bootstrap/auth-state changes.
- [ ] Keep Email/Mobile verification under Account/Auth ownership; never move it to `user_profiles`.

---

## Coordination

Authoritative trackers:

```text
#5  production hardening umbrella
#8  Account Email/Mobile persistence + verification UX/projection
#34 Auth identity/session/password/linking correctness
#44 canonical owner map
```

`#34` contains older text stating `public.users.email_verified_at` is absent; live schema and #8 supersede that statement. Do not create the column again.

## Acceptance

### Name

- [ ] exactly one durable editable Profile Name field remains: `user_profiles.name`;
- [ ] `users.name` is removed safely with no `CASCADE`;
- [ ] fresh Auth provisioning does not fabricate a Profile Name;
- [ ] onboarding and Profile Settings Name edits persist only to `user_profiles.name`.

### Verification

- [ ] Auth confirmation is the only trusted verification evidence;
- [ ] public verification timestamps are deterministic exact-contact projections, never client truth;
- [ ] current live exact-match Email confirmation projection is repaired;
- [ ] Account Settings cannot display false Verified state;
- [ ] Email signup pending-confirmation state is not reported as authenticated success;
- [ ] real Email/Mobile verification flows are used;
- [ ] contact changes invalidate only their own verification state;
- [ ] exact-head Flutter/Dart + Android CI and focused DB regressions are green before freezing.

## Guardrails

- No applied migration edits.
- No `CASCADE`.
- No dual Name write.
- No Profile Name bootstrap from Auth/provider metadata.
- No client-authoritative verification timestamps.
- No verification inference from mere Email/Mobile presence.
- No broad auth-provider switch.
- PR #50 remains Draft/open/unmerged unless separately authorized.
