# Auth Canonical Email Identity Function

**Status:** In progress
**Primary owner:** `supabase/*`
**Affected platforms:** Supabase database contract only
**Related issue:** #34
**Parent task:** `.ai/tasks/auth-identifier-uniqueness.md`

## 1. Discovery

### User Outcome

Create the smallest server-owned canonical Email identity primitive required before Email/Mobile verified-ownership enforcement and Phone-first Auth can safely expand account entry paths.

### Success Criteria

- One database function defines Tio's provider-aware Email identity key.
- Gmail and Googlemail aliases canonicalize to the same identity key by lowercasing, normalizing `googlemail.com` to `gmail.com`, removing Gmail local-part dots, and stripping `+tag`.
- Non-Gmail domains are trimmed/lowercased without universal `+tag` stripping or dot removal.
- Blank or structurally invalid single-address input returns `NULL` instead of producing an ownership key.
- Normal Flutter clients cannot execute the canonicalization function directly as an authoritative account-resolution primitive.
- No Email/Mobile uniqueness constraint, ownership bind, reconciliation behavior, Auth UI, or production Supabase state changes in this slice.

### Scope

- Add one forward migration defining the canonical Email identity function.
- Lock function execution to trusted server roles needed by later database/Auth composition.
- Record focused canonicalization cases and validation evidence.

### Non-Goals

- `public.users.email_identity_key` column or unique index.
- Mobile uniqueness.
- Auth-to-account reconciliation changes.
- Email Signup admission changes.
- `google-login-admission` changes.
- Phone OTP capability or Auth UI.
- Production migration apply.

## 2. Codebase Exploration

### Verified Evidence

- `.ai/tasks/auth-identifier-uniqueness.md` freezes provider-aware Gmail canonicalization and verified-only ownership semantics.
- `private.provision_tio_user_root()` currently uses only `lower(btrim(new.email))`.
- `private.reconcile_tio_user_contact_verification()` currently uses only lower/trim Email normalization.
- `google-login-admission` currently performs exact lowercased Email lookup.
- Live `public.users` has no `email_identity_key`; current lower-Email and Mobile indexes are non-unique.
- Existing verified contact ownership remains Supabase Auth-backed and must not be weakened.
- Live read-only preflight confirms `public.canonical_email_identity(text)` does not already exist and trusted roles `service_role` / `supabase_auth_admin` are present.

### Existing Pattern to Follow

- Supabase migrations own durable database functions and revoke client execution for privileged helpers.
- Later slices will consume the same canonical contract from provisioning/reconciliation/admission rather than inventing separate identity rules.

### Tests or Validation Already Present

- Read-only duplicate/Gmail-alias preflight is clean from the parent audit.
- No dedicated SQL test directory currently exists under `supabase/`; focused non-production verification SQL therefore lives under `supabase/drafts/`.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Canonicalization is provider-aware | Frozen | Gmail alias semantics differ from other domains | #34 Product/Auth |
| Function is server-owned | Frozen | Client input cannot become authoritative account identity | Auth/Data |
| Invalid input returns `NULL` | Chosen | Ownership code must fail closed instead of creating malformed keys | Auth/Data |
| This slice does not add uniqueness | Frozen scope | Keep one bounded implementation slice active | Architecture |
| Production apply is separate | Frozen | Source implementation does not authorize live DDL | Owner |

## 4. Architecture Design

### Chosen Approach

Define one immutable SQL function in the database contract that accepts raw Email text and returns the canonical identity key or `NULL`.

```text
raw Email
→ trim + lowercase
→ exactly one @ + non-empty local/domain guard
→ Gmail/Googlemail provider rule OR generic-domain rule
→ canonical identity key
```

For Gmail consumer identities:

```text
Na.Me+Fit@googlemail.com
→ name@gmail.com
```

For other domains:

```text
User+Fit@Example.com
→ user+fit@example.com
```

The function is intentionally placed in `public` with normal client execution revoked. This lets a later trusted Edge Function use the same database-owned contract through privileged RPC instead of reimplementing Gmail identity rules in TypeScript, while `anon` and `authenticated` cannot treat the function as client authority.

### Ownership and Data Flow

```text
Later trusted Auth/provisioning/reconciliation/admission code
→ public.canonical_email_identity(text)
→ verified ownership representation
```

### Alternative Rejected

Do not begin by adding `UNIQUE lower(email)` because pending/unverified secondary contacts must not reserve ownership and Gmail aliases require provider-aware canonicalization.

Do not duplicate Gmail alias logic separately in Flutter and `google-login-admission`; the database contract is the durable authority for later trusted consumers.

### Failure and Accessibility States

Database-only slice. Malformed input fails closed to `NULL`; no user-facing UI changes.

## 5. Implementation Plan

- [x] Add canonical Email identity function migration source.
- [x] Revoke normal client execution; grant only trusted server roles required by later slices.
- [x] Add focused verification SQL for Gmail, Googlemail, plus-tag, dot, mixed-case, non-Gmail plus-tag, blank, and malformed cases.
- [x] Run read-only equivalent logic against live Postgres to validate the case matrix without applying DDL.
- [x] Review migration for unintended schema/data mutations.
- [ ] Execute the actual migration + verification script on a disposable/dev Supabase database before declaring migration syntax/runtime validation complete.
- [ ] Record final CI and disposable/dev DB validation evidence.

## 6. Quality Review

### Validation Run

```text
Source commits:
- e9f1385f938f5c7b14854031370cef387d9c3f45  task brief start
- 6d78ca6e4988ec4f091e47c608874221c494b2d0  canonical function migration source
- b89cefa9cd2b5729dac6731e8e0c680b15b43fe2  focused SQL verification script

Live Supabase read-only preflight:
- public.canonical_email_identity(text) already exists: false
- required trusted roles present: service_role, supabase_auth_admin
- normal roles present for explicit revoke: anon, authenticated

Read-only canonicalization matrix using the exact proposed algorithm:
- 12/12 cases matched expected output
- Gmail +tag collapse: pass
- Gmail dot collapse: pass
- googlemail.com → gmail.com: pass
- case/outer-space normalization: pass
- non-Gmail +tag preserved: pass
- non-Gmail dots preserved: pass
- blank/missing @/multiple @/missing local/missing domain/embedded whitespace: fail closed to NULL

Production DDL/data mutation: NOT performed.
Actual migration compilation/execution on disposable/dev DB: pending.
GitHub CI for b89cefa...: Flutter CI #2078 and Android Native CI #490 currently running.
```

### Review Findings and Resolution

The migration only creates the canonicalization function, comment, and execution grants. It does not add a column/index, backfill data, alter verification timestamps, modify Auth reconciliation, or change application behavior.

Keeping the function `IMMUTABLE` makes it usable by later indexed/generated ownership representations if that final schema shape is selected. Normal client roles are explicitly revoked; only trusted server roles are granted execution.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/auth-canonical-email-identity-function.md`
- `supabase/migrations/20260826093500_add_canonical_email_identity_function.sql`
- `supabase/drafts/20260826_verify_canonical_email_identity.sql`

### Actual Behavior

Repository source now contains the canonical Email identity primitive and focused verification script. No live Supabase behavior has changed because the migration has not been applied.

### Known Limitations

- Actual migration execution/compilation still needs disposable/dev Supabase validation.
- Verified Email/Mobile ownership enforcement is not implemented yet.
- Pending-contact-safe reconciliation remains the next ownership-related slice after the canonical primitive is validated.
- Email Signup/Google admission do not consume the canonical function yet.
- Production migration apply requires separate explicit owner approval.

### Final Status

`PARTIAL` — source implementation is complete; disposable/dev DB execution and CI completion remain pending.
