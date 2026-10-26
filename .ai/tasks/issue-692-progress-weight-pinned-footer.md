# #692 A3-F — Progress pinned editor footer and Core DateTime popup

**Status:** In progress. Implementation owned solely by GitHub `im-tnyx` on `feat/issue-692-progress-pinned-footer-datetime`; independent review and exact-head CI pending. **NO MERGE**.
**Planning:** [GitHub #692](https://github.com/im-tnyx/tio-world/issues/692), Linear TNYX-119 (parent, In Progress), TNYX-154 and TNYX-139 boundaries; TNYX-185/TNYX-114 Nutrition ownership and temporal semantics.
**Owner approval:** 2026-10-26 approved Food-style pinned Weight footer with Notes, disabled Photo, shared date/time and pinned Save. User explicitly authorized implementation up to merge gate, prohibited merge.
**Observed base:** `main@80db18965fdba53745d96e9bb97c0cc9ea465caa`; A3 PR #691 squash merged; exact PR-head CI 5/5 PASS and post-merge CI SUCCESS. Windows `G:\projects\Tio-World` not mounted in this tool environment. Only remote GitHub API scope verified; no local `git status`, Flutter binaries or device QA claimed.

## Discovery and architecture
- Root and feature `AGENTS.md`, Core theme README, canonical module ownership, workflow, approved #692 and A3 handoff audited.
- Nutrition's `MealLogActionFooter` supplies one aligned separator/leading/trailing/action row for Quick Add and Meal Editor, with stable category and semantic keys. Core `TioEditorSheet` already pins `actions`; `TioDateTimePickerPopup` wraps its child using `OverlayPortal` and `TioDateTimeWheelPicker`.
- Extract only presentation slots and generic footer action styling to Core. Leave category and meal-time meaning in Nutrition and weight/note/session semantics in Progress.
- Progress replaces separate Material date/time dialogs with Core anchored popup above footer. Date/time maximum recalculated on tap, interaction and app resume; selected values remain local UI values and existing `BodyWeightRecord.measuredAt` conversion to UTC remains unchanged. Popup Back/outside dismisses popup first, not the draft.
- Rejected: duplicate feature-specific footer, new wheel, generic persistence abstraction, Nutrition import from Progress, storage/scheme/UI unrelated changes.

## Acceptance and limits
- Preserve Food visual geometry, category identities, keys, callbacks, semantic button treatment, loading and disabled states.
- Weight pinned Notes/disabled Photo on left, date/time on right, Save beneath; note remains in scrollable body and preserved when collapsed. Preserve kg/lb display, stable UUID, immutable UNKNOWN retry, confirmed rejection recovery, owner/login-cycle fail-closed, cache invalidation.
- Only Flutter Core, Nutrition, Progress code and tests, Core README, Progress docs and this task index. No Supabase migration/RLS/Storage, media, A4, routing, watch or service work.
- Validation: exact-head Flutter analyzer and widget shards in GitHub CI, Food light/dark/compact/text/keyboard behavior, Weight popup/Back/outside/UTC/future/session/UNKNOWN coverage, independent reviewer disposition. Remote CI cannot establish physical Android/iOS QA.

## Owner refinement: 2026-10-26, during #695 review preparation

Explicit owner-approved UI adjustments to this same active PR (not new unrelated work):
- Reuse `TioInput.multiline` for Weight Notes, `minLines: 1, maxLines: 2`, hard limit 100 whitespace-separated words with an input formatter. Suppress the visible `0/500` Flutter maxLength counter. Retain A3 domain's 500-grapheme integrity cap internally; no backend schema/data contract changes. The note stays optional, scrollable and session-local, and may collapse without losing its draft.
- Remove redundant `Weight (kg)`/`Weight (lb)` label above the *full-height* `TioWeightWheel`. The wheel still gets the app-global `WeightUnit` with `showUnitSwitcher: false`. No new user preference.
- Put a pencil `IconButton` immediately left of Close `X` in the Weight sheet header. Follow existing Settings Body Weight manual-versus-wheel affordance using core `TioInput.numericEditor`, bounded kg conversion via `UnitConverters`, and fail-closed Save when manual input is invalid. Wheel remains default and returns intact after toggling; save/UNKNOWN locks also disable pencil.
- Fix Progress root Top Bar parity: audited `TioShell` maps `ShellTab.progress` to `null`, unlike Workout and Nutrition. Reuse `TioShellStatusTopBar` in a status-absent variant with the same `TioNavigationTokens.topBarHeight`, title/spacing/elevation, but *never invent a streak count or fire icon*. Respect `isRootTopBarVisible` and other tabs' existing status semantics. Pure app/Core shell UI, no feature-domain or navigation change.
- Added Progress note/word/manual-mode/keyboard/weight tests and shell Progress top-bar geometry and nested-screen suppression tests; keep previously requested complete Food regression suite. Final-HEAD CI and independent review must rerun after these pushes. No merge.

## Owner-reported follow-up, 2026-10-26: redundant title and double-card appearance

The shared Progress shell now renders the real `Progress` title in `TioShellStatusTopBar`. `ProgressWeightPage` additionally rendered a separate `Weight` headline in its list, directly under the shell; removed the duplicate headline without changing the `Weight summary`, Weight dashboard, history, error, scroll or loading behavior. Added a widget regression asserting no `progress-weight-heading` below the top bar.

The Core anchored DateTime popup source renders **one** outer `TioCard` and one `TioDateTimeWheelPicker`; the native selection pill is inside the same wheel (not a second popup). However its default elevated shadow can visually resemble a second card over the raised Weight editor underneath. Added the presentation-only optional `elevatedCard` flag to Core (`true` by default for Food and all other callers). Progress alone sets `false`, so the anchored popup is a single flat card without the extra projected shadow, while retaining the Core date wheel, popup dimensions/anchor, Back/outside dismissal, session teardown and date-time bounds. Added a widget regression verifying one surface `TioCard` and one `TioDateTimeWheelPicker` in the overlay. Do not claim device visual verification without Android/iOS QA.

GitHub exact-HEAD Flutter CI and independent review must be rechecked after these changes. Owner instruction remains **NO MERGE**.
