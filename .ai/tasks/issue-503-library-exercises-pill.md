# GitHub #503 — Library Exercises pill alignment

**Status:** Ready for merge decision — PR #504 exact-head gates clean before final handoff commit
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
- Create Exercise and Exercises are separate standalone `TioCard` surfaces; no `TioGroupCard` on this Library action surface.
- Favorites/Folders remain capability-gated; when real, each joins as its own standalone card.
- No Custom-only product surface.

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
- `TioCard(padding: EdgeInsets.zero)` + `TioSettingsNavigationRow` is the reusable standalone action-card composition for this Library surface. `TioGroupCard` is explicitly not used here.

## In Scope

- Library full category strip for currently available real categories: Programs + Exercises.
- Programs remains default content and reuses the current Programs navigation capability; no inline Program/Routine expansion.
- Explicit selection collapses strip to circular X + selected pill.
- Selected Exercises content has exactly two current actions: Create Exercise and Exercises, each in its own standalone `TioCard`.
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
- Favorites/Folders behavior; only their future standalone-card presentation contract is recorded.
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
       ├─ standalone TioCard: Create Exercise → /workout/exercises?create=true
       │    └─ existing ExercisesPage + CustomExercisesController → editor
       └─ standalone TioCard: Exercises → /workout/exercises

Future capability-ready entries:
       ├─ standalone TioCard: Favorites
       └─ standalone TioCard(s): Folders

/workout/exercises
  └─ one canonical ExercisesPage
       ├─ catalog Exercises
       └─ user-created Exercises + Custom badge
```

No new Exercise model/repository/collection truth.

## Implementation Plan

- [x] Convert Library presentation to owner-approved category strip/selection state.
- [x] Keep only current-capability Programs content in default/Programs state.
- [x] Add selected Exercises actions: Create Exercise + Exercises.
- [x] Render each current Exercises action as its own standalone `TioCard` and remove `TioGroupCard` from this Library action surface.
- [x] Add one-shot `create=true` entry seam to existing ExercisesPage editor flow.
- [x] Remove Custom-only Library route/query and `customOnly` page behavior.
- [x] Update Library/router/Exercises tests.
- [x] Reconcile `docs/screens/library.md` and `docs/screens/exercise-search.md`.
- [x] Run exact pre-PR branch scope audit.
- [x] Hide Create Exercise when canonical durable user-Exercise repository capability is unavailable and cover the fail-closed route/widget states.
- [x] Complete exact-head GitHub CI + Codex review gates.

## Validation

Pre-PR connector audit at implementation checkpoint:
- base/current `main@56617849be27cecded266b1f8b1f6853fe24430c`;
- branch `11 ahead / 0 behind`;
- exactly 10 owned paths: 2 task/docs governance files, 2 canonical screen docs, 3 production Flutter files, 3 focused test files;
- no Supabase, repository/domain model, Program/Routine, Your Plan, Favorites/Folders, editor-field or Core contract file touched;
- connector-side scan across all changed text: 0 trailing-whitespace lines and 0 conflict markers;
- runtime/test source has 0 `customOnly`, `onCustomExercisesPressed`, or `_exercisesCustomParameter` references; the old Library Custom key remains only in a negative regression assertion;
- legacy `?custom=true` is covered as compatibility input and now leaves the canonical unified screen unfiltered;
- `CustomExercisesController.load()` was re-audited: it publishes ready via `notifyListeners()`, so `startCreating` opens the existing editor after durable source readiness without a second controller or route owner.

Codex review follow-up:
- Codex P2 on PR #504 correctly identified a fail-closed gap: when `userExerciseRepositoryProvider` is null, the Create card could navigate to `?create=true` but no editor could open.
- Fix contract: app composition derives an explicit create capability from the canonical nullable repository; Library hides **Create Exercise** when durable user-Exercise persistence is unavailable, while **Exercises** remains available.
- No in-memory persistence fallback, fake success, or duplicate repository is introduced.
- Normal configured production behavior remains the owner-approved standalone Create Exercise + Exercises cards.

CI review follow-up:
- exact head `d3acffba63d0a7d3af4953d8584b58f76e3ab46b` passed Flutter and Dart analyze, then Flutter tests reported 384 passed / 1 failed;
- the single failure was the new app-route create-flow assertion: default `find.byType(ExercisesPage)` skips the offstage owner route while `CustomExerciseEditorPage` is pushed above it;
- production flow was not failing: the canonical Exercises route stays mounted underneath the editor by normal Navigator semantics;
- app-route and feature-level create tests now use `find.byType(ExercisesPage, skipOffstage: false)` while the editor is open, then assert normal visible Exercises state after editor pop;
- no production source behavior changed for this CI repair.

Exact-head review gate before final handoff commit:
- PR head `3cee78162bef2f09baf1d9024e6f3c1deb9417e0`;
- branch `32 ahead / 0 behind`, exactly the same 10 owned paths;
- Flutter CI `Analyze and test`: PASS (bootstrap, Flutter analyze, Dart analyze, Flutter tests, Dart tests);
- Commit attribution guard: PASS;
- Attribution guard runner: PASS;
- Codex exact-head review: "Didn't find any major issues" on `3cee78162b`;
- unresolved review threads: 0;
- PR reports `mergeable=true` and `mergeable_state=clean`;
- GHAS: two runs failed before meaningful analysis with HTTP 402 monthly quota; no concrete security finding and no security pass claimed;
- current GitHub rulesets API returns `[]`; branch-protection endpoint is not readable by this integration (403). Current repository governance records identify GHAS as supplemental/non-required, and the PR remains mergeable/clean despite the GHAS failure. Required attribution evidence is green.

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
**Review owner:** GitHub PR #504 / Codex exact-head review
**Current state:** PR #504 is open and the production slice is validated at exact head `3cee78162bef2f09baf1d9024e6f3c1deb9417e0`: Library uses standalone `TioCard` actions (no `TioGroupCard`), Create Exercise fails closed when durable user-Exercise persistence is unavailable, canonical Exercises remains unified, Flutter/Dart analyze+tests pass, attribution passes, Codex exact-head review is clean, and unresolved review threads are 0. GHAS remains a supplemental HTTP 402 quota failure before analysis. The bounded production implementation remains unchanged: Library owns Programs/Exercises pill selection; default Programs reuses only the shipped Programs navigation capability; selected Exercises renders exactly Create Exercise + Exercises actions and no Exercise rows; Create Exercise uses `/workout/exercises?create=true` to open the existing editor once; normal `/workout/exercises` remains the unified catalog + user-created collection; Library Custom Exercises entry, `customOnly`, and the app-shell custom query contract are retired. Exact head `d3acffba...` passed both analyze phases but one new create-flow test failed because the assertion skipped the offstage canonical Exercises owner route while its editor route was on top; that test-only assumption is corrected on the branch. No production behavior, Program/Routine/Your Plan/Favorites/Folders/Supabase scope was added. GHAS remains an HTTP 402 quota failure before meaningful analysis.
**Next exact action:** after this final handoff-only commit, rerun exact-head CI/Codex checks; if clean, stop at the merge decision and wait for explicit `Go merge`.
