# TNYX-193 P6 — AI Governance Header Rollout

**Status:** In progress
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
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main@44b92d6690f35bc1741460268065ee38dc8a5502`; GitHub #250 open; Linear TNYX-193 `In Progress`; P6 explicitly assigned 10 stable files and P7 assigned the two dynamic current-state snapshots.
**Branch:** `tnyx/tnyx-193-p6-ai-governance-headers`
**HEAD SHA:** task-brief checkpoint to be recorded after commit
**Observed working-tree state:** Connector/API execution only; no local worktree claim.
**Observed uncommitted/dirty files:** Not applicable through connector/API.
**PR / tracker:** GitHub #250 / Linear TNYX-193
**Current implementation state:** planning + source audit complete; implementation has not yet changed the 10 P6 rule/orientation files.
**Relevant execution surface:** `.ai/DECISIONS.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/README.md`, `.ai/architecture-summary.md`, `.ai/coding-rules.md`, `.ai/ownership-rules.md`, `.ai/project-context.md`, `.ai/supabase-rules.md`, `.ai/ui-rules.md`, `.ai/workflow.md`, this task brief, and `.ai/tasks/README.md`.
**Validation completed at SHA:** read-only audit on `44b92d6690f35bc1741460268065ee38dc8a5502`; 12 top-level `.ai/*.md` files exist, none has all four governance fields; P6/P7 boundary reconciled in GitHub #250 and Linear TNYX-193.
**Validation remaining:** apply bounded P6 edits; verify 10/10 headers, canonical label vocabulary, no P7 file diff, no stale protected-backend paths in P6 scope, source-backed Supabase/current-owner wording, local Markdown references, exact changed-file scope and docs patch hygiene.
**Current blocker:** none
**Open review finding IDs:** P6-AUDIT-01 through P6-AUDIT-06 below
**Next exact action:** implement the 10-file P6 governance/header + bounded factual-drift slice, then validate exact head and open a docs-only PR.

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

- [ ] add 10/10 four-line governance headers;
- [ ] reconcile protected-backend namespace/current Supabase wording in architecture/project context;
- [ ] reconcile current schema and legacy adapter preservation wording in Supabase rules;
- [ ] reconcile decision-log facts that are contradicted by current App Mode/onboarding/Supabase runtime;
- [ ] correct Default Glass Size ownership in ownership rules;
- [ ] run exact scope/reference/patch-hygiene validation;
- [ ] open docs-only PR and obtain available exact-head review.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| P6-AUDIT-01 | P2 | Open | `architecture-summary.md` says Supabase is planned and future work belongs under `backend/*`. | 44b92d6690f35bc1741460268065ee38dc8a5502 | Canonical architecture says Supabase active; future protected path is `services/api`. |
| P6-AUDIT-02 | P2 | Open | `project-context.md` calls Supabase future and names `backend/api`, `backend/ai-coach`, `backend/jobs`. | 44b92d6690f35bc1741460268065ee38dc8a5502 | Canonical architecture/current checkout contradicts this. |
| P6-AUDIT-03 | P2 | Open | `supabase-rules.md` lists legacy three-table schema and removed Remote Workout/Targets symbols. | 44b92d6690f35bc1741460268065ee38dc8a5502 | P4B schema inventory + source search. |
| P6-AUDIT-04 | P2 | Open | `DECISIONS.md` contains current-state wording inconsistent with active Supabase/App Mode/onboarding persistence. | 44b92d6690f35bc1741460268065ee38dc8a5502 | Current canonical docs/runtime. |
| P6-AUDIT-05 | P2 | Open | `ownership-rules.md` assigns Glass Size to Nutrition despite accepted Settings-owned ADR-0009. | 44b92d6690f35bc1741460268065ee38dc8a5502 | ADR-0009 + Settings canonical screen doc. |
| P6-AUDIT-06 | Boundary | Resolved | Exact P6/P7 file ownership was undefined. | 44b92d6690f35bc1741460268065ee38dc8a5502 | #250/TNYX-193 now lock P6=10 stable files, P7=2 dynamic snapshots. |

## 7. Final Handoff

### Changed Files

Not final yet.

### Actual Behavior

Documentation-only; no runtime behavior change.

### Known Limitations

P7 remains separately gated and must reconstruct `.ai/CURRENT.md` plus `.ai/IMPLEMENTATION_STATUS.md`.

### Final Status

`PARTIAL`
