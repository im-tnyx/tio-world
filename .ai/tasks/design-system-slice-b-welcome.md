# Design System Slice B — Welcome Cleanup

**Status:** Validated  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

The transitional Welcome-owned visual token catalog has been removed. Welcome now consumes governed core primitives, runtime semantic theme roles, typography/effects, and reusable components without an approved visible UI change.

## Mandatory Visual Freeze

No Welcome layout, spacing, color appearance, typography appearance, radius, image/icon sizing, gradient, motion, or component geometry may change without separate explicit owner/design approval.

`pixels before == pixels after` remained the migration contract.

## Preconditions

- [x] Slice A runtime/source boundary validated by Flutter CI #624.
- [x] Canonical primitive/core ownership was stable for feature migration.
- [x] Color audit rules were available from `.ai/tasks/design-system-hardcoded-color-audit.md`.
- [x] Canonical usage/maintenance guide exists at `apps/core/lib/src/theme/README.md`.

## Final Ownership

```text
Core physical values / semantic roles
        ↓
TioColors runtime light/dark/OLED scheme
        ↓
WelcomeScreen / Welcome widgets
```

Welcome does **not** own or export a design-token/theme catalog.

### Generic core contracts added from evidenced UI

Exact existing Welcome values justified these generic app-wide owners:

- `TioSize.dp60`;
- `TioOpacity.opacity0/18/94/100`;
- `TioAlpha.alpha179` and byte-exact `TioPalette.whiteAlpha179`;
- `TioFontSize.size9_5/size10_5/size42`;
- `TioLineHeight.height110`;
- runtime semantic media roles `TioColors.mediaBackground`, `onMediaPrimary`, and `onMediaSecondary`.

No core API is named after Welcome. Media roles are resolved by the active light/dark/OLED scheme, while their current mappings preserve the existing media composition pixels.

### Composition data intentionally remains local

The following are program/composition values, not global design tokens:

- hero image height factor `0.82`;
- flex values `1/3`;
- content reveal interval start `0.40`;
- backdrop coverage factor `0.50`;
- gradient stop arrays and associated local composition data.

## Completed Checklist

- [x] Inventory every value formerly owned by `welcome_visual_tokens.dart`.
- [x] Classify geometry, color, typography, motion/effect, component roles, factors/ratios, and runtime/program values.
- [x] Reuse existing governed ownership first.
- [x] Add missing core physical values only where exact current UI evidence required them.
- [x] Add generic runtime media semantic roles rather than Welcome-specific color roles.
- [x] Migrate `WelcomeScreen`, `WelcomeFeatureTile`, `WelcomeTopBar`, and `WelcomeBackdrop`.
- [x] Remove `WelcomeLayoutTokens` dependency.
- [x] Remove `WelcomeTypographyTokens` dependency.
- [x] Remove `WelcomeColorTokens` dependency.
- [x] Remove `WelcomeMotionTokens` dependency.
- [x] Remove `WelcomeBackdropTokens` dependency.
- [x] Delete `welcome_visual_tokens.dart`.
- [x] Remove the now-empty `presentation/theme/` boundary from the tracked tree.
- [x] Do not introduce `WelcomeTokens`, `WelcomeVisualTokens`, or another replacement feature token bag.
- [x] Preserve current Welcome legal/footer decisions.
- [x] Preserve existing Roboto hero family through governed `TioFontFamily.roboto`; do not expose it as a Settings-selectable font without verified availability.
- [x] Run focused core tests for newly evidenced primitives/media semantics.
- [x] Run static import/public-export/structure audit.
- [x] Run analyze and required CI.

## Pixel-Equivalence Evidence

No approved visual normalization was applied in Slice B.

During migration, an initial mapping of legacy `TioSpacing.extraLarge` to `TioSpacing.xxl` was caught by the explicit value audit before final validation. The correct exact mapping is `extraLarge -> xl -> 24dp`; both occurrences were corrected before the validated B2 head.

Other representative exact mappings include:

```text
extraSmall -> xs -> 4dp
small      -> sm -> 8dp
medium     -> md -> 12dp
large      -> lg -> 16dp
extraLarge -> xl -> 24dp
```

Fixed Welcome geometry that is not a semantic spacing/radius role uses exact `TioSize` values rather than visual normalization.

## Validation Evidence

- Flutter CI #640: generic media semantic/core contract boundary passed Flutter/Dart analyze and tests.
- Flutter CI #645: corrected Welcome consumer migration passed Flutter/Dart analyze and tests.
- Flutter CI #646: final head after deleting `welcome_visual_tokens.dart` passed Flutter/Dart analyze and tests.
- Final validated source commit: `2399b6745e2fd7396296a314ee660f2c3f0307e8`.
- `apps/features/welcome/lib/welcome.dart` exports only the Welcome route; the removed token file was not public API.
- Current `apps/features/welcome/lib/src/presentation/` tree contains no `theme/` directory after deletion.

## Exit Criteria

- [x] No Welcome-owned design-token catalog remains.
- [x] Welcome consumes governed core design-system contracts.
- [x] Runtime media colors resolve through the active theme scheme.
- [x] No visible UI change was approved or intentionally introduced.
- [x] Tests/analyze/required CI pass.

Slice C — Core Components is now unblocked.
