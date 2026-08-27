# Account Setup Complementary Email

**Status:** Source hardening complete; executable validation and hosted Email redirect retest pending  
**Primary owner:** `apps/features/account_setup` with Auth/Settings app composition through `apps/app`  
**Affected platforms:** Flutter mobile

## Global UI / Design-System Guardrail

This slice follows `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md`. It preserves the existing Account Setup and Account Settings visual language. No unrelated redesign is authorized.

## 1. Discovery

### User Outcome

Complete the Account Setup part of #118 so the flow asks only for the contact method that is complementary to the trusted authenticated identity, and make the resulting Auth state truthful end-to-end.

```text
trusted Email / Google identity
→ Username
→ Mobile optional

trusted Phone identity
→ Username
→ Email optional
```

### Runtime Findings Added After Device Smoke

Two defects were reproduced after real hosted Phone OTP testing and are now part of this task rather than deferred follow-up work.

1. **Email confirmation redirect defect**
   - Phone signup and optional Email request succeeded.
   - Supabase sent the Email change confirmation message and accepted the first confirmation click.
   - After verification, the browser was redirected to `localhost:3000`, producing `ERR_CONNECTION_REFUSED` on the mobile device.
   - Read-only hosted Auth evidence confirmed the Email itself became verified, so the defect was the post-confirmation redirect rather than ownership verification.

2. **False Google Connected state in Account Settings**
   - A Phone-created account with a later Email identity showed `Google / Connected` in Account Settings.
   - Read-only Supabase identity evidence for the account contained `phone` and `email`, with no `google` identity.
   - Root cause: the Settings widget had a hardcoded Google fallback and the production route did not supply provider-truth evidence.

No private identifier is recorded in this task file.

### Success Criteria

- trusted Email + no trusted Phone plans optional Mobile;
- trusted Phone + no trusted Email plans optional Email;
- both trusted identities require no complementary contact step;
- optional Email can be left blank and Account Setup completes;
- entered Email delegates to Auth-owned Supabase Email add/change + confirmation semantics;
- Email confirmation requests explicitly use the mobile callback `tio://login-callback` instead of relying on the localhost Site URL;
- the mobile callback is represented in repo Supabase redirect configuration;
- Account Settings derives linked provider labels from trusted Supabase Auth provider metadata, not Email presence, profile metadata, or a hardcoded Google label;
- a Phone + Email account must not display Google Connected unless Supabase actually reports a Google identity;
- no Flutter code writes Email verification timestamps;
- canonical authenticated UUID is unchanged;
- no schema, migration, hook, or Edge Function change is required for these fixes;
- PR remains Draft until executable validation and hosted Email redirect retest pass.

### Scope

- Account Setup step model/planner;
- Account Setup Email step presentation and focused validation;
- app composition from trusted Auth session evidence;
- Account Setup completion-marker semantics needed to distinguish completed setup from merely verified Mobile;
- Auth-owned Email confirmation redirect hardening;
- trusted Auth provider identity projection into `AuthSession`;
- bounded Account Settings provider-truth correction;
- local/repo Supabase redirect allow-list source configuration;
- focused planner/presentation/bridge/Auth/Settings regression tests;
- Issue #130 under parent #118 and Draft PR #131.

### Non-Goals

- Phone OTP capability or Phone-first Login/Signup UI;
- password creation/reset/change;
- Google linking/unlinking behavior;
- Account Settings contact redesign;
- Product Onboarding changes;
- schema or production data mutation;
- marking any stacked PR Ready or merging it;
- claiming hosted Email redirect acceptance before a real device retest.

## 2. Verified Evidence

- Account Setup planner and optional Email behavior were already implemented on the clean #129 child branch.
- Real hosted Phone OTP device smoke passed: SMS request, OTP verification, Supabase session, confirmed Phone and matching projected user state were observed.
- Hosted Auth logs showed Email-change mail delivery and successful verification, followed by localhost redirect behavior.
- Read-only Auth state confirmed the target Email became verified even though the browser landed on localhost.
- Read-only Supabase provider evidence for the Phone-created account reported `phone` + `email` and no `google` identity.
- Android already declares the app deep link `tio://login-callback` in `AndroidManifest.xml`.
- The Supabase Dart Auth API used by this repo supports `emailRedirectTo` for `updateUser` and `resend`.
- Current connector access does not expose hosted Auth URL Configuration mutation, so hosted redirect allow-list acceptance must be verified separately before runtime closure.

## 3. Architecture Decisions

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Trusted Email / Phone source | Made | Use Auth confirmation evidence, not non-empty contact strings | Auth boundary |
| Linked provider truth source | Made | Use normalized Supabase `app_metadata.provider/providers` projected into `AuthSession.identityProviders` | Auth boundary |
| Settings provider display | Made | App composition passes a label derived from `AuthSession.identityProviders`; no inference from Email/Profile data | App shell / Settings |
| Email callback | Made | Explicitly pass `tio://login-callback` to Auth Email update/resend operations | Auth boundary |
| Hosted redirect acceptance | Pending retest | Repo allow-list source includes callback, but hosted Dashboard config cannot be mutated/read by the current connector | Supabase hosted config |
| Cross-feature dependency | Made | Account Setup remains free of direct Auth SDK/provider imports; app composition bridges bounded features | App composition |
| Pending optional Email | Made | Request Auth confirmation first, then Account Setup may complete while Email remains pending | Auth + Account Setup |
| Completion meaning | Made | `account_setup_completed_at` remains the durable setup acknowledgement | Profile persistence |

## 4. Data Flow

```text
Phone OTP authenticated Supabase user
→ AuthSession
   ├─ verified Email/Phone evidence
   └─ identityProviders from Supabase Auth app metadata
→ Account Setup planner
→ optional Email
   ├─ blank → complete setup
   └─ entered
      → Supabase Auth updateUser(email, emailRedirectTo: tio://login-callback)
      → confirmation Email
      → Supabase verifies ownership
      → mobile callback opens Tio app

Account Settings
→ AuthSession.identityProviders
→ Phone / Email / Google labels only when actually reported by Supabase Auth
```

## 5. Implementation Checklist

### Original complementary-contact slice

- [x] add `email` Account Setup step ID and complementary-contact planner matrix;
- [x] add optional Email step UI using existing Tio design-system primitives;
- [x] extend `AccountSetupFlowPage` with Email state, validation, skip, and Auth request-before-completion behavior;
- [x] add `AccountSetupAuthContactBridge` and compose it at app level;
- [x] make `account_setup_completed_at` the explicit durable completion signal;
- [x] add focused planner, Email presentation, and bridge tests.

### Runtime hardening added from device testing

- [x] pass `tio://login-callback` as `emailRedirectTo` for Email add/change requests;
- [x] pass the same callback when resending verification for an existing unconfirmed Email;
- [x] add `tio://login-callback` to repo `supabase/config.toml` redirect allow-list source;
- [x] add `AuthSession.identityProviders` as provider-neutral trusted identity evidence;
- [x] map Supabase `app_metadata.provider/providers` into `AuthSession.identityProviders`;
- [x] wire Account Settings provider label from actual Auth identity evidence;
- [x] add Auth regression tests proving Phone + Email does not imply Google and Google is shown only when reported;
- [x] add Email redirect regression assertions for `updateUser` and `resend`;
- [ ] run Flutter/Dart analyze and focused tests on the exact current PR #131 head;
- [ ] verify hosted Supabase Redirect URLs allow `tio://login-callback`;
- [ ] run a fresh real-device Email confirmation smoke and prove the app opens instead of `localhost:3000`;
- [ ] re-open Account Settings after the same Phone + Email flow and prove Google is absent unless a Google identity is actually linked.

## 6. Source Changes Added by Runtime Hardening

- `apps/features/auth/lib/src/domain/models/auth_session.dart`
- `apps/features/auth/lib/src/data/repositories/supabase_auth_session_repository.dart`
- `apps/features/auth/lib/src/data/repositories/supabase_account_contact_verification_repository.dart`
- `apps/features/auth/test/data/supabase_auth_session_repository_test.dart`
- `apps/features/auth/test/data/supabase_account_contact_verification_repository_test.dart`
- `apps/app/lib/app/router.dart`
- `supabase/config.toml`
- this task file

The original Account Setup slice files remain part of PR #131.

## 7. Expected Behavior After Hardening

```text
Phone-only trusted account
→ Authentication: Phone Connected

Phone account + verified/linked Email identity
→ Authentication: Phone + Email Connected
→ Google must NOT appear

Google-authenticated/linked account where Supabase reports google
→ Authentication includes Google Connected

Optional Email confirmation
→ confirmation Email received
→ link verifies ownership
→ redirect returns to tio://login-callback
→ Tio app opens
→ localhost must not be the user-visible destination
```

## 8. Validation / Handoff

### Completed

- source implementation for both runtime defects;
- read-only hosted evidence establishing the original defects;
- Auth provider-truth mapping based on hosted metadata shape;
- source-level regression tests authored;
- no schema/data mutation;
- PR remains Draft/open/unmerged.

### Pending Gates

1. Flutter/Dart executable validation on exact current #131 head.
2. Hosted Redirect URL allow-list confirmation for `tio://login-callback`.
3. Real-device Email confirmation retest.
4. Real-device Account Settings provider display retest.

### Final Status

`PARTIAL` — both reported defects are source-fixed and recorded in this task, but runtime closure requires executable CI/tests plus a fresh hosted device retest. PR #131 must remain Draft/unmerged until those gates are satisfied.
