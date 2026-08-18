# Design System Slice A — Core Foundation

**Status:** In progress  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`  
**Scope:** `apps/core/lib/src/theme/**`, `apps/core/test/theme/**`

## Outcome

Establish one canonical core owner for fixed visual primitives before feature migration continues.

This is an ownership/architecture slice, not a general screen redesign. The only standing visual adjustment approved by this program is the controlled `±1dp` spacing/radius normalization below.

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
- every actual normalization must be recorded in active slice evidence;
- do not create new spacing/radius roles only to preserve near-duplicate values;
- this exception does not apply to component heights, Avatar sizes, icon/image sizes, typography, colors, alpha, shadows, motion, ratios/factors, or unrelated geometry;
- ambiguous or larger changes require separate approval or exact preservation.

## Hard Boundaries

This slice must not migrate Welcome, Auth, Account Setup, Onboarding, Home, Profile, Settings, or other feature screens. It must not change auth/session behavior, navigation behavior, persistence, Supabase behavior, business logic, or product flow.

## Canonical Ownership

```text
TioSize                         physical numeric geometry registry
TioOpacity                      normalized opacity registry
TioAlpha                        exact 0–255 alpha registry
TioDuration                     physical duration registry
TioFontSize                     physical typography size registry
TioFontWeight                   physical typography weight registry
TioLetterSpacing                physical tracking registry
TioLineHeight                   physical line-height registry
TioFontFamily                   physical/named family identifiers
    ↓
TioSpacing / TioRadius          reusable semantic geometry scales
TioStroke                       reusable stroke-width physical contract
TioMotion                       semantic motion roles
TioShadowTokens                 reusable static shadow contracts
TioTypography                   semantic TextTheme roles
TioFontFamilyOption             verified runtime-selectable font choices
TioIconSize                     only when reusable semantic roles are evidenced
    ↓
Runtime theme schemes/config    TioMotionScheme / TioShadows / TioThemeConfig
    ↓
Reusable component contracts   semantic aliases to governed primitives/roles
    ↓
Reusable core components
    ↓
Feature screens/widgets
```

Physical primitives own numbers. Foundation/effects/typography/component families own semantic intent.

## Scalable Foundation Contract

### TioSize

`TioSize` contains fixed geometry values evidenced by production UI or explicit design decisions. It is not limited by spacing/radius role count.

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

Reusable component size contracts retain semantic component names but alias governed primitives.

```text
TioAvatarTokens.compactSize    → TioSize.dp24
TioAvatarTokens.smallSize      → TioSize.dp36
TioAvatarTokens.mediumSize     → TioSize.dp48
TioAvatarTokens.largeSize      → TioSize.dp100
TioAvatarTokens.extraLargeSize → TioSize.dp160
```

Avatar ring/frame widths now alias `TioStroke`; Avatar size/radius/text factors remain component-specific ratios because they are not physical geometry primitives.

## Typography Runtime Preference Contract

Typography must support a future app-level **Settings → Font Style** preference without requiring feature screens or reusable components to know which font is selected.

```text
TioFontFamily / bundled font assets
        ↓
TioFontFamilyOption (stable persisted option id)
        ↓
TioThemeConfig.fontFamilyOption
        ↓
TioTypography.textTheme(... fontFamily: resolved family)
        ↓
Theme.of(context).textTheme
        ↓
Reusable components / feature UI
```

Rules:

- `TioFontFamily.system = null` keeps Flutter/platform default resolution.
- The default runtime option remains `system`, preserving current product typography.
- `TioFontFamilyOption.id` is stable and intended for app-level persistence; display labels remain Settings/localization owned.
- A family becomes a selectable `TioFontFamilyOption` only after availability is verified on every supported platform, normally through explicitly bundled font assets.
- A named family may exist in `TioFontFamily` for an evidenced existing visual contract without being exposed as a Settings option.
- `Roboto` is currently an evidenced named family but is not registered as a bundled cross-platform font in the repository, so it is intentionally **not** selectable yet.
- Future Settings persistence/controller logic remains app-level. Core only owns the option contract and runtime theme resolution.
- Do not create per-screen font-family switches. Consumers should resolve typography through `Theme.of(context).textTheme` or governed component typography contracts.

## Verified Starting Debt

- primitive geometry ownership did not exist before Slice A;
- spacing/radius independently owned overlapping raw numbers;
- original `TioSpacing` had only five roles and insufficient growth scope;
- component token files still contained raw geometry, factor and other physical values;
- `TioMotion` and `TioMotionTokens` duplicated duration ownership;
- `TioShadowTokens` and `TioShadows` duplicated the same soft shadow;
- `TioPalette`, `TioSemanticColors`, `TioDomainColors`, and `TioColors` overlapped in color ownership;
- static compatibility getters remain under `context/` for live consumers;
- `TioTheme.colors(context)` remains transitional for live consumers;
- typography physical values were split across typography and component token classes;
- runtime font selection was not modeled before A7.

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
- [x] Record current component-migration normalization outcome: **none applied**; exact values were preserved through `TioSize` where no exact semantic spacing/radius role existed.
- [x] Add `TioStroke` after repeated reusable stroke-width evidence was confirmed.
- [x] Defer `TioIconSize`; current evidence does not justify a shared semantic icon-size family yet.

### A3 — Opacity and exact alpha

- [x] Establish `TioOpacity` for normalized opacity/state values.
- [x] Establish `TioAlpha` for exact 0–255 alpha values.
- [x] Preserve exact integer-alpha contracts without rounded conversion.
- [x] Migrate current component opacity/alpha roles to primitive aliases.
- [x] Flutter CI #521 passed for the A3 head.

### A4 — Motion and duration

- [x] Establish `TioDuration` as the canonical fixed-duration owner.
- [x] Alias `TioMotion` semantic roles to `TioDuration`.
- [x] Convert `TioMotionTokens` into a compatibility facade instead of a second physical owner.
- [x] Keep `TioMotionScheme` as runtime/reduced-motion resolution.
- [x] Preserve `90/150/250/310/400/1200ms` exactly.
- [x] Add primitive/semantic/runtime motion contract tests.
- [x] Flutter CI #541 passed Flutter/Dart analyze and tests for the A4 head.

### A5 — Shadows/effects

- [x] Resolve duplicate soft-shadow ownership between `TioShadowTokens` and `TioShadows`.
- [x] Make `TioShadowTokens.soft` the single static soft-shadow contract.
- [x] Make runtime `TioShadows` alias governed static shadow contracts.
- [x] Alias soft shadow blur/offset geometry to `TioSize`.
- [x] Preserve exact shadow color `0x1A000000`, blur `24`, spread `0`, and offset `0/12`.
- [x] Add shadow effect ownership contract tests.
- [x] Flutter CI #545 passed the A5 validated head.

### A6 — Colors

- [x] Audit `TioPalette`, `TioColors`, `TioSemanticColors`, and `TioDomainColors` as one graph.
- [x] Centralize current raw physical core colors in `TioPalette` while preserving exact ARGB values.
- [x] Alias `TioColors`, `TioDomainColors`, reusable component color roles, and shadow color primitives to governed owners.
- [x] Remove zero-reference duplicate `TioSemanticColors` facade/export.
- [x] Make runtime UI shadow color resolve through `context.tioShadows` instead of direct palette consumption.
- [x] Audit core reusable UI hardcoded colors and retain only documented framework-transparent exceptions.
- [x] Preserve current visible colors.
- [x] Apply `.ai/tasks/design-system-hardcoded-color-audit.md` to the current core slice.
- [x] Flutter CI #565 passed the A6 cleanup head.

### A7 — Typography

- [x] Inventory font size, weight, family, line height, letter spacing, decoration, and relevant style contracts.
- [x] Keep typography physical ownership separate from `TioSize`.
- [x] Establish governed physical registries: `TioFontSize`, `TioFontWeight`, `TioLetterSpacing`, `TioLineHeight`, and `TioFontFamily`.
- [x] Migrate `TioTypography` TextTheme roles to canonical typography primitives.
- [x] Migrate current reusable component typography roles to canonical typography primitives.
- [x] Preserve all audited typography appearance values exactly.
- [x] Add `TioFontFamilyOption` with stable persistence ids for future Settings font selection.
- [x] Add `TioThemeConfig.fontFamilyOption` and runtime family resolution into `TioTypography`.
- [x] Keep current runtime default on `system` so current UI does not change.
- [x] Gate selectable font options on verified cross-platform/platform-or-bundled availability.
- [x] Keep currently unbundled `Roboto` as an evidenced named family, not a selectable Settings option.
- [x] Add typography primitive/component/runtime-selection contract tests.
- [x] Flutter CI #576 passed the A7 foundation/component typography head before runtime-font preference wiring.
- [x] Flutter CI #595 passed the runtime-font preference head; A7 is validated.

### A8 — Component token audit

- [x] Audit every `tokens/components/` file.
- [x] Migrate Avatar size contracts `24/36/48/100/160` to `TioSize` aliases.
- [x] Add tests locking Avatar semantic size roles to canonical primitives.
- [x] Migrate reusable component typography roles to canonical typography owners.
- [x] Add `TioStroke` after repeated reusable stroke-width evidence was confirmed.
- [x] Move remaining raw integer physical geometry to `TioSize`/canonical spacing/radius owners without changing rendered values.
- [x] Apply controlled `±1dp` rule conservatively: **no normalization was performed in A8**; exact `5dp`, `6dp`, `14dp`, etc. contracts remain exact where semantic substitution would change pixels.
- [x] Keep component token classes only for genuinely reusable component contracts.
- [x] Keep component-specific ratios/factors local rather than misclassifying them as geometry primitives.
- [x] Do not create screen-specific core token bags.
- [x] Flutter CI #605 passed the `TioStroke` ownership head.
- [x] Flutter CI #610 passed the first exact component-geometry migration batch.
- [x] Flutter CI #620 passed the complete component-geometry migration/test head.

```text
Reusable component    → semantic component tokens alias governed primitives/roles
Reusable semantic     → foundation/semantic/typography/effects
One-off screen visual → governed primitive/core role directly
Screen-specific bag   → forbidden
```

### A9 — Context and compatibility APIs

- [x] Keep `context.tioColors`, `context.tioMotion`, and `context.tioShadows` as canonical dynamic accessors.
- [x] Confirm current branch has one canonical `theme/context/` path; old `theme/locals/` duplicate path is absent.
- [x] Audit radius context compatibility accessors against current-branch consumers; live feature references remain, so deletion is intentionally deferred until zero-reference migration.
- [x] Route temporary `radiusSmall/radiusMedium/radiusLarge` compatibility getters through canonical `TioRadius.sm/md/lg` internally.
- [x] Audit `TioTheme.colors(context)`; live consumers remain, so deletion is intentionally deferred until zero-reference migration.
- [x] Do not make `context/` a general wrapper for static tokens; only runtime theme accessors plus explicitly temporary compatibility getters remain.
- [x] Add focused context-accessor contract coverage.
- [ ] Flutter CI #622 must pass before the A9 implementation head is considered validated.

### A10 — Validation

- [x] Primitive barrels exported intentionally.
- [x] Primitive geometry/spacing/radius tests added.
- [x] Avatar primitive alias tests added.
- [x] Motion duration/scheme tests added.
- [x] Shadow ownership tests added.
- [x] Color ownership tests added.
- [x] Typography ownership/runtime-selection tests added.
- [x] Stroke ownership tests added.
- [x] Component geometry ownership tests added.
- [x] Context runtime/compatibility accessor test added.
- [x] No approved `±1dp` normalization occurred in Slice A component migration, so no assertions intentionally changed pixel values.
- [ ] Run focused core theme tests, analyze, and required workspace CI at the final Slice A boundary after A9 validation.

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
93f671c37a32e9d782c2a5853b69e61b0a5e8a82  add TioDuration primitives
9b220a6e6b7ea046f173e76cf30382816eafd843  export TioDuration
7791363ef4fb5638ffb9feb760df0f0beda90d64  alias TioMotion to TioDuration
65a366e84e419883a4a7bc75c3179df3b18e82a9  convert TioMotionTokens to compatibility aliases
6e9a301d65563b98009c3fe5de5cdeb6d9a0c652  lock duration/motion runtime contracts
ad2ec6a42940e6b427f5b00a603a4a733dd11430  centralize static soft shadow contract
eae3ef3488f9e865b8806bf9ff839457c55087fd  alias runtime shadows to static contract
218c2b36c33294bccfd4bc5618480bd875294eee  lock shadow effect ownership
62b4f623be03c0cd2b1fd0dbd76cd8f494e42d2b  add TioFontSize registry
5d2ed418cba91978664830fa34f18445b4d5f236  add TioFontFamily registry
307be2c11e679963e8ea67b7cd789348a316a582  add TioFontWeight registry
fc5859515c4f5f79d15251ae09a15b240705c245  add TioLetterSpacing registry
dc85c4e460deee45313575afb3fa5bb7ac959393  add TioLineHeight registry
c4ede3f3a93b7c7427f13200c7c3e7ae6d6c718c  alias TextTheme to typography primitives
022371da07595d60c575e48cd390e51bcda81ffc  lock component typography relationships
2c55980047fb117df6ea0c6e08bed3d860e8f63a  add runtime font-family option model
7db4fda8e7c3de9f6f28e55c93b518d5fd5509f9  add font preference to TioThemeConfig
283e21be59d2702e9adecfd861aee3db8eed3a2c  make TioTypography accept runtime family
158af0756a54ab6d07be0fd52a7229d6997927b0  wire TioTheme to configured font family
07948cb8c13818cfffa25baff577dc21c513b2ba  gate selectable fonts on verified availability
6f8255f32183c8515e2d0821050af5ef3a752028  lock font option/runtime contracts
d334f7198be941f9c599f6d9c76f3dbb1d2b9628  validate TioStroke ownership batch
c9bc949fed8dae7bec836c0f13967dae6af682bd  lock first exact component geometry batch
2bd07356ce8165e0ef7074dc39ba51c04e6b843b  lock complete component geometry ownership
a94a030b9e81d62b6fd2e2ad33c34febec7b2860  route context radius compatibility through canonical roles
16fe9bc02fa36b57dd698724c67de917028838c9  lock context accessor contracts
```

Slice B remains blocked until Slice A is validated.
