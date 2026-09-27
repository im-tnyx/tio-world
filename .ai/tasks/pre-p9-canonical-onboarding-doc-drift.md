# Pre-P9 — Canonical Onboarding Documentation Drift Reconciliation

**Status:** In progress
**Primary owner:** repository documentation governance + onboarding
**Affected platforms:** Documentation only

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Owner authorized continuation with “Next go” after the read-only #250 contradiction audit identified stale canonical onboarding wording.
**Approved product/UI/data-shape boundaries:** Documentation-only reconciliation to current merged onboarding runtime and accepted Product Onboarding state.
**Explicit non-changes:** No runtime/UI/routes/state, no Supabase schema/RLS/migrations/functions, no P9 routing-map decision, no #250 acceptance checkbox mutation in this implementation PR.

## Active Handoff

**Planning owner:** TNYX-193 / GitHub #250
**Implementation owner:** current agent
**Review owner:** exact-head manual review + repository checks
**Implementation ownership state:** Active
**Repository state last verified:** `main@9c3c18a360fca4a79337b86a83be3d9b6ff5edf3`
**Branch:** `tnyx/pre-p9-canonical-onboarding-doc-drift`
**HEAD SHA:** branch created from exact verified main
**Observed working-tree state:** Connector-backed branch; no local worktree claim.
**Observed uncommitted/dirty files:** Not applicable.
**PR / tracker:** GitHub #250 / Linear TNYX-193
**Current implementation state:** Reconciling three canonical onboarding docs whose current-state wording predates merged O1–O11 runtime.
**Relevant execution surface:** docs only
**Validation completed at SHA:** Audit baseline `9c3c18a360fca4a79337b86a83be3d9b6ff5edf3`
**Validation remaining:** PR exact-head review/checks.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Apply the three bounded doc corrections, validate, then open a docs-only PR.

## 1. Discovery

### User Outcome
Make canonical onboarding documentation truthful to current merged runtime before #250’s broad no-contradiction acceptance criterion is reconsidered.

### Success Criteria
- MVP acceptance no longer claims mode-conditioned owner steps are unimplemented.
- Onboarding architecture no longer claims Nutrition/Targets compatibility blocks completion.
- Onboarding screen doc no longer marks the frozen O1–O11 flow PARTIAL or NutritionTarget as an active compatibility blocker.
- Statements remain bounded to source/tracker evidence and do not imply every later feature/release refinement is complete.

### Scope
- `docs/planning/MVP_ACCEPTANCE.md`
- `docs/architecture/ONBOARDING_ARCHITECTURE.md`
- `docs/screens/onboarding.md`
- this task brief

### Non-Goals
No source behavior, UI, Supabase, schema, P9, or tracker acceptance mutation.

## 2. Codebase Exploration

### Verified Evidence
- PR #50 is merged/closed on current history; Product Onboarding #40 and schema cleanup #54 are closed/frozen.
- Current source has mode-specific `BuildOnboardingFlowUseCase` behavior and integrated acceptance tests.
- `OnboardingSectionRenderer` routes real Health Connections and Review sections.
- `NutritionTargetScreen` is a real active target screen and is exercised by current tests.
- Supabase-backed completion/owner persistence and completed-session readback tests exist on current main.
- `OnboardingCompatibilitySection` remains source for inactive/historical identities; its existence is not proof that those identities are active flow blockers.

## 3. Clarification
No product decision required; this is factual documentation drift correction.

## 4. Architecture Design
No architecture change. Preserve existing ownership and current runtime truth.

## 5. Implementation Plan
- [x] Correct stale MVP acceptance wording.
- [x] Correct stale onboarding architecture blocker wording.
- [x] Correct stale onboarding screen status/NutritionTarget wording.
- [x] Validate exact branch scope and source-backed statements.
- [ ] Exact-head review and CI gate.

## 6. Quality Review

### Validation Run
Repository API validation: 4 ahead / 0 behind from `main@9c3c18a360fca4a79337b86a83be3d9b6ff5edf3`; exactly 4 changed paths; targeted stale blocker/status phrases absent; replacement claims cross-checked against current flow/renderer/target/completion source and merged #50 plus closed #40/#54 evidence.

### Review Findings and Resolution
None yet.

## 7. Final Handoff

### Changed Files
`docs/planning/MVP_ACCEPTANCE.md`, `docs/architecture/ONBOARDING_ARCHITECTURE.md`, `docs/screens/onboarding.md`, and this task brief.

### Actual Behavior
Documentation only; runtime unchanged.

### Known Limitations
This slice does not prove every canonical document repo-wide contradiction-free; it removes the concrete onboarding drift found by the current audit.

### Final Status
`REVIEW`
