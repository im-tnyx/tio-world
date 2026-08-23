# O11A1 — Canonical Profile Settings write cutover

Status: Active

Issue: #103  
Parent O11A: #102  
Parent O11: #54

Starting exact checkpoint:

```text
3ac008bbd38a56d39469c5af55b002ec22f1453b
Flutter CI #1650 ✅
Android Native CI #62 ✅
```

## Goal

Move Profile Settings persistence away from Profile/Body mirrors in `public.users` without changing schema.

## Ownership

```text
username                     → ProfileAccountRepository / users account owner
name/gender/DOB/height       → UserProfileRepository / user_profiles
current weight               → BodyRepository / body_weight_logs
activity/health/units        → preserve existing canonical user_profiles values
```

## Contract

- read the current canonical `UserProfileData` before a partial Profile Settings update;
- fail closed when canonical Profile is missing;
- upsert edited common Profile fields while preserving activity, health conditions, other condition, and unit preferences;
- record Current Weight through `BodyRepository.recordCurrentWeight` with source `profile_settings`;
- do not write `users.name`, `users.gender`, `users.date_of_birth`, `users.dob`, `users.height_cm`, or `users.current_weight_kg`;
- do not claim cross-table transactional rollback;
- no schema/migration change.

## Acceptance

- focused adapter tests cover preservation, provenance, missing-profile failure and write ordering;
- app provider composes the canonical adapter;
- full Flutter/Dart analyze/tests green;
- Android native build green on the exact source SHA.

## Exit

Freeze O11A1, then proceed O11A2 canonical Profile display/settings read composition.