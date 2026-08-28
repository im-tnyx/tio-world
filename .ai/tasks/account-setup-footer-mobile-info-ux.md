# Account Setup footer and Mobile information UX

Status: Complete / Frozen

## Fresh audit

Account Setup owned one shared fixed footer for Username and Mobile. The footer drew a top border/divider and also contained step-specific helper copy before the Continue button.

Former footer copy:

- Username: `Username is required before continuing.`
- Mobile: `Mobile is optional. You can leave it blank and continue.`

Mobile already contained recovery/security context near the input but had no explanatory bottom sheet.

## Theme / reusable UI ownership audit

`apps/core/lib/src/theme/README.md` is the canonical Flutter UI ownership guide and requires feature work to prefer an existing reusable core component before adding feature-owned visual contracts.

The existing reusable sheet owner is:

```text
apps/core/lib/src/ui/components/sheets/tio_sheet.dart
```

`TioSheet` owns the shared themed sheet surface, top radius, padding, title typography, and runtime semantic colors. Account Setup therefore does not recreate that surface with a feature-owned decorated container and does not add an AccountSetup-specific sheet token class.

The modal transparency is framework/composition behavior and uses the existing governed opacity primitive instead of raw `Colors.transparent`:

```text
context.tioColors.<semantic>.withValues(alpha: TioOpacity.opacity0)
```

No new core reusable API or token was required, so the public design-system contract itself did not change.

## Accepted product behavior

### Shared footer

- Extra top divider/border removed on both Username and Mobile.
- Fixed Continue action remains at the bottom.
- Validation, save semantics, progress, Back behavior, E.164 normalization, and Account Setup ownership are unchanged.

### Username

- `Username is required before continuing.` moved out of the shared footer and into Username content near the input as subtle helper copy.
- Existing availability, suggestions, validation, and save-error behavior remains unchanged.

### Mobile

- Optional/later guidance lives in Mobile content near the phone input.
- Mobile remains optional.
- Account Setup does not imply or perform OTP verification.
- A Mobile-only bottom action above Continue reads `Why do we need this information?` with an information icon.
- Tapping the action opens a theme-aware modal explanation covering account recovery, security features, future verification, and later Account Settings management.
- The explanatory visual surface uses existing reusable `TioSheet`.
- Verified-provider copy remains truthful when a trusted/verified mobile is already present.

## Implementation result

1. `UsernameStep` owns required-helper placement near the username input.
2. `MobileStep` owns optional/later helper copy near the phone field.
3. `AccountSetupFlowPage` footer no longer owns a divider or duplicate step helper copy.
4. Mobile owns the `Why do we need this information?` footer action.
5. The explanation is presented through core `TioSheet`; Account Setup owns only product-specific copy/modal invocation.
6. Modal transparency uses semantic color + `TioOpacity.opacity0`; the previous direct feature `Colors.transparent` violation is gone.
7. Focused widget regression confirms helper placement, divider absence, Mobile-only info action, reusable `TioSheet` usage, explanatory content, and unchanged optional-mobile persistence.

## Constraints preserved

- No Supabase/schema/auth-provider changes.
- No OTP implementation.
- No phone normalization changes.
- No routing redesign.
- No feature-specific sheet token/widget.
- PR #50 remains Draft/open/unmerged.

## Accepted source checkpoint

```text
f0ba3d29543a2b188f3393c4846d1495a5018e11
```

Validation on that exact source SHA:

```text
Flutter CI #2062 / run 32931363127 ✅
- Flutter analyze ✅
- Dart analyze ✅
- Flutter tests ✅
- Dart tests ✅
- core final visual-ownership enforcement ✅

Android Native CI #474 / run 32931363080 ✅
- phone Android debug APK ✅
- Wear Android debug APK ✅
```

This task-file freeze commit is documentation-only and does not replace the accepted runtime/source checkpoint above.

## Merge guard

PR #50 stays Draft/open/unmerged. Do not mark Ready, merge, or enable auto-merge without explicit owner authorization.
