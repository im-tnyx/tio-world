# Splash screen — replace logo image with "TIO" wordmark

**Status:** In progress
**Primary owner:** `apps/features/splash`
**Affected platforms:** Flutter phone app (`apps/app` via `tio_feature_splash`)

## Global UI / Design-System Guardrail

Read before implementing (done retroactively — see Review Findings below): `.ai/tasks/design-system-token-consolidation.md`, `apps/core/lib/src/theme/README.md`.

## 1. Discovery

### User Outcome

Replace the splash screen's packaged logo image with a large, bold "TIO" text wordmark, so the splash surface is a text mark instead of an image asset.

### Success Criteria

- Splash renders "TIO" as text (no `Image` widget) using the largest/boldest core typography tokens.
- The wordmark and loading spinner stay legible against the splash background in both light and dark theme (owner flagged during review that the initial fixed-white color was invisible on light theme).
- The status/navigation bar icon brightness matches the active theme instead of assuming a permanently dark background (owner flagged: status bar icons — battery, network — didn't match the theme).
- The wordmark's vertical position does not depend on which sibling content (spinner vs. failure/retry block) is currently rendering below it (owner flagged: TIO visibly shifted position between the loading and failure states because both shared one auto-sized `Column`).
- The wordmark and the spinner/failure block can never visually overlap, on any viewport size or system text-scale factor (Codex review flagged that an earlier independent-`Align`-based fix for the point above did not reserve space between the two, so a long, heavily text-scaled failure message could paint over the wordmark).
- The layout never overflows/clips on a short viewport (e.g. landscape or split-screen) combined with a large accessibility text scale; it scrolls instead (Codex review flagged that the fixed-header + `Expanded` design could exceed the available height before `Expanded` is laid out in that scenario).
- No orphaned design-system primitive left behind.
- `apps/features/splash` and `apps/core` analyze/test stay green; exact-head Flutter CI passes.

### Scope

- `apps/features/splash` presentation (`splash_screen.dart`), its asset declaration and test.
- `apps/core` primitive size registry, only to remove the token this change orphaned.
- `docs/screens/splash.md` runtime-behavior line.

### Non-Goals

- No change to splash routing, bootstrap/session logic, or navigation timing.
- No change to `apps/core/assets/brand/dark_logo.jpg` (separate file, used only for launcher-icon generation in `apps/app`/`apps/wear`).
- No redesign of the failure/retry UI beyond the shared color-token fix already covering it.

## 2. Codebase Exploration

### Verified Evidence

- Source/config inspected: `apps/features/splash/lib/src/presentation/screen/splash_screen.dart`, `apps/features/splash/pubspec.yaml`, `apps/features/splash/assets/dark_logo.jpg`, `apps/core/lib/src/theme/tokens/primitive/tio_size.dart`, `apps/core/lib/src/theme/tokens/semantic/tio_colors.dart`, `apps/core/lib/src/theme/tokens/typography/tio_font_size.dart` + `tio_font_weight.dart`, `docs/screens/splash.md`, `apps/features/splash/test/presentation/splash_design_system_ownership_test.dart`, `apps/core/test/theme/final_enforcement_primitive_liveness_test.dart`.
- Repo-wide grep confirmed `apps/features/splash/assets/dark_logo.jpg` was referenced only by the splash screen and its own pubspec; `apps/core/assets/brand/dark_logo.jpg` is a separate physical file used only by `apps/app`/`apps/wear` pubspecs for `flutter_launcher_icons` — unaffected by removing the splash copy.
- `TioColors.onMediaPrimary` is a fixed white token across every color scheme constant (light/dark/oled), intended for text over the fixed `mediaBackground` (always black) — not appropriate for this screen's Scaffold, which paints `colors.background` (theme-adaptive: light → `slate50`, dark → `neutral950`). `colors.textPrimary` is theme-adaptive and is the correct token here.
- `TioFontSize.size44` / `TioFontWeight.w900` are the largest/boldest entries in their respective primitive registries.
- The original `AnnotatedRegion<SystemUiOverlayStyle>` hardcoded `statusBarIconBrightness: Brightness.light` / `statusBarBrightness: Brightness.dark` / `systemNavigationBarIconBrightness: Brightness.light` — correct only for a permanently dark background. Once the background became theme-adaptive (it already was; this was a pre-existing latent bug the wordmark/spinner change exposed), these needed to flip with `colors.isDark` (Android's `statusBarIconBrightness`/`systemNavigationBarIconBrightness` and iOS's `statusBarBrightness` use opposite conventions for the same "is the bar itself dark" question).
- The wordmark and the spinner/failure block were siblings in one `Column` with `mainAxisSize.min` inside a single `Align`; because the failure/retry block is taller than the spinner, swapping between the two states changed the Column's total height and therefore the wordmark's resolved screen position under the shared `Align`. Fixed by decoupling them into two independently positioned `Align` widgets inside a `Stack`: the wordmark at a fixed `Alignment(0, -0.3)`, and the spinner/failure block at `Alignment.center` (a literal dead-center anchor, per owner's explicit request that the spinner always stay centered).
- `apps/features/splash/test/presentation/splash_design_system_ownership_test.dart` statically forbids raw `Colors.*`/`Color(0x...)`/numeric `fontWeight`/numeric `fontSize` in this file — confirmed the implementation only uses `TioFontSize`/`TioFontWeight`/`context.tioColors`.
- `apps/core/test/theme/final_enforcement_primitive_liveness_test.dart` requires every `TioSize`/`TioOpacity`/`TioAlpha`/`TioDuration`/`TioPalette` entry to have at least one production reference outside its own file. Removing the `Image.asset(width/height: TioSize.dp120)` usage left `TioSize.dp120` with zero remaining references anywhere in `apps/` — first Flutter CI run on this branch (`33262625451`) failed on exactly this violation.
- Existing pattern to follow: `tio_size.dart`'s own doc comment — "Add values only when they are evidenced by current production UI" — so removing the now-dead `dp120` entry is the policy-correct fix, not adding a synthetic reference.

## 3. Clarification

### Decisions Required or Made

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Use `colors.textPrimary` (not `onMediaPrimary`) for wordmark + spinner | Made | Splash background is theme-adaptive; a fixed-white foreground was invisible in light theme (owner-reported) | Owner (via review) |
| Shift wordmark/spinner block slightly above center (`Align(0, -0.3)`) | Made | Explicit owner request during review | Owner |
| Remove `TioSize.dp120` rather than keep it or add an allowlist | Made | Matches the registry's own documented liveness policy; confirmed via CI failure + repo-wide grep | Agent, confirmed by CI |
| Give the wordmark a fixed top offset and the spinner/failure block an `Expanded`+`Center`+`SingleChildScrollView` region, instead of two independent `Align`s in a `Stack` | Made | The independent-`Align` version had no reserved, non-overlapping bounds; a Codex review correctly showed the real production failure message, wrapped at a large text-scale factor on a compact viewport, could paint over the wordmark | Agent, per Codex review |

## 4. Architecture Design

### Chosen Approach

Swap the `ClipRRect(Image.asset(...))` block for a plain `Text('TIO', ...)` styled with existing `TioFontSize`/`TioFontWeight` tokens and `context.tioColors.textPrimary`. The wordmark is the first child of a `Column` with a fixed `Padding(top: TioSize.dp100)`, so its position never depends on its sibling. That sibling is `Expanded(child: Center(child: SingleChildScrollView(child: <spinner-or-failure-block>)))`, which fills all remaining space below the wordmark and centers its (possibly scrolling) content within that reserved region — by construction, a `Column`'s `Expanded` regions cannot overlap, and `SingleChildScrollView` means arbitrarily tall/text-scaled content scrolls instead of overflowing upward into the wordmark's area. Recolor the sibling `CircularProgressIndicator` the same way for consistency; drop the now-dead asset, pubspec entry, and `TioSize.dp120` primitive; derive status/navigation bar icon brightness from `colors.isDark`.

### Ownership and Data Flow

No data flow change — this is a presentation-only, stateless-composition edit within `SplashScreen.build()`.

### Alternative Rejected

- Keeping `onMediaPrimary` and instead making the Scaffold background a fixed dark color: rejected as larger-scope (would change the screen's theme-adaptive background contract, not requested).
- Adding a synthetic reference to keep `TioSize.dp120` alive: rejected — contradicts the registry's own "evidenced by current production UI" policy; the correct action is deletion once truly unused.
- Two independent `Align` widgets in a `Stack` (wordmark fixed, spinner/failure block at `Alignment.center`): rejected after Codex review — neither `Align` reserves space for the other, so they can overlap on a compact/text-scaled viewport. Superseded by the `Column`+`Expanded`+`SingleChildScrollView` design above.
- A `LayoutBuilder`/`Positioned`-based explicit split with a computed pixel boundary: considered for exact full-screen-center spinner placement, but rejected as unnecessary complexity — the simpler `Expanded`+`Center` region achieves the same non-overlap guarantee and centers the spinner within the (large majority of screen) space below the wordmark, which is visually indistinguishable from true center for the spinner's small size.
- Final refinement (Codex review #5): the fixed-header + `Expanded` `Column` above still assumed the header always fits within the viewport; on a short/scaled viewport it would not, causing a `RenderFlex` overflow. Wrapped the whole `Column` in the standard Flutter "scroll if it doesn't fit" pattern — `SingleChildScrollView` → `ConstrainedBox(minHeight: viewport height via LayoutBuilder)` → `IntrinsicHeight` → `Column`. In the normal case this pins the Column to exactly the viewport height (so `Expanded` fills the remainder as before); when the header alone would exceed the viewport, `IntrinsicHeight` lets the Column grow to fit and the outer scroll view makes the extra height reachable instead of overflowing/clipping. The inner `SingleChildScrollView` around only the failure/spinner content (from the previous fix) was removed as redundant once the whole composition can scroll.

### Failure and Accessibility States

Unaffected — failure/retry text and button already used theme-adaptive `colors.textSecondary`/`colors.primary` and are untouched by this change.

## 5. Implementation Plan

- [x] Replace the logo `Image.asset` with a `Text('TIO', ...)` wordmark using core typography tokens.
- [x] Remove the unused `apps/features/splash/assets/dark_logo.jpg` and its pubspec entry.
- [x] Fix wordmark color to `colors.textPrimary` (theme-adaptive) after owner flagged light-theme invisibility.
- [x] Shift the wordmark/spinner block slightly above center per owner feedback.
- [x] Fix the loading spinner's matching fixed-white color for the same reason.
- [x] Remove `TioSize.dp120`, orphaned by the image removal, per `apps/core`'s primitive-liveness governance test.
- [x] Make status/navigation bar icon brightness theme-adaptive (was hardcoded for a permanently dark background).
- [x] Decouple the wordmark's position from the spinner/failure block's height via an independently-positioned `Stack`; anchor the spinner/failure block at the literal screen center.
- [x] Replace the `Stack`-of-independent-`Align`s with a `Column` (fixed-offset wordmark, then `Expanded(Center(SingleChildScrollView(...)))`) after a Codex review correctly found the independent-`Align` version could let the wordmark and a long, text-scaled failure message paint over each other on a compact viewport.
- [x] Wrap that `Column` in the `SingleChildScrollView`+`ConstrainedBox`+`IntrinsicHeight` scroll-if-needed pattern after a further Codex review found it could still overflow on a short/scaled viewport where the header alone exceeds the available height.
- [x] Update `docs/screens/splash.md` runtime-behavior line.
- [x] Add/extend widget tests: no `Image` widget remains; wordmark styling; wordmark + spinner color differs from the theme background in both `TioThemeMode.light` and `TioThemeMode.dark`.
- [x] Write this task brief (retroactively, per Codex review finding — see below).

## 6. Quality Review

### Validation Run

```text
apps/features/splash: flutter analyze -> No issues found.
apps/features/splash: flutter test -> 12/12 passed (includes design-system ownership governance test and
  regression coverage for: no Image widget; wordmark styling; wordmark+spinner color differs from
  background on TioThemeMode.light/dark; wordmark position unaffected by spinner-vs-failure state;
  spinner horizontally centered and always below the wordmark; wordmark and failure/retry content never
  overlap on a 320x480 viewport at 2.5x text scale with the real production failure message; an 800x240
  viewport at 3.0x text scale scrolls without throwing/overflowing).
apps/core: flutter analyze -> No issues found.
apps/core: flutter test -> 114/114 passed (includes primitive-liveness governance test).
git diff --check -> clean.
PR #171 exact-head Flutter CI (abbreviated -- each earlier commit was superseded before or shortly after
its own CI result by the next review-driven fix; see git log for the full intermediate trail):
  - commit 1ccc3442: CI run 33262625451 FAILED -- TioSize.dp120 liveness violation (fixed by 56cc00cb).
  - commit 01164767: CI run 33263398556 PASS.
  - commit 3e11413f (overlap-safety Column redesign): CI run 33264543488 PASS.
  - commit <scroll-safety fix HEAD, updated below>: current head, CI pending/result to be recorded on
    completion.
```

### Review Findings and Resolution

- **GitHub Codex automated review #1 (PR #171, inline comment on `splash_screen.dart:57`, commit `56cc00cb`, P1):** flagged that this is a user-facing visual change (branding, typography, vertical layout) implemented without a focused `.ai/tasks/` brief, per `AGENTS.md:L51-L57`. **Valid finding** — the change touches splash typography/layout and a cross-package `apps/core` primitive-registry edit, which the Task Execution Protocol requires a brief for regardless of how small the visible diff looks. Resolved by writing this brief (commit `d108d889`) and recording the full discovery/decision/validation trail after the fact.
- **GitHub Codex automated review #2 (PR #171, inline comment on `tio_size.dart:55`, commit `aa242a34`, P1):** flagged that removing `TioSize.dp120` changed a public `apps/core` token contract without updating `apps/core/lib/src/theme/README.md`'s mandatory compatibility guidance, and that `.ai/tasks/design-system-slice-g-remaining-ui.md` (Validated) still documented `dp120` as governed splash-logo geometry evidence. **Valid finding for the stale task-brief reference** — corrected it (commit `01164767`) to mark that specific line superseded, pointing to this brief. The README itself documents `TioSize` only as a category pattern (`TioSize.dpN`), not individual values, so no README line existed to update; this judgment was surfaced back to the reviewer in the reply thread in case a different treatment (e.g. a removed-primitives changelog) is wanted.
- **GitHub Codex automated review #3 (PR #171, inline comment on `splash_screen.dart:73`, commit `0ae4a5a3`, P2):** flagged that the independent-`Align`-in-`Stack` fix for the wordmark/spinner position bug (below) didn't reserve space between the two, so the real production failure message (`apps/app/lib/app/router.dart:241-243`) wrapped at a large text-scale factor on a compact viewport could paint over the wordmark. **Valid finding** — redesigned as `Column` (fixed-offset wordmark) + `Expanded(Center(SingleChildScrollView(...)))` (spinner/failure block), which cannot overlap by construction; added a regression test at a 320x480 viewport with 2.5x text scale using the actual production failure string.
- **GitHub Codex automated review #4 (PR #171, inline comment on `splash-tio-wordmark.md`, commit `01164767`, P1):** flagged that this brief's recorded validation evidence (`8/8` tests, pending CI for `56cc00cb`) predated later commits' theme-adaptive system-bar/layout changes and two new tests, so it didn't actually validate the reviewed tree. **Valid finding, already addressed** by the very next commit (`0ae4a5a3`), which updated the Validation Run/Final Status to the accurate `10/10` count and the real passing CI run for that exact head; this entry documents that resolution for the record.
- **GitHub Codex automated review #5 (PR #171, inline comment on `splash_screen.dart:62`, commit `3e11413f`, P2):** flagged that the fixed-header + `Expanded` `Column` from review #3's fix still assumed the header (fixed `dp100` padding + a `size44`/`w900` wordmark) always fits within the viewport; on a short landscape/split-screen viewport combined with a large accessibility text scale, the header alone could exceed the available height before `Expanded` is laid out, causing the `Column` to overflow and clip the spinner/recovery UI. **Valid finding** — wrapped the `Column` in the standard `SingleChildScrollView` → `ConstrainedBox(minHeight: viewport height)` → `IntrinsicHeight` pattern: this pins the `Column` to exactly viewport height in the normal case (so `Expanded` still works as before), but lets it grow to fit and become scrollable instead of overflowing when the header alone doesn't fit. Added a regression test at an 800x240 viewport with 3.0x text scale asserting no exception is thrown and all content remains reachable.
- **Owner review (mid-implementation, via chat):** two more defects were found and fixed before CI passed: (1) the status/navigation bar's `SystemUiOverlayStyle` hardcoded brightness for a permanently dark background, causing status-bar icons to mismatch the light theme; (2) the wordmark and the spinner/failure-retry block shared one auto-sized `Column`, so the wordmark's position shifted depending on which (differently-sized) sibling was rendering below it. Both fixed in commit `aa242a34` — status bar brightness now derives from `colors.isDark`; the wordmark/spinner position-coupling was fixed with an independent-`Align`-in-`Stack` design that Codex review #3 (above) then found insufficient and which was superseded by the final `Column`+`Expanded` design.

## 7. Final Handoff

### Changed Files

- `apps/features/splash/lib/src/presentation/screen/splash_screen.dart`
- `apps/features/splash/pubspec.yaml`
- `apps/features/splash/test/presentation/screen/splash_screen_test.dart`
- `apps/features/splash/assets/dark_logo.jpg` (deleted)
- `apps/core/lib/src/theme/tokens/primitive/tio_size.dart`
- `docs/screens/splash.md`
- `.ai/tasks/splash-tio-wordmark.md` (this file)
- `.ai/tasks/README.md`
- `.ai/tasks/design-system-slice-g-remaining-ui.md`

### Actual Behavior

Splash shows a bold "TIO" text wordmark (no image) at a fixed offset from the top, independent of anything below it, followed by a loading spinner or failure/retry UI that fills and centers within the remaining space. The whole composition scrolls instead of overflowing/clipping when it doesn't fit a short or heavily text-scaled viewport. The wordmark, spinner, and status/navigation bar icon brightness are all theme-adaptive (`colors.textPrimary` / `colors.isDark`) so they stay legible and correctly matched in both light and dark theme, and the wordmark can never visually overlap the content below it.

### Known Limitations

None known.

### Final Status

`REVIEW` — implementation and local validation (analyze + 12/12 splash tests + 114/114 core tests) complete for the scroll-safety redesign; awaiting the exact-head Flutter CI result for the current head before this returns to `Validated`.
