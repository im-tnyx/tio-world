# Account Setup Complementary Email

**Status:** Source complete; executable validation and hosted Email/Google runtime retests pending  
**Primary owner:** `apps/features/account_setup` with Auth/Settings composition through `apps/app`  
**Affected platforms:** Flutter mobile

## Outcome

Complete #130 under parent #118 and harden the runtime behavior discovered during real Phone OTP testing.

```text
trusted Email / Google identity
→ Username
→ Mobile optional

trusted Phone identity
→ Username
→ Email optional
```

Account Settings must keep contact verification and OAuth identity linking as separate truths:

```text
Email        verified badge only after Email ownership verification
Phone        verified badge only after Phone ownership verification
Google       Connect while no Google identity exists
Google       Connected only after a real Google identity is linked
```

## Runtime findings incorporated into this task

### 1. Email confirmation redirect

Observed on a real device:

```text
Phone signup
→ optional Email
→ confirmation mail received
→ Email ownership confirmed in Supabase
→ browser redirected to localhost:3000 ❌
```

Hosted Supabase Dashboard evidence later confirmed `tio://login-callback` was already present in Additional Redirect URLs. The defect was therefore the client request falling back to Site URL instead of sending an explicit mobile redirect.

Source fix:

```text
updateUser(email)
/resend Email verification
→ emailRedirectTo: tio://login-callback
```

### 2. False Google Connected

Read-only hosted Auth evidence for the tested Phone-created account showed:

```text
providers = phone + email
Email verified = true
Phone verified = true
Google identity = absent
```

The previous Settings UI could still show `Google / Connected`, which was false.

### 3. Google Connect must be real identity linking

`Google / Connect` must never call the normal Google sign-in path in a way that can replace the current account. It must link Google to the current authenticated Supabase UUID and show `Connected` only after authoritative Google identity evidence exists.

Supabase Auth remains the identity authority.

## Architecture decisions

| Concern | Decision |
|---|---|
| Trusted Email/Phone | Use provider-backed Auth confirmation evidence |
| Provider truth | Project normalized Supabase `app_metadata.provider/providers` into `AuthSession.identityProviders` |
| Google UI state | `Connect` unless provider truth contains `google`; `Connected` only when it does |
| Google linking | Native Google chooser + Supabase `linkIdentityWithIdToken` |
| UUID invariant | Capture current UUID before linking and require the same UUID after refresh |
| Post-link evidence | Require `getUserIdentities()` to contain `google` before success |
| Post-link refresh | Refresh Supabase session and invalidate app Auth session state |
| Email callback | Explicit `tio://login-callback` on Email update/resend |
| Settings ownership | Settings owns UI only; provider SDK/Supabase linking remains Auth-owned |
| Google unlink | Out of scope for this slice |

## Implemented flow

```text
Account Settings
→ Email / Phone verified badges remain independent
→ Google state from AuthSession provider evidence

if google absent
→ Google / Connect
→ explicit Google account chooser
→ obtain Google ID + access token
→ Supabase linkIdentityWithIdToken(google)
→ require Google identity in getUserIdentities()
→ refresh session
→ require refreshed user UUID == original UUID
→ invalidate Auth session state
→ Google / Connected

if chooser cancelled
→ remain Google / Connect

if linking/evidence/UUID check fails
→ fail closed
→ remain Google / Connect
```

## Implementation checklist

### Complementary Account Setup

- [x] trusted Email only plans optional Mobile;
- [x] trusted Phone only plans optional Email;
- [x] both trusted contacts skip complementary collection;
- [x] optional Email may be blank;
- [x] entered Email delegates to Auth-owned confirmation request;
- [x] `account_setup_completed_at` is the durable Account Setup completion marker;
- [x] focused planner/presentation/bridge tests authored.

### Email redirect hardening

- [x] pass `tio://login-callback` to Email add/change request;
- [x] pass `tio://login-callback` to Email verification resend;
- [x] record mobile callback in repo Supabase config;
- [x] owner screenshot confirmed hosted Additional Redirect URLs already contains `tio://login-callback`;
- [x] redirect propagation regression tests authored;
- [ ] fresh real-device Email confirmation retest on latest build.

### Provider truth and Google Connect

- [x] add `AuthSession.identityProviders`;
- [x] map Supabase provider metadata into domain Auth session;
- [x] remove hardcoded Google default from Account Settings;
- [x] keep Email/Phone verified badges independent;
- [x] render `Google / Connect` when Google identity is absent;
- [x] render `Google / Connected` only when Google identity is present;
- [x] add narrow `GoogleIdentityLinkRepository` Auth boundary;
- [x] implement native Google linking with Supabase `linkIdentityWithIdToken`;
- [x] require authoritative Google identity after linking;
- [x] enforce same canonical UUID after session refresh;
- [x] refresh/invalidate Auth state after successful link;
- [x] handle chooser cancellation without false Connected state;
- [x] add Settings widget tests for Connect, Connected, success and cancellation;
- [x] add Auth repository tests for unauthenticated, already-linked, cancel, success, missing identity evidence and UUID change;
- [ ] verify hosted Supabase manual identity linking is enabled;
- [ ] real-device Google Connect smoke on latest build.

### Validation

- [ ] Flutter/Dart analyze and tests on exact latest PR #131 head;
- [ ] Android build/CI on exact latest head as available;
- [ ] real device: Email confirmation opens Tio instead of localhost;
- [ ] real device: Phone + Email account shows `Google / Connect`;
- [ ] real device: Google Connect preserves UUID and adds `google` identity;
- [ ] real device: Settings changes to `Google / Connected` only after successful link.

## Changed areas

Original Account Setup slice plus runtime hardening now touches:

- `apps/features/account_setup/...`
- `apps/features/profile/lib/src/data/repositories/supabase_account_setup_repository.dart`
- `apps/features/auth/lib/src/domain/models/auth_session.dart`
- `apps/features/auth/lib/src/domain/repositories/google_identity_link_repository.dart`
- `apps/features/auth/lib/src/data/repositories/supabase_auth_session_repository.dart`
- `apps/features/auth/lib/src/data/repositories/supabase_account_contact_verification_repository.dart`
- `apps/features/auth/lib/src/data/repositories/supabase_google_identity_link_repository.dart`
- `apps/features/auth/test/data/...`
- `apps/features/settings/lib/src/presentation/...`
- `apps/features/settings/test/presentation/account_settings_page_test.dart`
- `apps/app/lib/app/router.dart`
- `apps/app/lib/app/google_identity_link_controller.dart`
- `apps/app/lib/main.dart`
- `supabase/config.toml`

No database schema, migration, hook, Edge Function, or production data mutation is introduced by this source hardening.

## Expected final behavior

```text
Phone + verified Email, no Google identity
Email        ✅ verified badge
Phone        ✅ verified badge
Google       Connect

After successful Google identity link
same Supabase UUID
providers include google
Email/Phone badges unchanged
Google       Connected
```

## Final handoff

`PARTIAL` — requested source changes are implemented and regression tests are authored. Runtime closure still requires executable Flutter/Dart validation, hosted manual-linking readiness, a fresh Email deep-link retest, and a real Google identity-link device smoke. PR #131 must remain Draft/open/unmerged until those gates pass.
