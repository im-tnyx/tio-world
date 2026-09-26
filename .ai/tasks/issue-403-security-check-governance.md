# GitHub #403 — Security-Check Governance for Supabase and Protected Server Changes

**Status:** In progress
**Primary owner:** repository AI/governance + Supabase/protected-server validation guidance
**Affected platforms:** repository-wide governance/docs only
**Tracker:** GitHub #403; related Linear TNYX-193 / TNYX-256

## Owner Approval and Scope Boundary

**Trigger classification:** No mandatory product/UI/data-shape approval trigger; this is repository-governance documentation only.
**Authorization:** Owner explicitly said `Go` after C3e source/archive lifecycle completion and fresh current-main audit.
**Approved boundary:** Add an explicit agent-readable security-check decision rule to root `AGENTS.md`, align `docs/PUSH_TEMPLATE.md`, and record this focused execution handoff.
**Explicit non-changes:** No runtime/product/UI change; no Supabase schema/RLS/Edge Function/Auth mutation; no CI workflow change; no branch-protection/ruleset change; no GHAS outage fix; no change making every GHAS/AI scanner required by default.

## Active Handoff

**Planning owner:** current #403 governance session
**Implementation owner:** current #403 governance session
**Review owner:** Codex exact-head re-review pending after P2 fix
**Implementation ownership state:** Complete
**Repository base last verified:** `main@399f4fddcabbece0588778afe41d62a77e25123c`
**Branch:** `tnyx/issue-403-security-check-governance`
**Observed working-tree state:** connector/API execution only; no local working tree is available to inspect
**Overlap audit:** no open PR overlaps `AGENTS.md`, `docs/PUSH_TEMPLATE.md`, or this task brief. One planned TNYX-193 P2 overlap exists in the stale `docs/PUSH_TEMPLATE.md` `backend/*` reference; #403 owns that single correction so P2 must not duplicate it.
**Linear mirror status:** dedicated issue creation was attempted but blocked by the workspace free-issue limit. TNYX-193 carries a visibility/overlap comment; TNYX-256 remains the separate GHAS unsupported-model outage tracker.
**Validation remaining:** exact current-head PR patch scan after this task-record update and independent exact-head re-review.
**Current blocker:** None; prior Codex P2 finding is fixed and locally/API-audited, pending exact-head re-review.
**Next exact action:** request Codex re-review on the new exact head; resolve the P2 thread only after the exact-head review confirms no remaining regression.

## 1. Discovery

### User Outcome

Future agents should know exactly when security evidence must be inspected for live Supabase/server boundaries and how to classify a failing security check without guessing from the check name alone.

### Success Criteria

- Root `AGENTS.md` explicitly lists the security-sensitive scopes that trigger security-evidence inspection.
- Applicable task-specific migration/RLS/security validation, Supabase Security Advisor review where relevant, and repository security/code-scanning checks are required for those scopes.
- Required merge-check failures are tied to actual repository branch/ruleset configuration.
- Concrete security findings are distinguished from external scanner/infrastructure failures and supplemental/non-required checks.
- Pure UI/layout/docs-only/unrelated refactors do not automatically require Supabase-specific security validation when they do not touch a security-sensitive boundary.
- `docs/PUSH_TEMPLATE.md` uses the same decision rule and canonical future protected-server path `services/api`.
- TNYX-256 remains separate and no branch protection is weakened.

## 2. Codebase Exploration

- C3e lifecycle is complete; current `main` is `399f4fddcabbece0588778afe41d62a77e25123c`.
- GitHub #403 preconditions are satisfied.
- Root `AGENTS.md` currently requires task-specific Supabase migration/RLS/security checks but has no explicit trigger/failure-classification rule.
- `docs/PUSH_TEMPLATE.md` has generic Supabase/protected-backend validation and one stale `future backend/*` architecture reference.
- TNYX-256 tracks the current GitHub-managed AI code-scanning unsupported-model outage separately.
- No open PR overlap was found for the governed files.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Add explicit security-sensitive scope gate | Chosen | Removes ambiguity for future agents |
| Make every GHAS/AI scan required | Rejected | Required status must come from actual branch/ruleset configuration |
| Treat scanner infrastructure failure as a security pass | Rejected | No meaningful analysis means neither pass nor finding |
| Change runtime/Supabase/CI workflow | Rejected | #403 is governance/docs-only |
| Correct PUSH_TEMPLATE `backend/*` to `services/api` | Chosen | Required for canonical alignment; overlap recorded against TNYX-193 P2 |

## 4. Architecture Design

`AGENTS.md` owns the concise mandatory decision rule. `docs/PUSH_TEMPLATE.md` mirrors it at push/PR validation time without creating a separate policy vocabulary.

## 5. Implementation Plan

- [x] add security-sensitive scope decision rule to `AGENTS.md`
- [x] align `docs/PUSH_TEMPLATE.md` validation/failure classification
- [x] correct stale protected-server path to `services/api`
- [x] keep runtime, Supabase, CI workflow and branch protection untouched
- [x] run exact docs-only PR patch audit
- [ ] complete independent exact-head re-review after P2 fix

## 6. Quality Review

### Validation Run

Implementation head before final handoff update: `6ab39d90ec66dc97512ae6fcd7a606f03433f055`.

Connector/API branch audit:
- base `main@399f4fddcabbece0588778afe41d62a77e25123c`
- 4 ahead / 0 behind before this handoff update
- exactly 4 owned governance paths
- runtime/source paths: 0
- trailing-whitespace scan: 0
- conflict-marker scan: 0
- `AGENTS.md` security-sensitive gate present
- `docs/PUSH_TEMPLATE.md` aligned and contains no `backend/*` protected-server reference
- GitHub PR #405 opened; exact-current-head patch scan/review still required

### Review Findings and Resolution

| ID | Severity | Status | Finding | Evidence or follow-up |
|---|---|---|---|---|
| `PR405-P2-TWO-AXIS` | P2 | Resolved | Required-vs-supplemental gate status and finding-vs-infrastructure outcome were expressed as one mutually exclusive taxonomy | Fixed in `AGENTS.md` and `docs/PUSH_TEMPLATE.md` by recording merge-gate requirement and analysis outcome/cause as independent axes; validated at `44e258193f067189af0b817517b3d14d8a3410de`: exactly 4 governance paths, 7 ahead / 0 behind, trailing whitespace 0, conflict markers 0, missing-final-newline markers 0, both required+infrastructure and supplemental+finding cases explicitly covered. Exact-head re-review still required after this task-record update. |

## 7. Final Handoff

### Changed Files

Expected:
- `.ai/tasks/issue-403-security-check-governance.md`
- `.ai/tasks/README.md`
- `AGENTS.md`
- `docs/PUSH_TEMPLATE.md`

### Actual Behavior

Future agents now receive an explicit security-sensitive scope trigger, applicable validation expectations, required-vs-supplemental verification rule, and evidence-based failure classification. Push/PR guidance mirrors that rule and uses canonical `services/api` for future protected service code.

### Known Limitations

GitHub-managed AI code-scanning availability is not fixed by this slice; TNYX-256 owns that outage.

### Final Status

`REVIEW` — bounded docs implementation and P2 fix are complete; exact-current-head re-review remains before merge.
