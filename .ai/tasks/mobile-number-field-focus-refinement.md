# Mobile Number Field Focus Refinement

**Status:** In progress
**Primary owner:** Codex
**Affected platforms:** Flutter Android + iOS

## Owner Approval and Scope Boundary

**Trigger:** Product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** Owner requested mobile text field refinement and selected `TioMobileNumberField` on 2026-11-15.
**Approved product/UI/data-shape boundaries:** Refine the existing shared `TioMobileNumberField` using the supplied phone-field reference: place the country flag/code and number inside one outlined field, with a clear focus outline. Keep the existing 56dp height, 16dp radius, and all number/verification behavior.
**Explicit non-changes:** No `TioInput` or other input changes; no call-site migration; caller-owned labels/helper copy stay where they are; no validation, formatting, focus dismissal, keyboard, verification, persistence, or Supabase changes.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Previous agent:** Not applicable
**Last commit agent:** Codex
**Last commit SHA:** `f258e2e59c81679c7f6e3d0be66ee7c13a6ab66d`
**Review owner:** Not available
**Implementation ownership state:** Handoff pending
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-11-15; clean before task file creation
**Branch:** `tnyx/mobile-number-field-focus-refinement`
**HEAD SHA:** `e8e5bf7f5e251f65cd6c22c6e12d9240efa9964a`
**Observed working-tree state:** Two scoped commits pushed; GitHub PR #761 is open and non-draft.
**Observed uncommitted/dirty files:** `.ai/tasks/mobile-number-field-focus-refinement.md`, `.ai/tasks/README.md` (PR handoff update)
**PR / tracker:** [GitHub PR #761](https://github.com/im-tnyx/tio-world/pull/761) is open and ready for review. Reconciled Linear `TNYX-152` / GitHub #208 and existing field ownership in GitHub #24; this is a separately authorized visual refinement, not a migration.
**Current implementation state:** Shared Core field uses one outlined surface for the flag, country code and number, with focus styling; PR #761 is awaiting review and device visual acceptance.
**Relevant execution surface:** `apps/core` shared input component
**Validation completed at SHA:** Source commit `f258e2e59c81679c7f6e3d0be66ee7c13a6ab66d` — Flutter analyzer found no issues in the component and focused test; focused widget tests passed 2/2. `git diff --check` will be rerun after this handoff metadata update. Dart formatter reported `0 changed`.
**Validation remaining:** Device visual validation against the supplied reference. The formatter reported no changes but its restricted-shell attempt exited non-zero during telemetry metadata update.
**Current blocker:** None for source/widget validation; device visual acceptance remains unverified.
**Open review finding IDs:** None
**Next exact action:** Address PR review feedback and record device visual acceptance against the supplied reference.

## Global UI / Design-System Guardrail

Read `.ai/tasks/design-system-token-consolidation.md` and `apps/core/lib/src/theme/README.md`. The component and focused tests were inspected. Use the existing governed `TioInputTokens.focusedOutlineWidth`; do not add raw fixed visual values or change the field height/radius.

## 1. Discovery

### User Outcome

The mobile-number field follows the supplied reference's unified flag/country-code/number surface and gives a clear visual indication while focused.

### Success Criteria

- Country flag, country code and number sit within one full-width outlined surface.
- Focused, unverified field uses the existing primary color and focused outline width.
- Unfocused and verified appearances remain unchanged.
- Existing field height and radius remain unchanged; caller-owned labels and helper text do not move.
- Phone formatting, callbacks, verify affordance, keys, and accessibility labels remain unchanged.

### Scope

- `apps/core/lib/src/ui/components/inputs/tio_mobile_number_field.dart`
- `apps/core/lib/src/theme/README.md` to document the focused-state contract

### Non-Goals

- Any other input component or consumer migration.
- Error state/API, content copy, field height/radius, or visual redesign beyond the supplied unified-field reference.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: shared `TioMobileNumberField`, `TioInputTokens`, focused mobile-field widget tests, core theme README, and relevant callers.
- Existing pattern to follow: `TioInput` switches its focused outline to `context.tioColors.primary` and uses `TioInputTokens.focusedOutlineWidth`.
- Existing tests inspected: `apps/core/test/ui/components/tio_mobile_number_field_test.dart`.
- Ownership: GitHub #24 owns the reusable mobile-number input contract; GitHub #208 requires explicit authorization for future text-field slices. This request authorizes only the focus appearance refinement.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Target | Approved | Owner selected `TioMobileNumberField`. | Owner |
| Visual scope | Approved | Reference image #2 guides the unified phone field; retain current height/radius and caller-owned labels/helpers. | Owner |

## 4. Architecture Design

### Chosen Approach

Move the country prefix inside the existing 56dp outlined field. Track text-input focus and apply the existing primary outline and focused width. Preserve the current verified outline priority and use existing spacing/radius contracts.

### Ownership and Data Flow

```text
TextField focus → TioMobileNumberField presentation state → existing Core outline tokens/colors
```

### Alternative Rejected

No feature-local styling or new token/API: all consumers share this Core-owned contract.

### Failure and Accessibility States

No change to input, verification, or accessibility states. Focus feedback remains visual and does not replace text labels or verification semantics.

## 5. Implementation Plan

- [x] Place country flag/code and number inside one outlined field.
- [x] Add focus tracking and focused outline styling.
- [x] Document the component visual contract.
- [x] Review the diff and report validation limits.

## 6. Quality Review

### Validation Run

```text
`git -c core.fsmonitor=false diff --check` — passed. `flutter analyze lib/src/ui/components/inputs/tio_mobile_number_field.dart test/ui/components/tio_mobile_number_field_test.dart` — no issues found. `flutter test test/ui/components/tio_mobile_number_field_test.dart` — passed 2/2 using the Flutter SDK's `flutter_tools.snapshot` test command. `dart format lib/src/ui/components/inputs/tio_mobile_number_field.dart` reported `0 changed`; its restricted-shell attempt exited non-zero on a denied telemetry metadata update.
```

### Acceptance Evidence

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Prefix and number share one outlined surface | `tio_mobile_number_field.dart` | Source diff review; runtime not checked | Working tree based on HEAD `3de52946` / local | Device layout and visual acceptance remain unverified. |
| Focus outline appears on focus | `tio_mobile_number_field.dart` | Source diff review; no assertion in current focused test | Working tree based on HEAD `3de52946` / local | Device visual validation pending. |
| Existing verify/verified behavior preserved | `tio_mobile_number_field.dart` | Focused widget test passed 2/2 | Working tree based on HEAD `3de52946` / local | Device visual acceptance remains open. |

### Review Provenance

**Review source / link:** self-review
**Reviewer / relation to implementer:** Codex / same implementer
**Diff or commit SHA actually reviewed:** `f258e2e59c81679c7f6e3d0be66ee7c13a6ab66d` on `tnyx/mobile-number-field-focus-refinement`
**Review result and finding IDs/dispositions:** No source-scope issue found by manual review; visual/runtime validation remains open.
**Independent review?** No (self-review)
**Limitations and unmet required gates:** No device visual acceptance; existing focused widget tests do not assert the new focus outline.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|

## 7. Final Handoff

### Changed Files

- `apps/core/lib/src/ui/components/inputs/tio_mobile_number_field.dart`
- `apps/core/lib/src/theme/README.md`
- `.ai/tasks/mobile-number-field-focus-refinement.md`
- `.ai/tasks/README.md`

### Actual Behavior

The flag and country code now sit inside the same outlined field as the mobile number. Focused unverified state uses the existing primary color and focused outline width. Verified styling and number/verification behavior remain as before.

### Known Limitations

Focused widget tests pass 2/2, but they do not assert the new focus outline. Device visual validation remains incomplete. Formatting reported no changes but exited non-zero due telemetry metadata access denial. `git diff --check` passed.

### Final Status

`PARTIAL`
