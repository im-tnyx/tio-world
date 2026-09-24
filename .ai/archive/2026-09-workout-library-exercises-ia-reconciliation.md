# Workout Library / Exercises / Explore IA reconciliation

**Status:** Validated
**Completion date:** 2026-09-24
**Primary owner:** Workout planning (`docs/screens/*`, `.ai/DECISIONS.md`, Linear roadmap)
**Affected platforms:** Phone Workout planning only; no runtime/UI change

## Owner Approval and Scope Boundary

**Trigger:** None for runtime. Owner-approved product IA reconciliation (planning/tracker/docs only).
**Approval status:** Approved
**Approval evidence:** Owner approved the Library/Exercises/Explore navigation contract and authorized roadmap/IA reconciliation on 2026-09-24 after the read-only audit (`READY_FOR_RECONCILIATION`).
**Approved product/UI/data-shape boundaries:** Planning/tracker/docs reconciliation of the owner-approved IA below.
**Explicit non-changes:** no runtime code, routes, router, Flutter UI, bottom navigation, Supabase, Explore, W1A2/W3A/W6A implementation; owner assets `apps/core/assets/exercises/` untouched; ADR-0011 unchanged.

### Owner-approved IA

- Library is one canonical Workout-owned route/screen. Approved initial target (planned, not implemented): `Workout → Workout Home → Library entry → Library`. It is not a bottom-nav destination now.
- A future configurable 3–6 bottom navigation (TNYX-131) may expose Library; it must open the same route/state, and the Workout Home → Library path remains when Library is not selected.
- Workout Home offers independent Library (and later Explore) entries; the earlier Workout-local `[ Explore ] [ Library ]` content tabs are superseded.
- Library root: Programs, Routines, Plans / Training Plans, Exercises. Sections are capability-gated; no placeholders. Library owns no Program/Routine/TrainingPlan/Exercise truth.
- `Library → Exercises` opens a dedicated Exercises screen (W3A catalog, search, filters; W3B detail; later Favorites, Custom, Folders). Library does not render the Exercise catalog/list.
- Exercises first, Explore later.

## Active Handoff

**Planning owner:** current planning agent
**Implementation owner:** current planning agent (docs/governance only)
**Review owner:** Not assigned
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** 2026-09-24 after `git fetch origin --prune`
**Branch:** `tnyx/workout-library-exercises-ia-reconciliation` (merged via squash in PR #331; no Linear key)
**HEAD SHA:** merged PR head `6bda1e77a7626d8b50dfa291ae52e5cc7896820b`; squash merge commit on `main` `65353fec3875c57e05db51d90ab2eda8aa1a6b0c`
**Observed working-tree state:** clean except untracked owner assets `apps/core/assets/exercises/`
**Observed uncommitted/dirty files:** none besides the owner assets
**PR / tracker:** PR #331 merged via squash; Linear reconciliation remains as recorded below and was not changed by this archive handoff
**Current implementation state:** Validated. Planning/docs reconciliation is on `main`; durable contract exists in D-020 and canonical screen docs; no runtime work remains in this task.
**Relevant execution surface:** `docs/screens/{library,workout,exercise-search,routine-library,README}.md`, `docs/{ROADMAP,MVP_ACCEPTANCE}.md`, `.ai/DECISIONS.md`, this brief, `.ai/tasks/README.md`
**Validation completed at SHA:** content `0653deaa53eb496d3ad455e0d53adecae56c04a9` (section 6); the following evidence-only commit changes this brief alone and is revalidated at the live PR head
**Validation remaining:** None for this task. `github-advanced-security` failed before producing code-scanning analysis because of the known TNYX-256 external unsupported-model outage; this is not a security pass.
**Current blocker:** None
**Open review finding IDs:** None (R1–R6 resolved, section 6)
**Next exact action:** None for this task; next technical gate is a fresh TNYX-260 / W1A2 implementation-readiness audit.

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
- [x] 4. Validate; push; exact-head review gate; owner-authorized PR #331 squash merge.

## 6. Quality Review

### Validation Run

At content SHA `0653deaa53eb496d3ad455e0d53adecae56c04a9` (earlier runs at `43cccda1`, `7d76eaa5` and `816a25bb` are historical):

```text
git diff --check origin/main...HEAD                          PASS
bash scripts/check_commit_attribution.sh origin/main HEAD    PASS
relative Markdown links in all changed/new docs (14 files)   PASS
stale-term audit (Current:, current access, Library filter/scroll, nested Exercise Search,
  WorkoutContentTab, [ Explore ] [ Library ], WorkoutSet, Routine Library):
  no normative occurrence left; remaining hits are ADR-0011/D-019 retirements, this brief's
  superseded notes, D-010/D-014 rows that D-020 clarifies, and start-workflow launcher lines
  in MODULE_OWNERSHIP/UX_UI_SYSTEM that mean the Routines capability
Flutter tests: not run (docs-only)
```

### Final PR Evidence

```text
PR #331 state                                             MERGED
PR head                                                   6bda1e77a7626d8b50dfa291ae52e5cc7896820b
merge commit                                              65353fec3875c57e05db51d90ab2eda8aa1a6b0c
merge method                                              squash
Commit attribution guard                                  SUCCESS
Attribution guard runner                                  SUCCESS
Codex exact-head review (6bda1e77)                        clean
unresolved review threads                                 0
github-advanced-security                                  FAILURE — known TNYX-256 external unsupported-model outage;
                                                           no code-scanning analysis was produced; not a security pass
```

### Review Findings and Resolution

Codex review of `43cccda1` on PR #331 (5 × P2), fixed in `47173351` and `7d76eaa5`; re-review of `816a25bb` (1 × P2), fixed in `0653deaa`.

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| R1 | P2 | Resolved | ROADMAP/MVP_ACCEPTANCE still describe only Routine Library and nested Exercise Search | `43cccda1` | Phase 3 and Workout MVP now list Library, dedicated Exercises (W3A list/search/filters, W3B detail) and builder picker |
| R2 | P2 | Resolved | `library.md` labels an unimplemented path `Current` | `43cccda1` | `Initial target` plus "not at runtime yet"; D-020, brief and PR body use planned wording |
| R3 | P2 | Resolved | Routines return-state named as Library filter/scroll | `43cccda1` | Routines list search/filter/scroll state; Routines browse/list state |
| R4 | P2 | Resolved | `Validation completed at SHA` not an exact SHA | `43cccda1` | Exact content SHA recorded above |
| R5 | P2 | Resolved | Exercise detail not gated to W3B | `43cccda1` | `exercise-search.md` Incremental Delivery; workout.md, ROADMAP, MVP and D-020 aligned |
| R6 | P2 | Resolved | W3A Exercises screen unreachable until W6A adds the Library entry | `816a25bb` | Docs state W3A is the capability foundation (route/screen, no user-facing entry, no interim entry without owner approval) and W6A delivers `Workout Home → Library → Exercises`; matches existing TNYX-261/TNYX-266 scope, no Linear change. Folding a Library entry into W3A would be an owner scope decision |

## 7. Final Handoff

### Changed Files

- new `docs/screens/library.md`; `docs/screens/{exercise-search,routine-library,workout,README,home}.md`
- `docs/MODULE_OWNERSHIP.md`, `docs/UX_UI_SYSTEM.md`, `.ai/architecture-summary.md` (Routine Library → Workout Library in promotion lines only)
- `docs/ROADMAP.md` Phase 3 Workout items and `docs/MVP_ACCEPTANCE.md` Workout MVP (review fix R1)
- `.ai/DECISIONS.md` (new D-020); this brief and `.ai/tasks/README.md`
- unchanged: ADR-0005, ADR-0011, D-014, runtime, router, Supabase, owner assets

### Final Scope

Planning/docs only: no runtime, Flutter UI, router, Supabase, Exercise asset, W1A2 implementation, or W3A implementation change.

### Final Status

`PASS` — planning/docs reconciliation validated and squash-merged via PR #331 (`65353fec`); archived 2026-09-24. Next technical gate is a fresh TNYX-260 / W1A2 implementation-readiness audit.
