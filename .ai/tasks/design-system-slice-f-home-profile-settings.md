# Design System Slice F — Home + Profile + Settings

**Status:** Validated  
**Current phase:** Complete  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Home, Profile, and Settings presentation now consume governed core design-system ownership while preserving current product behavior and visible UI.

## Mandatory Visual Freeze

No layout, spacing, color appearance, typography appearance, radius, icon/image sizing, shell styling, motion, gradient, or component geometry changed without separate explicit owner/design approval.

## Preconditions

- [x] Slices A–E are `Validated`.
- [x] Slice E final implementation passed Flutter CI #825.
- [x] Slice E synchronized branch state passed Flutter CI #828.

## Hard Boundaries Preserved

- [x] no profile persistence/domain changes;
- [x] no Settings behavior changes unrelated to styling;
- [x] no ThemeMode/AppThemeController behavior changes;
- [x] no navigation/business-flow changes;
- [x] no feature token catalog introduced.

## Checklist

- [x] Inventory Home/Profile/Settings visual literals and helpers.
- [x] Classify colors, typography, geometry, strokes, opacity/alpha, motion and fixed responsive values.
- [x] Reuse governed core primitives/roles/components first.
- [x] Apply `.ai/tasks/design-system-hardcoded-color-audit.md`.
- [x] Keep `AppThemeController` app-level state/persistence responsibility intact.
- [x] Remove or avoid feature-owned visual/token catalogs.
- [x] Preserve existing rendering and behavior.
- [x] Run focused tests/static audit.
- [x] Run analyze and required CI.

## Completed Inventory and Ownership

### Home

`HomePage` is currently an empty `SizedBox.expand` production stub. It contains no product-visible visual contract to migrate, so Slice F intentionally made no fake Home token migration.

### Profile

Profile presentation now uses governed core ownership across `ProfilePage` and `AvatarPreviewPage`, including plan badge roles, palette ownership, typography, geometry, spacing/radius aliases and SnackBar visuals.

A dedicated static ownership gate at `apps/features/profile/test/presentation/profile_design_system_ownership_test.dart` rejects direct/raw framework colors, raw `Color(0x...)`, typography literals, alpha/opacity literals, raw millisecond visual durations and legacy spacing/radius aliases in Profile presentation code.

### Settings

Settings presentation now uses governed ownership across the Settings hub, App Settings, App Mode, Theme Settings, theme-selection bottom sheet, Account Settings, Measurement Units and Profile Settings surfaces.

A dedicated static ownership gate at `apps/features/settings/test/presentation/settings_design_system_ownership_test.dart` enforces the same visual-ownership rules while explicitly preserving the Account Settings username debounce and fallback availability-check delays as behavior/program timing rather than design-system motion.

## Preserved Behavior and Domain Contracts

The following intentionally remain outside visual token ownership:

- Account Settings username debounce `450ms`;
- fallback username availability delay `250ms`;
- username validation lengths and account save/verify/delete flows;
- Profile date, height and weight domain values and conversion factors;
- App Mode persistence/navigation behavior;
- `AppThemeController` theme persistence responsibility;
- navigation and business-flow behavior.

## Core Ownership Added From Production Evidence

Slice F added only exact, evidenced physical/semantic ownership required by current rendering, including missing geometry/opacity/alpha/motion/palette values. No feature-local or screen-specific token bag was introduced.

## Validation Evidence

Final Slice F implementation head `da9e60d6b8a5afc1b293d59cef7a7aacce5553c4` passed **Flutter CI #843**.

The `Analyze and test` job completed successfully with:

- [x] Bootstrap workspace
- [x] Analyze Flutter packages
- [x] Analyze Dart packages
- [x] Test Flutter packages
- [x] Test Dart packages

The Flutter test phase includes the new Profile and Settings static visual-ownership gates.

## Completion Lifecycle

- [x] Inventory
- [x] Classification
- [x] Planned ownership
- [x] Implementation
- [x] Focused tests
- [x] Static audit
- [x] Pixel/UI regression contract preserved by exact-value migration and mandatory visual freeze
- [x] Analyze
- [x] Required CI
- [x] Update evidence
- [x] Mark `Validated`
- [x] Unblock Slice G

## Exit Criteria

- [x] Home/Profile/Settings consume canonical core visual ownership where production visuals exist.
- [x] Theme-mode state architecture remains unchanged.
- [x] No feature token catalog remains or was introduced in Slice F scope.
- [x] No visible UI change occurred without separate approval.
- [x] Tests/analyze/required CI pass.

## Handoff

Slice F is `Validated`. Slice G — Remaining UI is unblocked and may begin with inventory/classification before any mutation.
