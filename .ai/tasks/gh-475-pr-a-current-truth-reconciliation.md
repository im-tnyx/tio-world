# GitHub #475 PR-A — Library current-truth reconciliation

**Status:** In progress — audit complete; tracker/docs reconciliation active
**Primary owner:** Workout Library planning/docs (apps/features/workout)
**Affected platforms:** Flutter mobile planning/navigation only; no runtime mutation in PR-A
**GitHub tracker:** #475
**Linear trackers:** TNYX-78, TNYX-80, TNYX-81, TNYX-83, TNYX-264, TNYX-267

## Outcome

Reconcile GitHub #475 and canonical Workout Library planning with the runtime actually shipped on main, without implementing new Library UI. Split later runtime work into dependency-safe tracker-backed PRs so Program/Routine ownership, default My Program, and future capabilities are not mixed into one large change.

## Approval

**Approval status:** Approved
**Approval evidence:** On 2026-10-05 the owner approved splitting #475 into tracker-backed PRs and explicitly instructed starting the first audit/reconciliation slice with durable tracker comments/handoff context.

PR-A is documentation/tracker reconciliation only. It does not authorize a new visible Library layout, Program/Routine runtime behavior, Supabase schema/column changes, or standalone workout-start behavior.

## Verified baseline

Repository anchor: main@eb22bf3f79b1d23af8b2b756da16bc6a2a887c4f.

- /workout/library, /workout/programs, and /workout/exercises are shipped nested Workout routes.
- Library currently routes to Programs, Exercises, Custom Exercises (same canonical Exercises surface with custom=true), and Exercise search.
- Programs has real persisted collection/create behavior; Program rows remain display-only and no Program-detail route exists.
- Custom Exercise W3D3 is merged (#497) and its archive reconciliation is merged (#498).
- Program/Routine domain and repository boundaries exist, but broad W4 builder/detail capability is not shipped.
- Canonical Workout architecture rejects standalone Quick Start/Start Empty Workout: session start uses a selected saved Routine or scheduled PlannedWorkout context.

Tracker state observed 2026-10-05:

- TNYX-78 W1 — In Progress.
- TNYX-80 W3 — **In Progress** after PR-A tracker reconciliation. Initial audit found it incorrectly in Backlog even though W3A was shipped and W3D/TNYX-264 was actively In Progress; PR-A corrected the parent state without claiming unfinished W3B/W3C/W3E complete.
- TNYX-81 W4 — Backlog; blocked by W1/W3.
- TNYX-83 W6 — Backlog; blocked by W3/W4.
- TNYX-264 W3D — In Progress.
- TNYX-267 W6B — Backlog; blocked by W6A and W4.

## Reconciliation findings

### R1 — #475 current-runtime wording is stale

#475 predates merged W3D3 runtime. Current Library already exposes Custom Exercises through the canonical Exercises route. Tracker text must not describe the older Programs/Exercises-only runtime as current truth.

### R2 — standalone Start Empty Workout conflicts with canonical architecture

#475 still sketches a lower Start Empty Workout action. Canonical Workout docs and ownership require start from an explicitly selected saved Routine or scheduled PlannedWorkout context and prohibit standalone Quick Start. PR-A must reconcile #475 to that rule and must not invent ad-hoc Routine/session semantics.

### R3 — direct Create Routine remains gated by stable default My Program identity

The approved Library-level Create Routine entry may exist only after it resolves exactly one owning Program. Canonical docs require stable/idempotent default My Program identity independent of mutable display name. Current Program persistence/controller has no verified default-program discriminator. Do not implement name-based lookup or create-on-miss semantics.

### R4 — W4 remains the Program detail/Routine capability gate

/workout/programs exists, but individual Program rows do not open Program detail. TNYX-267 explicitly depends on TNYX-81 W4. #475 must not bypass that dependency.

### R5 — capability-gated entries stay gated

Explore, Favorites, Folders and Your Plan appear only after their owning capabilities are real. Custom Exercises is now real and should be reflected as such. No placeholders.

## Approved PR sequence

Dependency order remains:

1. PR-A — current-truth reconciliation (this task): tracker/canonical-doc reconciliation only; no Flutter/Supabase behavior.
2. PR-B — default My Program identity foundation: audit the minimum stable/idempotent identity contract; any Supabase table/column shape requires explicit owner approval.
3. PR-C — W4 Program detail foundation: Program row to Program detail with real Program-owned Routine read surface; no broad builder expansion.
4. PR-D — Program-owned Routine create/edit/composition: bounded W4 slice using canonical Program ownership.
5. PR-E — #475 Library Programs composition: render real Programs on Library and navigate individual Program rows directly once Program detail exists.
6. PR-F — Library + actions: expose only actions whose capabilities are real; direct Create Routine only after canonical My Program resolver exists.

**Owner sequencing correction — 2026-10-05:** after PR-A review/merge, pause PR-B onward. First perform a fresh audit of the already-shipped Library/Programs/Exercises UI and fix/polish the current UI in bounded tracker-backed slices. Resume the dependency sequence above only after the currently implemented UI is satisfactory.

Explore/Favorites/Folders/Your Plan remain separately capability-gated and are not pulled forward merely to complete #475.

## In scope for PR-A

- Reconcile #475 current-runtime claims with merged W3D3.
- Remove/reframe standalone Start Empty Workout from #475 target direction so it matches canonical Workout start semantics.
- Preserve Program-owned Routine ownership and default My Program prerequisite.
- Preserve W4/W6B dependency gates.
- Record tracker-backed PR sequence and durable handoff.
- Update canonical docs only where current-truth wording is actually stale.

## Out of scope

- Flutter runtime/UI changes or new routes.
- Program detail or Routine builder implementation.
- Default My Program persistence implementation.
- Supabase schema/RLS/Storage changes.
- Active Workout/WorkoutSession semantics.
- Explore, Favorites, Folders, Your Plan implementation.
- Visual polish or redesign.

## Validation

### Completed before Codex review — checkpoint `1087c7160f5275f8ac4203d2b6fad71212c168f6`

- **Parent/head scope audit: PASS.** `main@eb22bf3f79b1d23af8b2b756da16bc6a2a887c4f` → checkpoint was `3 ahead / 0 behind`, with exactly two changed documentation paths: this task brief and `.ai/tasks/README.md`.
- **Markdown connector-side hygiene scan: PASS.** Both changed Markdown files had `0` trailing-whitespace lines and `0` conflict markers.
- **Canonical/runtime/tracker cross-check: PASS for PR-A scope.** Current `LibraryPage`, `ProgramsPage`, Workout routing, `docs/screens/library.md`, `docs/screens/programs.md`, `docs/screens/workout.md`, ADR-0015, GitHub #475, and Linear TNYX-78/80/81/83/264/267 were reconciled before opening PR #499.
- **Required attribution gate: PASS** on checkpoint `1087c716...`.
- **GHAS supplemental check: infrastructure failure, not a security result.** The job failed before meaningful analysis with HTTP 402 `You have exceeded your monthly quota`; no concrete repository finding was produced.
- **Codex review on checkpoint `1087c716...`: REVIEW findings P2×2.** Both findings are handoff-consistency/documentation issues being repaired in this review pass.
- **Local `git diff --check`: NOT RUN / not claimed** because this connector-only session has no local worktree.

### Pending after this review repair

- Re-run branch ahead/behind + complete changed-file audit on the resulting head.
- Re-run connector-side Markdown hygiene scan on the resulting head.
- Verify required checks on the resulting head.
- Request/verify a fresh exact-head Codex review and confirm `0` unresolved review threads before merge.

## Active Handoff

**Repository anchor:** main@eb22bf3f79b1d23af8b2b756da16bc6a2a887c4f
**Branch:** tnyx/gh-475-pr-a-current-truth-reconciliation
**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT (docs/tracker reconciliation only)
**Review owner:** pending PR review
**Current state:** fresh audit complete; GitHub #475 body reconciled to merged W3D3/current Library runtime and canonical no-Quick-Start rule; TNYX-80 parent corrected Backlog → In Progress; TNYX-83/W6 and TNYX-267/W6B remain Backlog because their W4/W3 dependency gates are real. Owner sequencing now requires auditing/fixing the already-shipped Library/Programs/Exercises UI before PR-B onward.
**Open blockers:** none for PR-A. PR-B requires exact default-Program identity/data-shape audit and may hit Owner Approval if a Supabase table/column change is required.
**Next exact action:** complete this Codex review repair, re-run exact-head scope/check/review gates for PR #499, then stop at the merge decision. Do not start PR-B or future #475 capability implementation; after PR-A merge, next work is a fresh audit of the already-shipped UI.
