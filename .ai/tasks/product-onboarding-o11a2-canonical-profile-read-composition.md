# O11A2 — Canonical Profile display/settings read composition

Status: Active

Issue: #105  
Parent O11A: #102  
Parent O11: #54

Starting source checkpoint:

```text
9a6f853cd245ee7358185c5f57c4a5ac8b169abb
Flutter CI #1654 ✅
Android Native CI #66 ✅
```

## Goal

Stop using broad `public.users` Profile/Body mirrors as production Supabase read truth for Profile display, Profile Settings hydration, and Profile completion reminders.

## Read ownership

```text
UserProfileRepository     → name/gender/DOB/height/activity/health/units
BodyRepository            → current weight + active Body target
account-only users reader → username/avatar/plan/mobile/verification
```

`profile_image` remains avatar-only compatibility fallback until the avatar cleanup gate. Legacy Profile/Body columns must not be fallback truth.

## Acceptance

- canonical composition fails closed on missing canonical Profile/current weight;
- account reader selects only account-owned fields;
- `profileDataProvider` uses canonical composition on the Supabase path;
- `profileCompletionSummaryProvider` derives Profile-owned completion truth from canonical Profile data;
- no schema/migration change;
- exact Flutter/Dart + Android CI green.