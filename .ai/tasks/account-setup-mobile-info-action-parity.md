# Account Setup Mobile Info Action Parity

**Status:** In progress
**Primary owner:** `apps/core` + `apps/features/account_setup` + `apps/features/onboarding`
**Affected platforms:** Flutter phone UI
**Tracking:** GitHub issue #115
**Working branch:** `agent/mobile-info-parity-115`

## 1. Discovery

### User Outcome

The Account Setup Mobile contextual info action must look and behave exactly like the existing Product Onboarding contextual info action instead of inheriting the larger global `TextButton` treatment.

### Success Criteria

- one reusable core contextual info-action implementation is used by both consumers;
- rendered contract is `12px`, `w500`, `16px` icon with the existing compact spacing;
- Account Setup no longer inherits the global `TextButton` minimum height for this action;
- existing information sheets still open correctly.
- Mobile information sheet includes the same explicit `Understood` dismissal
  action used by Product Onboarding information sheets.

### Scope

- add one reusable core contextual info-action widget;
- migrate Product Onboarding bottom info action to it;
- migrate Account Setup Mobile info action to it;
- align the Account Setup Mobile sheet's action affordance with Product
  Onboarding;
- add focused widget/regression coverage;
- document the reusable component contract in the core theme README.

### Non-Goals

- no Mobile copy/data-policy changes;
- no footer or Continue-button redesign;
- no unrelated Product Onboarding visual changes;
- no feature-local token catalog.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `AGENTS.md`, `apps/features/AGENTS.md`, `.ai/workflow.md`, `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, `apps/features/account_setup/lib/src/presentation/account_setup_flow_page.dart`, `apps/features/onboarding/lib/src/presentation/widgets/onboarding_bottom_bar.dart`, `apps/core/lib/src/theme/tio_theme.dart`, `apps/core/lib/src/theme/tokens/components/tio_button_tokens.dart`.
- Existing pattern to follow: Product Onboarding currently renders the approved compact `Icon + Text` treatment using governed core values.
- Reuse evidence: Account Setup Mobile and Product Onboarding are independent feature consumers of the same contextual info-action behavior.
- Tests or validation already present: Account Setup tests cover visibility and sheet opening; core has focused reusable-component widget tests.
- Account Setup Mobile already uses `TioSheet`, but its informational content
  has no explicit dismissal action, unlike Product Onboarding information
  sheets.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Canonical visual is the current Product Onboarding treatment | Approved | Explicit owner instruction from issue #115 | Product |
| Promote shared behavior to `apps/core` | Approved | Cross-feature reuse is already evidenced | Engineering |
| Do not use global `TextButton` geometry | Approved | It causes the device-visible mismatch | Product/Engineering |
| Add an explicit Mobile-sheet dismissal action | Approved | The owner identified the missing button as the remaining visible difference | Product |

## 4. Architecture Design

### Chosen Approach

Add a small public `TioInlineInfoAction` reusable component under core buttons. It directly consumes existing governed primitives/semantic colors and does not introduce a new token class.

For the Mobile explanation, retain the reusable `TioSheet` surface and compose
the existing reusable `TioButton.primary` beneath the product-owned body copy.

### Ownership and Data Flow

```text
Feature footer/bottom bar
  -> TioInlineInfoAction
     -> icon + label + callback
```

### Alternative Rejected

Keeping two feature-local implementations was rejected because it preserves the source of drift. Creating a new component token bag was rejected because the visual contract is simple and existing primitives already own all physical values.

### Failure and Accessibility States

The widget remains a semantic button with an opaque tap target around its compact padded content. Existing callbacks and sheet failure behavior remain owned by each feature.

The explanatory sheet also has an explicit primary dismissal action, while
modal outside/back dismissal continues to work.

## 5. Implementation Plan

- [ ] add/export `TioInlineInfoAction` in core;
- [ ] document it in the core theme README;
- [ ] migrate Product Onboarding consumer;
- [ ] migrate Account Setup Mobile consumer;
- [x] add the Account Setup Mobile sheet dismissal action;
- [ ] add focused reusable-component and feature regression tests;
- [ ] run applicable validation and record exact results.

## 6. Quality Review

### Validation Run

- `git diff --check` passed.
- Dart formatting parsed and formatted the changed source/test files, but its
  telemetry session timestamp could not be written outside the repository.
- `flutter test test/presentation/account_setup_flow_page_test.dart` produced
  no test result after 60 seconds in this environment and was stopped; it is
  not counted as passing validation.

### Review Findings and Resolution

Pending implementation.

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

None identified yet.

### Final Status

`REVIEW`
