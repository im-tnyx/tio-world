# Account Setup footer and Mobile information UX

Status: Active

## Fresh audit

Account Setup currently owns one shared fixed footer for Username and Mobile. The footer draws a top border/divider and also contains step-specific helper copy before the Continue button.

Current footer copy:

- Username: `Username is required before continuing.`
- Mobile: `Mobile is optional. You can leave it blank and continue.`

Mobile screen already contains recovery/security context in its header and a second helper below the phone field. There was no explanatory bottom sheet before this slice.

## Theme / reusable UI ownership audit

`apps/core/lib/src/theme/README.md` is the canonical Flutter UI ownership guide and requires feature work to prefer an existing reusable core component before adding feature-owned visual contracts.

The existing reusable sheet owner is:

```text
apps/core/lib/src/ui/components/sheets/tio_sheet.dart
```

`TioSheet` already owns the shared themed sheet surface, top radius, padding, title typography, and runtime semantic colors. Therefore Account Setup must not recreate that surface with a feature-owned `Container` / `BoxDecoration` or add an AccountSetup-specific sheet token class.

The modal transparency is framework/composition behavior. In feature code it must use the existing governed opacity primitive rather than raw `Colors.transparent`:

```text
context.tioColors.<semantic>.withValues(alpha: TioOpacity.opacity0)
```

No new core reusable API or token is required for this slice, so the public design-system contract itself does not need to change.

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
- The explanatory surface must use the existing reusable `TioSheet` owner.
- Verified-provider copy remains truthful when a trusted/verified mobile is already present.

## Smallest implementation

1. Update `UsernameStep` helper placement.
2. Update `MobileStep` optional/later helper copy without changing phone field behavior.
3. Remove the shared footer top border and step helper text from `AccountSetupFlowPage`.
4. Add a Mobile-only `Why do we need this information?` footer action.
5. Present the explanation through existing core `TioSheet`; keep only product-specific copy in Account Setup.
6. Use semantic colors/governed opacity for the modal composition; no raw framework/product colors in the feature.
7. Update focused Account Setup widget regressions for divider absence, helper placement, Mobile-only info action, reusable sheet content, and existing persistence behavior.

## Constraints

- No Supabase/schema/auth-provider changes.
- No OTP implementation in this slice.
- No phone normalization changes.
- No routing redesign.
- No feature-specific sheet token/widget when `TioSheet` already owns the reusable visual contract.
- No copy or layout changes outside Account Setup Username/Mobile unless required by an existing reusable Tio primitive.
- PR #50 remains Draft/open/unmerged.

## Validation

Run focused `tio_feature_account_setup` tests, core visual-ownership enforcement, then full Flutter/Dart analysis/tests and Android exact-SHA CI before freezing.
