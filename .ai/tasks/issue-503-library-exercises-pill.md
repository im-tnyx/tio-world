# GitHub #503 — Library Exercises pill alignment

**Status:** In progress
**Primary owner:** `apps/features/workout` presentation + `apps/app` route composition
**Affected platform:** Flutter phone UI
**GitHub tracker:** #503
**Linear planning:** TNYX-264 / TNYX-83 / TNYX-267 (dedicated child unavailable because the Linear workspace free issue limit was already reached)

## Owner Approval

Approved through the 2026-10-05 Library clarification sequence and the owner's `next go`.

Final approved Exercises category behavior:

```text
Library full strip
[ Programs ] [ Exercises ]

tap Exercises
→ [ X ] [ Exercises selected ]

Create Exercise
Exercises
```

No exercise rows render inside Library.

- Create Exercise opens the existing canonical user-created Exercise create flow.
- Exercises opens the canonical `/workout/exercises` screen.
- Catalog + user-created Exercises compose together only on that canonical screen.
- User-created rows retain the presentation-only `Custom` tag.
- No Favorite/Custom/Folder landing rows and no Custom-only product surface.

## Verified Baseline

Repository anchor: `main@56617849be27cecded266b1f8b1f6853fe24430c`.

Current runtime:
- Library is a standalone nested screen with Programs / Exercises / Custom Exercises navigation rows.
- Library top-bar search pushes `/workout/exercises?search=true`.
- Exercises pushes canonical `/workout/exercises`.
- Custom Exercises pushes `/workout/exercises?custom=true`.
- `ExercisesPage(customOnly: true)` is a stale focused product mode.
- canonical Exercises already composes catalog rows + active user-created rows and marks custom rows with the `Custom` badge.
- current Programs capability is a persisted Programs collection/create route; Program detail/Routine work is not ready.
- Your Plan is capability/data-gated and must remain hidden.
- GitHub #501 / PR #502 were based on the stale Custom-only direction; #502 was closed without merge and #501 closed not-planned.

Core audit:
- no reusable Tio pill/segment component currently exists.
- feature-local pill composition may consume governed `TioColors`, `TioRadius`, `TioSize`, spacing and typography without introducing a screen-specific token catalog.
- `TioGroupCard` + `TioSettingsNavigationRow` remain the reusable action-row surface.

## In Scope

- Library full category strip for currently available real categories: Programs + Exercises.
- Programs remains default content and reuses the current Programs navigation capability; no inline Program/Routine expansion.
- Explicit selection collapses strip to circular X + selected pill.
- Selected Exercises content has exactly two actions: Create Exercise and Exercises.
- Create Exercise enters existing W3D create flow through the canonical Exercises capability.
- Exercises opens canonical unified `/workout/exercises`.
- remove Library Custom Exercises row and app-shell `?custom=true` handoff.
- retire `customOnly` from `ExercisesPage` runtime API and tests.
- preserve Library top-bar search until the separately gated top-bar + / Routine flow is ready.
- focused route/widget tests and canonical Library/Exercise docs reconciliation.

## Out of Scope

- Program detail, inline Program Routine rendering, W4/W6B expansion.
- Create Routine/default My Program.
- top-bar +.
- Your Plan/TrainingPlan.
- Favorites/Folders.
- Exercise Detail.
- custom editor field/layout redesign.
- Supabase/schema/RLS/Storage/media changes.

## Architecture

```text
LibraryPage
  owns presentation-only selected category state
  ├─ Programs content
  │    └─ existing onProgramsPressed → /workout/programs
  └─ Exercises content
       ├─ Create Exercise → /workout/exercises?create=true
       │    └─ existing ExercisesPage + CustomExercisesController → editor
       └─ Exercises → /workout/exercises

/workout/exercises
  └─ one canonical ExercisesPage
       ├─ catalog Exercises
       └─ user-created Exercises + Custom badge
```

No new Exercise model/repository/collection truth.

## Implementation Plan

- [ ] Convert Library presentation to owner-approved category strip/selection state.
- [ ] Keep only current-capability Programs content in default/Programs state.
- [ ] Add selected Exercises actions: Create Exercise + Exercises.
- [ ] Add one-shot `create=true` entry seam to existing ExercisesPage editor flow.
- [ ] Remove Custom-only Library route/query and `customOnly` page behavior.
- [ ] Update Library/router/Exercises tests.
- [ ] Reconcile `docs/screens/library.md` and `docs/screens/exercise-search.md`.
- [ ] Run exact branch scope + CI + Codex review gates.

## Validation

Connector-only session:
- GitHub compare for exact base/head scope;
- connector-side Markdown hygiene;
- GitHub Flutter CI/analyze/tests;
- attribution checks;
- exact-head Codex review;
- unresolved-thread audit.

Local Flutter commands / local `git diff --check` are not claimed unless a local worktree becomes available.

## Active Handoff

**Repository anchor:** `main@56617849be27cecded266b1f8b1f6853fe24430c`
**Branch:** `tnyx/issue-503-library-exercises-pill`
**Implementation owner:** ChatGPT
**Review owner:** pending PR
**Current state:** owner direction reconciled; #502 closed without merge; #503 branch created; no source change yet.
**Next exact action:** implement the bounded Library pill/actions + canonical create seam + stale customOnly retirement, then audit scope before PR.
