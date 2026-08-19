# Design System Slice E — Product Onboarding

**Status:** Validated  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Migrate Product Onboarding presentation to governed core design-system ownership without changing onboarding sequence, persistence, validation, or visible design.

## Mandatory Visual Freeze

```text
pixels before == pixels after
```

No layout, spacing, color appearance, typography appearance, radius, icon/image sizing, picker geometry, motion, gradient, or component geometry may change without separate explicit owner/design approval.

## Preconditions

- [x] Slice A validated by Flutter CI #624.
- [x] Slice B validated by Flutter CI #646.
- [x] Slice C validated by Flutter CI #710.
- [x] Slice D Auth + Account Setup validated; final source/catalog boundary passed Flutter CI #742.
- [x] Theme README-first workflow and component-token admission gate are active.

## Hard Boundaries

- no onboarding step/order changes;
- no draft/resume/completion behavior changes;
- no persistence/Supabase changes;
- no app-mode business-rule changes;
- no feature token/color/layout/theme catalog;
- no `OnboardingTokens`, screen-specific core token class, or equivalent replacement bag;
- behavior/domain/program values remain outside the design-token system;
- the separate reusable-field Issue #24 is not implemented unless explicitly expanded later.

## Ownership Order

```text
Existing reusable core component
        ↓
Existing runtime semantic role / TextTheme
        ↓
Existing reusable component contract
        ↓
Existing exact governed primitive
        ↓
Only then consider a narrowly evidenced reusable core extension
```

## Checklist

### E1 — Inventory and classification

- [x] Inventory onboarding screen/widget visual literals and helper/theme/token files.
- [x] Classify colors, typography, geometry, strokes, opacity/alpha, motion, picker factors/ratios and fixed responsive values.
- [x] Separate behavior/domain/program values from product-visible fixed visual values.
- [x] Record exact current rendered values before mutation.

### E2 — Ownership plan

- [x] Reuse governed core primitives/roles/components first.
- [x] Apply `.ai/tasks/design-system-hardcoded-color-audit.md`.
- [x] Identify feature-owned visual/token catalogs for removal.
- [x] Reject proposed component token classes that fail the admission gate.
- [x] Keep genuine one-off composition data local instead of creating an Onboarding token bag.

### E3 — Implementation

- [x] Migrate onboarding consumers in bounded batches.
- [x] Preserve picker geometry, field visuals, progress chrome and navigation visuals exactly.
- [x] Delete obsolete feature visual/token helpers only after zero-reference verification.

### E4 — Validation

- [x] Run focused onboarding tests/static audit.
- [x] Verify no onboarding sequence/persistence/validation/business behavior changed.
- [x] Verify no unapproved visible UI change occurred.
- [x] Run analyze and required CI.
- [x] Record evidence, mark `Validated`, and unblock Slice F.

## Validation Evidence

### Core ownership migration

- Product Onboarding shell, dialogs, data sheet, top/bottom chrome, progress, content host and wheel surfaces consume governed core roles/primitives.
- App Mode, Profile, Workout, Targets, Review, Compatibility and Congratulations presentation surfaces were migrated in bounded batches.
- Feature-owned onboarding visual/token proxy catalogs and their proxy-only contract tests were removed after consumer migration and zero-reference verification.
- Exact fixed visual ownership was added only where production evidence required it across `TioSize`, `TioOpacity`, `TioAlpha`, `TioDuration`, typography primitives, palette/domain colors and existing reusable component contracts.
- No `OnboardingTokens`, screen-specific core token bag or replacement feature catalog was introduced.

### Values intentionally kept outside design tokens

The following remain local because they are behavior/domain/program or genuine one-off composition data rather than reusable visual-token roles:

- onboarding sequence, controller behavior and persistence timing such as draft autosave debounce;
- profile/target calculations, calorie/BMI/goal-pace formulas, validation ranges and program thresholds;
- wheel conversion math and picker behavior ratios where not shared core contracts;
- Congratulations confetti physics and gradient stop composition;
- equipment/focus-area grid composition ratios;
- experience-level signal-bar composition geometry;
- Goal Pace graph control-point ratios and domain timeline math.

### Framework exception

`CongratulationsScreen` keeps transparent system status/navigation bar values required for edge-to-edge Flutter system UI. Visible media/background/text/gradient colors are governed through Tio theme/palette roles.

### Static enforcement

`apps/features/onboarding/test/presentation/onboarding_design_system_ownership_test.dart` enforces Product Onboarding visual ownership and rejects:

- direct framework/raw production colors;
- raw font weights, font sizes and letter spacing;
- raw opacity/alpha values;
- raw millisecond visual durations;
- legacy spacing/radius compatibility aliases.

Controller behavior/program timing is intentionally excluded from the visual gate.

### CI

Flutter CI **#825** passed on the final Slice E implementation head `1c1d9f12f068b4ba333594d072cdbb9c5c921f48`:

- Flutter package analyze — passed;
- Dart package analyze — passed;
- Flutter package tests, including the Product Onboarding ownership gate and existing onboarding behavior tests — passed;
- Dart package tests — passed.

No onboarding sequencing, draft/resume/completion, validation, persistence/Supabase or App Mode business behavior was intentionally changed by Slice E.

## Completion Lifecycle

1. Inventory ✅
2. Classification ✅
3. Planned ownership ✅
4. Implementation ✅
5. Focused tests ✅
6. Static audit ✅
7. Pixel/UI regression ownership review ✅
8. Analyze ✅
9. Required CI ✅ — Flutter CI #825
10. Update evidence ✅
11. Mark `Validated` ✅
12. Unblock Slice F ✅

## Exit Criteria

- [x] onboarding consumes canonical core visual ownership;
- [x] no feature token/color/layout/theme catalog remains for Product Onboarding;
- [x] no screen/workflow-specific core token class was introduced;
- [x] onboarding behavior remains unchanged by the design-system migration;
- [x] no visible UI change was intentionally introduced outside existing approved governance;
- [x] tests/analyze/required CI pass.
