# Core Group Card and Settings Rows — Phase-2B

**Status:** In progress
**Primary owner:** `apps/core` and Settings/Nutrition presentation
**Affected platforms:** Flutter mobile

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Approved
**Approval evidence:** Owner requested GitHub #183 / Linear TNYX-139 Phase-2B only on 2026-09-01.
**Approved product/UI/data-shape boundaries:** Pixel- and behavior-preserving extraction of the neutral non-selectable grouping surface and demonstrated Settings row family into `apps/core`, then migration of equivalent Settings and Nutrition consumers.
**Explicit non-changes:** Selection cards; #24 input fields; confirmation dialogs; App Mode behavior; routes; domain models; repositories; schema; Supabase; TNYX-63, TNYX-144, and TNYX-141.

## Verified Evidence and Decisions

- Fresh audit: `main` and `origin/main` both resolve to `fbee66e36e3ddcf2b5ba64be222e2fa09bd4275b`; working tree clean; one main worktree; no open PR.
- GitHub #183 is open; Phase-2A merged through PR #187. GitHub #188 is closed after PR #190. #24 owns fields and #173 owns destructive-confirmation work.
- Linear TNYX-139 remains the backlog mirror of #183; its Phase-2A comment confirms PR #187. TNYX-137/TNYX-69 are completed consumers. TNYX-63/TNYX-144/TNYX-141 are future or separate work.
- Fresh source inventory found six equivalent `surfaceRaised` / `TioRadius.lg` / clipped `Material` / `Column` group cards: Settings root, Health & Goals, Body & Weight, Daily Wellness, Nutrition hub, and Nutrition profile/targets.
- Existing `TioCard` cannot express the no-padding clipped grouping contract without overloading its general card API. Add the smallest domain-neutral `TioGroupCard`.
- No existing reusable core row represents the current navigation, editable-value, and read-only behavior. Establish only those demonstrated variants; page-owned dividers stay explicit because their indentation and alpha are intentionally different.

## Active Handoff

**Planning owner:** Codex
**Implementation owner:** Codex
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** Phase-2B changes only; ready for commit after local validation
**Branch:** `codex/core-group-card-settings-row`
**HEAD SHA:** `fbee66e36e3ddcf2b5ba64be222e2fa09bd4275b` (pre-commit)
**Observed working-tree state:** task brief, core group/row components and approved Settings/Nutrition presentation/test migrations only
**Open findings:** None
**Next action:** commit, push, create a Draft PR, update #183/TNYX-139 and observe exact-head CI. No merge.

## Implementation Checklist

- [x] Add and export core grouping/row contracts with focused widget tests.
- [x] Migrate equivalent Settings and Nutrition consumers; preserve existing keys and page-owned dividers.
- [x] Prove obsolete duplicate definitions have no references.
- [x] Run focused formatting, analyzes, tests, and `git diff --check`.
- [ ] Update GitHub #183 and Linear TNYX-139 without closing either; publish draft PR and observe exact-head CI.

## Visual Preservation Contract

Keep `surfaceRaised`, `TioRadius.lg`, clipping, child order, row padding, typography, leading/trailing affordances, tap behavior, disabled/read-only behavior, App Mode visibility, and all persisted values unchanged. No deliberate visual delta is approved.

## Local Validation

- `dart format --output=none --set-exit-if-changed` for the touched Phase-2B files; the pre-existing Sleep Schedule formatting was intentionally restored after the focused migration to avoid unrelated Phase-2A/#188 churn.
- `apps/core`: `flutter analyze` PASS; `flutter test test/ui/components/tio_group_card_settings_rows_test.dart` PASS (4 tests).
- `apps/features/settings`: `flutter analyze` PASS; root, Health & Goals, Body & Weight and Daily Wellness focused suite PASS (120 tests).
- `apps/features/nutrition`: `flutter analyze` PASS; Nutrition hub/Profile/Targets focused suite PASS (56 tests).
- `git diff --check` PASS.

## Intentional Exceptions

- `_SleepScheduleSummaryCard` remains a two-line, schedule-specific hierarchy.
- `_DailyWellnessValue` remains local because it preserves the accepted number/unit text treatment inside the shared row.
- Page dividers remain local because their leading alignment and alpha differ intentionally.
- `_UnitPreferenceRow` remains the measurement editor's label-plus-segmented-control `Wrap`, not a settings navigation/value row.
- App Mode and Nutrition choice cards remain selectable Phase-2C work; #24 fields and #173 confirmations remain untouched.
