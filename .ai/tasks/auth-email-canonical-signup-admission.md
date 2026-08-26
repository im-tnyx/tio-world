# Auth Email Canonical Signup Admission

**Status:** In progress
**Primary owner:** `apps/features/auth` + Supabase Auth/Postgres
**Affected platforms:** Flutter Auth + hosted Supabase Auth
**Related issue:** #120
**Parent tracker:** #34
**Depends on:** #119 verified ownership, #121 canonical admission guard, #122 typed Google admission
**Working branch:** `agent/auth-email-canonical-signup`
**Draft PR:** #123

## 1. Discovery

### User Outcome

Make Email + Password Signup/Login use one provider-aware canonical Email identity rule while preserving Supabase's account-enumeration protections and preventing Gmail/Googlemail aliases from becoming separate canonical Tio identities.

### Success Criteria

- Gmail/Googlemail aliases collapse by trim/lowercase, `googlemail.com → gmail.com`, local `+tag` removal, and local dot removal.
- Non-Gmail dots and `+tag` semantics remain unchanged after trim/lowercase.
- Password stays inside direct Supabase Auth SDK calls.
- Email Signup never performs a client-visible canonical owner lookup before mailbox ownership is proven.
- fresh pending Signup and Supabase's obfuscated existing-account Signup produce the same neutral check-email product outcome.
- Email Login uses the same canonicalizer as Signup.
- Signup has a bounded timeout.
- hosted `Before User Created` protection enforces canonical form without turning account existence into an oracle.
- no new table, column, generated identity field, or contact table.

### Non-Goals

- Forgot/Reset Password;
- authenticated Change Password;
- Settings Email change/linking;
- Phone OTP / #118;
- Google Settings linking/unlinking;
- Auth UI redesign;
- PR Ready/merge.

## 2. Codebase / Runtime Evidence

Before this slice, Email Signup/Login only trimmed/lowercased Email and repository internals could expose `user_already_exists` from Supabase's obfuscated duplicate Signup response.

Chosen client boundary:

```text
raw Email
→ canonicalEmailIdentity()
→ direct supabase.auth.signUp / signInWithPassword
→ Supabase native exact-Email behavior
→ pending confirmation or authenticated session
```

Server backstop:

```text
provider=email
→ canonicalize submitted Email
→ already canonical? allow
→ noncanonical Gmail/Googlemail alias? generic reject
```

The hook does **not** query verified owner existence for Email/password Signup.

Hosted functions are live:

```text
private.before_user_created_canonical_email_guard(jsonb)
public.before_user_created_canonical_email_guard(jsonb)
```

The public function is a thin SECURITY INVOKER Dashboard wrapper delegating to the private policy owner. `anon`, `authenticated`, and `service_role` do not have wrapper EXECUTE; `supabase_auth_admin` does.

The hosted Supabase Dashboard was configured with:

```text
Before User Created
schema: public
function: before_user_created_canonical_email_guard
```

Post-save Auth logs showed an API configuration reload. The connector cannot read the selected hook name back directly, so a real Auth invocation remains the final execution proof.

## 3. Frozen Decisions

| Decision | Status | Rationale |
|---|---|---|
| Provider-aware Gmail canonicalization | Frozen | Gmail alias semantics differ from other domains |
| No universal `+tag` stripping | Frozen | Non-Gmail provider semantics vary |
| No client owner precheck | Frozen | Raw Email is not ownership proof and lookup would leak account existence |
| Password stays direct to Supabase Auth | Frozen | Avoid widening password handling |
| Pending confirmation is not authenticated success | Frozen | Session absence remains authoritative |
| Duplicate/pending Signup product outcome is neutral | Implemented | Preserve Supabase enumeration resistance |
| Hook enforces Email canonical form only | Implemented/live | Backstop old/malicious clients without owner-existence leakage |
| Public hook entrypoint is wrapper only | Implemented/live | Keep business logic private and Dashboard-selectable |

## 4. Architecture

Gmail/Googlemail:

```text
Na.Me+Fit@googlemail.com
→ name@gmail.com
```

Non-Gmail:

```text
User.Name+Fit@Example.com
→ user.name+fit@example.com
```

Product-facing Signup result:

```text
fresh Signup, session absent
             ┐
             ├→ email_confirmation_required
obfuscated duplicate Signup
             ┘
```

No UUID/owner metadata is returned to the client.

Hosted migration IDs owned by this PR:

```text
20260826114935 harden_email_signup_canonical_form
20260826121524 add_public_before_user_created_hook_wrapper
```

The full stacked Auth migration source now matches hosted migration history; no migration was replayed during source-history cleanup.

## 5. Implementation Plan

- [x] Add provider-aware Email canonicalization helper.
- [x] Use helper for Email Signup.
- [x] Use helper for Email Login.
- [x] Neutralize fresh-pending vs obfuscated-duplicate product result.
- [x] Add bounded Signup timeout.
- [x] Add focused Dart test source.
- [x] Harden private Email hook policy.
- [x] Add public Dashboard-selectable SECURITY INVOKER wrapper.
- [x] Apply and verify both hosted DB migrations after explicit approval.
- [x] Verify hosted Dashboard hook selection/save.
- [x] Align repository migration filenames with hosted migration IDs.
- [x] Reconcile #119 → #121 → #122 → #123 into a clean linear stack.
- [ ] Execute Flutter/Dart analyze/tests in a working Flutter toolchain.
- [ ] Run controlled real Email Signup + confirmation smoke.
- [ ] Run Gmail/Googlemail alias duplicate/canonical smoke.

## 6. Quality Review

Completed SQL/runtime evidence:

```text
private Email hook cases             6 / 6 PASS
public wrapper delegation            4 / 4 PASS
wrapper SECURITY DEFINER             false
supabase_auth_admin wrapper EXECUTE  true
anon wrapper EXECUTE                 false
authenticated wrapper EXECUTE        false
verified Email collision groups      0
Auth/public projection mismatches    0
```

Fresh post-branch-cleanup hosted read-only audit:

```text
auth.users                            0
public.users                          0
private hook exists                   true
public wrapper exists                 true
supabase_auth_admin wrapper EXECUTE  true
anon/authenticated wrapper EXECUTE    false
```

The current hosted project has no user fixtures. This is not a failure, but it means a real smoke test must create/use a controlled test identity rather than infer execution from existing accounts.

Git source-history reconciliation:

```text
#119 → #121  linear
#121 → #122  linear
#122 → #123  linear
```

No Core/Onboarding/Account Setup/Welcome UI file remains in the Auth stack. The unrelated UI state was preserved separately on `agent/ui-bottom-sheet-welcome-parity-preserve` before branch cleanup.

Executable Flutter validation is still unavailable in the current execution environment because `flutter`/`dart` are not installed and the stacked PRs do not trigger the repository's `pull_request -> main` workflow.

## 7. Final Handoff

### Changed Runtime/Source Files

- `apps/features/auth/lib/src/domain/domain.dart`
- `apps/features/auth/lib/src/domain/utils/canonical_email_identity.dart`
- `apps/features/auth/lib/src/domain/usecases/sign_up_with_email_use_case.dart`
- `apps/features/auth/lib/src/domain/usecases/sign_in_with_email_use_case.dart`
- focused Auth domain tests
- `supabase/migrations/20260826114935_harden_email_signup_canonical_form.sql`
- `supabase/migrations/20260826121524_add_public_before_user_created_hook_wrapper.sql`
- focused verification SQL

### Remaining Gate

```text
controlled Email Signup
→ confirm mailbox
→ verify one Auth/public UUID projection
→ attempt equivalent Gmail alias
→ verify no second canonical account
→ inspect Auth logs + DB invariants
```

### Final Status

`PARTIAL` — source implementation, production DB migrations, Dashboard hook activation, ACL checks, migration-history reconciliation, and branch-stack cleanup are complete. Executable Flutter validation and controlled real Auth smoke remain pending. PR #123 stays Draft/unmerged.