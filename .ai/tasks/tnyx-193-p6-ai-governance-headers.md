# TNYX-193 P6 — AI Governance Header Rollout

**Status:** In review
**Primary owner:** repository AI governance
**Affected platforms:** documentation only

## Owner Approval and Scope Boundary

**Trigger:** None — docs-only execution inside the separately gated TNYX-193 P6 phase
**Approval status:** Approved
**Approval evidence:** Owner said `Go` after the P6/P7 boundary audit.
**Approved scope:** Add the canonical four-line governance header to exactly 10 stable top-level `.ai/` orientation/rule files and reconcile only factual drift required to make the `Last Verified` claim truthful.
**Explicit non-changes:** No `.ai/CURRENT.md` or `.ai/IMPLEMENTATION_STATUS.md` edits; no runtime/UI/routing/state changes; no Supabase schema/migration/RLS/storage/function/Auth mutation; no CI workflow or lockfile changes; no P7 or P9 implementation.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** independent exact-head review after the bounded P6 slice
**Implementation ownership state:** Handoff pending
**Ownership transition:** Not applicable
**Repository state last verified:** `main@44b92d6690f35bc1741460268065ee38dc8a5502`; GitHub #250 open; Linear TNYX-193 `In Progress`; P6 explicitly assigned 10 stable files and P7 assigned the two dynamic current-state snapshots.
**Branch:** `tnyx/tnyx-193-p6-ai-governance-headers`
**HEAD SHA:** source/docs review checkpoint `c73d832de4f65355916f7f05a70ad08d01871c27`; the final handoff-only commit will move HEAD and must be revalidated externally rather than recursively rewriting this field
**Observed working-tree state:** Connector/API execution only; no local worktree claim.
**Observed uncommitted/dirty files:** Not applicable through connector/API.
**PR / tracker:** GitHub #250 / Linear TNYX-193
**Current implementation state:** P6 implementation is complete at the source/docs checkpoint: all 10 locked stable `.ai/` files carry the four-line governance header and known contradicted architecture/data/ownership/current-state prose in P6 scope is reconciled.
**Relevant execution surface:** `.ai/DECISIONS.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/README.md`, `.ai/architecture-summary.md`, `.ai/coding-rules.md`, `.ai/ownership-rules.md`, `.ai/project-context.md`, `.ai/supabase-rules.md`, `.ai/ui-rules.md`, `.ai/workflow.md`, this task brief, and `.ai/tasks/README.md`.
**Validation completed at SHA:** source/docs checkpoint `c73d832de4f65355916f7f05a70ad08d01871c27`: 16 ahead / 0 behind from `main@44b92d6690f35bc1741460268065ee38dc8a5502`; 12 changed paths = 10 P6 stable files + this task brief + task index; 10/10 governance headers; P7 files zero diff; 36 local Markdown refs / 0 missing; patch hygiene 0 trailing whitespace / 0 conflict markers / 0 missing-final-newline markers; known stale protected-backend paths, legacy schema symbols, removed adapter names, App Mode device-local authenticated wording, and Nutrition Water/Glass ownership claims absent.
**Validation remaining:** after this handoff refresh, revalidate the resulting exact PR head, required checks, mergeability, and available review evidence externally; do not add another commit solely to embed its own SHA.
**Current blocker:** none
**Open review finding IDs:** none — P6-AUDIT-01 through P6-AUDIT-08 are resolved
**Next exact action:** open/update the docs-only P6 PR, perform exact-head review/check reconciliation, then stop at the explicit owner merge gate.

## 1. Discovery

### User Outcome

Make the stable `.ai/` execution/orientation layer trustworthy enough for agent routing without turning it into a second product-truth store.

### Success Criteria

- exactly the 10 P6-assigned stable top-level files carry all four governance fields directly below H1;
- `CURRENT.md` and `IMPLEMENTATION_STATUS.md` remain untouched for P7;
- all P6 documents use the canonical `Canonical Live Doc` status only within their narrow AI-execution/orientation truth boundaries;
- known contradicted backend/Supabase/ownership/persistence wording is reconciled before claiming `Last Verified: 2026-09-27`;
- no runtime, Supabase, CI, or product-visible behavior changes.

### Scope

- `.ai/DECISIONS.md`
- `.ai/FEATURE_DEVELOPMENT.md`
- `.ai/README.md`
- `.ai/architecture-summary.md`
- `.ai/coding-rules.md`
- `.ai/ownership-rules.md`
- `.ai/project-context.md`
- `.ai/supabase-rules.md`
- `.ai/ui-rules.md`
- `.ai/workflow.md`
- `.ai/tasks/README.md`
- this task brief

### Non-Goals

- no P7 reconstruction;
- no broad product/canonical-doc rewrite;
- no new ADR;
- no source refactor or dead-code cleanup;
- no future service scaffolding.

## 2. Codebase Exploration

### Verified Evidence

- Canonical documentation governance lives in `docs/README.md`; `.ai/` is explicitly execution/routing/handoff only.
- Canonical architecture says active `supabase/` + future-only `services/api` and conditional `services/worker`; no `backend/*` namespace.
- Verified current Supabase readable inventory contains 14 public tables and supersedes the legacy three-table wording in `.ai/supabase-rules.md`.
- `GoogleAuthUseCase` still exists only as a fail-closed legacy Firebase compatibility path; production auth is Supabase-first.
- `RemoteWorkoutPreferencesRepository`, `WorkoutPreferencesDtoMapper`, `RemoteTargetsSetupRepository`, and `TargetsSetupDtoMapper` are not current source symbols.
- Durable onboarding draft persistence exists through `SupabaseOnboardingDraftRepository` + `public.onboarding_drafts`.
- Authenticated App Mode persistence is canonical in `public.user_app_preferences`; local SharedPreferences is pre-auth staging/cache.
- Default Glass Size is a Settings-owned local convenience preference per ADR-0009, not Nutrition-owned domain truth.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| P6 covers all 12 top-level `.ai/*.md` files | Rejected | `CURRENT.md` and `IMPLEMENTATION_STATUS.md` are dynamic current-state snapshots and now belong to P7. | GitHub #250 / Linear TNYX-193 |
| P6 may mechanically stamp headers without content reconciliation | Rejected | `Last Verified` would become false where known contradicted claims remain. | docs governance |
| Stable P6 files use `Canonical Live Doc` | Resolved | They are current for their narrow AI-execution/orientation scope; Truth Boundary must state that canonical docs/source win for product/runtime truth. | docs governance |
| P6 may remove legacy/future HTTP abstractions from source | Rejected | Documentation-only scope; source cleanup requires separate audit/authorization. | scope boundary |

## 4. Architecture Design

### Chosen Approach

Apply one narrow governance header contract to the 10 stable files, plus only source-backed factual corrections needed for honest verification.

### Alternative Rejected

Treating all `.ai/` content as canonical product truth was rejected; every P6 truth boundary explicitly keeps runtime/canonical docs above this AI orientation layer.

## 5. Implementation Plan

- [x] add 10/10 four-line governance headers;
- [x] reconcile protected-backend namespace/current Supabase wording in architecture/project context;
- [x] reconcile current schema and legacy adapter preservation wording in Supabase rules;
- [x] reconcile decision-log facts that are contradicted by current App Mode/onboarding/Supabase runtime;
- [x] correct Wellness Water Goal + Default Glass Size ownership in ownership rules;
- [x] run exact scope/reference/patch-hygiene validation;
- [ ] open docs-only PR and obtain available exact-head review.

## 6. Quality Review

### Validation Run

```text
Source/docs checkpoint: c73d832de4f65355916f7f05a70ad08d01871c27
Base: main@44b92d6690f35bc1741460268065ee38dc8a5502
Ahead / behind: 16 / 0
Changed paths: 12 = 10 P6 stable .ai files + task brief + task index
Governance headers: 10 / 10
P7 files changed: 0
Local Markdown references: 36 checked / 0 missing
Patch hygiene: 0 trailing whitespace / 0 conflict markers / 0 missing-final-newline markers
Known stale P6 patterns: 0
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| P6-AUDIT-01 | P2 | Resolved | `architecture-summary.md` says Supabase is planned and future work belongs under `backend/*`. | 44b92d6690f35bc1741460268065ee38dc8a5502 | Canonical architecture says Supabase active; future protected path is `services/api`. |
| P6-AUDIT-02 | P2 | Resolved | `project-context.md` calls Supabase future and names `backend/api`, `backend/ai-coach`, `backend/jobs`. | 44b92d6690f35bc1741460268065ee38dc8a5502 | Canonical architecture/current checkout contradicts this. |
| P6-AUDIT-03 | P2 | Resolved | `supabase-rules.md` lists legacy three-table schema and removed Remote Workout/Targets symbols. | 44b92d6690f35bc1741460268065ee38dc8a5502 | P4B schema inventory + source search. |
| P6-AUDIT-04 | P2 | Resolved | `DECISIONS.md` contains current-state wording inconsistent with active Supabase/App Mode/onboarding persistence. | 44b92d6690f35bc1741460268065ee38dc8a5502 | Current canonical docs/runtime. |
| P6-AUDIT-05 | P2 | Resolved | `ownership-rules.md` assigns Glass Size to Nutrition despite accepted Settings-owned ADR-0009. | 44b92d6690f35bc1741460268065ee38dc8a5502 | ADR-0009 + Settings canonical screen doc. |
| P6-AUDIT-06 | Boundary | Resolved | Exact P6/P7 file ownership was undefined. | 44b92d6690f35bc1741460268065ee38dc8a5502 | #250/TNYX-193 now lock P6=10 stable files, P7=2 dynamic snapshots. |
| P6-AUDIT-07 | P2 | Resolved | `ownership-rules.md` assigned Water Goal to Nutrition even though canonical ownership keeps Daily Water Goal in Wellness through the Progress-owned `WellnessTargetsRepository`. | c73d832de4f65355916f7f05a70ad08d01871c27 | Removed Water Goal from Nutrition and recorded Wellness/Progress ownership plus separate Settings Default Glass Size ownership. |
| P6-AUDIT-08 | P2 | Resolved | Second review found stale current-state wording for future Apple Watch existence, authenticated App Mode persistence, speculative full-schema future scope, and preserved HTTP adapters. | c73d832de4f65355916f7f05a70ad08d01871c27 | Reconciled against canonical Architecture/Settings/Supabase docs and current source without changing runtime. |

## 7. Final Handoff

### Changed Files

- `.ai/DECISIONS.md`
- `.ai/FEATURE_DEVELOPMENT.md`
- `.ai/README.md`
- `.ai/architecture-summary.md`
- `.ai/coding-rules.md`
- `.ai/ownership-rules.md`
- `.ai/project-context.md`
- `.ai/supabase-rules.md`
- `.ai/ui-rules.md`
- `.ai/workflow.md`
- `.ai/tasks/README.md`
- this task brief

### Actual Behavior

The 10 stable top-level `.ai/` orientation/rule files now carry explicit status, verification date, owner, and narrow truth boundaries. Known P6 factual drift is reconciled so the AI layer routes to active Supabase/current ownership/future `services/api` correctly without becoming a duplicate canonical source. No runtime behavior changed.

### Known Limitations

P7 remains separately gated and must reconstruct `.ai/CURRENT.md` plus `.ai/IMPLEMENTATION_STATUS.md`. Exact PR-head checks/review still need reconciliation after this handoff-only commit.

### Final Status

`REVIEW`
