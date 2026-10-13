# GitHub #535 — Atomic Routine Create foundation

**Status:** In progress — bounded database-first draft; no user-visible change or hosted deployment.
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
**Validation completed at SHA:** None yet for #535. Existing PR #533 source CI at its distinct head is not #535 validation.
**Validation remaining:** Exact-head disposable Supabase DB CI including new SQL regression and concurrency tests; security-advisor review, manual code/security review. Flutter integration/device QA afterward.
**Current blocker:** PR #533's canonical Exercise picker/editor is unmerged and owned by another implementation slice. Never clone or edit its source concurrently.
**Open review finding IDs:** #534 server-side archive-vs-save hardening for existing **edit** RPC remains open.
**Next exact action:** Review/implement transactional create function and tests, run exact-head CI, then request independent review. Do not deploy or merge without explicit owner gate.

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
