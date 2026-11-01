# Routine Notes Flutter UI Integration

Status: **In Progress — source-only, review-gated**

## 1. Discovery

### User Outcome

Show and manage authenticated user-owned Routine Notes from the existing Routine
Detail screen without changing the Notes persistence contract or unrelated Routine
layout.

### Success Criteria

- Routine-level Notes load through the existing `RoutineNotesRepository.read()`.
- Loading, empty, populated, retry and safe authorization/error states are visible.
- Authenticated users can create and delete Routine-scoped Notes.
- `RoutineId` scope, five-active-note limit and 500-character body limit are enforced.
- Session/account changes cannot display or mutate stale owner data.
- Existing Routine Detail behavior remains unchanged outside the approved Notes area.

### Scope

- `apps/features/workout`: Routine Notes controller/state and Routine Detail UI.
- `apps/app`: authenticated/session-safe Notes provider composition and injection.
- Focused controller/widget/integration tests.
- This task brief and active task index only for governance.

### Non-Goals

- Exercise-scoped Notes using `ExerciseRef`.
- Note edit/update, scope transfer or screenshot-specific pinned-row/swipe design.
- Supabase migrations, hosted deployment, gate activation or production Notes enablement.
- New repositories, RPCs, storage, schema, RLS/grant or infrastructure.

## 2. Codebase Exploration

### Verified Evidence

- `apps/shared/lib/src/workout/routine_note.dart` owns `RoutineNote` and `RoutineNoteScope`.
- `apps/features/workout/lib/src/domain/repositories/routine_notes_repository.dart` owns
  the read/create/delete command contracts and failure types.
- `apps/features/workout/lib/src/data/repositories/supabase_routine_notes_repository.dart`
  owns authenticated Data API read/mutation/reconciliation behavior.
- `apps/features/workout/lib/src/presentation/library/routines/routine_detail_page.dart`
  is the current read-only Routine Detail surface.
- `apps/app/lib/app/composition/workout_providers.dart` is the app-level repository/session
  composition boundary; `authSessionStateProvider` and `AuthSessionAuthenticated` are
  the session identity sources.
- `supabase/migrations/` contains the merged Notes contract and pre-Notes gate; hosted
  deployment remains separately unauthorized.
- Linear `TNYX-81` is `Backlog` for broader W4 and has owner-defined Notes rules; GitHub
  #716 is closed and PRs #717, #720 and #721 are merged.

### Existing Pattern To Follow

Use the current Routine Detail `StatefulWidget`/controller lifecycle and app-level
Riverpod providers. Use the public `package:tio_core/core.dart` components and
`TioInput.multiline`; do not create feature-local design tokens.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Routine-level Notes only | Approved by task scope | Avoids widening into Exercise Notes or sharing/copy behavior | Product Owner |
| Create/delete only | Approved by task scope | Existing repository supports it; edit/transfer remain deferred | Product Owner |
| Existing backend contract | Required | Preserve PR #717/#720 persistence and security boundaries | Implementation owner |

## 4. Architecture Design

### Chosen Approach

Add a session-bound app provider for `SupabaseRoutineNotesRepository`, a
Routine-scoped controller that owns read/create/delete state, and a focused Notes
section in `RoutineDetailPage`. The controller captures owner/session identity,
rejects stale completions, uses stable UUIDs for commands, and re-reads after
successful deletion/create as needed.

### Ownership And Data Flow

```text
Routine Detail UI
  -> RoutineNotesController (RoutineId + owner/session guard)
  -> RoutineNotesRepository
  -> SupabaseRoutineNotesGateway
  -> existing Notes table / mutation RPCs
```

### Alternative Rejected

Do not add direct Supabase calls in widgets, local note storage, a second repository,
new RPCs or a new schema/API surface.

### Failure And Accessibility States

Loading, empty, populated, retryable failure, forbidden/unauthorized failure,
quota rejection and unknown mutation outcome must be represented without exposing
private server messages or stale account data. Notes input uses the governed
multiline Core component and accessible labels/semantics.

## 5. Implementation Plan

- [x] Reconcile repository, tracker, merged PRs and current Notes source.
- [x] Create this focused task handoff and implementation branch.
- [x] Add session-safe Notes repository provider.
- [x] Add Routine Notes controller/state with create/delete.
- [x] Add Routine Detail Notes UI using Core components.
- [x] Add focused controller/widget/integration tests.
- [x] Run targeted Flutter validation and inspect exact changed-file scope.
- [x] Open focused PR; independent review remains pending; stop before merge.

## 6. Quality Review

### Validation Run

```text
PASS — G:\dev\flutter-sdk\bin\flutter.bat analyze (apps/features/workout)
PASS — G:\dev\flutter-sdk\bin\flutter.bat analyze (apps/app)
PASS — focused Routine Notes controller/widget tests
PASS — Routine Detail and existing Routine Notes repository tests
PASS — app workout route regression tests
PASS — git diff --check
PASS — review-remediation focused controller/widget tests (15 tests)
PASS — GitHub `Attribution guard`, `Commit attribution guard` and
`Check documentation diff hygiene` at validation head `b38162ca`; resolve the
mutable PR head live from GitHub.
```

### Acceptance Evidence

| Criterion | Changed behavior / file | Test or manual evidence + actual result | Observed SHA / environment | Remaining risk |
|---|---|---|---|---|
| Routine Notes read/create/delete UI | Implemented | Controller and widget tests PASS; existing repository tests PASS | Local Flutter SDK, current branch | Physical device and hosted deployment remain separate |
| Session/account isolation | Implemented | Stale read, auth guard, owner/scope, UUID, quota and unknown-outcome tests PASS | Local synthetic fixtures | Live auth/device lifecycle remains unverified |
| Existing Routine Detail regression | Implemented | Routine Detail suite and app workout route regression PASS | Local Flutter SDK, current branch | No unrelated layout change intended |

### Review Provenance

**Review source / link:** https://github.com/im-tnyx/tio-world/pull/722
**Reviewer / relation to implementer:** Codex and Copilot automated review comments;
 independent human approval from `im-tio` is still pending.
**Diff or commit SHA actually reviewed:** Current PR head before remediation:
 `f4a991963a426f293dae0337fec4a78d889ac740`.
**Last independently verifiable PR head before this handoff edit:** `b38162ca`
**Review result and finding IDs/dispositions:** Eight distinct actionable finding IDs
were identified. They represent six review themes because `4436062657` and
`4436083898` cover the same retryable-create failure, while `4436062664` and
`4436083867` cover the same unknown-create duplicate-prevention failure. The
remaining session, empty-state warning, same-screen refresh and lazy-header
findings are distinct. Fixes are implemented at the commits recorded below and
require exact-head CI plus independent re-review.
**Independent review?** Pending — automated comments are not approval.
**Limitations and unmet required gates:** Hosted migration, Notes activation,
physical Android/iOS QA and production release are out of scope.

### Review Findings And Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| `4436062657` | Review | Resolved on GitHub; independent approval pending | Retryable create failures left the composer unable to retry. | `a47cd9fa3c81eddf659fa7866c62364866c044e6` | Create failures now preserve a ready state and focused retry test passes. |
| `4436062664` | Review | Resolved on GitHub; independent approval pending | Unknown create outcomes could lose the original mutation identity. | `a47cd9fa3c81eddf659fa7866c62364866c044e6` | Pending create identity blocks duplicate mutation and is confirmed by read-back or remains retry-blocked; focused unknown-outcome tests pass. |
| `4436083844` | Review | Resolved on GitHub; independent approval pending | A session change could leave a private composer draft visible. | `a47cd9fa3c81eddf659fa7866c62364866c044e6` | Composer polls the session guard, redacts the draft and removes the modal; focused session-revocation test passes. |
| `4436083867` | Review | Resolved on GitHub; independent approval pending | Unknown create read-back could permit a duplicate retry. | `a47cd9fa3c81eddf659fa7866c62364866c044e6` | Same pending-create identity/read-back handling as above; focused duplicate-prevention test passes. |
| `4436083898` | Review | Resolved on GitHub; independent approval pending | Retryable create failure had no usable retry path. | `a47cd9fa3c81eddf659fa7866c62364866c044e6` | Same ready-state retry correction as `4436062657`; focused retry test passes. |
| `4436083913` | Review | Resolved on GitHub; independent approval pending | Unknown delete warnings were hidden when the list became empty. | `a47cd9fa3c81eddf659fa7866c62364866c044e6` | Action notices render before the empty state; focused empty-list warning test passes. |
| `4436135056` | P2 | Resolved on GitHub; independent approval pending | An unconfirmed create had no same-screen refresh/reconciliation action. | `a55728a90fd6974a89bc28ee9686405303adee12` | Unknown-save recovery now closes the composer and exposes a Notes `Refresh` action; controller and widget evidence passes. |
| `4436187860` | P2 | Resolved on GitHub; independent approval pending | Lazy Routine Detail headers could dispose the controller and lose pending mutation identity during scrolling. | `527129fb69b2b227caf824470badf392d17cb048` | `RoutineNotesSection` now opts into `AutomaticKeepAliveClientMixin`; lazy-list scroll regression test passes. |
| `4436255166` | P3 | Resolved on GitHub; independent approval pending | Review summary said six actionable threads while the table listed eight distinct finding IDs. | `6642f75ae0bdbba2e21b04439062ac48b24f8466` | Handoff now explains eight IDs grouped into six themes, preserving the duplicate-pair history. |

## 7. Final Handoff

### Changed Files

- `.ai/tasks/README.md`
- `.ai/tasks/routine-notes-flutter-ui-integration.md`
- `apps/app/lib/app/composition/workout_providers.dart`
- `apps/app/lib/app/routing/shell/shell_route.dart`
- `apps/features/workout/lib/src/presentation/library/library.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_detail_page.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_notes_controller.dart`
- `apps/features/workout/lib/src/presentation/library/routines/routine_notes_section.dart`
- `apps/features/workout/test/presentation/routine_notes_controller_test.dart`
- `apps/features/workout/test/presentation/routine_notes_section_test.dart`

### Actual Behavior

Routine Detail renders a session-bound Routine Notes section only when the app
has an authenticated, owner-verified session. The section loads through the
existing repository, supports empty/populated/retry states, creates normalized
1–500 rune Notes with a five-note limit and stable UUIDs, and deletes with the
persisted revision. Session changes suppress stale completions and the existing
repository remains responsible for authorization, conflicts and mutation
reconciliation.

### Known Limitations

This slice does not deploy the merged Notes migrations, activate the server gate,
enable production Notes, implement Exercise Notes, edit/transfer, sharing/copying,
or claim physical-device QA.

### Final Status

`REVIEW` — review-remediation source changes and local validation complete;
 exact-head CI, reviewer disposition and independent `im-tio` approval are still
 required. No hosted deployment, Notes activation or merge is authorized by this
 task.
