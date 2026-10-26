# Progress root UI correction — GitHub #694 and #697

**Date:** 2026-10-26  
**Status:** Implementation on an isolated dependent PR; no merge.  
**Approval:** Owner screenshot and explicit request to fix missing-looking chart, excessive chart height and incorrect Log Weight button position.  
**Ownership:** `apps/features/progress` presentation only. `im-tnyx` writes, not `im-tio`.  
**Source base:** exact PR #695 head `f9cecdbd40df15332dd450a0056f5a6b9e8ffda4` because it already fixes the root Progress top bar and editor footer. New PR should target #695 branch as a dependent review so none of its work is copied or silently lost. `main` remains `80db18965fdba53745d96e9bb97c0cc9ea465caa`.  
**Tracking:** GitHub #694 (bottom action, Timeline, top-bar parity already implemented in #695) and #697 (selected-range fallback and compact plot); parent Linear TNYX-119 In Progress. Scope #692 remains existing sheet; #693 UNKNOWN across restart remains separate.

## Verified diagnosis

- On 2026-10-26 the screenshot displays current 74kg and history records dated Sep 3 / Sep 19. The default **Last 30 days** chart is correctly empty because no rows fall in the selected period. Current Weight comes from latest eligible history regardless of chart range; the target 72kg is a goal reference and not a measurement.
- Before this change, selected 30-day empty chart consumes a 160dp blank body, populated chart 200dp, and the only Log Weight trigger appears in the scrolling History header. Nutrition already implements bottom-end `SafeArea → Align` anchored action with explicit scroll clearance; #694 requires matching 56dp footprint and theme roles.

## Implemented bounded proposal

1. On initial/default 30-day empty state, search real owner-scoped History windows 90 then 365 days, stop at first with a point and visibly select it. Preserve exact selected window when the user chooses a range; reset auto policy on session/owner changes. Do not fabricate points, change Current Weight eligibility or data access/goal semantics.
2. Populated plot 160dp; empty state a compact explanatory text with existing goal reference. No fake data line, interceptors, RLS or schema changes.
3. Reuse `TioButton.primary` with the 56dp minimum height (Nutrition parity), primary/onPrimary theme and a save icon in a `SafeArea` bottom-end overlay. Scroll body reserves action footprint + current bottom safe inset; header is now `Timeline`. Keep existing sheet action callback and persistence/UNKNOWN/lifecycle guard, no duplicate action.
4. Focused widget regression for Sept 3/19, manual 30, 365 and goal empty, compact sizes, anchored scrolling/open, and existing A3-F sheet tests.

## Rejected alternatives

- Do not extend Sept 19 weight as a fake Oct 26 measurement or reinterpret goal updates as weight logs.
- Do not silently change user-selected 30-day filter.
- Do not copy Nutrition domain feature or add a generic FAB component for one extra reuse.
- Do not edit PR #695's source in place, modify Supabase/Storage, or merge without owner instruction.

## Validation / handoff

Source patch prepared against PR #695 head. Verify exact commit through GitHub CI and independent review; external Android/iOS physical-device QA, Windows worktree and locale/large-text manual visual checks unavailable here and must not be claimed as PASS.

## Verified remote CI limitation and next gate

At proposed head `5fcd255f28b1e54aee2ff7b18b6f89a866afd3ec`, GitHub PR #698 is OPEN, based on #695's feature branch, and no Flutter/Docs/attribution Action run appeared on the new head. Verified workflow source `.github/workflows/flutter-ci.yml`, `docs-hygiene-ci.yml` and `commit-attribution-guard.yml` triggers restrict automatic pull-request runs to base `main`. Cursor's neutral checks are not equivalent to CI or independent approval. A manual `workflow_dispatch` of Flutter CI on the exact branch, or merging #695 first and safely retargeting #698 to `main`, is required before claiming tested/merge-ready. No Flutter binary or Windows worktree available here; test code added but not executed. No CI pass claimed and no merge attempted.
