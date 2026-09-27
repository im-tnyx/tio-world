# TNYX-193 P4 — Documentation Authority Governance

**Status:** In progress
**Primary owner:** repository documentation governance
**Affected platforms:** documentation only

## Owner Approval and Scope Boundary

**Trigger:** None — documentation governance inside the already approved TNYX-193 phase plan
**Approval status:** Approved
**Approval evidence:** owner said `Go` after the P4 read-only audit
**Approved product/UI/data-shape boundaries:** no product-visible UI, runtime, or Supabase data-shape change
**Explicit non-changes:** no P4A document moves; no P5/P6 header rollout; no P7 `.ai/CURRENT.md` refresh; no runtime, Supabase, CI, lockfile, ADR-history, or product-visible changes

## Active Handoff

**Planning owner:** current P4 session
**Implementation owner:** current P4 session
**Review owner:** pending independent review
**Implementation ownership state:** Complete
**Ownership transition:** Not applicable
**Repository state last verified:** `main@52236317a57c94d7a28620c7d007e706b7945665`
**Branch:** `tnyx/tnyx-193-p4-doc-authority-governance`
**HEAD SHA:** `a681987a3faeebaf814f778da19ddf17382fa18a` before this handoff update
**Observed working-tree state:** connector/API execution only; no local working tree is available to inspect
**Observed uncommitted/dirty files:** Not applicable
**PR / tracker:** GitHub #250 / Linear TNYX-193
**Current implementation state:** bounded P4 source edits and branch validation complete
**Relevant execution surface:** `docs/README.md`, `.ai/README.md`, `.ai/workflow.md`
**Validation completed at SHA:** `e65542c14bcbdc570b51f9ccbd77668b32a526ed`
**Validation remaining:** exact PR patch scan, repository checks, exact-head independent review
**Current blocker:** none
**Open review finding IDs:** none
**Next exact action:** open the bounded P4 PR, validate its exact head, and request independent review

## 1. Discovery

### User Outcome

Tio-world should have one obvious documentation authority model before any document-location normalization or header rollout begins.

### Success Criteria

- `docs/README.md` defines authority layers and conflict resolution in one canonical place.
- All six planned document-status labels are defined in `docs/README.md`.
- `.ai/README.md` no longer restates a separate precedence list; it points to the canonical rule.
- Existing local links remain resolvable.
- No P4A/P5/P6/P7 or runtime scope leaks into P4.

### Scope

- `docs/README.md`
- `.ai/README.md`
- `.ai/workflow.md` (review-found duplicate precedence list)
- this focused task brief and task index

### Non-Goals

- document/folder moves
- repository-wide status headers
- `.ai/CURRENT.md` refresh
- runtime/Supabase/CI changes
- changing existing architecture or product direction

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `AGENTS.md`, `docs/README.md`, `.ai/README.md`, GitHub #250, Linear TNYX-193
- Existing pattern to follow: current `docs/README.md` Documentation Rules + `.ai/README.md` Priority Rule, reconciled into one canonical docs-governance rule
- Tests or validation already present: pre-implementation markdown-link sweep checked 52 references across `docs/README.md`, `.ai/README.md`, and `AGENTS.md`; 0 missing

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Canonical documentation governance lives in `docs/README.md` | Chosen | `docs/` owns canonical product/architecture docs and #250 assigns P4 there | Owner + repo governance |
| `.ai/README.md` points to canonical conflict rules instead of restating them | Chosen | avoids duplicate authority logic in an orientation layer | Owner + repo governance |
| P4 does not move documents | Chosen | moves belong to separately gated P4A | Owner |
| P4 does not add four-line headers repository-wide | Chosen | header rollout belongs to P5/P6 after P4A | Owner |

## 4. Architecture Design

### Chosen Approach

Add compact governance sections near the top of `docs/README.md` covering:
- authority layers;
- conflict-resolution order;
- six status-label definitions;
- normalization/location boundary that points future relocation work to P4A without performing it.

Replace the numbered `.ai/README.md` Priority Rule with a concise pointer to `docs/README.md`, while retaining the rule that `.ai/` is orientation/handoff only.

### Ownership and Data Flow

```text
runtime source/config/migrations -> executable truth
docs/README.md -> canonical documentation authority/status/conflict model
canonical docs / ADRs -> intended architecture and product rules
module-local docs -> implementation detail for their owned scope
.ai/ -> execution/routing/handoff pointers only
```

### Alternative Rejected

Keep duplicate priority rules in both `docs/` and `.ai/`. Rejected because they can drift independently.

### Failure and Accessibility States

Not applicable; docs-only governance.

## 5. Implementation Plan

- [x] add canonical authority layers to `docs/README.md`
- [x] add explicit conflict-resolution order to `docs/README.md`
- [x] add six canonical document-status definitions to `docs/README.md`
- [x] replace duplicate `.ai/README.md` Priority Rule with canonical pointer
- [x] replace duplicate `.ai/workflow.md` Source Of Truth Order with canonical pointer
- [x] preserve all existing documentation entry links and current architecture direction
- [x] verify exact changed paths and local-reference integrity
- [ ] request independent exact-head review

## 6. Quality Review

### Validation Run

```text
Branch validation after Codex P2 fix at `9e4fa14fd07459b233483c9efe1919a74d48c23f`:
- base main@52236317a57c94d7a28620c7d007e706b7945665
- 7 ahead / 0 behind before this handoff update
- exactly 5 expected paths after resolving Codex P2 review finding
- runtime/Supabase/CI/service files changed: 0
- all six canonical status labels present
- docs/README.md contains canonical authority + conflict sections
- .ai/README.md contains canonical pointer and no duplicate numbered Priority Rule
- .ai/workflow.md contains the canonical pointer and no duplicate numbered Source Of Truth Order
- 55 local markdown references checked, 0 missing
- trailing whitespace: 0
- conflict markers: 0
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| PRRT_kwDOTOXwB86mXsGm | P2 | Resolved | `.ai/workflow.md` still carried a competing source-of-truth precedence list, so `docs/README.md` was not yet the single canonical authority location. | `3285d226d398c86fc74138986ad4f7ed6e1d4d24` | Replaced the workflow list with a pointer to `docs/README.md` in `a681987a3faeebaf814f778da19ddf17382fa18a`; exact-head revalidation/re-review required. |

## 7. Final Handoff

### Changed Files

Expected:
- `.ai/tasks/README.md`
- `.ai/tasks/tnyx-193-p4-doc-authority-governance.md`
- `docs/README.md`
- `.ai/README.md`
- `.ai/workflow.md`

### Actual Behavior

P4 now has one canonical documentation authority/status/conflict model in `docs/README.md`; both `.ai/README.md` and `.ai/workflow.md` route to it instead of restating precedence.

### Known Limitations

P4 defines governance only. P4A performs document-location normalization; P5/P6 apply headers; P7 refreshes current execution state.

### Final Status

`REVIEW` — bounded implementation and branch validation complete; exact PR checks/review remain.
