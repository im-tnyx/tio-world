# Auth Verified Identifier Ownership + Reconciliation

**Status:** In progress
**Primary owner:** `supabase/*`; later Flutter/Auth consumers remain separate slices
**Affected platforms:** Supabase database contract
**Related issue:** #34
**Parent task:** `.ai/tasks/auth-identifier-uniqueness.md`
**Depends on:** `.ai/tasks/auth-canonical-email-identity-function.md`
**Working branch:** `agent/auth-verified-identifier-ownership`
**Draft child PR:** #119

## 1. Discovery

### User Outcome

Enforce one canonical Tio account per **verified** Email and **verified** Mobile without adding another identity table/column and without letting pending secondary contacts reserve ownership.

Existing contact model remains sufficient:

```text
public.users.email
public.users.email_verified_at
public.users.mobile
public.users.mobile_verified_at
```

### Success Criteria

- no new table, contact column, generated identity column, or persistent verification CHECK constraint;
- verified Gmail/Googlemail aliases cannot belong to two canonical accounts;
- verified E.164 Mobile cannot belong to two canonical accounts;
- pending Email/Mobile stays non-authoritative and editable;
- Auth reconciliation changes only the contact whose Auth state changed;
- normal clients cannot release an already-verified ownership predicate by directly replacing that verified contact;
- no silent merge or UUID switch.

### Non-Goals

- production DDL apply without separate explicit owner approval;
- Phone OTP / #118 UI;
- Google/Email signup admission;
- password/recovery/linking work;
- Flutter conflict typing;
- `email_identity_key` or a separate contact table.

## 2. Codebase Exploration

### Verified Live Evidence

Current project `oykupyiitspujzpwwvuj` read-only audit:

```text
public.users verified Email rows                         2
public.users verified Mobile rows                        0
verified canonical Email collision groups                0
verified Mobile collision groups                         0
pending Email/Mobile rows                                0 / 0
pending-vs-verified overlaps                             0 / 0
missing public.users roots                               0
verification projection mismatch rows                   0
verified Mobile non-E.164 rows                           0
```

Current indexes are non-unique for Email/Mobile ownership:

```text
idx_users_email_lower   NON-UNIQUE
idx_users_mobile        NON-UNIQUE
```

### Reconciliation Defect

Current live `private.reconcile_tio_user_contact_verification()` rewrites both application contacts whenever any Auth Email/Phone confirmation field changes. Therefore an Email-only Auth update can erase a pending Mobile stored only in `public.users`, and the reverse is also possible.

### Verified-Ownership Release Defect

Current `public.protect_user_contact_verification()` lets a normal client replace a verified contact by clearing the corresponding verification timestamp. Once uniqueness is verified-only, that would release public ownership while Supabase Auth could still own the old verified identifier.

### Canonicalizer ACL Audit

The Email expression index requires PostgreSQL to execute `private.canonical_email_identity(text)` during authenticated/service-role DML. The source therefore grants only the namespace/function access required for that stored-expression maintenance.

Fresh live private-schema ACL audit confirmed the other existing private functions already have explicit restricted EXECUTE ACLs:

```text
private.provision_tio_user_root                       postgres + supabase_auth_admin
private.reconcile_tio_user_contact_verification      postgres + supabase_auth_admin
private.username_suggestions                         postgres only
private.username_unavailability_reason               postgres only
```

So granting schema `USAGE` for index maintenance does not by itself expose those functions to normal clients.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| No new table / identity-key column | Approved | Existing contact + verification columns are sufficient |
| No persistent canonical/E.164 CHECK constraints in this slice | Approved simplification | Supabase Auth is trusted verification authority; migration-time preflight is enough for current minimal foundation |
| Email uniqueness only when verified | Frozen | Pending Email must not reserve ownership |
| Mobile uniqueness only when verified | Frozen | Pending Mobile must not reserve ownership |
| Gmail aliases provider-aware | Frozen | #34 product decision |
| Reconcile only changed Auth contact | Frozen | Preserve unrelated pending/verified contact |
| Direct replacement of already-verified public contact is rejected | Required | Prevent ownership release while Auth still owns identifier |
| Production apply is separate | Frozen | Source work does not authorize live DDL |

## 4. Architecture Design

### Minimal Persistent DB Changes

The ownership migration now intentionally contains **no `ALTER TABLE ... ADD COLUMN` and no persistent `CHECK` constraint**.

Persistent additions are only two named indexes plus replacement of two existing functions:

```sql
CREATE UNIQUE INDEX users_verified_email_identity_uidx
ON public.users (private.canonical_email_identity(email))
WHERE email_verified_at IS NOT NULL;

CREATE UNIQUE INDEX users_verified_mobile_uidx
ON public.users (mobile)
WHERE mobile_verified_at IS NOT NULL;
```

The migration still runs a fail-closed read-only preflight before index creation. It aborts rather than rewriting identities if current trusted rows are malformed or collide.

### Pending vs Verified Ownership

```text
pending/unverified contact
→ may overlap another pending or verified value
→ does not own/reserve identifier

trusted Auth verification projected
→ row enters verified-only UNIQUE index
→ exactly one canonical account can own identifier
```

### Contact-Specific Reconciliation

```text
Auth Email/email_confirmed_at changed
→ update public Email + email_verified_at only

Auth Phone/phone_confirmed_at changed
→ update public Mobile + mobile_verified_at only
```

### Client Guard

```text
pending contact edit
→ allowed, stays unverified

client attempts verification timestamp promotion
→ trusted old value preserved

client directly replaces already-verified contact
→ reject 42501
→ supported change path remains Supabase Auth + trusted reconciliation
```

## 5. Implementation Plan

### Phase A — canonicalizer

- [x] Provider-aware canonical Email function source.
- [x] Move helper to `private` for non-public RPC ownership.
- [x] Grant only schema/function access needed for expression-index maintenance.
- [x] Verify existing private functions remain execution-restricted.

### Phase B — minimal ownership migration

- [x] Migration-time collision/malformed trusted-row preflight.
- [x] `users_verified_email_identity_uidx` partial unique expression index.
- [x] `users_verified_mobile_uidx` partial unique index.
- [x] Remove proposed persistent Email/Mobile CHECK constraints after simplification review.
- [x] No table, column, generated identity field, or contact table added.

### Phase C — contact safety

- [x] Contact-specific Auth reconciliation source.
- [x] Preserve unrelated pending/verified contact.
- [x] Reject direct client replacement of already-verified public Email/Mobile.
- [x] Keep pending contact edits allowed/unverified.

### Phase D — validation / deployment gate

- [x] Focused SQL verification source exists for pending duplicates, verified collisions, expression-index DML, verified direct-mutation guard, and pending edits.
- [x] Fresh production read-only preflight remains clean.
- [x] Source diff reviewed for no new table/column/persistent CHECK constraint.
- [ ] Apply migration to current Supabase project only after separate explicit owner approval.
- [ ] After apply, run focused read-only post-migration checks and Auth contact smoke verification before advancing #34.

## 6. Quality Review

### Current Source Review

Latest simplification removes the two proposed persistent table CHECK constraints. The remaining migration surface is intentionally narrow:

```text
1 canonical Email helper function
2 verified-only UNIQUE indexes
1 existing verification guard replacement
1 existing Auth reconciliation function replacement
```

No app source/UI changed in this child PR. Current Flutter/Android workflows do not auto-run for this parent-targeted `.ai/` + `supabase/`-only diff; the accepted unchanged-app parent checkpoint remains Flutter CI #2079 and Android Native CI #491.

### Production State

```text
New migrations applied: NO
Production DDL/DML mutation from this slice: NO
```

## 7. Final Handoff

### Changed Files

- `.ai/tasks/auth-canonical-email-identity-function.md`
- `.ai/tasks/auth-verified-identifier-ownership-reconciliation.md`
- `supabase/migrations/20260826093500_add_canonical_email_identity_function.sql`
- `supabase/migrations/20260826100000_enforce_verified_identifier_ownership.sql`
- `supabase/drafts/20260826_verify_canonical_email_identity.sql`
- `supabase/drafts/20260826_verify_verified_identifier_ownership.sql`

### Actual Behavior

Repository source now has the minimal verified-ownership/reconciliation migration. Current Supabase behavior has not changed because the migration is unapplied.

### Known Limitations

Google/Email admission, controlled verification-conflict UX, Phone OTP, #118, recovery/password, and linked identities remain later bounded slices.

### Final Status

`REVIEW` — minimal source shape is ready for owner review; live migration apply is a separate explicit decision.
