# Onboarding Back Navigation Resume Checkpoint

**Status:** In progress — implementation and automated validation green; real-device acceptance pending
**Tracking:** GitHub Issue #13 / PR #36
**Primary owner:** `apps/features/onboarding` + `apps/app`
**Affected platforms:** Flutter phone app

## 1. Discovery

### User Outcome

Allow users to navigate backward through Product Onboarding to review or edit earlier answers, including reaching Profile Name and logging out, without permanently rewinding the durable resume point for the next authenticated session.

### Success Criteria

- Back navigation changes only the currently visible onboarding step.
- Forward progress advances a durable/furthest valid resume checkpoint.
- Back navigation never lowers that resume checkpoint.
- Profile Name remains the authenticated root Back/logout boundary.
- Logout preserves onboarding data and the durable resume checkpoint.
- Same-account login resumes at the furthest still-valid checkpoint, not the last screen reached by Back.
- After resume, the user may Back again to review/edit earlier steps.
- Editing an earlier answer persists normally; if it invalidates downstream flow, resume reconciles to the furthest still-valid checkpoint.
- Visible Back and Android/system Back retain parity.
- No UI redesign or new visual component is introduced.

### Acceptance Example

```text
Name -> Gender -> Goal -> DOB -> ... -> Activity
resume checkpoint = Activity

Activity -> Back -> ... -> Name
visible step = Name
resume checkpoint = Activity

Name -> Back -> logout confirmation -> Log out -> Welcome
same account login -> Activity
Activity -> Back -> earlier steps remains allowed
```

## 2. Codebase Exploration

### Verified Evidence

- `.ai/tasks/onboarding-auth-draft-handoff.md` already requires same-account draft resume after root logout but did not distinguish visible Back cursor from durable resume checkpoint.
- `OnboardingController._moveToProfileStep`, `_moveToWorkoutStep`, `_moveToTargetStep`, and `_moveTo` intentionally keep updating the visible draft cursor so Back remains fully navigable/editable.
- `hydrateDraft()` rebuilds initial state from the persisted draft cursor, so persistence ownership is the correct place to prevent Back from becoming a durable rewind.
- `AuthAwareOnboardingDraftRepository` already owns authenticated/local/remote draft routing, while the production provider can safely compose an additional persistence decorator around the existing Google-identity/auth-aware chain.
- Root logout does not clear the user-bound onboarding draft and remains unchanged as a non-discard exit.
- The existing snapshot schema can remain unchanged; the furthest checkpoint can be represented by the same stable current-step fields in the last successfully persisted snapshot while the controller keeps a separate in-memory visible cursor.

### Existing Pattern to Follow

Keep typed stable step IDs and repository-owned draft persistence. Separate navigation cursor semantics from durable resume semantics without adding route-level state or a new persisted schema shape.

## 3. Clarification

### Decisions Made

| Decision | Status | Rationale |
|---|---|---|
| Back remains fully navigable/editable | Approved | User may need to review earlier answers |
| Back must not rewind next-login resume | Approved | Back is navigation, not progress reset |
| Name remains logout boundary | Approved | Existing root-exit UX is accepted |
| Same-account login resumes furthest valid progress | Approved | Matches expected continuation behavior |
| No draft deletion on logout | Approved | Existing persistence contract remains correct |
| Preserve existing snapshot schema | Implemented | A repository decorator can retain the furthest valid stable cursor without migration risk |

## 4. Architecture Design

### Chosen Approach

Maintain two concepts without changing the serialized schema:

```text
controller draft cursor
= current visible screen

last successfully persisted draft cursor
= durable resume checkpoint
```

Production persistence is composed as:

```text
OnboardingController
-> ResumePreservingOnboardingDraftRepository
   -> GoogleIdentityOnboardingDraftRepository
      -> AuthAwareOnboardingDraftRepository
         -> secure local / user-owned remote draft
```

`PreserveOnboardingResumeCheckpointUseCase` compares the incoming visible cursor with the previous persisted cursor, keeps the furthest cursor that still belongs to the current flow, and validates every prerequisite step before that cursor against the latest edited data. If an earlier edit invalidates downstream progress, persistence clamps to that earliest invalid prerequisite.

The controller itself is intentionally unchanged for Back semantics, so the user can still move from Activity to Name and edit earlier fields. Hydration/login naturally opens the persisted checkpoint because the existing controller already restores the repository snapshot cursor.

Confirmed root logout performs one explicit awaited repository save before sign-out. This drains ordered draft saves and prevents the Back-autosave/logout race from losing the latest edited values or checkpoint.

### Failure / Compatibility

- Existing persisted drafts require no schema migration and remain readable.
- The first loaded snapshot becomes the resume baseline for old/current drafts.
- Flow-plan changes reconcile an obsolete persisted cursor to the current valid flow.
- Earlier invalid edits clamp the durable cursor rather than resuming into an invalid downstream screen.
- A persistence failure does not trap the user during confirmed logout; the last successfully persisted checkpoint remains the safe fallback.

## 5. Implementation Plan

- [x] Audit draft model/serialization and repository compatibility path.
- [x] Preserve the durable checkpoint without changing the persisted schema.
- [x] Keep the furthest valid persisted cursor when forward progress advances.
- [x] Keep Back navigation persistence from lowering the durable cursor.
- [x] Hydrate/resume from the persisted checkpoint while preserving earlier edited values.
- [x] Add domain/repository regressions for Activity -> Back -> Name -> next session -> Activity.
- [x] Add invalidated-earlier-data and changed-flow reconciliation regressions.
- [x] Keep visible/system Back dispatch unchanged and add logout-save ordering coverage.
- [x] Run latest PR automated CI.
- [ ] Complete real-device acceptance.

## 6. Quality Review

### Validation Run

Implementation head `83fb0171183af90dde163b57dae61392f1ac106f` passed GitHub Actions Flutter CI **#923**, run `32285931528`:

```text
Bootstrap workspace      PASS
Analyze Flutter packages PASS
Analyze Dart packages    PASS
Test Flutter packages    PASS
Test Dart packages       PASS
```

After this task evidence was recorded, latest PR head `8a33e170cb019518def290dd5658a692e77d72ba` also passed Flutter CI **#924**, run `32286508843`, with the same full analyze/test matrix green.

### Review Findings

- A new serialized resume-checkpoint field was not necessary. Reusing the existing stable cursor fields in the persisted snapshot keeps old drafts compatible and makes the visible-vs-durable separation an explicit persistence concern.
- Draft saves are serialized by `ResumePreservingOnboardingDraftRepository`, preventing later Back saves from racing and overwriting a farther durable checkpoint.
- The persisted snapshot always uses the latest field values even when its cursor remains farther ahead, so valid earlier edits are retained without rewinding resume.
- If a previously satisfied prerequisite becomes invalid, the resolver clamps the persisted cursor to that prerequisite.
- Confirmed root logout now awaits one final repository save before invoking the app-owned sign-out callback; `Stay` does not perform that explicit exit save.
- No visual/theme/layout behavior changed.

## 7. Final Handoff

### Changed Files

- `apps/features/onboarding/lib/src/domain/usecases/preserve_onboarding_resume_checkpoint_use_case.dart`
- `apps/features/onboarding/lib/src/domain/usecases/usecases.dart`
- `apps/features/onboarding/lib/src/data/repositories/resume_preserving_onboarding_draft_repository.dart`
- `apps/features/onboarding/lib/src/data/data.dart`
- `apps/features/onboarding/lib/src/presentation/pages/onboarding_flow_page.dart`
- `apps/app/lib/app/onboarding/onboarding_draft_providers.dart`
- focused domain/data/presentation regression tests

### Actual Behavior Pending Device Verification

```text
Activity reached
-> Back to Name
-> optionally edit earlier valid data
-> Name root logout
-> Welcome
-> same account login
-> resume at Activity (or the farther valid checkpoint actually reached)
-> Back remains available again
```

If an earlier edit makes a required prerequisite invalid, the next session resumes at that invalid prerequisite instead of skipping over it.

### Final Status

`REVIEW` — automated gate green; real-device acceptance still required.
