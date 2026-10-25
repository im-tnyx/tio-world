# Progress Weight A2 — read-only dashboard and History

**Status:** In progress — approved implementation slice; PR/review gate pending
**Primary owner:** Progress/Body `apps/features/progress`; app shell composition in `apps/app`
**Affected platforms:** Flutter Android + iOS phone
**Approval:** Owner explicitly requested "Go A2 — Progress Weight Screen" on 2026-10-26; product-visible Weight dashboard, chart and History approved. No merge authorized.
**Implementation owner:** `im-tnyx` GitHub connector on isolated branch (sole source writer)
**Review owner:** independent distinct reviewer to be requested once CI validates; author self-review is not independent
**Base SHA:** `main@2f95bb81f61a6979f5b0f6d96767ba4e50bd639b` (A1 #689 squash merge)
**Branch:** `feat/tnyx-119-progress-weight-a2-screen`
**Local worktree:** Windows `G:\projects\Tio-World` unavailable in connected execution environment; local `git status`, Dart and Flutter SDK checks cannot run here. GitHub API and CI are source/validation surfaces.
**Planning:** Linear TNYX-119 (In Progress), TNYX-154 (Settings/Progress ownership boundary); D0 #687 merged; A1 #689 merged.
**Agent context:** Linear `get_agent_context` was invoked before task work but integration returned `Tool get_agent_context not found`; other Linear issue reads succeeded. Do not invent shared field notes.

## Verified discovery

- `AGENTS.md`, `apps/features/AGENTS.md`, `apps/core/lib/src/theme/README.md`, `.ai/FEATURE_DEVELOPMENT.md`, task template, D0 contract and A1 source inspected.
- `apps/app/lib/app/routing/shell/shell_route.dart` maps Progress to `TioShellPlaceholder`; existing shell retains primary-tab navigation and chrome.
- A1 `BodyRepository.getWeightHistory` uses owner-scoped, login-cycle-guarded, ID-stable keyset paging `(measured_at DESC,id DESC)`; `getBodyState` returns goal and latest weight but current selection is not future-safe or tie-stable. A2 must use eligible History projection for **displayed** Current Weight, not modify Settings/Body Goal lifecycle.
- Live `body_weight_logs` and `user_body_goals` have enabled RLS and ownership predicates for SELECT/INSERT/UPDATE/DELETE (including UPDATE WITH CHECK); no schema migration is required.
- Approved owner references: Weight summary/current/range trend/goal, History below chart, existing app navigation. A2 must not render inactive Body/Health/Photos tabs or misleading enabled Log/Edit actions.
- `TioCard`, `TioButton`, `TioSpacing`, `TioSize`, `context.tioColors`, `UnitFormatters`, `UnitConverters` already exist. Avoid feature-local theme/token catalogs.

## Bounded implementation

1. Progress-owned reader/controller derives latest eligible Current Weight from `getWeightHistory` with an exclusive bound immediately after captured UTC `now`. Same-time tie behavior comes from A1; no changes to canonical `getBodyState` or backend goal RPC.
2. Selected-range chart loads all actual measurements in the window via A1 keyset paging; range change computed only with at least two comparable real points, no smoothing/interpolation/fake percentages. Active goal used only as a target reference.
3. History in chronological DESC ID tie order, separate initial page + explicit Load More, multiple same-day records kept intact; date/time displayed in local timezone and global kg/lb unit respected.
4. Screen state gates by authenticated owner/login-cycle at app composition, resets on session changes, discards stale asynchronous results; loading/empty/error/retry/no-goal; responsive scrolling and accessible textual summaries/history.
5. Focused reader, widget and routing tests; CI + independent reviewer gate.

## Explicit non-goals

No A3 Log Weight bottom sheet/new insert action, A4 Edit/Delete UI, Body/Health/Photos activation, Storage, Supabase migration/RLS/RPC, Profile or Settings/Body Goal semantics changes, theme tokens, Watch, public rollout, or merge.

## Quality / handoff

**Validation completed:** None yet at task initialization. Do not claim Flutter test or local worktree validation until real evidence exists.
**Required:** focused and CI Flutter analyzer/tests, app shell route regression, branch compare/changed-file audit, reviewer verdict and unresolved thread audit. Update task with exact-head evidence.
**Known risk:** large-range chart pagination and expensive loads; preserve truthful empty/error state rather than silently truncate data. Stale auth/cycle responses must never become rendered health information.
**Next:** implement bounded A2 files on this branch, open focused PR, verify head and CI, request independent review. Leave unmerged until explicit owner instruction.
