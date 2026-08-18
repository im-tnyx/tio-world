# Design System Token Consolidation

**Status:** In progress
**Primary owner:** `apps/core` design-system contracts; every Flutter screen is a consumer
**Affected platforms:** Flutter mobile UI
**Related issue:** #6
**Working branch:** `codex/design-system-token-consolidation`
**Draft PR:** #22

## 1. Product Outcome

Tio must use one professional, governed design system across the phone app. Screen and widget files must not invent visual values ad hoc. Reusable styling comes from `tio_core`; feature-only composition values use narrowly named role tokens rather than anonymous numbers.

The migration remains pixel-preserving unless a separate visual-design decision explicitly approves a change.

## 2. Non-Negotiable Design-System Rules

### No Random Visual Literals

Final production screen/widget code must not contain unexplained hardcoded styling values for:

- spacing / padding / gaps
- radius / shape
- fixed width / height / min size
- icon size
- border / stroke width
- opacity / alpha
- typography size / weight / line height / letter spacing
- animation duration / easing
- reusable colors
- elevation / shadow
- recurring layout dimensions

A value is not made acceptable merely by moving `20.0` into a file-local constant. It must have an intentional token role.

### Token Taxonomy

```text
Foundation tokens
  spacing / radius / primitive size / stroke / opacity / motion
        ↓
Semantic tokens
  colors / typography / state / domain roles
        ↓
Component tokens
  button / input / card / avatar / navigation / sheet / reusable widgets
        ↓
Feature composition tokens (only when truly feature-specific)
  e.g. WelcomeLayoutTokens.featurePanelRadius
        ↓
Screen/widget implementation
```

Rules:

1. **Use an existing token first.**
2. If no token exists, classify the role before adding one.
3. Add a foundation token only when it is a stable reusable scale value.
4. Add a component token when the value belongs to a reusable component contract.
5. Add a feature composition token only when the value is intentionally feature-specific and not reusable elsewhere.
6. Feature tokens should alias core foundation/semantic tokens whenever possible.
7. Never create `size4`, `radius20`, `value56`, or a generic numeric catalog solely to hide literals.
8. Never normalize pixels to the nearest existing token without explicit visual approval.
9. Theme-aware colors and typography should come from `TioTheme`, `ColorScheme`, `TextTheme`, semantic tokens, or explicit component tokens—not arbitrary screen colors/styles.
10. Any new token requires a semantic name, owner, usage evidence, and focused contract/test coverage where practical.

### Allowed Non-Design Literals

This rule targets **visual design values**. Normal program/data literals remain allowed when they are not design decisions, for example loop indexes, enum/data values, mathematical zero/one, validation limits, IDs, dates, and business calculations.

Responsive values derived from runtime constraints may remain expressions, but any reusable design factor or breakpoint must itself have an intentional token/contract.

## 3. Current Foundation Evidence

Current shared foundations are intentionally small:

```text
TioSpacing: small=8, medium=12, large=16, extraLarge=24
TioRadius: small=8, medium=12, large=16, extraLarge=24, full=999
```

A common `4dp` rhythm is now evidenced by real layout usage and is eligible to become a named smallest spacing foundation role (for example `TioSpacing.extraSmall = 4`) rather than being repeated as file-local `4.0`.

A Welcome-only `20dp` feature-panel radius is **not** enough evidence for a generic shared `20` radius primitive. It should live behind a semantic Welcome composition token such as `WelcomeLayoutTokens.featurePanelRadius` until broader reuse proves a shared role.

## 4. Completed Slices

### Slice 1 — Core Component Aliases

Exact-value aliases implemented:

| Component token | Previous | Current owner |
|---|---:|---|
| `TioButtonTokens.contentGap` | `8` | `TioSpacing.small` |
| `TioButtonTokens.radius` | `999` | `TioRadius.full` |
| `TioCardTokens.padding` | `16` | `TioSpacing.large` |
| `TioCardTokens.radius` | `16` | `TioRadius.large` |
| `TioCardTokens.radiusItem` | `8` | `TioRadius.small` |
| `TioNavigationTokens.itemRadius` | `16` | `TioRadius.large` |
| `TioSheetTokens.padding` | `24` | `TioSpacing.extraLarge` |

CI #399 passed full bootstrap/analyze/test on source head `24c4dbd`.

### Slice 2 — Avatar Source Of Truth

Runtime/test contract is `small=36`, `large=100`, `extraLarge=160`. Profile/Profile Settings use semantic `large`; shell uses `small`; Profile Photo uses a responsive `customDimension` preview.

Runtime `large=100dp` remains unchanged. Stale 80dp docs/test wording was aligned to runtime. CI #401 passed full bootstrap/analyze/test on head `18e8d89`.

## 5. Welcome Migration — Revised Professional Standard

### Existing Migration

`WelcomeDimens` / `WelcomeColors` were removed from live screen usage and reusable values were mapped to core tokens. Source head `1ad507e` is currently under CI validation.

### Required Follow-Up Before Welcome Is Considered Complete

The current temporary file-local visual constants introduced during migration are **not final architecture** under the new governance:

- `_topBarVerticalPadding = 4.0`
- `_featureDividerHorizontalMargin = 4.0`
- `_featurePanelRadius = 20.0`

They must be replaced by governed tokens:

- add the proven common `4dp` role to the spacing foundation and consume it through `TioSpacing`;
- create a narrow Welcome composition token contract for the intentional 20dp panel radius (and any other truly Welcome-only visual geometry that survives the audit);
- do not recreate the old catch-all `WelcomeDimens` bag.

### Welcome Raw-Value Audit

Audit and classify every remaining Welcome visual literal in:

- `welcome_screen.dart`
- `welcome_top_bar.dart`
- `welcome_feature_tile.dart`
- `welcome_backdrop.dart`
- any live Welcome route/component

Each value must end as one of:

1. existing core token/theme role;
2. newly justified core foundation/semantic/component token;
3. narrowly scoped `WelcomeLayoutTokens` / equivalent feature composition token;
4. non-design program literal with documented reason;
5. obsolete code removed.

Do **not** blindly tokenise gradient math, responsive calculations, or one-off visuals; first identify their semantic design role.

### Welcome Legal Orphans

`WelcomeDisclaimer` has no live call site. Its four legal-copy fields exist only for that orphan widget. Product intent keeps the Welcome legal footer removed while shared `TioTermsDisclaimer` remains available for Auth. Remove only the Welcome orphan wrapper/state after final reference audit.

## 6. Repository-Wide Professional Token Audit

Issue #6 is now treated as the design-system governance foundation, not merely a Welcome cleanup. After Welcome establishes the pattern, audit all active Flutter surfaces in bounded slices.

### Audit Order

1. `apps/core` reusable components and shell
2. Welcome
3. Auth + Account Setup
4. Product Onboarding
5. Home + shell-owned surfaces
6. Profile + Settings
7. Workout
8. Nutrition
9. Progress / remaining active phone features
10. app-level composed screens and tests

Each package gets an inventory before edits. Do not mix unrelated features into one commit.

### Per-Screen Checklist

For every active screen/widget:

- [ ] colors use theme/semantic/component roles;
- [ ] typography uses `TextTheme` / typography/component roles;
- [ ] spacing uses `TioSpacing` or semantic component/feature layout tokens;
- [ ] radius/shape uses `TioRadius` or semantic component/feature tokens;
- [ ] icon dimensions use a governed size/component token;
- [ ] fixed component dimensions use component tokens;
- [ ] borders/strokes use governed roles;
- [ ] opacity/state layers use governed roles;
- [ ] motion uses `TioMotionScheme` / motion tokens;
- [ ] responsive factors/breakpoints have named contracts when reusable;
- [ ] no accidental pixel change;
- [ ] no duplicate private token bag shadowing `tio_core`;
- [ ] focused tests/analyze pass.

## 7. Enforcement / Quality Gate

Before final completion:

- add/update token contract tests;
- add a practical static-audit strategy for obvious raw visual literals in production screen/widget paths where it can be reliable without blocking legitimate business/math constants;
- document intentional exceptions rather than silently allowing them;
- run full Flutter/Dart analyze and tests;
- review the PR diff feature-by-feature;
- perform light/dark and compact-width validation for UI-touching migrations where practical.

A regex-only ban is not sufficient by itself because it cannot distinguish business numbers from design numbers. Enforcement should combine token ownership conventions, code review, focused tests, and targeted static checks.

## 8. Architecture Decisions

| Decision | Status |
|---|---|
| Preserve current pixels during ownership migration | Required |
| Screen/widget raw visual styling values | Disallowed final state |
| `TioSpacing` and `TioRadius` | Keep separate |
| Generic `TioDimensions.sizeN` catalog | Rejected |
| Common 4dp spacing foundation role | Approved by usage evidence |
| Generic shared 20dp radius only for Welcome | Rejected |
| Welcome semantic composition token for 20dp panel | Approved |
| Feature token bags duplicating core scales | Rejected |
| Component-specific dimensions | Keep with component owner |
| Theme/semantic typography and colors | Required |
| Repo-wide screen audit | Required, sliced by package |

## 9. Implementation Plan From This Checkpoint

### Slice 3B — Finish Welcome Token Architecture

- [ ] wait for / inspect CI on `1ad507e`;
- [ ] add `TioSpacing.extraSmall = 4` with contract coverage;
- [ ] create narrow Welcome composition token contract for remaining feature-only geometry;
- [ ] replace temporary file-local visual constants;
- [ ] inventory and classify remaining Welcome raw visual literals;
- [ ] migrate only values with clear semantic destinations;
- [ ] remove obsolete Welcome-only legal wrapper/state;
- [ ] full CI + diff audit.

### Slice 4+ — Package Audits

- [ ] core reusable components/shell raw-value audit;
- [ ] Auth + Account Setup audit;
- [ ] Product Onboarding audit;
- [ ] Home/Profile/Settings audit;
- [ ] Workout/Nutrition/Progress audit;
- [ ] remaining app screen audit;
- [ ] final docs/enforcement/tests.

## 10. Quality Evidence

```text
CI #399 — PASS (Slice 1 source head 24c4dbd)
CI #401 — PASS (Slice 2 head 18e8d89)
CI #404 — validating Welcome source head 1ad507e at time of governance update
```

## 11. Final Status

`PARTIAL — professional token governance approved; repo-wide screen migration remains in progress.`
