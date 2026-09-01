# Phase-2B Post-Merge Review Remediation

**Status:** Ready to merge
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
**Review owner:** Owner-performed manual substantive review (see Review Gate below)
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-01; clean `main` matched `origin/main` before branch creation.
**Branch:** `codex/phase2b-post-merge-remediation`
**Last source/test-changing HEAD:** `523ef2879e28d4fbcd154caa023bfd2efcee6b14` — the head all source, test and CI validation below was performed against.
**Final HEAD:** this governance-text commit, applied on top of `523ef287`. It changes documentation only; the Flutter source and test diffs are byte-identical to `523ef287`, so no code validated above is invalidated by it. The exact final SHA is recorded in the PR body, which a commit cannot self-reference.
**Observed working-tree state:** Clean after the governance update.
**Observed uncommitted/dirty files:** None.
**PR / tracker:** PR #192 (Ready for review), follow-up to PR #191; GitHub #183 and Linear TNYX-139 remain open.
**Current implementation state:** Both findings implemented, validated, published, reviewed, and clear to merge.
**Relevant execution surface:** Nutrition Profile restrictions summary row and core theme/design-system component guidance.
**Validation completed at SHA:** `523ef2879e28d4fbcd154caa023bfd2efcee6b14`: focused format; Nutrition/Core analyze PASS; Nutrition Profile 27/27 PASS; `git diff --check` PASS; **repository Flutter CI `Analyze and test` PASS**.
**Validation remaining:** None.
**Current blocker:** None.
**Open review finding IDs:** None current. `discussion_r3903038287` and `discussion_r3903038295` are the original PR #191 threads, deliberately left open until this remediation is merged.
**Next exact action:** Squash merge PR #192, delete the branch, then resolve the two original PR #191 threads.

## Review Gate

**Automated latest-head Codex review: unavailable.** The Codex code-review quota was exhausted, and the only routes offered were an account upgrade or purchased credits. The owner's standing constraint is that no paid tooling is used, so that gate could not be satisfied and was not waited on indefinitely.

The earlier automated Codex review ran against `2046e24741c25a82a7eadeebca1bfbdd537e2fb5`, **not** against the final source head `523ef287`. Its one finding (machine-specific SDK paths) was fixed in `523ef287` and its thread is resolved and outdated. **No automated review of `523ef287` exists, and none is claimed here.**

**Substituted with a manual substantive review**, which inspected:

- the actual four-file diff, not just the file list;
- the shared default — `labelSingleLine` remains `false` in `apps/core/lib/src/ui/components/settings/tio_settings_rows.dart`, which this PR does not touch; only one call site opts in;
- consumer scope — all four `TioSettingsValueRow` consumers were checked for the same regression. `Allergies & Restrictions` (24 characters) is the longest label by nine characters; the next longest is `Starting Weight` (15). No other consumer needs the flag, so the fix is correctly scoped rather than under-scoped. The same `labelSingleLine: true` pattern already ships on `main` at `nutrition_targets_settings_page.dart`;
- compact-label coverage — the new test pins `maxLines == 1` and `overflow == TextOverflow.ellipsis` at 320px width;
- the README contract — `TioGroupCard` plus all six `TioSettings*` components and feature-consumption guidance are documented.

**Result: no defect found. Merge readiness: READY.**

One honest limitation of the coverage, recorded rather than hidden: the new test asserts widget properties, not rendered geometry. It would still pass if the label did not actually overflow at 320px. This matches how contract coverage is written elsewhere in the repository, but it is not visual proof.

## Global UI / Design-System Guardrail

This remediation follows `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`, and `apps/features/AGENTS.md`. It restores the pre-PR #191 rendered contract and does not authorize a redesign.

## 1. Discovery

### User Outcome

Close the two valid asynchronous Codex review omissions from merged PR #191 without broadening Phase-2B.

### Success Criteria

- `Allergies & Restrictions` keeps one line with ellipsis at compact phone width.
- Focused widget coverage asserts the actual `Text` contract.
- The core theme README documents every public GroupCard/Settings-row contract introduced by PR #191.
- Follow-up exact-head CI passes and a completed substantive review reports zero current unresolved threads before merge.
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
- [x] Publish Draft PR #192 and reply to both original PR #191 findings without resolving them.
- [x] Exact-head Flutter CI PASS on `523ef287`.
- [x] Substantive review completed with no defect found; automated latest-head Codex review unavailable under the no-paid-tools constraint.
- [ ] Resolve original PR #191 threads only after verified merge.

## 6. Quality Review

### Validation Run

```text
dart format
  lib/src/presentation/pages/nutrition_profile_settings_page.dart
  test/presentation/nutrition_profile_settings_page_test.dart
PASS

flutter analyze  # working directory: apps/features/nutrition
PASS — No issues found

flutter analyze  # working directory: apps/core
PASS — No issues found

flutter test  # working directory: apps/features/nutrition
  test/presentation/nutrition_profile_settings_page_test.dart
PASS — 27 tests

git diff --check
PASS

Repository Flutter CI  # GitHub Actions, exact head 523ef287
  Analyze and test
PASS
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| `discussion_r3903038287` | P2 | Resolved | Restrictions label lost its prior single-line ellipsis contract. | `54ed532ec8393be8b9e3d63ff0e3dba242b6c881` | Consumer fix plus compact-width contract test; original thread stays open until remediation merge. |
| `discussion_r3903038295` | P2 | Resolved | New public GroupCard/Settings-row contracts were not documented. | `54ed532ec8393be8b9e3d63ff0e3dba242b6c881` | Canonical core theme README now documents every shipped Phase-2B contract; original thread stays open until remediation merge. |
| `discussion_r3903298318` | P1 | Resolved | The task brief recorded machine-specific Flutter SDK paths. | `2046e24741c25a82a7eadeebca1bfbdd537e2fb5` | Validation commands now use portable tool names with explicit repository working directories. |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/phase2b-post-merge-remediation.md`
- `apps/core/lib/src/theme/README.md`
- `apps/features/nutrition/lib/src/presentation/pages/nutrition_profile_settings_page.dart`
- `apps/features/nutrition/test/presentation/nutrition_profile_settings_page_test.dart`

### Actual Behavior

The restrictions label again uses one line with ellipsis at compact width. Public core GroupCard and Settings-row ownership/consumption guidance is current.

### Known Limitations

No automated Codex review exists for the final source head `523ef287`; the quota was exhausted and the only routes offered were paid, which the owner's standing constraint rules out. A manual substantive review was performed instead and found no defect. See the Review Gate section for exactly what it inspected and what it did not.

The compact-width test asserts the `Text` widget contract rather than rendered geometry, so it is contract coverage, not visual proof.

### Final Status

`READY`
