# Auth Email Canonical Signup Admission

**Status:** In progress
**Primary owner:** `apps/features/auth` + Supabase Auth admission boundary
**Affected platforms:** Flutter Auth + Supabase Auth/Postgres
**Related issue:** #120
**Parent tracker:** #34
**Depends on:** PR #122 Google canonical admission source; live canonical Email ownership foundation
**Working branch:** `agent/auth-email-canonical-signup`

## 1. Discovery

### User Outcome

Make Email + Password Signup resolve Gmail/Googlemail aliases to one canonical Supabase/Tio identity without exposing whether an existing canonical account exists, without passing the user's password through a custom Tio server, and without creating new tables or columns.

### Success Criteria

- Gmail dot / `+tag` / `googlemail.com` aliases resolve to the same Auth Email identity before `auth.signUp`.
- Non-Gmail `+tag` and dots are preserved.
- Password continues directly from Flutter to Supabase Auth.
- Supabase duplicate-Signup obfuscation is not decoded into an explicit account-existence result.
- `user != null && session == null` remains pending confirmation, never authenticated success.
- Email Signup is bounded by timeout.
- Email Login accepts the same canonical Gmail aliases used by Signup.
- Existing verified-only canonical Email uniqueness remains the final ownership backstop.
- No new table/column/generated identity field.
- Hosted Before User Created hook activation is never claimed until independently verified.

### Scope

- provider-aware canonical Email helper;
- Email Signup and Email Login input canonicalization;
- neutral Signup duplicate/pending response;
- Signup timeout;
- focused domain tests;
- server hook source that enforces canonical form without owner lookup;
- a dashboard-selectable public Auth Hook wrapper that delegates to the private implementation with restricted EXECUTE ACL.

### Non-Goals

- password policy redesign;
- Forgot/Reset Password;
- Settings Email change/linking;
- Phone OTP / #118;
- UI redesign;
- Google Settings linking;
- new identity/contact tables or columns;
- PR Ready/merge.

## 2. Codebase Exploration

### Verified Evidence

Before this slice:

```text
SignUpWithEmailUseCase
→ repository.signUpWithEmailPassword
→ trim + lowercase only
→ Supabase auth.signUp
```

The repository treated `user.identities.isEmpty` and duplicate AuthException text as `user_already_exists`. The Signup page rendered that failure directly and exposed a Log In action. Supabase documentation states existing-account Signup may intentionally return an obfuscated response to prevent user enumeration, including Email Signup after an OAuth account with the same Email. Therefore decoding that response was unsafe.

Existing pending-confirmation behavior was correct:

```text
user created + session == null
→ email_confirmation_required
→ no device sync
→ no authenticated onboarding success
```

Email Signup had no bounded timeout. Email Login only trimmed input, so canonical Signup storage without Login canonicalization would make Gmail alias Login inconsistent.

Fresh hosted read-only audit before production apply:

```text
auth users                              2
confirmed Auth Email users              2
unconfirmed Auth Email users            0
Email provider identities               0
Google identities                       2
Auth Emails needing Gmail rewrite       0
verified public Emails needing rewrite  0
pending public Email rows               0
verified canonical collision groups     0
Auth/public projection mismatches       0
```

No existing hosted row needed a canonical Email rewrite.

The hosted Dashboard Auth Hook picker did not list the valid `private.before_user_created_canonical_email_guard(jsonb)` function even though Postgres confirmed the function signature and `supabase_auth_admin` privileges were correct. The public-schema picker path is therefore supported through a thin wrapper that delegates to the private implementation.

### Existing Pattern to Follow

- Password stays inside Supabase Auth SDK calls.
- Reuse the frozen provider-aware rule implemented by `private.canonical_email_identity(text)`.
- No client-visible canonical owner precheck before Email ownership is proven.
- Verified-only canonical Email UNIQUE ownership remains the final trusted DB authority.
- Keep business/policy logic in `private.before_user_created_canonical_email_guard(jsonb)`.
- The public Auth Hook entrypoint is a SECURITY INVOKER wrapper only; it is not a second policy implementation.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| No canonical owner precheck from Flutter Signup | Frozen | Raw Email is not ownership proof and lookup would become an enumeration oracle |
| No custom Tio Signup endpoint carrying plaintext password | Frozen | Supabase Auth remains password owner |
| Canonicalize Gmail aliases before direct `auth.signUp()` | Implemented | Converts provider-equivalent aliases to Supabase exact Email identity while preserving native duplicate behavior |
| Canonicalize Email Login with same rule | Implemented | Avoids alias-login regression |
| Do not expose `user_already_exists` from obfuscated Signup response | Implemented at product-facing use-case boundary | Preserves account-enumeration-safe behavior |
| Keep session-absent Signup distinct from authenticated success | Frozen | Existing semantics correct |
| Email server hook may enforce canonical form only, never owner existence | Implemented and live in Postgres | Closes old/malicious client alias bypass without exposing account existence once the hosted hook is active |
| Use a public dashboard wrapper instead of moving private policy logic | Implemented and live | Studio did not list the private function; thin invoker delegation keeps one policy owner and restricts normal-client EXECUTE |

## 4. Architecture Design

### Chosen Approach

```text
raw Email
→ canonicalEmailIdentity()
→ direct Supabase auth.signUp / signInWithPassword
→ Supabase exact Email uniqueness + native duplicate obfuscation
→ pending confirmation or authenticated session
```

Gmail / Googlemail:

```text
trim + lowercase
→ googlemail.com → gmail.com
→ strip local +tag
→ remove local dots
```

Other domains:

```text
trim + lowercase
→ preserve local dots
→ preserve +tag
```

Signup product outcome:

```text
fresh Signup, session absent
             ┐
             ├→ same neutral check-email result
obfuscated existing-account Signup
             ┘
```

No UUID or owner lookup is exposed.

### Server Backstop

The production hook implementation makes `provider=email` only check whether the submitted Email is already in canonical form. It never calls `verified_email_owner_exists` for Email/password Signup.

```text
provider=email
→ canonicalize input
→ canonical form? allow
→ Gmail alias/noncanonical form? generic reject
```

This decision is independent of account existence. Google behavior remains unchanged and may use verified-owner existence because Google provider evidence has already proved Email ownership.

Core private hook migration:

```text
20260826114935 harden_email_signup_canonical_form
```

Hosted Dashboard compatibility wrapper:

```text
public.before_user_created_canonical_email_guard(event jsonb)
→ private.before_user_created_canonical_email_guard(event)
```

The wrapper is SECURITY INVOKER, has `search_path = ''`, and is executable by `supabase_auth_admin` only. `anon`, `authenticated`, and `service_role` cannot execute it.

Live wrapper migration record:

```text
20260826121524 add_public_before_user_created_hook_wrapper
```

### Alternatives Rejected

- raw owner-existence RPC from Signup client;
- custom password Signup Edge Function;
- universal plus/dot stripping;
- relying only on verified public index while allowing avoidable alias Auth UUID creation;
- exposing `user_already_exists` from `identities.isEmpty`;
- duplicating hook policy in a second public implementation;
- widening wrapper EXECUTE to normal Data API roles.

## 5. Implementation Plan

- [x] Fresh repository/use-case/UI audit.
- [x] Fresh hosted canonical-state audit.
- [x] Review Supabase duplicate Signup / enumeration semantics.
- [x] Add pure provider-aware Email canonicalization helper.
- [x] Use helper for Email Signup.
- [x] Use helper for Email Login.
- [x] Map pending confirmation and `user_already_exists` to the same product-facing neutral result.
- [x] Add bounded Email Signup timeout.
- [x] Add focused canonicalizer/use-case tests.
- [x] Add Email hook canonical-form enforcement source.
- [x] Add focused SQL verification draft.
- [x] Read-only equivalent server-rule validation: 6/6 cases matched.
- [x] Apply production hook-function migration after explicit owner authorization.
- [x] Post-apply function behavior/ACL verification: 6/6 cases matched, restricted execute privileges preserved.
- [x] Add dashboard-selectable public SECURITY INVOKER wrapper source.
- [x] Apply wrapper migration after explicit owner authorization.
- [x] Verify wrapper delegation and ACL: 4/4 focused cases matched; only `supabase_auth_admin` has EXECUTE.
- [ ] Execute Flutter analyze/tests in a Flutter/Dart-capable environment.
- [x] Verify the hosted Before User Created hook is enabled with
  `public.before_user_created_canonical_email_guard` in Supabase Dashboard.
- [ ] Real Email Signup/confirmation smoke on a controlled test identity.

## 6. Quality Review

### Validation Run

```text
Hosted pre-apply data audit                  PASS
Equivalent Email hook rule cases             6 / 6 PASS
Private hook migration                       20260826114935 LIVE
Post-apply private hook cases                6 / 6 PASS
Public wrapper migration                     20260826121524 LIVE
Public wrapper delegation cases              4 / 4 PASS
Wrapper SECURITY DEFINER                     false
Wrapper EXECUTE: supabase_auth_admin         true
Wrapper EXECUTE: anon/authenticated/service  false
Verified Email collision groups              0
Auth/public projection mismatches             0
Branch base                                  PR #122 head
Flutter/Dart executable validation           NOT RUN
Hosted Before User Created hook activation   VERIFIED (Chrome Dashboard)
```

### Review Findings and Resolution

1. Existing exact-Email duplicate inference defeats Supabase obfuscation. Product-facing `SignUpWithEmailUseCase` maps pending and duplicate codes to the same neutral outcome.
2. Signup-only canonicalization would make alias Login inconsistent. `SignInWithEmailUseCase` uses the same canonical identity helper.
3. Client owner precheck is unsafe before Email proof. Not introduced.
4. Password proxying would widen secret handling. Not introduced.
5. Old/malicious clients could still submit Gmail aliases unless the hosted Before User Created hook is active. The policy function and dashboard-selectable wrapper are live, and Dashboard now confirms the public wrapper is enabled.
6. The Dashboard picker did not surface the private function. A public SECURITY INVOKER wrapper was added instead of moving or duplicating private business logic.
7. Settings/contact verification still uses lower/trim-only normalization and remains a separate #34/#8 lane.
8. Post-DDL Supabase security advisor warnings are pre-existing/unrelated. The new wrapper is not SECURITY DEFINER and is not executable by normal client roles.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/auth-email-canonical-signup-admission.md`
- `apps/features/auth/lib/src/domain/domain.dart`
- `apps/features/auth/lib/src/domain/utils/canonical_email_identity.dart`
- `apps/features/auth/lib/src/domain/usecases/sign_up_with_email_use_case.dart`
- `apps/features/auth/lib/src/domain/usecases/sign_in_with_email_use_case.dart`
- `apps/features/auth/test/domain/canonical_email_identity_test.dart`
- `apps/features/auth/test/domain/email_auth_canonicalization_use_case_test.dart`
- `supabase/migrations/20260826114935_harden_email_signup_canonical_form.sql`
- `supabase/migrations/20260826121524_add_public_before_user_created_hook_wrapper.sql`
- `supabase/drafts/20260826_verify_email_signup_canonical_form.sql`

### Actual Behavior

- Official Email Signup/Login inputs canonicalize Gmail/Googlemail aliases provider-aware.
- Non-Gmail plus/dot semantics remain unchanged.
- Password remains direct to Supabase Auth.
- Product-facing Signup no longer distinguishes a fresh pending confirmation from repository `user_already_exists`.
- Signup timeout returns `email_signup_timeout`.
- The private production hook enforces Email canonical form without querying owner existence.
- A public dashboard-selectable wrapper delegates to the private hook and is callable only by `supabase_auth_admin`.

### Known Limitations

- Existing repository internals still produce `user_already_exists`; the normal product path is protected by `SignUpWithEmailUseCase`. Direct repository consumers must not be added as UI/business entry points.
- Flutter/Dart tests are source-only until run in a toolchain-capable environment.
- No controlled real Email Signup/confirmation identity has been mutated for smoke testing yet.

### Final Status

`PARTIAL` — Phase 4 source, private hook migration, and dashboard-selectable wrapper are live with clean ACL/behavior validation. Hosted hook activation, executable Flutter validation, and controlled real Auth smoke remain pending.
