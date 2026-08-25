# Production Hardening — Profile Health Calculations

Status: **AUDIT COMPLETE / IMPLEMENTATION REQUIRED**
Owner: #5 P2 item 17
Implementation PR: #50 (Draft/open/unmerged)
Audit date: 2026-08-25

Fresh audit head:

```text
4a4e6c1a9567d4a026ff8164cfa149fe10277a87
```

## Goal

Move reusable Age/BMI/BMR business calculations out of `ProfilePage` presentation code into the Profile domain while preserving current display behavior and keeping Goal Pace/Nutrition target ownership unchanged.

## Fresh finding

`apps/features/profile/lib/src/presentation/pages/profile_page.dart` currently owns three private business calculations:

- `_calculateAge(DateTime dob)` using `DateTime.now()`;
- `_calculateBmi(...)` including formula + one-decimal rounding;
- `_calculateBmr(...)` including gender-specific BMR adjustment.

The widget invokes those formulas directly during `build()` and renders the derived Age/BMI/BMR values.

Code search found no existing Profile-domain metrics calculator. Nutrition owns its separate target-recommendation calculator; this slice must not pull TDEE/calorie/macro/Goal Pace logic into Profile or create a cross-feature presentation dependency.

## Owner decision

```text
Age/BMI/BMR calculation       → Profile domain calculator
Profile formatting/rendering  → ProfilePage
Nutrition target/TDEE/macros  → Nutrition domain (unchanged)
Goal Pace                     → Body-owned accepted #113 contract (unchanged)
```

The domain calculator accepts an optional reference date so age behavior is deterministic in unit tests. Production defaults to the current date inside the domain boundary.

## Implementation

- [ ] add a Profile-domain health metrics result model;
- [ ] add a pure Profile-domain calculator for Age/BMI/BMR;
- [ ] preserve current BMI precision and BMR gender formula;
- [ ] remove Age/BMI/BMR formula ownership from `ProfilePage`;
- [ ] keep ProfilePage responsible only for rendering/measurement formatting;
- [ ] add focused domain tests including birthday boundary, BMI rounding, gender BMR variants and invalid dimensions;
- [ ] add/retain presentation regression proving metrics still render;
- [ ] do not change Nutrition target/TDEE/calorie/macro calculation;
- [ ] do not change Goal Pace behavior or introduce calorie/BMR/TDEE coupling into Goal Pace;
- [ ] exact-head Flutter/Dart + Android CI green.

## Acceptance

1. No Age/BMI/BMR formulas remain in `ProfilePage`.
2. Profile-domain tests deterministically own the calculations.
3. Valid Profile data renders the same metric values as before.
4. Non-positive height/weight keeps BMI/BMR unavailable instead of fabricating values.
5. Existing Nutrition/Onboarding/Goal Pace tests remain green.
6. No Supabase/schema/auth/routing change.
7. PR #50 remains Draft/open/unmerged unless separately authorized.
