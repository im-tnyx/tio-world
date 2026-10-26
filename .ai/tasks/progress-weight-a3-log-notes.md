# A3 — Progress Weight Log Sheet + optional Note

**Status:** In progress; implementation authorized 2026-10-26, review/CI pending.
**Primary owner:** `apps/features/progress` (domain, UI, repository) with `apps/app` composition only.
**Planning:** Linear TNYX-119 In Progress, TNYX-154 Settings ↔ Progress ownership boundary; merged D0 #687, A1 #689 and A2 #690 (`main@b255ef4095cb23192e72e308c93cf5d020cda255`).
**Implementation owner:** GitHub `im-tnyx` connector, isolated branch `feat/tnyx-119-progress-weight-a3-log-notes`.
**Review owner:** distinct `im-tio` reviewer after CI.
**Local Windows checkout:** `G:\projects\Tio-World` not mounted. Do not claim local Flutter tools, worktree checks or physical device QA.

## Approval and product boundary

Owner approved start and explicit icon behavior 2026-10-26: Log Weight sheet reuses existing Core `TioWeightWheel`; Notes icon reveals optional note field only when pressed; Photo has a separate icon. Previous approval/audit establishes A3 manual Weight + selected date/time and optional note; Photos are **separate gated Slice B**. Since the only live Storage bucket is public `avatars`, no active Photo picker/upload/link or fake saved-photo state is authorized in A3. A clear disabled photo affordance may describe the future capability. No A4 edit/delete actions, inactive Body/Health/Photos tabs, schema/Storage migration or unrelated UI redesign.

## Discovery

- Read root `AGENTS.md`, `apps/features/AGENTS.md`, Core theme README, feature workflow, task template, architecture/ownership/security, Progress contract and current A2 source.
- Core already owns `TioWeightWheel`, `TioEditorSheet`, `TioInput.multiline` and `TioButton`. Settings uses the same wheel with canonical-kg output; reuse public Core contract.
- A1 `BodyRepository.recordCurrentWeight` inserts a new owner-scoped row into `public.body_weight_logs` with `weight_kg`, `measured_at`, `source`; no note contract today. Table has `metadata jsonb NOT NULL DEFAULT '{}'`, UUID `id`, positive weight CHECK, own-row RLS, no note column. A3 can represent a bounded optional note in existing metadata with legacy-safe decode; do not create schema.
- A2 `ProgressWeightPage` is read-only summary/chart/history. Owns refresh; app composition passes repo, owner/login cycle and global unit. A3 integrates without new route/source.
- A1 create command lacked caller-stable identity; A3 should avoid duplicate submit on rapid taps and ambiguous save response, without changing Settings/Body Goal semantics.
- Existing A2 task/index status is stale (says In Review) though PR #690 is merged. Reconcile index in this task, do not silently edit other old handoffs.

## Bounded deliverables

- Weight sheet: wheel using globally selected unit; explicit local measurement date/time resolved to UTC; note IconButton toggles `TioInput.multiline` field (optional, bounded/validated); disabled/future-photo affordance clearly disclosed.
- Canonical `BodyWeightRecord`/History optional note support and repository parity (Supabase metadata + InMemory); legacy histories remain readable; exact-A1 update/delete preserve note and metadata.
- Save-once/in-flight and stable draft identity/retry protocol for Supabase inserts; no silent duplicate creation if server committed before client error. Surface failure without discarding draft.
- Auth/session fail closed before writing or publishing cross-session responses; refresh A2 after confirmed success; focused repository/domain/widget/route tests.
- CI + independent GitHub review gate; do **not** merge unless explicit owner `Go merge`.

## Verification

No new Flutter/CI/device validation yet. Hosted Supabase queried read-only: owner RLS/metadata and Storage buckets; no DB or Storage changes. Exact-head checks and changed-file list must be documented at review checkpoint.
