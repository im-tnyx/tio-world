# GitHub #596 — Slice B1 multi-agent evidence and completion contract

**Status:** In progress
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
**Implementation owner:** This bounded B1 GitHub connector edit session; only one active source writer for this slice.
**Review owner:** Not assigned. Independent review pending; author self-audit must not be labeled independent.
**Implementation ownership state:** Handoff pending (docs edits complete; no additional source writer authorized without refreshed ownership check)
**Ownership transition:** Not applicable (new B1 slice).
**Repository state last verified:** 2026-10-20, remote `main@08757a899ed6ecd7f72e8aa358f6475bf9cd1a3d`.
**Branch:** `docs/issue-596-b1-quality-contract`.
**HEAD SHA:** Docs/process content last changed at `ca1c541b865c18867db74fc903eff34f229ed6b4`; subsequent handoff-only commit must be verified as the live PR head.
**Observed working-tree state:** GitHub API editing only. Remote branch based on verified main; local Windows checkout not accessible.
**Observed uncommitted/dirty files:** Unknown in user's local checkout; no cleanliness claim.
**PR / tracker:** GitHub #596; no dedicated Linear counterpart positively identified. TNYX-193 tracks separate #250.
**Current implementation state:** Focused documentation edits complete; GitHub PR review and required checks remain.
**Relevant execution surface:** `.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/TEMPLATE.md`, `.ai/tasks/README.md`, `.github/PULL_REQUEST_TEMPLATE.md`, this brief and focused task-index entry.
**Validation completed at SHA:** GitHub API-equivalent source/scope validation at `ca1c541b865c18867db74fc903eff34f229ed6b4`: base ancestor / 7 ahead / 0 behind; exactly five expected paths; complete changed-file scan found no trailing whitespace, missing final newlines, or merge-conflict markers; new relative links verified against checked repo paths; all four final status rules present. This is **not** local `git diff --check` or a completed independent review.
**Validation remaining:** Run actual `git diff --check origin/main...HEAD` from a checkout when available; review exact final PR head, disposition findings, verify required GitHub checks. Source inspection/API-equivalent whitespace check is not the required local command.
**Current blocker:** Local `git diff --check` is unavailable on this connector-only execution surface; no local repository is mounted. This is a disclosed review/validation limitation, not permission to waive a required merge gate.
**Open review finding IDs:** G596-A01 through A04 and A02/A03 clarify via this slice; remaining A05–A08 outside scope.
**Next exact action:** Open a narrowly scoped PR from this branch to `main`, independently review its exact head and run the remaining docs-only validation from an available checkout; **do not merge**.

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
- [ ] Local docs `git diff --check`, exact final-head independent review, and GitHub required checks.

## 6. Quality Review

### Validation Run

- GitHub read-only/API comparisons and complete changed-file hygiene inspection at `ca1c541b`: PASS, five owned paths, no observed trailing whitespace/conflict markers, expected new links/statuses present.
- **Not run:** local `git diff --check` (checkout unavailable). No Flutter/DB tests applicable to these docs-only changes.
- **Review:** author-side limited source inspection only; independent review and final PR exact-head check outstanding.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| | | Open | | | |

## 7. Final Handoff

### Changed Files

`.ai/FEATURE_DEVELOPMENT.md`, `.ai/tasks/TEMPLATE.md`, `.ai/tasks/README.md`, `.github/PULL_REQUEST_TEMPLATE.md`, `.ai/tasks/issue-596-b1-multi-agent-evidence-contract.md` (five paths; no runtime/CI/protection files).

### Actual Behavior

Docs/process only; no runtime behavior changed.

### Known Limitations

Local Windows worktree unavailable from this GitHub API surface, so `git status` and actual `git diff --check` are unverified locally. No independent review, current-HEAD required-check pass or merge authorization is claimed.

### Final Status

`REVIEW` (pending exact-head review/validation; not `PASS`).
