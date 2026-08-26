# Auth Canonical Email Identity Function

**Status:** In progress
**Primary owner:** `supabase/*`
**Affected platforms:** Supabase database contract only
**Related issue:** #34
**Parent task:** `.ai/tasks/auth-identifier-uniqueness.md`

## 1. Discovery

### User Outcome

Create one provider-aware canonical Email identity primitive that later verified-ownership, Signup admission, Google admission, recovery, and linking paths can reuse without duplicating Gmail alias rules.

### Success Criteria

- Gmail / Googlemail aliases collapse by trim + lowercase + `googlemail.com -> gmail.com` + Gmail dot removal + Gmail `+tag` removal.
- Other domains are trim/lowercase normalized without universal `+tag` stripping or dot removal.
- Blank or structurally ambiguous input returns `NULL`.
- The canonicalizer is a database-owned primitive, not client-owned account authority.
- Its ACL/schema shape is compatible with later PostgreSQL expression-index maintenance.
- No production Supabase DDL is applied without separate owner authorization.

### Scope

- one immutable canonical Email function migration;
- focused non-production verification SQL;
- expression-index-safe schema/ACL correction discovered by Step 2 audit.

### Non-Goals

- verified Email/Mobile uniqueness itself;
- Account contact reconciliation changes;
- Signup/Google admission changes;
- Phone OTP / #118 UI;
- production migration apply.

## 2. Codebase Exploration

### Verified Evidence

- `.ai/tasks/auth-identifier-uniqueness.md` freezes provider-aware Gmail canonicalization and verified-only ownership semantics.
- Current provisioning/reconciliation and Google admission still use simple lower/trim Email matching.
- Live `public.users` has no extra Email identity-key column and current Email/Mobile indexes are non-unique.
- Step 2 audit proved a public function with normal client execution revoked is incompatible with the chosen verified-only expression-index design because PostgreSQL must evaluate the function during DML index maintenance.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Provider-aware canonicalization | Frozen | Gmail alias semantics differ from other providers | Product/Auth |
| No universal non-Gmail `+tag` stripping | Frozen | Provider semantics vary | Product/Auth |
| Invalid/ambiguous input returns `NULL` | Frozen | Ownership must fail closed | Auth/Data |
| Function lives under `private` | Chosen after Step 2 audit | Avoid normal PostgREST RPC exposure while supporting DB ownership/index use | Data |
| `authenticated` / `service_role` may execute only this deterministic primitive | Chosen | PostgreSQL stored-expression maintenance requires function/schema access | Data |
| Function output alone never proves ownership | Frozen | Verification remains Supabase Auth authority | Auth |
| Production apply is separate | Frozen | Source implementation is not live DDL authorization | Owner |

## 4. Architecture Design

```text
raw Email
→ private.canonical_email_identity(text)
→ canonical account-resolution key
→ later verified-only ownership/admission consumers
```

Examples:

```text
Na.Me+Fit@googlemail.com → name@gmail.com
N.A.M.E+tag@gmail.com    → name@gmail.com
User+Fit@Example.com     → user+fit@example.com
First.Last@Example.com   → first.last@example.com
```

The function is `IMMUTABLE`, `STRICT`, and `PARALLEL SAFE`. It lives in the `private` schema. `authenticated`, `service_role`, and `supabase_auth_admin` receive the minimum namespace/function access needed for database-maintained expressions and trusted server/database paths. The private schema remains outside the normal public PostgREST exposure surface.

## 5. Implementation Plan

- [x] Add provider-aware canonical function source.
- [x] Add focused canonicalization verification SQL.
- [x] Run read-only equivalent canonicalization matrix against live Postgres: 12/12 expected cases passed.
- [x] Revise the unapplied migration from `public` to `private` after expression-index ACL audit.
- [x] Align verification SQL with the private schema.
- [ ] Execute the actual migration and verification SQL on a disposable/dev Supabase database.
- [ ] Record final child-branch CI + disposable/dev DB evidence.

## 6. Quality Review

### Validation Run

```text
Parent checkpoint before Step 2 ACL correction:
a5ecdbef4cc3c012376842982caa737fb0bca5a9
Flutter CI #2079 / run 32954102032        success
Android Native CI #491 / run 32954102044 success

Read-only canonicalization matrix: 12/12 pass
Production DDL/DML: NOT performed
Disposable/dev migration execution: pending
```

Current child branch source correction:

```text
agent/auth-verified-identifier-ownership
545eb43eb4009e5be74b2938fe3d9273a37dda19
```

### Review Findings and Resolution

The original public-function ACL was safe from client-authority misuse but not suitable for the later expression-index implementation. Because the migration has never been applied to production, the source was corrected before first live application instead of introducing a compatibility migration for a schema shape that never went live.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/auth-canonical-email-identity-function.md`
- `supabase/migrations/20260826093500_add_canonical_email_identity_function.sql`
- `supabase/drafts/20260826_verify_canonical_email_identity.sql`

### Actual Behavior

Repository source contains the canonical Email identity primitive. Live production behavior is unchanged because the migration is not applied.

### Known Limitations

Verified ownership enforcement and contact-specific reconciliation are owned by `.ai/tasks/auth-verified-identifier-ownership-reconciliation.md`. Signup/Google admission and Phone OTP remain later slices.

### Final Status

`PARTIAL` — source contract is prepared; disposable/dev DB execution remains required before production consideration.
