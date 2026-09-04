# Product Onboarding Card Variant Cleanup

**Status:** Validated
**Primary owner:** `apps/features/onboarding`
**Affected platforms:** Flutter Android and iOS

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI/UX change
**Approval status:** Approved
**Approval evidence:** On 2026-09-04 the owner explicitly requested removal of the unused `TargetsCompatibilityScreen`, then requested changing the two remaining active `TioCardVariant.outlined` onboarding cards to `TioCardVariant.elevated`.
**Approved product/UI/data-shape boundaries:** Delete the unreachable compatibility placeholder; change only the Health Connections status card and Sleep schedule card from outlined to elevated; align directly stale documentation/comments with current Nutrition Target runtime truth.
**Explicit non-changes:** No layout, spacing, typography, copy, interaction, navigation, controller, persistence, calculation, Core component, theme-token, Supabase, or external-system changes. No other card variants change.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Not applicable
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-04
**Branch:** `codex/onboarding-card-variant-cleanup`
**HEAD SHA:** `68b85c88869be5ad9d6c4613d18b3c4d12a57810`
**Observed working-tree state:** Scoped task changes only.
**Observed uncommitted/dirty files:** Deleted compatibility screen; updated target validator comments and onboarding architecture truth.
**PR / tracker:** None
**Current implementation state:** Dead placeholder removed; both approved active cards use the elevated variant; focused and package validation passed.
**Relevant execution surface:** Product Onboarding Health Connections and Sleep schedule presentation.
**Validation completed at SHA:** Uncommitted working tree based on `68b85c88869be5ad9d6c4613d18b3c4d12a57810`; focused tests 9/9, full onboarding tests 450/450, onboarding analyze, format, zero-reference search, and `git diff --check` passed.
**Validation remaining:** Optional runtime/device visual review for the approved shadow/fill change.
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Owner review; commit/push only if explicitly requested.

## Global UI / Design-System Guardrail

This task follows `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md`. The visible approval is limited to the two named card fill/elevation treatments. Existing `TioCard` is reused through `package:tio_core/core.dart`; no reusable Core contract changes.

## 1. Discovery

### User Outcome

Remove an unreachable compatibility screen and make the two remaining active outlined onboarding cards use the existing elevated card treatment.

### Success Criteria

- `TargetsCompatibilityScreen` and all live references are absent.
- Health Connections status card uses `TioCardVariant.elevated`.
- Sleep schedule card uses `TioCardVariant.elevated`.
- No active `TioCardVariant.outlined` usage remains in Product Onboarding.
- Focused validation passes.

### Scope

- `apps/features/onboarding/lib/src/presentation/screens/health/health_connections_screen.dart`
- `apps/features/onboarding/lib/src/presentation/screens/targets/sleep_target_screen.dart`
- unused compatibility-screen deletion
- directly stale comments/docs naming the removed blocker

### Non-Goals

- Redesigning either screen
- Changing card content or behavior
- Changing `TioCard` or `TioCardTokens`
- Changing Nutrition Target calculations or persistence

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: both active outlined call sites, `TargetStepRenderer`, Nutrition Target calculator adapter, full-repository symbol references.
- Existing pattern to follow: the same screens already use `TioCardVariant.elevated` for other primary card surfaces.
- Tests or validation already present: onboarding package Flutter tests and analyzer configuration.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Delete unreachable compatibility placeholder | Approved | No runtime constructor, renderer, route, or test consumes it | Owner |
| Change exactly two active outlined cards to elevated | Approved | Explicit owner request after usage inventory | Owner |

## 4. Architecture Design

### Chosen Approach

Use the existing `TioCardVariant.elevated` enum value at the two call sites. No wrapper, new variant, or token is needed.

### Ownership and Data Flow

```text
Onboarding screen -> public TioCard -> existing Core theme/tokens
```

### Alternative Rejected

Changing `TioCard` defaults or removing `outlined` globally would affect unrelated consumers and exceeds the approved scope.

### Failure and Accessibility States

No state or semantics changes. Existing Health Connections live-region semantics and Sleep time-picker interactions remain unchanged.

## 5. Implementation Plan

- [x] Verify the compatibility screen has no runtime consumer.
- [x] Delete the compatibility placeholder and correct directly stale truth references.
- [x] Change the two approved active card variants.
- [x] Run focused validation and review the final diff.

## 6. Quality Review

### Validation Run

```text
dart format <5 touched Dart files> -> PASS
flutter test test/domain/o7b_health_connections_runtime_test.dart test/presentation/targets_section_test.dart --reporter expanded -> PASS, 9/9
flutter analyze -> PASS, no issues
flutter test --reporter compact -> PASS, 450/450
git diff --check -> PASS
rg obsolete compatibility symbols / active outlined onboarding cards -> PASS, no live source matches
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| None | — | Resolved | No review finding recorded | `68b85c88` | Scoped source inventory |

## 7. Final Handoff

### Changed Files

- Deleted `apps/features/onboarding/lib/src/presentation/screens/targets/targets_compatibility_screen.dart`.
- Updated Health Connections and Sleep schedule card variants.
- Added focused widget assertions for both elevated contracts.
- Corrected stale Nutrition Target comments and architecture documentation.
- Added this focused task brief and task index entry.

### Actual Behavior

The unreachable compatibility placeholder is absent. Health Connections status and Sleep schedule now use the existing elevated card appearance; navigation, data, semantics, copy, and interactions are unchanged.

### Known Limitations

No screenshot/golden or physical-device visual review was run. Widget tests lock the selected component variant, not rendered pixels.

### Final Status

`PASS`
