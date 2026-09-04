# TNYX-151 — App Preferences grouped card → canonical settings rows

**Status:** In progress
**Primary owner:** Flutter mobile / Settings feature
**Affected platforms:** Flutter Android and iOS

## Owner Approval and Scope Boundary

**Trigger:** Product-visible UI change on the exact surface the owner reported.
**Approval status:** Approved
**Approval evidence:** Owner confirmed the original physical-device complaint was the App Preferences grouped card (App Mode / Theme / Units rows), not the App Mode selectable option cards, and asked for that one card to be fixed. Scope frozen in GitHub #206 / Linear TNYX-151.
**Approved product/UI/data-shape boundaries:** `app_settings_page.dart` only, plus its focused tests and the geometry expectations that measure it.
**Explicit non-changes:** No other Settings page. No selection-card work (#183 family). No Supabase, migration, routing redesign, or persistence change. No broad token or `TioAlpha`/`TioOpacity` cleanup. No new core component or token.

## Active Handoff

**Implementation owner:** Claude
**Review owner:** Owner
**Base:** `main` `a0b5afcd70aafa298ee0f34ea9f8ba7210aa772b`
**Branch:** `codex/tnyx-151-app-preferences-canonical-rows`
**Device check:** **PENDING OWNER DEVICE CHECK**

## Why this exists

App Preferences was the **last production surface** still composing a raw Material `Card` of three raw `ListTile`s with raw leading `Icon`s and `Divider`s. Verified on the base commit, it referenced the canonical grouped-row family **0 times**, while `settings_page.dart` referenced it 17 times, `health_goals_settings_page.dart` 5, `body_weight_settings_page.dart` 3 and `daily_wellness_settings_page.dart` 2 — plus Nutrition's four grouped surfaces.

That is why the card read as a different component: it rendered Material's own card fill, elevation, radius and margin plus `ListTile` default padding and leading-icon treatment, next to screens rendering the governed `surfaceRaised` group with the canonical rounded leading-icon tile.

## What changed

`Card` → `TioGroupCard` · each `ListTile` → `TioSettingsNavigationRow` · each raw leading `Icon` → `TioSettingsLeadingIcon` · raw `Divider` → a local `_AppSettingsDivider` matching the Settings hub's separator (indent 64, `outlineStrong` @ `alpha20`).

## Preserved exactly

Titles **App Mode / Theme / Units** · supporting text, including the live `currentMode` and `currentThemeMode` labels · all three `ValueKey`s (`app-settings-app-mode-entry`, `app-settings-theme-entry`, `app-settings-units-entry`) · tap callbacks · navigation · behavior · persistence · page padding `TioSpacing.xl` · icons.

## Intentional visual delta — approved

The card gains the canonical grouped-surface treatment and the rows gain the canonical leading-icon tile and row geometry. Measured consequences at the frozen viewports:

| | Before | After |
|---|---|---|
| App Mode row rect (390) | `LTRB(28, 84, 362, 156)` | `LTRB(24, 80, 366, 152)` |
| App Mode row rect (320) | `LTRB(28, 84, 292, 208)` | `LTRB(24, 80, 296, 209)` |
| Theme row rect (390) | `LTRB(28, 157, 362, 229)` | `LTRB(24, 153, 366, 225)` |
| Theme row rect (320) | `LTRB(28, 209, 292, 295)` | `LTRB(24, 210, 296, 305)` |

The group now starts at the page padding (24) instead of 28 and sits 4dp higher, because `TioGroupCard` does not carry Material's own card margin.

**Behavior / navigation / persistence change: NONE.**

## Test geometry — updated, not loosened

`settings_page_test.dart` pinned those rects with the note "measured on the frozen pre-S0-A source". They were **re-measured and updated in this slice**, with the reason recorded inline, rather than relaxed into a range. Its `find.byType(ListTile)` count also moved to `TioSettingsNavigationRow` — that assertion was pinning an implementation detail, not a contract.

`apps/app/test/app/app_mode_router_test.dart` passes **unchanged** (14/14): the three stable keys still resolve and the Theme entry still navigates.

## Tests

New: `apps/features/settings/test/presentation/app_settings_page_test.dart` — 12 cases across one group card / three navigation rows / three leading icons · **no raw `Card` or `ListTile` remains** · all three stable keys survive and resolve to the row type · titles and supporting text unchanged · supporting text follows the live mode and theme · each of the three callbacks fires · tapping one row does not fire the others · light mode · dark mode · large text scale without overflow.

## Validation

At branch head, base `main` `a0b5afcd`:

| Check | Result |
|---|---|
| `dart format` on changed Dart files | PASS |
| `git diff --check` | exit 0 |
| Settings analyze | **No issues found** |
| New App Preferences tests | **12 passed** |
| Settings package suite | **192 passed** |
| `app_mode_router_test.dart` (unchanged) | **14 passed** |
| Workspace analyze | **16/16 packages PASS** |
| Workspace tests | **14/14 packages PASS, 1678 tests** |

Test count 1666 → 1678: the 12 added here.

**Still required before merge:** owner physical-device acceptance on `Settings → App Preferences`, light and dark. This is the surface the original complaint was about, so device sign-off is the point of the slice.
