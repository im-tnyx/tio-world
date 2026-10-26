# Progress Screen

Document Status: Canonical Live Doc
Last Verified: 2026-10-25 (D0 documentation/read-only contract audit; not a UI release)
Owner: `apps/features/progress`
Truth Boundary: Authoritative for Progress screen product contract and intended ownership; runtime source wins for actual behavior, and Linear/GitHub own delivery status.

**Surface:** Phone primary tab in Workout, Nutrition, and Hybrid App Modes
**Current route:** `/progress`
**Primary owner:** `apps/features/progress`; `apps/app` owns shell/routing composition
**Runtime in this A3 revision:** A2 owner-backed Weight summary, chart and paginated History are merged. A3 adds the Log Weight sheet using the existing Core wheel, selected date/time and icon-revealed optional note. Exact Edit/Delete and private Photos remain separate.

## Purpose

Show meaningful, honest change over time without taking ownership of workout, nutrition, profile, Body Goal, or recovery truth. Progress reads the appropriate owning domains and must not fabricate missing or stale indicators.

## Progress information architecture (Weight active; other lanes future)

The owner-directed structure is:

```text
Progress
├─ Weight             // first implementation lane
├─ Body               // not activated by Weight Slice A
├─ Health             // not activated by Weight Slice A
└─ Photos             // separate Slice B
```

Do not treat this structure as authorization to render inactive tabs, route into placeholder details, or redesign the existing shell. A2 activates only Weight content at the existing /progress branch root. The supplied Weight references establish **content order and interactions**, not unverified pixel dimensions, fonts, colors, spacing, or a reusable component redesign. Preserve current Tio theme, navigation and component ownership. Product-visible changes require the relevant approved implementation slice.

Future non-Weight Progress content can include workout consistency, nutrition adherence, achievements, and recovery summaries only once the source feature provides approved, dated, user-owned read contracts. A Recovery indicator must be identified as a summary, not inferred from unsupported data.

## Weight Slice A: proposed phone flow

```text
Progress → Weight
  Weight summary
    Current Weight
    selected-range weight change (when comparable)
    active Body Goal target reference (when present)
  Selected-range weight trend/chart
  History                       // below the chart, newest first
    exact measurement entries
    edit/delete the selected record
  [ Log Weight ]
    bottom sheet: weight + measured date/time
```

Weight is the first real post-onboarding Progress vertical slice, not a second weight source. A photo field or upload action must not be presented as working in Slice A; optional linked photos arrive with separately approved Slice B.

### Weight graph, range menu and separated stats (owner-approved 2026-10-26)

The Weight summary places the selected-range chart, axes and the dashed target line in a compact `TioCard`. The separate horizontal Target progress card renders only actual canonical goal distance with a truthful missing-data state, not the screenshot's illustrative number or an unverified pace assertion. The chart card's own header contains CURRENT and selected-window `N DAY CHANGE` once. Three equal-size compact TioCards below show active-goal STARTING, CHANGE since that goal baseline, and selected-window RATE OF CHANGE in one phone row (stacking only when accessibility text requires it). Goal Starting/Change never borrow a guessed History baseline. Selected-window change and weekly rate derive from first/last distinct real instants; the rate equals signed kg change divided by actual elapsed days times seven, converted for global kg/lb preference and labelled `kg/week` or `lb/week`. Insufficient comparable data is unknown, not zero; equal weights at distinct instants may truthfully yield zero.

The `Last 30/90/365 days` chooser reuses the existing Nutrition-proven `MenuAnchor + TioCard.elevated + MenuItemButton` popup contract, with a checked current selection, dismiss-on-outside, and original user-selected range/fallback behavior. No new Core component, custom color/token system, data source, schema or backend changes. This user-approved UI extension is appended to existing PR #701 rather than creating another PR; reopened exact-HEAD CI, independent review and mobile visual gates remain mandatory before merge.

### Chart range and compact root action (2026-10-26 follow-up)

With the default 30-day range and no in-window measurements, the initial Progress screen may choose the first wider supported range (90 or 365 days) with **real owner-owned recorded measurements**; the selected range label must match the chart. A user's explicit 30/90/365-day selection is never silently overridden. All-empty and future-only windows remain honest empty states; changing a Body Goal never invents a measurement or extends a trend line. The plot uses a more compact **120dp** height and a right-side numeric Y-axis in the global kg/lb preference; empty state consumes only its text. Single-point plots use one centered date label, not duplicated start/end dates. The selected-range change requires comparable recorded instants.

The `Log Weight` action is an always-visible Core-standard **46dp** labelled bottom-end pill over the root Progress body, outside its scrolling Timeline, with Nutrition's action location/safe-area and scroll-clearance semantics but deliberately shorter than its 56dp circular FAB per the owner's latest screenshot, while retaining Progress-owned save/auth/unknown handling and Core primary colors. The visible heading is `Timeline`; underlying History repository names/pagination are unchanged. PR #695 separately owns the shell top-bar and pinned **editor-sheet** footer.

### Month-grouped Weight Timeline (owner reference, 2026-10-26)

The section name stays **Timeline**. Render actual owner-scoped, newest-first Weight History grouped under local **month/year** headings, keeping distinct same-time IDs, optional note and existing `Load more` pagination. Compact cards use consistent height for a given viewport/text scale (including Today, notes and New low/change badges), with an inline status dot/date, recorded time beneath and tight inter-card spacing. Long notes show a one-line preview with full content available in a tooltip; large text/compact widths use a taller shared card height to avoid clipping weight/unit.  they retain prominent kg/lb-converted measurement, and **signed change from the immediately older actual measurement** only when its timestamp is strictly older. This is not a smoothed Trend calculation and does not infer missing values.

A **Today** dot/highlight applies only to nonfuture measurements on the captured local day. An optional **New low** badge requires proof that the actual measurement is strictly below **every older eligible measurement**; suppress it while more older pages remain unloaded. Positive/negative change is coloured as helpful/harmful only when active Lose/Gain goal direction supplies that meaning; absent direction uses neutral styling. Respect Tio semantic colors/cards/tokens rather than copying the reference image's purple background. Preserve the fixed Log Weight action and existing owner/session handling; exact-ID confirmed History Delete is now owner-approved and implemented in this PR. Edit and photo activation remain separately gated.

### Summary and chart

- `Current Weight` is derived from the latest **eligible** canonical `body_weight_logs` entry across the user's history, not the selected chart range or a Profile copy. Future-dated measurements must not silently masquerade as current. The precise future-date entry/eligibility policy must be validated in A1/A3 before it is shipped.
- The selected range governs trend points and change. Calculate a range change only from real comparable measurements (the earliest and latest eligible actual points in the interval). Fewer than two comparable records means "not enough history", not a fabricated zero trend or percent.
- Plot actual measurements at their real `measured_at` instants. Do not interpolate, average same-day values, fabricate smoothing or invent data on missing days. The chart must support readable dates, units, accessible point values and a nonvisual history/summary alternative.
- An active `user_body_goals` target may be shown as a labelled reference. Any progress-to-goal percentage/ring requires a separately validated calculation and a usable starting-weight snapshot; do not hardcode illustrative percentages from references.
- Range-selector choices, chart styling and exact component geometry are not frozen by this documentation audit. Confirm visible details under the approved A2 UI scope, using existing `tio_core` components and theme.

### History (below the chart)

- Show every owner-accessible measurement with its real date/time and globally selected weight display unit, newest-first. Multiple entries on the same date are valid and must remain individually addressable.
- Stable read ordering uses `measured_at DESC` plus a unique identity tie-breaker such as `id DESC`; pagination and tie behavior are A1 repository responsibilities.
- An entry action targets the exact `body_weight_logs.id`, never "that day", a position in a filtered list, or "the latest weight". Editing preserves the row identity; deleting requires explicit intent, removes only that measurement, and refreshes chart, summary and History.
- No history: explain the first Log Weight action. A missing goal is not an error, and a missing measurement must not become an invented current value.

### Log Weight bottom sheet

- Enter a positive weight in the current global `WeightUnit` (`kg`/`lb`), with a user-selectable measurement date and time. Existing `TioWeightWheel`, `UnitConverters` and `UnitFormatters` are reusable implementation candidates; feature flows must consume public core contracts rather than replicate controls.
- Convert input to canonical kilograms before persistence. The preference affects input/display only and does not alter stored `weight_kg` or existing historical values.
- The selected local date/time resolves to one absolute `measured_at` instant; preserve precise instants and multiple logs per local day. Timezone/local-date provenance for travel and historical grouping is an **A1/A3 audit decision**, not permission to add columns in D0.
- Saving a new manual entry creates a new log identity. A retry/double-tap must not create unintended duplicates; A3 must specify and test in-flight/idempotency behavior before shipping.
- The existing source values `onboarding_setup`, `profile_settings` and `body_weight_settings` are live compatibility inputs. TNYX-119 proposes semantic `manual` provenance for new manually recorded entries. A1/A3 must reconcile this with existing consumers without overwriting legacy rows or confusing capture screen with measurement source.
- New entry success refreshes owner-backed Weight state; errors preserve user input and allow controlled retry without optimistic fake history.
- **A3 note:** The Notes icon expands the optional Core multiline input, hidden until pressed. Notes use existing `body_weight_logs.metadata.note` (max 500 characters), not a new table/column; older rows remain readable and History shows a saved note.
- **A3 retry safety:** The draft retains one generated client UUID for every save/retry, owner-side duplicate recovery verifies exact payload and session, and failed/ambiguous attempts freeze the draft pending controlled retry.
- **A3 Photo icon:** Present only as explicitly disabled, with a future-private-media label; **no live photo picker, upload, file persistence or Photo relation** before Slice B.

### Edit / delete and error states

- Edit the selected record's positive weight and intended measurement instant, preserving `id` and ownership checks. Do not alter active Body Goal snapshots or rewrite unrelated logs as a side effect.
- Delete requires a clear confirmation tied to the exact record, then re-derive Current Weight and range indicators. No destructive cascade to media or other domains may be assumed.
- Loading, save-in-progress, validation errors, offline/network failures, permission/auth failures, stale results after session/account changes, and empty history need distinct, honest presentation. Avoid showing another user's cached health data after account switch.

## Canonical data, runtime evidence and privacy

- `public.body_weight_logs` is the single owner of actual current/historical weight. Existing live columns (2026-10-25 read-only): `id`, `user_id`, `weight_kg`, `measured_at`, `source`, `metadata`, `created_at` and `updated_at`.
- `public.user_body_goals` owns Body Goal lifecycle, starting-weight snapshot, target and pace. Settings and Profile read/write through approved owner contracts; Progress does not add a second `current_weight` column or own Body Goal lifecycle.
- Existing live `body_weight_logs` owner-scoped authenticated SELECT/INSERT/UPDATE/DELETE RLS is enabled. A1 must retain record/user authorization, validate schema assumptions, and add focused repository tests; D0 does not prove a new feature works end-to-end.
- Current Flutter `BodyRepository` supports `getBodyState()` and `recordCurrentWeight()` but not a history/list-by-id/edit/delete API. New contracts belong to Progress/Body domain/repository and are built in A1, not screens or `apps/app` routing glue.
- Weight data and timestamps are health-context information: no raw values or images in analytics, error logs, crash data or AI-provider calls without an independently approved purpose. Follow [Data & Privacy Governance](../security/DATA_PRIVACY_GOVERNANCE.md) for export/deletion, access and retention decisions.

## Progress Photos: separately gated future Slice B

WeightLog and ProgressPhoto are different identities. A photo may later be standalone or linked to one Weight Log, and one stored photo can appear in Weight and Photos contexts without duplicate upload. A future Workout association must be explicit, not automatic.

**Live Storage reality (read-only audit 2026-10-25):** only the existing public `avatars` bucket is present. It is not suitable for private Progress images. The parent [TNYX-119](https://linear.app/tnyx/issue/TNYX-119/progress-weight-logging-photos-and-private-user-media-persistence) currently proposes a private owner-scoped `user-media` bucket as a **candidate** for Slice B, not a bucket that exists or a permanently frozen name. The earlier `progress`/`progress-media` bucket assumptions are superseded planning language, not current Storage truth.

Before Slice B, separately approve and audit exact schema/bucket/path/MIME/limits, authenticated object access, account deletion/export, optional attachment failure/retry, orphan cleanup and last-reference-safe unlink/delete behavior. A narrow physical-media registry (Slice C) is conditional on proven need, not part of Weight Slice A or D0.

## Execution and approval boundaries

- **D0 (GitHub #686):** docs-only contract reconciliation and compact execution handoff. No Flutter, RLS, Storage or migration changes.
- **A1:** owner-backed Weight history/list/pagination and exact-ID edit/delete repository contracts with focused access/ordering tests. Reconcile measurement source and timezone-policy questions.
- **A2:** read-only Progress Weight summary, actual-data range chart and paginated History at /progress, with session/owner gate in app composition and no active Log/Edit actions. Current Weight is derived from A1 History up to captured UTC now; goal is read from the existing BodyState active goal only. Scoped tests and PR review gate apply.
- **A3:** Core Weight Wheel in Log Weight sheet with date/time, canonical-kg manual save, optional note revealed by Notes icon, stable retry identity, and disabled Photo icon until separately approved private Slice B.
- **A4:** exact-record Edit/Delete interactions and device/accessibility/regression QA.
- **Slice B/C:** separately approved private Progress Photos and conditional physical-media identity, following new Storage/privacy audits.

Each independently scoped product-visible implementation slice still follows [Owner Approval](../../.ai/FEATURE_DEVELOPMENT.md#owner-approval-gate); documentation does not authorize new UI or database shape. This D0 contract does not claim the Weight UI is implemented.

## Acceptance for Weight Slice A (future implementation)

- Actual, owner-scoped Weight data and valid current/goal/range provenance; no fabricated values or duplicated weight owner.
- Individual same-day logs, stable History ordering, exact-ID update/delete, canonical `kg` storage and global-unit display.
- User-directed measurement date/time, safe retries, session/permission isolation, explicit no-data/loading/error states.
- Chart and History accessibility with range/source labelling; visual acceptance against approved Tio-owned references.
- Zero private-photo schema/Storage or future Workout/Nutrition media platform bundled into Weight Slice A.

## Related

- [GitHub #686 D0 docs/contract freeze](https://github.com/im-tnyx/tio-world/issues/686)
- [Linear TNYX-119 Progress Weight/Photos parent](https://linear.app/tnyx/issue/TNYX-119/progress-weight-logging-photos-and-private-user-media-persistence)
- [Data & Privacy Governance](../security/DATA_PRIVACY_GOVERNANCE.md)
- [Screen catalog](README.md)
- [Workout](workout.md)
- [Nutrition](nutrition.md)
- [Recovery](recovery.md)


### A3-F footer integration (review slice #692)

The approved Weight Log editor places Notes (optional) and a disabled/future Photo icon at the left of a pinned editor action strip, with one right-aligned Date/Time control and Save Weight below. It reuses the Core pinned footer and DateTime popup while leaving body weight data, kg/UTC storage and owner/session protections unchanged. This section describes the targeted review slice, **not a merged or released feature**.

The same approved review additionally aligns the Progress root Top Bar with canonical shell sizing/placement (no fabricated streak), keeps the full Weight wheel without a redundant external kg/lb label, offers Settings-pattern pencil/manual numeric entry left of Close, and shows a one-to-two-line reusable Notes input with 100-word formatting limit and no visible character counter. The A3 500-grapheme backend guard stays unchanged.

### Progress header and Weight DateTime layering (PR #695, review only)

With the root shell now owning the `Progress` title, the Weight dashboard body begins at `Weight summary` and no longer repeats `Weight` just under the top bar. On the Weight editor only, the anchored Core DateTime popup uses its new flat-card option to avoid an apparent second elevated layer over the sheet. The shared Food DateTime popup retains its previous elevated surface and behavior. The date/time wheel's existing centered selection pill remains within the single popup, not a separate card. These changes are in an open, unmerged PR.


### Reconciled status — 2026-10-26

PR #695 and PR #696 are merged into `main`. The canonical Progress top bar is already owned by #695. The fixed `Log Weight` action and `Timeline` heading are owned by merged #696: explicit `TioButtonTokens.height` (46dp), no extra save icon, 24dp inset and safe-area/scroll clearance. PR #698 only contributes the truthful range fallback and 120dp chart/axis presentation; it does not reimplement the action. Older “review only/unmerged” text above is historical and superseded for #695/#696.

### Android QA correction — status, cards, and range rate

The phone chart card no longer repeats the numeric target sentence; a horizontal goal-distance card follows three shorter aligned weight stats. All three below-chart stats align as equal-width and equal-height columns at ordinary phone text scales, including the rate card. Weekly Rate of Change requires an actual seven-day measured interval to avoid extrapolating multiple same-day check-ins into misleading extreme weekly rates; range change still uses the actual points without that restriction. Timeline 72dp baseline and Core thin 0.75dp Today outline are shared across cards; New low/new high only appears for the newest eligible entry in the direction of the active Lose/Gain goal, beside its weight, not on historical milestones.

The actual Timeline UI now provides a small per-entry delete action using Core's destructive confirmation, targeting the exact owner-scoped UUID in the existing BodyRepository delete API. Cancel does not modify History, and confirmed success triggers a fresh canonical chart/summary/history read. Missing/failed writes do not optimistically remove records; identity/session changes invalidate in-flight completions. Photo/media deletion and A4 editing remain separately gated.

### Owner-approved Timeline edit affordance (2026-10-26)

Each Timeline measurement displays a pencil instead of the direct delete icon. It opens the same Core `TioEditorSheet` and complete numeric wheel/date-time footer as Log Weight, but prepopulates the exact record's original weight and timestamp. Save Changes calls the existing owner-scoped `updateWeightLog(BodyWeightLogEdit)` on the unchanged UUID; only weight and timestamp may change and the stored provenance and note remain unmodified. The destructive Delete action is inside that edit sheet's footer, reusing the Core confirmation bottom sheet, with cancel/no-write and canonical refresh after a confirmed request. The Notes/Photo creation affordances remain absent in edit mode because the existing edit repository contract cannot update metadata. The original Log Weight flow is unchanged.

### Weight summary: final owner screenshot layout (2026-10-26)

The chart's main TioCard contains CURRENT (left) and the selected 30/90/365 DAY CHANGE (right) **inside the chart**, above real measured points, actual axes and dashed goal reference with a short YOUR TARGET label. N DAY CHANGE must never be repeated below the chart. Below it are exactly three equal-size, value-first cards in a three-column phone row: STARTING, CHANGE and RATE OF CHANGE. Starting and Change use canonical active Body Goal `startingWeightKg` and current-minus-starting (unknown if the baseline is absent), which differs from the chart's selected-window N-day change; weekly rate uses actual selected-window readings and the existing 7-day minimum. High text scale stacks cards rather than clipping their units. The separate compact horizontal target TioCard includes a governed circular icon, real distance to go and "On track to target" only when Current is closer than the canonical starting distance. No guessed values or screenshot colors. Existing Timeline pencil, editing, deletion and session ownership flows are unchanged.

### 2026-10-26 UI QA: action position, round pencil and compact cards

Timeline weight stays in its middle column. The trailing action group follows `New low/New high → signed delta → pencil`, never prepending a record chip to the weight itself. The edit pencil reuses Settings' 36dp circular `surfaceVariant` background and 16dp edit icon inside a 40dp control. On compact widths or accessibility text scaling, the entire ordered action group moves to one trailing row rather than splitting a badge/delta across separate lines; the row-height breakpoint is shared by all entries, with a 0.5dp Today outline. Timeline heights are 56dp ordinary/100dp compact stacked, reduced from 72dp/112dp. The three aligned Weight-summary cards below the chart have compact 48dp content minimum, tighter TioCard padding and value-label gap, but still wrap genuine values rather than clip units. No storage or goal logic changes.

### 2026-10-26 Edit Weight header/footer parity

Edit Weight header shows **red Delete → Keyboard → X**, with the existing Core destructive confirmation for Delete. The pinned footer restores its original Notes, disabled Image placeholder, Date/Time and Save Changes controls. Edit Notes toggles a read-only original note or an empty-note explanation, not an unsupported metadata editor; existing notes longer than creation limits must not block weight/time updates. Log Weight continues to allow new Notes and retains its original validations. The Timeline weight uses the governed titleMedium style rather than titleLarge. Timeline size, 0.5dp Today outline, and trailing record/delta/pencil position remain unchanged.

### 2026-10-26 Timeline highlight: latest entry only

The 0.5dp progress-coloured outline, status dot and date text tint now highlight **only the newest eligible nonfuture measurement** under canonical `measuredAt DESC, id DESC` History ordering. Month heading is not a highlighted group, and older records in the same month or on the same day stay neutral—even though multiple legitimate entries may still display the truthful `Today` date label. No future record is highlighted. Goal-directed New low/high, change badges, 56dp/100dp Timeline heights, rounded pencil/Edit sheet and owner/session policies remain unchanged.

### 2026-10-26 Timeline long-press editing shortcut

Long-pressing a Timeline measurement card opens its existing exact-record Edit Weight sheet, identical to pressing the round pencil. This extra gesture does not turn a short tap into an edit, does not disable vertical ListView scrolling, and never directly deletes a row; Delete still requires separate confirmation within the editor. The gesture delegates to the same Progress-owned `_openWeightEditor(BodyWeightEntry)` with immutable row ID, owner-session/generation checks and a single-editor guard. Existing card geometry, notes, 0.5dp latest-only highlight, badges and pencil behavior remain unchanged. The long-press widget test verifies editing an older exact ID without creating duplicates or modifying the current record.

### 2026-10-26 Weight chart label proximity and date-format QA

The right-side numeric weight Y-axis is left-aligned and directly adjacent to the plot: removed the previous extra 4dp Row gutter and extended the horizontal grid and dashed goal guides to the plot's right edge. Recorded point X coordinates continue to reserve 8dp within the painter so the last actual measurement dot and rounded line caps are not clipped. The fixed 48dp axis column remains for large kg/lb numeric labels, without an intervening visible gap. Both multi-point bottom date endpoints and the one-point centered date label use Core Flutter's locale-aware `MaterialLocalizations.formatShortMonthDay` (for example `Oct 26` rather than `Mon, Oct 26`); no fabricated timestamps or hard-coded English date strings. Plot height, selected ranges, target reference and history remain unchanged.
