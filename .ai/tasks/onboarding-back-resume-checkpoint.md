# Onboarding Back Navigation Resume Checkpoint

**Status:** Validated
**Tracking:** GitHub Issue #13 / PR #36
**Primary owner:** `apps/features/onboarding` + `apps/app`
**Affected platforms:** Flutter phone app

## Outcome

Users may navigate backward through Product Onboarding to review or edit earlier answers, including reaching Profile Name and logging out, without permanently rewinding the durable resume point for the next authenticated session.

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

## Frozen behavior

- Back changes the currently visible onboarding cursor and remains fully navigable/editable.
- Back does not lower the durable resume checkpoint.
- Forward progress may advance the durable checkpoint.
- Profile Name remains the authenticated root Back/logout boundary.
- Logout does not clear the onboarding draft.
- Same-account login resumes at the furthest still-valid checkpoint.
- Earlier valid edits persist without rewinding resume.
- If an earlier edit invalidates a required prerequisite or changes the active flow, persistence clamps/reconciles to the furthest still-valid checkpoint.
- Visible Back and Android/system Back retain the same navigation contract.
- No UI/theme/layout redesign is part of this slice.

## Architecture

No serialized schema change was required. The controller keeps the visible cursor while production persistence preserves the durable cursor through:

```text
OnboardingController
-> ResumePreservingOnboardingDraftRepository
   -> GoogleIdentityOnboardingDraftRepository
      -> AuthAwareOnboardingDraftRepository
         -> secure local / user-owned remote draft
```

`PreserveOnboardingResumeCheckpointUseCase` compares the incoming visible cursor with the previous persisted cursor, preserves the furthest cursor in the current plan, and validates prerequisites against the latest edited data before persistence.

Confirmed root logout performs an explicit awaited repository save before the app-owned sign-out callback. This prevents a Back-autosave/logout race while preserving the last safe checkpoint.

## Implemented files

- `apps/features/onboarding/lib/src/domain/usecases/preserve_onboarding_resume_checkpoint_use_case.dart`
- `apps/features/onboarding/lib/src/domain/usecases/usecases.dart`
- `apps/features/onboarding/lib/src/data/repositories/resume_preserving_onboarding_draft_repository.dart`
- `apps/features/onboarding/lib/src/data/data.dart`
- `apps/features/onboarding/lib/src/presentation/pages/onboarding_flow_page.dart`
- `apps/app/lib/app/onboarding/onboarding_draft_providers.dart`
- focused domain/data/presentation regression tests

## Automated validation

Latest validated PR head before this documentation-only status update:

```text
head: 81d187300a528a5d41ececaf374cf6637639c8e4
Flutter CI: #927
run: 32287172622

Bootstrap workspace      PASS
Analyze Flutter packages PASS
Analyze Dart packages    PASS
Test Flutter packages    PASS
Test Dart packages       PASS
```

Focused regressions cover:

- Activity checkpoint followed by Back-to-Name persistence and next-session resume;
- valid earlier edits preserving the farther checkpoint;
- invalid earlier edits clamping to the prerequisite;
- later-section checkpoint preservation while navigating back;
- changed-flow reconciliation;
- ordered draft saves preventing a later Back save from overwriting farther progress;
- confirmed root logout awaiting the final draft save;
- `Stay` not invoking the explicit logout save/exit path.

## Real-device acceptance — 2026-08-20

Owner/device smoke passed on the active PR flow:

- Back button works through Product Onboarding.
- Next/Continue works through the tested flow.
- Profile completion card renders correctly in the tested Profile state.
- After backing to the Name root and logging out, signing in again with the same account resumes at the previously reached onboarding step instead of the Back destination.
- Back remains usable again after the resumed session.

This directly validates the primary product contract for `visible cursor != durable resume checkpoint`.

## Exit criteria

- [x] Back remains editable/navigation-only.
- [x] Durable checkpoint does not regress on Back.
- [x] Same-account relogin restores the farther valid checkpoint.
- [x] Invalid prerequisite changes reconcile safely.
- [x] Root logout preserves draft and save ordering.
- [x] Visible/system Back parity retained.
- [x] Full automated CI green.
- [x] Primary real-device acceptance green.

## Final handoff

`VALIDATED` — ready to be included in PR #36 review/merge. Issue #13 should remain open until the PR is merged.