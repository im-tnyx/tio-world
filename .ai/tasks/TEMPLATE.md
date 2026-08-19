# Feature Task Template

**Status:** Ready | In progress | Needs decision | Blocked | Validated | Superseded
**Primary owner:**
**Affected platforms:**

## Global UI / Design-System Guardrail

For any Flutter UI work, read `.ai/tasks/design-system-token-consolidation.md` and `apps/core/lib/src/theme/README.md` before changing visual implementation. Inspect the existing reusable core UI/component surface and prefer the public `package:tio_core/core.dart` boundary before rebuilding an equivalent pattern locally. When working under `apps/features/*`, also follow `apps/features/AGENTS.md`.

Mandatory rules:

- fixed product-visible visual values follow the centralized `apps/core` design-system ownership model;
- existing reusable core components are preferred before raw local reconstruction of equivalent shared UI;
- a new reusable core component/contract requires genuine reuse evidence; one-off feature/workflow composition stays with its owning feature while consuming governed core values;
- feature packages must not create parallel design-token catalogs such as `WelcomeTokens`, `AuthTokens`, `HomeTokens`, or equivalent feature color/layout/theme bags;
- component/feature/screen/widget code must not introduce independent raw fixed visual values when they belong to governed core ownership;
- design-system refactors are pixel-preserving by default;
- **no screen design, layout, color appearance, typography appearance, spacing, radius, icon sizing, component geometry, motion choreography, or other visible UI contract may change without separate explicit owner/design confirmation**;
- if implementation work exposes a UI/design improvement, record it as a separate decision/task and preserve current rendering until approved.

These rules do not prohibit business/domain values, runtime-derived measurements, indexes, validation limits, dates, calculations, or other genuine non-design literals.

## 1. Discovery

### User Outcome

### Success Criteria

### Scope

### Non-Goals

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
- Existing pattern to follow:
- Tests or validation already present:

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| | | | |

## 4. Architecture Design

### Chosen Approach

### Ownership and Data Flow

```text
UI -> Controller/Notifier -> Use case -> Repository -> Data source
```

### Alternative Rejected

### Failure and Accessibility States

## 5. Implementation Plan

- [ ]

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

## 7. Final Handoff

### Changed Files

### Actual Behavior

### Known Limitations

### Final Status

`PASS` | `REVIEW` | `PARTIAL` | `BLOCKED`
