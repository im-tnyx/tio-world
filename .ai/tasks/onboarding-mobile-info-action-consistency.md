# Onboarding Mobile Info Action Consistency

**Status:** In progress  
**Primary owner:** Flutter mobile / Product Onboarding  
**Affected platforms:** Flutter Android and iOS

## Global UI / Design-System Guardrail

The core theme guidance, design-system consolidation task, feature-package
rules, and existing reusable onboarding bottom-bar surface were inspected. This
slice changes only approved user-facing copy on an existing action; it does not
change component geometry, colors, typography, spacing, or interaction logic.

## 1. Discovery

### User Outcome

The Mobile screen's bottom data-information action should match the Goal
screen, without the longer label creating a different action-bar height.

### Success Criteria

- Mobile and Goal use the same `Why we collect this data` label.
- The existing Mobile data-collection sheet remains reachable and unchanged.
- No layout values or visual tokens change.

### Scope

- Mobile `OnboardingBottomInfoAction` label in the flow-page composition.

### Non-Goals

- Do not change Mobile header copy, field height, verification behavior,
  persistence, or the contents of either information sheet.

## 2. Codebase Exploration

### Verified Evidence

- `OnboardingFlowPage` supplies `Why we collect this data` for Goal and a
  longer mobile-specific label for Mobile.
- Both actions render through the same `OnboardingBottomBar` with the same
  `12sp`, `w500`, `textSecondary` style.
- The long Mobile label is the only action-content difference and can wrap at
  compact widths, increasing the bottom bar height.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Reuse the Goal information-action label for Mobile | Approved | Exact copy equality preserves the shared action height and visual rhythm | Product owner |

## 4. Architecture Design

### Chosen Approach

Replace only the Mobile action label in the composition root. It retains the
mobile-specific callback and data sheet.

### Ownership and Data Flow

```text
Mobile onboarding state -> OnboardingBottomInfoAction label -> OnboardingBottomBar
```

### Alternative Rejected

Changing bottom-bar padding or text style was rejected because both screens
already consume the same reusable visual contract.

### Failure and Accessibility States

The action remains tappable and continues to expose the existing Mobile
information sheet.

## 5. Implementation Plan

- [ ] Align the Mobile label with Goal.
- [ ] Add or update a focused flow-page regression.
- [ ] Run formatting and the focused test.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

Pending implementation.

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending validation.

### Known Limitations

The longer Mobile header subtitle is intentionally out of scope for this
bottom-action-height alignment slice.

### Final Status

`PARTIAL`
