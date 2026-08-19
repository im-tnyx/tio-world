# Design System Slice F — Home + Profile + Settings

**Status:** Ready  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Migrate Home, Profile, and Settings presentation to governed core design-system ownership while preserving current product behavior and visible UI.

## Mandatory Visual Freeze

No layout, spacing, color appearance, typography appearance, radius, icon/image sizing, shell styling, motion, gradient, or component geometry may change without separate explicit owner/design approval.

## Preconditions

- [x] Slices A–E are `Validated`.
- [x] Slice E final implementation passed Flutter CI #825.

## Hard Boundaries

- no profile persistence/domain changes;
- no Settings behavior changes unrelated to styling;
- no ThemeMode/AppThemeController behavior changes;
- no navigation/business-flow changes;
- no feature token catalog.

## Checklist

- [ ] Inventory Home/Profile/Settings visual literals and helpers.
- [ ] Classify colors, typography, geometry, strokes, opacity/alpha, motion and fixed responsive values.
- [ ] Reuse governed core primitives/roles/components first.
- [ ] Apply `.ai/tasks/design-system-hardcoded-color-audit.md`.
- [ ] Keep `AppThemeController` app-level state/persistence responsibility intact.
- [ ] Remove feature-owned visual/token catalogs if found.
- [ ] Preserve existing rendering and behavior.
- [ ] Run focused tests/static audit.
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
12. Unblock Slice G

## Exit Criteria

- Home/Profile/Settings consume canonical core visual ownership;
- theme-mode state architecture remains unchanged;
- no feature token catalog remains;
- no visible UI change occurred without separate approval;
- tests/analyze/required CI pass.
