# Progress Weight A1 — owner-backed repository foundation

**Status:** In progress (source-only review gate; unmerged)
**Primary owner:** Progress / Body, `apps/features/progress`
**Owner approval:** 2026-10-25 explicit "Go A1 — Progress Weight Repository Foundation", no merge.
**Implementation owner:** `im-tnyx` isolated GitHub branch. Review owner: distinct `im-tio` requested at PR gate.
**Source baseline:** `main@03c544356d03f9a6e6ee9a7e59565c2663a5a1bb`, GitHub connector; Windows local `G:\projects\Tio-World` not mountable in this environment. Local git status, Dart, Flutter and device evidence **NOT RUN**.
**Branch:** `feat/tnyx-119-progress-weight-a1-repository`
**Planning:** Linear [TNYX-119](https://linear.app/tnyx/issue/TNYX-119/progress-weight-logging-photos-and-private-user-media-persistence); D0 [GitHub #686](https://github.com/im-tnyx/tio-world/issues/686), [PR #687](https://github.com/im-tnyx/tio-world/pull/687) already merged.
**Current checkpoint:** Source and focused tests implemented in [PR #689](https://github.com/im-tnyx/tio-world/pull/689). Code HEAD `54296ccf6d7d17cac18fa58d3760d5d228349cc0` passed exact-head Flutter CI [run 40206916282](https://github.com/im-tnyx/tio-world/actions/runs/40206916282), **SUCCESS 5/5** (Analyzer/test Dart, three Flutter test shards, aggregate), plus Docs Hygiene and Attribution. Awaiting independent formal `im-tio` review; Codex re-review at latest head was unavailable due to quota. No merge authorized.

## Discovery and source evidence
- `AGENTS.md`, `apps/features/AGENTS.md`, root/docs/architecture/ownership/privacy/source guide and `.ai/FEATURE_DEVELOPMENT.md` read before source modification.
- Current Progress bottom navigation still placeholder, no History UI or Log Weight sheet.
- `BodyRepository` is the canonical owner; older callers consume `getBodyState` and `recordCurrentWeight`. App test fakes require compilation-only compatibility changes.
- Live Supabase `public.body_weight_logs`: UUID PK, authenticated own-row SELECT/INSERT/UPDATE/DELETE RLS, positive-weight DB CHECK and `(user_id, measured_at DESC)` index. Security advisor has no directly named weight-table finding. No new migration/Storage/RPC.
- Supabase `set_active_body_goal` RPC selects latest weight by `measured_at DESC` only. **Do not silently alter current-weight selection or body-goal lifecycle** in this slice; tie-break eligibility policy needs coordinated backend decision in a separate scope.

## Implemented boundaries
1. Backend-neutral `BodyWeightHistoryQuery/Page/Cursor` and `BodyWeightLogEdit` contracts; `BodyWeightEntry.id` optional for legacy state/test callers but required in History results.
2. Supabase owner-ID filter plus RLS, UTC half-open `[from,to)`, keyset `(measured_at DESC, id DESC)`, at most 100 records/page, immutable response list.
3. Exact `id + user_id` update/delete, no owner/source/metadata/goal alteration; `false` for inaccessible/missing row, error propagation for actual failures, signed-out reads empty and writes rejected.
4. InMemory repository mirrors identity, pagination, edit/delete, onboarding retry ID stability; lightweight fake interface changes preserve Settings/profile regression coverage.
5. `BodyWeightSources.manual` semantic provenance reserved for upcoming Log Weight sheet; no new insert behavior in A1.

## Excluded
- No production UI/widget, route, provider-composition, design tokens, Wear, Photos, Storage, Supabase migration/RLS/RPC, new goal behavior, or public activation.
- Local timezone conversion is the caller's responsibility: pass absolute `DateTime` range instants. No timezone column, date-based uniqueness or sample real user data.
- In-flight idempotent Log Weight insert belongs to A3, explicit delete confirmation to A4, and coordinated future/latest/tie policy requires a later backend/feature decision.

## Validation and review gate
- Focused History/mapper/auth/in-memory tests added under `apps/features/progress/test/data`.
- Code HEAD `54296ccf6d7d17cac18fa58d3760d5d228349cc0`: full Flutter CI 40206916282 **SUCCESS 5/5**. Docs Hygiene and Commit Attribution **SUCCESS** at this code HEAD. Previous heads failed on a malformed generated domain splice and then an extra 4-character UUID group; these were corrected before the passing run.
- Codex independent review found P1 malformed UUID regex on earlier head `0081bcf`; corrected at `54296ccf`, focused Progress tests passed, and old finding thread `PRRT_kwDOTOXwB86wCbUj` was replied to and resolved. Latest Codex re-review attempt failed solely from usage limits; this is **not** approval. Distinct `im-tio` GitHub review is requested but **no formal APPROVED** yet.
- This final task-handoff-only commit advances the PR HEAD after the above code validation. Recheck CI and docs hygiene at the new exact HEAD; do **not** transfer previous-head success to an unverified final head.
- Verify `dart format --output=none --set-exit-if-changed` on touched Dart; `flutter analyze`, Progress tests and affected app regression tests via Flutter CI.
- Before merge: inspect diff/changed-file list, CI conclusion on exact HEAD, GitHub reviews and unresolved threads. **Owner must explicitly authorize merge; do not auto-merge.**
- Reconcile Linear on meaningful state transitions; parent TNYX-119 includes future A2–A4 and Photos, so completing A1 does not close the parent.

## Handoff
Review the exact PR diff for UUID/cursor injection safety, `updated_at` trigger semantics, same-moment pagination, RLS on UPDATE/DELETE, session switch, no-goal/empty-state integrity and legacy caller compatibility. If CI or independent review finds a problem, fix in this branch and repeat exact-head checks. D0 task file/index historical `unmerged` wording predates verified [PR #687](https://github.com/im-tnyx/tio-world/pull/687) squash merge and must not be treated as active ownership.


## Independent REQUEST_CHANGES P2 remediation checkpoint (2026-10-25)

- Independent reviewer `im-tio` submitted `CHANGES_REQUESTED` on PR #689 at reviewed HEAD `b20ab4a144f03fcf70d1e5e86edcb41372aa05ed`, identifying old-C1 response acceptance after same-owner re-login (and A→B→A) when the post-await guard only checked `currentUser.id`.
- Bounded code remediation: `SupabaseBodySetupRepository` pins `weightLoginCycleId`, reads a live cycle callback before dispatch and after awaited History/Update/Delete; `apps/app` composition watches authoritative `authSessionStateProvider`, remakes the repository on session changes and revokes old callbacks. No change to existing `getBodyState`, post-onboarding Settings/Body Goal methods, database shape or RLS.
- A narrowly injected `BodyWeightLogTransport` preserves the same Supabase query and owner-ID filters while enabling controlled `Completer` response races. Nine focused tests cover same-owner C1→C2 History/Edit/Delete, A→B→A History, cross-owner Edit, stale dispatch, missing-cycle deny, logout and unchanged-cycle acceptance; app provider test covers same-user cycle transition.
- Exact code HEAD `ea7768d2a1c2eb91b3fc3cb7b21b16ded465d5c0`, [Flutter CI #40215288643](https://github.com/im-tnyx/tio-world/actions/runs/40215288643): **SUCCESS 5/5**, including Flutter/Dart analyzer and all three Flutter test shards. Previous intermediate analyzer import and test matcher failures were corrected; passing result belongs to that precise code HEAD.
- Reviewer [P2 thread](https://github.com/im-tnyx/tio-world/pull/689) replied to, intentionally **unresolved until independent re-review**. Prior independent formal `CHANGES_REQUESTED` remains active. Do not claim that a late response guard cancels a network-dispatched mutation; it rejects stale completion in a new session.
- This handoff-only amendment advances the PR head; verify final exact-head CI again and request formal re-review. No admin override or merge without explicit owner instruction.
