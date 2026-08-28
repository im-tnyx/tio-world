# Auth Identifier Uniqueness Foundation

**Status:** Ready
**Primary owner:** `apps/features/auth`, `apps/features/profile`, `supabase/*`; `apps/app` only for composition/error wiring when required
**Affected platforms:** Flutter phone app + Supabase
**Related issue:** #34
**Blocks:** #118 Mobile-first Auth mode switch + complementary contact setup

## 1. Discovery

### User Outcome

Tio must maintain exactly one canonical account per verified Email identity and per verified Mobile identity while still allowing a user to add a secondary Email/Mobile before it is verified.

Canonical account invariant:

```text
one canonical Tio account
→ one auth.users.id
→ one public.users.id
→ multiple verified sign-in methods may be linked later
```

Verified identifier invariants:

```text
one verified canonical Email identity
→ at most one canonical Tio account

one verified canonical Mobile identity
→ at most one canonical Tio account
```

Secondary contact state:

```text
absent
→ pending/unverified
→ verified/owned
```

An unverified secondary contact may be stored, but it is not ownership proof, does not create login/recovery capability, and must not permanently reserve the identifier against the real owner.

### Product Rules Frozen

- Email or Mobile may create a new account only when the corresponding canonical identifier is not already verified/owned by another canonical Tio account.
- Google signup/sign-in provides a trusted verified Email identity through Supabase Auth/provider confirmation evidence.
- A Google/Email-authenticated user may enter an optional Mobile without OTP; it may be stored as pending/unverified.
- A Phone-authenticated user may enter an optional Email before confirmation; it may be stored as pending/unverified.
- `email_verified_at` / `mobile_verified_at` remain null until trusted Supabase Auth confirmation evidence exists.
- Unverified contact presence must never be interpreted as verification, login capability, recovery capability, linking authority, or account-merge authority.
- If a pending Email/Mobile is already verified/owned by another account, the current account must not verify/bind it.
- Verification/binding must perform a final authoritative uniqueness check. Concurrent pending claims must resolve safely: at most one canonical account becomes the verified owner; the other receives a controlled conflict.
- Never silently merge two accounts because Email/Mobile strings match.
- All later sign-in methods added to an account must preserve the same `auth.users.id` / `public.users.id`.

### Email Canonicalization Policy

Tio uses a provider-aware Email identity key.

For Gmail consumer identities:

```text
trim
lowercase
normalize googlemail.com → gmail.com
strip +tag from the local part
remove dots from the Gmail local part
```

Examples:

```text
name@gmail.com
na.me@gmail.com
name+fit@gmail.com
n.a.m.e+anything@googlemail.com
→ same canonical Email identity key
```

For other providers/domains:

```text
trim
lowercase/domain normalization
no universal +tag stripping
no provider-specific alias rewrite unless explicitly supported by policy
```

The original verified Email value remains usable for communication/display. The canonical identity key exists only for account resolution/uniqueness.

### Success Criteria

- Verified canonical Email identities are unique across canonical Tio accounts.
- Verified canonical Mobile identities are unique across canonical Tio accounts.
- Pending/unverified secondary contact can be stored without becoming ownership truth.
- Pending/unverified contact does not permanently reserve an identifier from a later verified real owner.
- Final verification/bind is race-safe and conflict-safe.
- Gmail/Googlemail alias equivalence follows the frozen provider-aware rule.
- Google existing-account admission uses the same canonical Email identity rule.
- Auth provisioning/reconciliation and application conflict handling use one coherent identifier contract.
- Username conflict handling remains distinct from Email/Mobile uniqueness conflicts.
- No UUID/account switching or silent account merging occurs.

### Scope

- server-owned canonical Email identity function/contract;
- server-owned `email_identity_key` or equivalent canonical uniqueness representation;
- verified Email ownership uniqueness backstop;
- canonical E.164 Mobile ownership uniqueness backstop;
- explicit pending/unverified vs verified/owned semantics;
- authoritative final-bind conflict handling;
- Auth root provisioning alignment;
- Auth contact-verification reconciliation alignment;
- `google-login-admission` canonical Email lookup;
- typed application conflicts for Username vs Email vs Mobile;
- migration preflight and focused tests.

### Non-Goals

- Phone OTP Signup/Login UI;
- #118 round provider buttons / Phone-first UI;
- Google identity linking implementation;
- password policy;
- Reset Password completion/deep-link flow;
- authenticated Change Password;
- Truecaller/WhatsApp auth;
- automatic account merging;
- treating unverified contact as login/recovery authority.

## 2. Codebase Exploration

### Verified Evidence

Current accepted contact-verification owner is already complete/frozen in `.ai/tasks/account-name-and-contact-verification-ownership.md`:

```text
accepted SHA 1cde11557666a8e4d05673aeb301f7d4d127e8d2
Supabase Auth = verification authority
public.users.email_verified_at / mobile_verified_at = projections only
```

Current runtime Auth repository:

- Google sign-in uses Supabase Auth ID-token/OAuth exchange.
- Email + Password sign-in/signup exists.
- Email Signup correctly distinguishes `session == null` confirmation-pending from authenticated success.
- Password reset request has its own result type.
- Phone Signup/Login OTP request/resend/verify contract does not yet exist.

Current live Supabase audit on project `oykupyiitspujzpwwvuj`:

```text
public.users.email                 exists
public.users.email_verified_at     exists
public.users.mobile                exists
public.users.mobile_verified_at    exists
public.users.email_identity_key    absent

idx_users_email_lower              NON-UNIQUE
idx_users_mobile                   NON-UNIQUE

normalized Email duplicate groups 0
Mobile duplicate groups           0
Gmail alias collision groups      0
```

Current DB provisioning:

```text
private.provision_tio_user_root()
→ lower(btrim(new.email))
→ no provider-aware Email identity key
```

Current Auth→Account reconciliation:

```text
private.reconcile_tio_user_contact_verification()
→ lower(btrim(new.email))
→ normalized phone string
→ trusted confirmation timestamps projected
→ no provider-aware Email identity key
```

Current live `google-login-admission`:

```text
verified Google Email
→ lower(trim(email))
→ exact public.users.email lookup
```

It does not yet use the frozen provider-aware canonical Email identity rule.

Current `public.users` RLS allows authenticated own-row UPDATE. Existing `protect_user_contact_verification()` correctly prevents client promotion of verification timestamps and clears the corresponding verification timestamp when a contact changes, but it does not provide canonical identifier ownership semantics by itself.

Current `SupabaseProfileAccountRepository.updateAccountSettings()` maps any Postgres `23505` uniqueness error to `UsernameUnavailableException`, which will become incorrect once Email/Mobile uniqueness constraints exist.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| One canonical account per verified canonical Email | Approved | Prevent duplicate accounts while supporting multiple login methods | Product/Auth |
| One canonical account per verified canonical Mobile | Approved | Same account invariant for Phone identity | Product/Auth |
| Pending/unverified secondary contact may be stored | Approved | User may add optional contact before verification | Product |
| Pending contact is not ownership proof | Frozen | Prevent impersonation and false verification | Auth architecture |
| Pending contact must not permanently reserve identifier | Frozen | Prevent denial-of-service by typing another person's Email/Mobile | Auth architecture |
| Final verification/bind rechecks uniqueness | Frozen | Required for races/concurrent pending claims | Auth architecture |
| No silent merge on identifier collision | Frozen | Ownership must be explicitly verified/recovered/linked | Auth architecture |
| Gmail aliases use provider-aware canonicalization | Approved | Frozen #34 product decision | Product/Auth |
| Other domains do not universally strip `+tag` | Approved | Provider semantics vary | Product/Auth |
| Canonical identity key is server-owned | Frozen | Client must not forge account-resolution identity | Data/Auth |
| Verification timestamps remain server/Auth-owned | Frozen | Existing accepted verification contract | Data/Auth |
| Phone OTP + #118 UI happen after this foundation | Approved sequencing | Prevent new entry paths before account uniqueness is safe | Architecture |

## 4. Architecture Design

### Chosen Approach

Separate **contact value**, **verification state**, and **canonical ownership key**.

Conceptually:

```text
public.users.email
→ current/pending/display contact value

public.users.email_verified_at
→ trusted verification projection

server canonical Email identity key
→ provider-aware normalized account-resolution key
→ ownership uniqueness applies only when Email is trusted/verified
```

Equivalent rule for Mobile:

```text
public.users.mobile
→ current/pending E.164 contact value

public.users.mobile_verified_at
→ trusted verification projection

canonical Mobile ownership
→ unique when trusted/verified
```

Exact schema shape (`email_identity_key` column plus verified-only unique index, generated/trigger-maintained representation, or another server-owned equivalent) must preserve these invariants:

1. client cannot authoritatively choose the canonical ownership key;
2. unverified contact does not permanently reserve ownership;
3. verified ownership is unique;
4. final verification is atomic/race-safe;
5. provisioning/reconciliation/Google admission all use the same canonicalization function.

### Ownership and Data Flow

```text
User types secondary contact
→ application validates/normalizes presentation value
→ Supabase Auth contact add/change flow where verification is requested
→ pending/unverified contact may be stored
→ Supabase Auth confirmation evidence arrives
→ trusted DB reconciliation
→ canonical key computed server-side
→ final uniqueness bind
→ verified projection updated
```

Primary Email/Google account creation:

```text
verified Email evidence
→ canonical Email key
→ uniqueness check/backstop
→ one auth.users.id
→ one public.users.id
```

Primary Phone OTP account creation, future slice:

```text
verified Phone OTP
→ canonical E.164 Mobile
→ uniqueness check/backstop
→ one auth.users.id
→ one public.users.id
```

### Conflict Semantics

Do not collapse all database uniqueness errors into Username conflicts.

Expected typed outcomes:

```text
Username already used
Email already owned by another account
Mobile already owned by another account
verification/bind conflict after pending claim
```

No raw database error should leak to the user.

### Failure / Race States

- two accounts may temporarily hold the same unverified contact only if the chosen implementation safely allows it;
- when ownership is confirmed, only one account may bind the verified identifier;
- the losing account stays unverified and receives a controlled conflict;
- no migration may delete/rewrite development identities merely to force uniqueness;
- no uniqueness collision may silently move an identifier between UUIDs;
- no verified identifier collision may create a second valid canonical Tio account.

## 5. Implementation Plan

### Phase A — schema/function source

- [ ] Add one canonical provider-aware Email identity function owned by Supabase/database source.
- [ ] Choose and document the server-owned verified Email uniqueness representation.
- [ ] Add canonical verified Mobile uniqueness representation using E.164.
- [ ] Keep pending/unverified contacts non-authoritative.
- [ ] Backfill canonical verified ownership only for trusted existing contacts.
- [ ] Refuse migration if verified ownership collisions are found; do not silently repair/delete users.

### Phase B — Auth/database alignment

- [ ] Update `private.provision_tio_user_root()` to use the canonical contract without fabricating verification.
- [ ] Update `private.reconcile_tio_user_contact_verification()` so trusted confirmation performs the final canonical ownership bind atomically.
- [ ] Preserve the existing verification guard contract.
- [ ] Ensure changing one contact does not invalidate the unrelated verified contact.

### Phase C — Google admission

- [ ] Update `google-login-admission` to canonicalize the verified Google Email with the same rule.
- [ ] Resolve existing account by canonical verified Email identity rather than exact lowercase Email text.
- [ ] Preserve token verification and account-enumeration-safe response behavior.

### Phase D — application conflicts

- [ ] Stop mapping every `23505` to Username conflict.
- [ ] Add controlled typed Email/Mobile ownership conflict mapping where applicable.
- [ ] Keep Username RPC/claim behavior unchanged.
- [ ] Ensure pending contact save and verified-bind conflicts have distinct behavior/messages.

### Phase E — validation

- [ ] Read-only preflight duplicate normalized Email groups.
- [ ] Read-only preflight Gmail alias collision groups.
- [ ] Read-only preflight Mobile E.164 collision groups.
- [ ] Unit tests for Gmail, googlemail, plus-tag, dot variants and non-Gmail domains.
- [ ] Tests proving unverified contact is not ownership/login/recovery truth.
- [ ] Race/conflict test for two pending claims and one final verified owner.
- [ ] Google admission canonical alias tests.
- [ ] Username vs Email vs Mobile conflict typing tests.
- [ ] Flutter/Dart analyze/tests and required CI.
- [ ] Production migration only after separate explicit owner approval.
- [ ] Post-DDL security/performance advisors and exact live migration evidence.

## 6. Quality Review

### Validation Run

```text
Planning/audit only so far.

Read-only live audit:
- normalized Email duplicate groups: 0
- Mobile duplicate groups: 0
- Gmail alias collision groups: 0
- email/mobile indexes are currently non-unique
- email_identity_key is currently absent
```

No production schema/data mutation was performed while creating this brief.

### Review Findings and Resolution

The earlier simple idea of `UNIQUE lower(email)` / `UNIQUE mobile` is insufficient by itself because Tio explicitly allows optional secondary Email/Mobile to exist before verification. The implementation must distinguish pending contact storage from verified identifier ownership, otherwise an unverified user could reserve someone else's identifier.

The exact final schema mechanism remains an implementation design detail, but the product/security invariants above are frozen and must not be weakened.

## 7. Final Handoff

### Changed Files

Planning-only task brief.

### Actual Behavior

No runtime behavior or production Supabase state changed by this brief.

### Known Limitations

- Phone OTP Signup/Login remains a later bounded capability.
- #118 remains blocked until this foundation and real Phone OTP Auth are validated.
- Google linking, password setup/recovery completion, and Change Password remain later #34 slices.

### Final Status

`REVIEW` — architecture/product rules are frozen; implementation has not started.
