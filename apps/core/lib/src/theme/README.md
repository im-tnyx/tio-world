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
TioSelectableCard
TioConfirmationCard
TioAvatar
TioDateCalendar
TioDateTimePickerPopup
TioDateTimeWheelPicker
core reusable dialogs/pickers/sheets
```

`TioButton` is the shared button family for every action in the app. Its variants are semantic intents, not surfaces or features:

```text
primary       the main affirmative action
secondary     the outlined non-destructive action, including Cancel
ghost         the low-emphasis text action
destructive   removes or permanently changes something
```

Feature and sheet code selects an intent. It does not rebuild button chrome locally, and there is no per-surface or per-feature button class.

`TioButton.destructive` is an **outlined** action carrying the `danger` role, not a filled one. It shares the outlined chassis with `secondary`, so `TioButtonTokens` still owns its minimum height, pill radius, horizontal padding, content gap and label typography; only the colour roles differ. The danger colour reaches the foreground, the outline and the pressed/focused/hovered state layer, so the action stays destructive in every state — including while `loading`, where the shared disabled treatment would otherwise grey out a delete in flight. A destructive action that is genuinely `enabled: false` still uses the shared disabled treatment.

No `onDanger` foreground role exists, and this variant deliberately does not add one: an outlined destructive action renders `danger` on the surface beneath it, which is what the destructive actions already shipping do. A filled danger container would need that token and a separate contrast decision.

The variant exposes no radius, height, fill, border-colour or label-size override. Reproducing a historical local button recipe through override parameters is how the drift this family exists to remove becomes representable again.

`TioSocialButton` owns shared provider/mode action presentation for Google, Truecaller, Email, and Phone. Its default constructors retain the full-width provider treatment. `TioSocialButton.round` is the shared compact Auth action variant: a 56dp circular interactive target with a visible label, button semantics, theme-resolved colors, and governed geometry. Features own provider ordering, loading/availability state, and whether Email or Phone is the reciprocal mode action; they should not duplicate the round visual contract or create an Auth-specific token bag.

`TioInlineInfoAction` owns the compact contextual-info treatment used in feature footers: a `12px` `w500` label, `16px` icon, theme-resolved secondary text color, and compact governed padding without the global `TextButton` minimum height. Features provide only the label, optional icon, and callback.

`TioDateCalendar` is the reusable inline date calendar: a compact horizontal date strip and an expandable inline month grid that are two renderings of one caller-controlled `selectedDate`. It has no component-token file, because the component-token admission gate above is not met: it consumes `TioSize`, `TioSpacing`, `TioRadius`, `TioStroke`, `TioOpacity`, `TioFontWeight`, `context.tioColors` and `context.tioMotion` directly. Callers own `selectedDate`, `localToday`, `minDate`/`maxDate` and the resolved first day of week; per-date visuals arrive as a generic `TioDateDecoration` (progress, generic fill, marker count) so core renders presentation values without learning any feature's domain. `onVisibleDateRangeChanged` reports the inclusive seven-day week or calendar month owned by the active pager page, allowing a caller to distinguish selection from viewport without putting feature policy in Core. `progress: null` and `progress: 0` are deliberately different renderings. Do not add domain parameters to it, and do not turn it into a Planning or Progress calendar. `tioOrderedWeekdayLabels` and `tioWeekdayName` are exported beside it. The calendar's own weekday header draws its columns from the first; the second names a single day and is what the Settings first-day-of-week choice labels its options with. Both format from the locale; never hard-code an English weekday string beside them.

`TioDateTimePickerPopup` is an anchored overlay card that leaves its child layout and scroll extent unchanged. `TioDateTimeWheelPicker` is its controlled, theme-adapted wrapper around Flutter's `CupertinoDatePicker(mode: CupertinoDatePickerMode.dateAndTime, use24hFormat: false)`. The native picker owns its unified Date/Hour/Minute/AM-PM drum, natural 12-hour period behavior, and cylindrical perspective; Core adds the behind-text compact selection pill (`TioWheelPickerTokens.compactSelectionHeight`, 44dp) alongside the standard 48dp wheel selection contract, generic bounds, controlled resynchronization, and Android-only selection haptics. A feature owns its anchor, default value, clock freshness, draft lifecycle, persistence, and any domain meaning through `resolveDateTime`. Do not add meal, workout, timezone, storage, or submit behavior to the Core API.

`TioEditorSheet.bottomPadding` defaults to `TioEditorSheetTokens.bottomPadding` (the editor family's compact `12dp` bottom inset) while side and top padding retain their established value. A caller may override it only for a documented surface requirement; do not use negative layout offsets. This editor-surface inset is independent from popup-card internal padding and DateTime wheel selection geometry.

`TioShell` exposes one optional contextual status title. A tab label names a domain while the screen inside it may be one of several, so the composition layer supplies the screen's own name and the tab label stays the fallback. Core never learns which screen a feature is currently showing.

`TioShellStatusTopBar` retains ownership of the shared title and status treatment and exposes two optional generic action slots around it, so the cluster reads `[leadingAction?] [status] [trailingAction?]`. Core does not interpret either action's meaning, own its visibility or state rule, or learn what feature supplied it.

The trailing slot exists for a caller-owned contextual overflow or end action — the affordance a reader expects at the end of the bar. It is a deliberate product placement, not a fallback for a crowded leading slot: a feature that wants an action read as *before* the status uses `leadingAction`, and one that wants the bar's final action uses `trailingAction`. The status keeps a fixed side padding on whichever side has no action and drops the redundant one where an action sits, so two visible icons are never artificially far apart.

Compact-width geometry stays the caller's responsibility. The centre slot is absolutely positioned across the whole bar, so a caller filling both slots must verify that its cluster does not collide with a centred label at small widths, under a large text scale, or with a long localized string. Core does not reserve that space or shrink the cluster; a caller that cannot fit both actions should not use both. The visible status icon remains fixed at the right edge whether the optional action is present or absent. When that action exists, the status drops only its redundant leading padding so the two visible icons are not artificially far apart; right padding remains unchanged.

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

`TioInput.multiline` is the governed notes-field variant for longer free-text entries (health notes, event details, and similar). It uses the evidenced `16dp` rounded-surface radius and a fixed-alpha unfocused border that does not branch on theme brightness — a separate current contract from the generic `14dp` standard field, not a unification of the two. `maxLines`/`minLines` are required, since every current consumer needs its own value; `textCapitalization` defaults to `TextCapitalization.sentences`, matching every current consumer, and stays overridable. Default content padding equals `EdgeInsets.all(TioSpacing.lg)`, matching most current consumers without an override; callers that need a different shape still use the existing `contentPadding` override.

Two capabilities were added specifically to reproduce this variant's evidenced contract without forcing every consumer into identical styling:

- `hintStyle` — overrides the computed hint style entirely when supplied. Different notes fields use genuinely different hint colour/opacity/size today; `standard` and `compactNumber` are unaffected unless a caller opts in.
- `textAlignVertical` — null preserves Flutter's own default; `compactNumber` still always forces centering regardless of this value.

`textInputAction` is nullable so `TioInput.multiline` consumers can omit it entirely and let Flutter's own implicit default apply (`newline` when `keyboardType` is `TextInputType.multiline`, `done` otherwise) — exactly what the raw fields it replaces did before migration. `standard`, `compactNumber`, and `numericEditor` all continue to supply an explicit non-null default and are unaffected by the wider type.

Two details worth knowing before relying on them:

- No `autovalidateMode` is exposed, so a `validator` runs only when an enclosing `Form` asks it to. Exposing the callback adds no validation timing of its own.
- `errorText` still drives the component's error **styling** (border, cursor, label colour). A validator-only error renders its message but not those colours. The first consumer that needs both should carry that change.

The generic `TioInput` contract (14dp radius, 52dp minimum height) and the specialised boxed-field family — `TioUsernameInputField` and `TioMobileNumberField` at 16dp — are both current and are deliberately **not** unified.

### Neutral Settings grouping and rows

`TioGroupCard` is the neutral, **non-selectable** grouping surface for canonical grouped Settings and Nutrition rows. It owns the `surfaceRaised` material, shared radius, clipping, and child ordering while callers compose their own rows and separators. It does not represent selected or unselected state; selection cards remain a separate component contract.

### Anchored popups

`TioAnchoredPopup` is the contract for a floating card that opens beside a control without disturbing it. The content lives in an `OverlayPortal`, so opening one changes nothing about the widget it wraps: a pinned action region keeps its position and its height while the card floats over the body above it. A caller that grows its own footer to hold options is not using this contract.

The caller owns the open flag, the anchor `GlobalKey` and the content. Core owns placement — it prefers the side of the anchor with more room, keeps clear of the status bar, the keyboard and the home indicator, aligns to the anchor's leading edge and clamps itself on screen — and owns dismissal on an outside tap.

Height and width are both intrinsic and capped. The card is anchored by the edge nearest the control, so it grows away from it without anyone having to know its size in advance, and `contentBuilder` is told how much height it may use so long content can scroll inside rather than being clipped. `maximumWidth` keeps a short list from stretching into a band across the screen.

`TioPopupDismissBarrier` is the dismiss layer, and is exposed because two popups anchored to the same strip need it. Its optional `passThrough` rect is cut out of the barrier rather than made transparent, so nothing in the overlay is hit-testable there and the tap lands on the sibling control beneath — which is what makes moving from one card to the other cost one tap instead of two. It presents one dismiss action to assistive technology however many regions it paints, and a caller must only pass a rect through to a control that is actually enabled, or it hands the reader a dead area.

`TioDateTimePickerPopup` is the existing anchored card for date and time. It carries the same optional `passThroughAnchorKey`, defaulting off.

### Selection cards

`TioSelectableCard` is that contract: the canonical card chosen from a set of options. Features supply the content, the current `selected` value, and the action; core owns the selected/unselected appearance and the interactive semantics.

`TioCardTokens` remains the governed appearance contract. The component reads `selectedContainerAlpha`, `selectedBorderWidth`, `unselectedBorderWidth`, `unselectedOutlineAlpha`, `radius`, and `padding` from it, and exposes no override for any of them — a caller that can pass its own outline strength is a caller that can drift again.

Selection is state, not a fill variant, which is why it is a separate component rather than a flag on `TioCard`.

`onTap` is required. An option that cannot be chosen is `enabled: false` — which suppresses the tap, dims the card at `TioOpacity.opacity64`, and reports disabled to assistive technology — so there is one reusable way to be non-interactive rather than two. Padding is fixed at `TioCardTokens.padding`; a surface needing different inner spacing composes it into its own `child`.

Features should not rebuild selection-card `BoxDecoration` locally. Product-specific selection rules, persistence, capability gating, navigation, and analytics remain feature-owned.

Use the public Settings-row family when its demonstrated contract matches instead of recreating the same card/row geometry in a feature:

- `TioSettingsNavigationRow` provides a tappable navigation row with a caller-supplied leading widget, title, supporting text, and optional chevron.
- `TioSettingsLeadingIcon` provides the canonical themed leading-icon treatment for navigation rows.
- `TioSettingsValueRow` provides a tappable label/value editor row. Its value remains caller-composed, it supports an optional annotation and `labelSingleLine` behavior, and callers may use either the built-in edit affordance or a custom trailing widget, never both.
- `TioSettingsValueText` provides the standard right-aligned value presentation for `TioSettingsValueRow`.
- `TioSettingsEditAffordance` provides the standard neutral edit affordance.
- `TioSettingsReadOnlyRow` provides a non-interactive label/value detail row without tap or edit affordances.

Features still own callbacks, navigation, values, keys, domain copy, and intentionally specialised value presentation. Keep a feature-local composition only when its hierarchy or behavior does not match these public contracts.

`showTioRemoveImageConfirmationBottomSheet` is the reusable image-removal confirmation. It owns the sheet shell, copy, close affordance and result semantics (`true` confirm, `false` cancel and close, `null` dismiss), while its Remove and Cancel actions are `TioButton.destructive` and `TioButton.secondary`. `TioRemoveImageSheetTokens` therefore holds shell, copy and icon geometry only; action height, radius, outline, padding and label typography belong to `TioButtonTokens`.

`showTioInformationBottomSheet` is the reusable presenter for standard explanatory/informational content. It owns the modal shell, safe-area handling, close action, icon slot, title/body layout, and governed primary dismiss button. Features supply only the title, message, action label, and optional icon. Do not rebuild a bespoke information sheet when this presenter matches the intent.

`showTioEditorSheet` is the presenter for `TioEditorSheet`, the canonical editable modal. It owns the route-level flags the component depends on — scroll-controlled, no route drag, no Flutter drag handle — and forwards two optional booleans unchanged, both defaulting to Flutter's own `false`:

- `useRootNavigator` — a caller inside a nested navigator, such as a `StatefulShellRoute` branch, passes `true` so the barrier covers the chrome outside that branch instead of leaving an app bar action or the bottom navigation live behind the sheet. Core does not choose this: only the caller knows which navigator its editor belongs above.
- `useSafeArea` — matters more than the name suggests. Left `false`, the route applies `MediaQuery.removePadding(removeTop: true)`, so `TioEditorSheet`'s own `SafeArea` **cannot** bring the top inset back however it is configured, and an editor tall enough to reach the top of a short, split-screen or keyboard-raised viewport puts its handle and title under the status bar or a display cutout. Pass `true` for any editor that can grow that tall. Flutter wraps it as `SafeArea(bottom: false)`, so the component's inner `SafeArea` still owns the bottom and nothing is padded twice.

`TioEditorSheet` keeps its actions pinned below the scroll view, separated by `TioEditorSheetTokens.actionGap`. `flushActions` removes that gap so the action region begins immediately below the body; it defaults to false, so no existing sheet moves. Pass true only when the action region draws its own boundary — a rule across the sheet, for instance — because a gap and a separator say the same thing twice and leave dead space above the line.

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
