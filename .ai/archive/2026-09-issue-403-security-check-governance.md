# GitHub #403 — Security-Check Governance for Supabase and Protected Server Changes

**Status:** Validated
**Primary owner:** repository AI/governance + Supabase/protected-server validation guidance
**Affected platforms:** repository-wide governance/docs only
**Completed:** 2026-09-26
**Tracker:** GitHub #403; related Linear TNYX-193 / TNYX-256

## Owner Approval and Scope Boundary

**Trigger classification:** No mandatory product/UI/data-shape approval trigger; this was repository-governance documentation only.
**Authorization:** Owner explicitly said `Go` after C3e source/archive lifecycle completion and fresh current-main audit.
**Approved boundary:** Add an explicit agent-readable security-check decision rule to root `AGENTS.md`, align `docs/PUSH_TEMPLATE.md`, and record a focused execution handoff.
**Explicit non-changes:** No runtime/product/UI change; no Supabase schema/RLS/Edge Function/Auth mutation; no CI workflow change; no branch-protection/ruleset change; no GHAS outage fix; no change making every GHAS/AI scanner required by default.

## Active Handoff

**Planning owner:** complete
**Implementation owner:** none active
**Review owner:** complete
**Implementation ownership state:** Complete
**Repository base last verified:** `main@399f4fddcabbece0588778afe41d62a77e25123c`
**Source branch:** `tnyx/issue-403-security-check-governance`
**Final reviewed head:** `515ea739a5059f05b4e77922e8dfbf3058f3b704`
**Merged as:** `aede3c675d803ae81dc205c7114aad6d91394a1c`
**Observed working-tree state:** connector/API execution only; no local working tree was available to inspect
**Linear mirror status:** dedicated issue creation was attempted but blocked by the workspace free-issue limit. TNYX-193 carries visibility/overlap notes; TNYX-256 remains the separate GHAS unsupported-model outage tracker.
**Validation remaining:** none for #403 source governance behavior
**Current blocker:** none
**Open review finding IDs:** none
**Next exact action:** archive/index reconciliation only. No new product/runtime slice is authorized by this archive.

## Discovery

### User Outcome

Future agents should know exactly when security evidence must be inspected for live Supabase/server boundaries and how to interpret security-check failures without guessing from the check name alone.

### Success Criteria

- Root `AGENTS.md` explicitly lists the security-sensitive scopes that trigger security-evidence inspection.
- Applicable migration/RLS/security validation, Supabase Security Advisor review where relevant, and repository security/code-scanning checks are required for those scopes.
- Required-vs-supplemental merge-gate status is tied to actual repository branch/ruleset configuration.
- Merge-gate requirement and analysis outcome/cause are independent axes.
- A required scanner infrastructure failure remains merge-blocking.
- A supplemental scanner can still produce a real concrete finding requiring disposition.
- Pure UI/layout/docs-only/unrelated refactors do not automatically require Supabase-specific security validation when they do not touch a security-sensitive boundary.
- `docs/PUSH_TEMPLATE.md` mirrors the same rule and uses canonical future protected-service path `services/api`.
- TNYX-256 remains separate and no branch protection is weakened.

## Codebase Exploration

- C3e lifecycle was complete before #403 implementation began.
- Fresh current-main base was `399f4fddcabbece0588778afe41d62a77e25123c`.
- No open PR overlapped `AGENTS.md`, `docs/PUSH_TEMPLATE.md`, or the #403 task brief.
- Root `AGENTS.md` already required task-specific Supabase migration/RLS/security checks but lacked an explicit trigger and failure-classification rule.
- `docs/PUSH_TEMPLATE.md` had generic Supabase/protected-server validation and one stale `future backend/*` reference.
- That stale path overlapped TNYX-193 P2; #403 owned the PUSH_TEMPLATE correction and TNYX-193 was notified not to duplicate it.
- TNYX-256 separately tracks the GitHub-managed AI code-scanning unsupported-model outage.

## Architecture Design

`AGENTS.md` owns the mandatory agent-readable security decision rule. `docs/PUSH_TEMPLATE.md` mirrors the same rule at push/PR time without inventing a separate policy vocabulary.

Security reporting uses two independent dimensions:

1. **Merge-gate requirement**
   - required
   - supplemental/non-required
2. **Analysis outcome/cause**
   - concrete security finding / completed analysis
   - external scanner/infrastructure failure before meaningful analysis

This preserves combinations such as `required + infrastructure failure` and `supplemental + concrete finding`.

## Implementation

- [x] added security-sensitive scope decision rule to `AGENTS.md`
- [x] aligned `docs/PUSH_TEMPLATE.md` validation/failure guidance
- [x] corrected stale protected-server path from `backend/*` to `services/api`
- [x] kept runtime, Supabase, CI workflow and branch protection untouched
- [x] validated exact docs-only PR scope
- [x] completed independent exact-head review
- [x] resolved the review thread before merge
- [x] squash-merged PR #405

## Quality Review

### Final Merge Validation

```text
Base: main@399f4fddcabbece0588778afe41d62a77e25123c
Exact final reviewed head: 515ea739a5059f05b4e77922e8dfbf3058f3b704
Changed paths: exactly 4 governance paths
Runtime/source paths: 0
Trailing whitespace: 0
Conflict markers: 0
Missing-final-newline markers: 0
Repository workflows/status checks: none triggered for docs-only exact head
Codex exact-head re-review: no major issues
Unresolved review threads before merge: 0
PR #405 squash merge: aede3c675d803ae81dc205c7114aad6d91394a1c
GitHub #403: closed completed
```

### Review Findings

| ID | Severity | Status | Finding | Resolution |
|---|---|---|---|---|
| `PR405-P2-TWO-AXIS` | P2 | Resolved | Required-vs-supplemental gate status and finding-vs-infrastructure outcome were expressed as one mutually exclusive taxonomy | Reworked both governance docs to use independent merge-gate and analysis-outcome axes; validated at `44e258193f067189af0b817517b3d14d8a3410de`; Codex re-reviewed exact final head `515ea739a5` and found no major issues |

## Final Handoff

### Changed Files In Source PR

- `.ai/tasks/README.md`
- `.ai/tasks/issue-403-security-check-governance.md`
- `AGENTS.md`
- `docs/PUSH_TEMPLATE.md`

### Actual Behavior

Agents must inspect applicable security evidence when work touches live security-sensitive Supabase/server boundaries such as Edge Functions, Auth/session/account linking, migrations/RLS/RPC/privileged DB code, protected credentials, OAuth/provider integrations, protected server-side provider calls, or future approved `services/api` code.

The policy now requires agents to verify required-vs-supplemental status from current branch/ruleset configuration and record that independently from whether a check produced a concrete finding or failed because of external scanner infrastructure.

### Known Limitations

This governance change does not fix the current GitHub-managed AI code-scanning unsupported-model outage. TNYX-256 remains the tracker for that issue.

### Final Status

`VALIDATED — MERGED VIA PR #405 (aede3c67)`

## Archive Handoff

GitHub #403 is complete. The durable security-check decision rule is now in `AGENTS.md` and `docs/PUSH_TEMPLATE.md`. No runtime, Supabase, UI, CI workflow, or branch-protection behavior changed. Any future change to actual required security gates or branch protection requires separate current-state verification and authorization.
