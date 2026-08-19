# Onboarding Back Navigation Resume Checkpoint

**Status:** In progress
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

- `.ai/tasks/onboarding-auth-draft-handoff.md` already requires same-account draft resume after root logout but does not distinguish visible Back cursor from durable resume checkpoint.
- `OnboardingController._moveToProfileStep`, `_moveToWorkoutStep`, `_moveToTargetStep`, and `_moveTo` currently save the Back destination into the same persisted draft cursor.
- `hydrateDraft()` rebuilds initial state directly from persisted draft cursor, so Back-to-Name followed by logout currently resumes at Name.
- Root logout itself does not clear the user-bound onboarding draft, which is correct and must remain unchanged.

### Existing Pattern to Follow

Keep typed stable step IDs and repository-owned draft persistence. Separate navigation cursor semantics from durable resume semantics instead of adding route-level state.

## 3. Clarification

### Decisions Made

| Decision | Status | Rationale |
|---|---|---|
| Back remains fully navigable/editable | Approved | User may need to review earlier answers |
| Back must not rewind next-login resume | Approved | Back is navigation, not progress reset |
| Name remains logout boundary | Approved | Existing root-exit UX is accepted |
| Same-account login resumes furthest valid progress | Approved | Matches expected continuation behavior |
| No draft deletion on logout | Approved | Existing persistence contract remains correct |

## 4. Architecture Design

### Chosen Approach

Maintain two concepts in onboarding state/persistence:

```text
current visible cursor
!=
durable resume checkpoint
```

Forward navigation may advance the resume checkpoint. Back navigation may move the visible cursor backward but must not reduce the checkpoint. Hydration/login restores the checkpoint, reconciled against the current flow plan and still-valid nested step plans.

Avoid deriving resume solely from display fallbacks or route history. The checkpoint must use stable onboarding/profile/workout/target step identities already owned by the domain.

### Failure / Compatibility

- Existing persisted drafts without the new checkpoint must remain readable and fall back safely to their current cursor.
- Flow-plan changes must reconcile an obsolete checkpoint to a valid step.
- A changed earlier answer that alters eligible downstream flow must never resume into an invalid screen.

## 5. Implementation Plan

- [ ] Audit draft model/serialization and repository compatibility path.
- [ ] Add backward-compatible durable resume checkpoint representation.
- [ ] Advance checkpoint on forward progress only.
- [ ] Keep Back navigation persistence from lowering checkpoint.
- [ ] Hydrate/resume from checkpoint while preserving earlier edited values.
- [ ] Add controller/repository regressions for Activity -> Back -> Name -> logout/login -> Activity.
- [ ] Add invalidated-downstream reconciliation regression.
- [ ] Verify visible/system Back parity remains unchanged.
- [ ] Run latest PR CI and real-device acceptance.

## 6. Quality Review

### Validation Run

```text
Not run yet.
```

### Review Findings

Pending implementation.

## 7. Final Handoff

### Final Status

`REVIEW`
