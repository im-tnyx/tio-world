# W8A Workout History list and card

**Tracker:** [TNYX-85](https://linear.app/tnyx/issue/TNYX-85/w8-workout-history-completed-session-timeline-and-detail)
**Implementation owner:** Codex
**Previous agent:** None
**Last commit agent / SHA:** Codex / `39111163747387ddc1eda103906ba34b3abd4fc4` (implementation commit)
**Branch:** `codex/tnyx-85-w8a-workout-history`
**PR:** [#752](https://github.com/im-tnyx/tio-world/pull/752) — review/merge gate, no merge without PR-specific owner approval
**Base:** `main@23310eeef6c1d42142f3af8f8563e759350d087c` (matched `origin/main` after fetch, 2026-11-11)
**Status:** Implementation validated locally; PR review pending

## Discovery and owner approval

Owner approved the Workout root History action, authenticated completed-session list/read contract, and compact cards using the supplied visual reference. The owner subsequently requested missing total Volume and the same clean Time/Volume presentation as the new screenshot. Cards retain session IDs without selection. History Detail, Active Workout redesign, new schema/RPC/grants, watch, local database, offline sync, and deployment are out of scope.

## Reconciled evidence

- Linear TNYX-85 was Backlog and blocked by TNYX-84 at discovery; it moved to In Progress for this approved slice. TNYX-84 remains In Progress. W7 source and hosted migrations exist, but authenticated Save E2E/device acceptance and W3/W4 dependencies remain. W8A can read existing completed rows without claiming W7 acceptance or changing its status.
- `WorkoutHomePage` owns calendar/Library/Play only; `TioShellStatusTopBar` already supports a right trailing action, presently used by Meal Diary. Workout root retains title and streak.
- `WorkoutSessionRepository`/`SupabaseWorkoutSessionRepository`/gateway own W7 reads and owner/login-cycle checks. `user_workout_sessions` and `user_workout_performed_sets` grant authenticated SELECT under owner RLS. W7 Save persists `workout_title`, `workout_at_utc`, `workout_utc_offset_minutes`, `notes`, `gym_name`, `workout_duration_seconds`, frozen exercise snapshot, and performed sets. No authoritative PR, bpm, or calorie field was found.
- `AppRoutes` and Workout shell child routes keep nested destinations under `/workout`; `appModeRedirect` applies Workout mode gating to child paths.
- Core supplies `TioCard`, spacing/type/color primitives and existing shell bar. Workout supplies `ExerciseThumbnail` and catalog media lookup; a themed fallback is required where no valid media is available.
- Read-only hosted inspection on 2026-11-12 verified both W7 tables, authenticated owner RLS SELECT policies and no anon SELECT policy. Supabase Security Advisor returned existing notices unrelated to this read-only source slice; the former W7 trigger-helper warning was absent. No hosted write, migration or RLS change occurred.

## Architecture and decisions

Use the existing W7 Supabase client/repository ownership and add a bounded read-only History page contract. Query completed session headers in stable descending completion-time and ID order, then fetch that page's performed rows in a bounded batch. Build cards from saved fields and frozen exercise names; count non-skipped performed rows. Guard account changes before publishing async results. No in-memory cross-login cache.

Show saved duration and truthful performed previews. W7 stores actual external `load_kg` and `reps` on performed rows; Active Workout already sums `loadKg × reps`. History uses the same calculation only for completed, non-skipped measured pairs, showing Volume beside Time when at least one pair exists. Missing measurements do not become inferred zero-volume sets. Omit PR, average bpm, and calories because canonical completed-session values do not exist. Omit current-user avatar/name unless an existing approved profile read can be used without widening this slice. Empty/blank description and gym render no element or spacing.

**Rejected:** per-card set requests (N+1), planned Routine set counts, speculative stats, and a placeholder Detail route.

## Implementation and validation

- [x] Feature-owned read model and existing W7 gateway/repository projection: five completed headers per page, stable keyset cursor, owner filter/RLS and bounded batched performed-set reads. Refresh and account-cycle guards drop stale data; the UI deduplicates page boundaries.
- [x] Core route contract, Workout child route, root trailing History action, and read-only list/cards. No Detail route or tap action.
- [x] Focused repository/gateway, widget, routing/top-bar and regression tests. `dart analyze apps/features/workout`, `apps/app`, `apps/core`: each exit 0. `flutter analyze --no-pub` in each package: each exit 0. Full Workout `flutter test --no-pub`: 1435/1435, exit 0. Focused app route/top-bar suite: 66/66 plus compact top-bar test 1/1, exit 0. Core route test: 8/8, exit 0. Final History widget test: 5/5, exit 0. `git diff --check`: exit 0. Existing `uses-material-design` pubspec warning did not fail tests.
- [x] Publish scoped PR and link PR/task brief to TNYX-85; broader W8 remains In Progress.
- [ ] Inspect exact-head CI/review and request independent review. Merge requires PR-specific owner approval.

**Owner Volume correction validation:** `dart format` on seven changed Dart files: exit 0. Focused gateway/repository/card tests: 54/54, exit 0. Workout `flutter analyze --no-pub`: exit 0. Full Workout `flutter test --no-pub`: 1437/1437, exit 0. Existing Material icons pubspec warning and one pre-existing hit-test warning did not fail tests. Exact new PR-head CI remains pending.

**CI compatibility correction:** First PR run `43087828932` cloned moving Flutter `stable` at 3.50.0. Its analyzer failed across 14 packages with 418 SDK deprecation infos and one pre-existing unnecessary import, while the prior `main` analyzer passed. The two Flutter CI install steps are pinned to the existing Android CI version 3.47.9 (verified Flutter tag). The previous head `2fc63f89` passed Flutter CI `43088860428` and Android Native CI `43088860425`; the Volume follow-up requires fresh exact-head checks. No SDK/package migration is included.

**Future protected-API compatibility:** Compatible + evidence for this read-only projection: canonical `WorkoutSessionId` and saved W7 session/set tables remain unchanged; the feature repository boundary can be implemented by a later approved adapter without re-keying the card model or rewriting UI. Owner Auth/RLS was inspected live, while future API authorization and mixed-version clients were not tested. W7 mutations, retries and Save E2E are outside W8A.

**Remaining acceptance:** Exact-head CI and independent review are pending. Device visual/Save E2E acceptance is not claimed. TNYX-84 remains In Progress. **Detail follow-up:** obtain owner design and behavior before card-selection navigation.
