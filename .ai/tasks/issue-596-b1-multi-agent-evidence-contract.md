# GitHub #596 — Slice B1 multi-agent evidence and completion contract

**Status:** Blocked
**Primary owner:** Repository AI governance
**Affected platforms:** Documentation/process only (all platforms use the same agent workflow)

## Owner Approval and Scope Boundary

**Trigger:** None (docs/process clarification; no independent product feature, visible UI/UX, or Supabase table/column shape).
**Approval status:** Approved for this bounded docs-only slice.
**Approval evidence:** Owner's `Go` on 2026-10-20 immediately following the proposed #596 Slice B1 in conversation; this is chat approval, **not** a GitHub issue/PR approval.
**Approved product/UI/data-shape boundaries:** None.
**Explicit non-changes:** No app/watch/UI, Auth/health data, Supabase schema/RLS/functions, CI workflow, branch protection, attribution guard, credentials, product architecture, new governance framework, #250/#571/#580 scope, or merge.

## Active Handoff

**Planning owner:** GitHub #596 [Slice A baseline](https://github.com/im-tnyx/tio-world/issues/596#issuecomment-6286554549).
**Implementation owner:** B1 GitHub connector edit session, resumed under owner's latest `Go` for review finding fixes; no known competing source writer on the remote branch.
**Review owner:** GitHub author-side `im-tnyx` manual COMMENT reviews and Cursor supplemental automated checks observed; no independent GitHub `APPROVED` review established. Independent review pending.
**Implementation ownership state:** Handoff pending after scoped review-finding corrections; further source edits require live ownership/state verification.
**Ownership transition:** Previous B1 edit session (handoff pending) → current B1 edit session after owner's `Go` and verified unchanged remote PR head `f7809243` at takeover. No known concurrent remote source writer; other local worktrees could not be inspected.
**Repository state last verified:** 2026-10-20, remote `main@08757a899ed6ecd7f72e8aa358f6475bf9cd1a3d`.
**Branch:** `docs/issue-596-b1-quality-contract`.
**HEAD SHA:** Process-rule content last changed at `270ebfa249f84c6f917b257709a87fa9df129912`; task-brief-only checkpoint commit advances the branch beyond it. Verify the live PR head before attributing any latest-head checks/reviews.
**Observed working-tree state:** GitHub API editing only. Remote branch based on verified main; local Windows checkout not accessible.
**Observed uncommitted/dirty files:** Unknown in user's local checkout; no cleanliness claim.
**PR / tracker:** [GitHub PR #631](https://github.com/im-tnyx/tio-world/pull/631), parent GitHub #596; no dedicated Linear counterpart positively identified. TNYX-193 tracks separate #250.
**Current implementation state:** B1 process-doc clarification and author-side review findings corrected; review may continue, but completion/merge remains blocked on actual docs-only validation.
**Relevant execution surface:** `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/TEMPLATE.md`, `.ai/tasks/README.md`, `.github/PULL_REQUEST_TEMPLATE.md`, this brief and focused task-index entry.
**Validation completed at SHA:** Historical remote PR head `f780924344f68c3916b62667972145abfce71783`: GitHub compare 10 ahead / 0 behind, five expected docs paths, full PR patch hygiene scan with no added trailing whitespace or conflict markers; required `Commit attribution guard` and runner SUCCESS, Cursor Bugbot and Security Reviewer SUCCESS, Approval Router IN PROGRESS at last read. New process-rule corrections at `270ebfa2` require fresh exact-head validation/check inspection. None of this proves that local `git diff --check` ran.
**Validation remaining:** Run actual `git diff --check origin/main...HEAD` from a checkout when available; review exact final PR head, disposition findings, verify required GitHub checks. Source inspection/API-equivalent whitespace check is not the required local command.
**Current blocker:** Required docs-only `git diff --check origin/main...HEAD` has not actually run from a checkout and is unavailable in this connector-only session. Under the explicit status precedence this is `BLOCKED` for completion/merge, although author-side and independent PR review can proceed. API-equivalent hygiene is supplemental, not an undocumented waiver.
**Open review finding IDs:** B1-R01 P2 has a proposed fix at `fe7e7799` but remains Open until actual docs-only validation and exact-head recheck. B1-R02 P3 covers duplicated GitHub inline threads [r4322975969](https://github.com/im-tnyx/tio-world/pull/631#discussion_r4322975969) and [r4322977013](https://github.com/im-tnyx/tio-world/pull/631#discussion_r4322977013); status precedence corrected at `270ebfa2`. B1-R03 P3 missing acceptance/review receipt [r4322996007](https://github.com/im-tnyx/tio-world/pull/631#discussion_r4322996007) is addressed by this brief. B1-R04 P3 completion-gate contradiction found in [author COMMENT review](https://github.com/im-tnyx/tio-world/pull/631#pullrequestreview-5582617851) corrected at `270ebfa2`. B1-R05 P3 found in [r4323058162](https://github.com/im-tnyx/tio-world/pull/631#discussion_r4323058162): the brief marked B1-R01 Resolved prematurely; it remains Open in the corrected handoff. All open findings require new-head review and applicable validation before final resolution. Parent A05–A08 are outside B1.
**Next exact action:** Review live [PR #631](https://github.com/im-tnyx/tio-world/pull/631) on its final SHA; run local `git diff --check` from an available checkout, resolve any exact-head findings, verify required status checks, then request separate owner merge direction. **Do not merge**.

## 1. Discovery

### User Outcome

Any interchangeable agent (including Grok, Codex, Cursor or a human reviewer) can hand off a bounded task with truthful provenance, deterministic result status, and acceptance evidence without inventing formal approval or test completion.

### Success Criteria

- Explicit evidence-based `PASS | REVIEW | PARTIAL | BLOCKED` semantics in the canonical process owner.
- Small criterion-to-file/behavior-to-test/manual-proof-to-SHA matrix in the existing task template for substantive work; mechanical docs tasks remain lightweight.
- External/manual/chat-only review attribution is captured without requiring any named agent or confusing an opinion with GitHub `APPROVED`.
- Handoff source/tracker/docs precedence points to the canonical question-specific `docs/README.md` authority, not a conflicting global ladder.
- Existing single-source-writer, owner approval, safety and required check gates stay unchanged.

### Scope

Docs/process only; no test/CI automation and no changes to unrelated governance issues.

### Non-Goals

No mandatory 4-agent sequence, bot mandate, self-review mislabeling, or blanket tests/CI changes.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: root `AGENTS.md`, `.ai/workflow.md`, `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/README.md`, `.ai/tasks/TEMPLATE.md`, `.github/PUSH_TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `docs/README.md`, current `.github/workflows/flutter-ci.yml`.
- Existing pattern: [#596 Slice A gap map](https://github.com/im-tnyx/tio-world/issues/596#issuecomment-6286554549), plus representative PRs [#605](https://github.com/im-tnyx/tio-world/pull/605), [#613](https://github.com/im-tnyx/tio-world/pull/613), [#626](https://github.com/im-tnyx/tio-world/pull/626).
- Tests/validation present: docs-only `git diff --check` expected; GitHub API cannot inspect user's unmounted Windows worktree or run local commands there.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Review source can be Grok/Codex/Cursor/manual/chat-only | Chosen | Identity is not review proof; show SHA, reviewer relationship, findings and limitations | AI governance |
| Independent review vs self-review | Chosen | Label provenance truthfully; do not make formal GitHub approval out of chat-only feedback | AI governance |
| Extra status or tracker system | Rejected | Reuse existing `PASS/REVIEW/PARTIAL/BLOCKED` and issue/task architecture | AI governance |

## 4. Architecture Design

### Chosen Approach

Place decision semantics in `.ai/FEATURE_DEVELOPMENT.md`, receipt fields in `.ai/tasks/TEMPLATE.md`, canonical authority pointer in `.ai/tasks/README.md`, and small PR evidence cues in the existing PR template.

### Ownership and Data Flow

`docs/README.md` (authority) → `.ai/FEATURE_DEVELOPMENT.md` (process) → `.ai/tasks/TEMPLATE.md` (execution evidence) → GitHub PR (review/validation receipt).

### Alternative Rejected

New root agent rules, separate reviewer registry or Grok-specific bot gate.

### Failure and Accessibility States

Unavailable independent review or runner must be recorded, not fabricated. Existing required checks and explicit approval gates remain binding.

## 5. Implementation Plan

- [x] Clarify canonical review and final status conditions.
- [x] Add compact acceptance-to-proof and reviewer provenance fields.
- [x] Resolve task handoff precedence shortcut.
- [x] Add PR evidence cues.
- [ ] Required local docs `git diff --check`, exact final-head independent review, latest required checks and inline-thread resolution.

## 6. Quality Review

### Validation Run

- GitHub read-only/API compare and full PR patch hygiene inspection at historical head `f7809243`: PASS, five owned docs paths, no observed added trailing whitespace or conflict markers. Prior complete-file scan checked final newlines and relative references. New correction head requires the same review/checks.
- **Not run:** local `git diff --check` (checkout unavailable). No Flutter/DB tests applicable to these docs-only changes.
- **Review:** author-side GitHub COMMENT reviews surfaced four distinct P3 gaps (duplicate precedence threads count as one; B1-R05 found on later head); no formal independent `APPROVED`. Cursor Bugbot and Security Reviewer supplemental SUCCESS on `f7809243`; Approval Router in progress on that head. Codex review at older `a7095c2` failed with usage limits, not a completed analysis. Exact corrected head still needs verification.

### Acceptance Evidence (substantive scope)

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Deterministic final handoff status | `.ai/FEATURE_DEVELOPMENT.md` status table, overlap precedence and completion gate | Source review confirmed decision table and explicit priority, corrected B1-R02/R04; no runtime test applicable | Rules `270ebfa2`, GitHub API | Review of amended rules remains |
| Criterion → behavior/proof → SHA | `.ai/tasks/TEMPLATE.md` Acceptance Evidence matrix | GitHub PR patch confirms fields exist; this brief now exercises them | Template at `f7809243`, new brief at follow-up commit | Formal exact-head review pending |
| Review tool/provenance honesty | `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/TEMPLATE.md`, `.github/PULL_REQUEST_TEMPLATE.md` | Source review: independent/self and external/manual/chat-only source labels, reviewed SHA and limitations all captured | Rules `270ebfa2`, GitHub API | Independent GitHub approval not established |
| Canonical truth authority | `.ai/tasks/README.md` → `docs/README.md#conflict-resolution` | Link and owning conflict-resolution section verified on `main` | `f7809243`, GitHub API | No known mismatch |
| Single writer / existing safeguards | No production files, CI or ruleset edits; `.ai/FEATURE_DEVELOPMENT.md` retains owner gate | GitHub compare shows only five docs/task files and unchanged owner approval rules | `f7809243`, GitHub API | Local worktree and actual docs-only diff check unavailable |

### Review Provenance

**Review source / link:** [GitHub PR #631 author COMMENT reviews](https://github.com/im-tnyx/tio-world/pull/631); Codex usage-limit comment; Cursor Bugbot and Security Reviewer supplemental checks.
**Reviewer / relation to implementer:** Manual audit/review submissions through `im-tnyx`, the PR author's account; **same author identity**, not independent GitHub approval. Cursor is a separate automated checker, not a verified formal `APPROVED` review.
**Diff or commit SHA actually reviewed:** Author-side COMMENT reviews examined `f780924344f68c3916b62667972145abfce71783`; Codex failed at earlier `a7095c2`; amended SHA `270ebfa2` not yet independently reviewed.
**Review result and finding IDs/dispositions:** B1-R02 (two duplicate inline threads), B1-R03, B1-R04 and B1-R05 are P3. The original three inline threads have author-side replies and were confirmed resolved on GitHub; B1-R05 is being corrected in this handoff. B1-R01 remains Open pending actual docs validation/exact-head recheck despite the earlier process text fix. No new P1/P2 was reported by these reviews.
**Independent review?** No formal independent GitHub `APPROVED` verified; author-side reviews are **self-review**, Cursor automated checks are supplemental.
**Limitations and unmet required gates:** Actual local `git diff --check` not run; latest head checks/review pending; Codex quota failure is not an approval; owner must separately authorize any merge.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| B1-R01 | P2 | Open (fix proposed; validation/recheck pending) | Differentiate running from failed required checks and remove fixed-primary-agent implication | `a7095c2f` | Fix `fe7e7799`; required `git diff --check` and new-head recheck still outstanding |
| B1-R02 | P3 | Open (fix proposed) | Final-status precedence ambiguous, duplicate inline reports | `f7809243` | `270ebfa2`; [thread 1](https://github.com/im-tnyx/tio-world/pull/631#discussion_r4322975969), [thread 2](https://github.com/im-tnyx/tio-world/pull/631#discussion_r4322977013) |
| B1-R03 | P3 | Open (fix proposed) | New handoff brief omitted its own new template's evidence/provenance fields | `f7809243` | This amended brief; [thread](https://github.com/im-tnyx/tio-world/pull/631#discussion_r4322996007) |
| B1-R04 | P3 | Open (fix proposed) | Completion gate contradicts evidence-based PASS requirements | `f7809243` | `270ebfa2`; [review summary](https://github.com/im-tnyx/tio-world/pull/631#pullrequestreview-5582617851) |
| B1-R05 | P3 | Open (fix proposed; validation/recheck pending) | B1-R01 was prematurely marked Resolved without full required docs validation | `e06300f5` | This brief restores Open; [inline thread](https://github.com/im-tnyx/tio-world/pull/631#discussion_r4323058162) |

## 7. Final Handoff

### Changed Files

`.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/TEMPLATE.md`, `.ai/tasks/README.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.ai/tasks/issue-596-b1-multi-agent-evidence-contract.md` (five paths; no runtime/CI/protection files).

### Actual Behavior

Docs/process only; no runtime behavior changed.

### Known Limitations

Local Windows worktree unavailable from this GitHub API surface, so `git status` and actual `git diff --check` remain unverified locally. API-equivalent evidence is supplemental; required docs validation is missing. No formal independent review, corrected-HEAD required-check pass or merge authorization is claimed.

### Final Status

`BLOCKED` for validated completion/merge because the required local docs-only `git diff --check` has not run; independent review and current-head checks are also pending. The PR may continue **in review** while the completion gate is blocked. Apply `BLOCKED > PARTIAL > REVIEW > PASS` precedence.
