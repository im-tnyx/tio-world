# Design System Slice G — Remaining UI

**Status:** Ready  
**Current phase:** Inventory  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Migrate Workout, Nutrition, Progress, remaining phone UI, Wear UI, and any uncategorized production presentation code to governed core design-system ownership.

## Mandatory Visual Freeze

No visible UI change is allowed without separate explicit owner/design approval. Preserve current layout, spacing, colors, typography, radius, icon/image sizing, motion, gradients, component geometry and responsive behavior.

## Preconditions

- [x] Slices A–F are `Validated`.
- [x] Slice F final implementation head `da9e60d6b8a5afc1b293d59cef7a7aacce5553c4` passed Flutter CI #843.

## Scope

Remaining production Flutter UI not already covered by earlier slices, executed package-by-package with bounded diffs.

Initial inventory must identify all remaining production presentation packages and separate fixed product-visible values from behavior/domain/program values before any mutation.

## Hard Boundaries

- no workout/nutrition/progress business-rule changes;
- no domain calculation changes;
- no persistence/Supabase changes;
- no navigation behavior changes unrelated to styling;
- no feature token catalogs.

## Checklist

- [ ] Build a remaining-package inventory before edits.
- [ ] Process one package or bounded UI surface at a time.
- [ ] Classify all fixed visual values before migration.
- [ ] Reuse governed core primitives/roles/components first.
- [ ] Apply `.ai/tasks/design-system-hardcoded-color-audit.md`.
- [ ] Remove feature-owned visual/token catalogs.
- [ ] Preserve platform-specific behavior where intentional.
- [ ] Run focused package tests/static audit after each bounded migration.
- [ ] Run analyze and required CI at package/slice boundaries.

## Execution Rule

Do not begin implementation by broad search-and-replace. First establish the remaining-package inventory and classification, then migrate one bounded package/surface at a time. Reuse existing core ownership before introducing any new evidenced primitive or semantic contract.

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
12. Unblock Slice H

## Exit Criteria

- all remaining production UI consumes governed core visual ownership;
- no feature-owned design-token catalogs remain in migrated scope;
- no unapproved visible UI changes occurred;
- tests/analyze/required CI pass.
