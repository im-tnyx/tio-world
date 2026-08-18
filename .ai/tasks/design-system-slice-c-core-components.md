# Design System Slice C — Core Components

**Status:** In progress  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Audit reusable core components and their token contracts so component APIs express reusable intent without becoming screen-specific numeric/style bags.

## Mandatory Visual Freeze

No visible component or screen appearance may change without separate explicit owner/design approval. Existing geometry, color, typography, state layers, motion and interaction visuals must remain pixel-preserving by default.

## Preconditions

- [x] Slice A runtime/source boundary validated by Flutter CI #624 after A9/A10 implementation.
- [x] Slice B is `Validated`; final Welcome deletion head passed Flutter CI #646.
- [x] Theme usage/maintenance contract is documented in `apps/core/lib/src/theme/README.md`.

## Scope

Reusable core UI and shell contracts including buttons, cards, inputs, avatars, sheets, navigation, headers/layout helpers, pickers and other shared components.

The separate reusable-field architecture tracked by Issue #24 is **not** implemented here. Slice C may clean current input component ownership without redesigning variants or migrating feature screens.

## Ownership Rule

```text
Reusable component → component tokens
Reusable semantic role → foundation/semantic/typography/effects
One-off component composition → governed core primitive/role directly
Screen-specific core token bag → forbidden
```

A class must not be retained merely because it already exists under `tokens/components/`.

## Initial Token-Contract Inventory

All 14 current `tokens/components/` classes were read and classified before Slice C mutations:

```text
TioAvatarActionSheetTokens
TioAvatarTokens
TioButtonTokens
TioCardTokens
TioDialogTokens
TioDobPickerTokens
TioInputTokens
TioLegalTokens
TioMeasurementPickerTokens
TioMeasurementPreferenceTokens
TioNavigationTokens
TioRemoveImageSheetTokens
TioSheetTokens
TioWheelPickerTokens
```

### Initial classification

Strong reusable-contract evidence currently exists for:

- Avatar and Avatar action sheet;
- Button;
- Card;
- DOB/wheel/measurement pickers;
- Input plus specialized username/mobile contracts;
- Legal disclaimer;
- Navigation;
- Remove-image sheet and generic sheet.

Two contracts require focused reclassification:

1. `TioDialogTokens` is an oversized mixed bag containing two independently implemented reusable components: OTP verification and Delete Account overlay. The final contract should not keep unrelated `otp*` and `delete*` families in one generic token class merely for historical convenience.
2. `TioMeasurementPreferenceTokens` contains only one `sectionLabelFontSize` alias. Audit whether this one-value proxy expresses meaningful reusable intent; otherwise consume governed typography directly and delete the proxy after zero-reference validation.

### Remaining physical/effect evidence

- `TioCardTokens.materialThemeElevation = 0.0` and `TioNavigationTokens.elevation = 0.0` independently own the same fixed elevation value. This is repeated cross-component evidence for evaluating a generic effects owner such as `TioElevation.none`; do not add it until consumer audit confirms the role.
- Avatar ratios `0.28 / 0.5 / 0.36` are component-specific shape/icon/text factors and remain Avatar-owned unless broader reuse is proven.
- DOB picker `perspective = 0.004` and `diameterRatio = 1.3` are component-specific rendering factors and remain local to that reusable picker contract.
- Direct palette aliases such as navigation accent and delete-dialog destructive colors are permitted only as semantic component roles over governed physical palette ownership.

## Initial Component-Implementation Findings

The token audit is not sufficient by itself; reusable component source must also be audited.

Confirmed examples:

- `TioSocialButton` correctly composes `TioButton` but still recreates fixed `8` gap and `20` icon geometry in each provider branch. Final cleanup should consume `TioSpacing.sm` / `TioSize.dp20` directly rather than create `TioSocialButtonTokens`.
- `TioMeasurementUnitPreferencesEditor` still uses legacy spacing aliases and raw `FontWeight.w700`, and its only dedicated token is the one-value `TioMeasurementPreferenceTokens` proxy.
- `TioDeleteAccountOverlay` still contains component interaction constants such as the five-second hold contract plus legacy spacing aliases; duration/behavior values must be classified before any ownership change.
- Existing widget tests already cover delete-account, OTP, DOB, height, weight, generic input, mobile number, and username components, giving Slice C a regression harness without inventing a new test framework.

## Checklist

- [x] Inventory all 14 current reusable component token classes.
- [x] Classify obvious justified contracts, mixed bags, one-value proxies, shared raw effects, and component-specific ratios/factors.
- [ ] Audit every reusable component implementation and its current token/primitive dependencies.
- [ ] Confirm each retained component token class represents actual reusable component intent.
- [ ] Reclassify `TioDialogTokens` without changing OTP/Delete Account rendering.
- [ ] Resolve `TioMeasurementPreferenceTokens` one-value proxy after consumer audit.
- [ ] Resolve repeated fixed elevation ownership only if the component consumer audit confirms the shared effect role.
- [ ] Remove raw fixed visual values from reusable component implementations when governed owners already exist.
- [ ] Migrate edited core consumers away from legacy spacing/radius compatibility aliases.
- [ ] Ensure colors resolve through governed semantic/domain/component roles.
- [ ] Ensure typography resolves through governed typography roles.
- [ ] Ensure geometry/strokes/opacities/durations/factors resolve through canonical ownership without inventing fake global factors.
- [ ] Preserve intentional pixel differences such as distinct Material-vs-custom component contracts until separately approved.
- [ ] Update component/contract tests to lock alias ownership and current rendering.
- [ ] Run focused core UI tests, static audit, analyze and required CI.

## Planned Bounded Execution

### C1 — Complete component source inventory

Audit every exported reusable core component and shell helper for raw fixed values, legacy compatibility aliases, direct physical palette usage, raw typography weights/sizes, durations, and token dependencies. Record findings before mutation.

### C2 — Contract reclassification

Resolve oversized/misleading component token classes (`TioDialogTokens`, one-value proxies) and any shared effect ownership proven by C1. Preserve public component behavior and rendered pixels.

### C3 — Component implementation cleanup

Migrate reusable component implementations to the validated contracts and canonical token names. Do not implement Issue #24 feature-screen field adoption in this slice.

### C4 — Validation

Run existing focused component widget tests, ownership contract tests, static literal/compatibility audit, analyze and required CI; then mark Slice C `Validated` and unblock Slice D.

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
- no component class independently owns governed fixed visual values;
- no screen-specific token bag is hidden under core components;
- component-specific program ratios/factors are not misclassified as global design tokens;
- no unapproved visible UI change occurred;
- tests/analyze/required CI pass.
