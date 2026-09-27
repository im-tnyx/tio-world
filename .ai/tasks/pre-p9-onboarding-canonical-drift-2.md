# Pre-P9 — Remaining Onboarding Canonical Drift Reconciliation

**Status:** In progress
**Primary owner:** repository documentation governance + onboarding
**Affected platforms:** Documentation only

## Owner Approval and Scope Boundary

**Trigger:** None
**Approval status:** Not required
**Approval evidence:** Owner authorized “Go next” after the fresh #250 contradiction audit identified remaining stale onboarding claims.
**Approved product/UI/data-shape boundaries:** Documentation-only correction of remaining source-disproven onboarding current-state claims.
**Explicit non-changes:** No runtime/UI/routes/state, no Supabase/schema/RLS/migrations/functions, no #250 checkbox mutation, no P9 decision.

## Active Handoff

**Planning owner:** GitHub #250 / Linear TNYX-193
**Implementation owner:** current agent
**Review owner:** exact-head manual review + repository checks
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main@73a092adea5102a340d27e2d17249f7662273cda`
**Branch:** `tnyx/pre-p9-onboarding-canonical-drift-2`
**HEAD SHA:** branch created from exact verified main
**Observed working-tree state:** Connector-backed branch; no local worktree claim.
**Observed uncommitted/dirty files:** Not applicable.
**PR / tracker:** GitHub #250 / Linear TNYX-193
**Current implementation state:** Reconciling remaining onboarding canonical drift found after PR #430/#431.
**Relevant execution surface:** docs only
**Validation completed at SHA:** Audit baseline `73a092adea5102a340d27e2d17249f7662273cda`
**Validation remaining:** Exact branch scope, stale-phrase absence, source-backed wording, PR exact-head review/checks.
**Current blocker:** None.
**Open review finding IDs:** None.
**Next exact action:** Validate these two canonical doc corrections and open a docs-only PR.

## 1. Discovery

### User Outcome
Remove the remaining canonical onboarding claims contradicted by current O1–O11 runtime before #250's repo-wide contradiction criterion is reconsidered.

### Success Criteria
- Architecture no longer says active owner sections are compatibility/unimplemented blockers.
- Delivery-history language clearly distinguishes implemented checkpoints from pending work.
- Screen catalog no longer says conditional onboarding steps are merely planned.
- No unrelated implementation or acceptance bookkeeping changes.

### Scope
- `docs/architecture/ONBOARDING_ARCHITECTURE.md`
- `docs/screens/README.md`
- this task brief

### Non-Goals
No runtime, UI, Supabase, P9, or #250 acceptance mutation.

## 2. Codebase Exploration

### Verified Evidence
- Current renderer dispatches real `NutritionSection`, `TargetsSection`, Health Connections, and Review paths.
- Compatibility renderer fail-fast guards Nutrition/Targets identities rather than rendering them as active compatibility previews.
- `SupabaseOnboardingCompletionRepository` exists as the durable completion boundary.
- Integrated O3D/O4D/O5E/O6E/O7E/O9B/O10C acceptance tests exercise owner persistence, mode variants, retry convergence, and completion with durable readiness.
- GitHub Product Onboarding #40 is complete/frozen and #54 cleanup is closed.

## 3. Clarification
No product decision required.

## 4. Architecture Design
No architecture change; current source/runtime remains executable truth.

## 5. Implementation Plan
- [x] Correct remaining architecture current-runtime blocker claims.
- [x] Correct stale screen-catalog onboarding status/order wording.
- [ ] Validate exact branch scope and source-backed statements.
- [ ] Exact-head review and final gate.

## 6. Quality Review

### Validation Run
Pending branch validation.

### Review Findings and Resolution
None yet.

## 7. Final Handoff

### Changed Files
Pending validation.

### Actual Behavior
Documentation only; runtime unchanged.

### Known Limitations
This slice resolves the currently identified onboarding contradiction cluster only. A broader canonical-doc audit is still required before #250's no-contradiction criterion can be checked.

### Final Status
`REVIEW`
