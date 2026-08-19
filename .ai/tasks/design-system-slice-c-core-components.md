# Design System Slice C — Core Components

**Status:** Validated  
**Parent task:** `.ai/tasks/design-system-token-consolidation.md`  
**Related issue:** #6  
**Working PR:** #22  
**Working branch:** `codex/design-system-token-consolidation`

## Outcome

Reusable core components and their token contracts have been audited so component APIs express reusable intent without becoming screen-, feature-, or workflow-specific numeric/style bags.

This slice preserved the existing UI. No visual redesign was approved or performed.

## Mandatory Visual Freeze

```text
pixels before == pixels after
```

No visible component or screen appearance changed intentionally. Existing geometry, color, typography, state layers, motion and interaction visuals were preserved exactly while ownership moved to governed core contracts.

## Preconditions

- [x] Slice A runtime/source boundary validated by Flutter CI #624.
- [x] Slice B is `Validated`; final Welcome deletion head passed Flutter CI #646.
- [x] Theme usage/maintenance contract exists at `apps/core/lib/src/theme/README.md`.

## Scope

Reusable core UI and shell contracts including buttons, cards, inputs, avatars, sheets, navigation, headers/layout helpers, pickers and shared dialogs.

The separate reusable-field architecture tracked by Issue #24 was not implemented here. Existing input components were only ownership/canonical-name cleaned without feature-screen migration or API redesign.

## Final Ownership Rule

```text
Reusable component with proven stable contract → component tokens when useful
Reusable semantic role                        → foundation/semantic/typography/effects
One-off component/product-flow composition    → governed core primitive/role directly
Screen/feature/workflow-specific token bag    → forbidden
```

A class is not retained merely because it already exists under `tokens/components/`.

## Component-Token Admission Gate

A file under `tokens/components/` is valid only when all of the following hold:

1. The owning UI is a genuinely reusable core component, not a single product screen/workflow disguised as one.
2. The token class adds a stable reusable component contract beyond simply hiding primitive calls.
3. Reuse is evidenced by multiple contexts/consumers or a clearly generic API with independent use cases.
4. The name describes reusable component capability, not a feature/screen/workflow.
5. Physical values alias governed lower-level owners; the class is not a second physical registry.
6. If these checks fail, no token file is created. The composition consumes `TioSize`, `TioSpacing`, `TioRadius`, `TioStroke`, typography registries and runtime semantic roles directly.

Examples:

```text
TioButtonTokens             ✅ reusable component contract
TioInputTokens              ✅ reusable input-family contract
TioOtpDialogTokens          ✅ reusable email/phone/reset verification dialog
WelcomeTokens               ❌ feature-specific
ProfileTokens               ❌ feature-specific
DeleteAccountDialogTokens   ❌ single destructive product workflow
```

## Token-Contract Audit

Original Slice C inventory contained 14 component-token classes:

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

Final exported component contracts are:

```text
TioAvatarActionSheetTokens
TioAvatarTokens
TioButtonTokens
TioCardTokens
TioInputTokens
TioLegalTokens
TioMeasurementPickerTokens
TioNavigationTokens
TioOtpDialogTokens
TioRemoveImageSheetTokens
TioSheetTokens
TioWheelPickerTokens
```

### Removed/reclassified contracts

- [x] `TioMeasurementPreferenceTokens` removed as a one-value proxy; the preferences editor uses canonical typography/spacing directly.
- [x] Mixed `TioDialogTokens` facade removed after consumer/test migration and zero-reference verification.
- [x] Temporary `TioDeleteAccountDialogTokens` direction rejected and removed. Delete Account is a product workflow and now consumes governed core values directly.
- [x] `TioDobPickerTokens` removed as an unnecessary mixed proxy. Shared drum-wheel visuals remain in `TioWheelPickerTokens`; DOB-only sheet values use governed primitives directly.

### Retained-contract evidence

- `TioInputTokens` governs the reusable generic/mobile/username input family.
- `TioMeasurementPickerTokens` is shared by Height and Weight reusable pickers.
- `TioWheelPickerTokens` owns the shared drum-wheel visual contract used by reusable DOB/onboarding picker composition.
- `TioOtpDialogTokens` remains because the generic OTP dialog supports independent email, phone and reset-code verification use cases.
- `TioLegalTokens` supports the reusable legal disclaimer used across feature contexts.
- Avatar action/remove-image contracts back reusable shared sheets used from multiple profile/settings/avatar contexts.
- Button/Card/Avatar/Navigation/Sheet contracts represent stable generic reusable components.

## Important Classification Decisions

- `TioElevation.none = 0.0` is the canonical repeated zero-elevation effect role.
- Avatar `0.28 / 0.5 / 0.36` values are component-specific shape/icon/text ratios, not global geometry primitives.
- DOB wheel `perspective = 0.004` and `diameterRatio = 1.3` remain private rendering factors, not global tokens.
- Username `400ms` debounce is behavior timing, not visual motion.
- Delete Account five-second hold is product/interaction behavior, not visual motion.
- Height/weight conversion constants (`2.54`, `2.20462`) and validation ranges are domain behavior, not design tokens.
- Rare framework-transparent values remain implementation behavior where documented.

## Implemented Batches and Validation Evidence

- [x] C2.1 — introduced evidence-based `TioElevation.none`; Flutter CI #655 passed.
- [x] C2.2 — removed `TioMeasurementPreferenceTokens` proxy and migrated editor ownership.
- [x] Delete Account correction — removed `TioDeleteAccountDialogTokens` and mixed `TioDialogTokens`; Flutter CI #689 passed.
- [x] DOB correction — removed `TioDobPickerTokens`, retained shared wheel contract and local rendering factors; Flutter CI #697 passed.
- [x] C3.1 — `TioSocialButton` raw `8/20` geometry migrated to `TioSpacing.sm` / `TioSize.dp20` without creating a SocialButton token class; Flutter CI #698 passed.
- [x] C3.2 — `TioInput`, `TioMobileNumberField`, `TioUsernameInputField` canonicalized for typography/spacing/radius ownership; Flutter CI #701 passed.
- [x] C3.3 — Height/Weight picker legacy aliases and raw font weights canonicalized; formulas/ranges untouched; Flutter CI #703 passed.
- [x] C3.4 — OTP, Legal, Avatar Action and Remove Image reusable consumers canonicalized; Flutter CI #707 passed.
- [x] C3.5 — Shell top bar and ScreenHeader legacy aliases canonicalized; zero-reference deprecated avatar-frame sheet stub deleted.
- [x] C4 final source boundary `35adb47de9ddfc4d1fa2e9ddce4bb9526fa9fd2a` passed Flutter CI #710: Flutter analyze, Dart analyze, Flutter tests and Dart tests all succeeded.

## Final Static Audit

- [x] Current component barrel exports only the 12 retained reusable contracts listed above.
- [x] `TioDialogTokens`, `TioDeleteAccountDialogTokens`, `TioDobPickerTokens`, and `TioMeasurementPreferenceTokens` are absent from final component-token architecture.
- [x] Retained component contracts alias governed lower-level physical owners.
- [x] Edited reusable consumers no longer use the legacy spacing/radius names touched by this slice.
- [x] Edited reusable typography resolves through governed typography roles.
- [x] No product-flow token class was introduced as a replacement for removed bags.
- [x] Existing focused component widget tests were retained as behavior regression coverage.

## Delete Account Module Boundary

Delete Account is still physically implemented under core UI today, but its product-specific nature is explicitly recognized as a module-ownership smell. Slice C removed the invalid design-token justification without mixing a larger feature-module relocation into this visual-ownership migration. A future module move must preserve behavior and be scoped independently.

## Exit Criteria

- [x] Every retained component-token class passes the admission gate.
- [x] No token class is retained solely for one product screen/workflow.
- [x] No retained component token class independently redefines governed fixed physical values.
- [x] No screen/feature/workflow-specific token bag is hidden under core components.
- [x] `TioDeleteAccountDialogTokens` and deprecated mixed `TioDialogTokens` are absent.
- [x] Component-specific program ratios/factors are not misclassified as global design tokens.
- [x] No unapproved visible UI change occurred.
- [x] Focused tests, analyze and required CI passed.

## Handoff

Slice C is `Validated`. Slice D — Auth + Account Setup may now begin under the same mandatory visual freeze and component-token admission rules.
