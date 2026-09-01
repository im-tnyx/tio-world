# Tio Core Theme and Design System

This directory is the canonical usage and implementation boundary for Tio's shared Flutter theme, design tokens, typography, runtime theme extensions, effects, and reusable component visual contracts.

**Read this file before changing Flutter UI in `apps/core` or any feature package.** Normal feature UI work should not begin by crawling `tokens/**` files.

## Feature UI Quick Start

Use the public core boundary:

```dart
import 'package:tio_core/core.dart';
```

Prefer this order:

```text
Existing reusable core component
        ↓
Existing semantic/component role documented here
        ↓
Existing exact governed primitive
        ↓
Inspect core internals only if this README cannot answer the ownership question
```

Common static lookup:

```text
Spacing: none=0, xxs=2, xs=4, sm=8, md=12, lg=16, xl=24, xxl=32
Radius:  none=0, xs=4, sm=8, md=12, lg=16, xl=24, full=999
Exact geometry: TioSize.dpN
Stroke: TioStroke
Elevation: TioElevation
Typography: TioFontSize / TioFontWeight / TioLetterSpacing / TioLineHeight
```

Common runtime lookup:

```dart
final colors = context.tioColors;
final motion = context.tioMotion;
final shadows = context.tioShadows;
final textTheme = Theme.of(context).textTheme;
```

Prefer reusable core UI such as `TioButton`, `TioSocialButton`, `TioInlineInfoAction`, `TioInput`, `TioUsernameInputField`, `TioMobileNumberField`, `TioCard`, `TioConfirmationCard`, `TioGroupCard`, the `TioSettings*` row family, `TioAvatar`, and shared dialogs/pickers/sheets before rebuilding the same contract in a feature.

A normal feature edit should not require opening internal token source. Inspect `apps/core/lib/src/theme/tokens/**` only when a documented role is missing/ambiguous, runtime source and this README disagree, or the task intentionally changes the core design-system contract.

## Maintenance Contract

This README is part of the design-system contract.

Update it in the **same change/PR** when adding, removing, renaming, or materially changing:

- token categories or ownership rules;
- public theme/context APIs;
- spacing, radius, stroke, typography, color, motion, elevation or shadow contracts;
- reusable component contracts;
- `TioThemeConfig` behavior;
- runtime-selectable font behavior;
- compatibility/deprecation guidance;
- the recommended feature-consumption flow.

If runtime source and this README disagree, runtime source is authoritative for current behavior, but the documentation must be corrected before the design-system task is complete.

## Public Entry Point

Feature packages should normally import:

```dart
import 'package:tio_core/core.dart';
```

The internal theme barrel is:

```text
apps/core/lib/src/theme/theme.dart
```

It exports runtime context helpers, `TioTheme`, `TioThemeConfig`, and governed token families.

## Ownership Hierarchy

```text
Primitive physical values
        ↓
Foundation / semantic / typography / effects roles
        ↓
Reusable component contracts (only when genuinely useful)
        ↓
Reusable core components
        ↓
Feature screens/widgets
```

Core invariant:

> Every fixed product-visible physical value has one canonical owner. Upper layers alias governed lower-level values instead of independently redefining the same number, color, duration, or typography value.

Feature/screen/workflow token bags such as `WelcomeTokens`, `AuthTokens`, `ProfileTokens`, or `DeleteAccountDialogTokens` are not valid final architecture.

## Component-Token Admission Gate

**Do not create one token file per widget, dialog, sheet, screen, or product action.** A file under `tokens/components/` exists only for a proven reusable component contract.

A new or retained component-token class must pass all of these checks:

1. The owning UI is genuinely reusable, not a single product screen/workflow disguised as a component.
2. The class expresses a stable reusable visual contract that adds value beyond directly calling existing primitives/semantic roles.
3. Reuse is evidenced by multiple contexts/consumers or a clearly generic API with independent use cases.
4. The class name describes reusable component capability, not a feature, screen, workflow, or product action.
5. Physical values alias governed lower-level owners; the class is never a second physical registry.
6. If these checks fail, **do not create a token file**. Keep the composition with its owner and consume governed core values directly.

Examples:

```text
TioButtonTokens             ✅ reusable button contract
TioInputTokens              ✅ reusable input-family contract
TioOtpDialogTokens          ✅ reusable email/phone/reset verification dialog
WelcomeTokens               ❌ feature token bag
ProfileTokens               ❌ feature token bag
DeleteAccountDialogTokens   ❌ single destructive product workflow
```

A reusable widget does not automatically need a token class. Small/simple components may directly consume `TioSize`, `TioSpacing`, `TioRadius`, `TioStroke`, typography registries, and runtime semantic roles when a separate component-token facade adds no useful contract.

Likewise, a product-specific workflow living under core does not become a design-system component merely by giving it a token class.

## Token Families

### Primitive physical values

Lowest-level exact-value registries:

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

Do not add arbitrary values “just in case”. A new primitive must be evidenced by current UI or an approved design decision.

### Foundation geometry

Use semantic geometry when the role honestly matches:

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

If a fixed value has no matching semantic spacing/radius role, preserve it exactly with `TioSize` instead of forcing a nearby scale value.

```dart
const EdgeInsets.symmetric(horizontal: TioSize.dp20);
```

Do not normalize `20` to `16` or `24` merely to use `TioSpacing`.

### Colors

Theme-aware UI resolves runtime semantic colors:

```dart
final colors = context.tioColors;

Container(color: colors.surface);
Text('Title', style: TextStyle(color: colors.textPrimary));
```

`Theme.of(context).colorScheme` is also valid when the Material semantic role is appropriate.

Media/image compositions use runtime media roles:

```dart
Container(color: colors.mediaBackground);
Text('Hero', style: TextStyle(color: colors.onMediaPrimary));
Text('Supporting', style: TextStyle(color: colors.onMediaSecondary));
```

`mediaBackground`, `onMediaPrimary`, and `onMediaSecondary` are owned by the active `TioColors` light/dark/OLED scheme. Current mappings preserve existing pixels while allowing modes to diverge centrally later.

`TioPalette` is the physical color registry. Features should not normally consume palette colors directly.

Prefer:

```dart
context.tioColors
Theme.of(context).colorScheme
```

Avoid repeated feature-level `Color(0xFF...)` literals or direct palette access when a semantic role exists.

A rare audited one-off fixed color with no honest reusable semantic role may use its governed `TioPalette` owner directly rather than creating a feature color-token bag. Preserve byte-exact alpha through `TioAlpha`/palette ownership when required.

`Colors.transparent` may remain where transparency itself is framework/composition behavior rather than a product color role.

### Typography

Prefer semantic Flutter text roles:

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

A truly one-off typography composition may combine governed physical typography values at the consumer. Do not create a feature typography catalog to hide it.

Fractional evidenced sizes use explicit identifiers such as `TioFontSize.size9_5` and `TioFontSize.size10_5`.

#### Runtime font selection

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

The default remains the platform/system font. A font becomes selectable only after cross-platform availability is verified, normally through bundled/registered assets. An evidenced named family such as Roboto may exist without becoming a Settings option.

Do not add per-screen font-family switches.

### Motion

Use the runtime motion scheme:

```dart
duration: context.tioMotion.slow,
```

`TioDuration` owns physical durations, `TioMotion` semantic motion roles, and `TioMotionScheme` runtime/reduced-motion resolution.

Animation interval positions, progress factors, gradient stops, flex values, and component-specific ratios are not motion/geometry tokens merely because they are numeric.

Behavior timing is not automatically motion. Input debounce or destructive hold duration may remain component/domain behavior.

### Elevation

Repeated semantic elevation roles belong to `TioElevation`:

```dart
AppBar(elevation: TioElevation.none);
```

`TioElevation.none` is the canonical shared zero-elevation role. Add further roles only after real repeated evidence; do not create a speculative scale.

### Shadows

Theme-aware effects use:

```dart
final shadows = context.tioShadows;
```

Static reusable shadow contracts live under effects; runtime mode-specific resolution belongs to `TioShadows`.

### Domain semantic colors

`TioDomainColors` owns product-domain color semantics only when the role is genuinely shared across features.

### Reusable component tokens

Current component-token families are intentionally limited to reusable contracts that passed the admission gate, including Button, Input, Card, Avatar, Navigation, shared picker/sheet contracts, Legal, and reusable OTP verification.

Physical values must alias governed lower layers:

```dart
class TioButtonTokens {
  static const height = TioSize.dp46;
  static const radius = TioRadius.full;
  static const outlineWidth = TioStroke.width1;
}
```

A feature should prefer the reusable component itself rather than copying its token contract.

## Static vs Runtime Values

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
TioElevation.none
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

Do not wrap static tokens in `BuildContext` merely for convenience.

## Choosing the Correct Owner

Before adding a visual value:

1. **Raw physical value reused by governed contracts?** Use/add the appropriate primitive.
2. **Reusable semantic role?** Use/add foundation, semantic, typography, effects, or domain ownership.
3. **Proven reusable component contract?** Use a component token class only if it passes the admission gate.
4. **One-off composition/program data?** Keep it close to the consumer while fixed physical values use governed core owners.

Local composition/program data includes animation intervals, gradient stops, flex values, mathematical construction coefficients, and component-specific ratios/factors when they are not reusable design-system roles.

## Adding a New Token or Role

Before adding anything new:

1. Search for an existing equivalent owner.
2. Classify the value as physical, semantic, reusable-component, runtime, behavior/domain, or local composition data.
3. Reuse existing governed ownership first.
4. Add an exact primitive only when current UI/approved evidence requires it.
5. Add a semantic/component role only when reuse and intent justify it.
6. Apply the component-token admission gate before creating anything under `tokens/components/`.
7. Preserve current rendered values unless the active task explicitly approves a visual change.
8. Add/update the smallest relevant tests.
9. Update this README when the public usage/ownership contract changes.

Do not create near-duplicate token systems or per-screen token bags.

## Reusable Components First

Prefer:

```text
TioButton
TioSocialButton
TioInlineInfoAction
TioInput
TioUsernameInputField
TioMobileNumberField
TioCard
TioConfirmationCard
TioAvatar
core reusable dialogs/pickers/sheets
```

`TioSocialButton` owns shared provider/mode action presentation for Google, Truecaller, Email, and Phone. Its default constructors retain the full-width provider treatment. `TioSocialButton.round` is the shared compact Auth action variant: a 56dp circular interactive target with a visible label, button semantics, theme-resolved colors, and governed geometry. Features own provider ordering, loading/availability state, and whether Email or Phone is the reciprocal mode action; they should not duplicate the round visual contract or create an Auth-specific token bag.

`TioInlineInfoAction` owns the compact contextual-info treatment used in feature footers: a `12px` `w500` label, `16px` icon, theme-resolved secondary text color, and compact governed padding without the global `TextButton` minimum height. Features provide only the label, optional icon, and callback.

`TioConfirmationCard` is the generic themed confirm/cancel card composition. Product-specific copy, consequences, persistence, and navigation remain feature-owned. Present the card through the surface that fits the workflow, such as a modal sheet, rather than creating a product-action-specific dialog/token bag.

### Editable field capabilities

`TioInput` is the generic editable field. Alongside the label/hint/error, leading/trailing, focus, controller and line-count options it already owned, it now forwards five optional capabilities to the underlying field:

- `validator` — form validation callback
- `autofillHints` — platform autofill hints
- `inputFormatters` — input formatter list
- `textCapitalization` — defaults to `TextCapitalization.none`
- `suffixText` — static text after the input, such as a unit

These are **plumbing only**. Features own the validation rules, the formatter list, which autofill hints apply, the capitalisation choice, and any suffix content. Core adds no formatter, no validation rule, and attaches no unit or domain meaning to suffix text.

No matching prefix parameter is exposed. No editable-field consumer needs one, and this component does not ship API ahead of evidence.

Every one is optional and omitting it preserves current behaviour, so the default `TioInput` appearance is unchanged.

`TioInput.numericEditor` is the governed dense exact-value editor variant. It remains left-aligned, uses a decimal keyboard and Done action by default, does not select all on focus, and retains the dense `InputDecoration` defaults used by exact-value editors while the active theme supplies fill, border, radius, and padding. It owns only the reusable `18px` bold value, `18px` regular hint, and `15px` secondary suffix hierarchy. Features still own formatter rules, validation, unit content, controller state, and submit behavior. This is separate from the centered, underline-oriented `compactNumber` table-input contract; neither variant changes the generic standard input's `14dp`/`52dp` contract.

Two details worth knowing before relying on them:

- No `autovalidateMode` is exposed, so a `validator` runs only when an enclosing `Form` asks it to. Exposing the callback adds no validation timing of its own.
- `errorText` still drives the component's error **styling** (border, cursor, label colour). A validator-only error renders its message but not those colours. The first consumer that needs both should carry that change.

The generic `TioInput` contract (14dp radius, 52dp minimum height) and the specialised boxed-field family — `TioUsernameInputField` and `TioMobileNumberField` at 16dp — are both current and are deliberately **not** unified.

### Neutral Settings grouping and rows

`TioGroupCard` is the neutral, **non-selectable** grouping surface for canonical grouped Settings and Nutrition rows. It owns the `surfaceRaised` material, shared radius, clipping, and child ordering while callers compose their own rows and separators. It does not represent selected or unselected state; selection cards remain a separate component contract.

Use the public Settings-row family when its demonstrated contract matches instead of recreating the same card/row geometry in a feature:

- `TioSettingsNavigationRow` provides a tappable navigation row with a caller-supplied leading widget, title, supporting text, and optional chevron.
- `TioSettingsLeadingIcon` provides the canonical themed leading-icon treatment for navigation rows.
- `TioSettingsValueRow` provides a tappable label/value editor row. Its value remains caller-composed, it supports an optional annotation and `labelSingleLine` behavior, and callers may use either the built-in edit affordance or a custom trailing widget, never both.
- `TioSettingsValueText` provides the standard right-aligned value presentation for `TioSettingsValueRow`.
- `TioSettingsEditAffordance` provides the standard neutral edit affordance.
- `TioSettingsReadOnlyRow` provides a non-interactive label/value detail row without tap or edit affordances.

Features still own callbacks, navigation, values, keys, domain copy, and intentionally specialised value presentation. Keep a feature-local composition only when its hierarchy or behavior does not match these public contracts.

`showTioInformationBottomSheet` is the reusable presenter for standard explanatory/informational content. It owns the modal shell, safe-area handling, close action, icon slot, title/body layout, and governed primary dismiss button. Features supply only the title, message, action label, and optional icon. Do not rebuild a bespoke information sheet when this presenter matches the intent.

`showTioConfirmationBottomSheet` is the reusable presenter for confirm/cancel decisions. It owns the modal shell, safe-area handling, and `TioConfirmationCard` composition. Features supply only the title, message, confirm/cancel labels, and optional icon widget. Do not rebuild a bespoke confirmation sheet when this presenter matches the intent.

When a repeated pattern is missing, first ask whether the correct fix is an existing component, reusable variant, or direct governed primitives—not another token file.

Raw Flutter primitives are valid inside reusable core implementations and rare justified one-off cases.

## Compatibility APIs

Temporary compatibility surfaces remain while live feature consumers migrate:

```text
context.radiusSmall / radiusMedium / radiusLarge
TioTheme.colors(context)
legacy TioSpacing names (extraSmall/small/medium/large/extraLarge)
legacy TioRadius names (small/medium/large/extraLarge)
TioMotionTokens compatibility facade
```

Do not add new usage. Remove compatibility APIs only after repository-wide zero-reference verification and focused validation.

## Visual Safety

Design-system cleanup is not permission to redesign UI.

```text
pixels before == pixels after
```

Preserve colors, typography appearance, component sizes, icon/image sizes, spacing, radius, shadows and motion unless the active task explicitly approves a visible change. Numeric similarity alone never authorizes a rendered-value change.

## Tests and Validation

For theme/token ownership changes, update the smallest relevant contract/widget tests and run applicable workspace validation:

```bash
melos bootstrap
melos analyze
melos test
```

Required GitHub CI is the final source of truth for source validation boundaries.

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
│   ├── effects/      motion/elevation/shadow contracts and runtime schemes
│   └── components/   admitted reusable component contracts only
├── tio_theme_config.dart
├── tio_theme.dart
└── theme.dart
```

Keep this map and the rules above current whenever the theme system evolves.
