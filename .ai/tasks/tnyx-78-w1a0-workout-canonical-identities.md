# TNYX-78 W1A0 — Workout canonical identities and terminology

**Status:** In progress
**Primary owner:** Workout architecture / docs
**Affected platforms:** Shared Dart domain architecture; Flutter phone planning only (no runtime/UI change)

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner approved the bounded W1A0 docs-only slice on 2026-09-23 after reviewing the W1 readiness audit and explicitly accepted the recommended Q5/Q6/Q7 direction.
**Approved product/UI/data-shape boundaries:** Record canonical Workout identity ownership, built-in Exercise catalog identity, stale shared-scaffold cleanup direction, set terminology, and explicit deferrals. Docs/governance only.
**Explicit non-changes:** No Dart production code, JSON asset move/edit/commit, Supabase schema/data, repository implementation, UI/presentation/calendar/routing change, or Linear mutation in this slice.

## Active Handoff

**Planning owner:** current architecture agent
**Implementation owner:** current architecture agent (docs/governance only)
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** remote `main` = `b2e101f948b546c5a1be72df031d6e1fc913e7ac`; open PRs = 0
**Branch:** `tnyx/tnyx-78-w1a0-workout-canonical-identities`
**HEAD SHA:** starts from `b2e101f948b546c5a1be72df031d6e1fc913e7ac`; update after docs commits
**Observed working-tree state:** GitHub connector sees remote state only. Local audit reported unrelated untracked `apps/core/assets/exercises/`; preserve and do not stage/touch it.
**Observed uncommitted/dirty files:** `apps/core/assets/exercises/{exercises_data.json,exercise_standard_ids.json,exercise_standards.json}` reported untracked by local audit; excluded from W1A0.
**PR / tracker:** Linear `TNYX-78` Backlog, unblocked by completed TNYX-77; no PR yet.
**Current implementation state:** task brief created first; docs decisions pending in this branch.
**Relevant execution surface:** `.ai/`, `docs/adr/`, Workout ownership/catalog docs only.
**Validation completed at SHA:** Not run yet.
**Validation remaining:** docs diff review, `git diff --check` equivalent review, scope/path audit, fresh branch/main comparison.
**Current blocker:** None for W1A0.
**Open review finding IDs:** None.
**Next exact action:** add ADR-0011 and minimal canonical-doc updates for approved decisions and deferrals.

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
- No production code, assets, Supabase, UI, or Linear state changes occur.

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
- Tracker state: TNYX-78 is Backlog and unblocked; open PR overlap = 0.

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
- [ ] Add ADR-0011.
- [ ] Update ADR index.
- [ ] Update `.ai/DECISIONS.md`.
- [ ] Update `docs/MODULE_OWNERSHIP.md`.
- [ ] Update `docs/screens/exercise-search.md`.
- [ ] Add task to `.ai/tasks/README.md`.
- [ ] Run docs/scope validation.
- [ ] Refresh handoff with final branch HEAD and review state.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| W1A0-F1 | Medium | Deferred | D-010 still forbids standalone Quick Start while newer Workout trackers include ad-hoc/start-new paths | b2e101f9 | Resolve before W1A6a after explicit Q1 decision |
| W1A0-F2 | Low | Deferred | Exercise asset location/licensing remains unresolved; local audit found untracked assets under apps/core | b2e101f9 | Resolve in W3 catalog-loader/asset slice; do not touch assets in W1A0 |

## 7. Final Handoff

### Changed Files

Task brief only so far.

### Actual Behavior

No runtime behavior changes.

### Known Limitations

- Q2b, Q1, Q3, Q4, Q8-Q12 intentionally remain deferred to their owning slices.
- Exercise JSON catalog is still evolving and intentionally not part of this branch.
- Asset location/licensing is not resolved by W1A0.

### Final Status

`REVIEW`
