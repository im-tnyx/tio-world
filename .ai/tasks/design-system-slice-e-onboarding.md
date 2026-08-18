# Design System Slice E — Product Onboarding

**Status:** Blocked by Slice D  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Migrate Product Onboarding presentation to governed core design-system ownership without changing onboarding sequence, persistence, validation, or visible design.

## Mandatory Visual Freeze

No layout, spacing, color appearance, typography appearance, radius, icon/image sizing, picker geometry, motion, gradient, or component geometry may change without separate explicit owner/design approval.

## Preconditions

- [ ] Slices A–D are `Validated`.

## Hard Boundaries

- no onboarding step/order changes;
- no draft/resume/completion behavior changes;
- no persistence/Supabase changes;
- no app-mode business-rule changes;
- no feature token catalog.

## Checklist

- [ ] Inventory onboarding screen/widget visual literals and helpers.
- [ ] Classify colors, typography, geometry, strokes, opacity/alpha, motion, picker factors/ratios and fixed responsive values.
- [ ] Reuse governed core primitives/roles/components first.
- [ ] Apply `.ai/tasks/design-system-hardcoded-color-audit.md`.
- [ ] Remove feature-owned visual/token catalogs if found.
- [ ] Preserve all existing rendered values and interaction visuals.
- [ ] Run focused onboarding tests/static audit.
- [ ] Run analyze and required CI.

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
- no feature token catalog remains;
- onboarding behavior is unchanged;
- no visible UI change occurred without separate approval;
- tests/analyze/required CI pass.
