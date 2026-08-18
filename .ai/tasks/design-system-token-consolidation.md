# Professional Core Theme & Token System

**Status:** In progress — Slice A is active  
**Primary owner:** `apps/core/lib/src/theme`  
**Consumers:** every Flutter screen/component in `apps/app`, `apps/features/*`, and core UI  
**Reference architecture:** `im-tnyx/Tio-hub` centralized ownership, adapted to Flutter framework mechanics  
**Related issue:** #6  
**Working branch:** `codex/design-system-token-consolidation`  
**Draft PR:** #22

## Purpose

This file is the stable architecture/source-of-truth for the Tio Flutter design-system consolidation. Detailed implementation work lives in slice child tasks and must not turn this parent into a file-by-file implementation diary.

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

Final production must not introduce or retain feature design-token catalogs such as:

```text
WelcomeTokens / WelcomeVisualTokens
WelcomeColorTokens
WelcomeTypographyTokens
WelcomeMotionTokens
AuthTokens
OnboardingTokens
HomeTokens
ProfileTokens
feature-local color/layout/theme bags
```

A truly one-off fixed visual value may consume a governed core primitive/semantic role directly when no reusable role is justified.

## Non-Negotiable Ownership Rules

### One physical owner

Every fixed product-visible physical value has exactly one canonical core owner.

Examples:

```dart
TioSize.dp20
TioSize.dp46
```

Semantic/component APIs describe intent and alias governed lower-level values:

```dart
TioSpacing.large
TioRadius.medium
TioButtonTokens.height
TioInputTokens.minHeight
```

Component token classes are contracts, not independent numeric/color stores.

### Primitive families are concept-specific

Do not put every number into `TioSize`.

Use separate governed families when evidenced:

```text
geometry            → TioSize or equivalent
opacity             → TioOpacity or equivalent
exact integer alpha → TioAlpha or exact tested equivalent when required
fixed duration      → TioDuration / motion primitive
typography scale    → governed typography physical/semantic roles
palette colors      → TioPalette
ratios/factors      → dedicated governed family only if inventory justifies it
```

Do not pre-create arbitrary numeric ranges. Add only exact values evidenced by current production UI or explicitly approved design decisions.

### No silent normalization

Architecture cleanup must preserve exact rendered values.

```text
current = 7dp
existing scale = 8dp

7 → 8                       ❌
add/reuse governed exact 7  ✅
```

The same rule applies to colors, alpha, typography, motion, shadows and fixed ratios.

### Component tokens must not become a dumping ground

```text
Reusable component → component tokens
Reusable semantic role → foundation/semantic/typography/effects
One-off screen visual → governed core primitive/role directly
Screen-specific core token bag → forbidden
```

Removing feature token catalogs does not justify moving every screen's private style values into `tokens/components/`.

### Static vs dynamic Flutter access

Static design contracts are accessed directly:

```dart
TioSize.dp20
TioSpacing.large
TioRadius.small
TioButtonTokens.height
```

Runtime/theme-resolved values use one canonical Flutter context/theme path:

```dart
context.tioColors
context.tioMotion
context.tioShadows
Theme.of(context).textTheme
```

`context/` must not become a replacement static locals layer. Duplicate compatibility APIs may be removed only after zero-reference verification.

## Mandatory Visual Freeze

This program is an ownership/refactor program, not a screen redesign.

**No screen design/UI may change under this task, Issue #6, or PR #22 without a separate explicit owner/design confirmation.**

Without that separate approval, do not change:

- visible colors;
- layout/spacing/gaps;
- radius/shape;
- typography appearance;
- icon/image sizing;
- component geometry;
- gradients/shadows/elevation;
- motion/choreography;
- responsive visual contracts;
- any other product-visible pixel value.

If cleanup reveals a desirable UI improvement or defect, record it separately and preserve the current rendering until approved.

A token refactor that changes visible UI without separate approval is a regression.

## Target Core Structure

```text
apps/core/lib/src/theme/
├── theme.dart
├── tio_theme.dart
├── tio_theme_config.dart
├── context/
│   ├── context.dart
│   └── tio_theme_context.dart
└── tokens/
    ├── tio_tokens.dart
    ├── primitive/
    │   ├── primitive.dart
    │   ├── tio_size.dart
    │   ├── tio_opacity.dart        # only when evidenced
    │   ├── tio_alpha.dart          # only when exact integer alpha is needed
    │   ├── tio_duration.dart       # only when evidenced
    │   └── additional families only when justified
    ├── foundation/
    │   ├── foundation.dart
    │   ├── tio_palette.dart
    │   ├── tio_spacing.dart
    │   ├── tio_radius.dart
    │   ├── tio_icon_size.dart      # when justified
    │   └── tio_stroke.dart         # when justified
    ├── semantic/
    ├── typography/
    ├── effects/
    ├── components/
    └── domain/
```

`builders/` is optional and should be introduced only if `ThemeData` composition materially benefits after ownership cleanup. Do not create files for symmetry alone.

## Current Verified Core Debt

Fresh source audit before Slice A confirmed:

- `primitive/` is not implemented yet;
- `TioSpacing` and `TioRadius` duplicate physical geometry ownership;
- raw geometry/opacity/alpha/typography/color values remain throughout component token files;
- `TioMotion` and `TioMotionTokens` duplicate timing ownership;
- `TioShadowTokens` and `TioShadows` duplicate shadow ownership;
- `TioPalette`, `TioSemanticColors`, `TioDomainColors`, and `TioColors` have overlapping color ownership;
- static `context.radiusSmall/Medium/Large` compatibility getters remain;
- transitional `TioTheme.colors(context)` remains;
- typography physical values are split across core typography and component token classes;
- current tests still lock many values as independent component-owned values rather than primitive + alias ownership.

These findings belong to Slice A implementation detail; future evidence should be recorded in the child task rather than expanding this parent.

## Slice Execution Index

| Slice | Task | Status | Gate |
|---|---|---|---|
| A | [Core Foundation](design-system-slice-a-core-foundation.md) | **In progress** | Current work |
| B | [Welcome Cleanup](design-system-slice-b-welcome.md) | Blocked | Slice A validated |
| C | [Core Components](design-system-slice-c-core-components.md) | Blocked | Slices A–B validated |
| D | [Auth + Account Setup](design-system-slice-d-auth-account.md) | Blocked | Slice C validated |
| E | [Product Onboarding](design-system-slice-e-onboarding.md) | Blocked | Slice D validated |
| F | [Home + Profile + Settings](design-system-slice-f-home-profile-settings.md) | Blocked | Slice E validated |
| G | [Remaining UI](design-system-slice-g-remaining-ui.md) | Blocked | Slice F validated |
| H | [Final Enforcement](design-system-slice-h-final-enforcement.md) | Blocked | Slice G validated |

Cross-cutting color rules live in [Design System Hardcoded Color Audit](design-system-hardcoded-color-audit.md) and apply wherever a slice touches colors, alpha, gradients, shadows or state layers.

## Slice Completion Contract

Each slice follows the same lifecycle:

1. Inventory
2. Classification
3. Planned ownership
4. Implementation
5. Focused tests
6. Static audit
7. Pixel/UI regression check
8. Analyze
9. Full CI where appropriate
10. Update evidence
11. Mark slice `Validated`
12. Unblock the next slice

Do not start the next slice while its dependency remains partial/unvalidated.

## Hard Product Boundaries

This design-system program does not change, unless a separate approved task explicitly says otherwise:

- Auth/session identity architecture;
- Account Setup business flow;
- Product Onboarding sequencing/business rules;
- Supabase schema/data behavior;
- entitlement logic;
- navigation behavior unrelated to styling;
- persistence/domain calculations;
- Settings theme-mode state/persistence responsibility (`AppThemeController` remains app-level, not a duplicate core manager).

Business/math/date/conversion/validation values are not automatically design tokens.

## Testing and Searchability Standard

Tests must preserve both exact product values and ownership relationships.

Example target:

```dart
expect(TioSize.dp14, 14.0);
expect(TioInputTokens.radius, TioSize.dp14);
```

Representative physical values must be searchable from their canonical primitive owner, for example `TioSize.dp20`.

Regex-only numeric bans are insufficient; static audits must classify legitimate business/runtime values separately from fixed visual contracts.

## Definition of Done

The parent task is complete only when Slice H is validated and repository-wide evidence proves:

- every fixed product-visible physical value has one canonical core owner;
- primitive registries contain evidenced/approved values only;
- foundation/semantic/typography/effects/component contracts compose governed ownership;
- no feature-owned design-token/color/layout/theme catalog remains;
- no screen-specific token bag is hidden in core components;
- canonical dynamic Flutter theme access has no duplicate equivalent API;
- no unexplained production visual literal remains after classification;
- no visible UI change occurred without separate explicit approval;
- relevant focused tests, Flutter/Dart analyze and full workspace CI pass;
- Issue #6 and Draft PR #22 reflect the validated final state.

## Tracking

- GitHub Issue: #6
- Draft PR: #22
- Cross-cutting color audit: `.ai/tasks/design-system-hardcoded-color-audit.md`
- Current execution task: `.ai/tasks/design-system-slice-a-core-foundation.md`

Historical comments/task text that conflict with this parent architecture are superseded by this parent contract plus the currently active child slice, while verified pixel/product guardrails remain preserved.
