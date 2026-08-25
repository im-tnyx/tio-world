# Production Hardening — Mobile E.164 Canonicalization

**Status:** In progress  
**Primary owner:** shared contact contract + Account/Auth adapters  
**Affected platforms:** Flutter phone app; Supabase Auth/public account contact persistence  
**Tracking:** production hardening #5 follow-up before PR #50 merge readiness

## 1. Discovery

### User Outcome

India-only UI may remain `🇮🇳 +91` for now, but every persisted/verified phone identity must use one canonical E.164 string so verification state cannot be lost because of formatting differences and future international support does not require a storage-format migration.

### Success Criteria

- one shared pure-Dart phone canonicalization contract is used by Account Setup persistence, Account Settings persistence, and Supabase Auth verification;
- current India national input `9123456789` canonicalizes to `+919123456789`;
- already international `+...` input is canonicalized/preserved when valid E.164 length/shape is supplied;
- `public.users.mobile` writes no spaces, brackets, or hyphens;
- a verified Auth phone followed by Account Settings Save does not rewrite the same semantic number into a different string and clear `mobile_verified_at`;
- no new country-code column is introduced;
- app-level future country/region remains separate from phone-number calling code;
- current India-only phone UI is visually unchanged;
- exact-SHA Flutter/Dart + Android phone/Wear validation is green before freeze.

### Non-Goals

- no country selector UI;
- no app-level country/profile-country feature;
- no WhatsApp OTP provider work;
- no phone-auth provider switch;
- no verified timestamp fabrication;
- no destructive data migration;
- no unrelated Account/Profile redesign.

## 2. Fresh Current-Head Audit

Audit head:

```text
9990f50d802da3a4c487fa0c4e112706483a9ec6
```

Verified source/runtime evidence:

1. `TioMobileNumberField` is currently India-only by default (`🇮🇳`, `+91`, max 10 digits).
2. Account Setup presentation/draft currently formats national input as `+91 9123456789`.
3. `SupabaseAccountSetupRepository` and `SupabaseProfileAccountRepository` independently normalize 10-digit/91-prefixed input to the spaced string `+91 9123456789` before writing `public.users.mobile`.
4. `SupabaseAccountContactVerificationRepository` independently normalizes the same input to Auth E.164 `+919123456789`.
5. Live `auth.users` has an `AFTER INSERT OR UPDATE OF phone, phone_confirmed_at` reconciliation trigger. Its function writes Auth phone to `public.users.mobile` after removing whitespace and projects trusted `phone_confirmed_at` to `mobile_verified_at`.
6. Live `public.users` has a protection trigger that clears `mobile_verified_at` whenever an authenticated/anon client changes the `mobile` string.
7. Therefore, after successful phone verification, Auth reconciliation can store `+919123456789` with a trusted `mobile_verified_at`, while a later Account Settings Save can write `+91 9123456789`. Even though the repository's local normalization considers these semantically equal, the DB trigger sees a distinct string and clears verification.
8. Live data audit currently shows 0 populated `public.users.mobile` and 0 populated Auth phone values, so there is no existing phone data requiring a rewrite migration.
9. `apps/shared` is already a dependency of both `tio_feature_profile` and `tio_feature_auth`, so it is the dependency-safe owner for a pure cross-feature contact-format contract.

## 3. Decisions

| Decision | Status | Rationale |
|---|---|---|
| Canonical persisted phone format is E.164 | Made | same identity string across Auth and public account owner |
| India national input defaults to calling code `91` for current UI | Made | current product is India-only |
| Valid explicit `+...` E.164 input is accepted | Made | future country picker can supply canonical international value without storage migration |
| Do not add `mobile_country_code` | Made | calling code is already represented by E.164; duplicate source of truth is unnecessary |
| Future app/profile country is separate from phone calling code | Made | residence/locale and SIM/phone numbering region are different concepts |
| Shared pure-Dart contract belongs in `apps/shared` | Made | Profile and Auth both depend on shared without reverse feature dependency |
| Do not fabricate verification timestamps | Made | Auth/database reconciliation remains the trusted verification owner |
| DB schema constraint is optional only if fresh implementation review proves necessary | Pending implementation review | smallest owner-correct fix may be code-only because current trusted Auth reconciliation already emits E.164 and live phone data is empty |

## 4. Implementation Plan

- [ ] add shared E.164 canonicalization + focused pure Dart tests;
- [ ] export the shared contact contract;
- [ ] replace duplicate Profile Account Setup mobile normalization;
- [ ] replace duplicate Profile Account Settings mobile normalization;
- [ ] replace duplicate Auth phone normalization;
- [ ] add regression that Auth-facing national/international inputs produce the same canonical E.164 contract;
- [ ] add/adjust Account persistence tests so canonical values do not introduce a formatting-only rewrite;
- [ ] keep India-only UI unchanged unless a non-visual value callback must be canonicalized;
- [ ] review whether a forward-only DB check constraint is necessary; do not add it without evidence;
- [ ] run exact-SHA Flutter analyze, Dart analyze, Flutter tests, Dart tests, phone Android debug APK, and Wear Android debug APK;
- [ ] freeze accepted checkpoint in #5 and keep PR #50 Draft/open/unmerged.

## 5. Current Status

Concrete correctness defect reproduced from current code + live trigger behavior. Implementation authorized as the next bounded merge-hardening lane.

### Final Status

`REVIEW`
