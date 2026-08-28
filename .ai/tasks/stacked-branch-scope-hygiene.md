# Stacked Branch Scope Hygiene

**Status:** Validated
**Primary owner:** Repository workflow / GitHub contribution policy
**Affected platforms:** Git branches and pull requests only

## 1. Discovery

### User Outcome

Keep stacked development branches small, linear, and reviewable so unrelated UI, Auth, onboarding, or backend work cannot accidentally accumulate in the same pull request.

### Success Criteria

- every stacked PR records its exact parent branch/ref before implementation;
- agents verify parent ancestry and changed-file scope before every push;
- when a parent branch moves, child branches are reconciled in order before more work is added;
- unrelated work is preserved on a separate branch before any approved history rewrite;
- no force rewrite happens without explicit owner approval and a preserved recovery ref;
- PR bodies expose ahead/behind and changed-file scope evidence.

### Scope

- strengthen the push checklist with concrete ancestry/scope commands;
- add PR-template evidence for stack/base/scope auditing;
- rely on the existing root `AGENTS.md` requirement to read `docs/PUSH_TEMPLATE.md` before every push/PR instead of duplicating the same commands in two policy files.

### Non-Goals

- no runtime code, Flutter UI, Auth behavior, Supabase schema, CI trigger, merge, or branch deletion;
- no automatic rebasing or force-pushing;
- no changes to existing feature PR contents.

## 2. Codebase Exploration

### Verified Evidence

- `AGENTS.md` already requires `git status --short --branch`, small focused changes, no unrelated pushes, no history rewrite without explicit approval, and explicitly requires reading `docs/PUSH_TEMPLATE.md` before commit/push/PR creation.
- `docs/PUSH_TEMPLATE.md` already checked branch/base correctness and changed-file scope, but did not require a merge-base/ancestry audit for stacked PRs.
- `.github/PULL_REQUEST_TEMPLATE.md` did not require parent ref, ahead/behind state, or changed-file scope evidence.
- A recent stacked Auth branch temporarily accumulated unrelated Core/Onboarding/Welcome commits, which required source-history cleanup and child-stack reconstruction.

### Existing Pattern to Follow

Keep the current docs-first workflow and add the smallest explicit guardrails at the push/PR boundaries instead of introducing a new CI system or repository tool dependency.

### Tests or Validation Already Present

Docs-only change. Validation is repository-API ancestry/changed-file review plus full content inspection; no runtime build is applicable.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Require ancestry check for stacked PRs | Approved | Prevent child branches silently diverging from moved parents | Repository workflow |
| Require parent-to-head changed-file audit | Approved | Detect unrelated files before push | Repository workflow |
| Preserve recovery branch before approved rewrite | Approved | Avoid losing unrelated user work | Repository safety |
| Do not add new CI/tool dependency | Chosen | Workflow docs are sufficient for this bounded correction | Engineering |
| Do not duplicate the command list in `AGENTS.md` | Chosen | Root instructions already mandate `docs/PUSH_TEMPLATE.md`; one command source avoids drift | Engineering |

## 4. Architecture Design

### Chosen Approach

Use existing Git primitives as the canonical pre-push gate:

```text
parent ref
→ verify parent is ancestor of HEAD
→ inspect parent..HEAD commits
→ inspect parent...HEAD changed files
→ confirm task-owned paths only
→ push/update PR
```

When a stacked parent changes:

```text
parent moves
→ stop child implementation
→ preserve unrelated work if needed
→ reconcile child 1
→ reconcile child 2
→ reconcile child 3
→ rerun ancestry + changed-file audit
```

### Ownership and Data Flow

```text
AGENTS.md requires PUSH_TEMPLATE review
→ docs/PUSH_TEMPLATE.md owns executable branch/stack checks
→ .github/PULL_REQUEST_TEMPLATE.md records review evidence
```

### Alternative Rejected

A path-enforcing GitHub Action was not added because valid file ownership differs by task and would require a new scope-manifest system. The current issue is process/stack hygiene, so explicit Git evidence is the smaller reliable control.

### Failure and Accessibility States

If the parent is not an ancestor or unrelated files appear, do not push more work onto that branch. Preserve the current head before any approved rewrite and resolve stack ancestry first.

## 5. Implementation Plan

- [x] Audit existing agent/push/PR guidance.
- [x] Keep `AGENTS.md` unchanged because it already mandates `docs/PUSH_TEMPLATE.md` before push/PR creation.
- [x] Add concrete ancestry/scope commands to `docs/PUSH_TEMPLATE.md`.
- [x] Add stack/scope evidence section to `.github/PULL_REQUEST_TEMPLATE.md`.
- [x] Review final changed-file scope.

## 6. Quality Review

### Validation Run

```text
Base branch: agent/onboarding-slice-2-step-1-body-goal-ui
Base SHA:   7adaadfdc5fe06986aba05abbff191a0d2f3ea22
Branch:     agent/stacked-branch-scope-hygiene

GitHub compare before final task-only handoff update:
status:    ahead
behind:    0
ahead:     3

Changed files:
- .ai/tasks/stacked-branch-scope-hygiene.md
- .github/PULL_REQUEST_TEMPLATE.md
- docs/PUSH_TEMPLATE.md

Runtime/build validation: not applicable (docs/workflow only)
Local `git diff --check`: not executable through the current GitHub connector; complete changed-file and full text content were inspected instead.
```

### Review Findings and Resolution

1. Repeating all stack commands in `AGENTS.md` would create two policy copies that can drift. The root file already requires reading `docs/PUSH_TEMPLATE.md`, so the executable checklist remains single-owned there.
2. Routine recovery branches would themselves create clutter. The guidance limits recovery refs to explicitly approved history rewrites where work is actually at risk.
3. Automated path enforcement was intentionally not introduced because task-owned paths vary by slice; PR evidence now makes the scope decision explicit and reviewable.

## 7. Final Handoff

### Changed Files

- `.ai/tasks/stacked-branch-scope-hygiene.md`
- `docs/PUSH_TEMPLATE.md`
- `.github/PULL_REQUEST_TEMPLATE.md`

### Actual Behavior

Before future pushes, contributors/agents now have one mandatory parent-to-head ancestry, commit, changed-file, and diff-check sequence. Stacked PRs must record parent SHA, head SHA, ahead/behind state, expected paths, and complete changed-file evidence. Parent movement requires child reconciliation in order before more implementation continues.

### Known Limitations

These guardrails rely on agents/contributors running the documented Git checks; no automated path-policy engine is introduced.

### Final Status

`PASS`
