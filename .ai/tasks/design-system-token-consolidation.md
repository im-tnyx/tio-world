# Design System Token Consolidation

**Status:** In progress
**Primary owner:** `apps/core` design-system tokens; `apps/features/welcome` as the first migration consumer
**Affected platforms:** Flutter mobile UI
**Related issue:** #6
**Working branch:** `codex/design-system-token-consolidation`
**Draft PR:** #22

## 1. Discovery

### User Outcome

Keep the current Tio phone UI visually unchanged while making `tio_core` the source of truth for reusable design-system values and removing duplicate/private token ownership only where semantics genuinely match.

### Success Criteria

- No unapproved pixel or behavior changes.
- `TioSpacing` and `TioRadius` remain distinct semantic APIs.
- Component-local physical dimensions stay component-owned unless reuse evidence proves otherwise.
- Welcome reusable spacing/radius roles consume `tio_core`; Welcome-only composition geometry stays local.
- `welcome_tokens.dart` is removed only after every live member has a value-preserving destination and every remaining declaration is proven obsolete.
- No generic numeric `TioDimensions` catalog is introduced.
- Analyze/tests remain green.

### Scope

1. **Slice 1 — core aliases:** complete + validated.
2. **Slice 2 — Avatar source of truth:** complete + validated.
3. **Slice 3 — Welcome private-token ownership migration:** classified; implementation next.
4. **Slice 4 — Welcome raw literals + orphan state/widget cleanup:** pending.
5. **Slice 5 — final docs/validation:** pending.

### Non-Goals

No mobile redesign, Auth/Account Setup/onboarding behavior, backend, Supabase, arbitrary value normalization, or feature-specific geometry promotion into core.

## 2. Codebase Exploration

### Slice 1 — Core Alias Result

| Component token | Previous | Current owner |
|---|---:|---|
| `TioButtonTokens.contentGap` | `8` | `TioSpacing.small` |
| `TioButtonTokens.radius` | `999` | `TioRadius.full` |
| `TioCardTokens.padding` | `16` | `TioSpacing.large` |
| `TioCardTokens.radius` | `16` | `TioRadius.large` |
| `TioCardTokens.radiusItem` | `8` | `TioRadius.small` |
| `TioNavigationTokens.itemRadius` | `16` | `TioRadius.large` |
| `TioSheetTokens.padding` | `24` | `TioSpacing.extraLarge` |

Component-only values such as Button `46`, Input `14/52`, Navigation `62/22/125`, and Sheet radius `28` remain unchanged.

### Slice 2 — Avatar Decision

Runtime and tests agree on `small=36`, `large=100`, `extraLarge=160`. Profile/Profile Settings consume semantic `large`; shell consumes `small`; Profile Photo uses screen-derived `customDimension` rather than a fixed 160dp preview. Runtime `large=100dp` is authoritative and stale docs/test wording were aligned without changing UI.

### Slice 3 — Welcome Usage Inventory

Verified live `WelcomeDimens` usage exists only in `welcome_screen.dart` and `welcome_top_bar.dart`. `welcome_tokens.dart` is not part of the package public API.

| Private member | Runtime usage | Destination | Decision |
|---|---|---|---|
| `paddingScreen = 16` | Welcome screen horizontal padding | `TioSpacing.large` | migrate |
| `spaceXS = 8` | screen/top-bar gaps/padding | `TioSpacing.small` | migrate |
| `spaceS = 12` | screen vertical gaps/panel padding | `TioSpacing.medium` | migrate |
| `radiusL = 16` | top-bar InkWell radius | `TioRadius.large` | migrate |
| `spaceXXS = 4` | top-bar vertical padding + feature-divider margin | local composition constants | keep local, rename by role |
| `radiusXL = 20` | feature-panel radius | local `_featurePanelRadius` | keep local, rename by role |
| `spaceSM = 16` | no live reference | none | obsolete |
| `spaceM = 24` | no live reference | none | obsolete |
| `buttonHeightLarge = 56` | no live reference | none | obsolete |
| `borderThin = 1` | no live reference | none | obsolete |
| `borderSubtle = 0.8` | no live reference | none | obsolete |
| `featureTileHeight = 80` | no live reference | none | obsolete |
| `featureTileIconContainerSize = 48` | no live reference | none | obsolete |
| `radiusFeatureIcon = 12` | no live reference | none | obsolete |
| `iconSizeXS = 20` | no live reference | none | obsolete |
| `iconSizeS = 24` | no live reference | none | obsolete |
| `opacityGlass = 0.08` | no live reference | none | obsolete |
| `opacityOverlayLow = 0.1` | no live reference | none | obsolete |
| `opacityMuted = 0.5` | no live reference | none | obsolete |
| `WelcomeColors.transparent` | top-bar Material color | framework `Colors.transparent` | remove wrapper |
| `getAdaptivePrimary` | definition only | none | obsolete |
| `getOnSurfaceColor` | definition only | none | obsolete |

### Welcome Raw-Value Boundary

`welcome_screen.dart`, `welcome_feature_tile.dart`, and `welcome_backdrop.dart` still contain raw typography, icon sizes, animation offsets, divider dimensions, gradients, stops, and composition geometry. These are **not** part of Slice 3 unless required to eliminate `welcome_tokens.dart`. They remain for Slice 4 classification; numeric proximity alone is not a reason to replace them.

### Welcome Legal Orphan Evidence

`WelcomeDisclaimer` has no live call site. `termsPrefix/termsText/andText/privacyText` are referenced only by `WelcomeUiState` and that orphan widget. Product intent in #6 says the Welcome legal footer stays removed while shared `TioTermsDisclaimer` remains for Auth. Deleting the Welcome wrapper/state leftovers is deferred to Slice 4 so Slice 3 stays token-focused.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Pixel-preserving migration | Made | #6 is ownership cleanup, not redesign |
| Generic `TioDimensions` | Rejected | no repository-wide evidence |
| Avatar `100 -> 80` | Rejected | runtime/test contract is 100dp |
| Welcome `4` → nearest spacing token | Rejected | would change pixels |
| Welcome panel `20` → nearest radius token | Rejected | would change pixels |
| Delete `welcome_tokens.dart` after Slice 3 migration | Approved | all live members have classified destinations; remaining members are obsolete |
| Remove Welcome disclaimer/state in Slice 3 | Deferred | keep token migration narrow; do in Slice 4 |

## 4. Architecture Design

```text
TioSpacing / TioRadius
        ↓
Reusable core components/tokens
        ↓
Welcome reusable roles

Welcome-only composition geometry
        ↓
file-local named constants
```

A feature-local parallel `theme/` token system is not retained after the live reusable roles are migrated.

## 5. Implementation Plan

### Slice 1 — Complete

- [x] Seven exact semantic aliases.
- [x] Token contract tests.
- [x] CI #399 full green on `24c4dbd`.

### Slice 2 — Complete

- [x] Avatar runtime/docs/test audit.
- [x] Keep runtime Profile avatar at 100dp.
- [x] Align canonical docs and stale test description.
- [x] CI #401 full green on `18e8d89`.

### Slice 3 — Welcome token ownership

- [x] Inventory all private token members and live call sites.
- [x] Classify core destinations vs local composition vs obsolete declarations.
- [x] Verify `welcome_tokens.dart` is not public API.
- [ ] Replace screen `16/8/12` usages with `TioSpacing.large/small/medium`.
- [ ] Replace top-bar radius `16` with `TioRadius.large`.
- [ ] Replace `WelcomeColors.transparent` with `Colors.transparent`.
- [ ] Keep exact `4` values as role-named file-local constants.
- [ ] Keep exact `20` panel radius as a role-named file-local constant.
- [ ] Remove `welcome_tokens.dart` once zero references remain.
- [ ] Run full CI and inspect diff for pixel changes.

### Slice 4 — Pending

- [ ] Classify raw typography/colors/icon sizes/dividers/animation/gradient values.
- [ ] Remove orphan `WelcomeDisclaimer` and Welcome-only legal state after final reference audit.
- [ ] Preserve shared `TioTermsDisclaimer` and Auth legal UI.

### Slice 5 — Pending

- [ ] Final docs/task/Issue #6 sync.
- [ ] Relevant before/after compact/light/dark validation where practical.
- [ ] Final PR diff review.

## 6. Quality Review

```text
CI #399 — full green (Slice 1 source head 24c4dbd)
CI #401 — full green (Slice 2 head 18e8d89)
CI #402 — latest task-sync head validation in progress at Slice 3 start
```

## 7. Final Handoff

### Changed Files So Far

- `.ai/tasks/design-system-token-consolidation.md`
- four core component token files
- core token alias contract test
- avatar/Profile documentation
- stale Profile avatar test description

### Actual Behavior

Slices 1-2 preserve rendered behavior. Slice 3 implementation has not yet changed runtime source at this checkpoint.

### Known Limitations

Welcome token migration, raw-literal classification, and orphan cleanup remain open.

### Final Status

`PARTIAL`
