# Design System Token Consolidation

**Status:** In progress
**Primary owner:** `apps/core` design-system tokens; `apps/features/welcome` as the first migration consumer
**Affected platforms:** Flutter mobile UI
**Related issue:** #6
**Working branch:** `codex/design-system-token-consolidation`

## 1. Discovery

### User Outcome

Keep the current Tio phone UI visually unchanged while making `tio_core` the clear source of truth for reusable design-system values and removing parallel/duplicate token ownership where semantics genuinely match.

### Success Criteria

- Current rendered values remain unchanged unless a separate visual change is explicitly approved.
- `TioSpacing` and `TioRadius` remain distinct semantic APIs.
- Core component tokens alias existing foundation tokens only where role and value both match.
- Component-only physical dimensions remain component-owned unless repository-wide evidence proves a shared primitive is justified.
- Welcome reusable design language migrates toward `tio_core` without turning Welcome-only composition geometry into global tokens.
- `welcome_tokens.dart` is removed only after every call site has a verified value-preserving destination.
- Avatar documentation/runtime drift is resolved intentionally; no silent `100 -> 80` visual change.
- Relevant analyze/tests pass and the final diff contains no unintended visual redesign.

### Scope

This task is split into small slices:

1. **Slice 1 — inventory + safe core aliases**
   - audit foundation/component token ownership;
   - classify known alias candidates;
   - implement only exact, semantics-preserving core aliases;
   - record Welcome and Avatar findings without migrating them yet.
2. **Slice 2 — Avatar source-of-truth decision**
   - audit all semantic/custom avatar size call sites and tests;
   - decide whether runtime `100dp` or docs `80dp` is intended;
   - prefer documentation alignment if no explicit visual requirement approves a runtime change.
3. **Slice 3 — Welcome token ownership migration**
   - classify every `WelcomeDimens` / `WelcomeColors` member and call site;
   - migrate reusable roles to `tio_core`;
   - keep Welcome-only geometry local and narrowly named.
4. **Slice 4 — Welcome raw literals / dead-code cleanup**
   - classify raw colors, typography, spacing, icon/dimension values one by one;
   - remove obsolete Welcome theme/disclaimer leftovers only after reference audit.
5. **Slice 5 — docs + regression validation**
   - update `docs/UX_UI_SYSTEM.md` and task evidence;
   - run focused package tests/analyzers and inspect final diff.

### Non-Goals

- No mobile redesign.
- No Auth, Account Setup, onboarding-flow, backend, or Supabase behavior changes.
- Do not merge `TioSpacing` and `TioRadius`.
- Do not create a generic `size1...size100` token catalog.
- Do not replace literals mechanically just because numeric values are close.
- Do not normalize local values (for example `7 -> 8`) to fit a shared scale.
- Do not change `TioAvatarTokens.largeSize` from `100` to `80` without a separate product decision.
- Do not move Welcome-only illustration/layout geometry into core without reuse evidence.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
  - `.ai/workflow.md`
  - `.ai/tasks/TEMPLATE.md`
  - `apps/core/lib/src/theme/tokens/foundation/tio_spacing.dart`
  - `apps/core/lib/src/theme/tokens/foundation/tio_radius.dart`
  - `apps/core/lib/src/theme/tokens/components/tio_button_tokens.dart`
  - `apps/core/lib/src/theme/tokens/components/tio_card_tokens.dart`
  - `apps/core/lib/src/theme/tokens/components/tio_input_tokens.dart`
  - `apps/core/lib/src/theme/tokens/components/tio_navigation_tokens.dart`
  - `apps/core/lib/src/theme/tokens/components/tio_sheet_tokens.dart`
  - `apps/core/lib/src/theme/tokens/components/tio_avatar_tokens.dart`
  - `apps/features/welcome/lib/src/presentation/theme/welcome_tokens.dart`
  - `apps/features/welcome/lib/src/presentation/screen/welcome_screen.dart`
  - `apps/features/welcome/lib/src/presentation/widgets/welcome_top_bar.dart`
  - `apps/features/welcome/lib/src/presentation/widgets/welcome_feature_tile.dart`
- Existing pattern to follow:
  - semantic foundation tokens feed component tokens; component-local dimensions remain component-owned.
  - existing `TioCardTokens` already demonstrates internal semantic aliases (`selectedBorderWidth = borderThick`, etc.).
- Tests or validation already present:
  - repository Flutter CI exists;
  - focused core/Welcome/avatar tests will be identified before each UI-affecting slice.

### Slice 1 Classification

| Component token | Current | Candidate owner | Classification |
|---|---:|---|---|
| `TioButtonTokens.contentGap` | `8` | `TioSpacing.small` | safe semantic alias |
| `TioButtonTokens.radius` | `999` | `TioRadius.full` | safe semantic alias |
| `TioCardTokens.padding` | `16` | `TioSpacing.large` | safe semantic alias |
| `TioCardTokens.radius` | `16` | `TioRadius.large` | safe semantic alias |
| `TioCardTokens.radiusItem` | `8` | `TioRadius.small` | safe semantic alias |
| `TioNavigationTokens.itemRadius` | `16` | `TioRadius.large` | safe semantic alias |
| `TioSheetTokens.padding` | `24` | `TioSpacing.extraLarge` | safe semantic alias |
| `TioButtonTokens.height` | `46` | component | keep component-owned |
| `TioButtonTokens.horizontalPadding` | `20` | component / unresolved | do not alias by proximity |
| `TioInputTokens.radius` | `14` | component | keep component-owned |
| `TioInputTokens.minHeight` | `52` | component | keep component-owned |
| `TioNavigationTokens.bottomBarHeight` | `62` | component | keep component-owned |
| `TioNavigationTokens.iconSize` | `22` | component | keep component-owned |
| `TioNavigationTokens.planPillWidth` | `125` | component | keep component-owned |
| `TioSheetTokens.radius` | `28` | component | keep component-owned |

### Welcome Findings Frozen for Later Slices

- `WelcomeDimens` currently mixes reusable spacing/radius values with Welcome-specific composition geometry.
- `paddingScreen=16`, `spaceXS=8`, `spaceS=12`, `spaceSM=16`, `spaceM=24`, and `radiusL=16` have obvious numeric matches in core, but each call site must still be migrated value-preservingly.
- `spaceXXS=4`, `radiusXL=20`, feature-panel/icon geometry, border/opacity values, and raw values in `WelcomeScreen` / `WelcomeFeatureTile` require semantic classification rather than automatic token creation.
- `WelcomeColors.transparent` is a framework-primitive wrapper; adaptive/manual foreground helpers require usage review before removal.
- Welcome currently mixes private tokens, `TioSpacing`, `ColorScheme`, and raw typography/color/dimension values.

### Avatar Finding Frozen for Slice 2

- Runtime `TioAvatarTokens.largeSize = 100.0`.
- Issue/documentation history records Profile large as `80dp`.
- This task treats runtime appearance as frozen until product intent is explicitly decided; Slice 1 must not change avatar dimensions.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Preserve pixels during token ownership changes | Made | #6 is architecture cleanup, not redesign | Product/Engineering |
| Keep spacing/radius as separate semantic APIs | Made | equal values do not imply equal meaning | Design system |
| Implement seven exact component aliases in Slice 1 | Made | value + semantic role both match | Design system |
| Create `TioDimensions` now | Rejected | no repository-wide evidence yet | Design system |
| Change Avatar large `100 -> 80` now | Rejected for Slice 1 | would alter runtime UI without approval | Product |
| Delete `welcome_tokens.dart` now | Rejected | call-site classification/migration not complete | Welcome/design system |

## 4. Architecture Design

### Chosen Approach

```text
Foundation semantic tokens
        ↓
Component tokens (semantic aliases + component-local dimensions)
        ↓
Reusable core components
        ↓
Feature UI
```

Feature-specific composition geometry remains local. Shared values enter core only when repository usage demonstrates a stable reusable semantic role.

### Ownership and Data Flow

```text
TioSpacing / TioRadius
        ↓
TioButtonTokens / TioCardTokens / TioNavigationTokens / TioSheetTokens
        ↓
core UI components
        ↓
feature screens
```

### Alternative Rejected

- A generic numeric dimension catalog was rejected because it weakens semantic APIs and encourages arbitrary number-token selection.
- Mechanical Welcome literal replacement was rejected because numeric equality is insufficient evidence of shared ownership.
- Changing runtime visuals while cleaning token architecture was rejected because it violates the pixel-preserving acceptance criterion.

### Failure and Accessibility States

Token aliasing must not alter computed dimensions, hit targets, contrast, typography, navigation behavior, semantics, or accessibility output. UI-affecting later slices require before/after validation at equivalent viewport/theme states.

## 5. Implementation Plan

### Slice 1 — inventory + safe core aliases

- [x] Read #6 and implementation guardrails.
- [x] Inspect workflow/task template.
- [x] Audit foundation spacing/radius.
- [x] Audit core component token files.
- [x] Audit initial Welcome token/call-site evidence.
- [x] Freeze Avatar dimension as no-change for Slice 1.
- [ ] Alias `TioButtonTokens.contentGap` to `TioSpacing.small`.
- [ ] Alias `TioButtonTokens.radius` to `TioRadius.full`.
- [ ] Alias `TioCardTokens.padding` to `TioSpacing.large`.
- [ ] Alias `TioCardTokens.radius` to `TioRadius.large`.
- [ ] Alias `TioCardTokens.radiusItem` to `TioRadius.small`.
- [ ] Alias `TioNavigationTokens.itemRadius` to `TioRadius.large`.
- [ ] Alias `TioSheetTokens.padding` to `TioSpacing.extraLarge`.
- [ ] Add/adjust focused token-contract tests if the current core test structure supports a small durable assertion.
- [ ] Run core analyze/tests and `git diff --check` equivalent through CI/local handoff.
- [ ] Review diff for any computed-value change.

### Later slices

- [ ] Audit Avatar call sites/tests and freeze source of truth.
- [ ] Inventory every Welcome private token and usage.
- [ ] Inventory raw reusable Welcome values.
- [ ] Decide whether any missing shared primitive is justified.
- [ ] Migrate Welcome reusable design language value-preservingly.
- [ ] Remove obsolete Welcome parallel theme files only after zero references.
- [ ] Update docs and final validation evidence.

## 6. Quality Review

### Validation Run

```text
Slice 1 discovery complete.
Source alias implementation and validation not run yet.
```

### Review Findings and Resolution

- No evidence currently justifies a generic physical-dimension foundation.
- Seven component aliases are safe candidates because their semantic role and exact runtime value match existing foundation contracts.
- Welcome migration is deliberately deferred from Slice 1 to keep the first code diff narrow and auditable.
- Avatar runtime remains unchanged pending a source-of-truth decision.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/design-system-token-consolidation.md` (task brief; Slice 1 start)

### Actual Behavior

No runtime behavior changed by the task-brief commit.

### Known Limitations

Repository-wide usage inventory, Avatar decision, Welcome migration, source aliases, and validation remain in progress.

### Final Status

`PARTIAL`
