# Product Onboarding O7E — Integrated Health Connections Acceptance

**Status:** In progress  
**Tracker:** GitHub Issue #81  
**Parent O7:** #75  
**O7D:** #80 ✅ / CI #1600  
**O7C:** #78 ✅ / CI #1593 + Android Native #5  
**Health scope decision:** #79 ✅ availability-only  
**Parent Product Onboarding:** #40  
**Canonical ownership:** #44  
**O11 cleanup:** #54 BLOCKED until O10  
**Implementation PR:** #50 Draft/open/unmerged

## Starting exact validated checkpoint

```text
879112d05999a2d204e6d5e7cf93ec98415aa32f
Flutter CI #1600 / run 32612274689 / job 97127075778 ✅
Android Native CI #12 / run 32612274590 / job 97127104588 ✅
```

## Goal

Close O7 with one integrated acceptance suite proving Health Connections is optional, availability-only, resumable and completion-safe across all App Modes without introducing health-data authorization or persistence.

## Acceptance matrix

- all App Modes schedule Health Connections immediately before Review;
- current-release unavailable gateway cannot fabricate authorization;
- Health Connections completion is non-blocking;
- pre-O7B unfinished Review checkpoint routes through Health Connections;
- completed Health checkpoint resumes Review;
- snapshot serialization contains Health progress identity but no live platform status;
- canonical completion owner writes remain Profile/Body/Wellness/Nutrition/Workout/App Mode only as eligible;
- no Health owner/write exists in Product Onboarding completion;
- Hybrid setupNow/later semantics remain unchanged;
- completion failure ordering, retry and completed-call idempotency remain intact with Health step in the flow;
- no health permissions/plugin/schema/minSdk changes;
- full Flutter four-gate CI passes on one exact source SHA.

## Product decision retained

Future Tio intent includes syncing activity, sleep, nutrition, workout and water/hydration data. Current onboarding does not request these permissions. Future consuming-feature tasks must define exact record types/access/owner/retention/consent/privacy before authorization.

## Implementation approach

Acceptance-test first. Reuse existing O7B/O7D and O5/O6 completion fixtures rather than adding production abstractions. Only change production source if the integrated test proves an actual contract bug.

## Source/test audit targets

- `o7b_health_connections_runtime_test.dart`
- `o7d_health_connections_resume_review_test.dart`
- `o6e_integrated_workout_acceptance_test.dart`
- `o5e_integrated_nutrition_acceptance_test.dart`
- `persist_onboarding_owner_data_use_case_test.dart`
- `complete_onboarding_use_case.dart`
- `persist_onboarding_owner_data_use_case.dart`

## Validation

```text
Not run yet for O7E.
```

## Guardrails

- no fake `connected`;
- no `android.permission.health.*`;
- no health records/live authorization state in onboarding drafts;
- no new health DB owner/migration;
- no UI redesign;
- PR #50 remains Draft/open/unmerged;
- O11 remains blocked until O10.

## Exit

Freeze exact O7E source SHA + four-gate CI, close #81 and parent #75, sync #40/#44/PR #50 + durable docs to O7 ✅, then activate O8 Review/resume/edit-back.
