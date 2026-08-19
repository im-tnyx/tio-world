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
- [x] Latest pre-correction Slice C boundary `8bc03bf...` passed Flutter CI #674.

## Scope

Reusable core UI and shell contracts including buttons, cards, inputs, avatars, sheets, navigation, headers/layout helpers, pickers and other shared components.

The separate reusable-field architecture tracked by Issue #24 is **not** implemented here. Slice C may clean current input component ownership without redesigning variants or migrating feature screens.

## Ownership Rule

```text
Reusable component with proven component-level contract → component tokens when useful
Reusable semantic role → foundation/semantic/typography/effects
One-off component or product-flow composition → governed core primitive/role directly
Screen/feature/workflow-specific core token bag → forbidden
```

A class must not be retained merely because it already exists under `tokens/components/`.

## Component-Token Admission Gate

A new or retained file under `tokens/components/` must pass all of these checks:

1. The owning UI is a genuinely reusable core component, not a single product screen/workflow/action disguised as a component.
2. The token class expresses a stable reusable component contract that adds value beyond directly consuming existing core primitives/semantic roles.
3. Reuse evidence is recorded in the task: multiple feature contexts/consumers, or a clearly generic reusable API with independent use cases.
4. The class name describes a generic reusable component capability, not a feature, screen, workflow, or product action.
5. Physical values alias governed lower-level owners; the class does not become a second physical registry.
6. If these checks fail, do **not** create a token file. Keep the composition with its owner and consume `TioSize`, `TioSpacing`, `TioRadius`, `TioStroke`, typography registries, runtime semantic colors/effects, and other governed roles directly.

Examples:

```text
TioButtonTokens             ✅ reusable component contract
TioInputTokens              ✅ reusable component contract
TioOtpDialogTokens          ✅ only while the OTP dialog remains genuinely reusable across email/phone/reset flows
WelcomeTokens               ❌ feature-specific token bag
ProfileTokens               ❌ feature-specific token bag
DeleteAccountDialogTokens   ❌ single destructive product workflow; do not retain as a core design-system token class
```

A product-specific workflow living under `apps/core` is itself an ownership smell and must be evaluated separately; a token class must not be used to legitimize the wrong module boundary.

## Initial Token-Contract Inventory

All original 14 `tokens/components/` classes were read and classified before Slice C mutations:

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

### Current classification

Reusable-contract evidence exists for the generic/shared component families currently used across app contexts, including Button, Card, Input, Avatar, navigation, picker/sheet infrastructure, and OTP verification where multiple verification flows consume the same reusable dialog.

Contracts are not accepted solely because they match an existing core widget name. Each retained class must pass the admission gate above during final C4 audit.

Rejected/reclassified cases:

1. `TioMeasurementPreferenceTokens` was a one-value proxy and has been removed; the editor consumes canonical typography/spacing directly.
2. `TioDialogTokens` was an oversized mixed compatibility bag and is being retired.
3. Creating `TioDeleteAccountDialogTokens` as the replacement for the `delete*` half of `TioDialogTokens` was the wrong final direction: Delete Account is a specific destructive product workflow, so the dedicated core token class must be removed and the composition must consume governed core values directly.
4. `TioOtpDialogTokens` may remain only because the reusable OTP dialog serves independent email/phone/reset verification contexts; final C4 audit must confirm this evidence still holds.

### Remaining physical/effect evidence

- Repeated zero Material elevation is now owned by `TioElevation.none`; the implementation remains exact `0.0`.
- Avatar ratios `0.28 / 0.5 / 0.36` are component-specific shape/icon/text factors and remain Avatar-owned unless broader reuse is proven.
- DOB picker `perspective = 0.004` and `diameterRatio = 1.3` are component-specific rendering factors and remain local to that reusable picker contract.
- A rare exact one-off physical color may consume its governed palette owner directly when no honest reusable semantic role exists; do not create a product-flow color/token class merely to hide the palette access.

## Initial Component-Implementation Findings

The token audit is not sufficient by itself; reusable component source must also be audited.

Confirmed examples:

- `TioSocialButton` correctly composes `TioButton` but recreates fixed `8` gap and `20` icon geometry. Final cleanup should consume `TioSpacing.sm` / `TioSize.dp20` directly rather than create `TioSocialButtonTokens`.
- `TioMeasurementUnitPreferencesEditor` one-value proxy was unnecessary; direct canonical typography/spacing is the correct ownership.
- `TioDeleteAccountOverlay` owns a five-second destructive hold contract. That timing is product/interaction behavior, not a theme-motion token.
- Delete Account is currently consumed from Account Settings, which reinforces that its dedicated core token class is not reusable design-system ownership.
- Existing widget tests cover delete-account, OTP, DOB, height, weight, generic input, mobile number, and username components, giving Slice C a regression harness without inventing a new test framework.

## Checklist

- [x] Inventory original reusable component token classes.
- [x] Classify obvious justified contracts, mixed bags, one-value proxies, shared raw effects, and component-specific ratios/factors.
- [x] Resolve repeated zero-elevation ownership as `TioElevation.none` with exact-value tests; Flutter CI #655 passed that bounded batch.
- [x] Remove the one-value `TioMeasurementPreferenceTokens` proxy and migrate its editor to canonical typography/spacing.
- [ ] Complete every reusable component implementation audit and record actual reuse evidence for each retained component-token class.
- [ ] Remove `TioDeleteAccountDialogTokens`; migrate Delete Account visuals directly to governed core primitives/semantic roles without changing rendering.
- [ ] Retire the temporary `TioDialogTokens` facade after repository-wide zero-reference verification.
- [ ] Re-evaluate whether the Delete Account product workflow itself belongs in `apps/core`; do not mix a larger feature-module move into the token correction unless the bounded migration is proven safe.
- [ ] Remove raw fixed visual values from reusable component implementations when governed owners already exist.
- [ ] Migrate edited core consumers away from legacy spacing/radius compatibility aliases.
- [ ] Ensure colors resolve through governed semantic/domain roles or rare audited direct physical owners where no honest reusable semantic role exists.
- [ ] Ensure typography resolves through governed typography roles.
- [ ] Ensure geometry/strokes/opacities/durations/factors resolve through canonical ownership without inventing fake global factors.
- [ ] Preserve intentional pixel differences such as distinct Material-vs-custom component contracts until separately approved.
- [ ] Update component/contract tests to lock canonical ownership and current rendering.
- [ ] Run focused core UI tests, static token-admission/compatibility audit, analyze and required CI.

## Planned Bounded Execution

### C1 — Complete component source inventory

Audit every exported reusable core component and shell helper for raw fixed values, legacy compatibility aliases, direct physical palette usage, raw typography weights/sizes, durations, token dependencies, and actual reuse evidence.

### C2 — Contract reclassification

Resolve oversized/misleading component token classes, one-value proxies, invalid product-flow token classes, and shared effect ownership proven by C1. Preserve public behavior and rendered pixels.

### C3 — Component implementation cleanup

Migrate reusable component implementations to validated contracts/canonical token names. Product-specific compositions consume governed core roles directly rather than receiving their own token class. Do not implement Issue #24 feature-screen field adoption in this slice.

### C4 — Validation

Run existing focused component widget tests, ownership contract tests, repository/static token-admission audit, analyze and required CI; then mark Slice C `Validated` and unblock Slice D.

## Completion Lifecycle

1. Inventory
2. Reuse evidence
3. Classification
4. Planned ownership
5. Implementation
6. Focused tests
7. Static audit
8. Pixel/UI regression check
9. Analyze
10. Required CI
11. Update evidence
12. Mark `Validated`
13. Unblock Slice D

## Exit Criteria

- every retained component-token class passes the component-token admission gate;
- no token class is retained solely for one screen, dialog flow, sheet action, or product workflow;
- no component class independently owns governed fixed physical values;
- no screen/feature/workflow-specific token bag is hidden under core components;
- `TioDeleteAccountDialogTokens` and the deprecated mixed `TioDialogTokens` facade are absent from final architecture;
- component-specific program ratios/factors are not misclassified as global design tokens;
- no unapproved visible UI change occurred;
- focused tests/analyze/required CI pass.
