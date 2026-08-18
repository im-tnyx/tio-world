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

Current rendered values must remain exact. Never normalize an existing value merely to fit a nearby scale value.

## Hard Boundaries

This slice must not migrate Welcome, Auth, Account Setup, Onboarding, Home, Profile, Settings, or other feature screens. It must not change auth/session behavior, navigation behavior, persistence, Supabase behavior, business logic, or product flow.

## Canonical Ownership

```text
TioSize                         physical numeric geometry registry
    ↓
TioSpacing / TioRadius          reusable semantic geometry scales
TioIconSize / TioStroke        add only when reusable roles are evidenced
    ↓
Reusable component contracts
    ↓
Reusable core components
    ↓
Feature screens/widgets
```

`TioSize` uses numeric names because it owns physical values. Semantic families use intent/scale names and must not redefine raw physical values.

## Scalable Foundation Contract

The original five-role spacing API was too restrictive as a final design-system scale. Slice A corrects that limitation without changing any current pixels.

### TioSize

`TioSize` must contain the fixed geometry values actually evidenced by current production UI or separately approved design decisions. It must not be limited to the values currently used by `TioSpacing`.

Current audited integer geometry registry includes:

```text
0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24,
26, 27, 28, 30, 32, 36, 38, 44, 46, 48, 52, 54, 56, 62, 64,
72, 100, 125, 140, 160, 200, 999
```

Do not generate arbitrary unused values. Fractional stroke widths remain separate until `TioStroke` ownership is established.

### TioSpacing

Canonical reusable spacing roles:

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

Temporary compatibility aliases preserve existing consumers during migration:

```text
extraSmall → xs
small      → sm
medium     → md
large      → lg
extraLarge → xl
```

These legacy names are not the final canonical API.

### TioRadius

Radius has its own semantic scale even when some physical values overlap spacing:

```text
none → TioSize.dp0
xs   → TioSize.dp4
sm   → TioSize.dp8
md   → TioSize.dp12
lg   → TioSize.dp16
xl   → TioSize.dp24
full → TioSize.dp999
```

Temporary compatibility aliases:

```text
small      → sm
medium     → md
large      → lg
extraLarge → xl
```

`full` belongs to radius/shape semantics, not spacing.

### Category independence

Do not force equal semantic names to equal physical values across categories merely for symmetry.

```text
TioSpacing.xs may be 4dp
TioRadius.xs may be 4dp
TioIconSize.xs may later be 16dp
```

Each semantic family must reflect its actual reusable product contracts.

## Verified Starting Debt

- primitive geometry ownership did not exist before Slice A;
- spacing/radius independently owned overlapping raw numbers;
- original `TioSpacing` had only five roles and insufficient growth scope;
- component token files still contain raw geometry, typography, color, factor and other physical values;
- `TioMotion` and `TioMotionTokens` duplicate duration ownership;
- `TioShadowTokens` and `TioShadows` duplicate shadow ownership;
- `TioPalette`, `TioSemanticColors`, `TioDomainColors`, and `TioColors` overlap in color ownership;
- static compatibility getters remain under `context/`;
- `TioTheme.colors(context)` remains transitional;
- typography physical values remain split across typography and component token classes.

## Implementation Checklist

### A1 — Inventory and classification

- [x] Inventory raw fixed visual values under `apps/core/lib/src/theme/tokens/**`.
- [x] Classify geometry, opacity, exact alpha, duration, typography, color, effects, ratios/factors, semantic roles, component roles, and genuine non-design values.
- [x] Record exact values before edits.

### A2 — Primitive geometry and scalable foundation

- [x] Create `tokens/primitive/primitive.dart`.
- [x] Create canonical `TioSize`.
- [x] Expand `TioSize` to audited/evidenced integer geometry values instead of five spacing values only.
- [x] Add canonical `dp0` and the other audited integer geometry primitives.
- [x] Establish `TioSpacing.none/xxs/xs/sm/md/lg/xl/xxl`.
- [x] Preserve old spacing names as compatibility aliases.
- [x] Establish `TioRadius.none/xs/sm/md/lg/xl/full`.
- [x] Preserve old radius names as compatibility aliases.
- [x] Add contract tests for physical values, canonical semantic roles, and compatibility aliases.
- [ ] Add `TioIconSize` and/or `TioStroke` only when reusable roles are evidenced during component audit.

### A3 — Opacity and exact alpha

- [x] Establish `TioOpacity` for normalized opacity/state values.
- [x] Establish `TioAlpha` for exact 0–255 alpha values.
- [x] Preserve exact integer-alpha contracts without rounded conversion.
- [x] Migrate current component opacity/alpha roles to primitive aliases without changing public semantic names.
- [x] Flutter CI #521 passed for the A3 head.

### A4 — Motion and duration

- [ ] Establish one canonical fixed-duration owner such as `TioDuration`.
- [ ] Remove duplicate physical ownership between `TioMotion` and `TioMotionTokens`.
- [ ] Keep `TioMotionScheme` as runtime/reduced-motion resolution.
- [ ] Preserve `90/150/250/310/400/1200ms` contracts exactly.

### A5 — Shadows/effects

- [ ] Resolve duplicate ownership between `TioShadowTokens` and `TioShadows`.
- [ ] Preserve exact shadow colors, blur, spread, and offset.

### A6 — Colors

- [ ] Audit `TioPalette`, `TioColors`, `TioSemanticColors`, and `TioDomainColors` as one graph.
- [ ] Ensure raw physical colors have one core owner.
- [ ] Preserve all current visible colors.
- [ ] Apply `.ai/tasks/design-system-hardcoded-color-audit.md`.

### A7 — Typography

- [ ] Inventory font size, weight, family, line height, letter spacing, decoration, and relevant style contracts.
- [ ] Keep typography physical ownership separate from `TioSize`.
- [ ] Introduce a governed type scale only when evidence supports it.

### A8 — Component token audit

- [ ] Audit every `tokens/components/` file.
- [ ] Move raw physical values to primitive/foundation/semantic/typography/effects owners.
- [ ] Keep component token classes only for genuinely reusable component contracts.
- [ ] Do not create screen-specific core token bags.

```text
Reusable component   → component tokens
Reusable semantic    → foundation/semantic/typography/effects
One-off screen visual→ governed primitive/core role directly
Screen-specific bag  → forbidden
```

### A9 — Context and compatibility APIs

- [ ] Keep `context.tioColors`, `context.tioMotion`, and `context.tioShadows` as canonical dynamic accessors.
- [ ] Remove static radius context compatibility accessors only after zero-reference migration.
- [ ] Remove `TioTheme.colors(context)` only after zero-reference migration.
- [ ] Do not make `context/` a wrapper for static tokens.

### A10 — Validation

- [x] Primitive barrels exported intentionally.
- [x] Primitive geometry/spacing/radius tests added.
- [x] Existing runtime-value assertions preserved.
- [ ] Current scalable-foundation head must pass CI before A2 correction is considered validated.
- [ ] Run focused core theme tests, analyze, and required workspace CI at the slice boundary.

## Implementation Evidence

```text
7a55f2dea97074790007b0c8f3b81ac8a6672783  add initial size primitives
9916df8d64022ecf8f39b3e05533d70a4a2e03be  alias original spacing/radius roles
83da96d41fbc6a31a2e79d6f25b0e9d752ea3d12  add opacity/alpha primitives
631040377a7c36c9c4c2ad2e6f845def4887ed85  migrate opacity/alpha component roles
02ff356e27619df8a31388c71bd018ab4345e168  expand audited TioSize registry
f9ac707576730207593d3e34240dce1a239ba286  add scalable spacing roles
1a0416003f4616d6b8cd02e2badec54c1cdf5c20  add scalable radius roles
c29a7ca50e8f0a82c51e1ce5e920c7959e606631  lock scalable radius contracts
```

No production screen was redesigned by these changes. Legacy semantic names remain aliases so current rendered spacing/radius values are unchanged.

## Exit Criteria

Slice A remains `In progress` until every core fixed visual value has one canonical owner, duplicate motion/shadow/color ownership is resolved, component contracts no longer independently own physical values, compatibility APIs are safely migrated, and focused tests/analyze/full required CI pass.

Slice B remains blocked until Slice A is validated.
