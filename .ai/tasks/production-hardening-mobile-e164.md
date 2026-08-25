# Production Hardening — Mobile E.164 Canonicalization

**Status:** Complete / Frozen  
**Primary owner:** shared contact contract + Account/Auth adapters  
**Affected platforms:** Flutter phone app; Supabase Auth/public account contact persistence  
**Tracking:** production hardening #5 follow-up before PR #50 merge readiness

## 1. User Outcome

India-only UI remains `🇮🇳 +91`, while persisted/verified phone identity now uses one canonical E.164 string. Formatting differences can no longer turn the same verified phone into a database-visible contact change, and future international UI can supply explicit `+...` E.164 without a storage-format migration.

## 2. Reproduced Defect

Audit head:

```text
9990f50d802da3a4c487fa0c4e112706483a9ec6
```

Before the fix:

- Account Setup / Account Settings persistence normalized India input to `+91 9123456789`;
- Supabase Auth verification normalized the same identity to `+919123456789`;
- live Auth reconciliation writes the Auth phone to `public.users.mobile` and projects trusted `phone_confirmed_at` to `mobile_verified_at`;
- live `public.users` protection trigger clears `mobile_verified_at` when an authenticated/anon client changes the `mobile` string;
- therefore a verified E.164 phone could later be rewritten in spaced form by Settings Save and lose its trusted verification timestamp even though the semantic number had not changed.

Live audit showed 0 populated public/Auth phone values, so no data rewrite migration was required.

## 3. Frozen Decisions

| Decision | Result |
|---|---|
| Canonical persisted/verified phone format | E.164, e.g. `+919123456789` |
| Current national default | India calling code `91` for current 10-digit UI |
| Explicit international input | valid `+...` E.164-compatible input canonicalizes without changing storage shape |
| `mobile_country_code` column | not added; duplicate source of truth not needed |
| Future app/profile country | separate concept from phone calling code |
| Cross-feature contract owner | `apps/shared` pure Dart contact contract |
| Verification timestamp owner | Supabase Auth/database reconciliation only; never fabricated client-side |
| DB E.164 check constraint | not added; current production writers are now canonical and trusted Auth reconciliation already emits E.164, so a migration was not necessary for this defect |
| UI design | unchanged |

## 4. Completed Implementation

- [x] added `normalizePhoneNumberE164` shared pure-Dart contract;
- [x] exported contact contract from `tio_shared`;
- [x] added India national, formatted India, semantic-equivalence, explicit international, empty, and invalid-input tests;
- [x] replaced duplicate Account Setup persistence normalization;
- [x] replaced duplicate Account Settings persistence normalization;
- [x] replaced duplicate Supabase Auth phone normalization;
- [x] preserved canonical E.164 when Settings saves the same phone after Auth verification;
- [x] added Account Setup guard so optional mobile Continue is enabled only when blank or canonicalizable as a complete current phone number;
- [x] added focused widget regression for blank / partial / full mobile gating;
- [x] kept India-only field visuals and country-code presentation unchanged;
- [x] avoided schema migration/new country column;
- [x] ran exact-SHA Flutter/Dart + Android phone/Wear validation.

## 5. Accepted Checkpoint

Accepted runtime/source-test SHA:

```text
908a617d9c6a30abdfffbd154ae2cebb17eed0a9
```

GitHub Actions:

```text
Flutter CI #2017 / run 32855473413 ✅
  Flutter analyze ✅
  Dart analyze    ✅
  Flutter tests   ✅
  Dart tests      ✅

Android Native CI #429 / run 32855473366 ✅
  Phone Android debug APK ✅
  Wear Android debug APK  ✅
```

Runtime/source-test changes are bounded to:

- `apps/shared/lib/src/contact/contact.dart`
- `apps/shared/lib/src/contact/phone_number.dart`
- `apps/shared/lib/shared.dart`
- `apps/shared/test/contact/phone_number_test.dart`
- `apps/features/profile/lib/src/data/repositories/supabase_account_setup_repository.dart`
- `apps/features/profile/lib/src/data/repositories/supabase_profile_account_repository.dart`
- `apps/features/auth/lib/src/data/repositories/supabase_account_contact_verification_repository.dart`
- `apps/features/account_setup/lib/src/presentation/account_setup_flow_page.dart`
- `apps/features/account_setup/test/presentation/account_setup_mobile_validation_test.dart`

## 6. Final Handoff

**Complete / Frozen.** This docs-only closeout commit does not replace the accepted runtime/source-test SHA `908a617d9c6a30abdfffbd154ae2cebb17eed0a9`.

Future country-selector work should provide explicit E.164 phone identity plus separately owned app/profile country or region semantics; it does not require `public.users.mobile` format migration.

Next step is final PR #50 merge-readiness audit. PR #50 must remain Draft/open/unmerged until explicit merge authorization.

### Final Status

`PASS`
