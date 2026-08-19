# Account Setup Optional Mobile + Profile Completion Follow-up

**Status:** Approved for implementation
**Tracking:** GitHub issues #13 and #8
**Working branch:** `agent/app-mode-pre-signup` / PR #36
**Owners:** `apps/features/account_setup` + `apps/features/profile` + `apps/features/settings` + `apps/app`

## Product decision

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

A blank Mobile field followed by `Continue` is a valid acknowledgement of the optional step. No separate Skip button is required.

## Returning-account contract

```text
username persisted
→ Username screen does not return

account_setup_completed_at persisted
→ Mobile screen does not return
→ even when mobile is blank
```

Back is different from Continue:

```text
Mobile → Back/exit
→ do not mark Account Setup complete
→ next matching login may show Mobile again

Mobile blank → Continue
→ mark Account Setup complete
→ future login skips Mobile
```

## Profile completion affordance

Optional/missing data should be recoverable later from Profile instead of blocking first-run setup.

When relevant profile/account information is incomplete, show one compact completion card at the **bottom of Profile content, after the existing metrics row**.

Example:

```text
Your profile is 80% finished  →
```

Placement contract:

```text
Profile identity
→ Avatar
→ Name / demographics / plan
→ Weight / Height / BMI / BMR
→ Profile completion card (only when incomplete)
```

Do not place the card above the avatar or between identity and metrics.

When completion reaches 100%, hide the card.

## Completion V1

Use a small, explainable set of completion groups rather than counting every raw database column independently:

1. Name
2. Username
3. Demographics (`gender` + `dateOfBirth`)
4. Body measurements (`heightCm` + `currentWeightKg`)
5. Mobile

Each group contributes equally. Avatar is intentionally excluded so a user is not prevented from reaching 100% simply because they do not upload a photo.

This gives the approved common case:

```text
all required profile groups complete + mobile blank
→ 4 / 5 complete
→ 80%
```

## Card navigation

For V1, tapping the completion card opens Account Settings because Mobile is the expected post-setup missing account field and that screen already owns editing the persisted mobile number.

```text
Profile
→ completion card
→ Account Settings
→ Mobile field is blank when no number is stored
→ user enters number
→ Save
→ profile data refresh
→ completion percentage recalculates
→ card disappears at 100%
```

Do not reopen Product Onboarding or Account Setup merely to add an optional Mobile later.

## Persistence and save safety

Account Settings must support a mobile-only edit without forcing an unchanged existing Username through a uniqueness conflict path.

Required save behavior:

```text
existing username unchanged + mobile changed
→ do not reject the save because the existing username belongs to the same user
→ persist mobile
→ clear `mobile_verified_at` only when the normalized mobile actually changes
```

Username availability/claim behavior remains required when the username itself changes.

## UI/design-system ownership

- Follow `apps/core/lib/src/theme/README.md`.
- Use `package:tio_core/core.dart` and existing governed values/components.
- Prefer existing `TioCard` for the completion surface.
- Do not add a Profile-specific token bag.
- Do not add a new component-token family for a single Profile workflow.
- Card copy/navigation are Profile-owned product behavior.
- Preserve current Profile identity/metrics rendering outside the explicitly approved new bottom card.

## Acceptance tests

- [ ] Existing username skips Username Account Setup.
- [ ] Mobile blank + Continue completes Account Setup.
- [ ] Returning user with completed Account Setup does not see Mobile again solely because it is blank.
- [ ] Mobile Back/exit without Continue does not complete the Account Setup boundary.
- [ ] Profile with only Mobile missing reports 80% using the V1 completion groups.
- [ ] Completion card renders after the metrics row, not above/between Profile identity content.
- [ ] Completion card is absent at 100%.
- [ ] Completion card tap opens Account Settings.
- [ ] Account Settings shows persisted Mobile or blank when missing.
- [ ] Mobile-only save succeeds with unchanged existing Username.
- [ ] Changing Mobile clears verification state when appropriate.
- [ ] Profile refresh after save updates/removes completion card.
- [ ] Profile visual-ownership/static tests remain green.

## Real-device acceptance

```text
Fresh user
→ Get Started
→ App Mode
→ Signup
→ Username
→ Mobile blank
→ Continue
→ Product Onboarding
→ complete onboarding
→ Profile
→ bottom completion card shows 80%
→ tap card
→ Account Settings opens with Mobile blank
→ enter mobile
→ Save
→ return/reopen Profile
→ completion reaches 100% and card is hidden
```

Also verify a same-account logout/login after the blank-Mobile Continue does not replay Username or Mobile Account Setup.
