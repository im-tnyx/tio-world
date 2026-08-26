# Auth Verified Identifier Ownership + Reconciliation

**Status:** Ready
**Primary owner:** `supabase/*`; `apps/features/auth` / `apps/features/profile` only for later conflict/admission wiring
**Affected platforms:** Supabase database contract; later Flutter/Auth consumers
**Related issue:** #34
**Parent task:** `.ai/tasks/auth-identifier-uniqueness.md`
**Depends on:** `.ai/tasks/auth-canonical-email-identity-function.md`

## 1. Discovery

### User Outcome

Enforce one canonical Tio account per **verified** Email identity and per **verified** Mobile identity without preventing an authenticated user from temporarily storing an unverified secondary contact.

The schema must remain minimal. Existing contact columns are sufficient:

```text
public.users.email
public.users.email_verified_at
public.users.mobile
public.users.mobile_verified_at
```

No `email_identity_key` column is required unless a later implementation proves the expression-index/RPC design insufficient.

### Success Criteria

- Verified Gmail/Googlemail aliases cannot be owned by two `public.users.id` rows.
- Verified E.164 Mobile cannot be owned by two `public.users.id` rows.
- Unverified secondary Email/Mobile does not reserve ownership.
- Auth reconciliation never wipes the unrelated pending/verified contact.
- Final verified bind is atomic and race-safe.
- Existing trusted verification projection semantics remain Supabase Auth-owned.
- No silent merge or UUID switch.

### Scope

- fresh live read-only collision/preflight audit;
- verified-only partial UNIQUE index design;
- Auth reconciliation safety design;
- canonicalizer privilege/index-expression compatibility audit;
- exact migration shape recommendation;
- durable handoff for implementation.

### Non-Goals

- applying DDL to production;
- Phone OTP Signup/Login;
- #118 Auth UI;
- Google admission implementation;
- Email Signup canonical admission implementation;
- Google linking/password/recovery;
- adding a new contact table or `email_identity_key` column.

## 2. Codebase Exploration

### Verified Evidence

Current live `public.users` state on project `oykupyiitspujzpwwvuj`:

```text
verified Email rows                         2
verified Mobile rows                        0
pending Email rows                          0
pending Mobile rows                         0
verified canonical Email collision groups  0
verified Mobile collision groups           0
pending Email overlaps verified owner       0
pending Mobile overlaps verified owner      0
pending Email duplicate groups              0
pending Mobile duplicate groups             0
```

Current live `auth.users` state:

```text
auth users                                  2
confirmed Email rows                        2
unconfirmed Email rows                      0
confirmed Phone rows                        0
canonical Email collision groups (all)      0
canonical Email collision groups confirmed  0
Phone collision groups                      0
missing public.users roots                  0
verification projection mismatch rows       0
```

Verified Email quality preflight:

```text
verified Email rows                         2
canonicalizer would return NULL             0
verified display Email != canonical key      0
```

Current indexes:

```text
idx_users_email_lower     NON-UNIQUE lower(email) WHERE email IS NOT NULL
idx_users_mobile          NON-UNIQUE mobile WHERE mobile IS NOT NULL
idx_users_username_lower  UNIQUE
users_username_key        UNIQUE constraint
```

Current client boundary:

- `public.users` has RLS enabled.
- authenticated users can select/insert/update only their own `id` through RLS.
- column grants are broad, including contact verification columns, but `trg_users_protect_contact_verification` prevents `anon`/`authenticated` from promoting verification timestamps and clears the affected verification timestamp when the corresponding contact changes.
- both `private.reconcile_tio_user_contact_verification()` and `public.protect_user_contact_verification()` are owned by `postgres`.

Current pending Mobile persistence:

`SupabaseAccountSetupRepository.completeAccountSetup()` writes canonical E.164 Mobile directly to `public.users.mobile` and explicitly clears `mobile_verified_at` when the value changes. This intentionally allows pending/unverified Mobile storage.

Current trusted verification adapter:

`SupabaseAccountContactVerificationRepository` uses Supabase Auth `updateUser` + provider OTP confirmation and never writes verification timestamps itself. Verification succeeds only when the authoritative returned/current Auth user exposes the exact target contact as confirmed.

### Critical Reconciliation Defect

Current live `private.reconcile_tio_user_contact_verification()` is triggered by:

```text
AFTER INSERT OR UPDATE OF email, email_confirmed_at, phone, phone_confirmed_at
ON auth.users
```

But every invocation writes **both** application contacts:

```text
email = normalized auth.users.email
email_verified_at = auth email confirmation projection
mobile = normalized auth.users.phone
mobile_verified_at = auth phone confirmation projection
```

Therefore an Email-only Auth update can erase a pending Mobile stored only in `public.users`, and a Phone-only Auth update can erase a pending Email stored only in `public.users`. This violates the frozen complementary-contact model.

### Expression-Index Privilege Finding

The Step 1 source currently defines `public.canonical_email_identity(text)` as immutable but revokes `EXECUTE` from normal app roles.

PostgreSQL evaluates index expressions during DML as the inserting/updating user. Function `EXECUTE` privilege is therefore relevant to an expression index. A verified-only expression index that calls a function which `authenticated` cannot execute can cause permission failures on DML paths where the index expression is evaluated.

Durable references:

- PostgreSQL privileges: https://www.postgresql.org/docs/current/ddl-priv.html
- PostgreSQL discussion confirming INSERT evaluates index expressions as the inserting user: https://www.postgresql.org/message-id/c43bf10e0b8774e54befaad3d616c2eed0028034.camel%40j-davis.com
- Stored-expression function privilege behavior: https://www.postgresql.org/message-id/11652.1586101335%40sss.pgh.pa.us

Live schema audit also confirms `authenticated` and `anon` currently have no `USAGE` on schema `private`, while `supabase_auth_admin` does.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Do not add `email_identity_key` column | Approved | Existing contact + verification columns plus expression index are sufficient | Product/Data |
| Email uniqueness applies only when `email_verified_at IS NOT NULL` | Frozen | Pending Email must not reserve ownership | Auth/Data |
| Mobile uniqueness applies only when `mobile_verified_at IS NOT NULL` | Frozen | Pending Mobile must not reserve ownership | Auth/Data |
| Gmail aliases use provider-aware canonical function | Frozen | #34 product decision | Auth/Data |
| Reconciliation must update only the Auth contact whose authoritative state changed | Frozen | Preserve unrelated pending/verified contact | Auth/Data |
| Unique bind failure must abort verification transaction | Frozen | At most one verified owner wins a race | Auth/Data |
| No silent conflict repair/merge | Frozen | Ownership conflict needs controlled recovery/linking | Auth |
| Canonicalizer cannot remain an unusable expression-index dependency for authenticated DML | Frozen technical requirement | PostgreSQL function ACL is checked during expression evaluation | Data |

## 4. Architecture Design

### Chosen Approach

Use existing columns plus verified-only partial UNIQUE indexes.

Target Email ownership backstop:

```sql
CREATE UNIQUE INDEX users_verified_email_identity_uidx
ON public.users (canonical_email_identity(email))
WHERE email_verified_at IS NOT NULL;
```

Target Mobile ownership backstop:

```sql
CREATE UNIQUE INDEX users_verified_mobile_uidx
ON public.users (mobile)
WHERE mobile_verified_at IS NOT NULL;
```

Exact function schema/ACL must be adjusted before these indexes are created. Preferred security shape is:

```text
private.canonical_email_identity(text)
→ immutable deterministic function
→ not discoverable/callable as a normal PostgREST RPC
→ EXECUTE available where PostgreSQL stored-expression maintenance requires it
→ trusted server lookup exposed later through a narrowly scoped server RPC/function
```

Because the Step 1 migration has **not** been applied to production, it may be safely revised before first production application rather than preserving a public function shape that conflicts with the index design.

### Reconciliation Algorithm

For `INSERT` on `auth.users`:

```text
provision root
→ reconcile initial Auth Email state
→ reconcile initial Auth Phone state
```

For `UPDATE` on `auth.users`:

```text
emailChanged = NEW.email IS DISTINCT FROM OLD.email
            OR NEW.email_confirmed_at IS DISTINCT FROM OLD.email_confirmed_at

phoneChanged = NEW.phone IS DISTINCT FROM OLD.phone
            OR NEW.phone_confirmed_at IS DISTINCT FROM OLD.phone_confirmed_at

if emailChanged:
  update public.users.email + email_verified_at only

if phoneChanged:
  update public.users.mobile + mobile_verified_at only

never overwrite the unrelated contact merely because the trigger fired
```

This preserves:

```text
Google/Email Auth + pending Mobile
→ Email confirmation/reconciliation does not erase Mobile

Phone Auth + pending Email
→ Phone confirmation/reconciliation does not erase Email
```

### Atomic Verified Bind

When reconciliation changes `email_verified_at` or `mobile_verified_at` from pending/unverified to verified:

```text
Auth confirmation transaction
→ public.users projection update
→ verified-only UNIQUE index check
→ success: current UUID becomes verified owner
→ conflict: DB exception aborts the transaction
→ no second verified owner
```

The application still needs controlled pre-admission/conflict UX in later slices; the database backstop is not a substitute for that UX.

### Canonical Lookup Without Extra Column

A no-column design means PostgREST cannot simply filter `email_identity_key=...`.

Later Google/Email admission should use a narrow trusted server RPC such as conceptually:

```text
verified_email_owner(raw_email)
→ private.canonical_email_identity(raw_email)
→ indexed expression lookup on public.users
→ owner/no-owner result
```

Do not expose raw account existence to normal clients in a way that creates account-enumeration behavior. Google admission can call the trusted RPC with service credentials; Email Signup admission needs a separate enumeration-safe server flow.

### Alternative Rejected

`UNIQUE(email)` / `UNIQUE(mobile)` on all non-null contacts is rejected because pending/unverified contacts would reserve ownership and allow accidental/malicious squatting.

A duplicated `email_identity_key` column is rejected for this slice because it adds synchronization/server-ownership surface without current need.

## 5. Implementation Plan

### Phase A — canonicalizer source correction

- [ ] Revise the unapplied Step 1 canonicalizer migration to an expression-index-safe schema/ACL contract.
- [ ] Validate direct normal-client RPC access remains unavailable if the function is moved under `private`.
- [ ] Validate authenticated DML can maintain the expression index on a disposable/dev Supabase database.

### Phase B — verified ownership migration

- [ ] Preflight verified canonical Email/Mobile collisions and abort migration if any exist.
- [ ] Add named `users_verified_email_identity_uidx` partial unique expression index.
- [ ] Add named `users_verified_mobile_uidx` partial unique index.
- [ ] Do not alter pending/unverified contacts.
- [ ] Do not add `email_identity_key`.

### Phase C — reconciliation safety

- [ ] Replace all-contact overwrite with contact-specific changed-field reconciliation.
- [ ] Preserve the unrelated pending contact.
- [ ] Preserve unrelated verified contact/timestamp.
- [ ] Keep trusted Auth confirmation timestamps as the only verification authority.
- [ ] Add migration/backfill validation proving existing trusted projections remain unchanged.

### Phase D — focused validation

- [ ] Two pending same Email values are allowed.
- [ ] Two pending same Mobile values are allowed.
- [ ] One pending + one verified same Email can coexist, but pending account cannot bind verification.
- [ ] One pending + one verified same Mobile can coexist, but pending account cannot bind verification.
- [ ] Gmail dot/plus/googlemail verified aliases collide.
- [ ] Non-Gmail `+tag` remains a distinct canonical identity unless provider policy says otherwise.
- [ ] Email reconciliation preserves pending Mobile.
- [ ] Phone reconciliation preserves pending Email.
- [ ] Email change does not clear unrelated verified Mobile.
- [ ] Mobile change does not clear unrelated verified Email.
- [ ] Production apply requires separate explicit owner authorization.

## 6. Quality Review

### Validation Run

```text
Fresh live read-only audit only.
No DDL/DML production mutation.

public.users verified Email collisions:      0
public.users verified Mobile collisions:     0
pending-vs-verified overlaps:                 0 / 0
pending duplicate groups:                    0 / 0
auth.users canonical Email collisions:       0
auth/public missing roots:                    0
auth/public verification mismatch rows:      0
verified invalid canonical Email rows:        0
```

Step 1 source checkpoint `a5ecdbef4cc3c012376842982caa737fb0bca5a9` also has:

```text
Flutter CI #2079 / run 32954102032        success
Android Native CI #491 / run 32954102044 success
```

These CI runs validate the repository checkpoint, not a production database migration apply.

### Review Findings and Resolution

The no-extra-column approach is viable, but only with two mandatory corrections before ownership enforcement:

1. reconciliation must become contact-specific so it cannot erase the unrelated pending contact;
2. canonicalizer function schema/ACL must be compatible with PostgreSQL expression-index DML execution.

No product decision remains blocked for this slice. Disposable/dev DB validation is required before any live DDL.

## 7. Final Handoff

### Changed Files

Planning/audit task only.

### Actual Behavior

No runtime or production Supabase behavior changed by this audit.

### Known Limitations

- Google/Email canonical admission remains a later bounded slice.
- Controlled Auth verification conflict UX remains later application wiring.
- Phone OTP remains blocked until identifier ownership foundation is validated.

### Final Status

`REVIEW` — audit complete, implementation ready to begin as a separate explicit step.
