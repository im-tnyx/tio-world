# A3 — Progress Weight Log Sheet + optional Note

**Status:** In review; A3 code HEAD Flutter CI SUCCESS 5/5; distinct independent formal review pending.
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

Code HEAD `5d0defa2266b9550c1e571eef030f081bda161de` verified against [Flutter CI #40263113491](https://github.com/im-tnyx/tio-world/actions/runs/40263113491) **SUCCESS 5/5** (Analyzer/Dart, core-wear/Progress, app-workout, nutrition-onboarding and aggregate), Docs Hygiene and Attribution **SUCCESS**. Prior `c34e6e70` analyzer failure (unnecessary Flutter reexported `characters` import) corrected; never claim prior head passed. Current head will advance for this handoff-only update and must be revalidated. Hosted Supabase queried read-only: own-row RLS/metadata and public avatar-only Storage, **no database/storage mutations**. Local Windows checkout/device QA NOT VERIFIED.

### Codex findings (7 total)

- First review `0a7fcbcf`: P2 prevent barrier/Back dismissal during save; P2 invalidate Settings cached Body/Profile state after confirmed write. Fixed by Core `showTioEditorSheet(isDismissible:false)`, A3 `PopScope(canPop: !saving)` + idle Close and app-composition `onWeightLogged` invalidation; focused widget tests.
- Second review `ba111be3`: P2 when old owner/session invalidated, remove the *exact* A3 modal route, not only its content. Fixed post-frame `Navigator.removeRoute`, listener cleanup, widget regression verifying no lingering root modal.
- Third review `e09a3444`: P2 preserve same-owner unsaved draft during realtime Profile unit refresh; P1 update Core theme README for new editor dismissal contract; P2 hidden note retains content; P2 match Flutter grapheme counting for emojis. Fixed with scope-keyed `progressWeightUnitProvider(owner:cycle)` and prior resolved AsyncValue only inside same owner cycle, test pausing canonical preference re-read; Core README; note save reading controller regardless of expansion; direct `characters` dependency/domain + UI .characters.length, and 300-emoji + collapsed note regressions. All seven Codex threads replied, **open pending formal independent review/disposition**.

**Review:** `im-tio` distinct account requested, no formal APPROVED as of this checkpoint. PR [#691](https://github.com/im-tnyx/tio-world/pull/691) OPEN/unmerged; owner `Go merge` not supplied. A4 Edit/Delete and private media/photos Slice B remain deferred. Branch compare was 31 task commits ahead, 0 behind, exactly 18 A3-owned paths before this docs checkpoint. Do not treat bot neutral status as approval.

## Fresh source/review checkpoint (2026-10-26, Codex P2 #11)

- Current A3 scope remains Log Weight with optional Notes; **do not** fold the approved Food-style footer follow-up into this open PR. Approved follow-up is [GitHub #692](https://github.com/im-tnyx/tio-world/issues/692), separately gated after PR #691 review, explicit owner merge, and post-merge sync. Linear child creation was unavailable due workspace issue limit; parent TNYX-119 remains the planning tracker.
- At prior code HEAD `02a562d3c6`, Codex [P2 #11](https://github.com/im-tnyx/tio-world/pull/691#discussion_r4373744758) found a controlled `lb` wheel echo: selecting 117.0 lb emits canonical kg, parent echoes it in `valueKg`, `didUpdateWidget` re-synchronized numeric drums and floating-point truncation could change 117.0 visibly to 116.9. This is a measurement-correctness defect, not cosmetic UI drift.
- Within the existing implementation-owner/scope boundary, committed Core wheel fix `b813d2c59e863634b3bb1fc13fcab371b142b9c0`: do not resync numeric drums for the wheel's identical canonical `_selectedKg` echo, but still sync genuinely external kg updates and unit changes. All lb numeric initialization/sync/selection highlight paths now round to display tenths before dividing whole/decimal indices; no new wheel or storage owner. Core regression `27921b66c26c85feae26d539584558a58c2ed225` tests selecting 117.0 lb with controlled parent echo and a genuine external 154.3 lb equivalent update.
- **Validation as of this write:** GitHub source and two commits verified; latest code-head [Flutter CI #40265708060](https://github.com/im-tnyx/tio-world/actions/runs/40265708060) **running**, Docs Hygiene CI SUCCESS. Do not claim Flutter tests PASS, independent `im-tio` review approval, local Windows `git status`, physical device QA or merge. All prior Codex threads remain to be independently dispositioned. Local checkout is not mounted in this connector environment.

## Latest exact-source gate: nullable picker fix and session dispose regression (2026-10-26)

- Read CI logs: Flutter CI #40265915057 showed **5 Dart null-safety analyzer errors** in `progress_weight_log_sheet.dart` for `DateTime? date` and `TimeOfDay? time` captured by `setState`. Fixed only the nullable closure capture with final guarded `selectedDate`/`selectedTime` locals in commit `0acb279a9a14227ff685cce05feae72f822020c4`. No date/time UI redesign, no data/schema changes.
- That fix's CI #40266452254 independently established **Analyzer PASS**, Nutrition PASS, while Progress core-wear shard had 98 passing tests and **one lifecycle test failure**: the Log sheet listener called `ModalRoute.of(context)` while `ProgressWeightPage.dispose()` invalidated the session and the sheet element was deactivating. This is a real UI lifecycle defect rather than infrastructure noise.
- Fixed only A3 sheet teardown by caching its `ModalRoute` and `NavigatorState` in `didChangeDependencies` (active context), using those safe references in the invalidation callback and post-frame exact-route cleanup with navigator-mounted guard. Source commit `efbbae2f64d9c804bd77240fee5ea1ff4b1cdc22`.
- Added explicit page-unmount-with-open-modal regression in `progress_weight_page_test.dart`, commit `1e0089468accf7d22405f61a01489df3fd572a9a`. Existing owner/session, date/time dialog and retry regressions remain the required checks.
- GitHub Flutter CI #40267027368 for source HEAD `1e0089468accf7d22405f61a01489df3fd572a9a` was **pending** at checkpoint; Docs Hygiene SUCCESS. No local Windows checkout, device QA, independent `im-tio` APPROVED, or merge claim. Owner permission is still required before merging PR #691. Approved follow-up [#692](https://github.com/im-tnyx/tio-world/issues/692) is separate and remains unimplemented.
