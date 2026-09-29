# My Programs Library collection & create foundation

**Status:** Ready
**Primary owner:** `apps/features/workout` Programs capability + app composition/routing
**Affected platforms:** Flutter phone only; existing Supabase Program persistence is consumed, not changed

## Owner Approval and Scope Boundary

**Trigger:** New visible UI/UX product slice
**Approval status:** `AWAITING OWNER APPROVAL`
**Approval evidence:** Owner requested the audit and planning lock after confirming Library currently has no Program/Routine creation option. No visible UI implementation has been approved yet.
**Approved planning boundary:** Audit and lock the smallest user-visible Program capability that can ship before Routine composition.
**Explicit non-changes:** No Routine create/edit UI, no Routine composition, no `SetPrescription`, no Exercise picker, no Program detail/builder, no post-create rename flow, no delete/archive, no images/media, no TrainingPlan/scheduling, no Explore/adoption/provenance UI, no Supabase migration/table/column/RLS/grant change, no live data mutation, and no W1A3 source change.

## Active Handoff

**Planning owner:** Workout architecture audit
**Implementation owner:** None
**Review owner:** Unassigned
**Implementation ownership state:** Not started
**Repository state last verified:** 2026-09-29, `main@9652e63a64ea11ad75505eb912fb02a9aa77fef6`
**Planning branch:** `docs/my-programs-library-create-plan`
**Tracker:** TNYX-267 (W6B) + TNYX-81 (W4) context. No new Linear child can currently be created because the workspace free issue limit is exceeded.
**Current implementation state:** Program domain and live persistence exist, but there is no Programs route/page/controller/provider wiring and Library renders only Exercises.
**Current blocker:** Visible UI shape requires owner approval before source changes.
**Next exact action:** Owner approves or adjusts the proposed minimal UI contract below; then create a focused implementation branch from fresh `main` and update this brief to In progress.

## 1. Discovery

### User Outcome

From Workout Library, a signed-in user can reach their persisted Programs, create a new empty Program with a visible generated non-blank name, optionally rename that proposed name before confirmation, and immediately see the confirmed Program in their collection.

This first slice deliberately does not pretend Routine creation is ready.

### Verified Runtime Evidence

- `LibraryPage` currently renders only one ready section: Exercises.
- `AppRoutes` has Library and Exercises only; no Program route exists.
- App Workout composition currently wires Workout Profile/Targets repositories only; no Program repository provider exists.
- `ProgramRepository` already supports `list()`, `create(Program)`, and `rename(...)`.
- `SupabaseProgramRepository` persists only `id`, `user_id`, and `name` to live `public.user_workout_programs`.
- Program persistence and owner RLS/grants are already deployed and independently verified.
- Canonical `Program` is intentionally minimal: `ProgramId + non-blank name`.
- ADR-0015 allows a newly created Program to contain zero Routines.
- `docs/screens/library.md` capability-gates Programs until the capability is real.
- `docs/screens/programs.md` defines generated/renamable initial naming but the route/screen is still planned only.
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

## 3. Proposed UI Contract — Requires Owner Approval

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

- [ ] Re-read fresh main, AGENTS, active task and tracker state immediately before source edits.
- [ ] Obtain explicit owner approval for the proposed visible UI contract.
- [ ] Update this task to In progress and record the approved UI boundary.
- [ ] Add canonical Program repository composition without a production in-memory durability fallback.
- [ ] Add feature-owned Program ID generation.
- [ ] Add Programs state/controller with load/create/error/retry behavior.
- [ ] Add one canonical Programs route and app navigation callback.
- [ ] Add Programs row to Library only as part of the now-real capability.
- [ ] Add Programs collection screen.
- [ ] Add generated-name Create Program editor.
- [ ] Add focused controller/widget/router/composition tests.
- [ ] Run applicable Flutter analyze/tests and exact-head PR review.
- [ ] Update canonical Library/Programs docs only for behavior actually shipped.

## 7. Acceptance

- [ ] Library exposes a working Programs entry, not a placeholder.
- [ ] Programs screen reads persisted user Programs through `ProgramRepository`.
- [ ] loading, empty, load-failure/retry and create-failure states are real.
- [ ] create starts with a visible non-blank generated Program name and permits edit before confirmation.
- [ ] confirmed create persists exactly one Program and updates the collection.
- [ ] no fake in-memory production success path exists.
- [ ] no Program row has a dead or fake detail action.
- [ ] no standalone Routines section or top-level Create Routine exists.
- [ ] no W1A3/Routine composition/Exercise picker/persistence-schema scope is introduced.
- [ ] TNYX-81/TNYX-267 remain incomplete after this bounded slice.

## 8. Quality Review

### Planning validation

Read-only audit reconciled fresh source, canonical docs, ADR-0015, W1A3 handoff, TNYX-81 and TNYX-267. No runtime/source/Supabase mutation was performed.

### Open findings

| ID | Severity | Status | Finding | Follow-up |
|---|---|---|---|---|
| MP-P1 | Planning | Open | TNYX-81's broad W3 parent blocker is wider than minimal Program creation requires | Do not mutate relation in this planning PR; record bounded early slice under existing parents |
| MP-P2 | Planning | Open | Linear workspace free issue limit prevents focused child creation | Use TNYX-267/TNYX-81 comments + this repo task until capacity exists |
| MP-P3 | Product/UI | Needs owner decision | Exact Programs row copy/icon, create affordance placement and empty-state composition are visible UI decisions | Owner approves/adjusts before implementation |

## 9. Final Handoff

### Actual Behavior

No runtime behavior changes in this planning slice.

### Known Limitations

Routine creation remains unavailable until its canonical composition and builder slices land. This is intentional and must not be hidden behind a fake action.

### Final Status

`READY / AWAITING OWNER APPROVAL`
