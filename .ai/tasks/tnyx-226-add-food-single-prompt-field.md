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
  - `_KeyboardGap` replaces the fixed gap between the describe card and the Photo card. It is `TioSpacing.md` at rest and stretches by exactly the missing room while the keyboard would cover the card. The stretch is computed in `build` from the current keyboard height and one measured constant (the height below the gap). That constant is measured on the first rebuild after the sheet has finished opening, which is the first keyboard frame, so the stretch follows the keyboard from the second frame on and can trail it by one frame at the start (finding F2).
- Geometry note: at rest the field column loses the caption line, so the card is a few dp shorter; the 40dp keyboard/Mic controls now set the row height.

## Validation

- Regression tests in `meal_diary_add_food_flow_test.dart`:
  - `describe meal shows a single prompt and no themed outline on the field` (also asserts hint style, four lines, no keyboard-icon splash, primary mic) — the border assertion fails on the pre-change source;
  - five `describe meal stays reachable with the keyboard on …` cases (short keyboard, 320dp, 3-button navigation, very tall keyboard, small phone) asserting the sheet bottom and Photo card never move, the title row and card keep their spacing, the card rests just above the keyboard only when it would otherwise be covered, and the sheet surface stretches by the same amount;
  - unavailable state asserts the state line.
- The two `the N5 hierarchy holds at …px wide` tests are unchanged (Quick Add and Search remain side by side).
- `flutter analyze` in `apps/features/nutrition`: no issues. `flutter test`: `meal_diary_add_food_flow_test.dart` 62 passed; whole `apps/features/nutrition` 866 passed; `apps/app` 320 passed.
- CI: Flutter CI #2677 (`Analyze and test`) passed on source head `d2aa9add782d3452b22226e0a2155f7d5e099d75`. `flutter analyze` and the Add Food flow tests (62) were re-run on that head during review.
- Real-device QA on that head (Android, 3-button navigation, docked Gboard): passed. One resting prompt; no inner field outline; four visible lines; keyboard toggle; Mic to Send swap; Quick Add / Search Food unchanged; the sheet does not sink and leaves no blank bottom gap; title row and describe card lift together only when needed; closing the keyboard returns the sheet. Emulator (gesture navigation, floating Gboard, so no docked keyboard): resting layout and four-line growth checked.
- Not manually verified: TalkBack, light-theme visual check, rotation, hardware keyboard.
- Review: 0 unresolved review threads; implementing-agent COMMENT review found no blocking source finding (not an independent approval).
- GitHub AI scanner (`github-advanced-security`) is red for an external reason: `CAPIError: 400 The requested model is not supported` while creating its model session, before any analysis; no code-scanning analysis or alert exists. It is not a source or security finding.

## Review findings

Observed at source head `d2aa9add782d3452b22226e0a2155f7d5e099d75`. None blocks merge.

| ID | Severity | Status | Finding |
|---|---|---|---|
| F1 | P2 | Deferred (owner to acknowledge) | The light-theme resting hint uses `colors.textMuted`, about 2.54:1 on the light surface (dark about 6.99:1, OLED about 8.03:1). It is the owner-approved hint treatment and matches the `TioInput` convention; recorded so it stays a known choice. |
| F2 | P3 | Deferred | `_KeyboardGap` measures its constant on the first keyboard frame, so the stretch can trail by one frame; the cached value can go stale after rotation or a text-scale change. |
| F3 | P3 | Deferred | The keyboard icon has no visible focus indicator (overlay is transparent in every state). |
| F4 | P3 | Deferred | The state line's live region is now a conditionally inserted node; the TalkBack announcement is not verified. |

## Handoff

**Implementation owner:** current session (branch `tnyx/tnyx-226-add-food-single-prompt-field`, from `main` `07bbf612`).
**State:** implemented, committed and pushed as one commit; PR #301 is open and Ready for Review. Source head reviewed before this docs-only reconciliation: `d2aa9add782d3452b22226e0a2155f7d5e099d75`.
**Scope:** presentation and tests only. No backend, provider, Supabase, schema, persistence or routing change.
**Tracker:** TNYX-226 stays `Done`; this is a bounded follow-up to PR #300. TNYX-229 remains the production-readiness gate. TNYX-240 is separate.
**Next exact action:** merge PR #301 once exact-head CI has passed (owner authorized the merge in chat on 2026-09-20), then follow `docs/POST_MERGE_SYNC.md`. Deleting the branch is a separate owner decision.
**Resolved:** the inert mic in the primary colour is covered by approved boundary 6. The send arrow beside it keeps the default ink splash; only the keyboard icon was asked to lose it.
**Not changed:** `apps/features/nutrition/pubspec.lock` is touched by `flutter test` (a stale `dependency:` label on `main`) and is reverted before any commit; it is unrelated to this slice.
