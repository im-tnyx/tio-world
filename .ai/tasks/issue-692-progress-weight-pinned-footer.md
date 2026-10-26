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
