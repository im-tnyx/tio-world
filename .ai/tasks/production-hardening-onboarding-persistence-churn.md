# Production Hardening — Onboarding Persistence Churn

**Status:** In progress
**Primary owner:** Product Onboarding / production hardening #5 item 18
**Affected platforms:** Flutter phone app; storage-neutral onboarding persistence

## Global UI / Design-System Guardrail

No visual change is authorized by this task. Preserve current onboarding rendering, navigation, copy, geometry, and design-system behavior.

## 1. Discovery

### User Outcome

Keep unfinished onboarding durable and resume-safe without issuing redundant status writes or allowing overlapping draft saves to persist stale snapshots out of order.

### Success Criteria

- `OnboardingStatus.inProgress` is persisted only when the draft actually transitions into in-progress state, not on every field edit.
- Draft writes remain debounced for ordinary edits and immediate for navigation/branch transitions.
- Draft repository writes are serialized so an older request cannot complete after and overwrite a newer snapshot.
- A save failure retains the current in-memory draft and retries only after a later user change, preserving accepted O8D behavior.
- O8/O9 furthest-valid resume, edit-back, completion, retry, and idempotency contracts remain unchanged.

### Scope

- `apps/features/onboarding/lib/src/presentation/controllers/onboarding_controller.dart`
- focused persistence/controller tests only

### Non-Goals

- no Supabase schema/RLS/migration change;
- no `onboarding_drafts` ownership or payload format change;
- no navigation/flow/eligibility change;
- no completion ordering change;
- no UI/design change;
- no generic repository rewrite.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected:
  - `OnboardingController` at audit head `a76ec4502395296f6ee4b47c5564c6a8def088c8`;
  - `SupabaseOnboardingDraftRepository`;
  - `OnboardingStatusRepository`;
  - `onboarding_controller_draft_persistence_test.dart`;
  - O8D autosave/failure acceptance remains an authoritative regression boundary.
- Existing pattern to follow:
  - 300 ms debounce for ordinary draft edits;
  - immediate draft persistence for navigation/branch changes;
  - failed saves retain in-memory truth and retry on a later edit.
- Tests or validation already present:
  - hydration race protection;
  - immediate mode-selection save;
  - save failure preserves in-memory answers;
  - O8D failure recovery and historical-provenance acceptance.

### Reproducible Findings

1. `_markInProgress()` calls `_persistInProgress()` on every invocation even when `state.draft.status` is already `OnboardingStatus.inProgress`. Most field update methods call `_markInProgress()`, so ordinary editing creates redundant status-store writes.
2. `_scheduleDraftSave(immediate: true)` can start `_flushDraftSave()` while an older save is still in flight. The revision counters prevent some duplicate starts but do not serialize repository calls. If the older network request completes last, it can overwrite the newer row with stale draft state.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Persist in-progress status only on state transition | Made | Status is bootstrap metadata, not an edit journal | Onboarding |
| Serialize draft writes at controller boundary | Made | Repository is storage-neutral and should receive ordered semantic snapshots | Onboarding |
| Preserve debounce/immediate call sites | Made | Existing resume/navigation durability semantics are already accepted | O8/O9 |
| Do not auto-loop after save failure | Made | O8D requires retry on later edit, not uncontrolled background retry | O8D |

## 4. Architecture Design

### Chosen Approach

Keep the current scheduling semantics but replace parallel `_flushDraftSave(revision)` calls with a single drain worker. The worker saves the latest pending revision, then checks whether a newer revision arrived while it was in flight. It continues serially on success. On failure it exits and leaves the pending revision unsaved until a later `_scheduleDraftSave()` call restarts the worker.

### Ownership and Data Flow

```text
Onboarding UI
  -> OnboardingController
     -> transition-only OnboardingStatusRepository.write(inProgress)
     -> debounce/immediate draft scheduler
        -> single serialized draft-save worker
           -> OnboardingDraftRepository
              -> Supabase onboarding_drafts
```

### Alternative Rejected

- repository-level last-write-wins timestamps/revisions: would expand storage contract/schema concerns unnecessarily;
- removing immediate saves: would weaken accepted resume checkpoints;
- automatic retry loop after failure: could spin under outage and changes O8D semantics.

### Failure and Accessibility States

No visual/accessibility state changes. Draft save failure remains non-destructive and silent at this boundary, with in-memory state retained for the next edit retry.

## 5. Implementation Plan

- [ ] gate `_persistInProgress()` behind the actual local transition to `inProgress`;
- [ ] serialize draft saves with one in-flight drain worker;
- [ ] preserve 300 ms debounce and immediate navigation saves;
- [ ] add regression proving repeated edits produce one in-progress status write;
- [ ] add regression proving a newer immediate snapshot cannot overlap an older save;
- [ ] keep existing save-failure/recovery tests green;
- [ ] run focused/full Flutter/Dart + Android exact-SHA CI before freeze.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings and Resolution

Audit found two current-head persistence issues. Implementation is bounded to controller scheduling/status writes.

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Pending.

### Known Limitations

No offline queue or cross-device merge is introduced; this task only orders writes generated by one live controller instance.

### Final Status

`PARTIAL`
