# Tio Core Theme and Design System

This directory is the canonical implementation and usage boundary for Tio's shared Flutter theme, design tokens, typography, runtime theme extensions, and reusable component visual contracts.

Use this guide before adding or changing visual values in `apps/core` or any feature package.

## Maintenance Contract

This README is part of the design-system contract, not optional commentary.

When a change adds, removes, renames, or materially changes any of the following, update this README in the **same change/PR**:

- token categories or ownership rules;
- public theme or context APIs;
- spacing, radius, stroke, typography, color, motion, shadow, or component contracts;
- `TioThemeConfig` behavior;
- runtime-selectable font behavior;
- compatibility/deprecation guidance;
- the recommended way feature code consumes the design system.

If runtime source and this README disagree, runtime source is authoritative for current behavior, but the documentation is stale and must be corrected before the design-system task is considered complete.

## Public Entry Point

Feature packages should normally import the core package:

```dart
import 'package:tio_core/core.dart';
```

The theme barrel is:

```text
apps/core/lib/src/theme/theme.dart
```

It exports runtime context helpers, `TioTheme`, `TioThemeConfig`, and the governed token families.

## Ownership Hierarchy

```text
Primitive physical values
        ↓
Foundation / semantic / typography / effects roles
        ↓
Reusable component contracts
        ↓
Reusable core components
        ↓
Feature screens/widgets
```

The important rule is:

> A fixed product-visible physical value has one canonical owner. Upper layers alias governed lower-level values instead of redefining the same number/color/duration independently.

Feature-specific token bags such as `WelcomeTokens`, `AuthTokens`, `ProfileTokens`, or screen-local theme catalogs are not the target architecture.

## Token Families

### Primitive physical values

Use these as the lowest-level exact-value registries:

```text
TioSize       fixed geometry values
TioOpacity    normalized opacity values
TioAlpha      exact 0–255 alpha values
TioDuration   fixed durations
```

Example:

```dart
const SizedBox(width: TioSize.dp20);
```

Do not add arbitrary values “just in case”. A new primitive must be evidenced by current UI or an approved design decision. Exact migration evidence may add values that are uncommon globally (for example a fixed `60dp` geometry or exact opacity/alpha contract); the physical registry owns the exact value so feature code does not recreate it.

### Foundation geometry

Use semantic geometry when the role actually matches:

```text
TioSpacing.none / xxs / xs / sm / md / lg / xl / xxl
TioRadius.none / xs / sm / md / lg / xl / full
TioStroke.width075 / width1 / width125 / width15 / width2 / ...
```

Examples:

```dart
const EdgeInsets.all(TioSpacing.lg);

BorderRadius.circular(TioRadius.lg);

BorderSide(width: TioStroke.width1);
```

If an exact component value has no matching semantic spacing/radius role, preserve the exact value through `TioSize` rather than forcing a nearby scale value.

```dart
// Correct when 20dp is the exact component contract.
const EdgeInsets.symmetric(horizontal: TioSize.dp20);
```

Do not mechanically normalize `20` to `16` or `24` merely to use `TioSpacing`.

### Colors

Feature and reusable UI should resolve theme-aware colors dynamically:

```dart
final colors = context.tioColors;

Container(color: colors.surface);
Text('Title', style: TextStyle(color: colors.textPrimary));
```

`Theme.of(context).colorScheme` is also valid when the Material semantic role is appropriate.

`TioPalette` is the physical color registry. Feature screens should not normally consume palette colors directly.

Prefer:

```dart
context.tioColors
Theme.of(context).colorScheme
```

Avoid:

```dart
const Color(0xFF...);       // repeated product-visible color in feature UI
TioPalette.someColor;       // direct physical palette use when a semantic role exists
```

A rare audited one-off fixed color with no honest reusable semantic role may consume the governed `TioPalette` value directly rather than creating a feature color-token bag. Preserve byte-exact alpha through `TioAlpha`/palette ownership when the current ARGB contract depends on an exact alpha byte.

Intentional framework-transparent values such as `Colors.transparent` may remain where transparency itself is implementation behavior rather than a product color role.

### Typography

Feature UI should normally consume semantic `TextTheme` roles:

```dart
final textTheme = Theme.of(context).textTheme;

Text('Title', style: textTheme.titleLarge);
Text('Body', style: textTheme.bodyMedium);
```

Physical typography registries are:

```text
TioFontSize
TioFontWeight
TioLetterSpacing
TioLineHeight
TioFontFamily
```

These are primarily for `TioTypography` and reusable component typography contracts. Feature screens should not recreate a full style system from physical typography primitives.

For a truly one-off typography composition that has no reusable semantic role, compose the exact style at the consumer from governed physical typography values rather than introducing a feature typography-token catalog. Fractional font-size identifiers preserve the decimal explicitly, for example `TioFontSize.size9_5` and `TioFontSize.size10_5`.

#### Runtime font selection

The architecture supports a future Settings font preference:

```text
TioFontFamily
        ↓
TioFontFamilyOption
        ↓
TioThemeConfig.fontFamilyOption
        ↓
TioTypography
        ↓
Theme.of(context).textTheme
```

The default is the platform/system font. A font becomes a user-selectable `TioFontFamilyOption` only after availability is verified on all supported platforms, normally by bundling/registering the font assets.

Do not add per-screen font-family switches. An evidenced explicit family that is required to preserve an existing composition may remain a governed `TioFontFamily` identifier without automatically becoming a Settings-selectable option.

### Motion

Use the runtime motion scheme so reduced/custom motion behavior can be resolved centrally:

```dart
duration: context.tioMotion.slow,
```

`TioDuration` owns physical durations. `TioMotion` owns semantic duration roles. `TioMotionScheme` is the runtime-resolved scheme.

Do not add raw repeated `Duration(milliseconds: ...)` values in feature UI when an existing governed motion role applies.

Animation interval positions, normalized progress factors, gradient stops, flex values, and other composition/program ratios are not durations or geometry primitives merely because they are numeric. Keep genuinely local factors close to the owning consumer.

### Shadows

Use runtime shadows when a theme-aware shadow/effect role is required:

```dart
final shadows = context.tioShadows;
```

Static reusable shadow contracts live under the effects token family; runtime mode-specific resolution belongs to `TioShadows`.

### Domain semantic colors

`TioDomainColors` owns reusable product-domain color semantics where the role is shared across features. Do not create a feature-local color catalog when an existing semantic/domain role already expresses the intent.

### Reusable component tokens

Files under:

```text
tokens/components/
```

own reusable component contracts such as button, input, card, avatar, dialog, picker, navigation, and sheet values.

Component tokens may keep semantic names, but physical values must alias governed lower layers.

Example:

```dart
class TioButtonTokens {
  static const height = TioSize.dp46;
  static const radius = TioRadius.full;
  static const outlineWidth = TioStroke.width1;
}
```

A feature screen should prefer the reusable component itself (`TioButton`, `TioInput`, `TioCard`, etc.) rather than copying its token contract to rebuild the same component locally.

## Static vs Runtime Values

A useful rule:

```text
Static physical/semantic value → token directly
Runtime theme-dependent value  → BuildContext / ThemeData
```

Static examples:

```dart
TioSize.dp20
TioSpacing.lg
TioRadius.md
TioStroke.width1
TioFontSize.size16
```

Runtime examples:

```dart
context.tioColors
context.tioMotion
context.tioShadows
Theme.of(context).textTheme
Theme.of(context).colorScheme
```

Do not put static token wrappers into `BuildContext` merely for convenience.

## Choosing the Correct Owner

Before adding a visual value, classify it.

### 1. Is it a raw physical value reused by governed contracts?

Add/consume a primitive such as `TioSize`, `TioOpacity`, `TioAlpha`, `TioDuration`, or a typography physical registry.

### 2. Is it a reusable semantic role?

Use/add the appropriate foundation, semantic, typography, effects, or domain role.

### 3. Is it a reusable component contract?

Keep the semantic name in the component token class, but alias governed lower-level values.

### 4. Is it truly one-off feature composition data?

Do **not** create a feature token bag solely to hide it. Keep genuinely local runtime/composition data close to its consumer while using governed primitives for any fixed physical values.

Examples of composition/program data that should not be misclassified as geometry tokens include animation intervals, gradient stop positions, flex values, and component-specific ratios/factors when they are not reusable design-system roles.

## Adding a New Token or Role

Before adding anything new:

1. Search the repository for an existing equivalent owner.
2. Confirm whether the value is physical, semantic, component-specific, or runtime/composition data.
3. Reuse existing governed ownership first.
4. Add an exact primitive only when current UI/approved design evidence requires it.
5. Add a semantic/component role only when reuse or intent justifies it.
6. Preserve current rendered values unless the active task explicitly approves a visual change.
7. Add/update focused contract tests.
8. Update this README if the public usage/ownership contract changed.

Do not create near-duplicate token systems to preserve feature ownership.

## Reusable Components First

Feature screens should prefer reusable core UI:

```text
TioButton
TioInput
TioUsernameInputField
TioMobileNumberField
TioCard
TioAvatar
core dialogs/pickers/sheets
```

When a repeated visual/behavior pattern is missing, audit whether the correct fix is a reusable component or reusable variant before adding another screen-local implementation.

Raw Flutter primitives are valid inside reusable core implementations and for rare justified one-off cases.

## Compatibility APIs

The following compatibility surfaces still exist because current feature consumers have not all migrated yet:

```text
context.radiusSmall / radiusMedium / radiusLarge
TioTheme.colors(context)
legacy TioSpacing names (extraSmall/small/medium/large/extraLarge)
legacy TioRadius names (small/medium/large/extraLarge)
TioMotionTokens compatibility facade
```

Do not add new usage of these APIs. New/edited consumers should use canonical contracts. Remove compatibility APIs only after repository-wide zero-reference verification and focused validation.

## Visual Safety

Design-system cleanup is not permission to redesign UI.

By default:

```text
pixels before == pixels after
```

Preserve current colors, typography appearance, component sizes, icon/image sizes, spacing, radius, shadows, and motion unless the active task explicitly approves a visible change.

Numeric similarity is not enough to change a rendered value.

## Tests and Validation

When changing theme/token ownership, add or update the smallest relevant contract/widget tests and run the applicable workspace validation.

Typical repository validation:

```bash
melos bootstrap
melos analyze
melos test
```

For docs-only changes, at minimum ensure the diff is clean (`git diff --check` in a local workflow). Required GitHub CI remains the final source of truth for the branch/PR validation boundary.

## Directory Map

```text
theme/
├── README.md
├── context/
│   └── runtime BuildContext theme accessors
├── tokens/
│   ├── primitive/    exact physical values
│   ├── foundation/   spacing/radius/stroke and foundation roles
│   ├── semantic/     theme-aware semantic colors
│   ├── domain/       shared product-domain semantic roles
│   ├── typography/   font physical registries + semantic typography
│   ├── effects/      motion/shadow contracts and runtime schemes
│   └── components/   reusable component contracts
├── tio_theme_config.dart
├── tio_theme.dart
└── theme.dart
```

Keep this map and the examples above current whenever the theme system evolves.
