# W8C Completed Workout Edit

**Status:** Local implementation validated; exact-head CI and independent review pending
**Primary owner:** Codex
**Planning owner:** Codex
**Implementation owner:** Codex
**Previous agent:** Not applicable
**Last commit agent / SHA:** Not applicable
**Branch:** `codex/tnyx-85-w8a-workout-history`
**PR / tracker:** [#752](https://github.com/im-tnyx/tio-world/pull/752) / [TNYX-85](https://linear.app/tnyx/issue/TNYX-85/w8-workout-history-completed-session-timeline-and-detail)
**Verified HEAD:** `4830909cb215bf3b9f5c348e69c61651f9419b1e`; clean worktree before this brief. `origin/main@23310eeef6c1d42142f3af8f8563e759350d087c` was PR base at audit.

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
- [ ] Run the SQL matrix and exact-head CI; reconcile independent review and PR/Linear without merging.

## Handoff

**Current blocker:** No local Supabase CLI is available. Docker daemon and Supabase Postgres image are present, but the repository's disposable database replay requires CLI 2.116.0. The added pgTAP matrix is wired into `supabase-db-ci.yml`; its result awaits exact-head CI. Hosted migration/deployment and device acceptance are outside this authorization.
**Review provenance:** PR #752 requests `i-the`; no independent W8C review or unresolved review threads were observed at the pre-push audit. Cursor Bugbot has repeatedly reported a usage-limit failure, not a completed code analysis.
**Validation:** `flutter analyze --no-pub` for Workout, app and Core: exit 0 each. Full Workout `flutter test --no-pub`: 1456/1456, exit 0. Focused app route/policy: 48/48, exit 0; Core routes: 8/8, exit 0. The compact OLED widget test at 320px/1.6x checks X, Update and that the green completed row starts at x=0 and ends at x=320. Repository tests check same-ID/revision readback and in-flight account switch. `dart format` on affected edited Dart files and `git diff --check`: exit 0. No local pgTAP, hosted DB apply, physical-device QA or authenticated E2E was run.
**Security and compatibility:** Authenticated-only RPC calls `auth.uid()`, checks completed owner/session/revision and payload/owned custom exercise refs, then edits the canonical row plus performed sets atomically behind a transaction-local terminal-trigger gate. Authenticated clients retain SELECT-only table grants and owner RLS. Client owner checks, revision-bracketed readback and stale-result isolation remain. The existing W7 Save RPC and session IDs are unchanged; future protected-API callers would need to preserve the new revision/CAS, owner and idempotent replay semantics. Mixed old/new client E2E and hosted authorization are unverified.
