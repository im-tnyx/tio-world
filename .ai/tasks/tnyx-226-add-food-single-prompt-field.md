# TNYX-226 follow-up — Add Food describe-meal field polish

**Status:** Validated (PR #301 is Ready for Review; merge is owner-authorized)
**Primary owner:** `apps/features/nutrition` Add Food presentation
**Affected platforms:** Flutter phone app (Nutrition presentation only)

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI/UX change (follow-up to the merged TNYX-226 activation, PR #300; TNYX-226 is `Done`).
**Approval status:** Approved
**Approval evidence:** Owner device screenshot of the live Add Food sheet reporting the defect, followed by a series of explicit owner instructions in chat on 2026-09-20 (listed below). An owner reference image showing a single placeholder line in an input was used only for the "one prompt, no extra box" behaviour; its glow, colours and copy belong to another product and are not adopted.
**Approved product/UI/data-shape boundaries (all owner-stated):**

1. The describe-meal field shows one prompt at rest (`What did you eat?`), drawn as a hint (muted, regular weight).
2. The field draws no outline of its own; the surrounding `TioCard` is the only box.
3. The line under the field appears only when it carries state (processing, parse failure, unavailable).
4. The field grows to four lines (was three) before it scrolls.
5. The keyboard icon inside the field card paints no splash/highlight ("blur").
6. The mic icon uses the primary colour (it is the voice-logging entry point).
7. Keyboard behaviour: the sheet does **not** rise with the keyboard and does **not** sink when it opens (including on 3-button navigation). If the keyboard would cover the describe card, only the top part moves up: the title row (`Add Food`, close) and the describe card move together, keeping their spacing, and the sheet surface stretches upward. Everything from the Photo card down stays put. The movement follows the keyboard frame for frame.
8. Quick Add and Search Food stay in one side-by-side row, exactly as before. (A stacked layout was tried and reverted at the owner's request once the stretch behaviour above solved the keyboard problem.)

**Explicit non-changes:** keyboard affordance behaviour (show/hide only), Mic/Send swap, submit/retry/duplicate-suppression behaviour, Meal Editor handoff, Photo/Quick Add/Search cards and their layout, the parser, providers, `apps/core` theme/tokens, schema/RLS, and copy other than the removed idle caption and the shortened unavailable line.

## Verified evidence

- The app theme (`apps/core/lib/src/theme/tio_theme.dart`) sets a global `InputDecorationTheme` with `filled: true` and `OutlineInputBorder` for `enabledBorder`/`focusedBorder`.
- `add_food_sheet.dart` (added in #300) used `InputDecoration.collapsed(...)`, which only sets `border: InputBorder.none`; the themed outline is still merged in by `TextField`, and with zero content padding it hugs the hint as a pill. Confirmed by test: against the pre-change source the field's resolved decoration has `OutlineInputBorder` where `InputBorder.none` is expected.
- `Describe your meal` is the pre-existing caption from #214 (2026-09-06), when the surface was not yet an input. #300 added the real `TextField` above it, so both said the same thing at rest. The same line also carries `Processing meal…`, the parse-failure message and the unavailable state, which is why it stays for those states.
- `TioInput` draws its hint as `colors.textMuted`, `w400`; the Add Food hint now matches that convention (previously primary colour, `w600`, identical to typed text).
- Keyboard: a modal sheet is bottom-anchored and is not resized by the keyboard, and `SafeArea` follows `MediaQuery.padding`, which Android shrinks to zero while the keyboard covers a 3-button navigation bar, so the sheet sank by the bar's height. `viewPadding` does not change and is used instead. On a 360x800 phone with a 320dp keyboard the describe card's bottom overlapped the keyboard before this change.
- No golden or visual test covered the field's appearance.
- No borderless `TioInput` variant exists (all four are boxed), so the field stays a feature-owned composition per `apps/features/AGENTS.md`; `tio_otp_verification_dialog.dart` is the repo precedent for clearing every border explicitly.

## Implementation

- `add_food_sheet.dart`:
  - explicit borderless `InputDecoration` (all six borders `InputBorder.none`, `filled: false`, `isCollapsed: true`, zero padding — same geometry as `collapsed`); hint `textMuted`/`w400`; `maxLines: 4`;
  - `_supportingText()` returns `String?`, `null` at rest, `Not available yet` when unavailable; the gap and text are only built when non-null;
  - keyboard `InkResponse`: `NoSplash.splashFactory` and a transparent `overlayColor`; mic icon `colors.primary`;
  - sheet builder: bottom padding and the bottom fill use `viewPadding.bottom`, `SafeArea(top: false, bottom: false)`;
  - `_KeyboardLift` wraps the describe card and replaces the fixed gap between it and the Photo card. The gap is `TioSpacing.md` at rest and stretches by exactly the missing room while the keyboard would cover the card. The stretch is computed in `build` from the current keyboard height and one measured constant, `below`: the distance from the gap to the bottom of the sheet. `below` is measured relative to the sheet's own box (`TioSheet`), so it does not depend on the route's slide-in animation or on where the sheet is on screen. It is taken after the first layout, before a keyboard can appear, and again when the width, the text size or the card's size change, so the first keyboard frame is already correct for a sheet that fits;
  - a viewport too short for the sheet makes it scroll and leaves nothing above it to stretch into. There the sheet is scrolled after layout just far enough for the card to clear the keyboard: `offset = max(rest offset, offset + cardBottom - (keyboardTop - sm))`, clamped to the scroll extent, which is a fixed point (repeating it changes nothing) so it cannot oscillate. The rule is applied again (through a `SizeChangedLayoutNotifier` on the card, after layout) when the card grows or shrinks, so lines added while typing stay clear of the keyboard. The stretch supplies any scroll room that is missing, and the offset the sheet had returns when the keyboard closes. What is guaranteed there: the card rests `TioSpacing.sm` above the keyboard and the field is on screen; the title row can scroll out of view; the scroll lands one frame after the keyboard inset, so in such a viewport the card can trail by a frame; with very large text the card can be taller than the room above the keyboard, so its own top edge may scroll off while the field stays visible.
- Geometry note: at rest the field column loses the caption line, so the card is a few dp shorter; the 40dp keyboard/Mic controls now set the row height.

## Validation

- Regression tests in `meal_diary_add_food_flow_test.dart`:
  - `describe meal shows a single prompt and no themed outline on the field` (also asserts hint style, four lines, no keyboard-icon splash, primary mic) — the border assertion fails on the pre-change source;
  - five `describe meal stays reachable with the keyboard on …` cases (short keyboard, 320dp, 3-button navigation, very tall keyboard, small phone) asserting the sheet bottom and Photo card never move, the title row and card keep their spacing, the card rests just above the keyboard only when it would otherwise be covered, and the sheet surface stretches by the same amount;
  - unavailable state asserts the state line.
- The two `the N5 hierarchy holds at …px wide` tests are unchanged (Quick Add and Search remain side by side).
- Added after the Codex review of `d2aa9add` (findings C1 and C2 below), all in `meal_diary_add_food_flow_test.dart`:
  - `describe meal clears a keyboard that arrives in a single frame` pumps one frame, not `pumpAndSettle`, and asserts the card is clear, the Photo card has not moved and the title/card spacing is kept. It fails on the previous source;
  - `describe meal follows a rising keyboard frame by frame` and `describe meal re-measures when the text size changes` also step one frame at a time. They pass on the previous source too, so they document the behaviour and do not prove the fix;
  - three `describe meal stays reachable in a short viewport` cases: 800x300 landscape (scrolls at rest), 800x360 landscape with a 240dp keyboard (fits at rest, overflows once the keyboard needs room), and 800x360 landscape at 1.6x text (scrolls at rest). The outer sheet scroll view is looked up from the sheet itself, not by type, because the text field has a scrollable of its own. Each asserts that the card rests just above the keyboard, the field is on screen, the scroll viewport did not shrink, the content moved, that the card still rests just above the keyboard after four lines are typed, and that everything returns when the keyboard closes. All three fail on the previous source.
- Fix commit: `flutter analyze` in `apps/features/nutrition` and `apps/app`: no issues. `flutter test`: `meal_diary_add_food_flow_test.dart` 68 passed; whole `apps/features/nutrition` 872 passed; `apps/app` 320 passed.
- CI: Flutter CI #2677 passed on `d2aa9add782d3452b22226e0a2155f7d5e099d75` and #2678 on the docs-only `b845068c61b026cdcacefd06fd94915493ab2c15`. CI for the fix commit is checked on the PR before merge; no result is claimed here for it.
- Real-device QA (Android, 3-button navigation, docked Gboard) passed on `d2aa9add…`: one resting prompt; no inner field outline; four visible lines; keyboard toggle; Mic to Send swap; Quick Add / Search Food unchanged; the sheet does not sink and leaves no blank bottom gap; title row and describe card lift together only when needed; closing the keyboard returns the sheet. It was not repeated on the fix commit because the device was no longer connected; the fix is covered by the widget tests above and by an emulator run (gesture navigation, floating Gboard, so no docked keyboard) with no runtime exception.
- Not manually verified: TalkBack, light-theme visual check, landscape or rotation on a device, hardware keyboard.
- Review: implementing-agent COMMENT review of `d2aa9add…` found no blocking source finding (not an independent approval); Codex review threads are listed below.
- GitHub AI scanner (`github-advanced-security`) is red for an external reason: `CAPIError: 400 The requested model is not supported` while creating its model session, before any analysis; no code-scanning analysis or alert exists. It is not a source or security finding.

## Review findings

| ID | Severity | Status | Finding |
|---|---|---|---|
| C1 | P2 (Codex) | Resolved in the fix commit | In a viewport that scrolls, the baseline was never measured, so no keyboard clearance was applied. It also existed on `main`; it is fixed here because the approved behaviour is that the describe card clears the keyboard. See Implementation for exactly what is guaranteed. |
| C2 | P2 (Codex) | Resolved in the fix commit | The baseline was measured only after the route had finished animating, so the first keyboard frame used no baseline and the card trailed by one frame. It is now measured inside the sheet after the first layout; the single-frame test covers it. |
| C3 | P1 (Codex) | Resolved in `b845068c…` | The task brief still said the work was not committed or pushed. |
| F1 | P2 | Deferred (owner to acknowledge) | The light-theme resting hint uses `colors.textMuted`, about 2.54:1 on the light surface (dark about 6.99:1, OLED about 8.03:1). It is the owner-approved hint treatment and matches the `TioInput` convention; recorded so it stays a known choice. |
| F2 | P3 | Resolved in the fix commit | First-keyboard-frame lag, and a cached measurement that could go stale after a text-size change. Fixed with C2 (re-measured when width or text size change). Rotation is covered only by widget tests. |
| F3 | P3 | Deferred | The keyboard icon has no visible focus indicator (overlay is transparent in every state). |
| F4 | P3 | Deferred | The state line's live region is now a conditionally inserted node; the TalkBack announcement is not verified. |

## Handoff

**Implementation owner:** current session (branch `tnyx/tnyx-226-add-food-single-prompt-field`, from `main` `07bbf612`).
**State:** implemented, committed and pushed; PR #301 is open and Ready for Review. Source head first reviewed: `d2aa9add782d3452b22226e0a2155f7d5e099d75` (implementing-agent review, no blocking finding). Codex then raised two P2 findings (C1, C2) that changed the source; they are fixed in the follow-up fix commit, so validation above for that commit supersedes the earlier heads.
**Scope:** presentation and tests only. No backend, provider, Supabase, schema, persistence or routing change.
**Tracker:** TNYX-226 stays `Done`; this is a bounded follow-up to PR #300. TNYX-229 remains the production-readiness gate. TNYX-240 is separate.
**Next exact action:** wait for exact-head CI on the fix commit and a Codex review of it, reply to and resolve the review threads, then merge PR #301 (owner authorized this in chat on 2026-09-20, conditional on those gates), and follow `docs/POST_MERGE_SYNC.md`. Deleting the branch is a separate owner decision.
**Resolved:** the inert mic in the primary colour is covered by approved boundary 6. The send arrow beside it keeps the default ink splash; only the keyboard icon was asked to lose it.
**Not changed:** `apps/features/nutrition/pubspec.lock` is touched by `flutter test` (a stale `dependency:` label on `main`) and is reverted before any commit; it is unrelated to this slice.
