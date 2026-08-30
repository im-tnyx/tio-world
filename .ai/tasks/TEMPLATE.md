# Feature Task Template

**Status:** Ready | In progress | Needs decision | Blocked | Validated | Superseded
**Primary owner:**
**Affected platforms:**

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice | Unapproved product-visible UI/UX change | Supabase table/column shape change | None
**Approval status:** Not required | `AWAITING OWNER APPROVAL` | Approved
**Approval evidence:**
**Approved product/UI/data-shape boundaries:**
**Explicit non-changes:**

`New task` means a new independently scoped product task, feature, or product slice. Normal implementation subtasks required inside an already approved scope—including tests, scoped bug fixes, repository/provider/controller wiring, internal refactors, validation or CI fixes, review findings, documentation, and internal RPC/RLS/security/correctness work—are not new-task approval triggers by themselves.

When a trigger applies, record the proposed boundary and owner approval before implementation. Approval of visible UI/UX or an exact Supabase table/column shape as part of the task scope covers its implementation details without repeated approval. If implementation discovers a new trigger outside the approved boundaries, record it as a follow-up and return to the Owner Approval Gate in `.ai/FEATURE_DEVELOPMENT.md`.

## Active Handoff

This is a compact recovery checkpoint, not a live activity log. Refresh it only at meaningful durable checkpoints, when implementation pauses, when ownership changes, or when recovery is needed. Use `Not applicable` where no handoff state exists.

**Planning owner:**
**Implementation owner:**
**Review owner:**
**Implementation ownership state:** Not started | Active | Handoff pending | Paused | Blocked | Complete
**Ownership transition:** Previous Implementation Owner → Receiving Implementation Owner | Not applicable
**Repository state last verified:**
**Branch:**
**HEAD SHA:**
**Observed working-tree state:**
**Observed uncommitted/dirty files:**
**PR / tracker:**
**Current implementation state:**
**Relevant execution surface:**
**Validation completed at SHA:**
**Validation remaining:**
**Current blocker:**
**Open review finding IDs:**
**Next exact action:**

## Global UI / Design-System Guardrail

For any Flutter UI work, read `.ai/tasks/design-system-token-consolidation.md` and `apps/core/lib/src/theme/README.md` before changing visual implementation. Inspect the existing reusable core UI/component surface and prefer the public `package:tio_core/core.dart` boundary before rebuilding an equivalent pattern locally. When working under `apps/features/*`, also follow `apps/features/AGENTS.md`.

Mandatory rules:

- fixed product-visible visual values follow the centralized `apps/core` design-system ownership model;
- existing reusable core components are preferred before raw local reconstruction of equivalent shared UI;
- a new reusable core component/contract requires genuine reuse evidence; one-off feature/workflow composition stays with its owning feature while consuming governed core values;
- feature packages must not create parallel design-token catalogs such as `WelcomeTokens`, `AuthTokens`, `HomeTokens`, or equivalent feature color/layout/theme bags;
- component/feature/screen/widget code must not introduce independent raw fixed visual values when they belong to governed core ownership;
- design-system refactors are pixel-preserving by default;
- **no screen design, layout, color appearance, typography appearance, spacing, radius, icon sizing, component geometry, motion choreography, or other visible UI contract may change unless it is included in the owner-approved task scope or receives later explicit owner/design approval**;
- approved visible UI/UX scope does not require repeated confirmation for each implementation detail, while pixel- and behavior-preserving internal work requires no approval;
- if implementation work exposes an unapproved UI/design improvement, record it as a follow-up and preserve current rendering until approved.

These rules do not prohibit business/domain values, runtime-derived measurements, indexes, validation limits, dates, calculations, or other genuine non-design literals.

## 1. Discovery

### User Outcome

### Success Criteria

### Scope

### Non-Goals

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
- Existing pattern to follow:
- Tests or validation already present:

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| | | | |

## 4. Architecture Design

### Chosen Approach

### Ownership and Data Flow

```text
UI -> Controller/Notifier -> Use case -> Repository -> Data source
```

### Alternative Rejected

### Failure and Accessibility States

## 5. Implementation Plan

- [ ]

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

Use `Open`, `Resolved`, or `Deferred`. A Review owner records findings but does not modify source unless Implementation ownership is transferred.

## 7. Final Handoff

### Changed Files

### Actual Behavior

### Known Limitations

### Final Status

`PASS` | `REVIEW` | `PARTIAL` | `BLOCKED`
