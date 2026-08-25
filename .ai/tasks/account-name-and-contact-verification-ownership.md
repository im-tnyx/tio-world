# Account Name + Contact Verification Ownership Hardening

## Status

**IMPLEMENTATION COMPLETE / FROZEN — CODE + DATABASE.**

Accepted implementation/test checkpoint:

```text
1cde11557666a8e4d05673aeb301f7d4d127e8d2
Flutter CI #1879 / run 32809594177 ✅
Android Native CI #291 / run 32809594166 ✅
```

Live Supabase project:

```text
oykupyiitspujzpwwvuj
```

Forward-only live migrations:

```text
20260824192004 retire_account_bootstrap_name
20260824192328 reconcile_auth_contact_verification
```

No applied migration was edited. No `CASCADE` was used.

---

## A. Name ownership — COMPLETE / FROZEN

Final editable Name owner:

```text
public.user_profiles.name
```

`public.users.name` has been retired.

Accepted result:

- [x] Fresh dependency preflight found no legitimate catalog dependency on `public.users.name`; provisioning was the live semantic dependency and was updated first.
- [x] Forward-only migration removed bootstrap-Name derivation from `private.provision_tio_user_root()` and safely dropped `public.users.name` without `CASCADE`.
- [x] Google post-auth enrichment no longer writes provider display Name into `public.users`.
- [x] Fresh Auth root provisioning still creates exactly one minimal `public.users` root per `auth.users.id`.
- [x] Product Onboarding Name persists through `UserProfileRepository` to `user_profiles.name` only.
- [x] Profile Settings Name persists through the same canonical `user_profiles.name` owner.
- [x] No Name dual-write or synchronization trigger exists.
- [x] Provider/Auth display metadata is not copied into `user_profiles.name` automatically.

Final live Name invariant:

```text
public.users.name columns          0
public.user_profiles.name columns  1
```

Historical #44/O11 text saying `users.name` was retained describes the earlier accepted state and is superseded by this post-O11 hardening decision.

---

## B. Email/Mobile verification — COMPLETE / FROZEN (CODE + DB)

### Authority

Supabase Auth is the only trusted verification-evidence authority:

```text
auth.users.email_confirmed_at
auth.users.phone_confirmed_at
```

Tio keeps provider-neutral Account projections:

```text
public.users.email
public.users.email_verified_at
public.users.mobile
public.users.mobile_verified_at
```

The public timestamps are projections only; the client cannot establish verification truth.

### Database reconciliation

`private.reconcile_tio_user_contact_verification()` is the trusted reconciliation owner and runs after relevant `auth.users` INSERT/UPDATE contact-confirmation changes.

Accepted rules:

- [x] Exact normalized Auth Email + non-null `email_confirmed_at` is required for Email verification projection.
- [x] Exact normalized Auth Phone + non-null `phone_confirmed_at` is required for Mobile verification projection.
- [x] Relevant Auth changes reconcile deterministically into `public.users`.
- [x] Historical exact-match trusted Email confirmations were backfilled.
- [x] Client roles cannot promote `email_verified_at` / `mobile_verified_at`; the existing public guard remains in force.
- [x] Contact-change state-transition regressions prove one contact can change/verify without fabricating verification for the other.
- [x] New private reconciliation/provisioning functions introduced no Supabase security-advisor warning.

Final live verification invariant at freeze:

```text
auth_users                         4
public_users                       4
auth_with_email                    4
auth_email_confirmed               4
public_with_email                  4
public_email_verified              4
confirmed_email_missing_projection 0

auth_with_phone                    0
auth_phone_confirmed               0
public_with_mobile                 0
public_mobile_verified             0
confirmed_phone_missing_projection 0
```

All current live identities are development/testing identities; no existing testing identity was deleted or rewritten merely to make the migration pass.

### App/Auth behavior

- [x] `AuthSession` carries authoritative Email/Phone verification state.
- [x] Account Settings no longer defaults Email to Verified.
- [x] Missing/unverified/verified contact state is explicit rather than inferred from contact presence.
- [x] Fake local OTP-success semantics are removed; missing provider callbacks cannot show durable verification success.
- [x] Email add/change goes through Supabase Auth `updateUser(...)` / verification behavior.
- [x] Existing unconfirmed Email can request Supabase signup verification again.
- [x] Phone add/change goes through Supabase Auth `updateUser(...)` followed by `OtpType.phoneChange` verification.
- [x] Secure Email Change intermediate success is fail-closed: the app requires the exact target Email to be confirmed by Supabase Auth before reporting Verified.
- [x] Phone verification similarly requires the exact target Phone to be confirmed by Supabase Auth before reporting Verified.
- [x] Email Signup distinguishes `user created + session present` from `user created + confirmation pending/session absent`; pending confirmation is not authenticated success.
- [x] Google Email verification is derived from trusted Supabase Auth confirmation evidence, never provider display metadata alone.
- [x] Focused Auth-adapter tests prove `OtpType.emailChange` / `OtpType.phoneChange`, resend behavior, normalization, and fail-closed unconfirmed responses.
- [x] Settings regressions prove changed Email/Phone cannot be smuggled through ordinary Save without verification.
- [x] Exact-head Flutter/Dart + Android CI is green.

### External provider-delivery acceptance

Hosted inbox/SMS delivery itself is **not fabricated as tested** by this task. The connected Supabase tooling exposes database/docs/logs but not a disposable signed-in end-user session plus inbox/SMS receiver or all hosted Auth provider settings.

Therefore real-environment acceptance still requires a disposable account/device check of:

```text
Email signup → receive confirmation → confirm → signed-in/verified
Email change → Supabase confirmation flow (including both inboxes when Secure Email Change is enabled)
Phone add/change → receive SMS OTP → verify → confirmed/verified
```

This is an external delivery/configuration acceptance, not an open code/database ownership defect. The app is fail-closed if delivery/confirmation does not complete.

Current Supabase documentation confirms that authenticated Email changes are handled by `updateUser(...)`; Secure Email Change may require confirmation from both old and new Email, while Phone change uses `updateUser(phone)` followed by `phone_change` OTP verification.

---

## Coordination / remaining work

Authoritative trackers:

```text
#5  production hardening umbrella
#8  Account Email/Mobile persistence + verification UX/projection
#34 Auth identity/session/password/linking correctness
#44 canonical owner map
```

This task resolves Name ownership and the trusted contact-verification projection/Settings boundary. It does **not** close the broader #34 work for identifier uniqueness, password policy/recovery/change-password, linked identities, or the broader #5 Auth source-of-truth lane.

`#34` contains historical text saying `public.users.email_verified_at` did not exist. That text is stale and superseded; do not add the column again.

Next production-hardening slice after this freeze:

```text
#5 P1 item 6 — Presentation-layer direct Supabase access (fresh current-head audit)
```

Then continue with the broader #5 item 7 Auth source-of-truth alignment.

## Guardrails frozen

- No applied migration edits.
- No `CASCADE`.
- No dual Name write.
- No Profile Name bootstrap from Auth/provider metadata.
- No client-authoritative verification timestamps.
- No verification inference from Email/Mobile presence.
- No broad auth-provider switch in this task.
- PR #50 remains Draft/open/unmerged unless separately authorized.
