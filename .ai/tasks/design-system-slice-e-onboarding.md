# Design System Slice E — Product Onboarding

**Status:** In progress  
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

- [ ] Inventory onboarding screen/widget visual literals and helper/theme/token files.
- [ ] Classify colors, typography, geometry, strokes, opacity/alpha, motion, picker factors/ratios and fixed responsive values.
- [ ] Separate behavior/domain/program values from product-visible fixed visual values.
- [ ] Record exact current rendered values before mutation.

### E2 — Ownership plan

- [ ] Reuse governed core primitives/roles/components first.
- [ ] Apply `.ai/tasks/design-system-hardcoded-color-audit.md`.
- [ ] Identify feature-owned visual/token catalogs for removal.
- [ ] Reject any proposed component token class that fails the admission gate.
- [ ] Keep genuine one-off composition data local instead of creating an Onboarding token bag.

### E3 — Implementation

- [ ] Migrate onboarding consumers in bounded batches.
- [ ] Preserve picker geometry, field visuals, progress chrome and navigation visuals exactly.
- [ ] Delete obsolete feature visual/token helpers only after zero-reference verification.

### E4 — Validation

- [ ] Run focused onboarding tests/static audit.
- [ ] Verify no onboarding sequence/persistence/validation/business behavior changed.
- [ ] Verify no unapproved visible UI change occurred.
- [ ] Run analyze and required CI.
- [ ] Record evidence, mark `Validated`, and unblock Slice F.

## Completion Lifecycle

1. Inventory
2. Classification
3. Planned ownership
4. Implementation
5. Focused tests
6. Static audit
7. Pixel/UI regression check
8. Analyze
9. Required CI
10. Update evidence
11. Mark `Validated`
12. Unblock Slice F

## Exit Criteria

- onboarding consumes canonical core visual ownership;
- no feature token/color/layout/theme catalog remains;
- no screen/workflow-specific core token class is introduced;
- onboarding behavior is unchanged;
- no visible UI change occurred without separate approval;
- tests/analyze/required CI pass.
