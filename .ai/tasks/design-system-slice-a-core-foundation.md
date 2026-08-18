# Design System Slice A — Core Foundation

**Status:** In progress  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`  
**Scope:** `apps/core/lib/src/theme/**`, `apps/core/test/theme/**`

## Outcome

Establish one canonical core owner for every fixed visual primitive used by the current theme/token system before any feature migration continues.

This slice changes ownership and architecture only. It does not redesign screens.

## Mandatory Visual Freeze

Without separate explicit owner/design approval:

- no layout or spacing changes;
- no visible color changes;
- no typography appearance changes;
- no radius/shape changes;
- no icon/image sizing changes;
- no motion/choreography changes;
- no component geometry changes;
- no screen redesign.

Current rendered values must remain exact. Do not normalize a value to the nearest scale value. If current UI uses `7dp`, preserve `7dp` through governed ownership rather than changing it to `8dp`.

## Hard Boundaries

This slice must not migrate Welcome, Auth, Account Setup, Onboarding, Home, Profile, Settings, or other feature screens.

It must not change auth/session behavior, navigation behavior, persistence, Supabase behavior, business logic, or product flow.

## Architecture Contract

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

There is no feature composition token layer.

Component token classes are semantic contracts, not independent numeric/color stores. Screen-specific token bags must not be moved into `core/components` merely to avoid feature-local tokens.

## Verified Starting Debt

Current source audit identified these concrete debts:

- `primitive/` did not exist before Slice A implementation began;
- `TioSpacing` and `TioRadius` independently owned overlapping raw geometry values;
- component token files contain raw geometry, opacity, alpha, typography and color values;
- `TioMotion` and `TioMotionTokens` duplicate `150/250/400ms` ownership;
- `TioShadowTokens.soft` and `TioShadows.standard.soft` duplicate the same shadow contract;
- `TioPalette`, `TioSemanticColors`, `TioDomainColors`, and `TioColors` have overlapping color ownership;
- `context.radiusSmall`, `context.radiusMedium`, and `context.radiusLarge` are static compatibility accessors in the dynamic context API;
- `TioTheme.colors(context)` remains a transitional duplicate of `context.tioColors`;
- typography physical values are split between `TioTypography` and multiple component token classes;
- integer alpha values such as `25`, `40`, `50`, `80`, `120`, `200`, `245` coexist with normalized opacity values and must not be rounded during migration;
- fixed ratios/factors such as avatar sizing factors and wheel-picker perspective/diameter values require classification;
- current contract tests still lock many values as "component-owned" instead of locking canonical primitive + alias ownership.

## Implementation Checklist

### A1 — Inventory and classification

- [x] Inventory every raw fixed visual scalar/color/duration/factor under `apps/core/lib/src/theme/tokens/**`.
- [x] Classify each as geometry, opacity, exact integer alpha, duration, typography, palette color, effect/shadow, factor/ratio, semantic role, reusable component role, or genuine non-design/runtime value.
- [x] Record exact current values before edits.

### A2 — Primitive geometry

- [x] Create `tokens/primitive/primitive.dart`.
- [x] Create canonical `TioSize`.
- [x] Add only evidenced production values, not an arbitrary integer range.
- [x] Alias `TioSpacing` raw values to geometry primitives.
- [x] Alias `TioRadius` raw values to geometry primitives.
- [ ] Add `TioIconSize` and/or `TioStroke` only when reusable roles are evidenced during the component audit.

### A3 — Opacity and exact alpha

- [ ] Decide canonical ownership for normalized opacity values.
- [ ] Preserve exact 0–255 alpha contracts when used by APIs that depend on integer alpha.
- [ ] Do not silently convert `25/255` to rounded `0.10` or otherwise change rendered color.
- [ ] Add `TioOpacity`, `TioAlpha`, or equivalent families only if the inventory proves they are needed.

### A4 — Motion and duration

- [ ] Establish one canonical fixed-duration owner such as `TioDuration` or an equivalent motion primitive.
- [ ] Remove duplicate physical ownership between `TioMotion` and `TioMotionTokens`.
- [ ] Keep `TioMotionScheme` as the runtime/reduced-motion-resolved scheme.
- [ ] Preserve all current timings exactly.

### A5 — Shadows/effects

- [ ] Resolve duplicate ownership between `TioShadowTokens` and `TioShadows`.
- [ ] Keep one physical shadow definition and let runtime/theme-resolved contracts reference it.
- [ ] Preserve blur, offset, spread and color values exactly.

### A6 — Colors

- [ ] Audit `TioPalette`, `TioColors`, `TioSemanticColors`, and `TioDomainColors` as one ownership graph.
- [ ] Ensure raw physical colors have one core primitive owner.
- [ ] Keep dynamic light/dark/OLED/high-contrast semantic resolution in `TioColors` where appropriate.
- [ ] Retain `TioDomainColors` only if it has a distinct non-duplicate contract.
- [ ] Remove duplicate raw color definitions without recoloring any screen.
- [ ] Apply `.ai/tasks/design-system-hardcoded-color-audit.md` rules.

### A7 — Typography

- [ ] Inventory `fontSize`, `fontWeight`, `fontFamily`, line height, letter spacing, decoration, and relevant font style contracts.
- [ ] Keep typography physical ownership separate from `TioSize`.
- [ ] Introduce a governed type scale only if evidence supports it.
- [ ] Prefer semantic `TextTheme` roles for screen consumption.
- [ ] Preserve every current rendered typography value.

### A8 — Component-token audit

- [ ] Audit every file under `tokens/components/`, not only Button/Input.
- [ ] Migrate raw physical values to primitive/foundation/semantic/typography/effects ownership.
- [ ] Keep component token classes only when they represent reusable component contracts.
- [ ] Do not create screen-specific core token bags.
- [ ] Reclassify oversized bags such as dialog/surface-specific collections instead of automatically preserving them.

Decision rule:

```text
Reusable component → component tokens
Reusable semantic role → foundation/semantic/typography/effects
One-off screen visual → governed core primitive/role directly
Screen-specific token bag → forbidden
```

### A9 — Context and compatibility APIs

- [ ] Keep `context.tioColors`, `context.tioMotion`, and `context.tioShadows` as canonical dynamic accessors.
- [ ] Migrate consumers of `context.radiusSmall/Medium/Large` and remove those getters after zero-reference verification.
- [ ] Migrate `TioTheme.colors(context)` consumers to `context.tioColors` package-by-package and remove only after zero-reference verification.
- [ ] Do not turn `context/` into a wrapper layer for static tokens.

### A10 — Exports and tests

- [x] Export the new primitive barrel intentionally through `tio_tokens.dart`.
- [ ] Remove obsolete duplicate public exports only after consumer search.
- [x] Add primitive geometry contract tests.
- [x] Add alias tests for the migrated foundation relationships.
- [ ] Update remaining component alias tests as component values migrate to primitives.
- [x] Preserve existing runtime-value assertions that protect current pixels.
- [ ] Run focused core theme tests.
- [ ] Run Flutter/Dart analyze.
- [ ] Run full workspace CI at the slice boundary.

## A1 Inventory Evidence

The token tree audited before the first implementation edit was Git tree `9cdf0ec103e766b582466f4f4ee0f9ad058457a0`. The audit covered every source file under `apps/core/lib/src/theme/tokens/**`.

### Geometry / stroke values

Current core token files evidence fixed geometry/stroke values including:

```text
0, 0.75, 1, 1.25, 1.5, 2, 2.5, 3, 4, 5, 6,
8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 27, 28,
30, 32, 36, 38, 44, 46, 48, 52, 54, 56, 62, 64,
72, 100, 125, 140, 160, 200, 999
```

The first bounded A2 implementation intentionally centralizes only the already-proven foundation physical contracts `4/8/12/16/24/999`. Component-specific values will be added to `TioSize` only when their owners are migrated, rather than pre-populating a speculative numeric catalog.

### Normalized opacity values

Current token contracts include normalized opacity/state values such as:

```text
0.08, 0.09, 0.10, 0.12, 0.14, 0.16, 0.30, 0.35,
0.38, 0.40, 0.45, 0.50, 0.60, 0.70, 0.72
```

A3 remains pending; these values have not been normalized or changed.

### Exact integer alpha values

Current APIs also use exact 0–255 alpha contracts including:

```text
25, 30, 35, 40, 50, 80, 90, 120, 200, 245
```

These are classified separately from normalized opacity so conversion cannot introduce rounding/pixel drift.

### Motion / duration values

Current duration ownership includes:

```text
90ms, 150ms, 250ms, 310ms, 400ms, 1200ms
```

`150/250/400ms` are duplicated between `TioMotion` and `TioMotionTokens`. A4 remains pending.

### Typography physical values

Core typography/component contracts currently evidence font sizes including:

```text
12, 13, 14, 15, 16, 17, 18, 20, 22, 24, 28, 34, 36
```

and fixed letter-spacing/line-height contracts including values such as:

```text
letter spacing: -0.5, -0.3, -0.2, 0.5, 0.8, 6.0
line-height ratios: 1.25, 1.35, 1.4, 1.5
```

Typography remains separate from `TioSize`; A7 remains pending.

### Ratios / factors

Fixed visual ratios/factors include examples such as:

```text
0.28, 0.5, 0.36, 0.004, 1.3
```

These remain classified separately until reusable ownership is proven.

### Color / effect ownership

The audit confirmed raw palette/theme/domain/component colors across `TioPalette`, `TioColors`, `TioDomainColors`, Navigation/Dialog contracts and shadow definitions. Duplicate physical examples include domain colors such as workout/nutrition/progress/coach and the identical soft shadow physical definition in both `TioShadowTokens` and `TioShadows`. A5/A6 remain pending and must preserve exact ARGB values.

## A2 Implementation Evidence

First bounded geometry bootstrap:

```text
7a55f2dea97074790007b0c8f3b81ac8a6672783
  refactor(theme): add canonical size primitives

9916df8d64022ecf8f39b3e05533d70a4a2e03be
  refactor(theme): alias spacing and radius to size primitives
```

Current canonical relationships:

```text
TioSpacing.extraSmall  → TioSize.dp4
TioSpacing.small       → TioSize.dp8
TioSpacing.medium      → TioSize.dp12
TioSpacing.large       → TioSize.dp16
TioSpacing.extraLarge  → TioSize.dp24

TioRadius.small        → TioSize.dp8
TioRadius.medium       → TioSize.dp12
TioRadius.large        → TioSize.dp16
TioRadius.extraLarge   → TioSize.dp24
TioRadius.full         → TioSize.dp999
```

No rendered value changed in this migration.

Validation status:

```text
Flutter CI #518 — IN PROGRESS
Focused/core test result — not yet claimed until CI executes tests
Analyze result — not yet claimed until CI executes analyze
```

## Completion Lifecycle

1. Inventory
2. Classification
3. Planned ownership
4. Implementation
5. Focused tests
6. Static audit
7. Pixel/UI regression check
8. Analyze
9. Full CI
10. Update evidence
11. Mark Slice A `Validated`
12. Unblock Slice B

## Exit Criteria

Slice A is complete only when:

- every fixed core visual scalar has one canonical physical owner;
- no duplicate motion/shadow/color physical ownership remains in core theme;
- component contracts no longer act as independent physical-value stores;
- dynamic context access and static token access are clearly separated;
- tests lock both exact values and ownership aliases;
- no visible UI value changed without separate approval;
- focused tests, analyze, and required CI pass.

Until these conditions are met, Slice B remains blocked.
