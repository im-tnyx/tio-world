# Push And PR Template For AI Agents

Use this template before pushing any branch or opening/updating a pull request.

Audience: Codex, Gemini, Claude, and other AI coding agents working on **tio-world**.

Primary goal: push only intentional, reviewable, validated changes.

---

## Required Context

Fill this before pushing:

```text
Repo:
Base branch:
Base/parent SHA:
Working branch:
Task:
Expected owned paths:
Commit message:
PR title:
PR summary:
Validation:
```

For a stacked PR, `Base branch` is the immediate parent branch, not `main`, and `Base/parent SHA` must be refreshed immediately before push.

Example:

```text
Repo: im-tnyx/tio-world
Base branch: main
Base/parent SHA: <current main SHA>
Working branch: codex/update-flutter-readme
Task: Align root README and GitHub docs with Flutter-first tio-world architecture.
Expected owned paths: README.md, docs/*, .github/*
Commit message: docs(repo): align flutter monorepo docs
PR title: docs(repo): align flutter monorepo docs
PR summary:
- Updated root documentation for Flutter mobile architecture.
- Kept Flutter Wear OS and native watchOS strategy explicit.
- Added package and backend ownership guidance.
Validation:
- docs-only, no build required
```

---

## Mandatory Branch / Stack Scope Audit

Before every push, refresh the immediate parent and audit the exact parent-to-head delta. For a stacked PR, replace `<base-branch>` with the immediate parent branch.

```bash
git fetch origin --prune
git status -sb
git merge-base --is-ancestor origin/<base-branch> HEAD
git log --oneline origin/<base-branch>..HEAD
git diff --name-only origin/<base-branch>...HEAD
git diff --stat origin/<base-branch>...HEAD
git diff --check origin/<base-branch>...HEAD
```

Interpretation:

- `git merge-base --is-ancestor ...` must exit successfully. If it does not, the branch is diverged from its declared parent and must be reconciled before more work is pushed.
- `git log ...` must contain only commits that belong to the active task/slice.
- `git diff --name-only ...` must contain only files owned by the active task. A technically valid file from another feature area is still unrelated and must not be included.
- `git diff --check ...` must pass before push.

For GitHub/API-based agents that cannot run local Git commands, collect equivalent evidence through the repository API: parent SHA, merge-base/ancestor status, ahead/behind counts, commit list, and complete changed-file list. Do not treat a PR as clean until the equivalent evidence is reviewed.

### When A Stacked Parent Moves

Do not continue implementing on stale child branches.

```text
parent moves
→ stop child work
→ reconcile first child with the new parent
→ reconcile next child in order
→ repeat through the top of stack
→ rerun ancestry + changed-file audit on every child
```

Never solve parent movement by silently accumulating both histories in a child PR.

### Before Any Approved History Rewrite

History rewrite still requires explicit owner approval. If an approved cleanup would otherwise risk losing unrelated/user work, preserve the current head first using a clearly named recovery branch/ref, then perform the smallest rewrite necessary. Record the preserved ref in the handoff/PR notes.

Do not create recovery branches routinely. They are a safety measure only when a real rewrite/cleanup is authorized and the current head contains work that must be retained.

---

## Pre-Push Checklist

Confirm:

- [ ] Branch name is correct.
- [ ] Immediate base/parent branch is correct.
- [ ] Current base/parent SHA is recorded.
- [ ] Base/parent is an ancestor of `HEAD`.
- [ ] Parent-to-head commit list matches the active task only.
- [ ] Parent-to-head changed-file list matches the active task only.
- [ ] No unrelated feature areas are touched.
- [ ] If the parent moved, every affected child branch was reconciled in order before new implementation continued.
- [ ] No secrets, `.env`, keystores, signing files, APK/AAB/IPA files, build outputs, or cache files are included.
- [ ] No generated files are included unless explicitly required.
- [ ] No destructive git operation was used without explicit approval.
- [ ] If an approved history rewrite was needed, required unrelated work was preserved first and the recovery ref is recorded.
- [ ] Docs updated if runtime behavior, architecture, routing, data ownership, module ownership, or engineering practice changed.

---

## Architecture Checklist

For **tio-world** code changes:

- [ ] Flutter mobile code stays inside `apps/app`, `apps/shared`, `apps/core`, or an owning `apps/features/*` package.
- [ ] Shared reusable Dart logic belongs in `apps/shared`.
- [ ] Feature logic stays in the owning feature or package.
- [ ] UI widgets stay presentation-focused.
- [ ] Controllers/notifiers call use cases or repositories, not raw backend clients directly.
- [ ] API/database/backend assumptions do not leak into UI.
- [ ] Wear OS code stays in `apps/wear`.
- [ ] watchOS native code stays in `apps/watchos`.
- [ ] Watch apps remain fast, lightweight, and focused on quick workflows.
- [ ] Supabase Auth/data/Storage work stays in its approved `supabase/` boundary; Gemini, privileged AI, and advanced server work stay in approved protected functions or future `backend/*`.

If any item does not apply, mention why in the PR notes.

---

## Validation Checklist

Use the smallest meaningful validation.

Docs-only:

```text
Validation: docs-only, no build required.
```

Flutter monorepo:

```bash
melos bootstrap
melos analyze
melos test
```

Flutter mobile focused:

```bash
cd apps/app
flutter pub get
flutter analyze
flutter test
```

Wear OS:

```bash
cd apps/wear
flutter pub get
flutter analyze
```

Supabase or protected backend:

```text
Run the feature task's documented migration/RLS/security checks or the selected backend runtime checks.
```

If validation cannot run, document the exact reason.

---

## Commit Template

Use concise Conventional Commit style:

```bash
git add <scoped-files>
git commit -m "<type>(<scope>): <summary>"
```

Examples:

```text
docs(repo): add post-merge sync guide
feature(workout): add workout engine package
fix(mobile): preserve auth redirect route
refactor(sync): move wearable sync contracts
test(nutrition): cover macro calculator
```

Avoid:

```text
update
fix
final
misc changes
```

---

## Push Command

For a new branch:

```bash
git push -u origin <branch-name>
```

For an existing branch:

```bash
git push origin <branch-name>
```

Never force-push unless:

- the user explicitly asks, or
- maintainers requested history cleanup, and
- you clearly explain the risk.

If force push is approved:

```bash
git push --force-with-lease origin <branch-name>
```

Prefer `--force-with-lease` over `--force`.

---

## PR Body Template

```markdown
## Summary

-

## Why

-

## Scope

-

## Stack And Scope Audit

- Immediate parent branch:
- Parent SHA:
- Head SHA:
- Ahead / behind:
- Expected owned paths:
- Changed-file audit:

## Validation

- [ ] `melos analyze`
- [ ] `melos test`

## Notes

-
```

For documentation-only work:

```markdown
## Validation

- Docs-only change; no build required.
```

---

## GitHub CLI Commands

Create PR:

```bash
gh pr create \
  --base main \
  --head <branch-name> \
  --title "<PR title>" \
  --body "<PR body>"
```

For a stacked PR, replace `main` with the immediate parent branch.

View PR mergeability:

```bash
gh pr view <number> --json mergeable,mergeStateStatus,statusCheckRollup
```

If `gh` is not installed:

- push the branch
- provide the compare URL
- include PR title and summary for the user

Compare URL format:

```text
https://github.com/im-tnyx/tio-world/compare/<base-branch>...<branch-name>?expand=1
```

---

## Post-Push Report

After pushing, tell the user:

```text
Branch:
Parent branch / SHA:
Commit:
Ahead / behind:
Changed files:
Pushed:
PR:
Validation:
Working tree:
```

Example:

```text
Branch: codex/update-flutter-readme
Parent branch / SHA: main / <sha>
Commit: aa228e2 docs(repo): align flutter monorepo docs
Ahead / behind: 1 / 0
Changed files: README.md, docs/*
Pushed: yes
PR: https://github.com/im-tnyx/tio-world/pull/6
Validation: docs-only, no build required
Working tree: clean
```

---

## Agent Safety Rules

Agents must not:

- push unrelated changes
- keep implementing on a child branch after its declared parent has moved without reconciling the stack
- rewrite history without explicit approval
- commit secrets
- hide failing validation
- claim PR creation if the tool was unavailable
- delete branches unless requested
- merge PRs unless explicitly told to proceed

Agents should:

- keep scope tight
- record exact parent/child ancestry for stacked work
- inspect complete parent-to-head commit and changed-file lists before push
- preserve unrelated work before any approved history rewrite
- read nearby code before editing
- prefer existing patterns
- update docs when behavior changes
- report exact commands and outcomes

Ship clean, small, reviewable work. Future maintainers will thank you.
