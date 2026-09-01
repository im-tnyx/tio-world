# GitHub #24 Phase #24-B — Nutrition Numeric Input Migration

**Status:** Validated
**Primary owner:** `apps/core` input contract + `apps/features/nutrition` presentation
**Affected platforms:** Flutter phone app

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner explicitly requested GitHub #24 Phase #24-B in the current task.
**Approved product/UI/data-shape boundaries:** Migrate only the two existing Nutrition exact numeric editors to `TioInput`; preserve their current rendered appearance and behavior.
**Explicit non-changes:** No Nutrition Profile “Other” migration; no Workout, Settings, Auth, Onboarding, Body & Weight, routes, `TioEditorSheet`, domain/repository, schema, Supabase, or broad core redesign changes. GitHub #24 remains open.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Codex self-review after implementation
**Implementation ownership state:** Review remediation
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-01
**Branch:** `codex/nutrition-numeric-tio-input`
**HEAD SHA:** `654ec83cd83513a1a25e5a99dff5950e8f9a9c91` (reviewed head before audit-record remediation)
**Current local rebased head:** `f485fb021ee676b81f00466dda5e85b42a3256b7` (same 10-file implementation delta on rewritten `origin/main`)
**Observed working-tree state:** Clean before this audit-record remediation
**Observed uncommitted/dirty files:** None before this audit-record remediation
**PR / tracker:** GitHub #195 OPEN, Draft; Linear TNYX-146 In Review; no overlapping open PR
**Current implementation state:** Runtime implementation complete and substantively reviewed; PR #195 published; this audit-record remediation addresses the sole remaining P2 finding
**Relevant execution surface:** `TioInput`, Nutrition target exact editor, Nutrition macro exact-entry editor, focused widget tests
**Reviewed head before remediation:** `654ec83cd83513a1a25e5a99dff5950e8f9a9c91`
**Exact-head Flutter CI:** Run `33519625981` — `SUCCESS` on the reviewed head
**Local validation:** Core analyze PASS; core focused tests 18 PASS; core full suite 151 PASS; Nutrition analyze PASS; Nutrition focused tests 51 PASS; Nutrition full suite 133 PASS; `git diff --check` PASS
**Substantive runtime review:** PASS; only remaining finding was audit-record accuracy
**Validation remaining:** Commit/push this record refresh, rerun exact-head Flutter CI on the resulting head, resolve the review thread, and complete final merge gates
**Current blocker:** None
**Open review finding IDs:** None; P2 audit-record accuracy finding resolved by this remediation
**Next exact action:** Commit/push the two-record refresh, verify new-head CI/review/thread state, then proceed through the approved PR #195 merge gate.

## Global UI / Design-System Guardrail

This work follows `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md`. The migration is pixel-preserving: existing dense geometry, text/hint/unit hierarchy, theme borders, colors, and interaction behavior remain unchanged. `TioInput.standard`, `TioInput.compactNumber`, and the specialized username/mobile family are not visually changed.

## 1. Discovery

### User Outcome

The Calories/Fiber and Protein/Carbohydrate/Fat exact numeric editors consume the governed core input component instead of reconstructing the same raw field locally.

### Success Criteria

- Exactly the two approved Nutrition raw fields use `TioInput`.
- Stable keys, controllers, enabled/autofocus state, keyboard, formatter, Done submission, suffix, hint, blank semantics, validation, retry/save, coherence, slider synchronization, and persistence behavior remain unchanged.
- No raw-field type dependency remains in focused tests where a stable key or public `TioInput` contract is sufficient.
- Existing standard and compact-number input contracts remain unchanged.

### Scope

- `apps/core/lib/src/ui/components/inputs/tio_input.dart`
- `apps/core/lib/src/theme/README.md`
- `apps/core/test/ui/components/tio_input_test.dart`
- The two approved Nutrition page files and their focused tests

### Non-Goals

- Consumer migrations outside the two approved editors
- A feature-specific core component or token family
- Any domain, repository, persistence, schema, or Supabase change
- Closing GitHub #24 or merging the resulting PR

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: core `TioInput`, `TioInputTokens`, `TioTheme` input decoration, both Nutrition editors, their tests, and repository-wide raw Nutrition field inventory.
- Existing pattern to follow: public `package:tio_core/core.dart` component boundary with named variants for materially different reusable appearances.
- Tests or validation already present: core input API/default regression tests; Nutrition exact-entry, blank, validation, coherence, slider-sync, retry, and save tests.
- Raw production inventory: the two in-scope fields plus Nutrition Profile “Other”, which is explicitly out of scope.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep other Issue #24 consumers out of this slice | Decided | Owner explicitly bounded Phase #24-B to Nutrition numeric editors | Owner |
| Do not use `compactNumber` | Decided | It is centered, underline/table-oriented, and would change current sheet geometry | Codex |
| Add a domain-neutral dense numeric-editor variant | Decided | Both target consumers share the same evidenced contract; standard input would also alter padding and outline behavior | Codex |

## 4. Architecture Design

### Chosen Approach

Add a named `TioInput.numericEditor` variant that owns only the proven reusable presentation defaults while continuing to accept feature-owned controller, formatter, unit, enabled state, and callbacks. Preserve the current raw field's dense `InputDecoration` defaults, allow the active theme to supply fill/border/radius/padding, and apply the same text/hint/suffix styles.

### Ownership and Data Flow

```text
Nutrition sheet state/controller
  -> TioInput.numericEditor presentation contract
  -> existing validation/draft/save callbacks
  -> existing Nutrition repository/persistence path
```

### Alternative Rejected

- `TioInput.compactNumber`: different table-input alignment, border, focus-selection, and geometry.
- `TioInput.standard` with ad hoc overrides: still changes theme border widths/padding and would expose low-level styling knobs instead of a reusable contract.
- Feature-local wrapper: duplicates a proven shared input contract in Nutrition.

### Failure and Accessibility States

Existing validation copy, external error placement, disabled saving state, keyboard Done behavior, focus/autofocus, and `TextFormField` semantics remain unchanged.

## 5. Implementation Plan

- [x] Add and document `TioInput.numericEditor` without changing existing variants.
- [x] Pin the new core contract and existing variant regressions in core tests.
- [x] Migrate both approved Nutrition editors while retaining stable keys and behavior.
- [x] Replace brittle raw `TextField` test coupling with stable-key/public-contract assertions.
- [x] Run focused and relevant validation, complete substantive self-review, and publish Draft PR #195.
- [x] Refresh the durable task records to the published/reviewed state and resolve the audit-record accuracy finding.
- [ ] Commit/push this remediation, verify exact-head CI on the new head, resolve the review thread, and complete merge gates.

## 6. Quality Review

### Validation Run

```text
G:\dev\flutter-sdk\bin\dart.bat format <focused Dart files> — PASS
apps/core: flutter analyze — PASS, no issues
apps/core: flutter test test/ui/components/tio_input_test.dart — PASS, 18 tests
apps/core: flutter test — PASS, 151 tests
apps/features/nutrition: flutter analyze — PASS, no issues
apps/features/nutrition: focused target + macro page tests — PASS, 51 tests
apps/features/nutrition: flutter test — PASS, 133 tests
Repository search — PASS; only out-of-scope Nutrition Profile “Other” raw TextField remains
App tests — not applicable; no app composition, route, or key change
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| SR-1 | — | Resolved | No substantive correctness, behavior, visual-contract, or scope-leakage finding | `654ec83cd83513a1a25e5a99dff5950e8f9a9c91` | Runtime/core/Nutrition review PASS; exact-head Flutter CI run `33519625981` SUCCESS |
| AR-1 | P2 | Resolved | Durable task records still described the pre-publication/pre-CI state | `654ec83cd83513a1a25e5a99dff5950e8f9a9c91` | This remediation records branch, PR #195, reviewed head, validation evidence, CI success, scope boundary, and current merge-gate state |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/issue-24b-nutrition-numeric-input-migration.md`
- `apps/core/lib/src/theme/README.md`
- `apps/core/lib/src/theme/tokens/components/tio_input_tokens.dart`
- `apps/core/lib/src/ui/components/inputs/tio_input.dart`
- `apps/core/test/ui/components/tio_input_test.dart`
- `apps/features/nutrition/lib/src/presentation/pages/nutrition_macros_settings_page.dart`
- `apps/features/nutrition/lib/src/presentation/pages/nutrition_targets_settings_page.dart`
- `apps/features/nutrition/test/presentation/nutrition_macros_settings_page_test.dart`
- `apps/features/nutrition/test/presentation/nutrition_targets_settings_page_test.dart`

### Actual Behavior

The two approved exact numeric editors now use `TioInput.numericEditor`. Stable keys, controller ownership, enabled/autofocus state, decimal keyboard, formatter, Done submission, suffix/hint hierarchy, blank-as-unset behavior, validation, coherence, retry/save, and macro slider synchronization are preserved. Standard and compact-number input variants are unchanged.

### Known Limitations

Consumer migrations outside this two-editor slice remain under GitHub #24. The Nutrition Profile “Other” raw field remains intentionally unchanged. Schema is NONE and Supabase is UNCHANGED.

### Final Status

`VALIDATED` — PR #195 remains OPEN/Draft pending new-head CI, review-thread resolution, and final merge gates.
