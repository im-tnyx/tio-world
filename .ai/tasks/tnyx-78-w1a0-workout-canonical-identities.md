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
**Implementation ownership state:** Handoff pending
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-23 local shell after `git fetch origin --prune`: `origin/main` = `b2e101f948b546c5a1be72df031d6e1fc913e7ac`; open PRs = 0; no other Workout/W1 branch or PR
**Branch:** `tnyx/tnyx-78-w1a0-workout-canonical-identities`
**HEAD SHA:** PR #324 audited at `3ab78230ecfed0b940ebbbae9a56d4a67ee60aa1`; the brief-only checkpoint commit recording this audit follows it
**Observed working-tree state:** only unrelated untracked `apps/core/assets/exercises/` exists locally; it was not edited, moved, staged, stashed or committed.
**Observed uncommitted/dirty files:** `apps/core/assets/exercises/{exercises_data.json,exercise_standard_ids.json,exercise_standards.json}` untracked owner assets; excluded from W1A0.
**PR / tracker:** Draft PR [#324](https://github.com/im-tnyx/tio-world/pull/324) against `main` (open, Draft, mergeable); Linear `TNYX-78` Backlog (not changed by this slice).
**Current implementation state:** W1A0 docs decisions are complete; review findings F1–F4 are resolved and F5 remains intentionally deferred. No runtime/source implementation was added.
**Relevant execution surface:** `.ai/`, `docs/adr/`, Workout ownership/catalog docs only.
**Validation completed at SHA:** `3ab78230ecfed0b940ebbbae9a56d4a67ee60aa1` — local docs/scope/link/attribution validation and PR #324 checkpoint recorded in section 6.
**Validation remaining:** owner/reviewer review of PR #324 and checks on the checkpoint head. No Flutter CI result is claimed; none ran for this docs-only PR at the audited head.
**Current blocker:** None for W1A0 review. Ready for Review requires explicit owner authorization.
**Open review finding IDs:** W1A0-R5 (Low, open); W1A0-F1 and W1A0-F2 remain intentionally deferred (see section 6).
**Next exact action:** owner reviews Draft PR #324 and either authorizes Ready for Review or authorizes the optional W1A0-R5 one-line docs pointer first. Do not merge, update Linear, or start W1A7 before that authorization.

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

```text
Remote GitHub compare vs main at bfa669b7137edcb77bec50e6d8115012205f96c9:
- ahead: 7
- behind: 0
- changed files: 7
- scope: .ai/** and docs/** only
- no apps/**, supabase/**, JSON asset, UI, or runtime diff
```

Local `git diff --check` was not available through the GitHub connector at that checkpoint.

```text
Local shell review at 6e097f6fe22a5c6c04a9be07ed01a937015c56d9:
- git diff --check origin/main...HEAD: FAIL (ADR-0011 metadata trailing whitespace)

Local shell validation at content head 3f033faaf0477d6daf61ccc68e5ab4511e50f32e:
- base: origin/main = b2e101f948b546c5a1be72df031d6e1fc913e7ac (ancestor of HEAD)
- ahead / behind: 10 / 0
- changed files: 7, all under .ai/** or docs/**
- git diff --check origin/main...HEAD: PASS
- relative Markdown links in the 7 changed files: 61 checked, all resolve
- bash scripts/check_commit_attribution.sh origin/main HEAD: PASS (no prohibited AI attribution)
- secrets / machine-specific paths / binary files in diff: none
- no apps/**, supabase/**, pubspec, Exercise JSON asset, UI, router, calendar or migration diff
- untracked apps/core/assets/exercises/ preserved untouched

Draft PR #324 review checkpoint at head 3ab78230ecfed0b940ebbbae9a56d4a67ee60aa1:
- PR: https://github.com/im-tnyx/tio-world/pull/324 (open, Draft, base main)
- origin/main: b2e101f948b546c5a1be72df031d6e1fc913e7ac (ancestor of HEAD)
- ahead / behind: 11 / 0; commits in PR: 11
- mergeable: MERGEABLE; merge state: CLEAN
- changed files: 7, all under .ai/** or docs/**
- git diff --check origin/main...HEAD: PASS
- bash scripts/check_commit_attribution.sh origin/main HEAD: PASS
- relative Markdown links in the 7 changed files: 61 checked, 0 missing
- checks: Commit attribution guard = SUCCESS; Attribution guard runner = SUCCESS (no other checks ran)
- reviews: 0; top-level comments: 0; inline comments: 0; review threads: 0 (0 unresolved)
- legacy apps/shared/lib/src/workout/** scaffolds still present (W1A7 not started)
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| W1A0-F1 | Medium | Deferred | D-010 still forbids standalone Quick Start while newer Workout trackers include ad-hoc/start-new paths | b2e101f9 | Resolve before W1A6a after explicit Q1 decision |
| W1A0-F2 | Low | Deferred | Exercise asset location/licensing remains unresolved; local audit found untracked assets under apps/core | b2e101f9 | Resolve in W3 catalog-loader/asset slice; do not touch assets in W1A0 |
| W1A0-R1 | Blocking | Resolved | `git diff --check` failed on ADR-0011 metadata trailing whitespace | 6e097f6f | `35fd7d9f` uses the repository ADR list-metadata convention |
| W1A0-R2 | Medium | Resolved | Generic `apps/shared` ownership row dropped `repository contracts`, contradicting repo-wide docs and runtime `AppPreferencesRepository` | 6e097f6f | `3f033faa` restores the generic wording; the Workout-specific split section is unchanged |
| W1A0-R3 | Low | Resolved | ADR-0011 deferral list omitted Q11 set measurement kinds | 6e097f6f | `35fd7d9f` records the W1A3 deferral without choosing measurements |
| W1A0-R4 | Low | Resolved | Handoff metadata was stale (HEAD/ahead count/validation) | 6e097f6f | This brief refresh records current local validation evidence |
| W1A0-R5 | Low | Open | `docs/screens/workout.md` "Data And State Boundaries" still says Workout entities stay "in the Workout feature or `apps/shared` when they are truly cross-feature", which is weaker than ADR-0011's unconditional `apps/shared` ownership of durable Workout IDs/entities/snapshots | 3ab78230 | Not a merge blocker (ADR-0011 and MODULE_OWNERSHIP are explicit). Optional owner-authorized one-line pointer to ADR-0011 in W1A0, otherwise align it in W1A1 docs |

## 7. Final Handoff

### Changed Files

- `.ai/DECISIONS.md`
- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-78-w1a0-workout-canonical-identities.md`
- `docs/MODULE_OWNERSHIP.md`
- `docs/adr/0011-workout-canonical-identities-and-exercise-catalog.md`
- `docs/adr/README.md`
- `docs/screens/exercise-search.md`

### Actual Behavior

No runtime behavior changes. W1A0 records the approved catalog identity, shared/feature ownership split, W1A7 cleanup direction, set terminology, and explicit later-slice deferrals.

### Known Limitations

- Q2b, Q1, Q3, Q4, Q8-Q12 intentionally remain deferred to their owning slices.
- Exercise JSON catalog is still evolving and intentionally not part of this branch.
- Asset location/licensing is not resolved by W1A0.

### Final Status

`REVIEW`
