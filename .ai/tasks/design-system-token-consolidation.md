# Professional Core Theme & Token System

**Status:** In progress — Slices A–E validated; Slice F is ready  
**Primary owner:** `apps/core/lib/src/theme`  
**Consumers:** every Flutter screen/component in `apps/app`, `apps/features/*`, core UI, and Wear where applicable  
**Reference architecture:** `im-tnyx/Tio-hub` centralized ownership, adapted to Flutter framework mechanics  
**Related issue:** #6  
**Working branch:** `codex/design-system-token-consolidation`  
**Draft PR:** #22

## Purpose

This file is the stable architecture/source-of-truth for Tio Flutter design-system consolidation. Detailed implementation evidence belongs in slice child tasks.

## Canonical Architecture

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

There is **no feature composition token layer** in the final architecture.

Feature-local design token catalogs such as `WelcomeTokens`, `AuthTokens`, `OnboardingTokens`, screen-specific color/layout/theme bags, or equivalent systems are forbidden final-state architecture.

## One Physical Owner

Every fixed product-visible physical value has exactly one canonical core owner.

```dart
TioSize.dp20
TioSize.dp46
```

Semantic/component APIs describe intent and alias governed lower-level values:

```dart
TioSpacing.sm
TioRadius.lg
TioButtonTokens.height
TioInputTokens.minHeight
TioAvatarTokens.largeSize
```

Component token classes are semantic contracts, not independent physical-value stores.

For reusable component size contracts, the component keeps the semantic role while `TioSize` owns the number:

```dart
TioAvatarTokens.compactSize    = TioSize.dp24;
TioAvatarTokens.smallSize      = TioSize.dp36;
TioAvatarTokens.mediumSize     = TioSize.dp48;
TioAvatarTokens.largeSize      = TioSize.dp100;
TioAvatarTokens.extraLargeSize = TioSize.dp160;
```

The same ownership pattern applies to other reusable component geometry when those contracts are migrated.

## Primitive Families Are Concept-Specific

```text
geometry            → TioSize
opacity             → TioOpacity
exact integer alpha → TioAlpha
fixed duration      → TioDuration / governed motion primitive
typography           → governed typography physical/semantic roles
palette colors      → TioPalette
ratios/factors      → dedicated governed family only when evidence justifies it
```

Do not force typography, opacity, duration, ratios, or other unrelated numeric concepts into `TioSize` merely because they are numbers.

## Scalable Geometry Foundation

### TioSize

`TioSize` is a numeric physical geometry registry, not a semantic size scale. It must include exact fixed geometry values evidenced by current production UI or explicitly approved design decisions.

It must **not** be capped by the number of semantic `TioSpacing` or `TioRadius` roles.

Do not generate arbitrary unused ranges. Add exact values when product code/design evidence proves they are needed.

A primitive may remain while another semantic category still uses it. Remove an audited primitive only after zero-reference verification proves it is no longer needed.

### TioSpacing

Canonical reusable spacing scale:

```text
none → TioSize.dp0
xxs  → TioSize.dp2
xs   → TioSize.dp4
sm   → TioSize.dp8
md   → TioSize.dp12
lg   → TioSize.dp16
xl   → TioSize.dp24
xxl  → TioSize.dp32
```

The previous `extraSmall/small/medium/large/extraLarge` names are transitional compatibility aliases only and must not limit future scale growth.

### TioRadius

Canonical reusable radius scale:

```text
none → TioSize.dp0
xs   → TioSize.dp4
sm   → TioSize.dp8
md   → TioSize.dp12
lg   → TioSize.dp16
xl   → TioSize.dp24
full → TioSize.dp999
```

`full` is a radius/shape semantic, not a spacing semantic. Previous `small/medium/large/extraLarge` names remain temporary compatibility aliases during migration.

### Category Independence

Semantic families are independent. Do not force identical label-to-value mappings across categories for symmetry.

```text
TioSpacing.xs  may be 4dp
TioRadius.xs   may be 4dp
TioIconSize.xs may later be 16dp
```

`TioIconSize` and `TioStroke` should be introduced only when reusable roles are evidenced by the component audit.

## Controlled Semantic Normalization

The earlier rule that every existing spacing/radius value must remain numerically exact during token migration is superseded by this explicitly approved normalization rule.

When migrating a **spacing or radius** value to the canonical semantic scale, a value that is exactly `1dp` away from the intended reusable role may be normalized to that role when semantic intent is clear.

Approved examples:

```text
5dp spacing → TioSpacing.xs → 4dp   ✅
7dp spacing → TioSpacing.sm → 8dp   ✅
```

Rules:

- normalization is limited to `±1dp`;
- it applies only to spacing/radius migration into a clearly matching canonical semantic role;
- record every normalization in the active slice evidence;
- do not create `TioSpacing` roles such as `5dp` or `7dp` merely to preserve near-duplicate spacing;
- do not delete `TioSize.dp5` or another primitive if another legitimate geometry contract still uses it;
- if the difference is greater than `1dp`, semantic intent is ambiguous, or the value belongs to another category, preserve the current value unless separately approved.

This approval does **not** automatically normalize component heights, Avatar sizes, icon/image sizes, typography, colors, alpha, shadows, motion, responsive ratios, or unrelated geometry.

## Component Ownership Rule

```text
Reusable component     → semantic component tokens alias governed primitives/roles
Reusable semantic role → foundation/semantic/typography/effects
One-off screen visual  → governed core primitive/role directly
Screen-specific bag    → forbidden
```

Removing feature token catalogs does not justify moving each screen's private style values into `tokens/components/`.

## Static vs Dynamic Flutter Access

Static design contracts are accessed directly:

```dart
TioSize.dp20
TioSpacing.lg
TioRadius.sm
TioButtonTokens.height
```

Runtime/theme-resolved values use Flutter context/theme mechanisms:

```dart
context.tioColors
context.tioMotion
context.tioShadows
Theme.of(context).textTheme
```

`context/` must not become a wrapper layer for static tokens. Compatibility APIs are removed only after zero-reference verification.

## Visual Governance

This program is an ownership/refactor program, not a general screen redesign.

**No screen design/UI may change under this task, Issue #6, or PR #22 without explicit approval, except the controlled `±1dp` spacing/radius normalization approved above.**

Without another explicit approval, do not change visible colors, typography appearance, Avatar/component sizes, icon/image sizing, component heights/widths, shadows/elevation, motion/choreography, responsive visual contracts, or other product-visible values outside that narrow normalization rule.

## Target Core Structure

```text
apps/core/lib/src/theme/
├── theme.dart
├── tio_theme.dart
├── tio_theme_config.dart
├── context/
└── tokens/
    ├── tio_tokens.dart
    ├── primitive/
    │   ├── primitive.dart
    │   ├── tio_size.dart
    │   ├── tio_opacity.dart
    │   ├── tio_alpha.dart
    │   ├── tio_duration.dart
    │   └── additional justified primitive families only
    ├── foundation/
    │   ├── foundation.dart
    │   ├── tio_palette.dart
    │   ├── tio_spacing.dart
    │   ├── tio_radius.dart
    │   ├── tio_icon_size.dart      # when reusable roles are proven
    │   └── tio_stroke.dart
    ├── semantic/
    ├── typography/
    ├── effects/
    ├── components/
    └── domain/
```

## Slice Execution Index

| Slice | Task | Status | Gate |
|---|---|---|---|
| A | [Core Foundation](design-system-slice-a-core-foundation.md) | **Validated** | Flutter CI #624 |
| B | [Welcome Cleanup](design-system-slice-b-welcome.md) | **Validated** | Flutter CI #646 |
| C | [Core Components](design-system-slice-c-core-components.md) | **Validated** | Flutter CI #710 |
| D | [Auth + Account Setup](design-system-slice-d-auth-account.md) | **Validated** | Flutter CI #742 |
| E | [Product Onboarding](design-system-slice-e-onboarding.md) | **Validated** | Flutter CI #825 |
| F | [Home + Profile + Settings](design-system-slice-f-home-profile-settings.md) | **Ready** | Current next slice |
| G | [Remaining UI](design-system-slice-g-remaining-ui.md) | Blocked | Slice F validated |
| H | [Final Enforcement](design-system-slice-h-final-enforcement.md) | Blocked | Slice G validated |

Cross-cutting color rules live in `design-system-hardcoded-color-audit.md`.

## Slice Completion Contract

Each slice follows inventory → classification → planned ownership → implementation → focused tests → static audit → visual regression/approved-normalization review → analyze → required CI → evidence update → validation → next-slice unblock.

Do not start a blocked slice while its dependency remains partial/unvalidated.

## Hard Product Boundaries

This program does not change Auth/session identity architecture, Account Setup business flow, Product Onboarding sequencing, Supabase schema/data behavior, entitlement logic, unrelated navigation/persistence/domain calculations, or app-level theme-selection persistence responsibility (`AppThemeController`).

## Testing and Searchability Standard

Tests must preserve canonical physical ownership and approved semantic relationships.

```dart
expect(TioSize.dp14, 14.0);
expect(TioInputTokens.radius, TioSize.dp14);
expect(TioAvatarTokens.largeSize, TioSize.dp100);
```

Where controlled normalization is applied, tests should lock the canonical target relationship rather than the retired near-duplicate spacing/radius literal.

## Definition of Done

The parent task is complete only when Slice H is validated and repository-wide evidence proves:

- every fixed product-visible physical value has one canonical core owner;
- primitive registries contain evidenced/approved values only;
- semantic scales are scalable and not artificially capped by legacy role counts;
- approved `±1dp` spacing/radius normalizations are documented and intentional;
- reusable component geometry contracts alias canonical primitives/roles instead of owning raw numbers;
- no feature-owned design-token/color/layout/theme catalog remains;
- no screen-specific token bag is hidden in core components;
- canonical dynamic Flutter theme access has no duplicate equivalent API;
- no unexplained production visual literal remains after classification;
- no visible UI change occurred outside separately approved decisions, including the controlled normalization rule;
- focused tests, analyze, and required CI pass;
- Issue #6 and Draft PR #22 reflect the validated final state.

## Tracking

- GitHub Issue: #6
- Draft PR: #22
- Cross-cutting color audit: `.ai/tasks/design-system-hardcoded-color-audit.md`
- Current execution task: `.ai/tasks/design-system-slice-f-home-profile-settings.md`
