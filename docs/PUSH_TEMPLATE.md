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
Working branch:
Task:
Commit message:
PR title:
PR summary:
Validation:
```

Example:

```text
Repo: im-tnyx/tio-world
Base branch: main
Working branch: codex/update-flutter-readme
Task: Align root README and GitHub docs with Flutter-first tio-world architecture.
Commit message: docs(repo): align flutter monorepo docs
PR title: docs(repo): align flutter monorepo docs
PR summary:
- Updated root documentation for Flutter mobile architecture.
- Kept Wear OS and watchOS native strategy explicit.
- Added package and backend ownership guidance.
Validation:
- docs-only, no build required
```

---

## Pre-Push Checklist

Run:

```bash
git status -sb
git diff --stat
git diff --check
```

Confirm:

- [ ] Branch name is correct.
- [ ] Base branch is correct.
- [ ] Changed files match the task scope.
- [ ] No unrelated feature areas are touched.
- [ ] No secrets, `.env`, keystores, signing files, APK/AAB/IPA files, build outputs, or cache files are included.
- [ ] No generated files are included unless explicitly required.
- [ ] No destructive git operation was used.
- [ ] Docs updated if runtime behavior, architecture, routing, data ownership, or module ownership changed.

---

## Architecture Checklist

For **tio-world** code changes:

- [ ] Flutter mobile code stays inside `apps/app` or shared Dart packages.
- [ ] Shared reusable Dart logic belongs in `packages/*`.
- [ ] Feature logic stays in the owning feature or package.
- [ ] UI widgets stay presentation-focused.
- [ ] Controllers/notifiers call use cases or repositories, not raw backend clients directly.
- [ ] API/database/backend assumptions do not leak into UI.
- [ ] Wear OS code stays in `apps/wear`.
- [ ] watchOS native code stays in `apps/watchos`.
- [ ] Watch apps remain fast, lightweight, and focused on quick workflows.
- [ ] Backend and AI work stays in `backend/*`.

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

Backend:

```bash
pnpm install
pnpm lint
pnpm test
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
https://github.com/im-tnyx/tio-world/compare/main...<branch-name>?expand=1
```

---

## Post-Push Report

After pushing, tell the user:

```text
Branch:
Commit:
Pushed:
PR:
Validation:
Working tree:
```

Example:

```text
Branch: codex/update-flutter-readme
Commit: aa228e2 docs(repo): align flutter monorepo docs
Pushed: yes
PR: https://github.com/im-tnyx/tio-world/pull/6
Validation: docs-only, no build required
Working tree: clean
```

---

## Agent Safety Rules

Agents must not:

- push unrelated changes
- rewrite history without explicit approval
- commit secrets
- hide failing validation
- claim PR creation if the tool was unavailable
- delete branches unless requested
- merge PRs unless explicitly told to proceed

Agents should:

- keep scope tight
- read nearby code before editing
- prefer existing patterns
- update docs when behavior changes
- report exact commands and outcomes

Ship clean, small, reviewable work. Future maintainers will thank you.
