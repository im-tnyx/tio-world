# Phase-2B Post-Merge Review Remediation

**Status:** In progress
**Primary owner:** `apps/features/nutrition` + `apps/core` design-system documentation
**Affected platforms:** Flutter phone UI

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** This is a scoped correction of two valid post-merge review findings from PR #191, explicitly requested by the owner.
**Approved product/UI/data-shape boundaries:** Restore the prior single-line restrictions-label geometry, add focused compact-width coverage, and document the public Phase-2B core components.
**Explicit non-changes:** No shared-row default change, selection cards, fields, Settings consumers, Nutrition Targets, routes, repositories/domain, persistence, schema, Supabase, Phase-2C, #24, TNYX-63, TNYX-144, or TNYX-141.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** GitHub Codex automated review after publication
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-01; clean `main` matched `origin/main` before branch creation.
**Branch:** `codex/phase2b-post-merge-remediation`
**HEAD SHA:** `265dfae3b8a1badadb3cffc8308a87ec09129078`
**Observed working-tree state:** Four scoped remediation files modified/untracked; no unrelated files.
**Observed uncommitted/dirty files:** This task brief, Nutrition Profile source/test, and core theme README.
**PR / tracker:** Follow-up to PR #191; GitHub #183 and Linear TNYX-139 remain open.
**Current implementation state:** Both findings implemented and locally validated; publication, exact-head CI, and Codex review gates remain.
**Relevant execution surface:** Nutrition Profile restrictions summary row and core theme/design-system component guidance.
**Validation completed at SHA:** Scoped working tree atop `265dfae3b8a1badadb3cffc8308a87ec09129078`: focused format; Nutrition/Core analyze PASS; Nutrition Profile 27/27 PASS; `git diff --check` PASS.
**Validation remaining:** Exact-head CI and asynchronous Codex review gate after publication.
**Current blocker:** None.
**Open review finding IDs:** `discussion_r3903038287`, `discussion_r3903038295`
**Next exact action:** Commit and publish the four-file remediation as a Draft PR.

## Global UI / Design-System Guardrail

This remediation follows `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md`. It restores the pre-PR #191 rendered contract and does not authorize a redesign.

## 1. Discovery

### User Outcome

Close the two valid asynchronous Codex review omissions from merged PR #191 without broadening Phase-2B.

### Success Criteria

- `Allergies & Restrictions` keeps one line with ellipsis at compact phone width.
- Focused widget coverage asserts the actual `Text` contract.
- The core theme README documents every public GroupCard/Settings-row contract introduced by PR #191.
- Follow-up exact-head CI passes and automated Codex review completes with zero current unresolved threads before merge.
- Original PR #191 threads are resolved only after the remediation merge is verified.

### Scope

- Nutrition Profile restrictions-row consumer.
- Focused Nutrition Profile widget test.
- Core theme/design-system README.
- This task brief.

### Non-Goals

- Changing `TioSettingsValueRow` defaults or implementation.
- Any selection-card, field, domain, persistence, navigation, schema, or Supabase work.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `nutrition_profile_settings_page.dart`, `tio_settings_rows.dart`, `tio_group_card.dart`, and `apps/core/lib/src/theme/README.md`.
- Existing pattern to follow: `TioSettingsValueRow.labelSingleLine` already maps to `Text(maxLines: 1, overflow: TextOverflow.ellipsis)`.
- Tests or validation already present: `nutrition_profile_settings_page_test.dart` owns Profile summary/editor widget coverage and configurable test viewport setup can remain local.
- Fresh GitHub audit found exactly two unresolved, current, non-outdated PR #191 threads; both are valid and directly Phase-2B.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Apply `labelSingleLine: true` only to the restrictions consumer | Made | Restores the prior row contract without changing unrelated labels. | Owner contract |
| Assert `Text.maxLines` and `Text.overflow` at compact width | Made | Stable contract coverage without brittle pixel/golden comparison. | Implementation owner |
| Document only shipped public APIs | Made | Closes governance drift without speculating about Phase-2C. | Owner contract |

## 4. Architecture Design

### Chosen Approach

Use the existing shared-row capability at the one affected consumer, extend the owning feature test, and add public consumption guidance to the canonical core README.

### Ownership and Data Flow

```text
Nutrition Profile presentation -> public tio_core Settings row contract
```

No controller, repository, data-source, or schema flow changes.

### Alternative Rejected

Changing the global `labelSingleLine` default was rejected because it would alter unrelated consumers beyond the reviewed regression.

### Failure and Accessibility States

Navigation and tap behavior remain unchanged. Ellipsis restores compact-width stability while retaining the full semantic text value.

## 5. Implementation Plan

- [x] Set `labelSingleLine: true` on the restrictions row only.
- [x] Add compact-width contract coverage.
- [x] Document all shipped Phase-2B group/settings row components.
- [x] Run focused validation and inspect the final diff.
- [ ] Publish a Draft PR, then wait for exact-head CI and asynchronous Codex review before merge.
- [ ] Resolve original PR #191 threads only after verified merge.

## 6. Quality Review

### Validation Run

```text
G:\dev\flutter-sdk\bin\dart.bat format
  lib/src/presentation/pages/nutrition_profile_settings_page.dart
  test/presentation/nutrition_profile_settings_page_test.dart
PASS

G:\dev\flutter-sdk\bin\flutter.bat analyze  # apps/features/nutrition
PASS — No issues found

G:\dev\flutter-sdk\bin\flutter.bat analyze  # apps/core
PASS — No issues found

G:\dev\flutter-sdk\bin\flutter.bat test
  test/presentation/nutrition_profile_settings_page_test.dart
PASS — 27 tests

git diff --check
PASS
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| `discussion_r3903038287` | P2 | Resolved | Restrictions label lost its prior single-line ellipsis contract. | `54ed532ec8393be8b9e3d63ff0e3dba242b6c881` | Consumer fix plus compact-width contract test; original thread stays open until remediation merge. |
| `discussion_r3903038295` | P2 | Resolved | New public GroupCard/Settings-row contracts were not documented. | `54ed532ec8393be8b9e3d63ff0e3dba242b6c881` | Canonical core theme README now documents every shipped Phase-2B contract; original thread stays open until remediation merge. |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/phase2b-post-merge-remediation.md`
- `apps/core/lib/src/theme/README.md`
- `apps/features/nutrition/lib/src/presentation/pages/nutrition_profile_settings_page.dart`
- `apps/features/nutrition/test/presentation/nutrition_profile_settings_page_test.dart`

### Actual Behavior

The restrictions label again uses one line with ellipsis at compact width. Public core GroupCard and Settings-row ownership/consumption guidance is current.

### Known Limitations

Exact-head CI and asynchronous Codex review must complete with zero current unresolved follow-up threads before merge.

### Final Status

`REVIEW`
