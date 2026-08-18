# Design System Token Consolidation

**Status:** In progress
**Primary owner:** `apps/core` design-system tokens; `apps/features/welcome` as the first migration consumer
**Affected platforms:** Flutter mobile UI
**Related issue:** #6
**Working branch:** `codex/design-system-token-consolidation`
**Draft PR:** #22

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
- Avatar documentation/runtime drift is resolved intentionally without silently changing runtime pixels.
- Relevant analyze/tests pass and the final diff contains no unintended visual redesign.

### Scope

1. **Slice 1 — inventory + safe core aliases** — implemented and CI validated.
2. **Slice 2 — Avatar source-of-truth decision** — implemented and CI validated.
3. **Slice 3 — Welcome token ownership migration** — next.
4. **Slice 4 — Welcome raw literals / dead-code cleanup** — pending.
5. **Slice 5 — docs + regression validation** — pending.

### Non-Goals

- No mobile redesign.
- No Auth, Account Setup, onboarding-flow, backend, or Supabase behavior changes.
- Do not merge `TioSpacing` and `TioRadius`.
- Do not create a generic `size1...size100` token catalog.
- Do not replace literals mechanically just because numeric values are close.
- Do not normalize local values (for example `7 -> 8`) to fit a shared scale.
- Do not move Welcome-only illustration/layout geometry into core without reuse evidence.

## 2. Codebase Exploration

### Verified Evidence

Inspected:

- `.ai/workflow.md`
- `.ai/tasks/TEMPLATE.md`
- core foundation spacing/radius tokens
- all current core component token files
- `TioAvatar` and semantic avatar-size mapping
- Profile/Profile Settings avatar call sites
- full-screen Avatar Preview custom-dimension behavior
- Welcome private tokens and initial call sites
- `docs/UX_UI_SYSTEM.md`
- `docs/screens/profile.md`
- `docs/screens/profile-avatar.md`
- avatar regression tests

Existing pattern:

```text
Foundation semantic tokens
        ↓
Component tokens
        ↓
Reusable core components
        ↓
Feature screens
```

Component-local physical dimensions remain component-owned unless repository-wide evidence proves a reusable semantic primitive.

### Slice 1 Classification

| Component token | Previous | Owner after Slice 1 | Result |
|---|---:|---|---|
| `TioButtonTokens.contentGap` | `8` | `TioSpacing.small` | aliased |
| `TioButtonTokens.radius` | `999` | `TioRadius.full` | aliased |
| `TioCardTokens.padding` | `16` | `TioSpacing.large` | aliased |
| `TioCardTokens.radius` | `16` | `TioRadius.large` | aliased |
| `TioCardTokens.radiusItem` | `8` | `TioRadius.small` | aliased |
| `TioNavigationTokens.itemRadius` | `16` | `TioRadius.large` | aliased |
| `TioSheetTokens.padding` | `24` | `TioSpacing.extraLarge` | aliased |
| `TioButtonTokens.height` | `46` | component | unchanged |
| `TioInputTokens.radius` | `14` | component | unchanged |
| `TioInputTokens.minHeight` | `52` | component | unchanged |
| `TioNavigationTokens.bottomBarHeight` | `62` | component | unchanged |
| `TioNavigationTokens.iconSize` | `22` | component | unchanged |
| `TioNavigationTokens.planPillWidth` | `125` | component | unchanged |
| `TioSheetTokens.radius` | `28` | component | unchanged |

### Welcome Findings Frozen for Slice 3+

- `WelcomeDimens` mixes reusable spacing/radius values with Welcome-specific composition geometry.
- `paddingScreen=16`, `spaceXS=8`, `spaceS=12`, `spaceSM=16`, `spaceM=24`, and `radiusL=16` have direct numeric matches in core, but each usage still needs semantic/value-preserving migration.
- `spaceXXS=4`, `radiusXL=20`, feature-panel/icon geometry, border/opacity values, and raw values in Welcome require classification instead of automatic token creation.
- `WelcomeColors.transparent` is a framework-primitive wrapper; other color helpers require usage review before removal.
- No Welcome runtime source was changed in Slice 1 or Slice 2.

### Slice 2 Avatar Decision

Verified runtime contract:

- `TioAvatarTokens.largeSize = 100.0`.
- `TioAvatarSize.large.dimension` delegates to that token.
- `ProfilePage` and `ProfileSettingsPage` use semantic `large`.
- shell Profile entry uses semantic `small = 36`.
- `AvatarPreviewPage` uses screen-derived `customDimension`; it is not a fixed `extraLarge=160` preview.
- `tio_avatar_test.dart` explicitly asserts `small=36`, `large=100`, `extraLarge=160`.
- no assertion enforces an 80dp runtime Profile avatar.

Decision: **runtime `large=100dp` is authoritative.** Canonical UI/Profile docs and stale test wording were aligned to 100dp. Profile Photo docs were also corrected to describe the actual screen-sized `customDimension` preview while retaining `extraLarge=160` as a reusable semantic token.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Preserve pixels during token ownership changes | Made | #6 is architecture cleanup, not redesign |
| Keep spacing/radius as separate semantic APIs | Made | equal values do not imply equal meaning |
| Seven exact component aliases | Implemented | semantic role + exact runtime value match |
| Create `TioDimensions` now | Rejected | no repository-wide evidence yet |
| Avatar large source of truth | Implemented: `100dp` runtime | runtime token + call sites + explicit core test agree |
| Change Avatar large `100 -> 80` | Rejected | would create an unapproved visual change |
| Delete `welcome_tokens.dart` now | Rejected | migration/classification not complete |

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

Feature-specific composition geometry stays local. Shared values enter core only when usage demonstrates a stable reusable semantic role.

### Failure and Accessibility States

Token ownership changes must not alter computed dimensions, hit targets, contrast, typography, navigation behavior, semantics, or accessibility output. UI-affecting later slices require before/after validation at equivalent viewport/theme states.

## 5. Implementation Plan

### Slice 1 — inventory + safe core aliases

- [x] Read #6 and implementation guardrails.
- [x] Inspect workflow/task template.
- [x] Audit foundation/component tokens.
- [x] Alias Button `contentGap` and `radius`.
- [x] Alias Card `padding`, `radius`, and `radiusItem`.
- [x] Alias Navigation `itemRadius`.
- [x] Alias Sheet `padding`.
- [x] Add focused token-contract tests.
- [x] Review source diff for computed-value changes.
- [x] GitHub CI #399: bootstrap, Flutter/Dart analyze, Flutter/Dart tests all passed on source head `24c4dbd`.

### Slice 2 — Avatar source of truth

- [x] Audit semantic-size mapping.
- [x] Audit Profile/Profile Settings/shell/preview call sites.
- [x] Audit avatar tests.
- [x] Decide source of truth: runtime `large=100dp`.
- [x] Align `docs/UX_UI_SYSTEM.md` to 100dp and actual preview behavior.
- [x] Align Profile/Profile Photo screen docs to 100dp.
- [x] Rename stale `profile_page_test.dart` 80dp description without changing behavior.
- [x] GitHub CI #401: bootstrap, Flutter/Dart analyze, Flutter/Dart tests all passed on head `18e8d89`.

### Slice 3 — Welcome ownership migration

- [ ] Inventory every `WelcomeDimens` / `WelcomeColors` member and usage.
- [ ] Classify each as existing core token / missing shared role / component token / Welcome-only composition / obsolete.
- [ ] Migrate reusable values with exact runtime-value preservation.
- [ ] Keep composition geometry local.

### Slice 4/5

- [ ] Classify raw reusable Welcome colors/typography/spacing/dimensions.
- [ ] Remove obsolete Welcome theme/dead code only after zero references.
- [ ] Update final design-system docs and validation evidence.

## 6. Quality Review

### Validation Run

```text
GitHub Flutter CI #399 on source head 24c4dbd:
- Workspace bootstrap: PASS
- Flutter analyze: PASS
- Dart analyze: PASS
- Flutter tests: PASS
- Dart tests: PASS

GitHub Flutter CI #401 on head 18e8d89:
- Workspace bootstrap: PASS
- Flutter analyze: PASS
- Dart analyze: PASS
- Flutter tests: PASS
- Dart tests: PASS
```

### Review Findings and Resolution

- Seven aliases preserve exact computed values.
- No evidence currently justifies a generic physical-dimension foundation.
- Avatar runtime is internally consistent at 100dp; canonical docs now match runtime truth.
- The Profile Photo preview is screen-sized via `customDimension`; `extraLarge=160` remains a reusable semantic size rather than that route's actual runtime size.
- Welcome migration remains deliberately separate from the first two slices.

## 7. Final Handoff

### Changed Files So Far

- `.ai/tasks/design-system-token-consolidation.md`
- `apps/core/lib/src/theme/tokens/components/tio_button_tokens.dart`
- `apps/core/lib/src/theme/tokens/components/tio_card_tokens.dart`
- `apps/core/lib/src/theme/tokens/components/tio_navigation_tokens.dart`
- `apps/core/lib/src/theme/tokens/components/tio_sheet_tokens.dart`
- `apps/core/test/theme/token_alias_contract_test.dart`
- `apps/features/profile/test/presentation/profile_page_test.dart`
- `docs/UX_UI_SYSTEM.md`
- `docs/screens/profile.md`
- `docs/screens/profile-avatar.md`

### Actual Behavior

Slices 1-2 change token ownership and documentation/test wording only. Computed runtime values and rendered UI remain unchanged.

### Known Limitations

Welcome token migration/raw-literal cleanup remain open. Global `.ai` orientation files contain older project snapshots and are not treated as canonical runtime truth for this narrow slice.

### Final Status

`PARTIAL`
