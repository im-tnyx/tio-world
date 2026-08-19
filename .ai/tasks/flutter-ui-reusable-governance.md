# Flutter UI Reusable-First Governance

**Status:** In progress
**Primary owner:** repository AI governance + `apps/core` design-system boundary
**Affected platforms:** Flutter production UI across phone/features/app shell/Wear

## Global UI / Design-System Guardrail

This task strengthens agent instructions only. It does not redesign or modify product UI.

For any Flutter UI work, the canonical visual contract remains `apps/core/lib/src/theme/README.md`, with existing reusable core components preferred before raw local reconstruction.

## 1. Discovery

### User Outcome

Make the repository-wide agent instructions unambiguous so every Flutter UI change, not only explicit design-system/theme work, starts from the canonical theme README and reusable-core component boundary.

### Success Criteria

- Root `AGENTS.md` explicitly requires the theme README before any Flutter production UI change.
- Root `AGENTS.md` explicitly requires searching/reusing existing `apps/core` UI components before rebuilding locally.
- `.ai/tasks/README.md` applies that requirement repository-wide, while retaining `apps/features/AGENTS.md` as the feature-specific nested contract.
- `.ai/tasks/TEMPLATE.md` carries the same reusable-first/read-theme rule into every future UI task brief.
- Existing `apps/features/AGENTS.md` is not duplicated or weakened.
- No product/runtime source changes.

### Scope

- `AGENTS.md`
- `.ai/tasks/README.md`
- `.ai/tasks/TEMPLATE.md`
- this task brief

### Non-Goals

- No Flutter/Dart source changes.
- No design-system token/component API changes.
- No visual redesign.
- No rewrite of validated historical design-system task files.

## 2. Codebase Exploration

### Verified Evidence

- Root `AGENTS.md` already assigns reusable theme/widgets ownership to `apps/core`, but only explicitly requires the theme README for design-system/theme work.
- `apps/features/AGENTS.md` already has the desired feature-level workflow: read theme README, import `package:tio_core/core.dart`, and prefer reusable core components before rebuilding locally.
- `.ai/tasks/README.md` already mandates UI governance, but its explicit theme README/nested-agent step was phrased for normal feature UI rather than all Flutter production UI.
- `.ai/tasks/TEMPLATE.md` required the design-system consolidation brief for any Flutter UI work, but did not explicitly repeat the theme README + reusable-first lookup order.

### Existing Pattern to Follow

`apps/features/AGENTS.md` and `apps/core/lib/src/theme/README.md`.

### Tests or Validation Already Present

Docs-only change. Minimum validation is repository diff/whitespace review; PR CI is the final repository validation signal if triggered.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Keep this separate from PR #36 / Issue #13 product scope | Approved | Repository-wide governance should not be mixed into the Account Setup/Profile product slice | Owner |
| Reuse existing feature-level rules instead of duplicating them | Approved | Avoid instruction drift and duplicated policy | Owner |

## 4. Architecture Design

### Chosen Approach

Use root/task governance to establish the universal rule, then defer feature-package specifics to `apps/features/AGENTS.md` and visual implementation details to the theme README.

```text
Any Flutter production UI change
→ root AGENTS.md
→ .ai/tasks focused task
→ apps/core/lib/src/theme/README.md
→ inspect/reuse existing core component
→ nested apps/features/AGENTS.md when under apps/features/*
→ implement only if no existing reusable contract fits
```

### Alternative Rejected

Duplicating the entire theme/reusable policy in root, task README, template, and every feature package. This would create policy drift.

### Failure and Accessibility States

Not applicable; docs-only governance.

## 5. Implementation Plan

- [x] Strengthen root `AGENTS.md` Flutter UI rules.
- [x] Broaden `.ai/tasks/README.md` mandatory UI governance wording.
- [x] Add reusable-first/theme README rule to `.ai/tasks/TEMPLATE.md`.
- [x] Review final diff for duplication/conflicts.
- [x] Record validation/handoff state.

## 6. Quality Review

### Validation Run

```text
GitHub compare main...agent/ui-reusable-governance inspected:
- only AGENTS.md, .ai/tasks/README.md, .ai/tasks/TEMPLATE.md, and this focused task brief changed
- no Flutter/Dart/runtime/product source changed

PR #39 patch inspected:
- universal root/task rule added
- existing apps/features/AGENTS.md remains unchanged
- no conflicting duplicate policy introduced

CI:
- no workflow run triggered for the docs-only PR head

git diff --check:
- not executable in the connector-only GitHub editing environment because no local working tree is available
- limitation is explicitly recorded rather than claiming the command ran
```

### Review Findings and Resolution

- Feature-package governance was already correct, so it was intentionally left unchanged.
- Root/task governance now covers app shell, features, core, and Wear consistently.
- Reusable-first guidance points to the public core boundary rather than encouraging internal token crawling.

## 7. Final Handoff

### Changed Files

- `AGENTS.md`
- `.ai/tasks/README.md`
- `.ai/tasks/TEMPLATE.md`
- `.ai/tasks/flutter-ui-reusable-governance.md`

### Actual Behavior

Future Flutter UI tasks are explicitly instructed to read the canonical theme README, inspect/reuse existing core UI first, use `package:tio_core/core.dart` where available, and follow nested feature rules under `apps/features/*`.

### Known Limitations

The governance is implemented on branch `agent/ui-reusable-governance` in draft PR #39 and is not repository-main policy until that PR is merged. `git diff --check` could not be run in the connector-only environment.

### Final Status

`REVIEW`
