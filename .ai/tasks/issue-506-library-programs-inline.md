# GitHub #506 — Inline Programs on Library

**Status:** In review — PR #507 open; Codex findings addressed; exact-head CI/re-review pending
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
- [x] Run exact branch scope/hygiene audit.
- [x] Open PR.
- [ ] Complete GitHub CI + exact-head Codex review gate.

## Validation

Pre-PR connector audit:
- base/current `main@f27300ff1da444d38112bca9e7240b9983a040b7`;
- branch `13 ahead / 0 behind`;
- exactly 11 owned paths: 2 task-governance files, 2 canonical docs, 4 production Flutter files, 2 focused test files, and 1 app-shell/router test file;
- no Supabase, Program domain/repository, Routine, TrainingPlan, delete/archive, or default-My-Program contract file touched;
- changed-text scan: 0 trailing-whitespace lines and 0 conflict markers;
- current branch runtime has zero `onProgramsPressed` references;
- retired `library-programs-entry` key remains only as a negative Library regression assertion;
- existing `ProgramsPage` remains a thin optional manage-route wrapper over the same reusable `ProgramsSurface`;
- Library uses `ProgramsSurface.library` with the canonical `ProgramRepository?`, and Program rows remain display-only;
- Programs header retains a normal accessible Material tap target; no shrink-wrapped hit target is introduced.

CI follow-up:
- PR #507 exact head `53da7d4c0f157aefac421a7c15739d9aedd019e1` failed Flutter analyze on one `library_private_types_in_public_api` lint in `programs_surface.dart`;
- root cause: the public `ProgramsSurface` exposed a public `mode` field typed with the private `_ProgramsSurfaceMode` enum;
- fix: the mode field is now private (`_mode`) and remains constructor-internal; no product/UI/runtime behavior changed;
- Dart/tests were skipped on the failed head and must rerun on the resulting exact head.

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
**Review owner:** GitHub PR #507 / exact-head Codex review
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** `main@f27300ff1da444d38112bca9e7240b9983a040b7`
**Branch:** `tnyx/issue-506-library-programs-inline`
**HEAD SHA:** `0937683882d4f87c0f349d0942f22c938708ef6b` — current implementation checkpoint before this handoff-only anchor commit; runtime refresh fix, regression test, and review-handoff reconciliation are committed. Re-read PR metadata for the immutable exact validation/review head.
**Observed working-tree state:** connector-only session; no local worktree claim
**Observed uncommitted/dirty files:** not applicable
**PR / tracker:** PR #507; GitHub #506 / #475; TNYX-81 / TNYX-267 / TNYX-83
**Current implementation state:** implementation complete on branch; the first PR CI head exposed and fixed one analyzer-only public/private API lint: one reusable feature-owned `ProgramsSurface` now backs both the optional standalone `ProgramsPage` and Library inline Programs content. Library receives the canonical `ProgramRepository?`, shows a tappable Programs header + folder-plus Create Program affordance + persisted Program rows directly, and no longer uses the old mandatory Programs navigation card. Program rows remain display-only; W4/TNYX-81 and full W6B/TNYX-267 remain gated. Focused Library/router coverage and canonical Library/Programs docs are updated.
**Relevant execution surface:** Library default/Programs category, optional Programs manage route, persisted Programs collection/create
**Validation completed at SHA:** `2027b5ac06d03714deb28884c66348f98bf0442b` — Flutter CI and attribution passed; Codex review produced two P2 findings. Runtime refresh fix and focused regression test are now committed after that reviewed head.
**Validation remaining:** exact resulting-head Flutter CI, attribution, fresh Codex review, unresolved-thread and mergeability gate
**Current blocker:** none for this bounded presentation slice; W4 remains blocker for Program detail/Routine behavior
**Open review finding IDs:** `4186857060` refresh inline Programs after management; `4186857092` reconcile implemented HEAD in durable handoff. Both are addressed on branch and await exact-head verification/re-review before resolution.
**Next exact action:** verify the resulting branch HEAD, let exact-head Flutter CI/attribution run, reply to the two Codex threads with the bounded fixes, request fresh Codex review, then audit unresolved threads/mergeability and stop at the merge decision.
