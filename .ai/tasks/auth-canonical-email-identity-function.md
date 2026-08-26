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

### Existing Pattern to Follow

- Supabase migrations own durable database functions and revoke client execution for privileged helpers.
- Later slices will consume the same canonical contract from provisioning/reconciliation/admission rather than inventing separate identity rules.

### Tests or Validation Already Present

- Read-only duplicate/Gmail-alias preflight is clean from the parent audit.
- No dedicated SQL test directory currently exists under `supabase/`.

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

### Ownership and Data Flow

```text
Later trusted Auth/provisioning/reconciliation/admission code
→ canonical Email DB contract
→ verified ownership representation
```

### Alternative Rejected

Do not begin by adding `UNIQUE lower(email)` because pending/unverified secondary contacts must not reserve ownership and Gmail aliases require provider-aware canonicalization.

### Failure and Accessibility States

Database-only slice. Malformed input fails closed to `NULL`; no user-facing UI changes.

## 5. Implementation Plan

- [ ] Add canonical Email identity function migration source.
- [ ] Revoke normal client execution; grant only trusted server roles required by later slices.
- [ ] Validate Gmail, Googlemail, plus-tag, dot, mixed-case, non-Gmail plus-tag, blank, and malformed cases.
- [ ] Review migration for unintended schema/data mutations.
- [ ] Update this brief with exact validation evidence and handoff.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

Pending implementation.

## 7. Final Handoff

### Changed Files

Task brief only so far.

### Actual Behavior

No runtime or production Supabase behavior changed yet.

### Known Limitations

Verified ownership enforcement, reconciliation safety, Signup/Google admission, and typed conflicts remain later bounded slices of #34.

### Final Status

`REVIEW`
