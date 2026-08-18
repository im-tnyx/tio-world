# Design System Slice D — Auth + Account Setup

**Status:** Blocked by Slice C  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Migrate Auth and Account Setup production UI to governed core design-system ownership without changing authentication behavior, account-setup flow, or rendered UI.

## Mandatory Visual Freeze

No screen design, layout, spacing, color appearance, typography appearance, radius, icon/image sizing, motion, gradient, or component geometry may change without separate explicit owner/design approval.

## Preconditions

- [ ] Slices A–C are `Validated`.

## Scope

Auth and Account Setup presentation files plus narrowly required core design-system contracts.

## Hard Boundaries

- no auth/session architecture changes;
- no provider/sign-in behavior changes;
- no Account Setup sequencing/business-rule changes;
- no legal placement move/removal/addition unless separately approved;
- no feature token catalog.

## Checklist

- [ ] Inventory screen/widget visual literals and feature-local visual helpers.
- [ ] Classify colors, typography, geometry, strokes, opacity/alpha, motion and fixed factors.
- [ ] Reuse governed core primitives/roles/components first.
- [ ] Apply `.ai/tasks/design-system-hardcoded-color-audit.md`.
- [ ] Remove feature-owned visual/token catalogs if any are found.
- [ ] Preserve every existing rendered value and interaction visual.
- [ ] Run focused Auth/Account Setup tests and static audits.
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
12. Unblock Slice E

## Exit Criteria

- Auth/Account Setup consume canonical core design-system ownership;
- no feature token catalog remains;
- behavior is unchanged;
- no visible UI change occurred without separate approval;
- tests/analyze/required CI pass.
