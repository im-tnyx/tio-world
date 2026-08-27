# Account Setup Complementary Email

**Status:** Source hardening in progress; Google identity connect implementation and executable/runtime validation pending  
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

Three defects/requirements were confirmed after real hosted Phone OTP testing and are part of this task rather than deferred follow-up work.

1. **Email confirmation redirect defect**
   - Phone signup and optional Email request succeeded.
   - Supabase sent the Email change confirmation message and accepted the first confirmation click.
   - After verification, the browser was redirected to `localhost:3000`, producing `ERR_CONNECTION_REFUSED` on the mobile device.
   - Read-only hosted Auth evidence confirmed the Email itself became verified, so the defect was the post-confirmation redirect rather than ownership verification.

2. **False Google Connected state in Account Settings**
   - A Phone-created account with a later Email identity showed `Google / Connected` in Account Settings.
   - Read-only Supabase identity evidence for the account contained `phone` and `email`, with no `google` identity.
   - Root cause: the Settings widget had a hardcoded Google fallback and the production route did not originally supply provider-truth evidence.

3. **Google Connect / Connected must represent real identity linking**
   - Email and Phone verification badges represent ownership verification of those contacts.
   - Google uses a separate linked-identity state: `Connect` while no Google identity exists and `Connected` only after Supabase Auth reports a real `google` identity on the same canonical user UUID.
   - Tapping `Connect` must perform Supabase manual Google identity linking, not a normal Google sign-in that could switch/create a different user.
   - The linked state must be refreshed from Supabase Auth after successful linking rather than being set optimistically in UI-only state.

No private identifier is recorded in this task file.

### Success Criteria

- trusted Email + no trusted Phone plans optional Mobile;
- trusted Phone + no trusted Email plans optional Email;
- both trusted identities require no complementary contact step;
- optional Email can be left blank and Account Setup completes;
- entered Email delegates to Auth-owned Supabase Email add/change + confirmation semantics;
- Email confirmation requests explicitly use the mobile callback `tio://login-callback` instead of relying on the localhost Site URL;
- the mobile callback is represented in repo Supabase redirect configuration;
- Account Settings derives provider truth from trusted Supabase Auth provider metadata, not Email presence, profile metadata, or a hardcoded Google label;
- Email and Phone keep provider-backed verified badges independently of Google linking state;
- when no Google identity is linked, Authentication shows `Google` with an actionable `Connect` state;
- tapping `Google / Connect` invokes real Supabase Google identity linking against the current authenticated UUID;
- after successful linking, Supabase must still report the same canonical UUID and must report a `google` identity before UI shows `Connected`;
- a Phone + Email account must not display Google Connected unless Supabase actually reports a Google identity;
- no Flutter code writes Email verification timestamps;
- canonical authenticated UUID is unchanged;
- no schema, migration, hook, or Edge Function change is required for these fixes;
- PR remains Draft until executable validation and hosted Email/Google-link retests pass.

### Scope

- Account Setup step model/planner;
- Account Setup Email step presentation and focused validation;
- app composition from trusted Auth session evidence;
- Account Setup completion-marker semantics needed to distinguish completed setup from merely verified Mobile;
- Auth-owned Email confirmation redirect hardening;
- trusted Auth provider identity projection into `AuthSession`;
- bounded Account Settings provider-truth correction;
- Google Connect/Connected UI state in Account Settings;
- Auth-owned native Google identity-link boundary using Supabase manual identity linking;
- session/provider refresh after successful link;
- local/repo Supabase redirect allow-list source configuration;
- focused planner/presentation/bridge/Auth/Settings regression tests;
- Issue #130 under parent #118 and Draft PR #131.

### Non-Goals

- Phone OTP capability or Phone-first Login/Signup UI;
- password creation/reset/change;
- Google unlinking in this slice;
- Account Settings contact redesign;
- Product Onboarding changes;
- schema or production data mutation;
- marking any stacked PR Ready or merging it;
- claiming hosted Email redirect or Google-link acceptance before real device retests.

## 2. Verified Evidence

- Account Setup planner and optional Email behavior were already implemented on the clean #129 child branch.
- Real hosted Phone OTP device smoke passed: SMS request, OTP verification, Supabase session, confirmed Phone and matching projected user state were observed.
- Hosted Auth logs showed Email-change mail delivery and successful verification, followed by localhost redirect behavior.
- Read-only Auth state confirmed the target Email became verified even though the browser landed on localhost.
- Read-only Supabase provider evidence for the Phone-created account reported `phone` + `email` and no `google` identity.
- Android already declares the app deep link `tio://login-callback` in `AndroidManifest.xml`.
- The Supabase Dart Auth API used by this repo supports `emailRedirectTo` for `updateUser` and `resend`.
- Supabase Dart supports native manual linking via `linkIdentityWithIdToken(provider: OAuthProvider.google, idToken: ..., accessToken: ...)` for an already authenticated user.
- Supabase manual identity linking must be enabled in hosted Auth configuration before runtime linking can succeed.
- Current connector access does not expose hosted Auth URL Configuration/manual-linking mutation, so hosted settings must be verified separately before runtime closure.

## 3. Architecture Decisions

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Trusted Email / Phone source | Made | Use Auth confirmation evidence, not non-empty contact strings | Auth boundary |
| Linked provider truth source | Made | Use normalized Supabase `app_metadata.provider/providers` projected into `AuthSession.identityProviders` | Auth boundary |
| Settings Google state | Made | `Connect` when `identityProviders` lacks `google`; `Connected` only when Supabase reports `google` | App shell / Settings |
| Google linking operation | Made | Use native Google credentials + Supabase `linkIdentityWithIdToken`, never ordinary sign-in for the Settings Connect action | Auth boundary |
| UUID invariant | Made | Capture current user UUID before linking and require the same UUID after linking | Auth boundary |
| Email callback | Made | Explicitly pass `tio://login-callback` to Auth Email update/resend operations | Auth boundary |
| Hosted redirect acceptance | Confirmed by owner screenshot | Hosted Additional Redirect URLs already contains `tio://login-callback` | Supabase hosted config |
| Manual-linking hosted flag | Pending runtime check | Supabase requires manual linking to be enabled for explicit identity linking | Supabase hosted config |
| Cross-feature dependency | Made | Settings receives a narrow callback/state; provider SDK work remains Auth-owned | App composition |
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
→ Email / Phone verification badges from verification truth
→ Google state from AuthSession.identityProviders
   ├─ google absent → Google / Connect
   │  → native Google chooser
   │  → Supabase linkIdentityWithIdToken
   │  → require same UUID + google identity evidence
   │  → refresh Auth session
   └─ google present → Google / Connected
```

## 5. Implementation Checklist

### Original complementary-contact slice

- [x] add `email` Account Setup step ID and complementary-contact planner matrix;
- [x] add optional Email step UI using existing Tio design-system primitives;
- [x] extend `AccountSetupFlowPage` with Email state, validation, skip, and Auth request-before-completion behavior;
- [x] add `AccountSetupAuthContactBridge` and compose it at app level;
- [x] make `account_setup_completed_at` the explicit durable completion signal;
- [x] add focused planner, Email presentation, and bridge tests.

### Runtime hardening from device testing

- [x] pass `tio://login-callback` as `emailRedirectTo` for Email add/change requests;
- [x] pass the same callback when resending verification for an existing unconfirmed Email;
- [x] add `tio://login-callback` to repo `supabase/config.toml` redirect allow-list source;
- [x] confirm hosted Additional Redirect URLs already contains `tio://login-callback`;
- [x] add `AuthSession.identityProviders` as provider-neutral trusted identity evidence;
- [x] map Supabase `app_metadata.provider/providers` into `AuthSession.identityProviders`;
- [x] wire Account Settings provider evidence from actual Auth identity metadata;
- [x] add Auth regression tests proving Phone + Email does not imply Google and Google is shown only when reported;
- [x] add Email redirect regression assertions for `updateUser` and `resend`;
- [ ] replace unconditional Google Connected row with `Connect` / `Connected` driven by real Google identity evidence;
- [ ] add Auth-owned native Google identity-link implementation using `linkIdentityWithIdToken`;
- [ ] require same user UUID and authoritative Google identity evidence after linking;
- [ ] refresh Account Settings Auth state after successful linking;
- [ ] add focused Google Connect/Connected widget and repository tests;
- [ ] run Flutter/Dart analyze and focused tests on the exact current PR #131 head;
- [ ] verify hosted Supabase manual identity linking is enabled;
- [ ] run a fresh real-device Email confirmation smoke and prove the app opens instead of `localhost:3000`;
- [ ] run a real-device Google Connect smoke and prove same UUID + `google` identity + `Connected` UI;
- [ ] re-open Account Settings for a Phone + Email account with no Google identity and prove it shows `Google / Connect`.

## 6. Source Changes Added by Runtime Hardening

Existing hardening files:

- `apps/features/auth/lib/src/domain/models/auth_session.dart`
- `apps/features/auth/lib/src/data/repositories/supabase_auth_session_repository.dart`
- `apps/features/auth/lib/src/data/repositories/supabase_account_contact_verification_repository.dart`
- `apps/features/auth/test/data/supabase_auth_session_repository_test.dart`
- `apps/features/auth/test/data/supabase_account_contact_verification_repository_test.dart`
- `apps/app/lib/app/router.dart`
- `supabase/config.toml`
- this task file

Google identity-link implementation is expected to add a narrow Auth repository/capability plus Settings/app-composition tests without widening feature ownership.

The original Account Setup slice files remain part of PR #131.

## 7. Expected Behavior After Hardening

```text
Phone-only trusted account
EMAIL / PHONE verification remain independent
Authentication: Google        Connect

Phone account + verified Email identity
Email verified badge          ✅
Phone verified badge          ✅
Authentication: Google        Connect

After real Google identity linking on same UUID
Email / Phone badges          unchanged
Authentication: Google        Connected

Google already authenticated/linked account where Supabase reports google
Authentication: Google        Connected

Optional Email confirmation
→ confirmation Email received
→ link verifies ownership
→ redirect returns to tio://login-callback
→ Tio app opens
→ localhost must not be the user-visible destination
```

## 8. Validation / Handoff

### Completed

- original complementary Email source implementation;
- read-only hosted evidence establishing Email redirect and false-Google defects;
- Auth provider-truth mapping based on hosted metadata shape;
- hosted redirect allow-list confirmed by owner screenshot;
- source-level Email/provider regression tests authored;
- Google Connect/Connected requirement formally added to #130/#131 task scope;
- no schema/data mutation;
- PR remains Draft/open/unmerged.

### Pending Gates

1. Implement and source-review real Google identity linking and `Connect` / `Connected` UI.
2. Flutter/Dart executable validation on exact current #131 head.
3. Verify hosted Supabase manual identity linking is enabled.
4. Real-device Email confirmation retest.
5. Real-device Google identity-link retest proving same UUID and `google` identity.
6. Real-device Account Settings retest proving `Connect` before link and `Connected` only after link.

### Final Status

`PARTIAL` — the Google Connect/Connected requirement is now part of the task. Email/provider-truth source hardening is present, but Google identity linking plus executable and hosted device validation remain before PR #131 can leave Draft.
