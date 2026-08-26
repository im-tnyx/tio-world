# Auth Google Canonical Admission

**Status:** In progress
**Primary owner:** `supabase/functions/google-login-admission`, `supabase/migrations`, `apps/features/auth`
**Affected platforms:** Supabase Edge Function/Postgres + Flutter Auth data flow
**Related issue:** #120
**Parent tracker:** #34
**Depends on:** PR #121 canonical Email admission guard source
**Working branch:** `agent/auth-google-canonical-admission`
**Draft PR:** #122

## 1. Discovery

### User Outcome

Make Google Login/Signup resolve against Tio's canonical verified Email ownership rule without creating a second UUID, without treating a pending Email as ownership, and without turning normal Google Login into an implicit account-linking operation.

### Success Criteria

- Google token verification remains server-owned and requires stable Google subject (`sub`) plus verified Email.
- Existing-account Google Login succeeds when the stable Google subject is already attached to the canonical Tio identity and is not in conflict with another verified Email owner.
- A verified canonical Email owner with an unlinked Google identity is a controlled `link_required` state, not automatic Login/linking.
- A canonical Gmail/Googlemail alias collision does not intentionally reach a second Auth UUID creation path.
- A linked Google subject may continue signing into its existing UUID if the provider's current verified Email changes to an otherwise-unowned canonical Email; Auth reconciliation and verified-only uniqueness remain the final ownership backstop.
- No owner UUID or arbitrary account lookup is exposed to normal clients.
- No new table or column is introduced.
- Production migration, Edge Function deployment, and hosted Auth Hook activation remain separately authorized.

### Scope

- update `google-login-admission` to use a typed server-only identity/admission resolver;
- add only the minimum DB function needed to compare canonical verified owner and linked Google provider subject;
- update Flutter admission result typing/gating required for the new server decision;
- close the native-ID-token-unavailable OAuth admission bypass;
- keep local Edge Function JWT configuration aligned with the deployed custom-auth boundary;
- add focused resolver and Google-flow tests.

### Non-Goals

- Google identity linking implementation from Settings;
- unlinking;
- Email Signup canonical admission;
- Phone OTP / #118;
- password recovery/change-password;
- UI redesign;
- new identity/contact table or column;
- merging PR #122/#121/#119/#50.

## 2. Codebase Exploration

### Verified Evidence

The previously deployed `google-login-admission` v1 and pre-slice repository source both used:

```text
Google ID token
→ verify RS256 signature + kid/JWKS
→ verify audience + issuer + expiry
→ require email_verified = true + non-empty Email
→ exact lower(trim(email)) lookup in public.users
→ { allowed: bool }
```

Pre-slice gaps:

- token payload handling did not require/consume Google `sub`;
- account lookup did not require `public.users.email_verified_at IS NOT NULL`;
- Gmail/Googlemail aliases were not canonicalized;
- a pending/unverified public Email could look like an existing account;
- boolean response could not distinguish linked identity vs canonical owner with unlinked Google;
- `signupOrExisting` classified only in the background and did not gate `signInWithIdToken()`;
- missing native ID token used a signup-capable `signInWithOAuth()` fallback that bypassed Tio admission;
- deployed Edge Function had `verify_jwt=false`, but repo `supabase/config.toml` did not explicitly track that local/deployment parity.

Fresh live aggregate Auth audit before implementation:

```text
auth.users                               2
auth.identities                          2
Google identities                        2
Email identities                         0
users with multiple identities           0
users with multiple providers            0
verified public Email owners             2
verified owners with Google identity     2
verified owners without Google identity  0
Google identity missing public root      0
Google identity canonical mismatch       0
Google provider_id == identity_data.sub  2 / 2
```

`auth.identities` has a UNIQUE index on `(provider_id, provider)` and an index on `user_id`, so provider-subject resolution has an indexed lookup path.

Supabase Auth current documented identity behavior:

- OAuth identities with the same exact Email may be automatically linked to an existing user;
- manual/native linking has separate `linkIdentity` / `linkIdentityWithIdToken` APIs;
- publishable/secret key Edge Function flows that implement their own authentication should use `verify_jwt=false` and authenticate in the handler.

Parent #34 freezes `auth.users.id` as canonical identity and keeps Google connection/linking distinct from normal Login.

### Existing Pattern to Follow

- Edge Function verifies Google identity itself because `verify_jwt=false` is intentional for this external-provider token endpoint.
- New Supabase `sb_secret_*` keys are sent to Data API using only `apikey`; `adminApiKey()` supports `SUPABASE_SECRET_KEYS` and legacy service-role fallback.
- trusted DB RPCs use static SQL, `SET search_path = ''`, no owner UUID exposure, and revoke normal client execution.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Canonical owner existence alone is enough for new-user collision backstop | Frozen | PR #121 hook only needs to prevent a second UUID | Auth/Data |
| Canonical owner existence alone is NOT enough for returning Google Login | Frozen | It cannot distinguish linked Google identity from another sign-in method on the same account | Auth/Security |
| Normal Google Login must not silently become Settings identity linking | Frozen | Keeps login/account-linking boundaries explicit | #34 |
| Google provider subject (`sub`) participates in admission | Implemented | Stable provider identity maps to `auth.identities.provider_id` | Auth/Security |
| Already-linked Google subject remains sign-in authority if current provider Email changes and is otherwise unowned | Implemented refinement | `auth.users.id`/linked provider identity is canonical authority; avoid lockout from provider Email changes while still blocking ownership conflicts | Auth/Security |
| Edge response is typed instead of boolean-only | Implemented | Client distinguishes linked, unowned, link-required, conflict | Auth |
| OAuth fallback without native ID token cannot bypass admission | Implemented | Prevents Auth auto-link/create before Tio can classify identity | Auth/Security |
| Local function config explicitly uses `verify_jwt=false` | Implemented | Matches deployed custom Google-token verification boundary and current Supabase key guidance | Auth/Platform |

## 4. Architecture Design

### Chosen Approach

PR #121 keeps `verified_email_owner_exists(text)` for the Before User Created collision guard. Phase 3 adds a separate restricted resolver for Google Login/Signup that consumes both verified Google Email and stable Google subject.

```text
resolve_google_login_admission(raw_email, google_subject)
→ canonical verified Email owner lookup
→ Google auth.identities(provider='google', provider_id=google_subject) lookup
→ verify linked identity still has public.users root
→ compare UUID ownership internally
→ return decision only, never UUID
```

Typed states:

```text
linked_account
  Google subject is already linked to a valid Tio UUID, and the token's current
  canonical Email is either unowned or owned by that same UUID.

no_account
  no linked Google subject and no verified canonical Email owner.

link_required
  verified canonical Email owner exists, but this Google subject is not linked.

identity_conflict
  Google subject has no public root, or it is linked to one UUID while the
  token's current verified canonical Email is owned by another UUID.
```

Flutter gating:

```text
existingAccountOnly
  linked_account    → allow signInWithIdToken
  no_account        → google_account_not_found
  link_required     → google_account_link_required
  identity_conflict → google_identity_conflict

signupOrExisting
  linked_account    → allow signInWithIdToken
  no_account        → allow signInWithIdToken
  link_required     → block before exchange
  identity_conflict → block before exchange
```

If native Google ID token is missing, both intents now fail closed with `google_login_admission_token_unavailable`; the old OAuth fallback is not used.

Local config explicitly tracks:

```toml
[functions.google-login-admission]
verify_jwt = false
```

The function remains responsible for cryptographically verifying the supplied Google ID token before any account decision is returned.

### Ownership and Data Flow

```text
Google native ID token
→ google-login-admission
→ verified signature/aud/iss/exp/email_verified/sub
→ service-role-only resolve_google_login_admission()
   ├─ public.users verified canonical Email owner
   └─ auth.identities Google provider subject
→ typed decision
→ Flutter repository gates Supabase exchange
→ PR #121 Before User Created hook remains new-user alias backstop when deployed
→ live verified-only DB UNIQUE index remains final Email ownership backstop
```

### Alternative Rejected

- Do not just replace exact Email REST filtering with a canonical boolean lookup.
- Do not query `auth.identities` directly through exposed Data API tables.
- Do not return owner UUID to Edge/client.
- Do not use Supabase exact-Email automatic linking as the normal Tio Login contract.
- Do not block an already-linked Google subject solely because the provider Email changed to an otherwise-unowned address.
- Do not allow OAuth fallback to bypass provider-subject admission.
- Do not rely on undocumented/manual deploy flags for `verify_jwt`; keep repo config aligned with the intended endpoint auth model.

### Failure and Security States

- Invalid/missing Google `sub` is an admission infrastructure/token failure.
- infrastructure/RPC failure remains retryable and is not mapped to `no_account`.
- `identity_conflict` fails closed and never switches UUIDs.
- `link_required` is neither duplicate-account creation nor automatic merge; explicit linking remains a future Settings workflow.
- no raw Email, Google subject, UUID, token, or account metadata is returned from the admission endpoint.
- `verify_jwt=false` does not make the handler unauthenticated logically; Google JWT verification is the endpoint's explicit caller identity proof.

## 5. Implementation Plan

- [x] Fresh deployed Edge Function/source audit.
- [x] Fresh Flutter ordering/test audit.
- [x] Fresh live aggregate `auth.identities` audit.
- [x] Review current Supabase automatic/manual identity-linking semantics.
- [x] Freeze typed linked-vs-owner decision boundary.
- [x] Add restricted Google admission resolver migration source.
- [x] Extend Edge token validation to require `sub`.
- [x] Replace exact public.users lookup with typed resolver call.
- [x] Replace boolean Edge response/client enum with typed decisions.
- [x] Gate `signupOrExisting` before `signInWithIdToken()`.
- [x] Remove/fail-closed the native-ID-token-unavailable OAuth admission bypass.
- [x] Track `google-login-admission` `verify_jwt=false` in source config.
- [x] Add focused resolver/Flutter test source.
- [ ] Execute Flutter analyze/tests in an environment with Flutter/Dart toolchain.
- [ ] Execute migration + verification script on an approved non-production or production target.
- [x] Review Draft PR #122 source diff and deployment boundaries.
- [x] Record #120 source checkpoint.
- [ ] Production DB/function deployment only after separate explicit approval.

## 6. Quality Review

### Validation Run

```text
Fresh live read-only equivalent resolver audit:
- scenarios checked: 5
- linked_account cases: PASS
- no_account: PASS
- link_required: PASS
- identity_conflict: PASS
- all matched: true

Fresh hosted deployment-state check:
- live verified Email UNIQUE index: present
- auth.identities(provider_id, provider) UNIQUE index: present
- PR #121 owner helper live: false
- PR #121 Google hook live: false
- Phase 3 Google resolver live: false

Source tests added/updated:
- supabase/drafts/20260826_verify_google_canonical_admission.sql
- apps/features/auth/test/data/supabase_auth_sign_in_repository_test.dart
- apps/features/auth/test/data/google_profile_bootstrap_test.dart

Draft PR #122:
- base: agent/auth-canonical-email-admission
- branch compare: behind 0
- auto Flutter CI runs: none, expected because current pull_request workflow targets main only

Flutter/Dart execution: NOT RUN in current execution environment because no Flutter/Dart toolchain is available. A network clone fallback was also unavailable. Do not treat test source as passed runtime validation.
Production DDL/DML/Edge deployment: NOT performed.
```

### Review Findings and Resolution

1. A canonical-owner boolean is insufficient because it mixes account existence with Google linkage. Resolved with typed provider-subject resolver.
2. The first resolver draft treated `Google subject already linked + current token Email unowned` as conflict. That would make a stable linked provider identity depend on a possibly changed provider Email and could lock out the canonical UUID. Corrected: an existing linked subject with a valid `public.users` root is `linked_account` when current canonical Email is unowned or owned by the same UUID; only ownership by another UUID is a conflict.
3. The old signup-capable OAuth fallback could bypass Tio admission. Removed from this bounded source slice.
4. Source config did not record the deployed `verify_jwt=false` behavior. Corrected with `[functions.google-login-admission] verify_jwt = false`, while retaining mandatory Google token verification inside the handler.
5. Production ordering remains important: PR #121 hosted helper/hook is not yet live. Phase 3 must not be described as fully runtime-validated or deployed until the prerequisite/runtime decisions are executed.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/auth-google-canonical-admission.md`
- `apps/features/auth/lib/src/data/google_login_admission_checker.dart`
- `apps/features/auth/lib/src/data/repositories/supabase_auth_sign_in_repository.dart`
- `apps/features/auth/test/data/google_profile_bootstrap_test.dart`
- `apps/features/auth/test/data/supabase_auth_sign_in_repository_test.dart`
- `supabase/config.toml`
- `supabase/drafts/20260826_verify_google_canonical_admission.sql`
- `supabase/functions/google-login-admission/index.ts`
- `supabase/migrations/20260826110000_add_google_canonical_admission_resolver.sql`

### Actual Source Behavior

- Google admission is typed by canonical verified Email ownership + stable provider subject linkage.
- Both returning Login and signup-capable Google flows await admission before Supabase ID-token exchange.
- `link_required` and `identity_conflict` block before exchange.
- missing native ID token fails closed instead of invoking signup-capable OAuth fallback.
- first-account Google photo import remains limited to `no_account`; already-linked account sign-in never imports the provider photo.
- local Supabase config now matches the endpoint's deployed custom-auth `verify_jwt=false` model.

### Known Limitations

- Flutter/Dart tests have been updated but not executed in the current environment.
- PR #121 helper/hook is still unapplied to hosted Supabase.
- Phase 3 resolver migration and updated Edge Function are not deployed.
- Settings Google linking is not implemented, so `link_required` currently directs the user back to an existing sign-in method rather than linking automatically.
- Email Signup canonical admission remains later #120 work.

### Final Status

`PARTIAL` — Phase 3 source implementation, security/diff review, and read-only resolver logic validation are complete. Executable Flutter validation and hosted runtime deployment remain pending. Draft PR #122 must remain Draft until those gates are resolved.
