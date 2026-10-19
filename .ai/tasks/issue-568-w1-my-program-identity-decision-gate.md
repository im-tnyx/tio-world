# GitHub #568 — W1 canonical My Program identity and atomic direct Create decision gate

**Status:** Corrected physical shape OWNER APPROVED (2026-10-19 `Go`); decision PR at review gate, SQL implementation not started
**Primary owner:** W1 / Supabase-Postgres (data ownership and transactional persistence); later Workout feature/app integration
**Affected platforms:** Supabase SQL + disposable Database CI (future approved PR), Flutter Workout data/presentation/app (later separately gated)

## Owner Approval and Scope Boundary

**Trigger:** Exact Supabase column/table shape approval — **APPROVED in subsequent owner `Go` (2026-10-19) for EXACT column/index/grant scope**; this PR remains design-only.
**Owner-approved behavior and physical scope are distinct:** [GitHub #568](https://github.com/im-tnyx/tio-world/issues/568), [#475](https://github.com/im-tnyx/tio-world/issues/475) and [ADR-0015](../../docs/adr/0015-program-owned-routine-and-program-source-boundary.md) approve lazy, stable, renameable, non-deletable default identity with direct Library Create Routine; no fabricated empty Program, no orphan or duplicate, nonempty composition. The behavior approval alone did not approve the physical column/index; the owner's subsequent `Go` explicitly approved the shape stated below. Visible UI remains separately gated.
**Previously proposed; approved in follow-up owner `Go` (2026-10-19):** Add **only** `public.user_workout_programs.is_default boolean NOT NULL DEFAULT false`, plus **UNIQUE (user_id) WHERE is_default** (partial unique index). Existing Programs, including user-named "My Program", remain false and are **not automatically adopted, renamed, or reparented**. Old clients' Program name/ID insert and rename must remain functional; only server-authoritative paths may set the marker true.
**Explicit non-changes:** No SQL migration created/applied, table grants altered, user rows read/modified, Flutter UI/code, Move RPC grants, feature release, Delete Program, quotas, new backend service, PR merge, or physical QA in this design-only slice.

## Active Handoff

**Planning owner:** W1 identity/security architecture
**Implementation owner:** Supabase/Postgres (future approved SQL slice; **not started**)
**Review owner:** Independently review exact approved shape, auth/RLS, two-device concurrency, legacy compatibility and SQL tests
**Implementation ownership state:** Pending separately bounded SQL+tests implementation branch (no DDL yet)
**Ownership transition:** Not applicable
**Repository state last verified:** Protected `main@3d75d1b1224519d8a2a49c6528b1b4641fe5ebf0`, PR #618 merged; current branch from that SHA
**Observed working-tree state:** Remote GitHub branch only; owner's Windows checkout not accessed/synced
**Observed uncommitted/dirty files:** Owner previously reported unrelated `apps/features/nutrition/pubspec.lock` and Wear `GeneratedPluginRegistrant.java` modifications; preserve, not verified fresh
**PR / tracker:** GitHub #568; Linear [TNYX-78](https://linear.app/tnyx/issue/TNYX-78), downstream #567/#569, TNYX-81/W3
**Validation completed at SHA:** Read-only repo and live ACL/ADR verified, corrected owner-approved scope, two Codex P2 dispositions; no SQL/runtime test run
**Validation remaining:** Official CLI-generated versioned migration, disposable DB SQL/race/security tests, independent review, staged hosted rollout and app integration
**Current blocker:** Official CLI-generated migration filename and the separate source+tests implementation/CI gate; #554 numeric quotas remain separately unapproved
**Open review finding IDs:** None at start of design PR; new review findings must be dispositioned
**Next exact action:** Generate official versioned migration using the Windows CLI in a separate clean worktree; then implement the approved minimal schema/ACL plus atomic RPC and disposable SQL/two-session tests in a separate review-gated PR. Owner shape approval is already complete.

## 1. Discovery — owner-visible outcome

- A first-time account has **no Programs**, and opening/cancelling/failed direct Library Create Routine persists **nothing**.
- A successful direct Create persistently produces **one** canonical default "My Program", **one** owned Routine and its **nonempty ordered Exercise/Set composition**; when a default already exists (even renamed), reuse its stable ID.
- Program-scoped creation continues to use the explicitly selected owner Program, not My Program.
- Default may be renamed but must never be deleted, silently inferred by mutable name, first list item, local cache or predictable client-only UUID. Do not adopt/transfer existing legacy Programs by name.
- A confirmed write, uncertain result, replay, concurrent device operation, account switch, or rejected composition must never yield a second default or an orphan/empty new default.

## 2. Verified source/runtime baseline — 2026-10-19

- Source: `ProgramRepository` supports **list/create/rename**; `SupabaseProgramRepository` lists **id, name** and inserts client-supplied Program ID/name/owner. No default identity read/write or resolution capability.
- Live hosted `public.user_workout_programs`: **five columns** (`id uuid`, `user_id uuid`, `name text`, `created_at timestamptz`, `updated_at timestamptz`); no marker or default uniqueness. Owner RLS SELECT/INSERT/UPDATE applies; direct DELETE and table-wide UPDATE are denied, `UPDATE(name)` allowed.
- **P1 security design hazard (caught before any new schema):** `pg_class.relacl` explicitly contains `authenticated=ar` (table-level SELECT and **table-wide INSERT**), and `has_table_privilege('authenticated', ..., 'INSERT')=true`. Adding a writable `is_default` column **without revoking table-level INSERT in the same migration** would let a modified authenticated client set it directly. Direct `pg_attribute.attacl` audit confirms **no separate INSERT column grants** on those five columns; `information_schema.column_privileges` merely reflects effective table-wide INSERT. The three-column (`id`, `user_id`, `name`) grants must be **created explicitly** after revoking table-wide INSERT, in the same migration transaction.
- Proposed safe ACL transition in the future reviewed migration: `REVOKE INSERT ON public.user_workout_programs FROM authenticated`, then explicitly `GRANT INSERT (id,user_id,name) ... TO authenticated`; preserve owner INSERT RLS, existing name-only UPDATE and owner SELECT, but **no client INSERT/UPDATE on is_default**. Verify effective privileges, including inherited roles, with tests against both legacy and malicious client paths. Take care not to remove existing old-client ability to create regular nondefault Programs.
- Existing `public.create_user_workout_routine_with_composition(uuid,uuid,text,uuid,jsonb) returns bigint` is `SECURITY DEFINER` with empty search_path and grants only authenticated EXECUTE; its Routine metadata INSERT + protected composition writer occur in **one transaction**, rejecting empty Exercises/invalid payloads. Its FK is `(program_id,user_id)` to owned Program with `ON DELETE CASCADE`. Reuse it; do not duplicate composition validation or bypass its exact replay checks.
- GitHub #569 atomic **Create New Program + Move** is already deployed but dormant; live migrations **65/65**, Move RPC client EXECUTE still revoked and app Move release flag false. No new Move capability is authorized by this #568 contract.
- #554 Program/Routine inventory and write-rate limits require separately approved numeric policy; this design does not invent enforcement thresholds. #567 Delete Program needs a distinct secure lifecycle (default must be nondeletable).
- Canonical source: [ADR-0015](../../docs/adr/0015-program-owned-routine-and-program-source-boundary.md), [Program screen](../../docs/screens/programs.md), [Routine Library](../../docs/screens/routine-library.md); current runtime supersedes dated status snapshots.

## 3. Owner-approved schema; review-gated transaction implementation

### A. Stable canonical identity — preferred minimal proposal

1. `user_workout_programs.is_default boolean NOT NULL DEFAULT false` and partial unique per-owner default constraint/index, without changing Program IDs or owner/provenance boundaries.
2. All existing user Programs are **nondefaults**; no name-based adoption or implicit migration, even if displayed "My Program". No pre-seeding on signup, Library open or cancelled composer.
3. Server-created default uses an unpredictable UUID and `auth.uid()` as owner. Server **serializes per-owner default resolution** with **`SELECT ... FOR NO KEY UPDATE` on the owner `public.users` row**, a self-conflicting lock compatible with existing `FOR KEY SHARE` owner/FK reads. **Do not use `FOR KEY SHARE` as a serialization lock.** Then read the existing marked default by owner under this lock; a partial unique index is the final race invariant. Validate lock ordering against Routine create/Edit/Move/Delete, account deletion and older clients in 2-session CI before implementation.
4. Client can read the stable marker through owner-RLS and program repository projection once supported; Program rename changes only name. Do not make a second Program table/cache/identity source.
5. The same approved migration must harden authenticated table-wide INSERT to its three legacy client-supplied columns (`id`, `user_id`, `name`). Explicitly deny client mutation of `is_default`; owner checks and DB uniqueness enforce the invariant independently of Flutter.

**Alternatives rejected at this decision gate:** infer "My Program" by display name/oldest Program, rely on client list-then-insert, use a deterministic global UUID from account ID as the only guarantee (client-chosen global PK can be squatted), build a second default-Program source, or precreate on Library load. A separate immutable owner preference pointer/table is **not approved** by the owner's acceptance of the proposed one-column shape; do not build it.

### B. Atomic first-time Routine persistence — proposed server boundary

- **Do not call a standalone write-capable `ensure_my_workout_program()` before opening or saving the composer**. That would commit an unwanted empty default if the user cancels, a later Routine save rejects, or a request times out.
- Instead, propose **one owner-authenticated, server-authoritative RPC** (candidate name `create_user_workout_routine_in_my_program`) with a frozen client Routine UUID, mutation UUID, name and complete Exercises JSON. It resolves/creates the default and invokes the **existing** `create_user_workout_routine_with_composition` inside **the same SQL transaction**. Return the persisted default `ProgramId` and Routine revision for authoritative refresh.
- Composition validation failure must roll back the newly inserted default, Routine and children together. No asynchronous second client insert, client-side fake success, direct `UPDATE(program_id)` or broad grants.
- Retrying an uncertain result must reuse the same Routine UUID + mutation UUID + unchanged request, validate exact committed identity/composition and re-read the same marked default. Changed payloads or wrong owner/session must fail closed. Subsequent rename of the default cannot alter identity.
- First save when default absent, many simultaneous first saves, same-request replay and different-request races must serialize or resolve idempotently with no duplicate default; Program→Routine→composition lock order and account-deletion interactions need review. Post-Routine-create failure must leave no default.
- Restrict callable RPC to least-privileged reviewed owner-authenticated flow **only after tests**; new function starts with PUBLIC/anon/authenticated/service_role EXECUTE revoked while dormant, with explicit separate grant/release rollout. `SECURITY DEFINER` requires verified `auth.uid()`, empty `search_path`, owner scoping on every lookup and no direct exposed admin APIs.
- App-side Library direct Create must reuse the canonical Routine composer and avoid a fabricated Program row prior to save. Program-scoped Create remains on the existing path, unmodified by this design PR.

### C. Decision matrix

| Decision | Current state | Required next gate |
|---|---|---|
| Lazy default Program user behavior | **Owner approved** in #568 | Preserve |
| Exact `is_default boolean NOT NULL DEFAULT false` + UNIQUE user_id WHERE is_default | **APPROVED by owner `Go` 2026-10-19** | Separate SQL+tests implementation with timestamp generated by official CLI |
| Table INSERT ACL rewrite to protect marker | Security prerequisite **for** approved column | SQL ACL + legacy-client negative/positive tests |
| Single atomic default + Routine composition RPC | Proposed implementation contract | W1 security/lock-order review; avoid standalone pre-save ensure |
| Exact numeric inventory/velocity ceilings | #554 unapproved | Separate owner policy; do not silently add limits |
| #567 deletion / #569 Move, live grants or UI release | Separate scope | Independent acceptance/approval |

## 4. Review gate acceptance for the future SQL implementation (NOT run in this PR)

1. First-time account: open/cancel and definitely failed Create ⇒ **no Program/Routine**. Good Save ⇒ one default + one nonempty Routine, preserved Exercise and Set identity/ordering.
2. Second direct Create and renamed default ⇒ stable single Program ID, no display-name inference; existing user-created Program named "My Program" stays nondefault and untouched.
3. Two concurrent first-time Creates; same request retry before and after first commit; different requests on same owner; cross-owner A/B; bad auth/session; default uniqueness and correct per-request Routine payload.
4. Malicious authenticated `INSERT(...,is_default=true)`, table-wide `INSERT` and `UPDATE(is_default)` denied; old-client three-field Program INSERT/rename (timestamps server-defaulted) and new secure RPC still work. Exact RLS/ACL/function EXECUTE diff, default DELETE denied.
5. Default-create followed by composition rejection, stale/foreign Exercise, duplicate Routine ID, invalid client token, unknown/timeout, same UUID altered payload ⇒ no orphan Program and no false success.
6. Lock/race against owner deletion, Delete Program (#567), existing protected Routine operations and legacy direct Program writes; avoid deadlocks or cascading Routine loss. Verify negative cases with real two-session disposable Postgres harness.
7. Reconcile #554 quotas as a **separate** explicit acceptance dependency, not fabricated in this migration.
8. With exact owner schema approval recorded: new versioned migration + disposable SQL tests under `supabase/`; required DB CI, latest-head attribution, independent security/code review and resolved inline findings. **No hosted deploy or client grant at implementation PR review gate**, no merge without explicit owner instruction.

## 5. Current PR completion / next action

This PR delivers **audit + decision-ready contract only**, not source implementation. Do not mistake a green docs-only check for reviewed SQL or a tested default Create.
- Review for incomplete old-client ACL implications, unique-default/failure atomicity, owner authentication and replay; correct P1/P2/P3 findings before review handoff.
- **Shape gate satisfied by owner `Go` (2026-10-19), incorporating Codex P2 corrections.** Implement the minimum SQL/tests in a **separate** source PR, after generating a versioned filename with the official `supabase migration new` CLI; do not guess a version or apply SQL to hosted Supabase. Keep hosted SQL, client EXECUTE and production Flutter unchanged until their distinct approval gates.

**Codex P2 dispositions (2026-10-19):** Original direct Program create only submits `id/user_id/name`, so the proposed future grants do **not** include timestamp columns; defaults own those values. Per-owner `FOR NO KEY UPDATE` is mandatory to serialize absent-default resolution (self-conflicting, but compatible with existing account `FOR KEY SHARE` checks); exercise actual two-connection races before accepting the implementation. Both findings concern the *proposal*, not an already deployed schema.

### CLI/remote implementation boundary (recorded at owner approval)

Use the owner's installed Supabase CLI v2.121.0 from a **fresh safely synced worktree** to generate `supabase migration new w1_my_program_atomic_default_create`. Record the actual generated filename; do **not** invent a migration version, link a hosted project for DDL, or `db push` as part of this decision PR. Once that filename is known, implement only the approved Program column/index + timestamp-safe three-field INSERT ACL correction and one dormant atomic wrapper RPC around the established Routine-composition writer; add disposable SQL negative/positive matrix and real two-session race tests, wire DB CI and stop at review gate. Existing owner Windows Nutrition/Wear dirty files must be preserved.
