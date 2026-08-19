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

Optional/missing personal profile data should be recoverable later from Profile instead of blocking first-run setup.

When the user's personal profile identity is incomplete, show one compact completion card at the **bottom of Profile content, after the existing metrics row**.

Example:

```text
Your profile is 83% finished  →
```

Placement contract:

```text
Profile identity
→ Avatar
→ Name / demographics / plan
→ Weight / Height / BMI / BMR
→ Profile completion card (only when eligible + incomplete)
```

Do not place the card above the avatar or between identity and metrics.

When completion reaches 100%, hide the card.

## Completion V1: personal profile identity only

The completion score is intentionally limited to the user's actual personal/account profile data. It must not expand into fitness, onboarding, plan, targets, health, or derived metric completeness.

Count these six fields independently:

1. Name
2. Username
3. Email
4. Mobile
5. Gender / Sex
6. Date of Birth

Each field contributes equally.

Do **not** count:

- avatar/photo;
- plan/subscription;
- App Mode;
- goals;
- height;
- current/target weight;
- BMI/BMR;
- activity level;
- health conditions;
- workout/nutrition targets;
- any derived value or unrelated onboarding field.

Example:

```text
Name      complete
Username  complete
Email     complete
Gender    complete
DOB       complete
Mobile    blank

5 / 6 = 83% rounded
```

The calculation must use real persisted/profile/auth field presence. Do not treat display fallbacks/default values as proof that a field was actually supplied.

## Card navigation

For V1, tapping the completion card opens Account Settings because Mobile is the expected post-setup missing account field and that screen already owns persisted Username/Mobile editing.

```text
Profile
→ completion card
→ Account Settings
→ missing field can be completed there when owned by Account Settings
→ Save
→ profile data refresh
→ completion percentage recalculates
→ card disappears at 100%
```

Do not reopen Product Onboarding or Account Setup merely to add an optional Mobile later.

## Once-per-login reminder behavior

The card is a lightweight reminder, not a persistent nag.

```text
incomplete profile + current login has not dismissed card
→ show card

user taps card
→ mark completion reminder dismissed locally for the current login/session
→ navigate to the relevant settings surface

user fills data
→ completion may reach 100%
→ card stays hidden because profile is complete

user does not fill data and presses Back
→ card remains hidden for the rest of the current login/session

user logs out and later signs in again
→ local session dismissal resets
→ if profile is still incomplete, card may show once again
```

Dismissal is local/session UX state only. Do not persist the dismissal to Supabase and do not change profile/account completion data merely because the reminder was opened or dismissed.

A token refresh must not by itself count as a new login reminder cycle.

## Persistence and save safety

Account Settings must support a mobile-only edit without forcing an unchanged existing Username through a uniqueness conflict path.

Required save behavior:

```text
existing username unchanged + mobile changed
→ do not availability-check/reclaim the unchanged username
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
- [ ] Completion counts only Name, Username, Email, Mobile, Gender/Sex, and DOB.
- [ ] Fitness/onboarding/plan/derived values never affect completion percentage.
- [ ] Display fallback values do not falsely mark missing persisted profile fields complete.
- [ ] With only Mobile missing, completion reports 83% rounded.
- [ ] Completion card renders after the metrics row, not above/between Profile identity content.
- [ ] Completion card is absent at 100%.
- [ ] Completion card tap opens Account Settings for the current Mobile-first V1 path.
- [ ] Tapping the card dismisses it for the current login/session even when user returns without filling data.
- [ ] Logout + later login makes an incomplete profile eligible for the reminder again.
- [ ] Auth token refresh does not re-show the card as a new login.
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
→ bottom completion card shows 83% when Mobile is the only missing identity field
→ tap card
→ Account Settings opens with Mobile blank
→ Back without filling
→ Profile reminder stays hidden for this login
→ logout
→ sign in again
→ incomplete Profile may show the reminder once again
```

Also verify:

```text
Profile reminder → Account Settings → enter mobile → Save
→ profile refresh
→ completion reaches 100%
→ card is hidden
```

And verify same-account logout/login after blank-Mobile Continue does not replay Username or Mobile Account Setup.
