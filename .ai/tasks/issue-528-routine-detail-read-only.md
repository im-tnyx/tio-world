# GitHub #528 — Routine card opens owner-scoped read-only Routine Detail

**Status:** REVIEW; three scoped review fixes authored, Flutter CI and independent re-review pending  
**Primary owner:** `apps/features/workout` (Routine presentation/read controller), `apps/app` only for provider/navigation composition  
**Affected platforms:** Flutter phone; no watch, Supabase schema or backend changes

## Owner Approval and scope boundary
**Trigger:** Owner-approved bounded UI slice.
**Approval:** User 2026-10-11 `Go` directly following recommendation: existing GitHub #528 owner-scoped read-only Routine Detail, before full W4B builder; first preserve active #527 anchored popup ownership.
**In:** Program Detail and expanded Library Routine-card *primary tap* → selected Routine read-only detail, using exactly owning ProgramId and RoutineId. Separate Routine overflow **Edit** → existing Rename; no primary Rename. Revision-validated composition read, canonical catalog/user ExerciseRef lookup, ordered entry/set values, counts, missing/empty/failure/permission/retry/back, focused tests. Preserve popup geometry/behavior from owner-approved #527.
**Out:** Workout Start, prescribed duration/cardio/warmup without data, exercise/set editor or picker, inferred imagery, media Storage, delete/archive, Default My Program, new schema/RPC/RLS, release or production writes; broad W1/W3/W4 acceptance.

## Current truthful handoff
**Previous Implementation owner:** Previous #528 child-branch GitHub connector session (paused with handoff pending, last source head `7a38daf29148e66320a6ceea241f3bba525cd349`).
**Receiving Implementation owner:** Current GitHub-connected session, 2026-10-12 (review findings repair inside the existing #528 approved scope only).
**Review owner:** Prior independent read-only PR review #5484665302; receiving implementation owner is not its own independent reviewer.
**Implementation ownership state:** Review-fix implementation paused at verified follow-up head `e7391f6ad394135b50b7ae8e1e069ac88eb1e91f` pending parent merge and CI; no concurrent source writer observed at takeover. Receiving owner must reconstruct head before any further edits. Owner's Windows working tree unavailable, so local `git status`/Flutter execution cannot be claimed.
**Open finding continuity:** All three findings originated at `7a38daf2` and remain **Open / fix authored, unvalidated**: P1 session identity reset `PRRT_kwDOTOXwB86rQ1y9` (`8c1a45e` + in-flight disposal test `e7391f6`); P2 conditional catalog load `PRRT_kwDOTOXwB86rQ1zD` (`04c044f`, test constructor correction `d2d5f4e`); P2 lazy entry rendering `PRRT_kwDOTOXwB86rQ1zH` (`44c3d78`). No thread resolved until exact-head CI and independent re-review.
**Original verified source:** protected main `83e6fb813fc64b13b5bacc9863f67ab9ee9b8cbc`, PR #525 merged. PR #527 OPEN with independent implementation owner: `tnyx/issue-524-routine-popup-card@54758eaca923ed7da7e6544e54592e4a73ad5b56`, Flutter CI/attribution PASS; Codex quota limitation. Docs-only #523 OPEN and unrelated.
**Child branch:** `tnyx/issue-528-routine-detail-read-only` forked from exact #527 head `54758eaca923ed7da7e6544e54592e4a73ad5b56`. Open **stacked PR base = #527 branch**, NOT main; after parent merges reconcile base. No force-push or history rewrite.
**Local working tree:** User Windows checkout not accessible; GitHub API compares substitute for local git. No claim of local Flutter tests. No source changes to parent #527 branch.
**Planning dependencies:** [Linear TNYX-81](https://linear.app/tnyx/issue/TNYX-81) Backlog blocked by TNYX-78/W1 and TNYX-80/W3; TNYX-267 Backlog blocked by TNYX-266/TNYX-81. #528 is scoped carve-out and does not lift these gates.
**Current implementation state:** Owner-scoped RoutineDetailController/Page, canonical Exercise resolution, existing app composition provider, Library/Program Detail routing and popup Edit separation implemented on child branch. Regression tests authored for owner association, repeated/archived/missing Exercise refs, error/empty/retry, Program/Library navigation and distinct popup Edit; **not executed locally**.
**Observed working tree:** No access to owner's Windows worktree. GitHub API verified child branch head `e7391f6ad394135b50b7ae8e1e069ac88eb1e91f` after 6 scoped follow-up commits (including ownership handoff). No local uncommitted-file claim.
**Relevant code:** Workout-owned `RoutineCompositionRepository` and `SupabaseRoutineCompositionRepository` have read-only, revision-bracketed, owner-filtered snapshot reads; `RoutineRepository.list(ProgramId)` validates metadata owner association. `ExerciseCatalogRepository.load()` resolves canonical `ex_*`; `UserExerciseRepository.list(includeArchived: true)` resolves user UUID; unresolved refs show explicitly unavailable. Existing `RoutineMetadataCard` in #527 is a Core `TioCard` with anchored Edit-only popup; decouple `onTap` from `onEdit` on child only.
**Validation:** No Flutter/Dart executable in connected session; no local tests run. Latest head `e7391f6` has **0 GitHub check-runs** while PR #530 still targets `tnyx/issue-524-routine-popup-card`; `flutter-ci.yml` and attribution guard are main-targeted. Added two catalog, one large-list, one sign-out route, and one in-flight-disposal regression tests; **auth switch/reentry and Flutter execution must still be verified**. Static GitHub PR patch scan found no added-line trailing whitespace/conflict markers, but is not `git diff --check`. Codex bot quota notice is not approval. No direct CI policy change.
**Next exact action:** Await separate owner `Go merge #527`, verify parent merge + post-merge sync, reconcile/retarget child to fresh `main` without force/rewrite, then run exact-head Flutter/attribution and independent review. Add account-switch/in-flight navigation regression if re-review requires it; resolve each PR review thread only with passing validation. STOP before #530 merge unless separately owner-authorized.

## Boundary and rejected alternatives
- Reject clicking a Routine card to open Rename (owner-reported bug), opening a fake empty preview or showing enabled Start Workout before session engine exists.
- Reject a second independent Routine/Exercise truth: use canonical IDs and existing owner-safe repositories, never clone catalog or user-created Exercise.
- Reject changing #527 implementation branch, which is under a different implementation owner.
- Data access checks selected Routine belongs to selected Program via metadata before reading composition; auth changes/errors fail closed and never retain stale data.
