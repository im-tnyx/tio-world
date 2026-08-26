# Auth Verified Identifier Ownership + Reconciliation

**Status:** In progress
**Primary owner:** `supabase/*`; `apps/features/auth` / `apps/features/profile` only for later conflict/admission wiring
**Affected platforms:** Supabase database contract; later Flutter/Auth consumers
**Related issue:** #34
**Parent task:** `.ai/tasks/auth-identifier-uniqueness.md`
**Depends on:** `.ai/tasks/auth-canonical-email-identity-function.md`
**Working branch:** `agent/auth-verified-identifier-ownership`
**Draft child PR:** #119

## 1. Discovery

### User Outcome

Enforce one canonical Tio account per **verified** Email identity and per **verified** Mobile identity without blocking temporary pending/unverified secondary contacts.

The minimal schema remains:

```text
public.users.email
public.users.email_verified_at
public.users.mobile
public.users.mobile_verified_at
```

No `email_identity_key` column or separate contact table is required for this slice.

### Success Criteria

- Verified Gmail/Googlemail aliases cannot be owned by two `public.users.id` rows.
- Verified E.164 Mobile cannot be owned by two `public.users.id` rows.
- Pending/unverified Email/Mobile does not reserve ownership.
- Auth reconciliation updates only the contact whose authoritative Auth state changed.
- A normal client cannot release verified ownership by directly replacing a verified `public.users` contact while Supabase Auth still owns the old identifier.
- Final verified bind is atomic/race-safe and never silently merges UUIDs.
- Supabase Auth confirmation remains the only verification authority.

### Scope

- verified-only partial UNIQUE ownership backstops;
- canonical verified Email + E.164 verified Mobile checks;
- contact-specific Auth reconciliation;
- direct verified-contact mutation hardening in the existing verification guard;
- Step 1 canonicalizer schema/ACL correction needed by the expression index;
- focused disposable/dev SQL verification source;
- read-only live preflight and repository validation evidence.

### Non-Goals

- production DDL apply;
- Phone OTP Signup/Login;
- #118 Phone-first Auth UI;
- Google admission implementation;
- Email Signup canonical admission implementation;
- Google linking / password / recovery;
- Flutter conflict typing;
- extra Email identity-key column.

## 2. Codebase Exploration

### Verified Live Evidence

Project `oykupyiitspujzpwwvuj` read-only audit:

```text
public.users
verified Email rows                         2
verified Mobile rows                        0
pending Email rows                          0
pending Mobile rows                         0
verified canonical Email collision groups  0
verified Mobile collision groups           0
pending Email overlaps verified owner       0
pending Mobile overlaps verified owner      0
pending duplicate groups                    0 / 0

auth.users
auth users                                  2
confirmed Email rows                        2
unconfirmed Email rows                      0
confirmed Phone rows                        0
canonical Email collision groups            0
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

Current indexes before this migration:

```text
idx_users_email_lower     NON-UNIQUE
idx_users_mobile          NON-UNIQUE
idx_users_username_lower  UNIQUE
users_username_key        UNIQUE constraint
```

### Existing Pending Contact Behavior

`SupabaseAccountSetupRepository.completeAccountSetup()` may write a pending E.164 Mobile directly to `public.users.mobile` and leaves/clears `mobile_verified_at` to `NULL`. This is intentional and must remain possible.

`SupabaseAccountContactVerificationRepository` uses Supabase Auth `updateUser` + provider OTP/email confirmation and never writes verification timestamps itself. Success requires the exact target contact to be confirmed by the authoritative Auth user.

### Critical Reconciliation Defect

Current live `private.reconcile_tio_user_contact_verification()` fires for Email/Email-confirmation/Phone/Phone-confirmation Auth changes but rewrites **both** application contacts every time.

This can erase unrelated pending contact data:

```text
Email/Google Auth + pending Mobile
→ Email Auth update
→ old implementation may overwrite Mobile with auth.users.phone = NULL
```

and the reverse for Phone Auth + pending Email.

### Critical Verified-Ownership Release Defect

Current `public.protect_user_contact_verification()` clears the affected verification timestamp when an authenticated client directly changes `public.users.email` or `mobile`.

That behavior is insufficient once verified-only uniqueness is tied to the verification timestamp:

```text
Auth still owns verified Gmail A
→ client directly changes public.users.email
→ old guard clears email_verified_at
→ public verified ownership for Gmail A disappears
→ another Gmail alias could later become verified owner
```

Official Account Settings already verifies contact changes through Supabase Auth first, so direct replacement of an already-verified contact is not required by the supported product flow. The database guard must therefore reject direct client replacement of a verified contact. Pending/unverified contacts remain editable.

### Expression-Index ACL Finding

The Step 1 canonicalizer must be callable by PostgreSQL when maintaining the Email expression index during authenticated/service-role DML. Therefore it now lives under `private.canonical_email_identity(text)` with minimal `USAGE`/`EXECUTE` grants required for database-maintained expression evaluation, while the private schema remains outside normal public PostgREST RPC exposure.

### CI Trigger Finding

Repository Flutter/Android workflows are not automatic validation gates for this Supabase-only child PR:

```text
Flutter CI pull_request base filter: main
Flutter CI path filter: apps/** + workspace/tooling files
Android Native CI pull_request base filter: main
Android Native CI path filter: Android/Flutter app files only
```

PR #119 targets the parent branch and changes only `.ai/` + `supabase/`, so neither workflow auto-runs. Parent checkpoint CI remains relevant for unchanged Flutter/Android source, while this DB slice requires disposable/dev Supabase validation as its meaningful gate.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| No `email_identity_key` column | Approved | Existing contact + verification columns are sufficient | Product/Data |
| Email uniqueness only when verified | Frozen | Pending Email must not reserve ownership | Auth/Data |
| Mobile uniqueness only when verified | Frozen | Pending Mobile must not reserve ownership | Auth/Data |
| Gmail aliases use provider-aware canonicalizer | Frozen | #34 product decision | Auth/Data |
| Reconcile only the changed Auth contact | Frozen | Preserve unrelated pending/verified contact | Auth/Data |
| Direct client change of already-verified contact is rejected | Chosen / required | Prevent releasing DB ownership while Auth still owns identifier | Auth/Data |
| Pending contact remains client-editable | Frozen | Complementary contact may exist before verification | Product/Auth |
| Unique bind failure aborts verification transaction | Frozen | At most one verified owner wins | Auth/Data |
| No silent merge or UUID switch | Frozen | Ownership collision requires controlled later UX | Auth |
| Production apply requires separate approval | Frozen | Current authorization is source implementation only | Owner |

## 4. Architecture Design

### Verified Ownership Backstops

```sql
CREATE UNIQUE INDEX users_verified_email_identity_uidx
ON public.users (private.canonical_email_identity(email))
WHERE email_verified_at IS NOT NULL;

CREATE UNIQUE INDEX users_verified_mobile_uidx
ON public.users (mobile)
WHERE mobile_verified_at IS NOT NULL;
```

Additional trusted-state checks ensure a verified Email canonicalizes to a non-null key and a verified Mobile is canonical E.164.

Pending rows stay outside the unique indexes, so this remains valid:

```text
Account A pending  name+one@gmail.com
Account B pending  n.a.m.e@googlemail.com
→ allowed temporarily

Account A verifies canonical name@gmail.com
→ A becomes verified owner

Account B later tries to verify same canonical identity
→ UNIQUE conflict
→ B remains non-owner
→ no merge
```

### Client Guard

For `authenticated` / `anon` writes to `public.users`:

```text
pending contact change
→ allowed
→ verification remains NULL

attempt to promote verification timestamp
→ ignored/restored to trusted old value

attempt to replace already-verified contact directly
→ reject 42501
→ user must use Supabase Auth contact add/change/removal flow
```

Trusted Auth reconciliation runs as the privileged database owner and may update verified contacts/timestamps.

### Contact-Specific Reconciliation

On `auth.users INSERT`, initialize both Auth contacts because the root is new.

On `auth.users UPDATE`:

```text
Email or email_confirmed_at changed
→ update public Email + email_verified_at only

Phone or phone_confirmed_at changed
→ update public Mobile + mobile_verified_at only
```

Unrelated pending/verified contact is never overwritten merely because the trigger fired.

### Atomic Bind

```text
Supabase Auth confirmation transaction
→ trusted reconciliation update
→ partial UNIQUE index evaluation
→ success: same UUID owns verified identifier
→ conflict: transaction errors/rolls back
→ no second verified owner
```

Later application slices must map the DB/Auth conflict to controlled UX. The unique index is the authoritative backstop, not the final user-facing error flow.

## 5. Implementation Plan

### Phase A — canonicalizer correction

- [x] Move unapplied canonicalizer source to `private.canonical_email_identity(text)`.
- [x] Grant minimal schema/function access needed for stored-expression maintenance.
- [x] Keep it outside normal public PostgREST RPC exposure.
- [x] Align canonicalization verification SQL.

### Phase B — verified ownership migration

- [x] Add migration preflight that aborts on verified Email/Mobile collisions or malformed trusted values.
- [x] Add `users_verified_email_canonical_check`.
- [x] Add `users_verified_mobile_e164_check`.
- [x] Add `users_verified_email_identity_uidx` partial unique expression index.
- [x] Add `users_verified_mobile_uidx` partial unique index.
- [x] Do not modify pending contacts or add `email_identity_key`.

### Phase C — contact safety

- [x] Reject direct client replacement of already-verified Email/Mobile.
- [x] Keep pending contact replacement allowed and unverified.
- [x] Replace all-contact reconciliation with contact-specific reconciliation.
- [x] Preserve unrelated pending/verified contact.
- [x] Keep Supabase Auth confirmation timestamps as verification authority.

### Phase D — validation

- [x] Add disposable/dev SQL verification source covering pending duplicates, verified canonical collisions, authenticated expression-index maintenance, verified direct-mutation guard, and pending edits.
- [x] Fresh live preflight is collision-clean.
- [x] Confirm app CI does not auto-trigger for this parent-targeted Supabase-only child PR; no Flutter/Android source changed.
- [ ] Execute both migrations and verification scripts on disposable/dev Supabase.
- [ ] Verify reconciliation with real Auth-trigger transactions on disposable/dev Supabase.
- [ ] Production migration only after separate explicit owner approval.

## 6. Quality Review

### Source Checkpoints

```text
545eb43eb4009e5be74b2938fe3d9273a37dda19
  Step 1 canonicalizer private-schema/ACL correction

6b7a68a18cb451fa7376875b47058d7b189b8d3e
  verified ownership + guard + reconciliation migration

a9b30fa1a33bb72083145a17a2faf71089c266ed
  focused disposable/dev SQL verification hardening
```

Parent checkpoint before this child branch had:

```text
Flutter CI #2079 / run 32954102032        success
Android Native CI #491 / run 32954102044 success
```

PR #119 is Draft, targets the current parent branch, and is a six-file `.ai/` + `supabase/` diff. Flutter/Android workflow filters intentionally produce no child-run for this diff.

Current child source has **not yet** been executed as DDL on any Supabase environment in this task. Production DDL/DML remains untouched.

### Review Findings and Resolution

The no-extra-column approach remains valid, but only after three protections are present together:

1. canonical verified-only unique indexes;
2. contact-specific Auth reconciliation;
3. prevention of direct client replacement of an already-verified contact.

Without item 3, a client could release the public verified-ownership predicate while Supabase Auth still owned the identifier. This finding is now part of the durable design and migration source.

The remaining validation gate is database-specific, not Flutter-specific: run the migrations and focused verification against a disposable/dev Supabase branch before considering production application.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/auth-canonical-email-identity-function.md`
- `.ai/tasks/auth-verified-identifier-ownership-reconciliation.md`
- `supabase/migrations/20260826093500_add_canonical_email_identity_function.sql`
- `supabase/migrations/20260826100000_enforce_verified_identifier_ownership.sql`
- `supabase/drafts/20260826_verify_canonical_email_identity.sql`
- `supabase/drafts/20260826_verify_verified_identifier_ownership.sql`

### Actual Behavior

Repository source now contains the verified-ownership migration design and focused verification scripts. No live production behavior has changed because neither new migration has been applied.

### Known Limitations

- Disposable/dev DB execution is still required before production consideration.
- Google and Email Signup canonical admission remain later slices.
- Flutter typed Email/Mobile conflict UX remains later work.
- Phone OTP and #118 remain blocked on this foundation being validated.

### Final Status

`PARTIAL` — source implementation complete for this bounded DB slice; disposable/dev migration + real Auth-trigger validation remain pending.
