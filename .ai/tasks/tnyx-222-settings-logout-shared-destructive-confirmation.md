# TNYX-222 — Settings logout shared destructive confirmation

**Status:** In progress
**Primary owner:** Implementation
**Affected platforms:** Flutter phone app / Core UI

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice
**Approval status:** Approved
**Approval evidence:** Owner explicitly said `go follow agent.md`, then `go next` for the audited logout-card slice tracked by GitHub #173 / Linear TNYX-222.
**Approved product/UI/data-shape boundaries:** Add a backwards-compatible standard/destructive confirmation intent, route Settings logout through the shared presenter with destructive intent, preserve current copy and logout behavior.
**Explicit non-changes:** No confirmation-surface/background convergence, no global card semantic change, no onboarding/Body Goal/Nutrition consumer migration, no auth/session/routing/backend/Supabase/data change.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** Pending
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main` at `17383476fdb8844b592041e730a764bd132f602c`
**Branch:** `tnyx/tnyx-222-settings-logout-shared-destructive-confirmation-intent`
**HEAD SHA:** `17383476fdb8844b592041e730a764bd132f602c` at branch creation
**Observed working-tree state:** Connector-only session; local working tree unavailable.
**Observed uncommitted/dirty files:** Not observable in connector-only session.
**PR / tracker:** GitHub #173 / Linear TNYX-222
**Current implementation state:** Ready for bounded source edits.
**Relevant execution surface:** `apps/core` confirmation card/presenter and `apps/features/settings` logout entry/tests.
**Validation completed at SHA:** Not run yet.
**Validation remaining:** Focused Core + Settings tests, analyze/proportional CI.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Implement confirmation intent contract, presenter forwarding, Settings migration and focused tests.

## Global UI / Design-System Guardrail

Read and follow `apps/core/lib/src/theme/README.md` and `apps/features/AGENTS.md`. Preserve existing confirmation surface/background geometry in this slice; the approved visible delta is only the Settings logout confirmation moving from its local dialog to the existing shared bottom-sheet family with destructive action semantics.

## 1. Discovery

### User Outcome

Settings logout uses the same governed confirmation family as other app confirmations instead of a feature-local raw `AlertDialog`, while retaining destructive action semantics.

### Success Criteria

- explicit standard/destructive confirmation intent with standard default;
- existing shared-confirmation callers stay standard unless they opt in;
- Settings logout uses destructive shared confirmation;
- cancel calls logout zero times; confirm calls logout exactly once;
- copy and logout/session/navigation behavior remain unchanged.

### Scope

Core confirmation intent + presenter forwarding; Settings logout migration; focused tests; Core public component docs.

### Non-Goals

No `surfaceRaised` convergence; no other consumer migration; no auth/backend/data work.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `apps/features/AGENTS.md`, `apps/core/lib/src/theme/README.md`, `SettingsPage`, `TioConfirmationCard`, `showTioConfirmationBottomSheet`, Settings tests.
- Existing pattern to follow: `showTioConfirmationBottomSheet` → `TioConfirmationCard` and existing `TioButton.destructive`.
- Tests or validation already present: Settings logout confirm/cancel test pins callback count and currently asserts raw `AlertDialog`.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| `standard` is default intent | Locked | Backwards-compatible for existing consumers | Owner-approved audit |
| `destructive` maps confirm to `TioButton.destructive` | Locked | Reuses governed semantic action | Owner-approved audit |
| `surfaceRaised` convergence excluded | Locked | Separate visible surface contract in #173 | Owner-approved audit |

## 4. Architecture Design

### Chosen Approach

Add `TioConfirmationIntent` to Core, make `TioConfirmationCard` render primary/destructive confirm by intent, and forward the intent through the shared bottom-sheet presenter. Settings awaits the returned result and calls its existing logout callback only when result is `true`.

### Ownership and Data Flow

```text
SettingsPage logout row
→ showTioConfirmationBottomSheet(intent: destructive)
→ TioConfirmationCard
→ TioButton.destructive / TioButton.secondary
→ bool result
→ existing onLogoutPressed callback
```

### Alternative Rejected

Keep a local `AlertDialog` or create a Settings-specific confirmation widget: rejected because Core already owns the reusable confirmation family and GitHub #173 explicitly tracks convergence.

### Failure and Accessibility States

Cancel/dismiss must not call logout. Existing shared sheet safe-area/dismiss behavior remains authoritative. No auth failure handling changes in this slice.

## 5. Implementation Plan

- [ ] Add `TioConfirmationIntent.standard/destructive` with default `standard`.
- [ ] Map Core confirm button by intent; keep cancel secondary.
- [ ] Forward intent through `showTioConfirmationBottomSheet`.
- [ ] Migrate Settings logout to await shared presenter result and call logout only on `true`.
- [ ] Update focused Core and Settings tests.
- [ ] Update Core theme/component documentation.
- [ ] Validate and review exact diff.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| — | — | — | None yet | — | — |

## 7. Final Handoff

### Changed Files

Pending implementation.

### Actual Behavior

Pending implementation.

### Known Limitations

The reusable confirmation surface continues using its current elevated-card background/shadow contract; `surfaceRaised` convergence remains separate #173 work.

### Final Status

`REVIEW`
