# Pre-P9 — Workout canonical status reconciliation

**Status:** Validated — 2026-10-17 archival; bounded Workout docs correction merged in PR #582
**Primary owner:** Repository documentation governance / `docs/screens/`
**Affected platforms:** Phone Workout canonical documentation only; no Flutter, watch or backend behavior change

## Validated Outcome And Archive Decision — 2026-10-17

- **Final GitHub evidence:** [PR #582](https://github.com/im-tnyx/tio-world/pull/582) is **merged**, final PR head `22ed10cff855502d2175e40b3dfd5ad65e8ac4c8`, squash commit `28fe5cc5a03e0e7c1712f7897ea621c4b9116dae` (verified protected remote `main` at the archive baseline). Both documented P2 threads (`4298783108`, `4298783114`) are resolved. Owner authorized manual review in lieu of waiting for external reviewer, **without** claiming Codex or independent reviewer approval. Exact final head's App-pinned `Commit attribution guard` passed (App ID 5032971; workflow run `38960693197`); Flutter CI did not trigger for docs-only.
- **Canonical outcome:** Six existing [Workout / Library / Programs / Routines / Exercise screen specs](../../docs/screens/README.md) distinguish merged Routine Create/Edit/picker/atomic Name+Sets/Core action sheet from gated Workout Start, Move/Delete, default Program quick-create and release/device verification. No Flutter, database, RLS, Auth, CI, or lockfile change in PR #582.
- **Archive approval:** User `Go next` on 2026-10-17 after fresh `main@28fe5cc5` audit; a separate post-merge governance handoff/archive slice. Earlier `Go merge`/review-gate directions below are **pre-merge history**, not still-active requirements.
- **Broader status:** GitHub #250 remains Open with canonical contradiction acceptance unchecked, Linear TNYX-193 In Progress, P9 not started. Supabase inventory and other stale historical handoffs require separate bounded work.

## Owner Approval and Scope Boundary

**Trigger:** None — docs-only factual reconciliation within ongoing GitHub #250 criterion 2; owner explicitly said `Next go work start kare audit ke baad fress agent.md follow karna chahiye go` on 2026-10-17.
**Approved scope:** Fix current-state claims in `docs/screens/README.md`, `workout.md`, `library.md`, `programs.md`, `routine-library.md`, and `exercise-search.md`, plus this handoff and its current-task index entry. Preserve clearly dated historical planning and product target contracts.
**Explicit non-changes:** No app/runtime/UI/visuals/navigation, code, schema/migration/RLS/RPC, CI, lockfile, product scope, published-app release assertion, `docs/data/SUPABASE_SCHEMA.md`, `SUPABASE_STRATEGY.md`, old #563 handoff archival, Linear issue-description rewrite, GitHub #250 checkbox, or P9 routing map. No merge without separate owner `Go merge`.

## Historical Active Handoff (pre-merge snapshot)

- **Planning owner:** Repository documentation governance, GitHub #250 / Linear TNYX-193.
- **Implementation owner:** This GitHub-connected session on `docs/pre-p9-workout-canonical-status`; docs/AI handoff paths only. Workout runtime work has separate owners and is untouched.
- **Review owner:** Owner-authorized manual exact-head review for this docs-only PR; requested external `im-tio` and Codex are not represented as having approved.
- **Implementation ownership state:** Docs-only implementation complete on isolated branch; owner explicitly authorized manual review rather than waiting for `im-tio`, after earlier conditional `Go merge with gate`. Merge only after fresh exact-head technical gates and no new blocker.
- **Repository state last verified:** GitHub remote `main@633dbf38bb12aeb4a0e2920a22d63c904e087576` after merged PR #581. No open PRs at the initial reconciliation checkpoint; branch created from this immutable base SHA.
- **Observed uncommitted/dirty files:** Windows `G:\projects\Tio-World` worktree is unavailable to this GitHub connector; no local cleanliness or `git status` assertion. GitHub API changed only this isolated branch.
- **Validation completed at SHA:** Manual review at exact `4ee47ffb41e87fae0b8d8532d5d9b66ded86a4fb` against `main@633dbf38bb12aeb4a0e2920a22d63c904e087576`: base is merge-base, 20 ahead / 0 behind, 20 task-slice commits, eight scoped Markdown files only. Full eight-file contents and complete patch contain no trailing whitespace, conflict markers or missing final newline; six changed relative links all resolve. Source-verified merged Flutter Create/Edit/picker and Core Routine sheet, with no code/Supabase/CI/lockfile changes. GitHub protected `main` requires App ID `5032971` `Commit attribution guard`; exact-head check and runner both completed **success** (run `38959521284`). Flutter CI's path filter does not trigger for docs-only. This handoff edit requires final-HEAD recheck. No local Windows `git diff --check`, Flutter/device QA or hosted database query performed.
- **Validation remaining:** Revalidate new exact PR HEAD, compare/changed paths, GitHub required App check and resolved review threads after handoff/index update; then use GitHub's expected-head-SHA guarded squash merge. No external `im-tio` approval or Codex PASS is asserted; owner expressly chose manual review to avoid blocking the already authorized merge. No local Windows worktree or device/database testing in this connector session.
- **Open review finding IDs:** None among the two known P2 threads. `4298783108` (`PRRT_kwDOTOXwB86tW4ZY`) replied via `4298810721`, and `4298783114` (`PRRT_kwDOTOXwB86tW4Ze`) replied via `4298811145`; both GitHub threads confirmed **resolved** after verifying source fix `4e910ee257126ef07b3ca2d6880640a53471c4ec` at exact head `c2146371041a498d9bdc66a5c4de4eafa1f1e530`. Future reviews/checks may still surface more findings.
- **Current blocker:** None identified by the manual review of the scoped docs-only patch; remaining gate is exact new-HEAD App-pinned attribution success after these handoff edits. Owner accepted manual review instead of waiting for an external reviewer. Codex usage-limit failure is neither approval nor code finding.
- **Next exact action:** Reverify exact new HEAD and all mandatory gates, then squash merge PR #582 using `expected_head_sha` if green. Verify post-merge `main` and update GitHub #250 / Linear TNYX-193. Do not mark the broad #250 criterion done or start P9. Branch deletion and Windows-local post-merge sync are separate.

## 1. Discovery

**User outcome:** GitHub #250's canonical contradiction criterion must not treat implemented Workout Routine capabilities as future/unmerged. Improve discoverability using existing canonical docs without inventing a routing map.

**Success criteria:** Six updated specs consistently distinguish `main`-implemented Program Detail, Program-scoped Create, Exercise picker, guarded Create/Edit/atomic Name+Sets Update, Routine-card Core actions sheet from gated Workout Start, standalone Exercise Detail, default `My Program` quick-create, Move/Delete, TrainingPlan and release/device acceptance.

## 2. Codebase Exploration — verified evidence

- Audit comment: https://github.com/im-tnyx/tio-world/issues/250#issuecomment-6223288293
- GitHub #250 Open, criterion 2 unchecked, P9 not started. Linear TNYX-193 In Progress (tracking mirror); its description contains older phase prose and requires separate tracker reconciliation.
- PR #551 merged W4 Routine Create/Edit/picker; #566 merged Program-scoped Add Routine entry; #570 merged shared composer/detail Edit parity; #577 merged atomic Name+composition Edit; #581 merged Core Routine 3-dot bottom sheet.
- Current source: `apps/app/lib/app/routing/shell/shell_route.dart`; `apps/features/workout/lib/src/presentation/library/{programs/program_detail_page.dart,routines/create_routine_page.dart,routines/edit_routine_page.dart,routines/routine_detail_page.dart,routines/routine_exercise_picker_page.dart,routines/routine_metadata_card.dart}`.
- `docs/screens/routine-library.md` already includes a bounded 2026-10-16 reconciliation; older snapshots are expressly historical, not active Draft PRs.
- Existing canonical governance: `AGENTS.md`, `docs/README.md`, `.ai/workflow.md`, `.ai/tasks/README.md`, `.github/PUSH_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE.md` read; no nested `docs/AGENTS.md` or `docs/screens/AGENTS.md` found.

## 3. Clarification and 4. Architecture Design

Use existing screen document ownership. Change current-status prose and narrowly necessary boundaries only, preserving previously dated historical snapshots and unchanged target UX. No new architecture, route, schema, UI, ADR or status source. Treat merge as source-implemented, never app-store release or unverified phone QA.

Rejected alternative: create a new P9 routing map or flatten old W4 history into a fabricated all-green status.

## 5. Implementation Plan

1. Add the focused execution handoff/index before source-of-truth docs.
2. Reconcile six docs with verified current source/merged PR evidence.
3. Check exact branch diff, references, scope, status and review gates.
4. Open Draft PR referencing GitHub #250; request separate `Go merge` later.

## 6. Quality Review

**Validation run:** The initial Draft evidence was superseded by a manual full-scope audit on `4ee47ffb`: exactly eight Markdown paths, 20 ahead / 0 behind, complete eight-file Markdown hygiene pass and all six changed relative links resolved. The source-backed review checked `shell_route.dart`, Program Detail, Routine metadata card, Routine shared composer, Exercise picker and Create/Edit pages against current merged `main`. GitHub App-pinned required `Commit attribution guard` (App `5032971`) and runner passed on that SHA; documented docs-only Flutter CI path-filter. This was manual review by the current session, **not** independent or Codex approval. Exact HEAD must be refreshed after task-handoff commits.
**Review findings and resolution:** The two confirmed P2 findings (`4298783108`, `4298783114`) were corrected at `4e910ee`, replied to (`4298810721`, `4298811145`) and both threads are resolved. Fresh manual review at `4ee47ffb` found no additional blocking docs/source contradiction, broken relative link or out-of-scope change. Owner explicitly chose manual review instead of waiting for the external `im-tio` request; record this as an owner-approved review-gate substitution, not an independent approval. Codex usage-limit failure is not a source finding or approval.

## 7. Historical Final Handoff (pre-merge snapshot)

**Changed files:** Six `docs/screens/` specs, this brief and `.ai/tasks/README.md` (eight Markdown paths total).
**Actual behavior:** No application behavior changes; current-state documentation only.
**Known limitations:** No local Windows checkout or device QA, no fresh live Supabase schema query; separate schema-inventory correction and P9 determination remain open.
**Final status:** MANUAL REVIEW COMPLETE — owner-authorized review path; pending new exact-HEAD required-check verification and squash merge. The PR was not merged when this handoff was authored.
