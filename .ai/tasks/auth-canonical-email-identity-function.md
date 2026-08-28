# Auth Canonical Email Identity Function

**Status:** In progress
**Primary owner:** `supabase/*`
**Affected platforms:** Supabase database contract only
**Related issue:** #34
**Parent task:** `.ai/tasks/auth-identifier-uniqueness.md`
**Working branch:** `agent/auth-verified-identifier-ownership`

## 1. Discovery

### User Outcome

Provide one provider-aware server-owned Email identity canonicalizer for later verified ownership and account admission without adding an identity-key column.

### Success Criteria

- Gmail/Googlemail aliases collapse by trim/lowercase, `googlemail.com → gmail.com`, Gmail local `+tag` removal, and Gmail local dot removal.
- Non-Gmail domains keep provider-specific local-part semantics; `+tag` and dots are preserved.
- malformed single-address input fails closed to `NULL`.
- no normal public PostgREST RPC surface for the helper.
- no table or column change in this step.

### Non-Goals

- ownership UNIQUE indexes, reconciliation, Signup/Google admission, Phone OTP, Auth UI, or production apply by this task alone.

## 2. Codebase Exploration

Current provisioning/reconciliation and Google admission use only lower/trim Email matching. Live read-only preflight found no canonical verified Email collisions in current rows.

The later verified Email ownership index evaluates the canonicalizer during DML. Therefore the helper must be available to PostgreSQL index maintenance for roles that can write the indexed table, while remaining outside the exposed public RPC schema.

Fresh live private-schema ACL audit confirms existing private functions already have explicit restricted EXECUTE ACLs, so granting schema `USAGE` for expression-index maintenance does not expose them by itself.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Provider-aware Gmail canonicalization | Frozen | #34 product rule |
| No `email_identity_key` column | Approved | Expression index is sufficient |
| Helper under `private` schema | Chosen | Avoid normal public RPC exposure |
| Invalid input returns `NULL` | Chosen | Fail closed for ownership/admission callers |
| Production apply separate | Frozen | Source implementation is not live-DDL authorization |

## 4. Architecture Design

```text
raw Email
→ trim + lowercase
→ exactly one @ + non-empty local/domain guard
→ Gmail/Googlemail provider rule OR generic-domain rule
→ canonical Email identity
```

Examples:

```text
Na.Me+Fit@googlemail.com → name@gmail.com
N.A.M.E+1@gmail.com      → name@gmail.com
User+Fit@Example.com     → user+fit@example.com
First.Last@Example.com   → first.last@example.com
```

The helper is `IMMUTABLE` so it can back the verified-only expression index. Minimal `private` schema/function grants exist only for stored-expression evaluation; account existence/admission will later use a narrow trusted wrapper rather than exposing this helper as public client authority.

## 5. Implementation Plan

- [x] Add provider-aware canonicalizer migration source.
- [x] Move helper to `private` schema for the final expression-index design.
- [x] Align focused SQL verification script.
- [x] Read-only case matrix: 12/12 expected outputs passed.
- [x] Audit private-schema ACL impact.
- [ ] Apply together with the reviewed ownership migration only after separate explicit owner approval.

## 6. Quality Review

```text
Canonicalization read-only matrix: 12/12 pass
Existing live canonical Email collisions: 0
New table/column: none
Production migration apply: not performed
```

No Flutter/UI source changes are part of this task.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/auth-canonical-email-identity-function.md`
- `supabase/migrations/20260826093500_add_canonical_email_identity_function.sql`
- `supabase/drafts/20260826_verify_canonical_email_identity.sql`

### Actual Behavior

Repository source defines the canonical Email identity primitive. Live Supabase behavior is unchanged until migration apply.

### Final Status

`REVIEW` — source and read-only algorithm validation complete; live apply is a separate explicit decision.
