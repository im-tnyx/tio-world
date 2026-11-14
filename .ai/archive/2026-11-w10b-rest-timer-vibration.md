# W10-B — Foreground Rest Timer Vibration

**Status:** Validated / merged 2026-11-13 per the checked-in main audit; PR #754 is merged. The pre-merge review snapshot below is historical. Physical phone acceptance is not verified here.
**Primary owner:** `apps/features/workout`
**Affected platforms:** Flutter Android/iOS phones only

## Owner Approval and Scope Boundary

**Trigger:** New independently scoped product slice and visible Workout Settings toggle
**Approval status:** Approved (owner's explicit 2026-11-13 instruction in Tio-world project conversation).
**Approved boundaries:** Rest Timer Vibration switch under Workout Settings, default OFF, device-local account-scoped persistence. Best-effort **single vibration per naturally expired rest** in foreground Active Workout. Both current Save-only draft and legacy online session countdown paths. Skip/OFF/Cancel/background must be silent. Reuse Flutter haptic platform API; no new countdown engine.
**Explicit non-changes:** No Supabase change, migration, RLS/RPC, push/cloud preference sync, background service, notification/lock-screen vibration, Wear OS/watchOS behavior, timer sound/volume, Superset, altered rest-countdown semantics, visual redesign, or merging without owner authorization.

## Historical Pre-Merge Handoff

**Planning owner:** #00 Tio-world / owner
**Implementation owner:** ChatGPT (sole writer of W10-B; not the W10-A owner)
**Previous agent:** Not applicable — new child slice
**Last commit agent:** ChatGPT — single-owner W10-B
**Last commit SHA:** `3f4311b144400e8b4c1efb81f9ba7de98b9ab41a` (latest source remediation; this task-document follow-up is docs-only)
**Review owner:** `i-the` requested on PR #754; Codex automated review raised six P2 findings, each with scoped source fix/reply, none independently accepted or resolved
**Implementation ownership state:** Active
**Ownership transition:** Not applicable
**Repository state last verified:** GitHub remote main `706bcdf4cba238e567b14cdbc2b48b0942abcf9a`, protected; no open PR. Local Windows checkout/worktree **unavailable** from ChatGPT; do not claim local status.
**Branch:** `tnyx/w10b-rest-vibration`
**HEAD SHA:** `3f4311b144400e8b4c1efb81f9ba7de98b9ab41a` (latest source head before this docs-only checkpoint)
**Observed working-tree state:** Not observable from remote connector
**Observed uncommitted/dirty files:** Not observable
**PR / tracker:** [PR #754](https://github.com/im-tnyx/tio-world/pull/754) OPEN/UNMERGED; Linear [TNYX-87](https://linear.app/tnyx/issue/TNYX-87); GitHub [#48](https://github.com/im-tnyx/tio-world/issues/48).
**Current implementation state:** Settings boolean/local retry, foreground one-shot gate, draft/legacy expiry, modal-sheet awareness, stable rest identity, legacy resume/paused rest ticking, source Set-removal haptic suppression, manual deadline adjustment cancellation and focused source tests. W10-A merged via PR #753.
**Relevant execution surface:** `WorkoutRuntimeSettingsRepository`, `SharedPreferencesWorkoutRuntimeSettingsRepository`, `WorkoutRuntimeSettingsController`, `WorkoutSettingsPage`, `ActiveWorkoutDraftController`, `ActiveWorkoutController`, `ActiveWorkoutPage`, app auth-bound composition and focused tests.
**Validation completed at SHA:** Audit-only source/GitHub/Linear/Supabase metadata, no implementation tests run.
**Validation remaining:** Exact-final-head Flutter tests/analyze, Android Native CI, independent re-review/resolve of six P2 discussions, and real Android/iOS phone QA. No local toolchain/device access in this ChatGPT environment.
**CI failure (verified 2026-11-13):** At PR head `944a4ee44e60b26f6514cd4b73840d217bf09955`, [Flutter CI run 43342397666](https://github.com/im-tnyx/tio-world/actions/runs/43342397666) failed only the app-workout Flutter test shard. Logs show seven new Active Workout haptic widget tests expecting `HapticFeedbackType.vibrate` payload while calling `HapticFeedback.vibrate()`; all seven recorded zero matching payload strings. Flutter/Dart analyze, other Flutter shards, Android Native, Docs Hygiene and attribution passed. This focused correction records the actual platform method `HapticFeedback.vibrate`. No tests claimed passing before next exact-head CI.
**Current blocker:** W10 epic TNYX-87 formally blocked by TNYX-78. Owner approved W10-B child specifically; do not close epic or alter dependencies.
**Open review finding IDs:** P2 [#4558285034](https://github.com/im-tnyx/tio-world/pull/754#discussion_r4558285034) preference-load race; [#4558317255](https://github.com/im-tnyx/tio-world/pull/754#discussion_r4558317255) Workout-owned modal sheet; [#4558373627](https://github.com/im-tnyx/tio-world/pull/754#discussion_r4558373627) legacy resumed rearm; [#4558373640](https://github.com/im-tnyx/tio-world/pull/754#discussion_r4558373640) logged Set removal; [#4558415880](https://github.com/im-tnyx/tio-world/pull/754#discussion_r4558415880) manual deadline adjustment; [#4558415890](https://github.com/im-tnyx/tio-world/pull/754#discussion_r4558415890) paused legacy rest. All have source fixes/replies; **reviewer verification and thread disposition pending**.
**Next exact action:** Complete exact-final-head Flutter/Android CI and obtain independent reviewer disposition of all six P2 discussions; no merge without PR-specific owner approval.

## 1. Discovery

### User Outcome
A user can opt into one device vibration when their active rest naturally finishes while the phone app is foreground; all existing workout operations remain available if preference read or platform feedback fails.

### Success Criteria
- Default OFF. Device-local, authenticated owner-scoped preference persists across restarts, no Supabase writes. Auth cycle invalidates stale controller instances.
- Inactive/unset and malformed preferences fail safely OFF; transient read failure is retryable and never blocks Default Rest, Add Exercise or Save.
- The switch operates in the existing Workout/Hybrid Settings route; Nutrition still gated.
- One-shot natural expiry in **both** draft and legacy runtime; no alert on Skip, cancelled rest, explicit Rest OFF, +/- seconds causing cancellation, background expiry, restore already-expired timer, finished/discarded session or auth transition.
- No repeated buzz across ticks/rebuilds; fresh rest can alert again. Transition while visible and setting ON triggers at most one best-effort system haptic.
- Existing countdown, pause/resume, set entry and Rest Timer overrides unchanged.

## 2. Codebase Exploration

### Verified Evidence
- Source: `apps/features/workout/lib/src/domain/models/active_workout_draft.dart` stores UTC `ActiveWorkoutDraftRest.targetAtUtc` and stable exercise/set IDs. `active_workout_draft_controller.dart` creates/cancels rest on toggle and supports Skip / adjustRest.
- `active_workout_controller.dart` has in-memory `ActiveRestTimerState` and `updateElapsedDuration()` which clears expired rest without exposing a distinct completion event.
- `active_workout_page.dart` has `_StartWorkoutPreviewState` ticker, a controller-listening legacy screen, and Flutter lifecycle observation; separate no-duplicate feedback logic must handle both without creating a new countdown engine.
- W10-A `WorkoutRuntimeSettingsController` and owner-scoped `SharedPreferencesAsync` repository already handle Default Rest Time independently.
- Root `AGENTS.md`, `apps/features/AGENTS.md`, `apps/core/lib/src/theme/README.md`, `.ai/FEATURE_DEVELOPMENT.md`, canonical ownership/docs and relevant tests inspected on verified main.
- Supabase project `oykupyiitspujzpwwvuj` is target metadata only; no schema change required.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Device-local account scope, default OFF | Approved | Explicit owner W10-B scope | Product owner |
| Foreground natural expiry only; background silent | Approved | No unreliable background notifications | Product owner |
| Both current countdown paths, one-shot | Approved | No duplicate/replayed feedback | Product owner |
| Keep Default Rest independently available on optional vibration read failure | Required engineering behavior | Haptic preference is nonessential | Architecture |
| Built-in `HapticFeedback.vibrate`, no plugin | Provisional scoped engineering choice | Existing Flutter platform API | Implementation owner |

## 4. Architecture Design

```text
WorkoutSettingsPage -> WorkoutRuntimeSettingsController -> WorkoutRuntimeSettingsRepository
                  -> owner-scoped SharedPreferencesAsync (boolean, default OFF)
Rest timer UTC deadline / explicit natural-expiry signal
                  -> one-shot foreground completion gate
                  -> best-effort Flutter HapticFeedback.vibrate
```

Keep completion cause in the owning Workout presentation/controller boundary. No other module owns vibration logic, and preference errors do not block rest countdowns.

## 5. Implementation Plan
- [x] Preserve W10-A and extend Workout local preferences with separate haptic state/error/retry.
- [x] One themed Settings switch and error handling (accessibility requires QA).
- [x] Shared per-rest completion gate, draft + legacy runtime wiring and foreground suppression.
- [x] Add focused controller/repository/widget/lifecycle source tests; **not yet run**.
- [ ] Exact-final-head CI, independent P2 re-review, phone QA and owner-approved merge gate; do not merge.

## 6. Quality Review

**Validation run:** NOT RUN locally; Flutter/Dart SDK unavailable in ChatGPT container. Focused source tests were added but not executed. GitHub exact-head CI and physical-device QA pending.

| Criterion | Proposed evidence | Outcome |
|---|---|---|
| Device-local default OFF and auth isolation | Repository/controller + provider tests | NOT RUN |
| One natural expiry vibration, no duplicates | Gate + both countdown tests | NOT RUN |
| Skip/OFF/Cancel/background/restore silent | Focused negative-path tests | NOT RUN |
| Default Rest and Save remain functional on haptic failure | Error independence tests | NOT RUN |
| Phone QA Android/iOS | Real-device acceptance | NOT RUN |

**Review source / link:** GitHub [PR #754](https://github.com/im-tnyx/tio-world/pull/754); four automated review P2 findings, source fixes and replies; requested `i-the` review not complete.
**Independent review?** Automated separate review only; `i-the` human approval not yet received.
**Limitations and unmet required gates:** Device QA, exact-head CI and independent reviewer acceptance required.

## 7. Final Handoff

**Changed files:** Workout Settings repository/controller/UI, one-shot gate, Active Workout draft+legacy presentation, legacy completion revision and stable start identity, focused test fixtures/cases, canonical screen doc, task index and this handoff.
**Known limitations:** Foreground-only phone feedback; OS may suppress haptics; no alarm or scheduled delivery guarantee.
**Final Status:** REVIEW pending implementation/testing and independent review.

## Review remediation checkpoint — 2026-11-13

- W10-B PR #754 raised six P2 findings: preference-read race, owned modal visibility, foreground resume rearming, logged Set removal, manual adjustment cancellation and paused legacy Rest expiry. All six have scoped source fixes/replies; reviewer threads intentionally remain open until independent verification.
- Last source commit: `3f4311b144400e8b4c1efb81f9ba7de98b9ab41a`. Local Flutter/Dart and physical Android/iOS tests were NOT RUN. GitHub Docs Hygiene and attribution guard PASS at this source checkpoint; Flutter and Android CI were still in progress at last check. Earlier source-head analyze passed, but is not proof of this exact final head.
- No protected main push, force push, Supabase schema/data/hosted action, Android notification service, Watch change, background vibration or merge.
- This handoff edit is **docs-only** and creates a fresh PR head; all CI outcomes must be checked on that final head, not assumed from the prior source commit.

## CI failure handoff — 2026-11-13

- Scoped correction to W10-B platform-channel test recorder/expectations; no production/runtime code changed. Nine mock handlers now record `MethodCall.method`, and 14 assertions match `HapticFeedback.vibrate` rather than an absent payload argument.
- Prior [Flutter CI run #43342397666](https://github.com/im-tnyx/tio-world/actions/runs/43342397666): FAIL in app-workout only; other shards, analysis, Android Native all PASS. Need exact-head green Flutter CI and independent review, with physical Android/iOS device QA and PR-specific owner merge approval still outstanding. Do not merge.
