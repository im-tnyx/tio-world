# Feature Task: W7C-3 Active Workout execution and completion

**Status:** In progress — exact Save metadata contract is proposed; seven review fixes and the merge gate remain
**Primary owner:** Current local Codex implementation owner, continuing PR #740 on the existing branch
**Affected platforms:** Flutter Android and iOS phone

## Owner Approval and Scope Boundary

**Trigger:** Owner-approved W7C-3 execution and completion slice, expanded by the request on 2026-11-09.
**Approval status:** Approved for the requested runtime correctness work, the single 0–300-minute duration wheel, and real-save as the product goal. The earlier UI-only boundary in this brief and GitHub #739 is superseded for this active task. This does **not** approve a new Supabase table/column shape, hosted migration, Edge Function deployment, or billable infrastructure.
**Approved boundaries:** Preserve all owner-approved Active Workout and Save Workout visuals. Keep the Workout Home Play FAB and current route; fix current-session reconciliation, execution measurement capture, stable exercise identity, gym provider ownership/search/permission/fallback correctness, and Save truthfulness. Replace only the duration picker with one bounded 0–300-minute wheel, preserving canonical session timer precision and never mutating stored duration on open/cancel. Complete real Start/Set/Pause/Resume/Finish/Save/Restore/History behavior through already approved repository/backend contracts when available. Update focused tests and task/tracker evidence.
**Explicit non-changes:** No UI redesign beyond the duration wheel. No fabricated IDs/data, local-only production session or fake save. No new schema/RPC/table/column shape implementation or hosted migration/deployment without exact owner approval. No Google Places deployment, new billable infrastructure, branch creation, force push, or automatic merge. No wearable or unrelated roadmap work.

**Approved Save-title addendum (2026-11-09):** Workout Title is optional. At Save submission, trim surrounding whitespace from a nonblank custom title; otherwise derive `Morning Workout` (05:00–11:59), `Afternoon Workout` (12:00–16:59), `Evening Workout` (17:00–20:59), or `Night Workout` (21:00–04:59) from the selected local workout Date & Time. Never block Save for an empty title. Preserve the resolved value through canonical persistence, retry, restore, and history/detail reads. Keep the existing UI unchanged. The checked-in W7 session RPC/repository currently has no title argument/field and does not persist the editable Save Date & Time. Exact owner approval for a minimal owner-scoped schema/RPC extension is pending; do not implement a UI-only title or claim it was saved.

## Live Reconciliation and Save Contract Proposal — 2026-11-09 (review-fix handoff)

**Git / PR:** Repository root `G:\projects\Tio-World`; branch `feat/w7c-3-active-workout-execution-ui`; local HEAD and GitHub PR #740 HEAD are `38d2b631156bd74e799d0522cf9aee01815d515b`. Worktree clean, no stashes. GitHub API confirms `main@c76c81d79395bb7f242e321a9fdde1d1fc08e270`, also the PR base. `git fetch origin --prune` could not update `.git/FETCH_HEAD` in the prior session; this audit used GitHub API as the verified remote source. PR #740 remains open and unmerged.

**Review / CI:** Latest GitHub snapshot has 18/18 unresolved review threads, 8 current and 10 outdated. The latest `im-tio` review on `38d2b631` is `CHANGES_REQUESTED` and names seven P2 execution regressions; its seven-item list excludes the earlier duration/distance P1, which source and tests already address. All five PR-triggered workflows on `38d2b631` succeeded: Docs Hygiene CI, Supabase Functions CI, Flutter CI, Supabase Database CI, and Android Native CI. A later infrastructure-only Android attempt briefly hit GitHub release HTTP 504s; the third attempt passed and the exact-head run is green. The separate commit-attribution guard and automated Cursor/Codex checks are not independent approval. No review threads were resolved in this audit; request a fresh `im-tio` review after verified fixes.

**Linear / Issue:** TNYX-84 is `In Progress`, blocked by TNYX-80 and TNYX-81 and blocks TNYX-85 and TNYX-88. GitHub #739 still has its historical UI-only scope text; current owner direction supersedes that restriction only for real-save product behavior. A new table/column shape and hosted migration still need separate exact approval.

**Supabase deployment evidence:** Connected project verified as `tio-world`, ref `oykupyiitspujzpwwvuj`, `ACTIVE_HEALTHY`, Postgres 17.6.1. Hosted ledger has 81 entries and ends at `20261031142025`; metadata confirms no public `user_workout_sessions`, `user_workout_performed_sets`, or W7 session RPCs. The only checked-in migration later than that ledger is `20261106073920_user_workout_sessions.sql`; W7B-1 source was merged to `main` by PR #734 but is not hosted. Do not skip it, edit the hosted ledger manually, or deploy any migration in this task. The live Security Advisor also reports existing `SECURITY DEFINER` grants; these are not W7 session objects and require separate context before any disposition.

### Audited existing contract

- `WorkoutSession` requires canonical `sessionId`, `programId`, `routineId`, an immutable routine snapshot, `startedAtUtc`, and `localDate`; `PerformedSet` carries performed weight/reps/duration/distance and stable set IDs. The session header has notes and lifecycle timestamps/revision, but no title or selected Save timestamp/timezone.
- `rpc_start_workout_session` validates a real owner-owned Program/Routine and its exact composition. Routine/program IDs and snapshot are mandatory; there is no empty/ad-hoc Start operation. Do not fabricate IDs or treat Play preview as a persisted session.
- The seven existing RPCs enforce `auth.uid()` ownership, revision checks, parent-row locks and idempotent replay. RLS allows owner-only SELECT; direct table DML is revoked. `rpc_complete_workout_session` currently accepts `session_id`, `expected_revision`, `completed_at_utc`, and `notes`; it changes canonical status/timing and increments revision. It does not accept Save title or edited workout Date & Time.
- `SupabaseWorkoutSessionRepository.completeSession` calls that RPC then owner-scoped readback by session ID. This readback can verify a canonical completion, but there is no completed-history list contract yet; W8/TNYX-85 is a downstream Linear blocker. Existing session ID readback can validate an individual completed row.
- `SaveWorkoutPage` currently submits title/date, but `ActiveWorkoutPage` opens it with `notesOnly: true`, which makes title/date controls read-only. Only description maps to persisted `notes`; session duration remains derived from canonical `WorkoutTime` and must not be replaced by the selected history timestamp. Gym, activity type and overall RPE have no W7 session columns/DTO fields and must not be represented as saved.

### Proposed minimum compatible contract — approval required before source/schema implementation

1. Reuse `public.user_workout_sessions`; do not add a second workout or history table. Add nullable `workout_title text`, `workout_at_utc timestamptz`, and `workout_utc_offset_minutes integer` to preserve legacy rows without guessed backfills. Keep `started_at_utc` as the timer origin and `completed_at_utc` as the actual terminal transition. On new completions, update the existing `local_date` from the selected instant plus its saved UTC offset; do not overwrite the timer origin.
2. Add `rpc_complete_workout_session_v2(p_session_id uuid, p_expected_revision integer, p_completed_at_utc timestamptz, p_notes text, p_workout_title text, p_workout_at_utc timestamptz, p_workout_utc_offset_minutes integer) returns public.user_workout_sessions`. Leave the existing RPC/signature intact for older app clients. V2 requires a nonblank bounded resolved title and an offset within ±14 hours, checks `auth.uid()`, locks only the owner-scoped parent row, requires the exact expected revision, validates timestamp ordering, performs the same pause-accounting and terminal transition, and atomically writes title/time/offset/local_date plus completion. Replayed terminal calls return the existing row only when all completion payload fields match; conflicting replay is rejected. Revoke execute from `PUBLIC`/`anon`; grant only `authenticated`; retain the established `SECURITY DEFINER` + empty `search_path` pattern and explicit owner check because direct DML is denied.
3. In Flutter, resolve the custom title with `.trim()` at submit; otherwise derive the fallback from the selected local DateTime hour at submit, never `DateTime.now()` or UTC hour. Persist the selected instant as UTC plus `selectedDate.timeZoneOffset.inMinutes`. A separate IANA timezone ID is **not required** to round-trip this one selected instant: existing `local_date` plus the contemporaneous offset reconstructs its wall-clock date/time across device timezone changes. This follows the existing MealLog contract, which explicitly accepts either a timezone ID or UTC offset. An IANA ID would only be needed for future rules-based conversion of other instants in the original zone, which this Save contract does not perform.
4. Extend `WorkoutSession`, row DTO, repository/gateway and controller with the additive metadata and V2 call. Keep old JSON decode compatible with null fields for pre-existing rows. The Save page may make only title and selected Date & Time editable for real sessions after this contract is approved; preserve existing geometry and keep unsupported Gym/activity/RPE fields read-only. Await a V2 row plus owner-scoped repository readback showing `status=completed` and the resolved title/time before reporting Save success. Keep the exact submission tuple stable for retries; reconcile unknown outcomes with `getSession(sessionId)` before another completion attempt.
5. No new history store: completed-session details are read through the same owner-scoped table/RLS and `getSession`. Add the W8 history listing against this canonical table only in the separate TNYX-85 slice. Legacy completed rows keep null metadata and use a clearly documented legacy title fallback; do not fabricate historical custom titles.

**Migration/deployment order:** Hosted state is at `20261031142025`. After separate deployment approval, first apply the pending merged W7B migration `20261106073920_user_workout_sessions.sql` in order and verify its migration ledger/objects. Only then create a new W7C follow-up migration using the repo's `supabase migration new` workflow (no hand-invented timestamp), apply it after W7B, and verify columns, RPC signature, RLS/grants and security tests. Do not skip or manually insert ledger entries. Deploy compatible app code only after the additive migration is present. Rollback is forward-only: retain nullable columns/data and the old RPC; if V2 has a defect, stop using V2 in the client and ship a corrective migration. Do not drop columns or erase session metadata as rollback.

**Focused validation plan after approval:** SQL matrix for owner vs other owner/anon, grants and RLS, invalid/blank title, out-of-range UTC offset, timestamp/local-date agreement, OCC stale revision, identical and conflicting terminal replay, completion from active/paused, no duplicate timing/revision writes, legacy old-RPC compatibility, and no writes after terminal; W7B concurrency lock-order regression; Flutter fallback hour boundaries/midnight, trimmed custom title, selected past date/time, no current-time/UTC-hour dependency, legacy DTO decoding, V2 params, exact-row readback, unknown-outcome recovery and completed `getSession` reload; history ordering contract tests when TNYX-85 is active. Re-run migration replay/pgTAP, Flutter analyze/tests, Android build, security advisor and exact-head CI. Hosted integration tests remain separately gated and are not replaced by mocks.

**Exact owner decisions still required:** approve or reject the three nullable columns and `rpc_complete_workout_session_v2` contract above, including the persisted UTC-offset semantics; separately authorize ordered hosted W7B+W7C migration rollout. Product direction alone does not grant these shape/deployment approvals.

## Active Handoff

**Planning owner:** Current Codex agent (latest PR/tracker/source reconciliation complete)
**Implementation owner:** Current local Codex agent (seven-finding review-fix slice)
**Review owner:** Independent GitHub reviewer (`i-the` currently requested); must review the latest eligible HEAD
**Implementation ownership state:** Taken over from the prior ChatGPT GitHub implementation agent after repository/tracker reconstruction; no concurrent implementation owner is known.
**Ownership transfer record:** Previous Implementation Owner `ChatGPT GitHub implementation agent` → Receiving Implementation Owner `current local Codex implementation owner`. At transfer, verified clean worktree, branch `feat/w7c-3-active-workout-execution-ui`, PR HEAD `0c23e8fd5acafc09a5b97fb720c6f833fc9c602a`, base `c76c81d79395bb7f242e321a9fdde1d1fc08e270`, and no stashes. Scope continues the owner-approved W7C-3 task and does not grant the separate Supabase shape/deployment gate.
**Latest ownership transfer record (2026-11-09):** Previous Implementation Owner `prior local Codex session` → Receiving Implementation Owner `current local Codex session`. Reconstructed from clean local/PR HEAD `38d2b631156bd74e799d0522cf9aee01815d515b`, branch `feat/w7c-3-active-workout-execution-ui`, base `main@c76c81d79395bb7f242e321a9fdde1d1fc08e270`, no stashes, and no other active local implementation owner known. Scope is only the seven latest review fixes and their regression tests. This does not grant the separately gated Supabase shape/deployment authority or permission to merge.
**Ownership transition:** Consolidated the temporary Play FAB/UI work into the existing W7C-3 branch without rewriting original commits. The consolidation merge has original W7C-3 HEAD `0f32b91` and W7C-2 merged main `c76c81d` as parents, and selects the already-audited combined UI tree. Original implementation history remains reachable. PR #740 is canonical; duplicate PR #741 is superseded/closed.
**Repository state before this slice:** Clean at `38d2b631156bd74e799d0522cf9aee01815d515b`, matching GitHub PR #740 HEAD; base is `main@c76c81d79395bb7f242e321a9fdde1d1fc08e270`; no stashes. GitHub API verified the remote refs because git fetch was unavailable in the prior session. This task had no unrelated user changes to preserve.
**Branch:** feat/w7c-3-active-workout-execution-ui
**Observed working-tree state at takeover:** Clean at `38d2b631`; no untracked changes or stashes.
**PR / tracker:** GitHub PR #740 / GitHub #739 / Linear TNYX-84
**Relevant execution surface:** apps/features/workout, apps/app routing, .ai task handoff
**Validation at takeover:** Exact-head GitHub Actions runs for `38d2b631` report Docs Hygiene, Supabase Functions, Flutter, Supabase Database, and Android Native CI all successful. This slice later passed Workout analysis and all 1,333 Workout tests, app analysis and 101 focused app provider/routing tests.
**Prior local delta now committed:** `38d2b631` makes Save Workout await canonical discard confirmation and retain the page on a failed persistence result; two focused regressions passed. No migration or W7 persistence code changed.
**Current blockers:** Hosted project ledger ends at `20261031142025`; merged W7B `20261106073920_user_workout_sessions.sql` is not deployed. The proposed W7C nullable columns/V2 RPC require explicit shape approval. No real ad-hoc start or history-list contract exists; preview cannot report Save success. Google Places remains undeployed with quota/billing/abuse controls unverified. PR #740 had 18 threads at takeover; after 12 evidence-backed dispositions, the new `b9914f62` review added two more findings, for 20 total and 8 unresolved before the local follow-up. Fresh exact-head CI and independent review remain pending.
**Tracker state:** Linear TNYX-84 remains `In Progress`; it is blocked by TNYX-80/TNYX-81 and blocks TNYX-85/TNYX-88. GitHub #739's historical UI-only wording is superseded for the real-save product goal, while schema/deployment approval remains separate. Refresh PR #740 HEAD, checks, reviews and thread dispositions after publication.
**Next exact action:** Publish the tested reconciliation Retry/Back and mutually exclusive Save/Discard fixes to PR #740, then update their review threads and request fresh independent review. Do not merge or deploy.

## 1. Discovery

User wants a familiar Nutrition-style floating Play action on Workout Home. The Play action opens the reference-aligned Log Workout screen even before workout-start persistence is approved. Real active sessions still restore using the canonical controller.

## 2. Codebase Exploration

- Read root AGENTS.md, apps/features/AGENTS.md, Core theme README, architecture ownership, .ai/FEATURE_DEVELOPMENT, GitHub push/PR templates, #739 and TNYX-84.
- `MealDiaryLogAction` is a one-off Nutrition FAB composed from governed Core colors, shadows, 56dp sizing; reuse its theme/layout contract but do not import Nutrition into Workout.
- `RoutineSetInputRow` edits a Routine SetPrescription; cannot represent a performed set truth. Reuse Core boxedNumber and existing RoutineSetInputLimits for actual-set entry.
- `ActiveWorkoutPage` already consumes auth-bound controller and `WorkoutSessionSnapshot` under W7C-2; W7C-3 exploration adds stats/set UI.
- `WorkoutHomePage` is a date surface, app shell owns navigation and `/workout/active` already has no bottom bar/auth gating.

## 3. Clarification

| Decision | Status | Rationale |
| --- | --- | --- |
| Play opens Active Workout route directly (not separate Start page) | Owner-approved | Explicit current direction supersedes the earlier two-option #739 proposal for this UI slice |
| No data / no session | Entry preview only; Finish must not claim or simulate persistence | Preserves protected startup contract; zero persisted workout, zero fake exercises |
| Finish/save of a real supported session | Use existing session repository completion; Save reports success only after canonical completion confirmation | Current source contract supports notes, but not title or edited Save metadata; title/date-time schema proposal awaits owner approval |
| Add Set / Add Exercise persistence | Existing repository operations only; report unsupported operations as blocked | No approved snapshot amendment operation for ad-hoc/empty sessions |
| Actual set input | UI wired to existing logSet only when a real session exists | Never silently uses prescription as performed truth |

## 4. Architecture Design

Workout Home action -> app-owned navigation to `/workout/active?preview=1` -> feature-owned ActiveWorkoutPage. With no real session, show an in-memory UI preview; with a real session, render controller-backed state. No new session engine or local-only production data. Numeric input from `TioInput.boxedNumber`, feature-owned validation, existing `controller.logSet` mutation only for actual user-entered values.

**Rejected alternative:** Import Nutrition FAB into Workout or directly use RoutineSetInputRow; both breach feature/data ownership. Also rejected automatically launching a fake/empty server session.

**Failure/accessibility:** Existing auth invalidation and reconciliation states stay authoritative; FAB has label/tooltip; preview Add Exercise is enabled while Finish/Settings/Discard remain visibly disabled without a session; pending actions protected; month expansion hides FAB.

### Gym Location Architecture (Google Places API + Supabase Proxy)
- **Status:** Source changes under review; current tests were not run successfully in this session. Hosted `nearby-gyms` is absent and is not deployed.
- **Client GPS:** Uses `geolocator` on Flutter client to query device coordinates (`latitude`, `longitude`) with standard OS permissions (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` on Android; `NSLocationWhenInUseUsageDescription` on iOS). Timeout guards ensure testing stability without hanging.
- **Server-Side Proxy:** Per `AGENTS.md` ("Client apps may use only client-safe keys and APIs; never expose server keys/secrets in client apps"), requests route through Supabase Edge Function `/functions/v1/nearby-gyms`.
- **Google Places API:** Edge function securely reads `GOOGLE_PLACES_API_KEY` from environment secrets and queries Google Places API (New) (`places:searchNearby` with `includedTypes: ["gym", "fitness_center"]` around coordinates or `places:searchText` for queries), calculating distance with Haversine formula and sorting results.
- **Privacy & Fallbacks:** No hardcoded nearby results or distance values; failed/denied location leaves no fabricated nearby list. Google quota, billing, and abuse-rate controls still require owner/security disposition before deployment.
- **Tests:** Deno attempted, blocked at JSR dependency fetch; Flutter tests/analyze blocked by local Flutter tool Git launch failure. No test passes are claimed for this working tree.

## 5. Implementation Plan

- [x] Workout Play FAB with Nutrition-style governed appearance.
- [x] Workout Home callback and app-owned route wiring.
- [x] Truthful no-session preview on Play entry, without mutating data.
- [x] Preserve W7C-3 screenshot-inspired stats/set UI and accept entered actual set values.
- [x] Focused widget regression tests authored for duration, save truthfulness, execution measurements, and preview completion.
- [x] Focused regression tests completed and run for the seven review findings; title persistence tests remain gated on the approved backend contract.
- [ ] Exact-head CI, independent review, compact-width device visual comparison.

## 6. Quality Review

**Validation for commit `b9914f62` (pushed to PR #740):** `dart format` and `git diff --check` passed. Focused Active Workout/Set Input tests: 57 passed. Full `apps/features/workout` suite: 1,333 passed. Workout and app `flutter analyze --no-pub`: no issues. Relevant app provider/routing tests: 101 passed. Compact 320dp light/dark header widget checks ran. Exact-head CI was green for Flutter, docs, parser, attribution and most feature jobs; Android and database replay were still running when the two new findings arrived. The connected status API can verify job-level checks by exact SHA. Screenshot/device baseline comparison, Android device build/install, Deno tests, hosted persistence and independent review remain pending.

**Seven current `im-tio` findings and regression evidence:**

1. Additional persisted performed sets render after restore: `active_workout_page_test.dart` — `restores all additional performed sets beyond the snapshot`.
2. Preview set removal keeps later performed state attached to its UUID: `active_workout_page_test.dart` — `removing a preview Set preserves performed state on later Sets`.
3. Removed/re-added preview sets use a fresh UUID: `active_workout_page_test.dart` — `re-adding a preview Set after removal creates a unique UUID`.
4. Completed rows show only actual non-null performed values: `routine_set_input_row_test.dart` — `completed rows render only non-null performed measurements`.
5. Restored cardio values seed editing and survive re-log: `active_workout_page_test.dart` — `restored cardio values seed inputs and survive re-log at 320dp`.
6. Cardio execution headers match TIME/KM fields in both themes at compact width: `active_workout_page_test.dart` — light and dark `execution headers follow cardio measurement columns` tests.
7. Execution rep-range prescriptions use one actual-reps input: `routine_set_input_row_test.dart` — `rep-range execution uses one actual-reps input`.

**Earlier review findings:**

1. P1 false preview Save success — removed preview Save navigation; Finish explains the draft is not saved and retains it. Regression test authored, not run.
2. P1 session hidden by empty preview during reconciliation — reconciliation state remains authoritative even when entry requested preview. Test not run.
3. P1 duration/distance ignored — set row parses and validates those values, passes `durationSeconds`/`distanceMeters` to `logSet`, and renders restored values. Focused test authored, not run.
4. P1 repository constructed in GymSelectionPage — construction moved to app composition/provider and injected through `GymLocationRepository`. Test not run.
5. P2 Save metadata dropped — notes pass to canonical completion; unsupported title/date/time/duration/gym/activity/RPE edits are disabled for real-session Save. Auto-title and selected timestamp persistence await owner-approved contract. Success requires canonical completion confirmation. Tests authored, not run.
6. P2 exercise removal index corruption — preview maps and set-keyed maps are reindexed on removal. Dedicated identity regression test not yet authored/run.
7. P2 gym response race — initial and typed searches share request-generation guards for result/loading updates. Race regression test not yet authored/run.
8. P2 permission prompt timeout — timeout removed from `requestPermission`; position acquisition remains bounded. Permission-path test not yet authored/run.
9. P2 Set Type/RPE lost on restore — persisted-session override callbacks are unavailable; immutable snapshot type remains and widget-only overrides are not offered. Restoration test not yet authored/run.
10. P2 fabricated Jaipur proximity — hardcoded gyms/distances removed; denied/network failure returns no fabricated nearby list. Full Flutter suite passed; no dedicated fallback-widget test was found in this slice.
11. P2 discard persistence — Save Workout awaits discard confirmation and keeps the page open on persistence failure; `save_workout_page_test.dart` has success/failure regressions included in the passing full Workout suite.

The older P2 Save-metadata thread remains a real backend gate: current completion persists only notes, and title/selected date-time need the separately approved schema/RPC contract above. Do not resolve it as complete or claim auto-title persistence.

**Additional review received on `b9914f62` (two findings, now fixed locally and awaiting publication):**

1. P1 reconciliation recovery actions — `ActiveWorkoutPage` now exposes Retry (`controller.reconcileState()`) and Back; both are disabled during reconciliation. Focused `active_workout_page_test.dart` covers successful retry, pending guards, Back, and hidden raw backend errors.
2. P2 Save/Discard race — both callbacks now share `_isSaving`/`_isDiscarding` guards and are disabled while the opposite operation is pending. Focused `save_workout_page_test.dart` verifies Save pending blocks Discard; discard-pending also verifies Save disabled.

The follow-up focused suite passed (47 tests), Workout analysis passed, and the updated full Workout suite passed (1,335 tests). These follow-up edits are not yet committed/pushed. Their new GitHub threads remain open until the tested source is published and the thread replies are recorded.

**Nearby-gyms security:** Auth verification, bounded request validation, generic errors, and checked-in `verify_jwt` are present in source. Deno tests did not execute. Persistent rate/abuse limits and Google quota/billing controls remain unverified; hosted function is absent and deployment is blocked.

**Review provenance:** Awaiting evidence-backed dispositions for remaining old threads, publication of the two latest fixes, and a fresh independent `im-tio` review on the eventual pushed HEAD. ChatGPT implementation/self-inspection is not independent approval.

## 7. Final Handoff

**Status:** REVIEW — seven priority review fixes are published and validated; two newer review fixes are locally validated but unpublished. Exact-head CI and independent review remain pending; real-save title/date-time approval and hosted migrations remain separate blockers.

No hosted Supabase schema/RPC changes or deployments were made. Source changes do touch the checked-in Edge Function and `supabase/config.toml`. No merge authorization was given.
