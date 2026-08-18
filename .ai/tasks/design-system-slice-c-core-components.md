# Design System Slice C — Core Components

**Status:** Blocked by Slices A and B  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Audit reusable core components and their token contracts so component APIs express reusable intent without becoming screen-specific numeric/style bags.

## Mandatory Visual Freeze

No visible component or screen appearance may change without separate explicit owner/design approval. Existing geometry, color, typography, state layers, motion and interaction visuals must remain pixel-preserving by default.

## Preconditions

- [ ] Slice A is `Validated`.
- [ ] Slice B is `Validated`.

## Scope

Reusable core UI and shell contracts including buttons, cards, inputs, avatars, sheets, navigation, headers/layout helpers, pickers and other shared components.

## Ownership Rule

```text
Reusable component → component tokens
Reusable semantic role → foundation/semantic/typography/effects
One-off screen visual → governed core primitive/role directly
Screen-specific core token bag → forbidden
```

A class must not be retained merely because it already exists under `tokens/components/`.

## Checklist

- [ ] Audit every reusable component and its current token dependencies.
- [ ] Confirm component token classes represent actual reusable component contracts.
- [ ] Reclassify oversized/screen-proxy token bags where necessary.
- [ ] Remove raw physical values from component contracts.
- [ ] Ensure colors resolve through governed semantic/domain/component roles.
- [ ] Ensure typography resolves through governed typography roles.
- [ ] Ensure geometry/strokes/opacities/durations/factors resolve through canonical ownership.
- [ ] Preserve intentional pixel differences such as distinct Material-vs-custom component contracts until separately approved.
- [ ] Update component/contract tests to lock alias ownership and current rendering.
- [ ] Run focused core UI tests, static audit, analyze and required CI.

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
12. Unblock Slice D

## Exit Criteria

- reusable component token classes are justified and semantic;
- no component class independently owns physical visual values;
- no screen-specific token bag is hidden under core components;
- no unapproved visible UI change occurred;
- tests/analyze/required CI pass.
