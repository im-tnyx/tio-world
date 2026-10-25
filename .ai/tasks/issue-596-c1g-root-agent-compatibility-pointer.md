# GitHub #596 C1G — Root AGENTS.md Future-API Review Pointer

**Status:** In progress (docs-only, PR/review evidence pending)
**Primary owner:** Repository AI Governance
**Affected platforms:** AI coding-agent documentation only, with no runtime or schema change

## Owner Approval and Scope Boundary

**Trigger:** None: bounded documentation follow-up to approved #596 C1F, not a new product feature, visible UI change, or table/column shape change.
**Approval evidence:** Owner's `Go next @Linear @GitHub @Supabase` after read-only audit and confirmation that #596 contains a conditional root `AGENTS.md` pointer acceptance.
**Approved files:** Root `AGENTS.md`, this handoff, and a single active pointer in `.ai/tasks/README.md`.
**Explicit non-changes:** No change to canonical `docs/development/TESTING_GUIDE.md`, Flutter, Wear, watchOS, Supabase Auth/RLS/RPC/SQL, migrations, deployments, CI, branch/ruleset config, provider integrations, future `services/api`, or issue #596 D1 cohort measurement.

## Active Handoff

- **Planning / Implementation owner:** ChatGPT connected GitHub author (remote-only, one task-slice writer).
- **Review owner:** Separate reviewer to be requested on PR; formal review not claimed in this brief.
- **Implementation ownership:** Active until review-gate handoff.
- **Starting remote branch/base:** `docs/issue-596-c1g-root-agent-compatibility-pointer` from protected `main@bba5d59ded79e430ab59b238050224569e1f1c02`.
- **Owner Windows checkout:** `G:\projects\Tio-World` is not accessible here. Working-tree cleanliness and local git commands are **NOT VERIFIED**.
- **Primary tracker:** [#596](https://github.com/im-tnyx/tio-world/issues/596) is OPEN; C1F source merged [#679](https://github.com/im-tnyx/tio-world/pull/679), archive [#680](https://github.com/im-tnyx/tio-world/pull/680). D1 measurement remains independently active.
- **Linear reconciliation:** Search found no dedicated #596 mirror. [TNYX-193](https://linear.app/tnyx/issue/TNYX-193) belongs to documentation-governance #250, [TNYX-50](https://linear.app/tnyx/issue/TNYX-50) is the completed API lifecycle policy. Advertised `get_agent_context` failed: `Tool get_agent_context not found`. No Linear mutation.
- **Supabase:** Linked project `oykupyiitspujzpwwvuj` status `ACTIVE_HEALTHY` was read via connector; no SQL, migration, Auth or hosted QA was run.
- **Validation and review:** At brief creation NOT RUN; must use exact PR HEAD, docs hygiene and attribution checks. API-based compare is not a substitute for a local `git diff --check`; GitHub Actions native output may establish that separately.
- **Next action:** Confirm three-file scoped remote diff, open docs-only PR, check exact-head CI and request technical review. Do not merge without new explicit owner `Go merge`.

## Verified Architecture And Existing Rule

- Root `AGENTS.md` already describes active Supabase, future-only and approval-gated `services/api`, security sensitive validation and right-sized testing. A **direct navigation pointer to the specific new review section was missing** on audited main.
- [Canonical risk-based review](../../docs/development/TESTING_GUIDE.md#change-time-future-protected-api-compatibility-review-affected-contracts-only) was merged in #679 and tested with cited persisted/security #674 and exempt docs-only #671 examples.
- [ADR-0007](../../docs/adr/0007-active-supabase-and-future-services-api.md) remains the approved boundary. [API lifecycle](../../docs/backend/API_LIFECYCLE.md), [module ownership](../../docs/architecture/MODULE_OWNERSHIP.md), and [Supabase adapter preservation](../../.ai/supabase-rules.md) remain unchanged.
- #596 Additional C1 acceptance allows **at most one concise root pointer, only if needed**; do not duplicate the matrix or expand #250 governance.

## Implementation Plan And Acceptance

- [ ] Add exactly one root `AGENTS.md` line linking to the canonical compatibility review, conditionally applicable to contract changes and expressly exempting unrelated UI/docs/mechanical work.
- [ ] Keep `TESTING_GUIDE.md` and existing architecture/owner rules as the substantive source of truth, with no new CI gate.
- [ ] Verify branch `main` ancestry, complete changed paths, raw diff, Markdown link target and no unrelated files.
- [ ] Run/observe actual docs-only `git diff --check` on exact PR HEAD and required GitHub checks where available. Record anything untested truthfully.
- [ ] Request reviewer and keep PR at review/owner merge gate, #596 OPEN; do not claim human security sign-off.

**Compatibility classification:** `N/A`: governance-only text does not change data, identity, repository/DTO, Auth/RLS/RPC or phone/watch sync contracts. Existing rule stays applicable to future changed contracts.

## Final Handoff (pending PR)

**Changed files planned:** `AGENTS.md`, `.ai/tasks/issue-596-c1g-root-agent-compatibility-pointer.md`, `.ai/tasks/README.md`.
**Final result:** `REVIEW` until exact-head checks and review gates are actually verified; no product behavior or hosted database change.
