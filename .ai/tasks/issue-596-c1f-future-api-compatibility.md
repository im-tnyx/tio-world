# GitHub #596 C1F — Change-Time Future API Compatibility Review

**Status:** In progress (docs-only branch, merge not authorized)
**Owner:** Repository AI Governance (single Implementation owner for this slice)
**Affected platforms:** Engineering process only; current Flutter/Supabase runtime unchanged

## Owner Approval and Scope Boundary

**Trigger:** None. This is a bounded continuation of the already-tracked GitHub #596 quality/regression-policy effort, not a new product feature, UI/UX change, or Supabase table/column shape change.
**Approval evidence:** User instruction on 2026-10-25: "Start work follow agent.md @Linear @Supabase @GitHub".
**Primary tracker:** [GitHub #596](https://github.com/im-tnyx/tio-world/issues/596), still OPEN. #596's 2026-10-24 future-backend guardrail refinement was planning-only until this resumption.
**Planning ownership:** No dedicated #596 Linear mirror found by targeted Linear searches. TNYX-193 is #250's separate documentation-governance mirror; do not alter it merely to report #596 work. Linear's advertised `get_agent_context` failed with `Tool get_agent_context not found`, so shared field notes are unverified.
**In scope:** One focused addition to the existing canonical `docs/development/TESTING_GUIDE.md` risk-based review policy, plus this task brief and task-index pointer.
**Out of scope:** `AGENTS.md` rewrite, `.ai/FEATURE_DEVELOPMENT.md`, app/watch UI or behavior, repository/DTO/runtime adapters, Supabase schema/migrations/RLS/RPC/grants, remote hosted QA, CI/rulesets/security enforcement, new `services/api` or `backend/`, provider secrets, #250 whole-doc governance, #675 review closure, #596 parent closure and any merge.

## Active Handoff

**Implementation owner:** Repository AI Governance.
**Review owner:** Separately evidenced GitHub reviewer where available, otherwise record self-review truthfully.
**Implementation ownership state:** Active until docs-only PR review gate.
**Branch:** `docs/issue-596-c1f-compatibility-review-20261025`
**Source base:** GitHub protected `main@37f738c4a6788e3e997f1ab3938a2f6541f3644c` (2026-10-25, PR #678 already merged). GitHub compare returned identical with current main before branch creation.
**Local worktree:** Not available in this connector runtime; `git status --short --branch` cannot be run on the owner's Windows checkout. GitHub branch/commit/file-set audit plus actual Docs Hygiene CI are required substitutes, not a claim of local validation.
**Validation status:** Pending scoped diff + exact-HEAD required checks and review. No completed validation claimed by this brief.

## 1. Discovery

User outcome: at the point a PR changes a durable domain/data/security/sync contract, review whether the current Supabase-first and existing repository/DTO boundaries leave an evidenced future `services/api` adapter path without rewriting UI or durable identities. **This is a review question, not a promise of zero future work.**

Acceptance:
1. No second architecture owner or mandatory blanket CI gate; use existing `TESTING_GUIDE.md` matrix and task/PR evidence.
2. Trigger only for persisted domain identity/ownership, repository/DTO contracts, migrations/RLS/RPC, Auth/protected integrations, and phone/watch sync contracts.
3. Require canonical owner, current Supabase adapter and stable business contract, server-side identity/authorization, affected old-client compatibility, idempotency/retries/error paths; record `N/A`, `Compatible + evidence`, or `Migration/follow-up required + issue`.
4. Explicitly exempt unrelated pure UI, docs-only and mechanical work.
5. Provide a real, source-backed protected-data example and one genuinely exempt docs example, naming observed checks, required negative cases, and untested risk.
6. Maintain ADR-0007, `supabase/migrations/` single schema ownership, intentionally retained `Remote*/HTTP` adapters, and future-only `services/api`.

## 2. Codebase / Documentation Exploration

- Root `AGENTS.md` already establishes backend safety, tenant ownership, sensitive scope validation and future-only service. No extra pointer necessary.
- `docs/development/TESTING_GUIDE.md` already owns risk-based regression selection and task/PR AC-to-evidence mapping; that is the smallest canonical place for the additional change-time question.
- `docs/adr/0007-active-supabase-and-future-services-api.md`, `docs/architecture/MODULE_OWNERSHIP.md`, `docs/backend/API_LIFECYCLE.md` own runtime boundary, persistence ownership and mixed-version clients. `.ai/supabase-rules.md` explicitly preserves inactive `Remote*/HTTP` adapters.
- [PR #674](https://github.com/im-tnyx/tio-world/pull/674), reviewed source HEAD `6c782981f3d076dc1a615b7399017f2d8be5679a`, merged at `9e883c690fc5ca84f2f00e32c0b1489664dd1d1c`, adds checked-in `20261024120000_grant_move_routine_rpc_execute_to_authenticated.sql` with body fingerprints/least-privilege ACL preflight and postconditions. Exact-head Database CI #40102976395 was SUCCESS; linked hosted Supabase shows 70 applied migrations and authenticated-callable Move `SECURITY DEFINER` RPCs. Hosted wrong-owner/guest/JWT negative HTTP QA remains NOT RUN under #569 R5; passing SQL ACL/CI is not evidence of real hosted tenant isolation. Future portability cannot be declared proven.
- [PR #671](https://github.com/im-tnyx/tio-world/pull/671), source HEAD `db69f0358fa1a7474cc429cee252eeb117e45378`, merged `04bf644bc026256f9a5a3537c4fdb66689e3c31d`, touches only `.ai/...` archive/handoff files, no domain/runtime contracts. Its final source-HEAD Docs Hygiene, attribution guard and runner checks SUCCESS; no Flutter/DB tests required by that pure docs scope.
- GitHub #596 D1 prospective measurement milestone ledger was posted in #596 issue comments on 2026-10-25; do not confuse this docs slice with D1's independent seven-day regression observation.
- Supabase Security Advisor still reports authenticated-callable `SECURITY DEFINER` warnings; no advisor fix is in scope.

## 3. Clarification and Design

Use an in-place, concise section inside `TESTING_GUIDE.md` after its existing change-class matrix, before existing evidence/check guidance. The review result is recorded in the existing PR or active task brief, not a duplicate architecture checklist. Only ask compatibility questions supported by the changed boundary.

**Rejected:** blanket `services/api` migration infrastructure, speculative remote adapters, mandatory extra CI, another `AGENTS.md` rule, and treating a live JWT negative matrix as already passed. These duplicate canonical policy, broaden scope, or create false evidence.

## 4. Implementation

In-scope planned files:
- `docs/development/TESTING_GUIDE.md`: append bounded risk-only review guidance with two dated examples.
- `.ai/tasks/issue-596-c1f-future-api-compatibility.md`: durable handoff/validation record.
- `.ai/tasks/README.md`: one active slice pointer, without rewriting unrelated historical task statuses.

## 5. Quality Review and Final Handoff

- Verify exact changed-file set and branch relation to main using GitHub API.
- Require actual scoped `git diff --check` evidence from Docs Hygiene CI on the *final PR HEAD*; local Windows Git/Flutter/database checks were not executed by this assistant.
- Applicable acceptance: policy wording and examples mapped to the source references above; no runtime behavior to device-test in this docs-only PR.
- Record exact final-HEAD checks, review relationship/state, findings and any unavailable evidence in PR/tracker before any completion claim.
- Do not merge, close #596, or assert production API/hosted JWT coverage.
- **Current final status:** `REVIEW` (implementation/CI/review pending, no validation completion claimed).
