# My Programs Library collection & create foundation

**Status:** In review
**Primary owner:** `apps/features/workout` Programs capability + app composition/routing
**Affected platforms:** Flutter phone only; existing Supabase Program persistence is consumed, not changed

## Owner Approval and Scope Boundary

**Trigger:** New visible UI/UX product slice
**Approval status:** `APPROVED — 2026-09-29`
**Approval evidence:** After PR #468 merged, the owner explicitly approved the proposed Programs row, Programs collection screen, and Create Program editor by replying `go` on 2026-09-29.
**Approved implementation boundary:** Add the Programs row above Exercises; a persisted Programs collection; AppBar Create (+); an empty-state Create Program action; generated editable initial naming such as `Program 1`; real loading/load-failure-retry/create-failure states; display-only Program rows; existing live Program persistence only in production.
**Explicit non-changes:** No Routine create/edit UI, no Routine composition, no `SetPrescription`, no Exercise picker, no Program detail/builder, no post-create rename flow, no delete/archive, no images/media, no TrainingPlan/scheduling, no Explore/adoption/provenance UI, no Supabase migration/table/column/RLS/grant/deployment change, and no W1A3 source change. The approved user action does persist a new user-owned Program through the already-live repository/table; that runtime write is the purpose of this slice, not an infrastructure mutation.

## Active Handoff

**Planning owner:** Workout architecture audit
**Implementation owner:** Completed on `tnyx/tnyx-267-programs-library-create`
**Review owner:** Manual repository review while Codex code-review quota is exhausted
**Implementation ownership state:** Complete
**Repository state last verified:** 2026-09-29, `main@9244f503fc48e9ab2caefe7f3778469225896cec`
**Implementation branch:** `tnyx/tnyx-267-programs-library-create`
**Tracker:** TNYX-267 (W6B) + TNYX-81 (W4) context. No focused child was created for this bounded slice; TNYX-267 comments plus this repository task are the execution record.
**Current implementation state:** The bounded Program-only slice is implemented in PR #469. Library exposes Programs above Exercises; `/workout/programs` loads the persisted collection through the canonical Program repository; Create Program uses generated editable naming; loading/empty/retry/create-failure states are real; Program rows remain display-only; production has no in-memory Program durability fallback.
**Current blocker:** Manual runtime review found MP-R4 and its retry-name follow-up MP-R5 in ambiguous create reconciliation. Both source fixes and regression tests are included in the current head and require exact-head repository revalidation. Automated Codex review remains unavailable because the repository bot reports exhausted code-review usage limits. GitHub Advanced Security continues to fail before analysis on the known unsupported-model infrastructure error and is non-required.
**Next exact action:** Complete exact-head repository validation for the MP-R4 runtime fix, then triage any new review/check finding before owner merge approval.

## 1. Discovery

### User Outcome

From Workout Library, a signed-in user can reach their persisted Programs, create a new empty Program with a visible generated non-blank name, optionally rename that proposed name before confirmation, and immediately see the confirmed Program in their collection.

This first slice deliberately does not pretend Routine creation is ready.

### Pre-implementation Discovery Evidence

- At discovery time, `LibraryPage` rendered only one ready section: Exercises.
- At discovery time, `AppRoutes` had Library and Exercises only; no Program route existed.
- At discovery time, app Workout composition wired Workout Profile/Targets repositories only; no Program repository provider existed.
- `ProgramRepository` already supports `list()`, `create(Program)`, and `rename(...)`.
- `SupabaseProgramRepository` persists only `id`, `user_id`, and `name` to live `public.user_workout_programs`.
- Program persistence and owner RLS/grants are already deployed and independently verified.
- Canonical `Program` is intentionally minimal: `ProgramId + non-blank name`.
- ADR-0015 allows a newly created Program to contain zero Routines.
- At discovery time, `docs/screens/library.md` capability-gated Programs until the capability became real.
- At discovery time, `docs/screens/programs.md` defined generated/renamable initial naming while the route/screen was still planned only.
- W1A3 remains `Ready / AWAITING OWNER APPROVAL`; this Programs slice must not absorb Routine composition.
- Dedicated Exercises browse/search/filter is shipped; Exercise picker mode is still planned and therefore cannot be silently pulled into this slice.

## 2. Dependency Reconciliation

### Current tracker shape

- TNYX-267 W6B is blocked by TNYX-81 W4.
- TNYX-81 W4 is blocked by the broad TNYX-80 W3 parent and TNYX-78 W1.
- Core W3A Exercise catalog/screen work is already Done; W3B Detail and W3C/W3D/W3E Favorites/Custom/Folders remain Backlog.

### Audit finding

The full W4/W6B outcome still depends on Routine composition and later Exercise capabilities, but **minimal empty Program collection/create does not**:

```text
ProgramId + Program(name)
+ ProgramRepository.list/create
+ live user_workout_programs
+ Library route
= sufficient for minimal My Programs collection/create
```

Therefore no Linear dependency relation is mutated in this planning slice. The implementation should be treated as a bounded early W6B/W4 Program-only slice under the existing parents, not as evidence that TNYX-81 or TNYX-267 is complete.

## 3. Approved UI Contract

### Library root

Add the Programs capability as a real navigation row only when this slice lands. Keep it above Exercises, matching the documented target section order.

Proposed row:

```text
Programs
Create and manage programs
>```

Exact supporting copy/icon remains owner-approved UI detail; no standalone Routines row is permitted.

### Programs collection screen

Proposed shape:

```text
<AppBar: back | Programs | Create (+)>

loading → standard centered progress
load failure → clear message + Retry
empty → neutral empty state + Create Program action
ready → persisted Program names in one simple collection list
```

Program rows are display-only in this first slice. No dead tap target and no fake Program-detail destination is introduced.

### Create Program editor

Reuse the existing `showTioEditorSheet` + `TioInput` pattern rather than inventing a new dialog primitive.

On open:
- prefill a generated non-blank name such as `Program 1`;
- user may edit it before confirmation;
- blank/whitespace-only values are rejected through canonical `Program` validation;
- Cancel performs no write;
- Create writes exactly one user Program;
- success closes the editor and refreshes/updates the collection;
- failure remains visible and must never show fake success.

Exact naming-collision algorithm is not frozen by this brief. It must be deterministic and covered by tests; display-name uniqueness is not a database invariant.

## 4. Architecture Design

### Ownership

```text
apps/app composition
  -> supplies canonical ProgramRepository
  -> supplies route/navigation callbacks

apps/features/workout
  -> Programs controller/state
  -> Programs collection UI
  -> Program ID generation use case
  -> Library Programs callback/row

apps/shared
  -> existing ProgramId + Program only
```

Do not move Program presentation into app shell and do not create `LibraryProgram`.

### Repository composition

Production must use the existing Supabase Program repository when this signed-in capability is available. **Do not silently create an in-memory Program persistence fallback** for production UI, because a user-visible successful create that disappears later would violate durable Program truth. Tests should inject a fake repository at the feature/controller boundary.

The implementation audit must choose the smallest app-composition behavior for transient missing Supabase client/session state and surface an honest unavailable/error state rather than fake persistence.

### Program ID generation

The current repository requires a client-generated canonical UUID ProgramId.

Follow the repo's injectable UUID-generator precedent rather than generating IDs inside a widget. Preferred direction: a small feature-owned Program ID generator/use case with an injectable UUID-v4 function. Do not create a generic cross-product ID framework solely for this slice.

### Controller

One Programs controller/state should own:
- initial load;
- ready immutable Program list;
- load failure + retry;
- create-in-flight state;
- create failure;
- successful canonical list update/refresh.

The page should not call Supabase directly.

### Navigation

Library continues to receive navigation callbacks from app composition. The Programs capability should receive one canonical Workout-owned route. Exact path naming is finalized in the implementation audit against existing sibling-route conventions; Library must not become the domain owner merely through URL nesting.

## 5. Explicit Non-Goals

- Program detail page/builder;
- any Program row tap destination;
- post-create rename management;
- Routine list/create/rename UI;
- top-level Create Routine;
- Routine composition or `SetPrescription`;
- Exercise picker mode;
- W3B/C/D/E;
- Program delete/archive;
- Program image/media/Storage;
- TrainingPlan scheduling/start/follow state;
- Tio/AI/Coach Program adoption/provenance;
- schema/RLS/grant changes;
- live migration/deployment.

## 6. Implementation Plan

- [x] Re-read fresh main, AGENTS, active task and tracker state immediately before source edits.
- [x] Obtain explicit owner approval for the proposed visible UI contract.
- [x] Update this task to In progress and record the approved UI boundary.
- [x] Add canonical Program repository composition without a production in-memory durability fallback.
- [x] Add feature-owned Program ID generation.
- [x] Add Programs state/controller with load/create/error/retry behavior.
- [x] Add one canonical Programs route and app navigation callback.
- [x] Add Programs row to Library only as part of the now-real capability.
- [x] Add Programs collection screen.
- [x] Add generated-name Create Program editor.
- [x] Add focused controller/widget/router/composition tests.
- [x] Run applicable Flutter analyze/tests on runtime head `d5334c987674dac644799649a7dff59db1a74410`; manual PR review found only the stale-handoff issue recorded below.
- [x] Update canonical Library/Programs docs only for behavior actually shipped.
- [ ] Revalidate the current exact head after the MP-R4 runtime correction.

## 7. Acceptance

- [x] Library exposes a working Programs entry, not a placeholder.
- [x] Programs screen reads persisted user Programs through `ProgramRepository`.
- [x] loading, empty, load-failure/retry and create-failure states are real.
- [x] create starts with a visible non-blank generated Program name and permits edit before confirmation.
- [x] confirmed create persists exactly one Program and updates the collection.
- [x] no fake in-memory production success path exists.
- [x] no Program row has a dead or fake detail action.
- [x] no standalone Routines section or top-level Create Routine exists.
- [x] no W1A3/Routine composition/Exercise picker/persistence-schema scope is introduced.
- [x] TNYX-81/TNYX-267 remain incomplete after this bounded slice.

## 8. Quality Review

### Planning validation

Read-only audit reconciled fresh source, canonical docs, ADR-0015, W1A3 handoff, TNYX-81 and TNYX-267. No runtime/source/Supabase mutation was performed.

### Open findings

| ID | Severity | Status | Finding | Follow-up |
|---|---|---|---|---|
| MP-P1 | Planning | Deferred | TNYX-81's broad W3 parent blocker is wider than minimal Program creation requires | Existing dependency relation intentionally remains unchanged; this slice does not claim full W4/W6B completion |
| MP-P2 | Planning | Deferred | Linear workspace free issue limit prevented focused child creation during planning | TNYX-267 + this repository task remain the bounded execution record |
| MP-P3 | Product/UI | Resolved | Exact Programs row, AppBar Create (+), empty state and Create Program editor were owner-approved on 2026-09-29 | Implemented without widening into Routine/detail/media/TrainingPlan work |
| MP-R1 | P2 | Resolved | Manual PR review found this active handoff still described the pre-implementation state, unchecked implementation/acceptance, and “no runtime behavior changes” after the feature had shipped on the branch | Reconciled this brief to PR #469 runtime behavior, exact validated runtime head `d5334c987674dac644799649a7dff59db1a74410`, CI/security-check classification and current review state |
| MP-R2 | P2 | Resolved | Scope wording still said `no live data mutation` even though the approved feature's core behavior is persisting a new user-owned Program | Clarified that schema/RLS/grant/deployment changes remain out of scope while the existing live Program repository write is explicitly in scope |
| MP-R3 | P2 | Resolved | Historical discovery bullets were still labeled as current verified runtime evidence, and the handoff next-action text referred to an already-pushed correction | Re-labeled those bullets as pre-implementation discovery evidence and made the active next action current-head revalidation |
| MP-R4 | P1 | Resolved pending exact-head validation | A failed `create()` response could be transport-ambiguous: the row may already be durable, but the controller generated a fresh UUID on retry, allowing one user action to create duplicate Programs | Retain the pending client-generated `ProgramId` across retries and reconcile the canonical list after a create error; if that ID already exists, treat the durable write as success. Added regressions for ambiguous-after-write reconciliation and same-ID retry |
| MP-R5 | P1 | Resolved pending exact-head validation | After MP-R4, a rarer path remained: if the first durable write lost its response, reconciliation read also failed, and the user edited the name before retry, the stable ID prevented duplicates but could reconcile success with the old durable name | When the retained ID exists with different text, use the existing repository `rename()` boundary to reconcile the latest confirmed name on that same identity, then re-read canonical state. Added a regression covering response loss + failed reconciliation + edited retry |

## 9. Final Handoff

### Actual Behavior

- Library now shows a real `Programs` row above Exercises.
- Programs opens the canonical `/workout/programs` route without bottom navigation.
- The page loads persisted user Programs through `ProgramRepository`; app composition uses `SupabaseProgramRepository` when durable Supabase is available and fails closed when it is not.
- Empty users see `Create Program`; the AppBar also exposes Create (+).
- Create starts with a generated non-blank name such as `Program 1`, permits editing before confirmation, and preserves one client-generated `ProgramId` across retries. After a create error it reconciles the canonical list by that ID, so a durable-but-response-lost write is treated as success instead of creating a duplicate on retry. If the user changes the name after an unresolved ambiguous attempt, the latest confirmed name is reconciled onto that same durable identity through the existing repository rename boundary.
- Existing Program rows are display-only. No fake Program detail or Routine action exists.

### Validation Evidence

Pre-MP-R4 runtime head `d5334c987674dac644799649a7dff59db1a74410` on PR #469:
- `Analyze Flutter packages`: PASS
- `Analyze Dart packages`: PASS
- `Test Flutter packages`: PASS
- `Test Dart packages`: PASS
- required `Commit attribution guard`: PASS
- supplemental/non-required `github-advanced-security`: infrastructure failure before analysis because the requested `claude-opus-5[ReasoningEffort=medium]` model is unsupported; no repository security finding was produced

Automated Codex review is currently unavailable because the Codex connector reports exhausted code-review usage limits. Manual Codex-style review resolved MP-R1/MP-R2/MP-R3 in the handoff text, then found MP-R4 in runtime create retry semantics and MP-R5 in the edited-name retry edge of that reconciliation. MP-R4/MP-R5 are fixed in source with regression tests and are pending exact-head validation.

### Known Limitations

Routine creation, Program detail/builder, post-create rename management, delete/archive, media, provenance/adoption and TrainingPlan scheduling remain unavailable by design. TNYX-81 and the full TNYX-267 outcome remain incomplete.

### Final Status

`IN REVIEW / IMPLEMENTATION COMPLETE / HANDOFF-ONLY EXACT-HEAD REVALIDATION PENDING`
