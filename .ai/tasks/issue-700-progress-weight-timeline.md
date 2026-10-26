# Progress Weight Timeline — #700

**Status:** In review (PR #701 against main; do not merge without explicit owner instruction).
**Approval:** 2026-10-26 explicit owner message with two image references approving a visual Timeline refresh.
**Implementation owner:** GitHub `im-tnyx`; no source edits by the separate reviewer account.
**Scope:** Progress-owned Flutter presentation only, month grouping, weight/change chips, honest Today/New low, optional persisted note. Source remains A1 owner-scoped paginated History.
**Base:** `main@8fabf524a67bf13131225974d4d01288a6588b41` (merged PR #698), reconciled at `99328c88bd412ed851394ea7bfe9b3293a9e4ac8`. Child `feat/issue-700-progress-weight-timeline`.
**Trackers:** GitHub #700, Linear TNYX-119 In Progress. Root/feature AGENTS, canonical Progress docs/Core README and repo workflow read.

## Discovery
- Current `ProgressWeightPage` uses one flat `TioCard` per History entry; A1 history is newest-first stable-id and pages at 30. `ProgressWeightDashboardReader` retains future-dated rows in History but excludes them from eligible Current/chart. The user's reference has date/status column, prominent kg, delta badges, month sections, Today/New low.
- Existing UI Core `TioCard`/Tio colors/sizing suitable; screenshot's purple color theme and unverified 'Trend' numbers must not be copied.

## Architecture/decisions
- New presentation projection uses only currently loaded owner-scoped History, captured UTC time and `hasMore`. For each entry show signed difference to immediately preceding older actual instant; same-instant and missing previous display no delta.
- 'New low' requires complete History page coverage and strict lower weight than all older eligible entries; never claim all-time record while older pages exist. Today requires measured date's local day match and no future.
- Month headings based on measurement's local month/year, preserve actual order/IDs; Tio theme colors for attention, and benefit/harm color only when canonical Lose/Gain direction is known.
- Rejected: fabricating Trend smoothing, new backend queries/schema, modifying Core or Nutrition visuals, duplicate weight source.
- Keep PR #698's fixed Log Weight, compact chart and #695's editor sheet untouched; no Edit/Delete, Photos, Supabase or extra features.
- Source/test/doc only, tracked isolated branch. Windows checkout/Flutter SDK not available from current connected tools.

## Validation and gates
Focused projection tests for same-time/missing comparison, future Today, partial history low, plus widget checks for month groups, note, global lb, genuine New low. Require exact-HEAD Flutter tests/analyze, independent review, phone visual/compact/text-scale checks; cannot claim these until run. GitHub Actions PR workflows target base main only, so stacked child PR does not auto-run Flutter CI. **No merge** until owner explicit Go merge and all applicable gates pass.

## Review handoff checkpoint

- PR #701 now targets `main`, not the original stacked parent. Parent PRs #695 and #698 are merged; reconciliation commit `99328c8` preserved #698's optional-fallback P2 fix and test.
- Exact-head GitHub Actions launched only after targeting `main` and pushing new changes. Reconcile the newest commit's CI and independent review results before any merge.
- Source/docs were inspected remotely. Local checkout, Flutter/Dart execution and physical Android/iOS screenshot verification were not available from this execution environment. Do not claim visual QA.
- **Gate:** Not merge-ready until Flutter CI, Codex P2 disposition and applicable visual/layout checks are verified; owner separately prohibited merging in this slice.

## 2026-10-26 review + compact-card checkpoint

- PR #701 rebased by reconciliation merge onto merged `main`; scoped six-file diff, without dropping PR #698's optional-fallback P2 fix/regression. Root owner requested **smaller Timeline card height**, without changing screen structure or missing/owner-scoped Weight truth.
- Codex reviewed `99328c8` and found one P2 unit-test failure: fractional `-0.8` delta equality; replace only the matcher with `closeTo(-0.8, 0.001)`. Do not round production weight deltas to satisfy a test.
- Compact cards: Core `TioCard` retained, vertical padding `lg → sm`, Today dot aligned inline with date, recorded time remains below, inter-card gap `sm → xs`. Keep notes untruncated, Change/New low badges, global kg/lb, Today border, pagination, and pinned Log Weight. Add baseline widget geometry regression (<80dp), preserving text/weight and action visibility.
- Validation: GitHub read/review/source audit only before this patch; Flutter CI, reviewer disposition, and device screenshots pending. Older base/stack statements in prior checkpoints are historic, not live planning.

## Exact-head CI repair (following `370811e`)

- GitHub Flutter analyze (on `370811e`) flagged one `unnecessary_non_null_assertion` in the strictly-older delta projection. Removed redundant `!`; nonnull guard is retained.
- Progress widget shard exposed a pre-existing brittle expectation: Current summary **and** Timeline now both display `160.9 lb`. Replaced global single-text assertion with Timeline-card descendant assertion so the test checks the intended owner UI, not a duplicate count.
- Docs hygiene failure on `370811e` traced to markdown trailing spaces; corrected at `56ffabe`, whose docs hygiene check passed. All Flutter CI gates must re-run on the latest code HEAD; neither this note nor earlier runs count as validation.

## Owner card-height correction + Codex accessibility guard (2026-10-26)

- Owner observed variable Timeline card heights; corrected within the approved Timeline UI slice. All rows use a consistent 80dp height at the normal 390dp/1x viewport, irrespective of Today, badge or note. Longer notes have a one-line preview with the full saved note retained via Tooltip (no data loss).
- For narrow widths/accessibility text sizes, all cards in that viewport grow to the same taller shared height. Badge actions relocate below measurements rather than truncating lb/kg and user-entered weights. Small-screen/large-text physical layout remains to be QA-tested.
- Added widget regressions covering equal-height mixed cards and larger text with New low + lb; prior baseline height test now asserts exact 80dp. Continue exact-HEAD Flutter CI and independent Codex review; no merge.

## 2026-10-26 exact-head Flutter CI repair audit

- Confirmed HEAD `d84fd32a` failed Flutter CI run `40321469602` in `Test Flutter (core-wear)`: Progress shard 131 passed / 1 failed. Aggregate `Analyze and test` failure is downstream; Flutter/Dart analysis and other two Flutter shards passed.
- Root exception in the new 1.8x text widget test: chart date-label `Row` at `progress_weight_page.dart:461` overflowed horizontally by 158px. Make both date labels flexible, retaining full text through wrapping and baseline normal-scale alignment.
- The same test assumed both Timeline cards are mounted simultaneously, but the older record is below the lazy ListView viewport. Verify two row heights sequentially after scrolling, not via a false global count.
- Latest Codex P2 identified a Today-border 2dp width mismatch between Timeline badge stacking and fixed-height decisions near 337dp. Use a shared width predicate, reserve that inset consistently for every card, and add a narrow Today/non-Today equal-height/overflow regression. At standard 390dp/1x, 80dp same-height contract remains untouched.
- Scoped to existing approved #700 Progress UI/test repair. No schema/Auth/RLS/Storage change; TNYX-119 remains In Progress. GitHub source edits are committed by existing `im-tnyx` implementation owner only. Linear `get_agent_context` was unavailable (tool not found), while `get_issue(TNYX-119)` succeeded.
- Exact new commit Flutter CI, independent review, and physical Android/iOS screenshot QA still require verification; **do not merge** without separate owner instruction.

## 2026-10-26 independent review P2 performance fix

- Independent `im-tio` review on exact HEAD `92a1ba59` reported a real P2: the synchronous Timeline projection used nested full-History scans per row, `O(n²)`, while pagination can grow indefinitely. This is a code-performance issue, not an infrastructure problem.
- Replaced per-row suffix search and `priorOrConcurrentWeights` allocations with a reverse `O(n)` pass over canonical `measuredAt DESC, id DESC` History, grouped by the exact measurement instant. The closest strictly older eligible entry is used for delta; older eligible minima and equal-time minimum/tie count govern the conservative `New low` badge. Future records and incomplete pagination never create phantom lows.
- Added 6,000 timestamp-group/12,001-row regression covering ordering, sibling differences, earlier delta, future exclusion and incomplete pagination, plus a tied same-instant minimum negative-path regression.
- Previous exact-head Flutter run `40323286661` on `92a1ba59` was SUCCESS in all Flutter analysis/shards and Docs Hygiene; that success does **not** validate this new commit. Exact-new-HEAD checks and independent re-review remain required. Do not merge without an explicit owner merge instruction.

## 2026-10-26 Owner-approved graph and range menu extension (same PR, no merge)

- Owner explicitly requested graph-focused Weight summary, **separate Current / selected `N DAY CHANGE` / `RATE OF CHANGE` Tio cards** and, after read-only Core/Nutrition audit, gave `Go` to replace the material `PopupMenuButton` with existing Nutrition-style `MenuAnchor + TioCard.elevated + MenuItemButton`. Owner previously prohibited opening another PR unless #701 was merged first, and has not authorized merge. Therefore the extension stays in the existing PR #701 review branch; its old approval/CI status **must be revalidated** after the new commit.
- No new design system component. Changed only Progress page, read-only dashboard projection, focused widget/model tests, canonical Progress doc and handoff. Existing `TioCard`, `MenuAnchor`, theme tokens and fixed Log Weight action are preserved.
- Rate = signed actual newest-minus-oldest eligible selected-window kg change multiplied by seven and divided by elapsed measured days. Require two distinct instants; `null` shows unknown instead of fabricating rate. Unit follows global kg/lb. A real equal-weight interval yields zero, not unknown.
- Verification gates: latest HEAD Flutter CI, menu selection/dismissal, chart/stat separation, narrow/accessibility, exact range semantics, independent re-review and Android/iOS light/dark layout. Physical QA and formal independent approval remain **unverified**. No merge.

## 2026-10-26 exact-head CI test-only correction

- HEAD `f061034c` Docs Hygiene passed; Flutter Analyze failed only because the new widget test referred to unexported `ProgressWeightRange` as a generic type argument while asserting absence of `PopupMenuButton`. The reusable elevated `TioCard`, three `MenuItemButton` options and selected range behavior are already asserted. Removed this redundant compile-time assertion rather than importing a private presentation type solely for a negative test.
- All Flutter CI checks must rerun on the resulting HEAD. No approval or merge.

## 2026-10-26 new stats extension: Timeline lazy-list regression

- On `b1adc7a5`, exact-head Flutter Analyze/Dart succeeded. The core-wear shard's 140/141 Progress tests showed one existing large-text Timeline test assumed its first card was mounted at initial scroll offset. The newly approved three cards correctly push Timeline below the fold at 390dp/1.8x; this is an invalid test visibility assumption, not license to reduce/change the approved cards.
- Adjusted the test to `scrollUntilVisible('Today')`, then measure that card's own full lb value and later the strictly older card; preserves accessibility and equal-height assertions. New exact-head CI is required; **no claim of PASS until it completes**.

## Device QA correction: wheel and record calculation

Owner-reported Android QA: weight wheel lacks the original kg/lbs drum; restore existing Core three-drum `TioWeightWheel` with sheet-local unit selection, without changing global preference or canonical kg writes. Goal-directed record marker requires the newest eligible row, strict all-history proof and direction (`loseWeight` New low / `gainWeight` New high), none for Maintain/unknown. Approved further UI corrections and exact-ID History Delete will follow under same PR and must be revalidated before merge. Status REVIEW, not approved.

## 2026-10-26 same-PR device QA layout correction

- Graph target sentence removed and goal distance moved to independent horizontal TioCard; the value is derived from canonical current/target, never hard-coded from reference imagery. Smaller aligned stat cards (third spans full width on narrow phones), reduced chart padding. Weekly rate suppressed for intervals below seven elapsed days; actual range change retained. Timeline uniform baseline 72dp (narrow stack +40dp), Today border 0.75dp Core stroke, goal record beside the weight and not stacked into the delta badge; no markers when no active Lose/Gain goal.
- Pending: exact-ID History Delete action + security/session tests, CI, independent review/visual QA. No merge.

## 2026-10-26 exact History delete action

- Each Timeline card now has an explicit small delete icon for its immutable `BodyWeightEntry.id` and uses Core `showTioConfirmationBottomSheet` with destructive intent. Cancel/no-answer never touches data; confirmed calls existing owner/session-pinned `BodyRepository.deleteWeightLog(id)` once and refreshes real current/chart/History and app-owned Body caches. Missing/deleted row or exception is non-optimistic and shows a generic result without identifying the owner/weight in logs. Session and async generation checks suppress stale UI update. No direct Flutter-to-privileged API, new schema/RLS/Storage or delete-by-row-position.
- Device QA checkpoint: latest commit CI and independent review required; do not merge.

## 2026-10-26 CI lint gate

Flutter Analyze on `696b8f27` found one `curly_braces_in_flow_control_structures` info in the delete-confirmation handler. Corrected braces only. The prior check is not a PASS and new exact-head Flutter CI is required; review/merge still pending.

## Latest CI diagnostic corrections

Flutter Analyzer on `696b8f27` flagged one missing block-brace lint (fixed at `ba59d5fb`). The core-wear shard had 144/145 Progress tests successful; the only failure was a new goal marker test fixture missing mandatory `weeklyWeightChangeKg` for Lose Weight, not a production failure. Added the required test goal pace. Reduced timeline badge horizontal/vertical padding and date-to-weight gap to preserve full kg/lb text next to status and delete affordance. Exact-HEAD CI pending; no merge/review bypass.

## 2026-10-26 owner correction — pencil on Timeline, Delete inside Edit sheet

- Owner explicitly replaced per-card delete with an accessible pencil that opens an Edit Weight bottom sheet, and moved Delete to that sheet's pinned footer. Preserve same-PR scope and do not merge.
- Reuse the existing Progress-owned composition of `TioEditorSheet`, `TioWeightWheel`, Core DateTime picker and pinned footer rather than building a duplicate editor. Editing is addressed by the exact canonical UUID: `BodyWeightLogEdit(id, weightKg, measuredAt)`, with no new record or changed source/metadata. Existing private notes are displayed read-only: the current backend edit contract does not write note metadata, so Notes/Photo inputs are not enabled for edit.
- Deletion remains a separate Core destructive confirmation within the editor, invoking existing `BodyRepository.deleteWeightLog(id)` with caller session-generation checks; refreshing real owner-backed state on success/known absence. Validate cancellation, update identity, session invalidation and load/graph/Timeline refresh. Latest CI/re-review/device QA mandatory; not approved or merged.

## 2026-10-26 exact-HEAD edit-test import correction

On `0c39c74e`, Dart Analyze of production Progress code passed; the newly added edit sheet widget test referenced `BodyWeightEntry` without importing the public `tio_feature_progress/progress.dart` boundary, producing one `undefined_function` error. Added the missing public import. Exact new-head Analyze and tests, independent review and Android/iOS QA remain mandatory; not merged.

## 2026-10-26 final screenshot alignment correction

Owner clarified that "30 DAY CHANGE" belongs only inside chart (beside CURRENT), and below there must not be another N-day-change card. Retain three equal-width cards beneath chart as in reference: STARTING and CHANGE are active goal baseline and signed lifetime goal change, while RATE OF CHANGE is selected-window pace. They are distinct from selected-range N DAY CHANGE. Chart has target guide label and separate compact target-distance horizontal card. Avoid fabricating baseline; missing data displays —. Keep Core theme/tokens and 320–390dp/large-text behavior, with fresh exact-head CI and independent review before merge.

## 2026-10-26 latest head analyzer correction

Flutter Analyze on `e1f25c5b` found two undefined feature token symbols introduced by the screenshot refactor: `TioSize.dp280` and `TioFontSize.size10`. Replaced with documented existing governed values (`TioSize.dp320 - TioSize.dp40`, `TioFontSize.size10_5`) without adding Core tokens or changing layout intent. All checks must be rerun at the new exact head, no approval/merge.

## 2026-10-26 canonical doc convergence

Reconciled earlier historical Weight summary text stating 2+1 stats and N DAY CHANGE below graph: the owner-approved current architecture is Current+N Day Change inside chart, exactly three aligned goal-baseline Starting/Change and measured weekly Rate below, and separate goal-distance card. No app source behavior changed by this docs-only follow-up. Fresh exact-HEAD CI and independent review remain gating; do not merge.

## 2026-10-26 owner correction: Timeline trailing order and compactness

Owner clarified that the right side (not beside the weight) must be `New low → -1.0 → pencil`, with a Settings-style round background behind the pencil, and smaller Timeline and three Summary stat cards. Reused Core Settings visual recipe (36dp circular surfaceVariant and 16dp icon, 40dp action hit area). The status+delta+edit group stays ordered horizontally and moves together to a trailing row when content width or text scale requires it; never clip the actual weight/unit and keep all Timeline heights identical for viewport. The 56dp standard/100dp stacked Timeline and 48dp stat content minimum reduce unused vertical space without introducing a new token/component. Tests assert order/round shape/geometry. Exact-head Flutter CI and independent review are mandatory; do not merge or approve without gates.

## 2026-10-26 owner-approved Timeline border 0.5dp

Read-only verification of PR #701 found the Today outer Timeline border and matching reserved inset at `TioStroke.width075` (0.75dp), distinct from the graph/target card outline. Owner requested `0.5dp` while retaining the accepted 56dp/88dp Timeline heights. Switched only Timeline Today border, its matching inset, and the two responsive width calculations to existing Core `TioStroke.width05`. Added narrow-width Today border regression assertions. No new token, no graph/target border change, no data/session behavior change. New exact-head Flutter CI, review and device QA remain mandatory. Not approved or merged.

## 2026-10-26 CI evidence supersedes optimistic 88dp stacked estimate

During latest branch audit, concurrent owner commit `939f8182` changed Today-only border and matching geometry to 0.5dp; preserved this exact approved styling. However Flutter core-wear on earlier `0be20d75` independently reported actual 1.5px Today and 11px long-note vertical overflows at 88dp stacked height. A full visible weight/note and right-side `New low → delta → pencil` sequence cannot all fit at 88dp with current governed typography. Increased **only stacked** Timeline height to 100dp (12dp less than previous 112dp), retained 56dp wide single-row and 0.5dp Today border; updated same-viewport equal-height tests. Also changed painter's raw `FontWeight.w600` to governed `TioFontWeight.w600` after Core visual ownership test failed. Exact new HEAD Flutter CI/re-review/device QA required; not approved/merged.

## 2026-10-26 owner Edit Weight footer correction

Owner confirmed **red Delete → Keyboard → X** in edit header and original Notes/Image/DateTime/Save footer. Keep Timeline pencil unchanged. Moved delete to header with danger semantic color and existing confirmation, switched wheel-mode icon from pencil to keyboard, restored footer Notes/Image for edit as well as creation; edit Notes shows original metadata read-only because BodyWeightLogEdit does not write notes or photo. Suppressed creation-specific note word/character validation in edit to address historical oversized note P2. Reduced only Timeline weight typography titleLarge→titleMedium, preserving row height and border. Widget test checks exact header order, footer actions, read-only long note and update identity. Latest CI/re-review/device QA still required; no merge.

## 2026-10-26 user QA: latest-only Timeline highlight

Actual PR source showed `isToday` driving purple border/dot/date tint for every same-day log, which the user perceived as the month being highlighted. Added O(n) projection boolean `isLatestEligible` from the first nonfuture row in canonical sorted History; kept `isToday` solely for date/Today semantics, and keyed 0.5dp border, dot and tinted date only to latest eligibility. Do not change height/layout, historical records, goal-directed badges or source truth. Tests cover multiple same-day entries, future exclusion and exactly one outlined row. Latest CI/independent review/physical QA required; do not merge.

## 2026-10-26 owner-approved Timeline card long press

Added card-surface `GestureDetector.onLongPress` as an alternate path to the existing exact-row, session-guarded `_openWeightEditor(entry)`. Keep the pencil and normal short tap/scroll interactions; a long press never deletes without the separate confirmation inside the editor. Same PR and no new UI, source of truth, backend, RLS or token. Targeted widget regression tests single-tap no-op, older selected-record update, no duplicate/current-row mutation and pencil functionality. Exact-head CI and independent review/physical Android/iOS gesture QA remain required; do not merge.

## 2026-10-26 owner Weight chart QA: axis gap and weekday removal

User reported unnecessary space between right Y-axis weights and horizontal graph lines, plus redundant weekday in chart bottom dates. Audited current painter: 8dp guide-right inset + 4dp Row spacer + end-aligned labels in 48dp Y-axis column. Removed spacer, start-aligned numeric labels, and extended horizontal grid/target guides to plot edge while keeping actual measurement-dot right inset (prevents clipping). Replaced chart date-only formatter from `formatMediumDate` to locale-aware `formatShortMonthDay` for single/multi-point labels, e.g. `Oct 26` without weekday. Added layout/locale tests; existing timeline, edit, long-press, session and backend unchanged. Require new exact-head Flutter CI/review and physical visual QA, no approval/merge.

## 2026-10-26 owner correction: true 2dp guide/axis spacing and right-aligned numbers

The earlier zero-gutter + start-aligned fixed 48dp axis shifted chart weights left and looked wrong. Owner asked for 2dp space and right-aligned labels. Applied existing Core `TioSpacing.xxs` between plot and Y-axis, and converted fixed 48dp column into `IntrinsicWidth` to make the visible text actually adjacent to the 2dp gap while aligning all three right edges. The painter's horizontal grid/goal lines still reach its edge, and actual point inset is unchanged. Existing predecessor CI was not green: one newly authored test used `find.text('Oct 16')` globally and found matching Timeline text. Scoped dates to the chart card in the corrected regression test and updated geometric assertions for right alignment and 2dp spacing. Recheck latest exact-head Flutter CI and device screenshot before approval. No merge.

## 2026-10-26 owner-approved nonblank pull refresh (GitHub iOS screenshot reference)

Owner supplied GitHub mobile pull-to-refresh behavior *as a visual reference* and clarified that old content remains visible while the spinner appears in the top overscroll space, not a full-screen black/empty loading state. Source audit located the real Progress cause: `_reload()` always set `_loading=true` and `_snapshot=null`, so its existing `RefreshIndicator` preserved scroll input but cleared the entire chart/Timeline during refresh. Added soft same-owner refresh `_reload(preserveContent:true)` only to the pull path, with adaptive indicator, atomic replacement after a successful read, and non-destructive inline retry on transient error. Initial/cold load, explicit chart range change, write refresh and session/repository identity change stay hard, preserving privacy/session isolation and honest range labels. Generation invalidation, pagination-cancellation flag and existing reader are reused; no speculative cache, new state container, Supabase or token modifications. Tests hold a real repository read, verify chart/Timeline/action remain visible until completion, then verify swap and failure/retry. Also repair previous exact-HEAD CI false test assertion that naturally sized Y-axis label width must be <48dp (verified prior run actual 50dp), measuring rendered label max instead. CI/review/device scroll QA pending; do not approve or merge.

## 2026-10-26 pull-refresh test hardening

Adjusted the new refresh-success regression assertion to Timeline's actual canonical one-decimal record formatting (old 73.0 kg) rather than the previous Current header's whole-number 73 kg. Added a strict same-widget-State session transition test during an in-flight pull: owner A's retained content clears synchronously on owner B's session/repository switch and cannot reappear after owner A's held future completes. Privacy-first hard reload and generation guards unchanged. Exact new-head CI required; no merge.

## 2026-10-26 owner correction: in-flow pull spacing, not spinner overlay

Owner clarified Github iOS screenshot is only reference: dragging Progress content downward must create real space between shell top bar and Weight summary with spinner in that revealed space. Flutter API docs confirm CupertinoSliverRefreshControl is in-flow, unlike overlaid RefreshIndicator, and requires bounce physics on Android. Replaced the feature-owned ListView with keyed CustomScrollView containing top CupertinoSliverRefreshControl and padded SliverList with identical child list, preserving owner-safe soft refresh and all other feature behavior. Added BouncingScrollPhysics/AlwaysScrollableScrollPhysics, updated empty-History scroll test and new physical pull-displacement test. No change to navigation, fixed Log Weight action, backend, data privacy or design tokens. Verify exact-head CI and device pull/scroll UX; independent review still required, do not merge.

## 2026-10-26 owner correction: no blank-screen Log/Edit/Delete writes

Audit found successful Log Weight and Edit/Delete still invoked hard `_reload()` and wiped `_snapshot`. Added the same-owner `_reconcileWeightMutation` with soft canonical reload and a stale-action interlock: chart/Timeline remain visible while read pending, but logging/edit/delete/long-press/history pagination are disabled until successful real fresh read. If the read fails, show inline Retry without implying server data were refreshed; prevent repeating a mutation on stale Timeline records. Cold/range/session hard reload and previous session guards remain intact. Reconciled 3 prior SliverList CI widget failures caused by lazy unbuilt offscreen Timeline and idle sliver control. CI and device touch QA required before merge.

## 2026-10-26 mutation soft-reload gate tests

Added deferred canonical-read widget regressions for Log, Edit and Delete: confirmed backend mutation must never unmount chart/Current/Log Weight while its History read is pending. Log/Edit tests verify historical ID integrity, nonblank graph, action lock and successful reenable; Delete simulates a confirmed deletion followed by failed read and validates stale pencil remains disabled until inline Retry reconciles the true remaining History. No optimistic deletion and no extra API. Exact-HEAD Flutter CI, independent review and physical UI QA remain mandatory; do not merge.

## 2026-10-26 post-write lint gate

Exact HEAD `4ffc4c56` Flutter Analyze failed a single existing-repo strict Dart lint: `curly_braces_in_flow_control_structures` in the new session-generation guard immediately before Edit/Delete post-write soft refresh. Wrapped that guard in braces. No behavior or scope change; rerun new exact-head CI.

## 2026-10-26 exact HEAD second Dart lint correction

CI `9515e010` still failed one `curly_braces_in_flow_control_structures` at line 116: the wrapped multi-line `_openWeightEditor` guard for `_mutationNeedsReconcile`, distinct from the previously corrected Edit/Delete post-write generation guard. Added braces around the actual multiline `if`. No behavior changes; new exact-head CI required.

## 2026-10-26 mutation Delete Retry lazy viewport assertion

The last completed test job for `9515e010` passed 160 Progress tests, including newly added Log and Edit live-read regressions, but the Delete failure/Retry test expected the inline error row to be mounted while the lazy SliverList viewport remained scrolled down to the deleted row's pencil. That widget is intentionally offscreen/not built. Keep validating the disabled stale pencil where visible; then jump the actual scroll position to zero and assert/tap the Retry row at the top. No production behavior change; rerun CI on exact HEAD.

## 2026-10-26 owner-approved chart hold detail

User supplied a reference showing recorded weight on a date, vertical guide and separate target value, and explicitly wants press-and-hold details on the Weight graph. Added a feature-owned chart StatefulWidget around the unchanged canonical painter with touch hold/drag cursor, nearest **actual** recorded timestamp by O(log n) binary search, deterministic same-time sibling, chart-clamped UI chips and optional canonical goal Target reference. Release/cancel removes tooltip; current graph, axes, units, data, goal and runtime boundaries unchanged. Tests press/drag across three real values including optional goal, dismiss, and single-point lb without invented goal. Refresh/owner changes clear chart-local selection. Exact-head tests, CI, Android/iOS touch and accessibility QA and independent review pending; no approval or merge.

## 2026-10-26 exact HEAD chart CI corrections

On chart inspector HEAD `d9c48a35`, CI verified the two new gesture/tooltip tests passed (actual 74→76→73 kg and target, single-point lb without target). Flutter Analyze failed on one redundant non-null `scale!` in a second painter constructor; removed the unnecessary operator. The core-wear shard had one unrelated pre-existing pull-overscroll regression that searched for the lazily detached `CupertinoSliverRefreshControl` via `find.byType` during animation; inspect the configured first sliver in the keyed CustomScrollView and assert actual card physical displacement instead, without weakening visible behavior. Re-run exact new HEAD CI and physical Android/iOS QA; no approval/merge.

## 2026-10-26 owner: compact chart tooltip, full dates and weekly-pace target estimate

After audit, canonical BodyGoalState contains goal start timestamp, starting/target kg and weekly kg change but **no persisted target-date field**; onboarding computes a calendar estimate from those inputs. On owner's clarification that weekly pace yields target date, keep strict semantic distinction: tooltip shows recorded History date as a full locale medium date; Target chip displays real target weight and a labelled *Est.* original goal completion date derived from goal startedAt and starting-vs-target difference/pace. Never claim a saved absolute date or fabricate when any required input is absent or invalid. Replaced fixed 200dp popup with content-sized IntrinsicWidth (200dp upper bound) and non-expanding chips; test checks narrower popup, exact calculation, no-pace omission and real date. No cross-feature dependency or backend/schema scope expansion; follow exact-head Flutter CI and Android/iOS narrow/large-text screenshots, independent review, no merge.

## 2026-10-26 target estimate test contract hardening

The current canonical `BodyRepository.setActiveBodyGoal` correctly requires both Target Weight and weekly pace for directional goals; the first missing-pace test fixture had erroneously omitted the pace entirely and could not represent a valid edited goal. Replaced that invalid fixture with a real accepted **0 kg/week** pace, which must show existing Target weight but suppress estimated date rather than divide by zero. Canonical contract remains unchanged; re-run CI at new exact HEAD.

## 2026-10-26 final owner tooltip override

The latest owner instruction supersedes the interim full-date and estimated-goal tooltip design. Reference means two compact **one-line** inverse-contrast pills with the *same selected historical date*: `4 Oct: 76 kg` / `4 Oct: 72 kg`, blue/green dots retained. No Goal Pace future date inside the chart (onboarding calculator left intact). The previous interim full-date+Est. layout actually failed latest CI with 12–62px RenderFlex overflows and 200dp wide bubble. Replaced it with a compact single Row per chip, a date that can safely ellipsize at accessibility widths, localized day-before-abbreviated-month format using already-Core-aligned `intl ^0.20.2`, Core primary/onPrimary inverse surfaces, and no extra future line. Tests target Light 337dp and Dark styling, 2 matching dates, no estimated date, and no overflow. Requires exact new HEAD CI and physical QA, no merge.
