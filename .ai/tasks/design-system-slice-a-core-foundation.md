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

- `primitive/` does not yet exist;
- `TioSpacing` and `TioRadius` independently own overlapping raw geometry values;
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

- [ ] Inventory every raw fixed visual scalar/color/duration/factor under `apps/core/lib/src/theme/tokens/**`.
- [ ] Classify each as geometry, opacity, exact integer alpha, duration, typography, palette color, effect/shadow, factor/ratio, semantic role, reusable component role, or genuine non-design/runtime value.
- [ ] Record exact current values before edits.

### A2 — Primitive geometry

- [ ] Create `tokens/primitive/primitive.dart`.
- [ ] Create canonical `TioSize` (or final agreed equivalent).
- [ ] Add only evidenced production values, not an arbitrary integer range.
- [ ] Alias `TioSpacing` raw values to geometry primitives.
- [ ] Alias `TioRadius` raw values to geometry primitives.
- [ ] Add `TioIconSize` and/or `TioStroke` only when reusable roles are evidenced.

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

- [ ] Update token barrels intentionally.
- [ ] Remove obsolete duplicate public exports only after consumer search.
- [ ] Update primitive contract tests.
- [ ] Update alias tests to lock relationships such as `TioInputTokens.radius == TioSize.dp14`, not independent component ownership.
- [ ] Preserve exact existing runtime-value assertions where they protect pixels.
- [ ] Run focused core theme tests.
- [ ] Run Flutter/Dart analyze.
- [ ] Run full workspace CI at the slice boundary.

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
