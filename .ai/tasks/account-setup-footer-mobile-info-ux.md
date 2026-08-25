# Account Setup footer and Mobile information UX

Status: Active

## Fresh audit

Account Setup currently owns one shared fixed footer for Username and Mobile. The footer draws a top border/divider and also contains step-specific helper copy before the Continue button.

Current footer copy:

- Username: `Username is required before continuing.`
- Mobile: `Mobile is optional. You can leave it blank and continue.`

Mobile screen already contains recovery/security context in its header and a second helper below the phone field. There is no explanatory bottom sheet.

## Accepted product behavior

### Shared footer

- Remove the extra top divider/border on both Username and Mobile.
- Keep the fixed Continue action at the bottom.
- Do not change validation, save semantics, progress, Back behavior, E.164 normalization, or Account Setup ownership.

### Username

- Move `Username is required before continuing.` out of the shared footer and into the Username screen content near the username input as subtle helper copy.
- Existing availability, suggestions, validation, and save-error behavior remains unchanged.

### Mobile

- Move the optional/later guidance into the Mobile screen content near the phone input.
- Keep the mobile step optional.
- Do not imply that Account Setup performs OTP verification.
- Add a bottom action above Continue: `Why do we need this information?` with an information icon.
- Tapping that action opens a theme-aware modal bottom sheet explaining that a mobile number can support account recovery, security features, and future verification, and that it can be added or verified later from Account Settings.
- Verified-provider copy remains truthful when a trusted/verified mobile is already present.

## Smallest implementation

1. Update `UsernameStep` helper placement.
2. Update `MobileStep` optional/later helper copy without changing phone field behavior.
3. Remove the shared footer top border and step helper text from `AccountSetupFlowPage`.
4. Add a Mobile-only `Why do we need this information?` footer action and modal bottom sheet using existing Tio semantic colors/spacing and SafeArea conventions.
5. Update focused Account Setup widget regressions for divider absence, helper placement, Mobile-only info action, bottom-sheet content, and existing persistence behavior.

## Constraints

- No Supabase/schema/auth-provider changes.
- No OTP implementation in this slice.
- No phone normalization changes.
- No routing redesign.
- No copy or layout changes outside Account Setup Username/Mobile unless required by a reusable Tio primitive.
- PR #50 remains Draft/open/unmerged.

## Validation

Run focused `tio_feature_account_setup` tests, then full Flutter/Dart analysis/tests and Android exact-SHA CI before freezing.
