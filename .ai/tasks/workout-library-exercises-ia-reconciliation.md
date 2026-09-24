# Workout Library / Exercises / Explore IA reconciliation

**Status:** In progress — planning/docs only
**Primary owner:** Workout planning (`docs/screens/*`, `.ai/DECISIONS.md`, Linear roadmap)
**Affected platforms:** Phone Workout planning only; no runtime/UI change

## Owner Approval and Scope Boundary

**Trigger:** None for runtime. Owner-approved product IA reconciliation (planning/tracker/docs only).
**Approval status:** Approved
**Approval evidence:** Owner approved the Library/Exercises/Explore navigation contract and authorized roadmap/IA reconciliation on 2026-09-24 after the read-only audit (`READY_FOR_RECONCILIATION`).
**Approved product/UI/data-shape boundaries:** Planning/tracker/docs reconciliation of the owner-approved IA below.
**Explicit non-changes:** no runtime code, routes, router, Flutter UI, bottom navigation, Supabase, Explore, W1A2/W3A/W6A implementation; owner assets `apps/core/assets/exercises/` untouched; ADR-0011 unchanged.

### Owner-approved IA

- Library is one canonical Workout-owned route/screen. Current access: `Workout → Workout Home → Library entry → Library`. It is not a bottom-nav destination now.
- A future configurable 3–6 bottom navigation (TNYX-131) may expose Library; it must open the same route/state, and the Workout Home → Library path remains when Library is not selected.
- Workout Home offers independent Library (and later Explore) entries; the earlier Workout-local `[ Explore ] [ Library ]` content tabs are superseded.
- Library root: Programs, Routines, Plans / Training Plans, Exercises. Sections are capability-gated; no placeholders. Library owns no Program/Routine/TrainingPlan/Exercise truth.
- `Library → Exercises` opens a dedicated Exercises screen (catalog, search, filters, detail; later Favorites, Custom, Folders). Library does not render the Exercise catalog/list.
- Exercises first, Explore later.

## Active Handoff

**Planning owner:** current planning agent
**Implementation owner:** current planning agent (docs/governance only)
**Review owner:** Not assigned
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-24 after `git fetch origin --prune`
**Branch:** `tnyx/workout-library-exercises-ia-reconciliation` (no Linear key, so merge cannot change tracker state)
**HEAD SHA:** base `origin/main` = `55463c61160b1d7263465ac4e0e09e564a1055e2`; live branch tip is authoritative
**Observed working-tree state:** clean except untracked owner assets `apps/core/assets/exercises/`
**Observed uncommitted/dirty files:** none besides the owner assets
**PR / tracker:** Linear reconciliation applied (below); Draft docs PR opened from this branch — live PR state is authoritative
**Current implementation state:** Linear done; docs reconciled and D-020 added
**Relevant execution surface:** `docs/screens/{library,workout,exercise-search,routine-library,README}.md`, `.ai/DECISIONS.md`, this brief, `.ai/tasks/README.md`
**Validation completed at SHA:** docs commit (section 6)
**Validation remaining:** exact-head PR checks and review
**Current blocker:** None
**Open review finding IDs:** None
**Next exact action:** Exact-head Draft PR review; Ready/merge need separate owner authorization.

## Global UI / Design-System Guardrail

No Flutter UI work is in scope.

## 1. Discovery

### User Outcome

Linear and repository planning describe one consistent Workout navigation/ownership contract, so the next implementation slices (W1A2 → W3A → W6A) start from correct trackers and docs.

### Scope

Linear issue patches/creation, repository planning docs, one decision entry, this brief.

### Non-Goals

See *Explicit non-changes*. No W1A2 or later implementation.

## 2. Codebase Exploration

### Verified Evidence (at `55463c61`)

- Router has only the `/workout` shell branch; no Library, Exercises or Explore route; no `WorkoutContentTab`.
- `docs/screens/exercise-search.md` described a builder-only picker; `routine-library.md` treated Routine Library as the Library; `workout.md` listed Routine Library/Exercise Search as top-level concepts.
- ADR-0005 and D-014 already require promoted routes to reuse the canonical owner route; they call the Workout Library "Routine Library".
- Bundled Exercise assets are untracked, not registered as app assets, and reference third-party media URLs (W1A0-F2 still deferred).

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Owner-approved IA above | Approved | Owner decision | Owner |
| Split W6 into W6A/W6B/W6C (capability-gated Library) | Approved | Exercises-first without W4/W9 or placeholders | Owner |
| Add W1A2 canonical Exercise read model before W3A | Approved | No W1 slice owned the Exercise entity; avoids a feature-local competing model | Owner |
| Catalog readiness gate is an explicit W3A blocker, not a separate issue | Approved | Asset path, schema validation, licence/attribution and media policy must be decided before content ships | Owner |
| New D-020 instead of editing D-014/ADR-0005 | Locked | D-014/ADR-0005 stay valid; D-020 records the Library hub/Exercises contract and clarifies "Routine Library" terminology | Planning |

## 4. Linear Reconciliation (applied 2026-09-24)

Created (all `Backlog` except W1A2 `Todo`; none started):

```text
TNYX-260  W1A2  canonical Exercise read model     parent TNYX-78  blockedBy TNYX-259
TNYX-261  W3A   catalog + Exercises screen         parent TNYX-80  blockedBy TNYX-260
TNYX-262  W3B   Exercise detail                    parent TNYX-80  blockedBy TNYX-261
TNYX-263  W3C   Exercise Favorites                 parent TNYX-80  blockedBy TNYX-261
TNYX-264  W3D   Custom Exercises                   parent TNYX-80  blockedBy TNYX-261
TNYX-265  W3E   Exercise folders                   parent TNYX-80  blockedBy TNYX-261
TNYX-266  W6A   Library route + gated root         parent TNYX-83  blockedBy TNYX-261
TNYX-267  W6B   Library Programs & Routines        parent TNYX-83  blockedBy TNYX-81, TNYX-266
TNYX-268  W6C   Library Training Plans             parent TNYX-83  blockedBy TNYX-86, TNYX-266
```

Patched: TNYX-76 (IA, `SetPrescription`/`PerformedSet`, sequencing), TNYX-79 (tabs → entries), TNYX-80 (incremental children, Exercises owns views), TNYX-83 (hub, IA with Plans, capability gating), TNYX-86 (Library Plans note), TNYX-82 (sequencing note), TNYX-131 (route-reuse guardrail). Not changed: TNYX-78 (`In Progress`), TNYX-81. W3C–W3E W1B0 dependency recorded as text; no W1B0 issue exists yet.

## 5. Implementation Plan

- [x] 1. Fresh reconstruction; confirm no competing issues/PRs.
- [x] 2. Linear creation, relations and patches.
- [x] 3. Reconcile repository docs and add D-020.
- [ ] 4. Validate; push; Draft PR; exact-head review gate. Merge needs separate owner authorization.

## 6. Quality Review

### Validation Run

```text
git diff --check origin/main...HEAD                          PASS
bash scripts/check_commit_attribution.sh origin/main HEAD    PASS
relative Markdown links in all changed/new docs              PASS
stale-term audit (WorkoutContentTab, [ Explore ] [ Library ], WorkoutSet, Routine Library):
  no normative occurrence left; remaining hits are ADR-0011/D-019 retirements, this brief's
  superseded notes, Routines-capability links, and ADR-0005/D-014 wording that D-020 clarifies
Flutter tests: not run (docs-only)
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| — | — | — | None | — | — |

## 7. Final Handoff

### Changed Files

- new `docs/screens/library.md`; `docs/screens/{exercise-search,routine-library,workout,README,home}.md`
- `docs/MODULE_OWNERSHIP.md`, `docs/UX_UI_SYSTEM.md`, `.ai/architecture-summary.md` (Routine Library → Workout Library in promotion lines only)
- `.ai/DECISIONS.md` (new D-020); this brief and `.ai/tasks/README.md`
- unchanged: ADR-0005, ADR-0011, D-014, runtime, router, Supabase, owner assets

### Final Status

`REVIEW` — planning/docs complete; exact-head PR review and merge authorization pending. Next implementation-readiness audit after merge: W1A2 (TNYX-260).
