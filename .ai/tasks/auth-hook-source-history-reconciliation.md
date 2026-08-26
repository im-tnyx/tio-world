# Auth Hook Source-History Reconciliation

**Status:** Validated
**Primary owner:** `supabase/*` migration history and stacked Auth admission PRs
**Affected platforms:** Hosted Supabase Auth/Postgres; repository migration source
**Related trackers:** #34, #120

## 1. Discovery

### User Outcome

Keep the already-live hosted Auth admission migrations and enabled `Before User Created` hook reproducible from one clean stacked Git history without replaying production SQL or mixing unrelated UI work into Auth PRs.

### Success Criteria

- repository migration filenames match the IDs recorded by the hosted project;
- each migration remains owned by the bounded PR that introduced its behavior;
- the hosted Dashboard binding remains `public.before_user_created_canonical_email_guard`;
- no migration is replayed and no production user/Auth data changes during source-history cleanup;
- #119 → #121 → #122 → #123 is linear with no branch drift;
- unrelated Core/Onboarding/Welcome UI commits are preserved outside the Auth stack.

## 2. Verified Evidence

Hosted migration IDs for this Auth lane are:

```text
20260826102110 add_canonical_email_identity_function
20260826102133 enforce_verified_identifier_ownership
20260826112650 add_canonical_email_admission_guard
20260826112754 add_google_canonical_admission_resolver
20260826114935 harden_email_signup_canonical_form
20260826121524 add_public_before_user_created_hook_wrapper
```

Dashboard verification showed an enabled `Before User Created` Postgres hook using:

```text
schema:   public
function: before_user_created_canonical_email_guard
```

The public wrapper delegates to `private.before_user_created_canonical_email_guard(event)`. Normal client roles do not have wrapper EXECUTE; `supabase_auth_admin` does.

A later local push had placed Auth migration-history reconciliation plus unrelated Core/Onboarding/Welcome UI commits on `agent/auth-canonical-email-admission`, causing #122 to diverge from #121. The UI state was preserved first on:

```text
agent/ui-bottom-sheet-welcome-parity-preserve
```

No UI commit was discarded during Auth branch cleanup.

## 3. Chosen Reconciliation

Migration ownership is distributed through the existing bounded stack instead of consolidating future-phase migration files into #121:

```text
#119
  20260826102110
  20260826102133
    ↓
#121
  20260826112650
    ↓
#122
  20260826112754
    ↓
#123
  20260826114935
  20260826121524
```

SQL content was retained while source filenames were aligned to the hosted IDs. Production migrations were not replayed.

## 4. Branch Reconciliation Result

Current source checkpoints after cleanup:

```text
#119  agent/auth-verified-identifier-ownership
      48e6eb1efed091c2249afbcd9abec523eddedfbd

#121  agent/auth-canonical-email-admission
      4ccb04821cec99c0b029f5ebe8f206b9512ba8c0

#122  agent/auth-google-canonical-admission
      0a7eef5a81fd75dbb544d63736e260f8e27e9209

#123  agent/auth-email-canonical-signup
      source-history cleanup parent: 0a7eef5a81fd75dbb544d63736e260f8e27e9209
```

After rebuilding the stacked heads, GitHub comparison reported:

```text
#119 → #121  ahead 1 / behind 0
#121 → #122  ahead 1 / behind 0
#122 → #123  ahead 1 / behind 0
```

Bounded changed-file audits:

```text
#121  4 files, Auth/Supabase only
#122  9 files, Auth/Supabase only
#123  Auth domain/tests + Phase 4 migrations/tasks only
```

No Core, Product Onboarding, Account Setup UI, or Welcome UI file remains in #121/#122/#123.

## 5. Production Safety Review

This reconciliation changed Git history/source filenames only. It did **not**:

- apply a Supabase migration;
- update the hosted Auth Hook setting;
- deploy an Edge Function;
- create, modify, merge, or delete an Auth identity;
- change RLS/ACL in production;
- mark any PR Ready or merge any PR.

Fresh read-only hosted state during the audit showed the hook functions/wrapper still present with restricted execution. The project currently has no Auth/public user rows, so the next real runtime validation must use a controlled test identity rather than infer success from existing fixtures.

## 6. Remaining Validation

- [ ] executable Flutter/Dart validation for #122/#123 in a working Flutter toolchain;
- [ ] controlled real Email Signup + confirmation smoke;
- [ ] Gmail alias duplicate/canonical smoke;
- [ ] controlled Google admission smoke when suitable test identities are available.

## 7. Final Status

`PASS` — migration source IDs and bounded PR ownership are reconciled, the Auth stack is linear again, unrelated UI work is preserved outside the stack, and no production mutation was performed by this cleanup.