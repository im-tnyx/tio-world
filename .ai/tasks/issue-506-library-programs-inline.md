# GitHub #506 — Inline Programs on Library

**Status:** In progress — PR #507 open; owner-approved #475 Program-row reconciliation and review findings are active
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
- Library Program rows use the owner-approved plain header treatment with an expand/collapse chevron, not a large/grouped Program card.
- The owner also approved the dotted `Add new routine` card beneath expanded Programs. That affordance remains capability-gated until W4 supplies a real Program-owned Routine create handoff; this slice must not ship it as an inert/fake action.
- Program detail, Program-owned Routine actions and Delete Program remain gated by W4/lifecycle readiness.
- Owner-approved follow-up in this same slice: Library Program 3-dot opens a Program-scoped bottom sheet; only the already-real persisted **Edit Program** rename action is exposed now.

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
- replace the Library grouped Program card with plain Program header rows and presentation-only expand/collapse state;
- keep the dotted `Add new routine` target recorded but do not expose it until a real W4 Routine-create callback is available;
- add Library-only 3-dot overflow → Program-scoped bottom sheet using reusable Tio sheet/group/settings components;
- expose only persisted Edit Program rename through the existing `ProgramRepository.rename()` boundary; keep Open/View, Add New Routine and Delete hidden until capability-ready;
- focused Programs/Library/router tests;
- reconcile `docs/screens/library.md` and `docs/screens/programs.md`.

## Out of Scope

- Program detail route or row navigation;
- Program detail navigation and Open/View action;
- Routine rows/persistence and active Add Routine;
- Delete/archive lifecycle;
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

TNYX-81 and TNYX-267 remain Backlog/blocked. This slice does not claim W4/W6B completion. Library Program names remain non-navigable; the chevron is presentation-only and the 3-dot sheet exposes only persisted rename, which already exists behind `ProgramRepository.rename()`.

## Implementation Plan

- [x] Refactor Programs presentation into reusable standalone/embedded surface without changing existing Programs-page behavior.
- [x] Replace Library Programs navigation card with embedded Programs surface.
- [x] Wire Program repository into Library composition.
- [x] Keep header → optional Programs manage route.
- [x] Add/adjust Programs, Library and app-router tests.
- [x] Reconcile Library/Programs canonical docs.
- [x] Reconcile owner-approved plain Program row, Library-only chevron, and 3-dot bottom-sheet interaction.
- [x] Wire persisted Edit Program rename while keeping W4/delete actions gated.
- [ ] Re-run exact branch scope/hygiene audit after the latest owner-approved UI correction.
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
**Current implementation state:** implementation active on branch. Library renders persisted Programs directly as plain rows, with Library-only expand/collapse chevrons and 3-dot overflow. The overflow opens a Program-scoped Tio bottom sheet and exposes only the already-real persisted Edit Program rename action. The optional standalone Programs page keeps its prior grouped display-only geometry without chevrons/overflow. W4-gated Program detail/Routine actions and delete lifecycle remain hidden. Focused Library/Programs tests and canonical docs are being reconciled.
**Relevant execution surface:** Library default/Programs category, optional Programs manage route, persisted Programs collection/create
**Validation completed at SHA:** `2027b5ac06d03714deb28884c66348f98bf0442b` — Flutter CI and attribution passed; Codex review produced two P2 findings. Runtime refresh fix and focused regression test are now committed after that reviewed head.
**Validation remaining:** exact resulting-head Flutter CI, attribution, fresh Codex review, unresolved-thread and mergeability gate
**Current blocker:** none for this bounded presentation slice; W4 remains blocker for Program detail/Routine behavior
**Open review finding IDs:** `4186857060` refresh inline Programs after management; `4186857092` handoff anchor; `4187057150` allowed task status; `4187057155` fail-closed Programs header handoff; `4187057166` visual baseline validation; `4187147622` standalone inert chevron; `4187147629` W4/current-runtime doc contradiction. Latest implementation addresses the runtime/status/standalone/docs findings; exact-head CI and re-review are still required before resolution.
**Next exact action:** verify the resulting branch HEAD and complete exact scope audit; inspect exact-head Flutter CI; reply to all addressed Codex threads with evidence; request fresh Codex review; audit unresolved threads/mergeability and stop at the merge decision.
