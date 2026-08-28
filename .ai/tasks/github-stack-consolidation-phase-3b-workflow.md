# GitHub stack consolidation — Phase 3B workflow hygiene

**Status:** Validated
**Primary owner:** Repository workflow and contribution documentation
**Affected platforms:** Git/PR workflow only; no runtime platform change
**Local branch:** codex/github-stack-consolidation

## 1. Discovery

Absorb only PR #124's effective workflow/docs net diff into the existing
consolidation branch. Validate this docs-only slice, create one new local
commit, and stop. Do not amend the Phase 3A commit.

- Starting Phase 3A HEAD: 31dd923a5fd433ff7b76f6d0b02f7f4f6a429c0f.
- Foundation PR #152: 5d44c1abf8682247e5eabe1081ca905f722910ee.
- Phase 3B source PR #124: 2d53a1b8f3c6d620a8fd95885ed351f6590ad464.
- Source parent: agent/onboarding-slice-2-step-1-body-goal-ui.
- Source parent SHA: 7adaadfdc5fe06986aba05abbff191a0d2f3ea22.
- Historical source range: four commits, three workflow/docs files.
- Success: three imported files retain #124's intended content, this brief is
  the only extra evidence path, and Phase 3A source remains unchanged.

Scope: .ai/tasks/stacked-branch-scope-hygiene.md,
.github/PULL_REQUEST_TEMPLATE.md and docs/PUSH_TEMPLATE.md.

Non-goals: runtime/source changes, UI-preserve, Phase 3C, new workflow tooling,
path manifests, CI enforcement, branch switching, worktree creation/use,
commit amendment, history rewriting, push, PR/Issue actions, main changes,
branch deletion, worktree deletion/pruning, or attachment/editor/session access.
No Supabase operation or source/config/data/schema mutation is authorized.
The unrelated agents/github-workflow-failure-fix worktree remains untouched.

## 2. Codebase Exploration

Read the Phase 2 reconciliation and Phase 3A execution reports, applicable
AGENTS.md, current push/PR templates, task template, workflow and task-file
conventions. Fresh fetch without pruning confirmed both #124 source pins.
The active branch/HEAD matched the starting state; tracked state was clean.
Pre-existing user-owned untracked attachments remain outside this slice.

Verified source range contains only the three listed files. A byte-preserving
net patch dry check passed. No historical commit replay or source merge is
needed. The imported historical task's earlier API-only validation and
three-commit checkpoint remain historical evidence, not Phase 3B results.

## 3. Clarification

| Decision | Status | Rationale |
|---|---|---|
| Stay on the existing consolidation branch | Approved | No worktree or branch switch |
| Import the exact three-file net diff | Approved | No workflow redesign or runtime changes |
| Add one Phase 3B brief | Chosen | Preserve the validated Phase 3A handoff unchanged |
| Keep generic prune command as source documentation only | Required | This task explicitly permits fetch without pruning only |
| Local commit after docs validation | Approved | One new commit; no push |
| Leave unrelated worktree and sessions untouched | Required | Worktree cleanup remains outside this phase |

## 4. Architecture Design

docs/PUSH_TEMPLATE.md continues to own executable parent/stack checks;
.github/PULL_REQUEST_TEMPLATE.md records ancestry, commit and changed-file
evidence. AGENTS.md already requires the push template and stays unchanged.
Parent movement requires ordered reconciliation. History rewrite still needs
explicit approval and preservation of required work on a recovery ref.

Source provenance parent (#124's parent) and integration base (Phase 3A HEAD)
are distinct. Audit each delta against its own exact base; do not treat the
source parent as the consolidation branch's newly selected PR base.

Rejected: replaying the four historical commits, duplicating policy in
AGENTS.md, adding a scope-manifest/CI system, or including UI-preserve.
No rendering, accessibility, navigation or persistence contract changes.

## 5. Implementation Plan

- [x] Verify active root, branch, starting HEAD and clean tracked state.
- [x] Fetch without pruning; verify exact source/parent and three-file scope.
- [x] Read current instructions and pass the net patch applicability check.
- [x] Import only the effective #124 net diff.
- [x] Inspect all final files; review Git syntax, approval and recovery guards.
- [x] Verify scope, Phase 3A retention, whitespace and relevant docs tooling.
- [x] Docs gates permit one bounded local Phase 3B commit; preserve Phase 3A.
- [x] Freeze this handoff; exact commit/final-state evidence belongs in the
  outside-repository report. Stop before Phase 3C.

## 6. Quality Review

Validation run:

- Fresh source pins, clean tracked preflight and net patch apply-check: PASS.
- Source-parent ancestry, parent..source log, parent...source name-only/stat
  and diff --check command forms: PASS using the verified origin refs.
- git rev-list --left-right --count for the source range: 0 parent-only,
  4 source-only commits; the exact historical scope is three files.
- Complete final content review: all three imported files inspected.
- All three imported Git blobs exactly match #124's final source.
- git diff --check: PASS after removing one extra EOF blank line in this brief.
- Integration scope: four paths, zero unexpected/missing entries; only the
  three imported workflow files plus this allowed evidence brief.
- git diff --quiet against Phase 3A: apps, supabase, AGENTS.md, tracked
  attachments and the Phase 3A brief are unchanged.
- Active-root worktree metadata still shows the unrelated branch at main's
  unchanged SHA; no command entered or operated on that worktree.

No configured Markdown/docs lint was found in the inspected repository
workflow/setup/contribution sources and root tooling candidates.
No extra linter was installed. Flutter/Dart suites and Android builds were
not rerun: this docs-only slice does not require them. Historical Phase 3A
test/build results are not presented as new executions.

The generic #124 template includes git fetch origin --prune. It is not an
instruction to execute pruning in this phase: the active task's no-prune,
no-push and preservation constraints take precedence. No destructive example,
push, PR operation or recovery branch creation is to be executed for validation.

Push and PR instructions agree on using the immediate parent for stacked work.
Placeholder commands need real ref/path values before use; Bash continuation
examples are not literal PowerShell commands. Approval plus recovery safeguards
remain required for any future history rewrite. No new enforcement system or
automatic rewrite/cleanup behavior was introduced.

## 7. Final Handoff

Validated scope: three exact #124 workflow/docs files plus this bounded task
record. Phase 3A units and its handoff brief remain unchanged; UI-preserve is
not yet integrated. No runtime source change, push, main mutation,
branch/worktree deletion, attachment access or Supabase operation occurred.

Preserve the historical #124 record as provenance. This brief holds the
current integration evidence; exact local commit and remote/ref proof belong
in github-consolidation-phase-3b-workflow-2026-08-28.md outside the repository.

**Final status:** PASS for local docs validation. One new local commit is
permitted; no amendment or push. Phase 3C requires a separate explicit request.
