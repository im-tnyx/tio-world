# TNYX-78 W1A0 — Workout canonical identities and terminology

**Status:** In progress
**Primary owner:** Workout architecture / docs
**Affected platforms:** Shared Dart domain architecture; Flutter phone planning only (no runtime/UI change)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner approved the bounded W1A0 docs-only slice on 2026-09-23 after reviewing the W1 readiness audit and explicitly accepted the recommended Q5/Q6/Q7 direction.
**Approved product/UI/data-shape boundaries:** Record canonical Workout identity ownership, built-in Exercise catalog identity, stale shared-scaffold cleanup direction, set terminology, and explicit deferrals. Docs/governance only.
**Explicit non-changes:** No Dart production code, JSON asset move/edit/commit, Supabase schema/data, repository implementation, or UI/presentation/calendar/routing change. Linear: task status may be reconciled when the real task state changes, per AGENTS.md (done: TNYX-78 `Backlog → In Progress → In Review`); still out of scope are Linear description, acceptance or scope rewrites, relation manipulation unrelated to verified tracker reconciliation, project status spam, and marking Done before merge/completion evidence.

## Active Handoff

**Planning owner:** current architecture agent
**Implementation owner:** current architecture agent (docs/governance only)
**Review owner:** Not assigned
**Implementation ownership state:** Handoff pending
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-23 local shell after `git fetch origin --prune`: `origin/main` = `b2e101f948b546c5a1be72df031d6e1fc913e7ac`; only open PR is #324; no other Workout/W1 branch or PR
**Branch:** `tnyx/tnyx-78-w1a0-workout-canonical-identities`
**HEAD SHA:** validated branch head `0d35927d164a923e03c4a84d96c7e48db877402a`; the brief-only W1A0-C5/C6 commit follows it (exact head on PR #324)
**Observed working-tree state:** only unrelated untracked `apps/core/assets/exercises/` exists locally; it was not edited, moved, staged, stashed or committed.
**Observed uncommitted/dirty files:** `apps/core/assets/exercises/{exercises_data.json,exercise_standard_ids.json,exercise_standards.json}` untracked owner assets; excluded from W1A0.
**PR / tracker:** PR [#324](https://github.com/im-tnyx/tio-world/pull/324) against `main` is Ready for Review (open, not Draft, mergeable; marked 2026-09-23T17:55:14Z). Linear `TNYX-78` moved `Backlog → In Progress` while Codex fixes were active, then `In Progress → In Review` after the Ready transition, with one reconciliation comment (assignee santosh, PR #324 attached, description/relations unchanged). Merge is not authorized.
**Current implementation state:** W1A0 docs decisions are complete. Review findings W1A0-R1–R5 are Resolved; Codex review findings W1A0-C1–C6 are Resolved (see section 6); W1A0-F1 (Quick Start conflict → W1A6a) and W1A0-F2 (Exercise asset location/licensing → W3) remain intentionally Deferred. No runtime/source implementation was added.
**Relevant execution surface:** `.ai/`, `docs/adr/`, Workout ownership/catalog docs only.
**Validation completed at SHA:** `0d35927d164a923e03c4a84d96c7e48db877402a` — current evidence in section 6; earlier checkpoints live in commit history and PR #324.
**Validation remaining:** reviewer feedback on the Ready PR. No Flutter CI result is claimed; none ran for this docs-only PR.
**Current blocker:** None. The non-required `github-advanced-security` failure is the external TNYX-256 unsupported-model outage, not a branch finding.
**Open review finding IDs:** None. Resolved: W1A0-R1–R5, W1A0-C1–C6. Deferred (not open): W1A0-F1, W1A0-F2.
**Next exact action:** await explicit owner merge authorization for PR #324 (then follow `docs/POST_MERGE_SYNC.md`). Do not merge, start W1A7, or rewrite the TNYX-78 description before that.

## Global UI / Design-System Guardrail

No Flutter UI work is in scope. Existing rendered UI must remain unchanged.

## 1. Discovery

### User Outcome

Create the smallest architecture decision slice needed before Workout domain code, while allowing the bundled Exercise JSON catalog to continue growing independently.

### Success Criteria

- Built-in Exercise catalog ownership and durable `ex_*` identity are explicit.
- Canonical Workout durable entities/value objects are owned by `apps/shared`; feature-specific repositories/data sources/controllers/presentation remain in `apps/features/workout`.
- Existing unused shared Workout scaffolds are marked for isolated cleanup before new canonical IDs/entities are added.
- Template sets use `SetPrescription`; actual performed sets use `PerformedSet`; `WorkoutSet` is retired from new design.
- Deferred decisions name the exact later slice that must resolve them.
- No production code, assets, Supabase, or UI changes occur; Linear changes are limited to task-status reconciliation (no description, acceptance, scope or unrelated relation rewrites).

### Scope

- ADR-0011 for canonical Workout identity/ownership rules.
- `.ai/DECISIONS.md` durable decision entries/status notes.
- `docs/MODULE_OWNERSHIP.md` minimal shared/feature ownership clarification.
- `docs/screens/exercise-search.md` catalog identity/incompleteness rules.
- ADR/task indexes.

### Non-Goals

- No W1A7 cleanup implementation.
- No W1A1 typed IDs/`ExerciseRef` implementation.
- No JSON loader/parser or asset relocation.
- No persistence/repository schema design (W1B0).
- No Quick Start, Routine revision, Program namespace, TrainingPlan/session semantics implementation.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/TEMPLATE.md`, `.ai/DECISIONS.md`, `docs/adr/README.md`, `docs/MODULE_OWNERSHIP.md`, `docs/screens/exercise-search.md`, current Linear TNYX-78, current Workout/shared structure from prior readiness audit.
- Existing pattern to follow: Nutrition keeps durable pure-Dart canonical entities/value objects in `apps/shared`, while feature repositories and feature behavior remain in `apps/features/*`.
- Tests or validation already present: W1A0 is docs-only; validation is scope/diff/link consistency rather than runtime tests.
- Tracker state at slice start: TNYX-78 was Backlog and unblocked; open PR overlap = 0.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Built-in Exercise catalog remains bundled/versioned JSON, not duplicated in Supabase | Approved | Catalog content is app-owned; only user-owned/dynamic Workout data needs persistence | Owner |
| Stable `ex_*` value is canonical built-in Exercise identity | Approved | Legacy numeric IDs/slugs are metadata/lookups and must not become identity | Owner |
| JSON completeness must not block domain architecture | Approved | Catalog is evolving; new well-formed `ex_*` IDs must be addable without redesign | Owner |
| Q5: durable Workout IDs/entities/value objects live in `apps/shared`; feature repositories/data sources/controllers/UI stay in `apps/features/workout` | Approved | Matches repository ownership rules and validated Nutrition precedent | Owner |
| Q6: unused competing shared Workout scaffolds are removed in isolated W1A7 before W1A1 | Approved | Prevents `Workout`/`TrainingSession`/`WorkoutSet` from becoming competing truth | Owner |
| Q7: template set = `SetPrescription`; actual set = `PerformedSet`; do not use `WorkoutSet` | Approved | Separates prescription from performed history and avoids ambiguous legacy name | Owner |
| Q2b curated Routine/Program namespace | Deferred to W1A3/W1A4 | Source/licensing/backend evolution is not locked yet; do not speculate in W1A1 | Owner |
| Q1 Quick Start/ad-hoc session | Deferred to W1A6a | Does not affect current docs/ID foundation; conflict is recorded | Owner |
| Q3 Saved/Following/Owned semantics | Deferred to W1A4 | Program/TrainingPlan relationship slice owns it | Owner |
| Q4 Routine revision/fork | Deferred to W1A3 | Routine composition/revision slice owns it | Owner |
| Q8 PlannedWorkout→WorkoutSession cardinality | Deferred to W1A6a | Session semantics slice owns it | Owner |
| Q9 session local date/timezone | Deferred to W1A6a | Session semantics slice owns it | Owner |
| Q10 TrainingPlan provenance | Deferred to W1A5 | TrainingPlan slice owns it | Owner |
| Q11 set measurement kinds | Deferred to W1A3 | SetPrescription contract owns it; do not invent RPE/etc. now | Owner |
| Q12 scheduled workout without TrainingPlan | Deferred to W1A5 | PlannedWorkout/TrainingPlan slice owns it | Owner |
| Newer/unknown built-in `ex_*` reference on an older/offline client (absent from its bundled catalog) | Deferred to W1B0/W3 | Later work must choose and validate a contract (minimum catalog/version, unknown-ID fallback, reference snapshot, or another approved mechanism); W1A0 selects none and keeps the no-Supabase-mirroring rule | Owner |

## 4. Architecture Design

### Chosen Approach

```text
Bundled/versioned Exercise JSON
        ↓
stable ex_* catalog identity
        ↓
apps/shared Workout identity/value-object layer
        ↓
apps/features/workout repositories/data sources/controllers/presentation
```

Built-in Exercise content stays local. User-created Exercises and user relationships may be persisted later, but built-in catalog rows are not mirrored into Supabase.

Historical WorkoutSession implementation must eventually snapshot performed data so later catalog/template edits cannot rewrite completed history.

### Ownership and Data Flow

```text
apps/shared
  → canonical Workout IDs/entities/value objects/snapshots

apps/features/workout
  → feature repository interfaces
  → catalog/user data sources
  → controllers/presentation

bundled assets
  → built-in Exercise content and standards lookup data

Supabase (later approved slices)
  → user-created/dynamic/transactional Workout data only
```

### Alternative Rejected

- Put canonical Workout entities only under `apps/features/workout/domain`: rejected because repo ownership guidance and existing durable shared-domain precedent favor `apps/shared` for cross-platform durable pure-Dart entities/value objects.
- Mirror the bundled catalog into Supabase: rejected as duplicate truth.
- Keep stale shared Workout scaffolds while adding new canonical types: rejected due to competing identities and ambiguous terminology.
- Derive identity from slug/title: rejected; shipped `ex_*` IDs are durable and independent of mutable content.

### Failure and Accessibility States

Not applicable; no UI/runtime behavior in this slice.

## 5. Implementation Plan

- [x] Reconcile fresh main, PR overlap and TNYX-78 state.
- [x] Create bounded W1A0 branch.
- [x] Create this task brief before canonical docs changes.
- [x] Add ADR-0011.
- [x] Update ADR index.
- [x] Update `.ai/DECISIONS.md`.
- [x] Update `docs/MODULE_OWNERSHIP.md`.
- [x] Update `docs/screens/exercise-search.md`.
- [x] Add task to `.ai/tasks/README.md`.
- [x] Run docs/scope validation.
- [x] Refresh handoff with final branch HEAD and review state.

## 6. Quality Review

### Validation Run

Current evidence at branch head `0d35927d164a923e03c4a84d96c7e48db877402a` (the brief-only W1A0-C5/C6 commit that follows re-runs the same checks; its exact-head results are on PR #324):

```text
- origin/main: b2e101f948b546c5a1be72df031d6e1fc913e7ac (ancestor of HEAD); ahead / behind: 17 / 0
- changed files: 8, all under .ai/** or docs/**; no apps/**, supabase/**, pubspec, Exercise JSON, UI, router, calendar or migration diff
- git diff --check origin/main...HEAD: PASS
- bash scripts/check_commit_attribution.sh origin/main HEAD: PASS
- relative Markdown links in the 8 changed files: 72 checked, 0 missing
- D-010 row byte-identical to origin/main
- GitHub checks: Commit attribution guard = SUCCESS (only required check on main); Attribution guard runner = SUCCESS;
  github-advanced-security = FAILURE (non-required; CAPIError 400 unsupported model before any analysis; external outage tracked in TNYX-256)
- untracked owner assets apps/core/assets/exercises/ untouched
```

Earlier intermediate checkpoints (older heads, ahead counts and PR states) are intentionally not repeated here; they remain auditable in the branch commit history and in [PR #324](https://github.com/im-tnyx/tio-world/pull/324) (checks, review threads and body).

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| W1A0-F1 | Medium | Deferred | D-010 still forbids standalone Quick Start while newer Workout trackers include ad-hoc/start-new paths | b2e101f9 | Resolve before W1A6a after explicit Q1 decision |
| W1A0-F2 | Low | Deferred | Exercise asset location/licensing remains unresolved; local audit found untracked assets under apps/core | b2e101f9 | Resolve in W3 catalog-loader/asset slice; do not touch assets in W1A0 |
| W1A0-R1 | Blocking | Resolved | `git diff --check` failed on ADR-0011 metadata trailing whitespace | 6e097f6f | `35fd7d9f` uses the repository ADR list-metadata convention |
| W1A0-R2 | Medium | Resolved | Generic `apps/shared` ownership row dropped `repository contracts`, contradicting repo-wide docs and runtime `AppPreferencesRepository` | 6e097f6f | `3f033faa` restores the generic wording; the Workout-specific split section is unchanged |
| W1A0-R3 | Low | Resolved | ADR-0011 deferral list omitted Q11 set measurement kinds | 6e097f6f | `35fd7d9f` records the W1A3 deferral without choosing measurements |
| W1A0-R4 | Low | Resolved | Handoff metadata was stale (HEAD/ahead count/validation) | 6e097f6f | `3ab78230` refreshed the handoff with local validation evidence |
| W1A0-R5 | Low | Resolved | `docs/screens/workout.md` "Data And State Boundaries" still says Workout entities stay "in the Workout feature or `apps/shared` when they are truly cross-feature", which is weaker than ADR-0011's unconditional `apps/shared` ownership of durable Workout IDs/entities/snapshots | 3ab78230 | `f5d6fca3` aligns that one bullet with ADR-0011 and links ADR-0011 and Module ownership; Quick Start/flow wording unchanged |
| W1A0-C1 | Low | Resolved | Codex: Active Handoff summarised findings as "F1–F4 resolved / F5 deferred", which did not match this table's IDs | d24a8221 | `dd00550d` uses the real IDs: R1–R5 and C1–C4 Resolved; F1/F2 Deferred |
| W1A0-C2 | Medium | Resolved | Codex: W1A0 rewrote D-010 in place, contrary to the `.ai/DECISIONS.md` maintenance rule to retain old decisions and supersede them with a new entry | d24a8221 | `7b727664` restores the D-010 row byte-identical to `origin/main`; D-019 records the Q1 conflict separately, decides nothing, and requires the superseding lifecycle if Q1 later changes D-010 |
| W1A0-C3 | Medium | Resolved | Codex: no stated contract for older/offline clients that receive a reference to a built-in `ex_*` absent from their bundled catalog | d24a8221 | `7b727664` adds an explicit ADR-0011 deferral to W1B0/W3; no mechanism, schema field or Supabase mirroring is chosen |
| W1A0-C4 | Medium | Resolved | Codex: TNYX-78 still `Backlog` while W1A0 work and PR #324 are active | d24a8221 | TNYX-78 moved `Backlog → In Progress` on 2026-09-23, then `In Review` after PR #324 became Ready for Review |
| W1A0-C5 | Medium | Resolved | Codex: section 6 had become a transcript of every intermediate SHA/ahead-count/PR-state checkpoint, contrary to the compact `.ai/tasks` rule | 0d35927d | The W1A0-C5/C6 brief commit keeps only current exact-head evidence plus this table; earlier checkpoints are referenced via commit history and PR #324 |
| W1A0-C6 | Low | Resolved | Codex: scope boundary and success criteria said "no Linear mutation" although TNYX-78 status was reconciled `Backlog → In Progress → In Review` | 0d35927d | The W1A0-C5/C6 brief commit allows task-status reconciliation per AGENTS.md and keeps description/acceptance/scope/unrelated-relation rewrites, project status spam and premature Done out of scope |

## 7. Final Handoff

### Changed Files

- `.ai/DECISIONS.md`
- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-78-w1a0-workout-canonical-identities.md`
- `docs/MODULE_OWNERSHIP.md`
- `docs/adr/0011-workout-canonical-identities-and-exercise-catalog.md`
- `docs/adr/README.md`
- `docs/screens/exercise-search.md`
- `docs/screens/workout.md` (W1A0-R5 ownership alignment only)

### Actual Behavior

No runtime behavior changes. W1A0 records the approved catalog identity, shared/feature ownership split, W1A7 cleanup direction, set terminology, and explicit later-slice deferrals.

### Known Limitations

- Q2b, Q1, Q3, Q4, Q8-Q12 intentionally remain deferred to their owning slices.
- Exercise JSON catalog is still evolving and intentionally not part of this branch.
- Asset location/licensing is not resolved by W1A0.
- Older/offline client compatibility with newer/unknown built-in `ex_*` references is deferred to W1B0/W3 (ADR-0011).

### Final Status

`REVIEW`
