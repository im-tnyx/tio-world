# Account Setup Optional Mobile + Profile Completion Follow-up

**Status:** Validated for PR #36
**Tracking:** GitHub issues #13 and #8
**Working branch:** `agent/app-mode-pre-signup` / PR #36
**Owners:** `apps/features/account_setup` + `apps/features/profile` + `apps/features/settings` + `apps/app`

## Product contract

Keep Username required, keep Mobile optional, and do not force optional Mobile again after the user has already continued through Account Setup.

```text
Fresh/freshly authenticated account
→ Username
   missing → show and require
   already persisted → skip
→ Mobile
   number entered → save number + complete Account Setup
   blank + Continue → allow + complete Account Setup
→ Product Onboarding
```

Back is not completion:

```text
Mobile → Back/exit
→ do not mark Account Setup complete
→ next matching login may show Mobile again

Mobile blank → Continue
→ mark Account Setup complete
→ future login skips Mobile
```

## Profile completion card

When the user's personal profile identity is incomplete, show one compact completion card at the **bottom of Profile content, after the existing metrics row**.

Use existing reusable/theme-governed `TioCard`. Do not create a Profile token bag or a new component family for this single workflow.

At 100% complete, hide the card.

### Completion V1

Count only these six actual personal/account profile fields independently:

1. Name
2. Username
3. Email
4. Mobile
5. Gender / Sex
6. Date of Birth

Do not count avatar, plan, App Mode, goals, height, weight, BMI/BMR, activity, health conditions, workout/nutrition data, targets, or derived values.

Only-Mobile-missing example:

```text
5 / 6 = 83% rounded
```

The calculation uses real persisted/auth/profile field presence rather than display fallback values.

## Reminder behavior

The card is a lightweight reminder, not a persistent nag.

```text
incomplete + not acknowledged this login
→ show card

card tap
→ navigate to the relevant settings surface
→ dismiss reminder locally for this login

Back without filling
→ reminder remains hidden for the current login

logout + later login
→ incomplete profile becomes eligible again
```

Dismissal is local/session UX state only and is not persisted to Supabase. Token refresh alone is not a new login reminder cycle.

For the current Mobile-first V1, the card routes to Account Settings. Product Onboarding/first-run Account Setup is not reopened merely to add optional Mobile later.

## Account Settings save safety

Mobile-only edits must not re-claim an unchanged Username.

```text
existing username unchanged + mobile changed
→ no username availability/reclaim path
→ persist mobile
→ clear mobile_verified_at only when normalized mobile changes
```

Username availability/claim behavior remains required when Username itself changes.

## Automated validation

Latest validated PR head before this documentation-only status update:

```text
head: 81d187300a528a5d41ececaf374cf6637639c8e4
Flutter CI: #927
run: 32287172622

Bootstrap workspace      PASS
Analyze Flutter packages PASS
Analyze Dart packages    PASS
Test Flutter packages    PASS
Test Dart packages       PASS
```

Automated coverage includes the Account Setup planner/completion behavior, Profile completion calculation/rendering, reminder/session behavior, and Account Settings save regressions added in this slice.

## Real-device acceptance — 2026-08-20

Owner/device smoke confirmed the primary integrated flow:

- Back and Next/Continue navigation work through the tested app flow.
- Profile completion card appears correctly on Profile.
- Same-account logout/login returns Product Onboarding to the previously reached valid step rather than replaying the Back destination.
- The integrated first-run/account/onboarding/profile flow is behaving as expected on device.

The device report validates the main product journey. Individual automated edge cases remain represented by the test suite rather than being mislabeled as separately device-tested.

## Exit criteria

- [x] Existing Username is skipped when already persisted.
- [x] Blank Mobile + Continue can complete Account Setup.
- [x] Completed Account Setup does not replay Mobile solely because it is blank.
- [x] Back without Continue does not become completion.
- [x] Completion score is limited to Name/Username/Email/Mobile/Gender/DOB.
- [x] Only-Mobile-missing reports 83% rounded.
- [x] Card is after Profile metrics and hidden at 100%.
- [x] Existing reusable themed card ownership is used.
- [x] Reminder acknowledgement is session/local only.
- [x] Mobile-only save does not force unchanged Username through uniqueness handling.
- [x] Full automated CI green.
- [x] Primary real-device integrated smoke green.

## Final handoff

`VALIDATED FOR PR #36` — ready for review/merge. Issue #8 remains the separate long-term Profile ownership tracker where applicable.