# Auth Canonical Email Admission

**Status:** In progress
**Primary owner:** `supabase/*`; later Google/Email client wiring remains separate bounded slices
**Affected platforms:** Supabase Auth/Postgres server boundary
**Related issue:** #120
**Parent tracker:** #34
**Depends on:** PR #119 verified identifier ownership foundation
**Working branch:** `agent/auth-canonical-email-admission`
**Draft child PR:** #121

## 1. Discovery

### User Outcome

Prevent a verified Google Email alias from creating a second canonical Tio account, while establishing one server-owned canonical verified-Email lookup that later Google admission can reuse. Keep Email/password signup enumeration safety intact rather than exposing raw account existence through a pre-signup probe.

### Success Criteria

- one trusted server-owned lookup answers whether a **verified** canonical Email owner exists;
- Gmail/Googlemail alias semantics reuse `private.canonical_email_identity(text)`;
- normal `anon` / `authenticated` clients cannot call the owner lookup;
- a `Before User Created` Postgres hook can block a new **Google** Auth user when the verified canonical Email is already owned;
- Email/password signup is **not** rejected by this hook solely because a verified canonical owner exists, because a hook error would make raw account existence observable before Email ownership is proven;
- no new table, column, identity-key field, or Flutter UI is added;
- production Auth hook enable/apply remains a separate explicit owner decision.

### Scope

- add one restricted server RPC for verified canonical Email owner existence;
- add one private Postgres `Before User Created` hook function scoped to Google new-user creation;
- add focused SQL verification source and local hook configuration;
- record security/enumeration-safety decisions in #120.

### Non-Goals

- production migration apply or hosted Auth Hook enable;
- changing `google-login-admission` in this slice;
- changing Flutter Email Signup/Google UI;
- Email/password canonical pre-admission implementation;
- password policy/recovery/change-password;
- identity linking/unlinking;
- Phone OTP / #118;
- new Email identity table/column.

## 2. Codebase Exploration

### Verified Evidence

- `public.users` already has verified-only canonical Email ownership via `users_verified_email_identity_uidx`.
- `private.canonical_email_identity(text)` is live and provider-aware.
- `service_role` has `BYPASSRLS`, `SELECT` on `public.users`, and canonicalizer execution.
- `supabase_auth_admin` does **not** have `BYPASSRLS` or `SELECT` on `public.users`; it does have canonicalizer execution.
- Current `google-login-admission` verifies the Google ID token server-side, including signature, audience, issuer, expiry, and `email_verified = true`, but its account lookup is exact `lower(trim(email))`.
- Current Google existing-account flow gates the Supabase token exchange through `google-login-admission`.
- Current Google signup-capable flow starts admission only as background classification and still performs `signInWithIdToken`, so a canonical alias can reach Auth account creation.
- Current Email signup calls `supabase.auth.signUp` directly after trim/lowercase; `user != null && session == null` is already treated as pending Email confirmation.
- Supabase documents `Before User Created` as running immediately before a new Auth user insert and allowing a Postgres function to reject creation.
- Supabase also documents obfuscated duplicate Email-signup behavior to reduce account enumeration. Returning a canonical-owner hook error for unverified Email/password signup would weaken that property.
- Current Supabase CLI hook schema explicitly supports `before_user_created`; the current CLI config template uses `[auth.hook.before_user_created]` plus a `pg-functions://postgres/<schema>/<function>` URI.

### Existing Pattern to Follow

- privileged database behavior is versioned in `supabase/migrations/`;
- server-only callable functions explicitly revoke `public`, `anon`, and `authenticated` execution;
- privileged functions use fixed `search_path` and narrow static SQL;
- production changes are separate from source implementation.

### Tests or Validation Already Present

- canonical Email matrix already covers Gmail/Googlemail aliases and non-Gmail `+tag` preservation;
- live verified Email collision groups are zero after PR #119 migration apply;
- auth repository tests cover Google admission-before-exchange and Email-signup session-present/session-absent semantics.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Reuse DB canonicalizer | Frozen | One provider-aware identity contract | Auth/Data |
| Lookup only verified owners | Frozen | Pending/unverified Email is not ownership | #34/#120 |
| No normal-client existence RPC | Frozen | Avoid enumeration/authority leakage | Security |
| Google new-user creation may be hook-gated | Chosen | Google provider evidence proves Email ownership before Auth exchange | Auth/Security |
| Email/password new-user creation is not hook-gated in this slice | Chosen | Hook rejection would expose canonical account existence before Email ownership proof | Auth/Security |
| Narrow helper may be `SECURITY DEFINER` | Chosen | Avoid broad `supabase_auth_admin` table SELECT; helper is static/read-only and returns only boolean | Auth/Data |
| Hook itself remains invoker | Chosen | Follow Supabase Auth-hook least-privilege guidance | Auth/Data |
| DB unique index remains final race-safe backstop | Frozen | Admission checks do not replace atomic ownership enforcement | Data |
| Production hook enable/apply is separate | Frozen | Source work does not authorize hosted Auth behavior change | Owner |

## 4. Architecture Design

### Chosen Approach

Add a narrow server-only RPC in `public` because the existing Edge Function can later call exposed PostgREST RPC schemas. Revoke it from normal client roles and grant only trusted server roles. The RPC performs one verified-owner existence lookup using the existing canonical expression and returns no UUID.

The RPC uses a tightly-scoped `SECURITY DEFINER` implementation so `supabase_auth_admin` does not receive broad table `SELECT` rights. It contains only static read-only SQL and `SET search_path = ''`.

Add a private invoker `Before User Created` hook that calls the RPC only for `provider = google`:

```text
new Google Auth user candidate
→ Before User Created hook
→ verified canonical owner exists?
   ├─ no  → allow Auth creation
   └─ yes → reject second UUID creation
```

Email/password remains different:

```text
unverified Email signup attempt
→ do not expose canonical owner existence through hook response
→ Supabase signup semantics continue
→ verified-only UNIQUE index remains final ownership backstop
→ canonical Email signup UX/admission handled in later #120 slice
```

### Ownership and Data Flow

```text
Google provider evidence
→ Supabase Auth Before User Created
→ private hook
→ restricted public verified-owner RPC
→ private.canonical_email_identity(text)
→ public.users verified-only ownership index
```

### Alternative Rejected

- Do not add `email_identity_key` or another contact table.
- Do not grant `supabase_auth_admin` broad `SELECT` on `public.users` just for one lookup.
- Do not expose a raw owner-existence RPC to `anon` / `authenticated`.
- Do not reject Email/password signup from this hook based on an unverified input Email; that would turn canonical account existence into an observable pre-verification response.

### Failure and Accessibility States

Database/server-only slice. Google conflict returns one controlled hook error and no second Auth UUID after the hook is actually enabled. Infrastructure/programmer errors must not silently create a second canonical verified owner; the existing verified-only UNIQUE index remains the final DB backstop.

## 5. Implementation Plan

- [x] Complete fresh source + live privilege audit.
- [x] Freeze enumeration-safe Google-vs-Email hook boundary.
- [x] Add restricted verified canonical Email owner lookup migration source.
- [x] Add private Google-scoped Before User Created hook migration source.
- [x] Add focused SQL verification source.
- [x] Confirm and wire current local `config.toml` hook contract; do not imply hosted hook enable.
- [x] Review branch diff against PR #119 parent.
- [x] Open Draft child PR #121.
- [ ] Execute actual migration/hook runtime validation only after an explicitly approved target is available.
- [ ] Apply/enable on hosted Supabase only after separate explicit owner approval.

## 6. Quality Review

### Validation Run

```text
Fresh read-only live privilege audit:
- service_role BYPASSRLS: true
- service_role SELECT public.users: true
- service_role canonicalizer EXECUTE: true
- supabase_auth_admin BYPASSRLS: false
- supabase_auth_admin SELECT public.users: false
- supabase_auth_admin canonicalizer EXECUTE: true

Fresh read-only equivalent lookup audit:
- known verified owner lookup logic: true
- reserved no-owner fixture collision: false
- public.verified_email_owner_exists(text) already live: false
- private.before_user_created_canonical_email_guard(jsonb) already live: false

Supabase CLI contract audit:
- hook key `before_user_created`: confirmed
- Postgres hook URI shape: confirmed

Branch compare against `agent/auth-verified-identifier-ownership` before this handoff:
- behind: 0
- changed runtime/config files are limited to `supabase/*`; task brief under `.ai/tasks/`

Production DDL/Auth-hook mutation from this task: NOT performed.
Actual migration compilation/hook runtime test: NOT performed; no separate dev branch requested and hosted apply is not authorized by this slice.
```

### Review Findings and Resolution

The initial idea of using one rejecting `Before User Created` hook for both Google and Email/password is unsafe for Email enumeration semantics. This task narrows the hook to Google, where provider verification establishes the Email before new-user creation, and leaves Email signup admission for a later dedicated #120 slice.

The hook itself stays `SECURITY INVOKER`. Only the narrow boolean lookup is `SECURITY DEFINER`, avoiding a broad `SELECT` grant to `supabase_auth_admin` while not returning user identity data.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/auth-canonical-email-admission.md`
- `supabase/migrations/20260826104000_add_canonical_email_admission_guard.sql`
- `supabase/drafts/20260826_verify_canonical_email_admission.sql`
- `supabase/config.toml`

### Actual Behavior

Repository source now contains the canonical verified-owner lookup, Google-only Before User Created guard, focused verification SQL, and local hook wiring. Hosted Supabase behavior is unchanged because the migration and hosted Auth Hook have not been applied/enabled in this task.

### Known Limitations

- actual migration compilation and real Auth-hook invocation remain unvalidated until an approved runtime target is used;
- `google-login-admission` still uses exact lowercased Email lookup;
- Email/password canonical alias admission remains later #120 work;
- no Flutter/UI changes are included.

### Final Status

`PARTIAL` — source shape and read-only audits are complete; actual migration/hook runtime validation and hosted activation remain pending separate approval.
