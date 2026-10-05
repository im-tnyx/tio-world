# GitHub #506 — Inline Programs on Library

**Status:** In progress
**Primary owner:** `apps/features/workout` Library/Programs presentation + `apps/app` composition
**GitHub tracker:** #506
**Planning:** #475, Linear TNYX-81 / TNYX-267 / TNYX-83
**Base:** `main@f27300ff1da444d38112bca9e7240b9983a040b7`

## Owner Approval

Approved through the owner-reported Programs mismatch against #475 followed by `Go with next follow agent.md`.

Final bounded target for this slice:

```text
Library
[ Programs ] [ Exercises ]

default / Programs selected
→ Programs                         [folder-plus]
→ persisted Program rows directly on Library
```

- Programs header text may open the existing `/workout/programs` screen as an optional secondary management surface.
- folder-plus reuses the current canonical Create Program flow.
- Program rows remain display-only until W4 supplies Program detail/Routine capability.

## Verified Baseline

- #504/#505 Exercises work is merged/archived.
- Current main: `f27300ff1da444d38112bca9e7240b9983a040b7`.
- Library currently renders one standalone Programs navigation card as default content.
- Tapping it pushes `/workout/programs`, making that screen a mandatory intermediate.
- `ProgramsPage` already has real persisted loading, retry, generated-name create, create failure and display-only rows through `ProgramsController` + `ProgramRepository`.
- production `programRepositoryProvider` fails closed with null when durable Supabase persistence is unavailable.
- #475 says Programs render directly on Library and the manage screen is optional secondary navigation.
- TNYX-267 remains blocked by TNYX-81 for Program detail/Routine behavior.

## In Scope

- reuse one feature-owned Programs controller/create/list implementation across Library and the existing Programs page;
- render Programs header + folder-plus create affordance directly on Library;
- render persisted Program rows directly on Library default/selected Programs state;
- keep Programs header → `/workout/programs` optional management route;
- preserve loading/empty/load-failure/retry/create-failure/fail-closed behavior;
- preserve display-only Program rows;
- focused Programs/Library/router tests;
- reconcile `docs/screens/library.md` and `docs/screens/programs.md`.

## Out of Scope

- Program detail route or row navigation;
- Program overflow actions;
- Routine rows, expand/collapse, Add Routine;
- Library top-bar + / default My Program;
- Program delete/archive/media;
- Your Plan / TrainingPlan;
- Supabase schema/RLS/Storage;
- new Program model, repository or persistence source.

## Architecture

```text
App composition
→ ProgramRepository?
→ LibraryPage
   → reusable feature-owned Programs collection surface
      → ProgramsController
      → ProgramRepository
      → canonical Create Program editor
→ optional Programs header tap
   → existing /workout/programs
   → same reusable Programs collection implementation
```

Library remains presentation/navigation only; Program truth stays behind `ProgramRepository`.

## Chosen Approach

Refactor the existing Programs presentation into one reusable stateful collection/surface that owns controller lifecycle and the Create Program editor. It can render:
- full standalone Programs page mode with the existing AppBar/create affordance; or
- embedded Library mode with the approved Programs header + folder-plus affordance and non-scrollable collection body.

This avoids duplicating repository/controller/create logic.

### Alternative rejected

Copying Programs loading/create/list logic into `LibraryPage` would create two presentation implementations and future drift. Embedding the full `ProgramsPage` Scaffold inside Library would create nested navigation/app-bar geometry and is rejected.

## Dependency Guard

TNYX-81 and TNYX-267 remain Backlog/blocked. This slice does not claim W4/W6B completion. Program rows intentionally stay non-interactive.

## Implementation Plan

- [x] Refactor Programs presentation into reusable standalone/embedded surface without changing existing Programs-page behavior.
- [x] Replace Library Programs navigation card with embedded Programs surface.
- [x] Wire Program repository into Library composition.
- [x] Keep header → optional Programs manage route.
- [x] Add/adjust Programs, Library and app-router tests.
- [x] Reconcile Library/Programs canonical docs.
- [ ] Run exact branch scope/hygiene audit.
- [ ] Open PR and complete GitHub CI + exact-head Codex review gate.

## Validation

Connector-only session:
- GitHub compare/base/head scope audit;
- changed-text whitespace/conflict-marker scan;
- GitHub Flutter analyze/test CI;
- attribution guards;
- exact-head Codex review;
- unresolved-thread audit.

Local Flutter commands / local `git diff --check` are not claimed unless a local worktree becomes available.

## Active Handoff

**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** pending PR
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main@f27300ff1da444d38112bca9e7240b9983a040b7`
**Branch:** `tnyx/issue-506-library-programs-inline`
**HEAD SHA:** branch created from base; source change not started
**Observed working-tree state:** connector-only session; no local worktree claim
**Observed uncommitted/dirty files:** not applicable
**PR / tracker:** GitHub #506; #475; TNYX-81 / TNYX-267 / TNYX-83
**Current implementation state:** reusable Programs surface extracted; Library now receives the canonical Program repository and renders Programs header/create/list directly; existing ProgramsPage reuses the same surface as optional secondary management; Program rows remain display-only; focused Library/router tests and canonical docs are updated
**Relevant execution surface:** Library default/Programs category, optional Programs manage route, persisted Programs collection/create
**Validation completed at SHA:** planning/audit only
**Validation remaining:** source scope audit, Flutter CI, attribution, Codex exact-head review
**Current blocker:** none for this bounded presentation slice; W4 remains blocker for Program detail/Routine behavior
**Open review finding IDs:** none
**Next exact action:** run exact branch source/scope/hygiene audit, correct any compile/test contract mismatch, then open the focused PR and use GitHub CI + exact-head Codex review as executable validation.
