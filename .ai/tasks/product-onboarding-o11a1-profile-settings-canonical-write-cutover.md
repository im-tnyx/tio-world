# O11A1 — Canonical Profile Settings write cutover

Status: Completed

Issue: #103 ✅  
Parent O11A: #102  
Parent O11: #54

Exact validated source checkpoint:

```text
9a6f853cd245ee7358185c5f57c4a5ac8b169abb
Flutter CI #1654 / run 32642495496 / job 97201663016 ✅
Android Native CI #66 / run 32642495467 / job 97201668257 ✅
```

## Result

Profile Settings no longer writes Profile/Body mirrors in `public.users`.

```text
username                     → ProfileAccountRepository / account owner
name/gender/DOB/height       → UserProfileRepository / user_profiles
current weight               → BodyRepository / body_weight_logs
activity/health/units        → preserved from canonical user_profiles read
```

`CanonicalProfileSettingsRepository` reads the current canonical Profile, fails closed if it is missing, preserves non-edited canonical Profile fields, upserts edited Profile fields, then records Current Weight with `BodyWeightSources.profileSettings` provenance.

No schema or migration change was made, and no cross-table transaction is claimed.

## Acceptance

- focused adapter preservation/provenance/fail-closed/write-order tests ✅
- live Profile Settings route composes canonical adapter ✅
- Flutter analyze ✅
- Dart analyze ✅
- Flutter tests ✅
- Dart tests ✅
- Android native debug build ✅

## Next

O11A2 — canonical Profile display/settings read composition.