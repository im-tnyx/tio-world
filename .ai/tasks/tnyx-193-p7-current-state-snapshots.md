# TNYX-193 P7 — Dynamic current-state snapshots

**Status:** In progress  
**Primary owner:** repository documentation governance  
**Affected platforms:** repository-wide documentation only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice | Unapproved product-visible UI/UX change | Supabase table/column shape change | None  
**Approval status:** Approved  
**Approval evidence:** Owner authorized P7 implementation after the 2026-09-27 read-only audit.  
**Approved product/UI/data-shape boundaries:** Reconstruct `.ai/CURRENT.md` and `.ai/IMPLEMENTATION_STATUS.md` together from current main, canonical docs, source/runtime evidence, and live GitHub/Linear state; apply truthful governance headers after reconstruction.  
**Explicit non-changes:** No runtime/UI/routing/state, Supabase/schema/RLS/migration, CI, lockfile, P8/P9, or unrelated stale-task cleanup.

## Active Handoff

**Planning owner:** TNYX-193 / GitHub #250  
**Implementation owner:** active P7 agent  
**Review owner:** pending  
**Implementation ownership state:** Active  
**Ownership transition:** Not applicable  
**Repository state last verified:** `main@0248fab407201bf5b8debd71262c871a4beb98a4`  
**Branch:** `tnyx/tnyx-193-p7-current-state-snapshots`  
**HEAD SHA:** `0248fab407201bf5b8debd71262c871a4beb98a4` at branch creation  
**Observed working-tree state:** Connector/API workflow; no local worktree claim.  
**Observed uncommitted/dirty files:** Not applicable.  
**PR / tracker:** GitHub #250 / Linear TNYX-193  
**Current implementation state:** Audit complete; bounded docs reconstruction authorized.  
**Relevant execution surface:** `.ai/CURRENT.md`, `.ai/IMPLEMENTATION_STATUS.md`  
**Validation completed at SHA:** Not yet.  
**Validation remaining:** exact diff/scope, stale-pattern scan, local-link review, tracker/PR review gates.  
**Current blocker:** None.  
**Open review finding IDs:** None.  
**Next exact action:** Reconstruct both P7 snapshots without widening into stale Product Onboarding task cleanup.

## 1. Discovery

### User Outcome

Make the AI current-state layer truthful again without turning `.ai/` into a competing source of product truth.

### Success Criteria

- Both dynamic snapshots agree with current canonical docs and live trackers.
- Closed Product Onboarding/O1–O11 work is not presented as active or blocked.
- PR #50 is not presented as open/unmerged.
- Current work is summarized without duplicating the full backlog.
- Both files receive the four-line governance header only after reconstruction.
- Stale `product-onboarding-canonical-execution.md` lifecycle cleanup remains a separate follow-up.

### Scope

- `.ai/CURRENT.md`
- `.ai/IMPLEMENTATION_STATUS.md`
- this focused task brief

### Non-Goals

- Editing/archive-moving historical or stale Product Onboarding task briefs.
- Changing canonical docs, source/runtime, Supabase, CI, UI, or tracker scope.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `docs/README.md`, `docs/architecture/ARCHITECTURE.md`, `docs/architecture/ONBOARDING_ARCHITECTURE.md`, `docs/data/SUPABASE_SCHEMA.md`, P7 files and task index.
- Existing pattern to follow: P5/P6 governance headers and `docs/README.md` authority model.
- Tests or validation already present: documentation-only exact-diff and reference/stale-pattern checks; live GitHub/Linear reconciliation.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| P7 owns both dynamic snapshots together | Approved | GitHub #250 canonical phase definition | Owner / #250 |
| Do not edit stale Product Onboarding task in P7 | Approved boundary | It is outside the locked P7 two-snapshot scope | P7 audit |

## 4. Architecture Design

### Chosen Approach

Keep `.ai/` as a concise execution/routing layer. Runtime/source remains behavior truth, canonical docs own intended architecture/policy, and Linear + linked GitHub own live task/phase state.

### Ownership and Data Flow

```text
runtime/source + canonical docs + live trackers
  -> reconciled P7 snapshots
  -> AI execution orientation only
```

### Alternative Rejected

Mechanical date/header bump over stale O7/PR #50 content.

### Failure and Accessibility States

Not applicable; documentation-only.

## 5. Implementation Plan

- [x] Fresh audit current main and P7 scope.
- [ ] Reconstruct `.ai/CURRENT.md`.
- [ ] Reconstruct `.ai/IMPLEMENTATION_STATUS.md`.
- [ ] Validate exact scope and stale claims.
- [ ] Open focused docs-only PR and run review gates.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| P7-F1 | Medium | Deferred | Product Onboarding canonical execution task/index remains materially stale but is outside P7 scope. | 0248fab407201bf5b8debd71262c871a4beb98a4 | Separate bounded lifecycle audit/archive follow-up. |

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Documentation-only; no runtime behavior change.

### Known Limitations

P7 does not repair unrelated stale task briefs.

### Final Status

`PARTIAL`
