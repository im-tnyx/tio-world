# Design System Slice A — Core Foundation

**Status:** In progress  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`  
**Scope:** `apps/core/lib/src/theme/**`, `apps/core/test/theme/**`

## Outcome

Establish one canonical core owner for fixed visual primitives before feature migration continues.

This is an ownership/architecture slice, not a general screen redesign. The only standing visual adjustment approved by this program is the controlled `±1dp` spacing/radius normalization described below.

## Visual Governance

Without separate explicit owner/design approval:

- no visible color changes;
- no typography appearance changes;
- no icon/image sizing changes;
- no Avatar/component size changes;
- no motion/choreography changes;
- no screen composition redesign.

### Approved spacing/radius normalization

When migrating a **spacing or radius** value to the canonical semantic scale, a value exactly `1dp` away from a clearly matching role may normalize to that role.

```text
5dp spacing → TioSpacing.xs → 4dp   ✅
7dp spacing → TioSpacing.sm → 8dp   ✅
```

Rules:

- maximum adjustment is `±1dp`;
- semantic intent must be clear;
- every actual normalization must be recorded in the active slice evidence;
- do not create new spacing/radius roles only to preserve near-duplicate `5dp`/`7dp` values;
- this exception does not apply to component heights, Avatar sizes, icon/image sizes, typography, colors, alpha, shadows, motion, ratios/factors, or unrelated geometry;
- ambiguous or larger changes require separate approval or exact preservation.

## Hard Boundaries

This slice must not migrate Welcome, Auth, Account Setup, Onboarding, Home, Profile, Settings, or other feature screens. It must not change auth/session behavior, navigation behavior, persistence, Supabase behavior, business logic, or product flow.

## Canonical Ownership

```text
TioSize                         physical numeric geometry registry
    ↓
TioSpacing / TioRadius          reusable semantic geometry scales
TioIconSize / TioStroke        only when reusable roles are evidenced
    ↓
Reusable component contracts   semantic aliases to governed primitives/roles
    ↓
Reusable core components
    ↓
Feature screens/widgets
```

`TioSize` owns physical numbers. Foundation/component families own semantic intent.

## Scalable Foundation Contract

### TioSize

`TioSize` contains fixed geometry values evidenced by production UI or explicit design decisions. It is not limited by the number of spacing/radius roles.

Current audited integer geometry includes:

```text
0, 1, 2, 3, 4, 5, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24,
26, 27, 28, 30, 32, 36, 38, 44, 46, 48, 52, 54, 56, 62, 64,
72, 100, 125, 140, 160, 200, 999
```

Do not generate arbitrary unused values. Remove an audited primitive only after zero-reference verification.

### TioSpacing

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

Legacy `extraSmall/small/medium/large/extraLarge` names are temporary compatibility aliases.

### TioRadius

```text
none → TioSize.dp0
xs   → TioSize.dp4
sm   → TioSize.dp8
md   → TioSize.dp12
lg   → TioSize.dp16
xl   → TioSize.dp24
full → TioSize.dp999
```

Legacy `small/medium/large/extraLarge` names are temporary compatibility aliases. `full` belongs to radius/shape semantics, not spacing.

### Reusable component geometry

Reusable component size contracts retain semantic component names but alias `TioSize` instead of owning raw numbers.

Avatar is the first explicit example:

```text
TioAvatarTokens.compactSize    → TioSize.dp24
TioAvatarTokens.smallSize      → TioSize.dp36
TioAvatarTokens.mediumSize     → TioSize.dp48
TioAvatarTokens.largeSize      → TioSize.dp100
TioAvatarTokens.extraLargeSize → TioSize.dp160
```

The verified `36/100/160` runtime decisions therefore remain valid as semantic Avatar contracts, but their physical values are owned by `TioSize`.

Avatar ring widths and size factors remain separate pending `TioStroke`/factor ownership decisions.

## Implementation Checklist

### A1 — Inventory and classification

- [x] Inventory raw fixed visual values under `apps/core/lib/src/theme/tokens/**`.
- [x] Classify geometry, opacity, exact alpha, duration, typography, color, effects, ratios/factors, semantic roles, component roles, and genuine non-design values.
- [x] Record exact values before edits.

### A2 — Primitive geometry and scalable foundation

- [x] Create `tokens/primitive/primitive.dart`.
- [x] Create and expand canonical `TioSize` to audited/evidenced integer geometry values.
- [x] Establish `TioSpacing.none/xxs/xs/sm/md/lg/xl/xxl`.
- [x] Preserve old spacing names as compatibility aliases.
- [x] Establish `TioRadius.none/xs/sm/md/lg/xl/full`.
- [x] Preserve old radius names as compatibility aliases.
- [x] Add physical/semantic/compatibility contract tests.
- [x] Approve controlled `±1dp` normalization for clearly matching spacing/radius roles.
- [ ] Record each actual future `±1dp` normalization during consumer migration.
- [ ] Add `TioIconSize` and/or `TioStroke` only when reusable roles are evidenced.

### A3 — Opacity and exact alpha

- [x] Establish `TioOpacity` for normalized opacity/state values.
- [x] Establish `TioAlpha` for exact 0–255 alpha values.
- [x] Preserve exact integer-alpha contracts without rounded conversion.
- [x] Migrate current component opacity/alpha roles to primitive aliases.
- [x] Flutter CI #521 passed for the A3 head.

### A4 — Motion and duration

- [ ] Establish one canonical fixed-duration owner such as `TioDuration`.
- [ ] Remove duplicate physical ownership between `TioMotion` and `TioMotionTokens`.
- [ ] Keep `TioMotionScheme` as runtime/reduced-motion resolution.
- [ ] Preserve `90/150/250/310/400/1200ms` unless a separate motion decision approves change.

### A5 — Shadows/effects

- [ ] Resolve duplicate ownership between `TioShadowTokens` and `TioShadows`.
- [ ] Preserve shadow colors, blur, spread, and offset unless separately approved.

### A6 — Colors

- [ ] Audit `TioPalette`, `TioColors`, `TioSemanticColors`, and `TioDomainColors` as one graph.
- [ ] Ensure raw physical colors have one core owner.
- [ ] Preserve current visible colors unless separately approved.
- [ ] Apply `.ai/tasks/design-system-hardcoded-color-audit.md`.

### A7 — Typography

- [ ] Inventory font size, weight, family, line height, letter spacing, decoration, and relevant style contracts.
- [ ] Keep typography physical ownership separate from `TioSize`.
- [ ] Introduce a governed type scale only when evidence supports it.

### A8 — Component token audit

- [ ] Audit every `tokens/components/` file.
- [x] Migrate Avatar size contracts `24/36/48/100/160` to `TioSize` aliases.
- [x] Add tests locking Avatar semantic size roles to canonical primitives.
- [ ] Move remaining raw physical geometry to primitive/foundation/semantic/typography/effects owners.
- [ ] Apply controlled `±1dp` normalization only to eligible spacing/radius roles and record each change.
- [ ] Keep component token classes only for genuinely reusable component contracts.
- [ ] Do not create screen-specific core token bags.

```text
Reusable component    → semantic component tokens alias governed primitives/roles
Reusable semantic     → foundation/semantic/typography/effects
One-off screen visual → governed primitive/core role directly
Screen-specific bag   → forbidden
```

### A9 — Context and compatibility APIs

- [ ] Keep `context.tioColors`, `context.tioMotion`, and `context.tioShadows` as canonical dynamic accessors.
- [ ] Remove static radius context compatibility accessors only after zero-reference migration.
- [ ] Remove `TioTheme.colors(context)` only after zero-reference migration.
- [ ] Do not make `context/` a wrapper for static tokens.

### A10 — Validation

- [x] Primitive barrels exported intentionally.
- [x] Primitive geometry/spacing/radius tests added.
- [x] Avatar primitive alias tests added.
- [ ] Update assertions when an approved `±1dp` spacing/radius normalization intentionally changes a canonical value.
- [ ] Current branch head must pass CI before the latest A2/A8 corrections are validated.
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
738e3df77603da3975fe9d30746ef8148761ad50  alias Avatar size roles to TioSize
bc5f85490d03c430ce697fc4cc9aae3bca114864  lock Avatar size primitive relationships
```

Slice B remains blocked until Slice A is validated.
