# W8C Completed Workout Edit

**Status:** Edit alignment follow-up locally validated; new exact-head CI, independent review and merge approval pending
**Primary owner:** Codex
**Planning owner:** Codex
**Implementation owner:** Codex
**Previous agent:** Not applicable
**Last commit agent / SHA:** Codex / `55b0810ac880ff33dea12c8f6f373b3cc83ad1ac` (latest W8C implementation commit)
**Branch:** `codex/tnyx-85-w8a-workout-history`
**PR / tracker:** [#752](https://github.com/im-tnyx/tio-world/pull/752) / [TNYX-85](https://linear.app/tnyx/issue/TNYX-85/w8-workout-history-completed-session-timeline-and-detail)
**Initial audit HEAD:** `4830909cb215bf3b9f5c348e69c61651f9419b1e`; clean worktree before this brief. `origin/main@23310eeef6c1d42142f3af8f8563e759350d087c` was PR base at audit and remained the base at the follow-up audit.

## Owner Approval and Scope Boundary

**Trigger:** New bounded Edit Workout slice and visible UI/data behavior.
**Approval:** Owner's 2026-11-12 chat and Edit Workout reference screenshot. Detail's Edit action must sit at the right edge and open an editor combining the saved metadata form with actual exercise/set inputs. `Save` becomes `Update`.
**In scope:** Edit one owner-owned completed workout's saved title, description, date/time, duration, gym, exercises and performed set values. Add/remove/replace exercises and add/remove sets through the Log Workout interaction pattern. Update atomically on the same canonical session ID with revision conflict handling, refresh History/Detail, owner/auth isolation and tests. Existing W7 tables only; a scoped RPC/trigger change is needed because terminal rows are immutable. The owner clarified exercise add/remove/replace in chat after the initial brief.
**Out of scope:** Exercise reordering, Active Workout redesign, media upload, social tagging/visibility, watch/offline edit queue, production migration/deployment, PR merge. Screenshot-only unsupported features are not promised.

## Discovery and Architecture

- TNYX-85 is In Review and blocked by TNYX-84; TNYX-84 remains In Progress. W7 Save E2E/device acceptance is pending. This source slice can build against the merged W7 schema without marking W7 Done; hosted edit acceptance waits for migration authorization and device evidence.
- `SaveWorkoutPage` owns metadata inputs; `WorkoutExerciseCard` and `WorkoutSetInputRow` provide the Log Workout composition. History Detail reads owner-filtered completed header and performed sets with revision and login-cycle isolation.
- W7 migrations revoke client table writes and reject terminal session/set mutation in triggers; `rpc_save_workout_session_v1` rejects completed sessions. A same-ID update therefore requires a bounded SECURITY DEFINER RPC, explicit `auth.uid()`/revision/status checks, validated payload, transaction-local trigger gate, and readback. Direct client UPDATE and a new duplicate Save are rejected alternatives.
- Feature owns editor state/repository; Core owns route; app shell wires route. No new table or column.

## Implementation Plan

- [x] Add bounded edit read/write model, RPC/gateway and SQL security matrix.
- [x] Build edit UI with existing Save and Log primitives, route from Detail and refresh after Update. The owner's follow-up replaces `Cancel` with an X icon; the completed-set green row spans the screen width like Log Workout.
- [x] Run local affected Flutter validation, owner/auth tests and diff hygiene.
- [x] Run the SQL matrix and source-head CI; reconcile PR/Linear without merging.
- [ ] Obtain independent review, resolve material findings and wait for PR-specific owner merge approval.

## Handoff

**Current blocker:** No local Supabase CLI is available. Docker daemon and Supabase Postgres image are present, but the repository's disposable database replay requires CLI 2.116.0. The added pgTAP matrix passed in the source-head Supabase Database CI. Hosted migration/deployment and device acceptance are outside this authorization.
**Review provenance:** PR #752 requests `i-the`; no independent W8C review or unresolved review threads were observed at the pre-push audit. Cursor Bugbot has repeatedly reported a usage-limit failure, not a completed code analysis.
**Validation:** `flutter analyze --no-pub` for Workout, app and Core: exit 0 each. Full Workout `flutter test --no-pub`: 1456/1456, exit 0. Focused app route/policy: 48/48, exit 0; Core routes: 8/8, exit 0. The compact OLED widget test at 320px/1.6x checks X, Update and that the green completed row starts at x=0 and ends at x=320. Repository tests check same-ID/revision readback and in-flight account switch. `dart format` on affected edited Dart files and `git diff --check`: exit 0. No local pgTAP, hosted DB apply, physical-device QA or authenticated E2E was run.
**Previous source-head CI:** At `97b6403344cae088630c861b5c6ecaecd0b44917`, [Flutter CI #43153688548](https://github.com/im-tnyx/tio-world/actions/runs/43153688548), [Android Native CI #43153688623](https://github.com/im-tnyx/tio-world/actions/runs/43153688623), [Supabase Database CI #43153688668](https://github.com/im-tnyx/tio-world/actions/runs/43153688668) and [Docs Hygiene CI #43153688547](https://github.com/im-tnyx/tio-world/actions/runs/43153688547) passed. The database regression job explicitly passed `Run W8C completed workout edit SQL matrix`, migration replay/ledger and W7 matrices. Final prior docs-head `146142ada30bb5423dbf5b1c52b741517d69037d` also passed those four CI workflows. The three current `main` required attribution/docs checks passed there. New UI-correction head requires its own CI evidence after push.
**Security and compatibility:** Authenticated-only RPC calls `auth.uid()`, checks completed owner/session/revision and payload/owned custom exercise refs, then edits the canonical row plus performed sets atomically behind a transaction-local terminal-trigger gate. Authenticated clients retain SELECT-only table grants and owner RLS. Client owner checks, revision-bracketed readback and stale-result isolation remain. The existing W7 Save RPC and session IDs are unchanged; future protected-API callers would need to preserve the new revision/CAS, owner and idempotent replay semantics. Mixed old/new client E2E and hosted authorization are unverified.

**2026-11-12 Edit set-column correction:** The owner found that Edit Workout's `PREVIOUS`, `KG`, `REPS`, `RPE` and check header did not line up with values and input fields. `WorkoutExerciseCard` already reserved `PREVIOUS`, while Edit's `WorkoutSetInputRow` omitted it. Commit `55b0810ac880ff33dea12c8f6f373b3cc83ad1ac` enables that row column, matches Log Workout's width-dependent `RPE` column, and reuses its RPE sheet so the control updates the same saved set. `PREVIOUS` truthfully shows an unavailable dash; no prior-workout data is fabricated. The owner-approved green completed row remains edge-to-edge. Focused Edit widget tests: 5/5, exit 0; Workout `flutter analyze --no-pub`: exit 0; full Workout `flutter test --no-pub --reporter compact`: 1458/1458, exit 0; `dart format` and `git diff --check`: exit 0. Tests check 400px header/value/input centers, changed reps, RPE reaching Update, and the existing 320px OLED layout. New exact-head CI, independent review, hosted Update E2E and device acceptance remain pending. W7/TNYX-84 remains In Progress.
