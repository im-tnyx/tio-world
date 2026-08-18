# Design System Slice B — Welcome Cleanup

**Status:** Blocked by Slice A  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Remove the transitional Welcome-owned visual token catalog and migrate Welcome to governed core primitives, semantic roles, typography/effects, and reusable components without changing rendered UI.

## Mandatory Visual Freeze

No Welcome layout, spacing, color appearance, typography appearance, radius, image/icon sizing, gradient, motion, or component geometry may change without separate explicit owner/design approval.

`pixels before == pixels after` is the default contract.

## Preconditions

- [ ] Slice A is `Validated`.
- [ ] Canonical primitive/core ownership is stable.
- [ ] Color audit rules are available from `.ai/tasks/design-system-hardcoded-color-audit.md`.

## Scope

- `apps/features/welcome/**`
- focused shared/core contracts only when an evidenced missing reusable role is discovered
- Welcome-focused tests

## Hard Boundaries

- no Auth behavior changes;
- no onboarding flow changes;
- no legal placement restoration/movement;
- no feature-owned replacement token file;
- no screen redesign.

## Checklist

- [ ] Inventory every value in `welcome_visual_tokens.dart`.
- [ ] Classify each as geometry, color, typography, motion/effect, reusable component role, fixed factor/ratio, or genuine runtime/program value.
- [ ] Reuse existing governed core ownership first.
- [ ] Add missing core primitives only for exact evidenced values.
- [ ] Add semantic/component roles only when reusable intent is justified.
- [ ] For truly one-off fixed Welcome geometry, consume the governed primitive directly.
- [ ] Remove `WelcomeLayoutTokens` final dependency.
- [ ] Remove `WelcomeTypographyTokens` final dependency.
- [ ] Remove `WelcomeColorTokens` final dependency.
- [ ] Remove `WelcomeMotionTokens` final dependency.
- [ ] Remove `WelcomeBackdropTokens` final dependency for fixed visual contracts.
- [ ] Do not introduce `WelcomeTokens`, `WelcomeVisualTokens`, or another feature token bag.
- [ ] Preserve current Welcome legal/footer decisions.
- [ ] Run focused Welcome tests and static literal audit.
- [ ] Compare representative states/viewports before and after where practical.
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
12. Unblock Slice C

## Exit Criteria

- no Welcome-owned design-token catalog remains;
- Welcome consumes governed core design-system contracts;
- no visible UI change occurred without separate approval;
- tests/analyze/required CI pass.
