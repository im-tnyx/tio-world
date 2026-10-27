# GitHub #699 — Library Programs single refresh cue and compact chevron/title
**Status:** In progress
**Primary owner:** apps/features/workout presentation
**Affected platforms:** Flutter Android/iOS, Library Programs surface

## Owner Approval and Scope Boundary
**Trigger:** Product-visible UI/UX change.
**Approval status:** Approved.
**Approval evidence:** Owner reported both behaviors on 2026-10-26, requested combining them in issue #699, and explicitly said “Ab aage ye sahi karna hoga ... follow agent.md” on 2026-10-27.
**Approved boundaries:** One Library Programs-level refresh indicator; retain verified same-owner rows during background loading; chevron visually adjacent to Program name with separate actions.
**Explicit non-changes:** No backend, auth, RPC, migrations, feature flags, Program Delete, Move/Undo server semantics, unrelated UI, Core token changes, or production release activation.

## Active Handoff
**Planning owner:** GitHub #699 / Linear TNYX-267 (W6B).
**Implementation owner:** im-tnyx — focused connector-authored branch `tnyx/issue-699-library-refresh-chevron-20261027`.
**Review owner:** independent code reviewer (pending)
**Implementation ownership state:** Active
**Ownership transition:** Not applicable.
**Repository state last verified:** GitHub `main@d1b373db0bff77c5d2b9bd447eb1489e21887643`; owner Windows working tree not visible to this connector.
**Branch:** `tnyx/issue-699-library-refresh-chevron-20261027`
**HEAD SHA:** `c3e6c59a9dbd51b32518def4e68d0c600b057a12` at implementation checkpoint; handoff commit will advance it.
**Observed working-tree state:** Remote GitHub branch only; local checkout not inspected.
**Observed uncommitted/dirty files:** Not observable through GitHub connector.
**PR / tracker:** https://github.com/im-tnyx/tio-world/pull/703 (Draft), https://github.com/im-tnyx/tio-world/issues/699, https://linear.app/tnyx/issue/TNYX-267.
**Current implementation state:** Authored controlled refresh states; a single Library Programs heading loader; content-preserving same-owner background reads; compact RTL-aware arrow/title and preserved separate actions; focused controller/widget regressions. Changes only in Workout feature/test files, no backend or release flags.
**Relevant execution surface:** `programs_surface.dart`, `inline_program_routines.dart`, owner-scoped presentation controllers and focused tests.
**Validation completed at SHA:** None on this new branch.
**Validation remaining:** Exact-final-HEAD Flutter CI analysis, Dart tests and app-workout shard; independent PR review and owner Android visual QA. Earlier PR test runs were cancelled when formatting/RTL fixes advanced HEAD; do not count those as exact-head PASS.
**Current blocker:** None for implementation; tests require CI or owner's Flutter installation.
**Open review finding IDs:** None observed yet.
**Next exact action:** Verify all required GitHub CI jobs against latest PR HEAD; correct failures, review diff, obtain independent review/owner visual QA; no merge yet.

## 1. Discovery
**User outcome:** Avoid a spinner under every expanded Program and eliminate needless arrow-title visual gap.
**Success criteria:** A single Programs-level refresh cue; no content disappearance during same-owner background read; strict owner-cycle invalidation; accessible 48dp separate Chevron/Program title/overflow taps; Move destination/source update remains correct.

## 2. Codebase Exploration
**Verified source:** `ProgramsSurface._routineRefreshVersion` broadcast refreshes each `InlineProgramRoutines`; `ProgramRoutinesController.load` currently publishes empty `loading`; `ProgramsController.load` also clears list. `_LibraryProgramRow` uses 48dp `centerStart` chevron next to title. `LibraryPage` currently has no pull-to-refresh.
**Existing pattern:** Existing single section heading, existing Core `TioSpacing`/`TioSize`/`TioStroke`, owner/cycle checks in Routine controller, existing Move fan-out widget tests.
**Docs:** root `AGENTS.md`, feature `AGENTS.md`, Core Theme README, `.ai/workflow.md`, Core design-system task, Workout module-ownership docs.

## 3. Clarification
- Owner-approved **one Programs-header loading cue** rather than blinking/replacing overflow.
- Preserve separate arrow-expand and title-open actions.
- Retain only same-owner/cycle verified rows while a *background* read is pending; no cached prior owner rows; write controls disabled during refresh.
- Keep startup loading, error/retry, stale UNKNOWN, and existing refresh correctness fail-closed.

## 4. Architecture Design
`LibraryPage → ProgramsSurface / InlineProgramRoutines → existing ProgramsController / ProgramRoutinesController → repository`.
- Controllers own loading/refresh data semantics, not new UI repository truth.
- Library composition aggregates current per-Program load activity only for displaying one spinner; no new persistence.
- No new Core component: one-off section cue consumes public Core visual tokens.
- Alternative rejected: hiding per-Program spinner without retaining verified rows (blank flicker), making 3-dot blink (confuses action affordance), narrowing fan-out (would leave destination stale), shrinking 48dp tap target.

## 5. Implementation Plan
- [x] Preserve validated records in refreshing controller states with owner/cycle safety.
- [x] Aggregate loading from expanded Routine controllers to single Library Programs section.
- [x] Align chevron glyph at title edge, preserve 48dp independent targets and RTL.
- [x] Add widget/controller regression tests for loading, Move fan-out, session invalidation and layout (not yet CI-verified).
- [ ] CI, exact-head review and owner Android acceptance.

## 6. Quality Review
### Validation Run
No local Flutter run: connector does not have the owner's Windows Flutter SDK or emulator. Exact-head GitHub CI triggered by Draft PR #703; conclusions pending for current HEAD. Earlier Docs Hygiene CI was green on a superseded HEAD and is not current release evidence.
### Acceptance Evidence
Code/test diffs authored in PR #703; CI and owner device receipts pending.
### Review Provenance
Independent reviewer pending. No self-review equated with approval.
### Review Findings and Resolution
None yet.

## 7. Final Handoff
**Changed Files:** `programs_surface.dart`, `programs_controller.dart`, `inline_program_routines.dart`, `program_routines_controller.dart`, `program_detail_page.dart`; focused `library_page_test.dart`, `programs_controller_test.dart`, `program_routines_controller_test.dart`, this handoff.
**Actual Behavior:** Implemented source behavior only; no successful validation recorded yet.
**Known Limitations:** No physical Android visual QA from connector.
**Final Status:** REVIEW — work pending.
