# Product Onboarding O7D — Health Connections Resume + Review

**Status:** In progress  
**Primary owner:** Product Onboarding orchestration  
**Affected platforms:** Flutter phone app (platform-neutral onboarding behavior)

**Tracker:** GitHub Issue #80  
**Parent O7:** #75  
**O7C:** #78 ✅  
**Health scope decision:** #79 ✅ availability-only for current onboarding  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting exact validated checkpoint

```text
f95ddf7cef05e658566e5d9493efd6099edded76
Flutter CI #1593 / run 32611022666 / job 97124041663 ✅
Android Native CI #5 / run 32611022667 / job 97124042275 ✅
```

Tracker/docs commits after this SHA do not replace exact O7C validation.

## Global UI / Design-System Guardrail

O7D is non-visual by default. Preserve existing Health Connections and Review rendering unless a correctness gap requires a minimal copy/state adjustment. Before any Flutter visual change, re-read `apps/core/lib/src/theme/README.md` and `apps/features/AGENTS.md` and reuse existing core components.

## 1. Discovery

### User Outcome

A user can skip Health Connections during early-stage onboarding, leave/restart/resume safely, reach Review, and finish onboarding without Tio persisting or implying health authorization that does not exist yet.

### Success Criteria

- Health Connections remains optional/non-blocking.
- Completion of the Health Connections onboarding step may persist only as ordinary onboarding progress/checkpoint state.
- Live Health Connect presence/authorization truth is not serialized into `OnboardingDraft` or `onboarding_drafts`.
- Review does not claim `connected` or imported data availability.
- Onboarding completion performs no health-data owner write.
- Historical/pre-O7B unfinished drafts reconcile through Health Connections as already validated.
- Full Flutter four-gate CI passes on one exact O7D source SHA.

### Scope

- audit snapshot/draft mapper fields for Health status leakage;
- audit resume checkpoint semantics at/after `healthConnections`;
- audit Review presentation/data model for truthful availability-only wording;
- add focused regression/acceptance tests;
- make only the smallest source correction proven by failing acceptance.

### Non-Goals

- Health Connect SDK authorization;
- `android.permission.health.*` declarations;
- activity/sleep/nutrition/workout/water record sync;
- health-data schema/RLS or canonical imported-record owner;
- Recovery implementation;
- HealthKit/iOS;
- O8 generic Review/edit-back redesign.

## 2. Codebase Exploration

### Verified Evidence

- O7B runtime places `Health Connections` after Nutrition Targets and before Review.
- `HealthConnectionsController` owns live status separately from `OnboardingDraft`.
- O7C source checkpoint only probes Android Health Connect surface presence and keeps production onboarding authorization unavailable/connect-later.
- #79 explicitly decides current onboarding stays availability-only; future activity/sleep/nutrition/workout/water sync is deferred to consuming features with exact permission contracts.
- Current canonical owner map has no approved imported-health-record owner.

Source/config to inspect before implementation:

- `apps/features/onboarding/lib/src/domain/models/onboarding_draft.dart`
- `apps/features/onboarding/lib/src/domain/models/onboarding_draft_snapshot.dart`
- `apps/features/onboarding/lib/src/data/mappers/onboarding_draft_snapshot_dto_mapper.dart`
- `apps/features/onboarding/lib/src/presentation/controllers/health_connections_controller.dart`
- `apps/features/onboarding/lib/src/presentation/screens/review/review_screen.dart`
- `apps/features/onboarding/lib/src/presentation/sections/health_connections_section.dart`
- existing O7B and draft persistence/resume tests.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Current onboarding requests Health Connect data permissions | No / frozen | Early stage; no approved consuming data contract | Product #79 |
| Future activity/sleep/nutrition/workout/water sync intent | Planned, not permission approval | Exact records/access/owners defined later per consuming feature | Product #79 |
| Persist live Health authorization in onboarding draft | No | Device/platform truth is not onboarding-owned durable data | #44/#79 |
| Persist ordinary Health Connections step completion/checkpoint | Yes, through existing onboarding orchestration only | Needed for resume without storing platform state | O7D |
| Add health DB table in O7D | No | No durable health connection/record owner approved | O7D |

## 4. Architecture Design

### Chosen Approach

Treat Health Connections as an ordinary optional onboarding step for navigation/resume while keeping all platform health state ephemeral and outside onboarding serialization.

### Ownership and Data Flow

```text
Health Connections screen
  → HealthConnectionsController (ephemeral live state only)
  → HealthConnectionGateway (platform boundary)

OnboardingController
  → currentStepId/completedStepIds only
  → OnboardingDraft snapshot persistence

Review
  → onboarding choices/progress truth only
  → never imported health records or fabricated authorization
```

### Alternative Rejected

- Persist `connected/denied/unavailable` in `onboarding_drafts`: rejected because it can become stale and is not onboarding-owned truth.
- Add a Health Connections database owner now: rejected because no durable connection/data contract is approved.
- Skip Health Connections checkpoint persistence entirely: rejected because resume would repeatedly reinsert an already-completed optional step.

### Failure and Accessibility States

- Unavailable or deferred health integration never blocks onboarding completion.
- Resume after process/app restart must land on the correct next onboarding step based on ordinary progress state.
- Review wording must be understandable without implying permission grant/data sync.

## 5. Implementation Plan

- [ ] inspect draft/snapshot serialization for any Health status field;
- [ ] inspect current Health Connections completion checkpoint/resume semantics;
- [ ] inspect Review data/copy for connection claims;
- [ ] add focused O7D tests proving no health-state serialization;
- [ ] add resume test after Health Connections completion;
- [ ] add Review truthfulness test for availability/connect-later scope;
- [ ] add completion test proving no health owner/write is invoked;
- [ ] fix only evidence-backed gaps;
- [ ] run full Flutter four-gate CI on one exact source SHA;
- [ ] freeze #80 and activate O7E only after exact green evidence.

## 6. Quality Review

### Validation Run

```text
Not run yet for O7D.
```

### Review Findings and Resolution

Pending source audit and focused tests.

## 7. Final Handoff

### Changed Files

Pending.

### Actual Behavior

Pending validation.

### Known Limitations

Real Health Connect authorization and activity/sleep/nutrition/workout/water sync remain intentionally deferred beyond Product Onboarding.

### Final Status

`REVIEW`
