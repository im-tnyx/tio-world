# GitHub #501 — Custom Exercises focused-state UI polish

**Status:** In progress — implementation complete; CI/review pending
**Primary owner:** `apps/features/workout` presentation
**Affected platform:** Flutter phone UI
**GitHub tracker:** #501
**Linear parent:** TNYX-264 (child creation blocked by Linear free issue limit)

## Owner Approval

**Approval status:** Approved.

Owner direction on 2026-10-05: before continuing future GitHub #475 capabilities, first audit and fix/polish the UI that is already shipped. On the next command the owner said `go next follow agent.md`, authorizing the current-UI audit/fix lane. This brief is the first bounded slice found by that audit.

## User Outcome

When a user enters Library → Custom Exercises, the focused state should visibly read as Custom Exercises instead of looking like the generic catalog screen, while still reusing the one canonical Exercises route/screen and existing W3D data/editor flow.

## Verified Baseline

Repository anchor: `main@56617849be27cecded266b1f8b1f6853fe24430c`.

Current source:
- Library Custom Exercises entry routes to `/workout/exercises?custom=true`.
- `ExercisesPage(customOnly: true)` filters to user-created rows and exposes only supported Custom taxonomy.
- The AppBar still renders `Exercises`.
- Search hint remains `Search exercises`.
- Filter tooltip/sheet title remain `Filter exercises`.
- No-match copy remains `No exercises match your search or filters.`.
- The focused list repeats a `Custom Exercises` section header below the screen title.
- Empty state already correctly says `No custom exercises yet`.
- Normal unified Exercises state intentionally renders `Custom Exercises` and `All Exercises` section headers.

Core/theme audit:
- `TioAppBar`, `TioInput`, `TioButton`, `TioEditorSheet` and current token usage are already canonical.
- No new reusable Core component is needed.
- No geometry/color/token redesign is required for this slice.

Tracker reconciliation:
- GitHub #475 remains open but future capability work is paused by owner direction.
- TNYX-264 remains In Progress for broader Custom Exercises.
- A Linear child was attempted for this polish slice but Linear rejected creation because the workspace has exceeded the free issue limit. GitHub #501 is therefore the implementation tracker; TNYX-264 receives durable comments and is not falsely given a child ID.

## In Scope

- Context-aware AppBar title for `customOnly=true`.
- Context-aware search hint.
- Context-aware filter tooltip and filter sheet title.
- Context-aware no-match message.
- Remove the redundant Custom Exercises section header only in focused mode.
- Add focused widget/router tests.
- Update canonical docs only if observed behavior text needs a small current-state clarification.

## Out of Scope

- New route or second Custom Exercises collection.
- Library IA/category redesign.
- Programs/Routines/default My Program.
- Exercise Detail, Favorites, Folders.
- Custom Exercise editor field/layout redesign.
- Supabase/schema/RLS/Storage/media changes.
- Catalog/unified Exercises behavior changes.

## Architecture

```text
Library Custom Exercises entry
  -> /workout/exercises?custom=true
    -> ExercisesPage(customOnly: true)
       -> same ExercisesController + CustomExercisesController
       -> same canonical Exercise/UserExerciseRepository
       -> presentation-only context labels
```

No ownership, persistence, route identity, domain model or repository contract changes.

## Implementation Plan

- [x] Make focused title/search/filter/no-match copy context-aware.
- [x] Let the filter sheet receive a caller-provided title while preserving its default.
- [x] Suppress the Custom Exercises section header only when the list itself is already focused.
- [x] Add focused widget tests covering title, search, filter sheet, no-match and section-header behavior.
- [x] Update app route test to assert Library → Custom Exercises visibly lands in the focused context.
- [ ] Run exact branch scope audit and GitHub CI/review gates.

## Validation

Pre-PR scope audit at branch head before PR creation:
- base `main@56617849be27cecded266b1f8b1f6853fe24430c`;
- branch `9 ahead / 0 behind`;
- exactly 6 changed paths: 2 `.ai/tasks` handoff files, 2 Workout production presentation files, 1 Workout widget test, 1 app route test;
- no Supabase/data/domain/editor-field/Library IA path touched;
- connector-side task/index Markdown scan: 0 trailing-whitespace lines, 0 conflict markers;
- semantic source re-audit confirmed unified `ExercisesPage.noMatchMessage` remains generic and `customNoMatchMessage` is used only in `customOnly=true` no-match state.

Connector-only session:
- use GitHub API compare for base/head ancestry, ahead/behind and complete changed-file scope;
- connector-side Markdown hygiene scan for task/docs;
- GitHub Flutter CI / attribution checks;
- Codex exact-head review;
- unresolved review thread audit.

Local Flutter commands and local `git diff --check` are not claimed unless a local worktree becomes available.

## Active Handoff

**Repository anchor:** `main@56617849be27cecded266b1f8b1f6853fe24430c`
**Branch:** `tnyx/issue-501-custom-exercises-focused-ui`
**Planning owner:** ChatGPT
**Implementation owner:** ChatGPT
**Review owner:** pending PR review
**Current state:** bounded presentation implementation and focused tests are on the branch. A pre-PR semantic audit caught and corrected one patch-order error where the Custom no-match copy had briefly landed in the unified branch; unified `ExercisesPage.noMatchMessage` is restored and `customNoMatchMessage` is now scoped only to `customOnly=true`. No route/domain/data/editor-field change.
**Next exact action:** run final parent/head scope + Markdown hygiene audit, open the focused PR, then use GitHub CI and exact-head Codex review as executable validation.
