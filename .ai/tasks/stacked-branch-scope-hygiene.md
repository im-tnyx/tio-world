# Stacked Branch Scope Hygiene

**Status:** In progress
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

- strengthen repository agent instructions for stacked branches;
- strengthen the push checklist with concrete ancestry/scope commands;
- add PR-template evidence for stack/base/scope auditing.

### Non-Goals

- no runtime code, Flutter UI, Auth behavior, Supabase schema, CI trigger, merge, or branch deletion;
- no automatic rebasing or force-pushing;
- no changes to existing feature PR contents.

## 2. Codebase Exploration

### Verified Evidence

- `AGENTS.md` already requires `git status --short --branch`, small focused changes, no unrelated pushes, and no history rewrite without explicit approval.
- `docs/PUSH_TEMPLATE.md` already checks branch/base correctness and changed-file scope, but does not require a merge-base/ancestry audit for stacked PRs.
- `.github/PULL_REQUEST_TEMPLATE.md` does not currently require parent ref, ahead/behind state, or changed-file scope evidence.
- A recent stacked Auth branch temporarily accumulated unrelated Core/Onboarding/Welcome commits, which required source-history cleanup and child-stack reconstruction.

### Existing Pattern to Follow

Keep the current docs-first workflow and add the smallest explicit guardrails at the push/PR boundaries instead of introducing a new CI system or repository tool dependency.

### Tests or Validation Already Present

Docs-only change. Validation is changed-file/diff review plus exact command examples; no runtime build is applicable.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Require ancestry check for stacked PRs | Approved | Prevent child branches silently diverging from moved parents | Repository workflow |
| Require parent-to-head changed-file audit | Approved | Detect unrelated files before push | Repository workflow |
| Preserve recovery branch before approved rewrite | Approved | Avoid losing unrelated user work | Repository safety |
| Do not add new CI/tool dependency | Chosen | Workflow docs are sufficient for this bounded correction | Engineering |

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
→ rerun ancestry/scope audit
```

### Ownership and Data Flow

```text
AGENTS.md policy
→ docs/PUSH_TEMPLATE.md operator checklist
→ .github/PULL_REQUEST_TEMPLATE.md review evidence
```

### Alternative Rejected

A path-enforcing GitHub Action was not added because valid file ownership differs by task and would require a new scope-manifest system. The current issue is process/stack hygiene, so explicit Git evidence is the smaller reliable control.

### Failure and Accessibility States

If the parent is not an ancestor or unrelated files appear, do not push more work onto that branch. Preserve the current head before any approved rewrite and resolve stack ancestry first.

## 5. Implementation Plan

- [x] Audit existing agent/push/PR guidance.
- [ ] Add stacked-branch rules to `AGENTS.md`.
- [ ] Add concrete ancestry/scope commands to `docs/PUSH_TEMPLATE.md`.
- [ ] Add stack/scope evidence section to `.github/PULL_REQUEST_TEMPLATE.md`.
- [ ] Review final changed-file scope.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

Pending final docs diff review.

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Repository workflow documentation only. No runtime behavior changes.

### Known Limitations

These guardrails rely on agents/contributors running the documented Git checks; no automated path-policy engine is introduced.

### Final Status

`PARTIAL`
