# W8B Workout History Detail

**Status:** In progress
**Primary owner:** Codex
**Planning owner:** Codex
**Implementation owner:** Codex
**Previous agent:** Not applicable
**Last commit agent / SHA:** Codex / `a3543c42dc4788c989dcb2ac599bb4a802db8e38` (latest W8B implementation commit)
**Branch:** `codex/tnyx-85-w8a-workout-history`
**PR / tracker:** [#752](https://github.com/im-tnyx/tio-world/pull/752) / [TNYX-85](https://linear.app/tnyx/issue/TNYX-85/w8-workout-history-completed-session-timeline-and-detail)
**Repository state last verified:** W8B implementation committed at `a3543c42dc4788c989dcb2ac599bb4a802db8e38`; `origin/main@23310eeef6c1d42142f3af8f8563e759350d087c` remains an ancestor. Working tree was clean before this handoff edit.

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product task/feature slice and visible UI/UX change.
**Approval status:** Approved in chat on 2026-11-12 with three History Detail reference screenshots and direction to add it on the same branch.
**Approved scope:** Tapping a completed History card opens a read-only Workout Detail route. The top displays saved title, optional description, actual duration, supported volume, completed set count, saved date/time and optional persisted gym. Below is a `Workout` header with a visible, disabled `Edit Workout` affordance, followed by historical exercise order and actual performed set measurements. Adapt the existing Routine Detail visual pattern to Tio theme and compact screens.
**Explicit non-changes:** Edit behavior awaits owner requirements; no edit mutation or placeholder editor. No new schema/RPC/grant, Active Workout redesign, watch/offline work, fabricated stats or prescribed Routine values. No PR merge or production deployment.

## Discovery and Architecture

- TNYX-85 is In Review and PR #752 is open. TNYX-84 remains In Progress; authenticated Save E2E and device acceptance remain separate. W8B reads existing W7 completed rows and does not change W7 status.
- W8A list has a canonical saved session ID and owner-scoped repository/gateway; `getSession` loses selected gym and duration metadata. The feature-owned detail projection uses a completed-and-owner-filtered header query and bounded `readPerformedSets`, with bracketed revision and owner/login-cycle checks. It reuses `WorkoutHistoryDto` for summary truth.
- Routine Detail's preview is private and based on `SetPrescription`, so only its themed exercise/set layout is suitable for adaptation. W8B values come from completed, non-skipped `PerformedSet` rows and frozen exercise snapshots. No N+1 requests or unbounded read.
- `apps/features/workout` owns model, repository contract, page and state. `apps/core` owns route contract; `apps/app` wires Workout child navigation and auth/App Mode guard.
- Loading, not found, offline/error/retry and stale account-result isolation are required. Optional blank fields have no row or spacing. `Edit Workout` is disabled and cannot navigate.

## Implementation Plan

- [x] Add completed-session detail read model and focused repository/gateway tests.
- [x] Add compact themed Detail page and card selection, with widget/routing/privacy tests.
- [x] Validate format, local analysis, affected Flutter tests and diff hygiene.
- [ ] Validate exact-head CI and seek independent review.
- [ ] Update PR and TNYX-85 with W8B evidence, keep merge held for PR-specific owner approval.

## Quality Review and Handoff

**Validation completed (same source tree as W8B implementation commit `a3543c42`):** `dart format` on 17 affected Dart files exit 0. Workout `flutter analyze --no-pub` exit 0 and full `flutter test --no-pub` 1446/1446 exit 0. App and Core `flutter analyze --no-pub` exit 0 each. Focused Workout repository/card/Detail tests 48/48, gateway 14/14, app routing/policy 47/47, and Core route 8/8: all exit 0. `git diff --cached --check` exit 0. Existing Material icons pubspec warning did not fail tests. W8A `8f595c18` Flutter/Android/required CI passed; W8B exact-head CI pending after push.
**Future protected-API compatibility:** Compatible + evidence. Canonical `WorkoutSessionId`, W7 table shape and owner/RLS boundary are unchanged; a later separately approved adapter can implement the same read-only History repository result without re-keying cards or changing presentation. Current owner-scoped gateway filter, DTO validation, bounded set read, revision retry and stale-account tests passed. A future adapter, older-client mix and authenticated Save E2E were not tested.
**Review provenance:** No W8B review yet.
**Known limitations:** Device acceptance unavailable; Edit Workout separately specified later. W7/TNYX-84 remains In Progress.
**Next exact action:** Push the scoped W8B change, then inspect exact-head CI and independent review.
