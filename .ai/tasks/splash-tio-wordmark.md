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

## 4. Architecture Design

### Chosen Approach

Swap the `ClipRRect(Image.asset(...))` block for a plain `Text('TIO', ...)` styled with existing `TioFontSize`/`TioFontWeight` tokens and `context.tioColors.textPrimary`; wrap the existing content column in `Align(alignment: Alignment(0, -0.3))` instead of `Center` so it renders shifted above dead-center without changing its internal layout; recolor the sibling `CircularProgressIndicator` the same way for consistency; drop the now-dead asset, pubspec entry, and `TioSize.dp120` primitive.

### Ownership and Data Flow

No data flow change — this is a presentation-only, stateless-composition edit within `SplashScreen.build()`.

### Alternative Rejected

- Keeping `onMediaPrimary` and instead making the Scaffold background a fixed dark color: rejected as larger-scope (would change the screen's theme-adaptive background contract, not requested).
- Adding a synthetic reference to keep `TioSize.dp120` alive: rejected — contradicts the registry's own "evidenced by current production UI" policy; the correct action is deletion once truly unused.

### Failure and Accessibility States

Unaffected — failure/retry text and button already used theme-adaptive `colors.textSecondary`/`colors.primary` and are untouched by this change.

## 5. Implementation Plan

- [x] Replace the logo `Image.asset` with a `Text('TIO', ...)` wordmark using core typography tokens.
- [x] Remove the unused `apps/features/splash/assets/dark_logo.jpg` and its pubspec entry.
- [x] Fix wordmark color to `colors.textPrimary` (theme-adaptive) after owner flagged light-theme invisibility.
- [x] Shift the wordmark/spinner block slightly above center per owner feedback.
- [x] Fix the loading spinner's matching fixed-white color for the same reason.
- [x] Remove `TioSize.dp120`, orphaned by the image removal, per `apps/core`'s primitive-liveness governance test.
- [x] Update `docs/screens/splash.md` runtime-behavior line.
- [x] Add/extend widget tests: no `Image` widget remains; wordmark styling; wordmark + spinner color differs from the theme background in both `TioThemeMode.light` and `TioThemeMode.dark`.
- [x] Write this task brief (retroactively, per Codex review finding — see below).

## 6. Quality Review

### Validation Run

```text
apps/features/splash: flutter analyze -> No issues found.
apps/features/splash: flutter test -> 8/8 passed (includes design-system ownership governance test).
apps/core: flutter analyze -> No issues found.
apps/core: flutter test -> 114/114 passed (includes primitive-liveness governance test).
git diff --check -> clean.
PR #171 exact-head Flutter CI:
  - commit 18b8e935 (initial wordmark swap): not separately checked pre-review.
  - commit 1ccc3442 (spinner color fix): CI run 33262625451 FAILED — TioSize.dp120 liveness violation.
  - commit 56cc00cb (dp120 removal): CI run 33262914450 pending at the time of writing this brief; update on completion.
```

### Review Findings and Resolution

- **GitHub Codex automated review (PR #171, inline comment on `splash_screen.dart:57`, commit `56cc00cb`, P1):** flagged that this is a user-facing visual change (branding, typography, vertical layout) implemented without a focused `.ai/tasks/` brief, per `AGENTS.md:L51-L57`. **Valid finding** — the change touches splash typography/layout and a cross-package `apps/core` primitive-registry edit, which the Task Execution Protocol requires a brief for regardless of how small the visible diff looks. Resolved by writing this brief and recording the full discovery/decision/validation trail after the fact.

## 7. Final Handoff

### Changed Files

- `apps/features/splash/lib/src/presentation/screen/splash_screen.dart`
- `apps/features/splash/pubspec.yaml`
- `apps/features/splash/test/presentation/screen/splash_screen_test.dart`
- `apps/features/splash/assets/dark_logo.jpg` (deleted)
- `apps/core/lib/src/theme/tokens/primitive/tio_size.dart`
- `docs/screens/splash.md`
- `.ai/tasks/splash-tio-wordmark.md` (this file)

### Actual Behavior

Splash shows a bold "TIO" text wordmark (no image) positioned slightly above center, followed by a loading spinner or failure/retry UI; both the wordmark and spinner now use the theme-adaptive `textPrimary` color so they stay legible in light and dark theme.

### Known Limitations

None known. The failure-message/retry UI was already theme-adaptive and untouched.

### Final Status

`REVIEW` — implementation and local validation complete; awaiting the exact-head Flutter CI result for commit `56cc00cb` before this can move to `Validated`.
