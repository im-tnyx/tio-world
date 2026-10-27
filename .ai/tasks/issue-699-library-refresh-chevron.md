# GitHub #699 — Library Programs single refresh cue and compact chevron/title
**Status:** In progress
**Primary owner:** apps/features/workout presentation
**Affected platforms:** Flutter Android/iOS, Library Programs surface

## Owner Approval and Scope Boundary
**Trigger:** Product-visible UI/UX change.
**Approval status:** Approved.
**Approval evidence:** User approved #699 implementation, then requested smaller chevron selection and original left padding; final explicit 2026-10-27 UX decision: chevron and title share ONE expand/collapse tap area and Open Program appears only in the 3-dot sheet.
**Approved boundaries:** Single Programs-level refresh indicator, owner-safe retained rows with stable card/action geometry, one combined chevron+title expand/collapse target, and Open Program as the first action in the existing 3-dot sheet. Existing Edit/Add remain; no Delete.
**Explicit non-changes:** No backend, auth, RPC, migrations, feature flags, Program Delete, Move/Undo server semantics, unrelated UI, Core token changes, or production release activation.

## Active Handoff
**Planning owner:** GitHub #699 / Linear TNYX-267 (W6B).
**Implementation owner:** im-tnyx — focused connector-authored branch `tnyx/issue-699-library-refresh-chevron-20261027`.
**Review owner:** Codex P1 + Cursor Bugbot issue (overlapping card geometry); source mitigations implemented, review confirmation pending.
**Implementation ownership state:** Active
**Ownership transition:** Not applicable.
**Repository state last verified:** GitHub `main@d1b373db0bff77c5d2b9bd447eb1489e21887643`; owner Windows working tree not visible to this connector.
**Branch:** `tnyx/issue-699-library-refresh-chevron-20261027`
**HEAD SHA:** `12300121b300ea51d25ca4980881729404859769` (latest compact-spacing, disabled-overflow guard, and widget expectation changes).
**Observed working-tree state:** Remote GitHub branch only; local checkout not inspected.
**Observed uncommitted/dirty files:** Not observable through GitHub connector.
**PR / tracker:** https://github.com/im-tnyx/tio-world/pull/703 (ready for review, not merged), https://github.com/im-tnyx/tio-world/issues/699, https://linear.app/tnyx/issue/TNYX-267.
**Current implementation state:** Single Programs heading refresh cue; content-preserving owner-safe background reads; RoutineMetadataCard keeps 48dp 3-dot geometry while disabling writes and guarding pending sheet callbacks; chevron/title is a unified full-width expand/collapse InkWell with original leading alignment, 6dp glyph-to-title gap, trimmed 4dp vertical row padding (while preserving 48dp accessible tap height), and Open Program moved to existing 3-dot TioSheet and uses the existing _openProgram readback navigation. Existing Edit/Add remain; no backend or release flags. Tests cover LTR/RTL tap, menu navigation, refresh card geometry.
**Relevant execution surface:** `programs_surface.dart`, `inline_program_routines.dart`, owner-scoped presentation controllers and focused tests.
**Validation completed at SHA:** Earlier `c27097bd` passed all Flutter/Dart CI and Docs Hygiene. New UX and review fixes advanced HEAD; exact-final-HEAD Flutter CI remains pending and earlier green results do NOT validate it.
**Validation remaining:** Exact-final-HEAD Flutter CI analysis and app-workout/navigation regressions; Docs Hygiene; independent review of all bot findings and disabled-overflow behavior; owner Android visual QA. Superseded prior runs do not count.
**Current blocker:** None for implementation; tests require CI or owner's Flutter installation.
**Open review finding IDs:** Codex P1 `#4386182151` thread `PRRT_kwDOTOXwB86wlrrN` still unresolved/outdated; Cursor `#4386201854` thread `PRRT_kwDOTOXwB86wlumn` resolved/outdated. New Cursor medium finding `#4386476685` thread `PRRT_kwDOTOXwB86wmZh7` reported disabled Routine overflow taps falling through to card navigation. Implemented a child opaque GestureDetector no-op while actions are disabled; must validate with regression test/review. Geometry test now asserts 6dp gap and reduced row padding.
**Next exact action:** Verify all required GitHub CI jobs against latest PR HEAD; correct failures, review diff, obtain independent review/owner visual QA; no merge yet.

## 1. Discovery
**User outcome:** Avoid a spinner under every expanded Program and eliminate needless arrow-title visual gap.
**Success criteria:** One Programs-level refresh cue; same-owner cards stable in size and location during background reads; strict owner-cycle invalidation; one min-48dp-height chevron+title expand/collapse action; independent 48x48dp 3-dot sheet with Open Program, Edit and Add where capabilities exist; correct Move fanout.

## 2. Codebase Exploration
**Verified source:** `ProgramsSurface._routineRefreshVersion` broadcast refreshes each `InlineProgramRoutines`; `ProgramRoutinesController.load` currently publishes empty `loading`; `ProgramsController.load` also clears list. `_LibraryProgramRow` uses 48dp `centerStart` chevron next to title. `LibraryPage` currently has no pull-to-refresh.
**Existing pattern:** Existing single section heading, existing Core `TioSpacing`/`TioSize`/`TioStroke`, owner/cycle checks in Routine controller, existing Move fan-out widget tests.
**Docs:** root `AGENTS.md`, feature `AGENTS.md`, Core Theme README, `.ai/workflow.md`, Core design-system task, Workout module-ownership docs.

## 3. Clarification
- Owner-approved **one Programs-header loading cue** rather than blinking/replacing overflow.
- Owner revision supersedes earlier separate actions: **chevron and title form ONE expand/collapse selection**. Open Program is a separate item inside existing Program 3-dot sheet; use the existing Program Detail callback and refresh on return.
- Retain only same-owner/cycle verified rows while a *background* read is pending; no cached prior owner rows; write controls disabled during refresh.
- Keep startup loading, error/retry, stale UNKNOWN, and existing refresh correctness fail-closed.

## 4. Architecture Design
`LibraryPage → ProgramsSurface / InlineProgramRoutines → existing ProgramsController / ProgramRoutinesController → repository`.
- Controllers own loading/refresh data semantics, not new UI repository truth.
- Library composition aggregates current per-Program load activity only for displaying one spinner; no new persistence.
- No new Core component: one-off section cue consumes public Core visual tokens.
- Alternatives rejected: hiding spinners while blanking cards (flicker), blinking/removing 3-dot actions during background reread (geometry shifts), narrowing Move fanout (stale destination). Owner explicitly approved a single large header tap area and full-height 48dp target; 3-dot remains separate.

## 5. Implementation Plan
- [x] Preserve validated records in refreshing controller states with owner/cycle safety.
- [x] Aggregate loading from expanded Routine controllers to single Library Programs section.
- [x] Align chevron at Library's leading edge; combine chevron + title under one accessible >=48dp-height tap target, RTL-aware; move Open Program into existing 3-dot sheet.
- [x] Add widget/controller regression tests for loading, Move fan-out, session invalidation and layout (not yet CI-verified).
- [ ] CI, exact-head review and owner Android acceptance.

## 6. Quality Review
### Validation Run
No local Flutter run: connector does not have owner's Windows Flutter SDK or emulator. Prior `c27097bd` Flutter and Docs CI success verified; new branch has review and UX changes; latest exact-head Flutter CI must finish. Earlier green runs are not new validation.
### Acceptance Evidence
Code/test diffs authored in PR #703; CI and owner device receipts pending.
### Review Provenance
Independent reviewer pending. No self-review equated with approval.
### Review Findings and Resolution
Codex P1 #4386182151 and Cursor #4386201854: during read-only refresh, removing callback-based Routine 3-dot collapsed Routine card height. Source patch adds `actionsEnabled` to canonical RoutineMetadataCard; retains menu slot but disables callbacks and guards outstanding modal actions. Deferred widget test now compares pre-/during-refresh rectangles. Await exact-head CI + follow-up reviewer acceptance.

## 7. Final Handoff
**Changed Files:** `programs_surface.dart`, `programs_controller.dart`, `inline_program_routines.dart`, `program_routines_controller.dart`, `program_detail_page.dart`; focused `library_page_test.dart`, `programs_controller_test.dart`, `program_routines_controller_test.dart`, this handoff.
**Actual Behavior:** Implemented source behavior; exact-final-head CI and owner device verification pending.
**Known Limitations:** No physical Android visual QA from connector.
**Final Status:** REVIEW — work pending.
