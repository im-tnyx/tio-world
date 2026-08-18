# Design System Slice B — Welcome Cleanup

**Status:** In progress  
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

- [x] Slice A runtime/source boundary is validated by Flutter CI #624 (Flutter/Dart analyze + Flutter/Dart tests passed).
- [x] Canonical primitive/core ownership is stable for feature migration.
- [x] Color audit rules are available from `.ai/tasks/design-system-hardcoded-color-audit.md`.
- [x] Canonical usage/maintenance guide exists at `apps/core/lib/src/theme/README.md`.

## Scope

- `apps/features/welcome/**`
- focused shared/core contracts only when an evidenced missing reusable role is discovered
- focused core contract tests for any newly evidenced primitives
- Welcome-focused static/audit validation

## Hard Boundaries

- no Auth behavior changes;
- no onboarding flow changes;
- no legal placement restoration/movement;
- no feature-owned replacement token file;
- no screen redesign.

## Verified Inventory / Classification

Current `welcome_visual_tokens.dart` owns five transitional feature catalogs:

```text
WelcomeLayoutTokens
WelcomeMotionTokens
WelcomeTypographyTokens
WelcomeColorTokens
WelcomeBackdropTokens
```

Initial ownership map:

- exact geometry values already governed by `TioSize`/`TioSpacing` are consumed directly;
- missing exact geometry `60dp` requires evidenced `TioSize.dp60`;
- exact normalized opacity contracts require `TioOpacity.opacity0/18/94/100` where currently missing;
- exact `0xB3FFFFFF` requires byte-exact alpha ownership (`TioAlpha.alpha179`) plus a governed palette color;
- Welcome typography adds evidenced physical sizes `9.5`, `10.5`, `42` and line height `1.10`; these belong in typography physical registries, not a Welcome typography bag;
- existing `Roboto` hero family remains `TioFontFamily.roboto` to preserve current rendering; it does not become a selectable Settings font option merely because Welcome uses it;
- timeline/coverage/layout factors such as `0.40`, `0.50`, `0.82`, gradient stops, and flex values are composition/program values, not geometry/opacity primitives; keep them private to the owning widget/screen rather than promoting fake global tokens;
- no `Welcome*Tokens` replacement bag will be introduced.

## Checklist

- [x] Inventory every value in `welcome_visual_tokens.dart`.
- [x] Classify each as geometry, color, typography, motion/effect, reusable component role, fixed factor/ratio, or genuine runtime/program value.
- [x] Reuse existing governed core ownership first.
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
- [ ] Run focused core tests for new primitives and Welcome static literal/zero-reference audit.
- [ ] Compare representative states/viewports before and after where practical.
- [ ] Run analyze and required CI.

## Planned Bounded Execution

### B1 — Missing governed physical values

Add only the exact missing physical values proven by the current Welcome UI and lock them with existing core contract tests. Update `apps/core/lib/src/theme/README.md` in the same change when the public token contract changes.

### B2 — Welcome consumer migration

Migrate `WelcomeScreen`, `WelcomeFeatureTile`, `WelcomeTopBar`, and `WelcomeBackdrop` to core governed values. Preserve private composition ratios/stops locally. No visual normalization.

### B3 — Delete transitional catalog

Verify zero legitimate references to the five `Welcome*Tokens` classes, delete `welcome_visual_tokens.dart` and its imports, run static audit/analyze/required CI, and record evidence.

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
