# Meal Diary today glyph — centre the day number in the calendar body

**Status:** In progress
**Primary owner:** `apps/app` shell (`_mealDiaryTodayGlyph` in `router.dart`)
**Affected platforms:** Flutter Android + iOS phone app

Trackers: none yet. No GitHub issue and no Linear issue exist for this slice; the Linear connector is currently invalid, so a Linear mirror could not be read or created (record, do not invent). Owner reported it directly with two reference screenshots.

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI change (Meal Diary top-bar Today icon: day number mis-positioned, plus an intentional accent-colour change for the number).
**Approval status:** OWNER APPROVED FOR IMPLEMENTATION (2026-09-22). Publication (commit/push/PR) is a separate gate and is not authorized yet.
**Approval evidence:** Owner reported the defect with a current screenshot and a reference screenshot (2026-09-22), confirmed "text thoda niche hota hai", and chose: **brief + plan first, then approval**; then refined the colour decision to **accent colour = the existing `info` (sky) semantic role** after seeing rendered options (an earlier "keep current colour" answer is superseded).
**Approved product/UI boundaries:**

- the day number is centred inside the calendar body and no longer collides with the bottom stroke;
- the day number is painted with `context.tioColors.info` (Dark/Tio Dark `sky400` `#38BDF8`, Light `sky600` `#0284C7`); the calendar outline keeps `colorScheme.onSurface`;
- the calendar outline asset, icon box (24dp), tap target, tooltip, position in the top bar and `ValueKey`s stay exactly as they are.

**Explicit non-changes:** no new `TioPalette`/`TioColors` token and no recolour of existing tokens; no SVG asset edit; no outline colour change; no new core component (one-off app-shell composition stays where it is per `apps/features/AGENTS.md` / theme README); no top-bar layout, order or spacing change; no Meal Diary screen redesign; no change to `shouldShowTodayAction` behaviour, streak icon or the More menu; no Wear/watchOS change.

## Active Handoff

**Planning owner:** Claude
**Implementation owner:** Claude
**Review owner:** Owner
**Implementation ownership state:** Active
**Repository state last verified:** 2026-09-22
**Branch:** `claude/meal-diary-today-glyph` (local only, from `main` `df0a0ce45605e13ed4471466ba056e0f2d1b338b`)
**HEAD SHA:** `df0a0ce45605e13ed4471466ba056e0f2d1b338b` (= `origin/main`)
**Observed working-tree state:** `router.dart` modified; `meal_diary_today_glyph.dart`, its test and this brief untracked. Nothing committed or pushed.
**PR / tracker:** none
**Validation completed at SHA:** working tree on base `df0a0ce` (uncommitted); see §6.
**Validation remaining:** none locally. Owner confirmed the fix visually on the installed debug build (2026-09-22). CI would run on a future PR.
**Current blocker:** none. Publication (commit/push/PR) not authorized yet.
**Next exact action:** owner authorizes publication → branch `claude/meal-diary-today-glyph` commit + push + PR per `docs/PUSH_TEMPLATE.md`.

## Global UI / Design-System Guardrail

Read `.ai/tasks/design-system-token-consolidation.md` and `apps/core/lib/src/theme/README.md` before changing visual implementation. This slice changes **one glyph's internal geometry and the day number's colour role only**. It must not change palette values, the icon asset, component geometry elsewhere, spacing tokens, typography scale or motion.

## 1. Discovery

### User Outcome

The Meal Diary top-bar "Today" icon reads as a calendar with the date sitting properly inside it, like the owner's reference — not a cramped number pressed against the bottom edge.

### Success Criteria

- The day number's painted box is horizontally centred in the 24dp glyph and vertically centred in the calendar body (between the header divider and the bottom stroke).
- The number never paints over the bottom stroke, at 1.0 and at 1.6 text scale, for 1- and 2-digit days.
- The number is painted with the `info` accent in all three themes; outline colour, asset, key, tap target, tooltip and top-bar position are unchanged.

### Scope

`_mealDiaryTodayGlyph` in `apps/app/lib/app/router.dart` plus focused tests.

### Non-Goals

See **Explicit non-changes**.

## 2. Codebase Exploration

### Verified Evidence (main `df0a0ce`)

- `apps/app/lib/app/router.dart:108-145` — `_mealDiaryTodayGlyph` builds `SizedBox(24×24)` → `Stack(fit: expand)` with `SvgPicture.asset('assets/svg_icon/ic_calendar.svg', package: 'tio_core')` tinted `colorScheme.onSurface`, and the day label in `Positioned(left: TioSpacing.xs /*4*/, top: TioSpacing.md /*12*/, right: TioSpacing.xs /*4*/, bottom: TioSpacing.xxs /*2*/)` → `FittedBox(scaleDown)` → `Text(style: labelSmall.copyWith(w700))`.
- `apps/core/assets/svg_icon/ic_calendar.svg` — body rounded rect y `4 → 21.5`, header divider at y `9.5`, tabs y `2.5 → 5.5`, stroke `1.3`. So the calendar **body** is y `9.5 → 21.5` (centre `15.5`).
- **Defect:** the label slot is y `12 → 22`, i.e. its centre is `17` (1.5dp below the body centre) and its bottom edge crosses the bottom stroke at `21.5`. The slot is only 10dp tall while `labelSmall` is `TioFontSize.size12` / `w600`, whose line box is taller, so `FittedBox` shrinks the glyph to roughly 7.5dp and drops it low — the cramped look in the owner's screenshot.
- `TioSize` has `dp3` and `dp10`; `TioFontSize` has `size9_5`; no fractional-dp token is needed.
- Tests touching this glyph: `apps/app/test/app/app_mode_router_test.dart:205-240` (glyph + day-label presence inside the Today action) and `:838-852` (painted glyph rect must not overlap the centred month label). No geometry assertion exists for the number itself.
- No production code uses `TextScaler.noScaling`, so text-scale safety must stay inside the widget (keep `FittedBox`).
- No golden-file infrastructure exists in this repo.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Day number uses the existing `info` (sky) accent | **Owner-decided 2026-09-22** | Closest existing token to the reference blue; avoids adding a new palette/semantic token. Rejected: `primary` (white in Dark/Tio Dark ⇒ no visible accent), `progress` violet, `nutrition` green, new brand blue `~#6C8CF5` (design-system change) | Owner |
| No new core component for the glyph | Made | One-off app-shell composition; theme README/`apps/features/AGENTS.md` require real reuse evidence before promoting to core | Planning |
| Keep `FittedBox(scaleDown)` | Made | Only in-widget guard against large text scale; repo has no no-scaling convention | Planning |
| Brief + plan before code | **Owner-decided 2026-09-22** | Product-visible change | Owner |

## 4. Architecture Design

### Chosen approach

Inside the existing `Stack`, replace the mis-measured slot with one that matches the calendar body, and give the number an explicit, deterministic size:

```text
Positioned(left: dp3, right: dp3, top: dp10, bottom: dp3)   // the drawn body: x 3→21, y 10→21, centre 15.5
  └ Center
     └ FittedBox(scaleDown)
        └ Text(day, style: labelSmall.copyWith(
              fontSize: TioFontSize.size9_5, height: TioLineHeight.height110,
              fontWeight: w700, color: context.tioColors.info))   // accent; outline stays onSurface
```

- `top: dp10` clears the header divider (9.5 + half stroke); `bottom: dp3` clears the bottom stroke (21.5 − half stroke). Slot centre `15.5` is exactly the body centre.
- `left`/`right: dp3` stop the slot at the body's side strokes, so wide digits are scaled down instead of painting over them.
- `height110` (1.10) is the smallest existing line-height token; at `size9_5` the line box is 10.45dp and fits the 11dp slot, so `Center` centres the digits rather than a tall line box. No new token is introduced for this.
- `size9_5` in a 24dp icon ≈ 40 % of the icon height, matching the reference proportion.
- `FittedBox(scaleDown)` stays, so at 1.6 text scale the number shrinks inside the slot instead of overflowing.

### Alternative rejected

- A new brand-blue token matching the reference exactly (`~#6C8CF5`): rejected for this slice — it would be an `apps/core` palette + semantic-role change with wider ownership. `info` is the closest existing role.
- `colors.primary` as the accent: rejected — it resolves to white in Dark/Tio Dark, so the number would look unchanged.
- Editing `ic_calendar.svg` (e.g. baking the number in): the asset is shared and correct; the defect is in the overlay.
- Promoting the glyph to a reusable core component: no second consumer today.

### Failure and accessibility states

- `ExcludeSemantics` and the `IconButton` tooltip stay as-is, so screen readers keep announcing the action, not the digits. Colour is decorative here: the date is also stated by the tooltip, so no information is conveyed by colour alone.
- Contrast of the accent against the surface it paints on (measured): `sky400` on `#000000` 9.8:1 and on `#111827` 8.28:1 (Dark / Tio Dark); `sky600` on `#FFFFFF` 4.1:1 and on `#F8FAFC` 3.91:1 (Light). All clear the 3:1 non-text bar, and Light also clears 3:1 with margin.

## 5. Implementation Plan (allowlist)

### Production (2)

- [x] `apps/app/lib/app/meal_diary_today_glyph.dart` — **new**: the private `_mealDiaryTodayGlyph` closure extracted into a public `MealDiaryTodayGlyph` widget, with the corrected geometry and accent.
- [x] `apps/app/lib/app/router.dart` — import the widget, drop the private builder, pass `localToday` (3 lines added, 43 removed; no formatter churn — the file is unformatted on `main`, so it was edited without running `dart format` over it).

**Allowlist deviation (recorded):** the brief planned one production file. A second file was added because the glyph was a private closure inside a ~1.6k-line router, which no focused geometry test can reach. Extraction keeps it in `apps/app` (not core, no reuse evidence), changes no behaviour beyond this slice, and leaves both `ValueKey`s intact.

### Tests (2)

- [x] `apps/app/test/app/meal_diary_today_glyph_test.dart` (new, focused): for days 4, 12 and 28, at text scale 1.0 and 1.6 —
  - the day label's painted rect is horizontally centred within the glyph rect (±0.5dp);
  - its vertical centre sits at the calendar body centre (glyph top + 15.5dp, ±0.75dp);
  - its top stays below the header divider (≥ glyph top + 10dp) and its bottom above the bottom stroke (≤ glyph top + 21dp);
  - the label's resolved colour equals `TioColors.<scheme>.info` in Light, Dark and Tio Dark, while the `SvgPicture` keeps the `onSurface` tint;
  - no overflow exception.
- [x] `apps/app/test/app/app_mode_router_test.dart` — untouched; its existing glyph expectations still pass.

### Current docs (0)

No doc changes: no public contract, token or component API changes. (`apps/core/lib/src/theme/README.md` is untouched because no core token/contract changes.)

Anything outside this allowlist needs a recorded reason here first.

## 6. Quality Review

### Validation plan

```text
dart format <changed files>
git diff --check
cd apps/app && flutter analyze --no-pub
cd apps/app && flutter test --no-pub test/app/meal_diary_today_glyph_test.dart test/app/app_mode_router_test.dart
full: per-package analyze + test across the workspace (melos 8.6.0 locally cannot read this melos.yaml; run CI-equivalent package commands)
visual: render the glyph to a PNG and inspect it before claiming done
optional (owner gate): Pixel_9 emulator / physical device check of the Meal Diary top bar in light, Dark and Tio Dark
```

### Validation Run

Run 2026-09-22 on branch `claude/meal-diary-today-glyph` (base `main` `df0a0ce`):

```text
dart format lib/app/meal_diary_today_glyph.dart test/app/meal_diary_today_glyph_test.dart  -> applied
                                        (router.dart deliberately NOT formatted: unformatted on main)
cd apps/app && flutter analyze --no-pub -> No issues found!
cd apps/app && flutter test --no-pub test/app/meal_diary_today_glyph_test.dart -> +9 All tests passed
cd apps/app && flutter test --no-pub   -> +353 All tests passed (includes app_mode_router_test)
git diff --check                        -> clean
```

Test-font note: `flutter_test` draws square glyphs, so "12" measures ~20dp wide in the test — wider than any real typeface. The width guard was therefore replaced by body-bound assertions (`label.left ≥ body left`, `label.right ≤ body right`), which is the stricter contract and is what caught the original slot width.

Device evidence: debug APK built from this tree and installed on the Pixel_9 emulator (`adb install -r` → Success). The emulator session is unauthenticated, so Meal Diary itself is behind sign-in there and no agent-side screenshot of the screen was taken. **Owner checked the installed build and confirmed the fix reads correctly (2026-09-22).** Workspace-wide package checks are unnecessary — the change is confined to `apps/app`.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence |
|---|---|---|---|---|---|
| — | — | — | none | `df0a0ce` | — |

### Risks

- `app_mode_router_test.dart:838-852` measures the painted glyph rect; the glyph box stays 24×24, so the guard should be unaffected — verify, do not assume.
- Exact perceived size is a judgement call; if the owner wants the number larger/smaller, it is a one-line `fontSize` change within this same approved scope.

## 7. Final Handoff

### Changed Files

This gate: `.ai/tasks/meal-diary-today-glyph-centering.md` only (untracked). No source change. Nothing committed or pushed.

### Final Status

`REVIEW` — plan ready, awaiting owner implementation approval.
