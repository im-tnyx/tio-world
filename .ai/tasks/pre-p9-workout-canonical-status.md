# Pre-P9 — Workout canonical status reconciliation

**Status:** In review — PR #582 opened; independent review and applicable checks pending
**Primary owner:** Repository documentation governance / `docs/screens/`
**Affected platforms:** Phone Workout canonical documentation only; no Flutter, watch or backend behavior change

## Owner Approval and Scope Boundary

**Trigger:** None — docs-only factual reconciliation within ongoing GitHub #250 criterion 2; owner explicitly said `Next go work start kare audit ke baad fress agent.md follow karna chahiye go` on 2026-10-17.
**Approved scope:** Fix current-state claims in `docs/screens/README.md`, `workout.md`, `library.md`, `programs.md`, `routine-library.md`, and `exercise-search.md`, plus this handoff and its current-task index entry. Preserve clearly dated historical planning and product target contracts.
**Explicit non-changes:** No app/runtime/UI/visuals/navigation, code, schema/migration/RLS/RPC, CI, lockfile, product scope, published-app release assertion, `docs/data/SUPABASE_SCHEMA.md`, `SUPABASE_STRATEGY.md`, old #563 handoff archival, Linear issue-description rewrite, GitHub #250 checkbox, or P9 routing map. No merge without separate owner `Go merge`.

## Active Handoff

- **Planning owner:** Repository documentation governance, GitHub #250 / Linear TNYX-193.
- **Implementation owner:** This GitHub-connected session on `docs/pre-p9-workout-canonical-status`; docs/AI handoff paths only. Workout runtime work has separate owners and is untouched.
- **Review owner:** Independent exact-head docs/source review and Codex if available.
- **Implementation ownership state:** Handoff pending — docs-only PR #582 is Ready for review; external reviewer `im-tio` requested, response pending. Do not merge.
- **Repository state last verified:** GitHub remote `main@633dbf38bb12aeb4a0e2920a22d63c904e087576` after merged PR #581. No open PRs at the initial reconciliation checkpoint; branch created from this immutable base SHA.
- **Observed uncommitted/dirty files:** Windows `G:\projects\Tio-World` worktree is unavailable to this GitHub connector; no local cleanliness or `git status` assertion. GitHub API changed only this isolated branch.
- **Validation completed at SHA:** Pre-review head `ef26b3039075de4260dadb0666cc664d1355a2b7` compared to `main@633dbf38`: 17 ahead / 0 behind, merge-base equals base and only eight approved Markdown files. Source-backed follow-up at `4e910ee257126ef07b3ca2d6880640a53471c4ec` corrects two confirmed P2 findings in `docs/screens/routine-library.md`. This handoff change requires exact-final-head recheck. Prior full-patch scan found zero added trailing-whitespace lines and all six changed relative links resolved; do not claim Flutter/hosted DB/device validation.
- **Validation remaining:** Recompare exact-final-head scope/patch/links, reply to both review findings with source evidence and resolve only after confirmation, obtain independent review (requested `im-tio`) and inspect applicable GitHub checks. GitHub Codex review at previous head `fd882e4` failed due to usage limits, not because of verified code findings; no Codex PASS. At `ef26b303` the PR had zero workflow runs and commit statuses (absence is not success). Local `git diff --check`, Flutter suite, hosted Supabase query and physical device QA were not run.
- **Open review finding IDs:** `4298783108` (`PRRT_kwDOTOXwB86tW4ZY`, canonical Document Status + Last Verified) and `4298783114` (`PRRT_kwDOTOXwB86tW4Ze`, old `main@5aec6ef1` mislabeled Current). Both source-corrected in `4e910ee257126ef07b3ca2d6880640a53471c4ec`; thread replies/resolution pending exact-head verification.
- **Current blocker:** Two documented P2 findings require verified reply/resolution; independent reviewer response and applicable GitHub check evidence remain pending. Owner merge authorization is separate.
- **Next exact action:** Run exact-final-head eight-path and markdown-link hygiene audit, reply/resolve verified P2 review threads, refresh GitHub/Linear checkpoints and receive a separate independent review and applicable CI evidence. Stop before owner `Go merge`.

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

**Validation run:** GitHub API comparison and full PR patch audit at initial Draft head `5f46ad4d` showed exactly six `docs/screens/` docs and two `.ai/tasks/` files, 14 ahead / 0 behind, no runtime/SQL/CI/lockfile changes, zero added trailing whitespace and six changed relative links resolving to existing files. All eight fetched Markdown files had no conflict markers or missing terminal newlines. Self-check found no confirmed blocking defect in the bounded docs patch; this is **not an independent approval**. No workflow runs, statuses or reviewer responses had appeared when checked. Final-head review/CI still pending.
**Review findings and resolution:** A later exact-head read-only COMMENT review submitted two confirmed P2 inline findings: canonical `Document Status` exact-value violation (`4298783108`), and historical `main@5aec6ef1` prose falsely labeled as current (`4298783114`). At `4e910ee`, corrected the exact header, updated focused Last Verified to 2026-10-17, explicitly marked pre-#570/#577/#581 snapshot historical, and added a source-verified current-main note. Both require thread reply/closure only after final-head verification. Codex usage-limit failure is not an approval or code finding.

## 7. Final Handoff

**Changed files:** Six `docs/screens/` specs, this brief and `.ai/tasks/README.md` (eight Markdown paths total).
**Actual behavior:** No application behavior changes; current-state documentation only.
**Known limitations:** No local Windows checkout or device QA, no fresh live Supabase schema query; separate schema-inventory correction and P9 determination remain open.
**Final status:** IN REVIEW — two P2 docs findings corrected awaiting exact-head recheck/thread disposition; independent reviewer requested; no CI/Codex PASS or approval established; not merged.
