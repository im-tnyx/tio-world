## Summary

-

## Feature Development Evidence

Use this section for user-facing features, cross-package changes, navigation, persistence, platform behavior, and design-system work. Mark `Not applicable` for a focused docs-only or maintenance PR.

- Task brief: `.ai/tasks/<task>.md` or Not applicable
- Discovery and codebase evidence:
- Clarifications and decisions:
- Chosen architecture and rejected alternative:
- Quality-review outcome:

## Stack And Scope Audit

For a stacked PR, use the immediate parent branch, not `main`.

- Immediate parent branch:
- Parent SHA at audit time:
- Head SHA:
- Ahead / behind:
- Expected owned paths:
- Complete changed-file audit:

- [ ] Immediate parent is an ancestor of `HEAD`.
- [ ] Parent-to-head commit list contains only this task/slice.
- [ ] Parent-to-head changed-file list contains only this task/slice.
- [ ] No unrelated feature area is included.
- [ ] If the parent moved, affected child branches were reconciled in order before new implementation continued.
- [ ] No history rewrite was used, or the rewrite was explicitly approved and required work was preserved on a recovery ref first.

## Type Of Change

- [ ] Documentation
- [ ] Flutter phone app shell (`apps/app`)
- [ ] Flutter shared/core package (`apps/shared` or `apps/core`)
- [ ] Flutter feature package (`apps/features/*`)
- [ ] Flutter Wear OS app (`apps/wear`)
- [ ] watchOS native app (`apps/watchos`)
- [ ] Backend / AI
- [ ] Architecture
- [ ] Navigation / routing
- [ ] Data / sync / persistence
- [ ] UI / design system
- [ ] Build / tooling / CI

## Architecture And Documentation

- [ ] Relevant documentation updated.
- [ ] ADR updated or added if a durable architecture decision changed.
- [ ] Architecture changelog updated if module boundaries, routing, data flow, or engineering practice changed.
- [ ] Mobile/watch/backend progress doc updated if implementation status changed.
- [ ] No documentation change needed.

## Public Repo Safety

- [ ] No local environment values or signing files are included.
- [ ] No generated/cache/build artifacts are included.
- [ ] No APK, AAB, IPA, archive, or local release artifact is included.
- [ ] Demo data is temporary scaffolding or clearly replaced by repository/API-backed data.
- [ ] Feature ownership follows the canonical docs.

## Definition Of Done

- [ ] Requirements implemented.
- [ ] Module ownership respected.
- [ ] `apps/app` remains a thin app shell where applicable.
- [ ] `apps/core` does not import feature packages.
- [ ] `apps/shared` remains pure Dart and does not import Flutter UI.
- [ ] Flutter screens/widgets remain presentation-only where applicable.
- [ ] Controller/notifier/use case/repository boundaries respected.
- [ ] Routing remains typed or centralized through the approved router.
- [ ] Flutter Wear OS and native watchOS apps stay lightweight and do not duplicate heavy phone/backend behavior.
- [ ] Loading, empty, and error states considered where applicable.
- [ ] Unit/widget/integration tests pass or are consciously scoped out.
- [ ] Analyze/build checks pass or the reason is documented.
- [ ] No new warnings introduced.
- [ ] UI matches approved design/product direction, if applicable.
- [ ] Accessibility reviewed, if applicable.

## Validation

List commands actually run:

-

Examples:

```bash
git merge-base --is-ancestor origin/<base-branch> HEAD
git log --oneline origin/<base-branch>..HEAD
git diff --name-only origin/<base-branch>...HEAD
git diff --check origin/<base-branch>...HEAD
melos analyze
melos test
cd apps/app && flutter test
cd apps/app && flutter analyze
cd apps/features/workout && dart test
cd apps/features/nutrition && dart analyze
pnpm test
```

## Notes

Add implementation notes, intentional deviations, preserved recovery refs, or non-applicable checklist explanations.
