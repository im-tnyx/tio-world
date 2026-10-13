# GitHub #535 — Atomic Routine Create foundation

**Status:** Database-first source CI validated at `cb1679c2`; Draft PR #536 unmerged, independent review pending; no user-visible change or hosted deployment.
**Primary owner:** Supabase Workout data contract; later Flutter Workout/app integration after PR #533.
**Affected platforms:** Supabase Postgres/RLS, later Flutter mobile.

## Owner Approval and Scope Boundary
**Trigger:** Owner-approved independent Routine Create behavior correction, plus narrow existing-table server RPC contract.
**Approval status:** Approved (owner "Next go" following explicit RPC + Flutter integration proposal, followed by "Go next").
**Approval evidence:** 2026-10-13 owner screenshot-backed requirement: no zero-Exercise Routine save; subsequent request specifically approved a new owner-scoped atomic create RPC on existing tables and Flutter integration via separate PR.
**Approved boundary:** Create a Routine + at least one canonical Exercise in one DB transaction, preserving Program ownership; idempotent confirmed retry and active Custom Exercise verification. Only one existing Program; no standalone Routine identity. Integrate canonical picker/editor after #533 is available.
**Explicit non-changes:** No table/column shape, direct workout start, Exercise definitions, other Routine editing, watch, AI, connector, media, superset, timed sets, rep ranges; no hosted migration deployment or silent merge.

## Active Handoff
**Planning owner:** Connected Tio-world architecture session.
**Implementation owner:** Connected GitHub session, exclusive for this #535 Supabase migration/test slice; **does not** own PR #533's editor/picker source.
**Review owner:** Independent reviewer/Codex after CI.
**Implementation ownership state:** Active on independent DB-only paths; Flutter Create integration paused until PR #533 is merged/ownership transfer.
**Ownership transition:** Not applicable; existing PR #533 owner unchanged.
**Repository state last verified:** GitHub protected main at `ee5ed4cc67bfb6c8d3eb867129578201b60703bc`; PR #533 Draft, exact separate head `9961d7230ddc9437ec316dd8540e8a1847baca80`. Existing hosted migrations end at `20261010061809`; no #535 RPC deployed.
**Branch:** `tnyx/issue-535-atomic-routine-create`, based on exact protected main.
**Observed working-tree state:** Remote GitHub only. Owner's Windows local dirty status and local Dart/SQL tools not available in this session; do not claim local validation.
**Observed uncommitted/dirty files:** Not inspectable on owner's Windows checkout.
**PR / tracker:** GitHub #535, #533 prerequisite, #534 archived-Custom save race; Linear TNYX-81 Backlog blocked by TNYX-78/TNYX-80.
**Current implementation state:** Database contract audit confirmed existing metadata create and separate save RPC permit empty Routine. New atomic RPC + SQL tests are the first disjoint slice.
**Relevant execution surface:** `supabase/migrations/`, `supabase/tests/database/`, `.github/workflows/supabase-db-ci.yml`.
**Validation completed at SHA:** `cb1679c2e0488e23a31bcc1d7f7b8e0f44709bfa`: [Supabase Database CI #38359620572](https://github.com/im-tnyx/tio-world/actions/runs/38359620572) SUCCESS (full migration replay, existing SQL/race tests, #535 SQL test, #535 two-session same-ID and archive-order races, no new lint error). Commit attribution guard and runner SUCCESS on same SHA. Initial #535 SQL test CI failed from an overly literal catalog search_path assertion; repaired test-only to Postgres stored `search_path=""` verified against deployed canonical function; no RPC semantic change.
**Validation remaining:** Independent latest-HEAD Codex/security review, then Flutter Create integration and device QA in a separate owned slice after #533 dependency clears. Draft docs-only HEAD after this checkpoint is not claimed to be the SQL-tested SHA.
**Current blocker:** PR #533's canonical Exercise picker/editor remains Draft and exclusive. Its latest Codex re-review has 3 unresolved P2 (login-cycle pre-RPC recheck, indefinite preflight Cancel/Back lock, truncated Custom owner listing). #535 Flutter Create integration must not clone picker/edit while these remain unresolved.
**Open review finding IDs:** #534 server-side archive-vs-save hardening for existing **edit** RPC remains open.
**Next exact action:** Request independent #536 DB/security review at latest HEAD, disposition findings without merging. Once #533 is separately reviewed and owner-approved/merged, start feature-owned Create integration on fresh main with explicit single-owner transfer; no hosted deployment or merge without owner gate.

## Discovery / Runtime Evidence
- `ProgramDetailPage._RoutineNameSheet` enables Create for nonblank name only; `ProgramRoutinesController.create(name)` calls `RoutineRepository.create` with no entries. `program_detail_page_test.dart` preserves that older metadata-only behavior until full integration.
- `public.save_user_workout_routine_composition(uuid,bigint,uuid,jsonb)` requires an existing owner Routine; one function call replaces ordered entries/Sets under a revision+mutation guard. An empty array is currently accepted by **edit** to preserve legacy removals. Do not change that behavior globally.
- Existing owner Routine + Program FK, child FK, grants/RLS and catalog Custom references are already deployed; no table/column expansion needed.
- On new create, validate >=1 Exercise and owner Program, insert metadata, enforce active Custom refs while locking their row lifecycle, then call existing composition RPC **within one server transaction**. A failed call rolls everything back. Handle same Routine UUID+mutation retries by validating immutable inputs and canonical persisted payload, not by inserting a second row.
- Retain old metadata-only create while old clients exist; retiring this write permission is a separate coordinated client rollout gate, not a silent privilege migration. Until Flutter switches, old clients can still create empty Routines. Never claim #535 product requirement shipped from an RPC alone.

## Architecture and security
- New function in `public` (API surface) is `SECURITY DEFINER`, `set search_path = ''`, fully qualified objects, and requires authenticated `auth.uid()`. Revoke EXECUTE from PUBLIC/anon/service_role and grant only authenticated. Existing direct table INSERT remains untouched for old clients.
- Reject zero Exercises, blank name, invalid owner, foreign/missing/archived Custom refs and unexpected payload; delegate canonical entry/Set validation to existing RPC rather than duplicate source of truth.
- Serialize active Custom Exercise archive writes with `FOR SHARE` on the owner+active Custom rows during new creation; do not misrepresent that as #534's unresolved **editing** RPC fix.
- Handle same ID/identical mutation replay, changed payload, wrong Program/name, different mutation ID, concurrent same-ID creation and uncertain-client retry safely.
- Rejected alternative: Flutter metadata Create followed by composition Save (partial durable empty Routine if second write fails). Rejected: editing PR #533's picker before its implementation ownership is transferred.

## Quality gates and handoff
- Disposable database migration replay + SQL tests + two-session concurrency (same UUID retry and Custom archive race).
- Supabase Security Advisor has existing `authenticated_security_definer_function_executable` notices. New narrow API must justify least-privilege invocation and no general role execution; record risk but don't silence advisory.
- No production Supabase change, no branch merge, no release until explicit owner action.
- Final status: PARTIAL until complete Flutter Create flow with Save disabled for zero entries and atomic persisted success.

## 2026-10-13 database-source validation milestone

- Draft [PR #536](https://github.com/im-tnyx/tio-world/pull/536): exact database source SHA `cb1679c2`. Migration, SQL regression matrix, 3 two-session lock scenarios and CI added. Remote `main@ee5ed4cc` remained unchanged.
- GitHub [Supabase Database CI #38359620572](https://github.com/im-tnyx/tio-world/actions/runs/38359620572): **SUCCESS**. Exact SHA attribution check and runner: **SUCCESS**. The earlier test run failed on test-only `pg_proc.proconfig` formatting, not on migration replay, and the following exact-source run passed the full matrix.
- Supabase hosted schema was **not modified**. Existing metadata-only direct client INSERT remains available until a safe client rollout, so no general product-level guarantee that empty Routines cannot be created yet.
- New Codex #533 re-review has three unresolved P2 threads; do not consume its editor source as settled or fork a second picker. #534 edit-save Custom archive race remains open and is not a claim about #536.
- Flutter Create screen, Save disabled state, and device QA are not implemented in this DB-first PR. These acceptance items remain mandatory before closing #535.
