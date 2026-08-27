# Account Setup Complementary Email

**Status:** PARTIAL — runtime acceptance passed; clean repository-wide serialized test/CI evidence remains pending.  
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

Account Settings keeps contact verification and OAuth identity linking as separate truths:

```text
Email        verified badge only after Email ownership verification
Phone        verified badge only after Phone ownership verification
Google       Connect while no Google identity exists
Google       Connected only after a real Google identity is linked
```

## Runtime findings and fixes

### Email confirmation redirect

The original Phone → optional Email confirmation flow verified ownership but could fall back to the hosted Site URL (`localhost:3000`). Hosted Dashboard evidence confirmed `tio://login-callback` was already allow-listed.

Source fix:

```text
updateUser(email)
/resend Email verification
→ emailRedirectTo: tio://login-callback
```

Owner-run fresh device validation now confirms the Email confirmation return-to-app behavior works.

### False Google Connected

A Phone-created account with verified Email previously could show `Google / Connected` despite no Google identity. Provider truth is now projected from Supabase Auth rather than inferred from contact/profile state.

### Real Google Connect

`Google / Connect` uses native Google credentials plus Supabase manual identity linking against the currently authenticated canonical user. It must not substitute ordinary Google sign-in for linking.

Implemented safety contract:

```text
Google / Connect
→ explicit Google account chooser
→ obtain Google ID + access token
→ Supabase linkIdentityWithIdToken(google)
→ require Google identity in getUserIdentities()
→ refresh session
→ require refreshed UUID == original UUID
→ invalidate Auth session state
→ Google / Connected
```

Cancellation or missing identity/UUID evidence fails closed and leaves `Connect`.

## Password behavior decision

Phone signup does not force password creation.

Adding and verifying optional Email does not automatically create Email + Password capability. If the user later wants Email + Password login, the verified Email can use the separate password set/recovery path. Password setup remains outside Account Setup.

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
- [x] hosted Additional Redirect URLs contains `tio://login-callback`;
- [x] redirect propagation regression tests authored;
- [x] fresh real-device Email confirmation return-to-app owner-confirmed working.

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
- [x] hosted manual identity linking readiness proven by successful real-device link;
- [x] real-device Google Connect succeeds;
- [x] Settings changes from `Connect` to `Connected` after successful link;
- [x] logout + subsequent Google login succeeds for the same Tio account;
- [x] read-only hosted Auth logs show Phone OTP and subsequent Google OIDC logins resolving to the same canonical user record.

### Executable validation

Validated source state before the final validation-fix commit:

- [x] Auth Google identity-link repository: 6 tests passed;
- [x] Settings package: 23 tests passed;
- [x] Account Setup package: 37 tests passed;
- [x] App package: 226 tests passed;
- [x] affected package analyzers passed;
- [x] manual analysis across Melos Flutter packages and `apps/shared` Dart package passed;
- [x] Android phone debug build passed.

Validation-fix commit:

`d3543512f7aa2307cf92ee1c045f65007186ed41`

The validated fixes were committed normally and pushed with a clean working tree. Post-commit focused commands and exact-commit Android rebuild were attempted, but the local Flutter SDK runner stalled on a stale `dart.exe` lock without emitting test/build output. These were not falsely marked green.

Remaining executable gates:

- [ ] clean environment / CI repository-wide serialized Flutter/Dart test run on the final accepted code SHA;
- [ ] exact committed-head Android rebuild evidence if required for release acceptance.

## Runtime evidence checkpoint

Owner-run device flow now passes:

```text
Phone OTP authentication
→ complementary Email add/verify
→ Email confirmation returns to Tio
→ Settings shows Google / Connect
→ Google identity links successfully
→ Settings shows Google / Connected
→ logout
→ Google login
→ same Tio account
```

Read-only hosted Auth logs independently confirm that the Phone OTP login and later Google OIDC login events resolve to the same canonical user record. No private identifier is recorded in this task file.

## Changed areas

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

## Final handoff

`PARTIAL` — product/runtime acceptance is passed for complementary Email, Google Connect/Connected, and subsequent same-account Google login. The only remaining closure gate is clean executable evidence for the final accepted code SHA. PR #131 must remain Draft/open/unmerged until that gate is intentionally accepted.