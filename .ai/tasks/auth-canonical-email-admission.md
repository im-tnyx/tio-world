# Auth Canonical Email Admission

**Status:** In progress
**Primary owner:** `supabase/*`; later Google/Email client wiring remains separate bounded slices
**Affected platforms:** Supabase Auth/Postgres server boundary
**Related issue:** #120
**Parent tracker:** #34
**Depends on:** PR #119 verified identifier ownership foundation
**Working branch:** `agent/auth-canonical-email-admission`

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
- add focused SQL verification source and local hook configuration only if it can remain non-production;
- record security/enum-safety decisions in #120.

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
| Google new-user creation may be hook-gated | Chosen | Google token/provider proves Email ownership before Auth exchange | Auth/Security |
| Email/password new-user creation is not hook-gated in this slice | Chosen | Hook rejection would expose canonical account existence before Email ownership proof | Auth/Security |
| DB unique index remains final race-safe backstop | Frozen | Admission checks do not replace atomic ownership enforcement | Data |
| Production hook enable/apply is separate | Frozen | Source work does not authorize hosted Auth behavior change | Owner |

## 4. Architecture Design

### Chosen Approach

Add a narrow server-only RPC in `public` because the existing Edge Function can later call only exposed PostgREST RPC schemas. Revoke it from normal client roles and grant only trusted server roles. The RPC performs a single indexed verified-owner existence lookup using the existing canonical expression.

The RPC may use a tightly-scoped `SECURITY DEFINER` implementation so `supabase_auth_admin` does not receive broad table `SELECT` rights. It must contain only static read-only SQL and `SET search_path = ''`.

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

Database/server-only slice. Google conflict returns one controlled hook error and no second Auth UUID. Infrastructure/programmer errors must not silently create a second canonical verified owner; the existing verified-only UNIQUE index remains the final DB backstop.

## 5. Implementation Plan

- [x] Complete fresh source + live privilege audit.
- [x] Freeze enumeration-safe Google-vs-Email hook boundary.
- [ ] Add restricted verified canonical Email owner lookup migration source.
- [ ] Add private Google-scoped Before User Created hook migration source.
- [ ] Add focused SQL verification source.
- [ ] Review local `config.toml` hook wiring; do not imply hosted hook enable.
- [ ] Review diff and update #120 checkpoint.
- [ ] Run available validation; record any environment limitation exactly.

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

Production DDL/Auth-hook mutation from this task: NOT performed.
```

### Review Findings and Resolution

The initial idea of using one rejecting `Before User Created` hook for both Google and Email/password is unsafe for Email enumeration semantics. This task narrows the hook to Google, where provider verification already proves control of the Email identity, and leaves Email signup admission for a later dedicated #120 slice.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/auth-canonical-email-admission.md`

### Actual Behavior

No runtime behavior changed yet. Task boundary is frozen before source implementation.

### Known Limitations

- hosted Auth Hook remains disabled/unmodified by this task until separately approved;
- Google admission Edge Function still uses exact lowercased Email lookup;
- Email/password canonical alias admission remains later #120 work.

### Final Status

`PARTIAL` — task brief/audit complete; source implementation and validation pending.
