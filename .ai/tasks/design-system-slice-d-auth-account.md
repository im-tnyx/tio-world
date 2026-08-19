# Design System Slice D — Auth + Account Setup

**Status:** Validated  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Auth and Account Setup production UI now consume governed core design-system ownership without changing authentication behavior, account-setup sequencing, routing behavior, legal placement, or rendered UI intentionally.

All feature-local Auth and Account Setup visual-token catalogs covered by this slice were removed rather than replaced with renamed feature token bags.

## Mandatory Visual Freeze

```text
pixels before == pixels after
```

No screen design, layout, spacing, color appearance, typography appearance, radius, icon/image sizing, motion, gradient, component geometry, legal placement, or interaction visual was intentionally changed.

## Preconditions

- [x] Slice A source/runtime boundary validated by Flutter CI #624.
- [x] Slice B Welcome validated by Flutter CI #646.
- [x] Slice C Core Components validated by Flutter CI #710.
- [x] Feature UI agents read `apps/core/lib/src/theme/README.md` before internal token files.
- [x] Core component-token admission gate forbids feature/screen/workflow token bags.

## Scope

- `apps/features/auth/**` presentation UI;
- `apps/features/account_setup/**` presentation UI;
- narrowly evidenced existing core physical registries;
- focused Auth/Account Setup tests and static audits.

The separate reusable-field architecture tracked by Issue #24 was not implemented here.

## Hard Boundaries Preserved

- no auth/session architecture changes;
- no provider/sign-in behavior changes;
- no Firebase/Supabase/auth backend behavior changes;
- no Account Setup sequencing/business-rule changes;
- no routing behavior changes beyond visual-ownership imports;
- no legal placement change;
- no feature token/color/layout/theme replacement catalog;
- no `AuthTokens`, `AccountSetupTokens`, or screen-specific core token class introduced.

## Ownership Rules Applied

```text
Existing reusable core component
        ↓
Existing runtime semantic role / TextTheme
        ↓
Existing reusable component contract
        ↓
Existing exact governed primitive
        ↓
Narrowly evidenced physical-registry extension only when exact UI required it
```

Behavior/domain/program values stayed outside the design-token system. Examples retained as behavior include form validation rules and Forgot Password's development-only 600ms simulated request delay.

## Checklist

### D1 — Inventory and classification

- [x] Inventoried Auth/Account Setup screens/widgets and visual helper/token/theme files.
- [x] Inventoried fixed colors, typography, geometry, strokes, opacity/alpha, motion/effects and component sizes.
- [x] Audited direct Flutter field/button/dialog usage without redesigning field architecture.
- [x] Classified behavior/domain/composition literals separately from product-visible fixed visual values.
- [x] Recorded exact current values before mutation through source/token contract tests.

### D2 — Ownership plan

- [x] Mapped visual values to existing core semantic/component/primitive ownership first.
- [x] Applied exact color/alpha/shadow ownership rules from the hardcoded-color audit.
- [x] Identified six Auth token files and one Account Setup token file as feature-local catalogs for removal.
- [x] Rejected any replacement Auth/AccountSetup core token bag.
- [x] Kept one-off Login/Sign Up floating-banner `elevation = 6.0` local rather than inventing a speculative shared elevation role.

### D3 — Implementation

- [x] Added only evidenced exact physical values to existing registries: `TioSize.dp40/dp80/dp480`, `TioStroke.width12/width18`, `TioFontSize.size11`, `TioLetterSpacing.positive10`.
- [x] Migrated `LoginPage` to direct governed core ownership.
- [x] Migrated `EmailLoginPage` to direct governed core ownership.
- [x] Migrated `ForgotPasswordPage` to direct governed core ownership.
- [x] Migrated `EmailSignupPage` to direct governed core ownership.
- [x] Migrated `AccountSetupFlowPage`, `MobileStep`, and `UsernameStep` to direct governed core ownership.
- [x] Preserved provider buttons, fields, legal disclaimer placement, loading states and interaction visuals.
- [x] Removed all six Auth feature token files and their six proxy-only token tests after production consumers migrated.
- [x] Removed `account_setup_visual_tokens.dart` and its proxy-only token test after all three Account Setup consumers migrated.

## Pixel/Ownership Audit Notes

- Login input outline widths remain exactly `1.2` and `1.8` through `TioStroke.width12/width18`.
- Account Setup max content width remains exactly `480px` through `TioSize.dp480`.
- Sign Up recovery action background preserves exact `0x32FFFFFF` through governed white + `TioAlpha.alpha50`.
- Login/Sign Up floating error banner content gap remains exactly 12dp (`TioSpacing.md`). A transient 10dp mapping was caught by static audit and corrected before final validation.
- Floating error shadow/color/icon/font contracts retain their exact current values through governed palette/opacity/size/typography owners.
- Forgot Password success geometry remains exactly `48/80/40/28/10/40` as previously rendered.

### D4 — Validation

- [x] Existing Auth page/widget tests retained as behavior regression coverage.
- [x] Existing Account Setup flow/system-back/username tests retained as behavior regression coverage.
- [x] Feature token proxy-only tests removed after exact uncommon physical owners were covered in core contract tests.
- [x] Auth production token catalogs removed; final Auth catalog-removal head passed Flutter CI #737.
- [x] Account Setup 3-consumer migration passed Flutter CI #740.
- [x] Final Account Setup catalog-removal source head `5e07070c870cc1eeff51ff1e39393517d723e961` passed Flutter CI #742: Flutter analyze, Dart analyze, Flutter tests and Dart tests all succeeded.
- [x] Empty Auth and Account Setup presentation `theme/` directories disappeared from Git after catalog deletion.
- [x] No unapproved visible UI change remains in the validated source boundary.

## Removed Feature Catalogs

Auth:

```text
auth_email_login_tokens.dart
auth_forgot_password_tokens.dart
auth_form_tokens.dart
auth_login_tokens.dart
auth_signup_tokens.dart
auth_visual_tokens.dart
```

Account Setup:

```text
account_setup_visual_tokens.dart
```

No replacement feature token catalog was created.

## Exit Criteria

- [x] Auth/Account Setup consume canonical core design-system ownership.
- [x] No feature token/color/layout/theme catalog remains in the migrated presentation boundaries.
- [x] No screen/workflow-specific token class was introduced in core.
- [x] Behavior, routing, provider/auth state and account-setup flow remain unchanged.
- [x] No unapproved visible UI change occurred.
- [x] Focused tests, analyze and required CI pass.

## Handoff

Slice D is `Validated`. Slice E — Product Onboarding may now begin under the same mandatory visual freeze, README-first usage flow, and component-token admission gate.
