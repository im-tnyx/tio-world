# TNYX-157 — Theme semantics: System / Light / Dark / Tio Dark

**Status:** In progress
**Primary owner:** `apps/core/lib/src/theme` (mode semantics) + `apps/app` (device-local persistence) + `apps/features/settings` (labels) + `apps/wear` (semantic rename)
**Affected platforms:** Flutter Android + iOS phone app, Flutter Wear OS

Trackers: GitHub [#213](https://github.com/im-tnyx/tio-world/issues/213) · Linear [TNYX-157](https://linear.app/tnyx/issue/TNYX-157/s0-g-theme-semantics-system-light-dark-tio-dark) (parent TNYX-118, In Review / Low)

## Owner Approval and Scope Boundary

**Trigger:** Unapproved product-visible UI/UX change (theme option labels/copy; System + OS-dark rendering changes from navy/slate to pure-black).
**Approval status:** OWNER APPROVED FOR IMPLEMENTATION (2026-09-22, starting SHA `fec4e0568f23e65c5d6bb444953f883314491a85`)
**Approval evidence:** Product semantics, migration contract and persistence direction frozen by owner decision 2026-09-22 and recorded in GitHub #213 / Linear TNYX-157. Owner authorized only this readiness/task-brief gate (audit + brief + local branch). Owner brief review (2026-09-22) froze the User Outcome compatibility wording, the legacy rollback-mirror strategy (§4.4) and the option copy (§4.6). Owner explicit implementation authorization (2026-09-22) approved the bounded slice in this brief, including all product-visible changes (four modes, palette mapping, System OS-dark → pure-black incl. the accepted legacy-System navy→pure-black change, Appearance copy, keys, unchanged icons/presentation), the dual-key rollback compatibility strategy, and the downgrade→old-build-change→re-upgrade caveat (V2 wins; no timestamp/version arbitration). Commit/push/PR/merge, closing #213 and marking TNYX-157 Done are **not** authorized in this gate.
**Approved product/UI/data-shape boundaries (frozen, not to be reopened):**

- exactly four user-facing modes: System, Light, Dark, Tio Dark;
- Light → existing Light palette; Dark → existing OLED/pure-black palette; Tio Dark → existing current Dark/navy-slate palette;
- System → OS Light ⇒ Light, OS Dark ⇒ Dark (pure-black), never Tio Dark;
- legacy migration `system→system`, `light→light`, `dark→tio_dark`, `oled→dark`;
- persistence `app_theme_mode` (legacy) → `app_theme_mode_v2` (`system`/`light`/`dark`/`tio_dark`), device-local; V2 always wins;
- legacy `app_theme_mode` is retained as a temporary downgrade/rollback compatibility mirror holding **old-meaning** values only (owner decision 2026-09-22, brief review);
- Appearance subtitles: Dark `Pure black appearance`, Tio Dark `Tio's signature midnight navy theme` (owner-frozen, §4.6);
- Wear: legacy OLED semantic → new Dark semantic, same pure-black rendering.

**Explicit non-changes:** no fifth mode; no hidden legacy-System mode, per-user compatibility flag or migrated-user-specific behavior; no new/second palette and no recolor; no `TioColors`/`TioShadows` value or constant-name change; no Supabase/schema/account-synced state; no `TioSelectableCard` adoption or Theme option-card visual refactor (#183 / TNYX-139); no bottom-sheet shell migration (#208); no persistence-failure UX redesign; no Settings redesign; no broad dark-theme test rewrite; no historical `.ai/tasks/*` rewrite.

## Active Handoff

**Planning owner:** Claude (readiness/task-brief gate)
**Implementation owner:** Claude (current implementation agent)
**Review owner:** Owner
**Implementation ownership state:** Active
**Ownership transition:** NONE → Claude (owner implementation authorization 2026-09-22)
**Repository state last verified:** 2026-09-22
**Branch:** `tnyx/tnyx-157-theme-semantics-migration` (pushed; tracks `origin/tnyx/tnyx-157-theme-semantics-migration`)
**HEAD SHA:** `71256c81b0bc5725925cf7e73a57c79059720010` (base `fec4e05` = `origin/main`; ahead 1 / behind 0)
**Observed working-tree state:** implementation committed as `71256c8` (24 files) and pushed; only this brief has a local post-commit update (publication evidence), not yet pushed.
**Observed uncommitted/dirty files:** `.ai/tasks/tnyx-157-theme-semantics-migration.md` (publication evidence only)
**PR / tracker:** Draft PR #318 (head `71256c8`). GitHub #213 OPEN. Linear TNYX-157 In Review / Low / parent TNYX-118.
**Current implementation state:** Implementation complete for the approved slice; automated validation passed (§6 Validation Run).
**Relevant execution surface:** see §5 allowlist.
**Validation completed at SHA:** local validation ran on the tree committed as `71256c8` (staged hash matched the reviewed tree); CI on #318 in progress.
**Validation remaining:** CI on #318 (Analyze and test, Build Android debug APKs pending at handoff). Owner review accepted (R1 P3 deferred); owner phone QA PASS; Wear physical + downgrade QA not run.
**Current blocker:** none. Owner authorized the publication gate 2026-09-22: commit, push, Draft PR against `main`, Linear → In Review. Merge, Done and closing #213 are not authorized.
**Open review finding IDs:** R1 (P3, Deferred — owner-accepted known limitation)
**Next exact action:** CI + PR review gate on #318. Merge, Linear Done and closing #213 are not authorized yet.

## Global UI / Design-System Guardrail

Read `.ai/tasks/design-system-token-consolidation.md` and `apps/core/lib/src/theme/README.md` before changing visual implementation; follow `apps/features/AGENTS.md` under `apps/features/*`. This slice changes **mode→palette resolution and copy only**. It must not change any palette value, shadow value, geometry, spacing, typography, icon size, component structure or motion. The only intended visual deltas are listed in §4.7.

## 1. Discovery

### User Outcome

Users see four clearly named appearances: **System**, **Light**, **Dark** (standard pure-black) and **Tio Dark** (Tio's navy/slate identity). System on a dark OS gives the standard pure-black Dark.

Users who explicitly selected legacy Light, Dark, or OLED keep the same palette after migration. Legacy System users preserve follow-OS semantics; on OS Dark their appearance intentionally changes from navy/slate to pure-black.

### Success Criteria

- `TioThemeMode` has exactly `system`, `light`, `dark`, `tioDark`; `oled` removed.
- `dark` resolves `TioColors.oled`/`TioShadows.oled`; `tioDark` resolves `TioColors.dark`/`TioShadows.dark`; `system` resolves Light or `TioColors.oled`/`TioShadows.oled` on OS dark.
- Persistence migrates `app_theme_mode` → `app_theme_mode_v2` per §4.3–4.5; legacy `dark` never read as new `dark`; legacy key keeps old meanings as a rollback mirror and never decides behavior while a valid V2 exists.
- Settings summary, Appearance sheet and compatibility `ThemeSettingsPage` show System / Light / Dark / Tio Dark consistently.
- Wear keeps pure-black rendering using `TioThemeMode.dark`.
- Focused tests in §5.2 cover the contract; full suite passes.

### Scope

Mode semantics, System resolution, device-local persistence migration, user-facing theme labels, Wear semantic rename, necessary contract tests and the two current docs in §5.3.

### Non-Goals

See **Explicit non-changes** above. Also out of scope: the pre-existing Appearance-sheet behavior of dismissing in `finally` when persistence throws (separate gap, not #213).

## 2. Codebase Exploration

### Verified Evidence (main `fec4e05`)

- `apps/core/lib/src/theme/tio_theme_config.dart:3` — `enum TioThemeMode { system, light, dark, oled }`; default `system`.
- `apps/core/lib/src/theme/tio_theme.dart:183-205` — only production mode→palette/shadow resolution: `dark→TioColors.dark`, `oled→TioColors.oled`, `system+OS dark→TioColors.dark`; shadows identical pattern. High contrast is applied after resolution (`colors.highContrast`).
- `TioColors.dark` = navy/slate (`neutral950` background); `TioColors.oled` = pure black (`TioPalette.black`, `gray005` surface). `TioShadows.dark`/`.oled` currently hold identical values.
- No production code outside `tio_theme.dart` references `TioColors.dark/oled` or `TioShadows.dark/oled` (context fallbacks use `.light`).
- `apps/app/lib/app/shared_preferences_app_theme_preference.dart` — `SharedPreferencesAsync`, key `app_theme_mode`, values `system/light/dark/oled`; unknown → `null`; `clear()` removes key.
- `apps/app/lib/app/app_theme_preference.dart` — interface `read()/write()/clear()`; enum-generic.
- `apps/app/lib/app/app_theme_controller.dart` — `load()`: `read() ?? system`; if `read()` throws → `system` + `lastError`. `select()` publishes only after successful `write()`. `clear()` awaits `preference.clear()` before resetting to `system`. Enum-generic; no production caller of `clear()` today.
- `apps/features/settings/.../app_settings_page.dart:132-139` — `_themeModeLabel` switch `System/Light/Dark/OLED`.
- `apps/features/settings/.../theme_settings_page.dart:76-99` — compatibility page `SegmentedButton` with 4 segments incl. `OLED`; shows explicit error text on failure.
- `apps/features/settings/.../theme_selection_bottom_sheet.dart:142-185` — canonical Appearance sheet; keys `theme-option-system/light/dark/oled`; `_ThemeOptionTile` presentation is #183 territory.
- `apps/app/lib/app/router.dart:1573` canonical sheet entry; `:1622` `/settings/theme` compatibility route.
- `apps/wear/lib/wear_app.dart:29` — `TioThemeConfig(mode: TioThemeMode.oled)`.
- No native (Kotlin/Swift/XML/JSON) reference to `app_theme_mode` or OLED. No golden files in the repo.
- Repository has no Dart persistence of `TioThemeMode.name`; storage uses explicit strings.

### Exact reference inventory

**PRODUCTION — must change (7)**

| File | Reference | Change |
|---|---|---|
| `apps/core/lib/src/theme/tio_theme_config.dart` | enum | `oled` → removed, add `tioDark`; doc comments stating palette mapping |
| `apps/core/lib/src/theme/tio_theme.dart` | `_resolveColors`, `_resolveShadows` | remap per §4.1 |
| `apps/app/lib/app/shared_preferences_app_theme_preference.dart` | key/values | V2 + migration per §4.3–4.5 |
| `apps/features/settings/lib/src/presentation/pages/app_settings_page.dart` | `_themeModeLabel` | `Dark`, `Tio Dark` |
| `apps/features/settings/lib/src/presentation/pages/theme_settings_page.dart` | 4th segment | `tioDark` / `Tio Dark` |
| `apps/features/settings/lib/src/presentation/widgets/theme_selection_bottom_sheet.dart` | option list data only | per §4.6 |
| `apps/wear/lib/wear_app.dart` | `TioThemeMode.oled` | `TioThemeMode.dark` |

**PRODUCTION — reference, unchanged:** `app_theme_controller.dart`, `app_theme_preference.dart`, `app_theme.dart` (barrel), `router.dart`, `tokens/semantic/tio_colors.dart`, `tokens/effects/tio_shadows.dart`, `context/tio_theme_context.dart`.

**TEST — must change (14)**

| File | Why |
|---|---|
| `apps/app/test/app/shared_preferences_app_theme_preference_test.dart` | uses `oled`; becomes the migration/persistence contract suite (§6) |
| `apps/app/test/app/app_theme_controller_test.dart` | uses `oled` (compile) → `tioDark` |
| `apps/app/test/app/app_mode_router_test.dart` | `oled` in system-bar case (:44-46) and layout matrix (:761); add compat-page 4-label assertion to existing theme-route test (:700-722) |
| `apps/app/test/app/meal_logging_modal_theme_test.dart` | `(dark, TioColors.dark)/(oled, TioColors.oled)` matrix → `(tioDark, TioColors.dark)/(dark, TioColors.oled)` |
| `apps/app/test/app/tio_theme_accessibility_test.dart` | "OLED mode exposes pure-black" (:129-137) → `TioThemeMode.dark`; add System+OS-dark pure-black case |
| `apps/core/test/theme/context_accessors_contract_test.dart` | `mode: dark` expects `TioColors.dark` → breaks; becomes the core resolution matrix (4 modes + System light/dark → colors + shadows) |
| `apps/core/test/ui/components/tio_date_time_wheel_picker_test.dart` | `mode: oled` → `dark` (expectations on `TioColors.oled` stay) |
| `apps/core/test/ui/components/tio_selectable_card_test.dart` | `mode: dark` asserts `TioColors.dark.surface` → switch argument to `tioDark` only (no #183 work) |
| `apps/features/nutrition/test/meal_diary/archived_meal_categories_test.dart` | Dark/OLED palette matrix (:354-355) |
| `apps/features/nutrition/test/meal_diary/meal_categories_settings_test.dart` | matrices at :416-417, :665-666, :2724-2729 (incl. System-dark → `TioColors.oled`) |
| `apps/features/nutrition/test/meal_diary/meal_diary_settings_shell_test.dart` | matrix :263-265 (incl. System-dark → `TioColors.oled`) |
| `apps/features/nutrition/test/meal_logging/meal_diary_add_food_flow_test.dart` | Dark/OLED/System-dark/live-change cases (:2013-2105) |
| `apps/features/settings/test/presentation/theme_selection_bottom_sheet_test.dart` | keys/labels; tap `theme-option-tio-dark` → `tioDark`; tap `theme-option-dark` → `dark` |
| `apps/features/settings/test/presentation/app_settings_page_test.dart` | add `Tio Dark` summary assertion (existing `Dark` assertion stays valid) |

Matrix rewrite rule for nutrition/app palette matrices: rename rows, do not restructure tests — `('Dark', dark, TioColors.dark)` → `('Tio Dark', tioDark, TioColors.dark)`; `('OLED', oled, TioColors.oled)` → `('Dark', dark, TioColors.oled)`; `System-dark` expected → `TioColors.oled`. The add-food "OLED is its own palette, not an alias of Dark" guard becomes "Dark (pure-black) is not an alias of Tio Dark".

**TEST — generic dark fixtures, unchanged (verified no navy-specific assertion; they will render pure-black and still pass):** `startup_hydration_test`, `welcome_accessibility_test`, `account_settings_route_test`, `body_weight_route_test`, `daily_wellness_route_test`, `nutrition_settings_route_test`, `onboarding_root_logout_router_test`, `router_provider_stability_test`, `tio_input_test` (alpha only), `tio_button_test` / `tio_remove_image_bottom_sheet_test` / `meal_type_selector_test` (`TioThemeMode.values` loops over resolved colors), `tio_date_calendar_ring_geometry_test` (asserts only `primary`/`progress`, identical in both dark palettes), `tio_dob_wheel_selection_pill_test` (palette-level), `meal_editor_create_page_test`, `meal_diary_history_view_test`, `meal_diary_daily_nutrition_*`, `nutrition_settings_page_test`, other nutrition meal-diary/meal-logging widget tests, `settings_page_test` (`Dark` label stays valid), `body_weight/daily_wellness/health_goals/calendar_settings_page_test`, `splash_screen_test`, `height_wheel_selection_pill_test`, `tio_weight_wheel_test`, `tio_anchored_popup_placement_test`. `tio_theme_accessibility_test` high-contrast dark case also stays valid (high contrast overrides the asserted fields).

**TEST — palette-level, unchanged under the §4.2 decision:** `core_color_ownership_contract_test`, `extended_theme_contract_test`, `tio_colors_lerp_test`.

**TEST — Wear, unchanged, required gate:** `apps/wear/test/wear_home_hardening_test.dart` ("TioWearApp uses the canonical OLED Tio theme" asserts `TioPalette.black` background) — must still pass after the rename; proves pure-black preservation.

**CURRENT DOC — must change (2):** `docs/screens/settings.md` (Theme Interaction section: choices + storage key), `apps/core/lib/src/theme/README.md` (add mode→palette resolution map; README requires the map to stay current).

**CURRENT DOC — unchanged:** `docs/ONBOARDING_ARCHITECTURE.md:719`, `docs/screens/onboarding.md:233` (refer to the dark/OLED *palettes* as QA coverage, which still exist), `docs/UX_UI_SYSTEM.md`, ADR-0004.

**HISTORICAL `.ai` EVIDENCE — do not rewrite:** `auth-google-identity-and-bootstrap-loading`, `auth-mobile-first-mode-switch-complementary-contact`, `design-system-hardcoded-color-audit`, `design-system-slice-b-welcome`, `design-system-slice-h-final-enforcement`, `design-system-token-consolidation`, `material-3-expressive`, `onboarding-flow`, `production-hardening-tio-colors-lerp`, `production-hardening-wear-os`, `settings-s0a-truthfulness-units`, `settings-s0b4-body-weight-device-qa`, `splash-tio-wordmark`, `tnyx-226-add-food-single-prompt-field`, `tnyx-67-meal-categories-readiness`, `tnyx-68-meal-diary-settings-shell-readiness`, `welcome-signin-footer-theme-contrast`.

**OUT OF SCOPE / UNRELATED:** `apps/features/onboarding/test/domain/*` `mode.name` hits (App Mode, not theme); `.agents/skills/**` "pooled" matches.

## 3. Clarification

| Decision | Status | Rationale | Owner |
|---|---|---|---|
| Four modes and palette mapping | Frozen | Owner decision 2026-09-22 | Owner |
| Legacy migration table and V2 key | Frozen | Owner decision 2026-09-22 | Owner |
| Enum shape `system/light/dark/tioDark`, `oled` removed | Made (§4.1) | No source evidence needs a 5th value; legacy strings are migrated at the storage boundary | Planning |
| Palette/shadow constants unchanged (Option A) | Made (§4.2) | Smallest, no silent renames | Planning |
| V2 precedence (V2 always wins) | Frozen (§4.3) | Owner brief review 2026-09-22 | Owner |
| Legacy key retained as old-meaning rollback mirror; dual-write on `write()`; no legacy deletion in this slice | Frozen (§4.4) | Downgrade/rollback compatibility; owner brief review 2026-09-22 | Owner |
| Migration/mirror write-failure handling, `clear()` ordering | Made (§4.4–4.5) | Never silently change the resolved theme; never resurrect stale state | Planning |
| Option copy/subtitles/keys (§4.6) | Frozen | Owner brief review 2026-09-22; icons/presentation unchanged | Owner |

## 4. Architecture Design

### 4.1 Enum and runtime resolution

```dart
enum TioThemeMode { system, light, dark, tioDark }
```

| Mode | Colors | Shadows |
|---|---|---|
| `light` | `TioColors.light` | `TioShadows.light` |
| `dark` | `TioColors.oled` | `TioShadows.oled` |
| `tioDark` | `TioColors.dark` | `TioShadows.dark` |
| `system` + OS light | `TioColors.light` | `TioShadows.light` |
| `system` + OS dark | `TioColors.oled` | `TioShadows.oled` |

High contrast continues to be applied after base resolution (unchanged). Default config mode stays `system`. Exhaustive `switch` expressions give compile-time coverage of every production branch.

### 4.2 Palette/shadow naming decision — Option A (keep internal constants)

Keep `TioColors.light/dark/oled` and `TioShadows.light/dark/oled` names and values unchanged; only `TioThemeMode` maps onto them. Document the mapping in enum doc comments and the theme README.

Option B (rename `TioColors.dark→tioDark`, `TioColors.oled→dark`, same for shadows) rejected: it would silently change the meaning of the identifier `TioColors.dark` (navy → black) with no compile error, which breaks palette-level contract tests (`core_color_ownership_contract_test` asserts `TioColors.dark.background == neutral950`) and any in-flight branch. It adds ~6+ test files of churn plus core contract edits with zero runtime benefit. Internal palette names are implementation roles ("navy/slate dark", "OLED pure-black"), not user-facing names. No recolor.

### 4.3 Persistence keys and V2 read precedence (exact)

| Key | Role | Values and meaning |
|---|---|---|
| `app_theme_mode_v2` | **Canonical** in the current app | `system`, `light`, `dark` (pure-black), `tio_dark` (navy/slate) |
| `app_theme_mode` | Legacy; temporary downgrade/rollback compatibility mirror | `system`, `light`, `dark` (navy/slate), `oled` (pure-black) — **old meanings only**, never reused with new meanings |

`SharedPreferencesAppThemePreference.read()`:

1. Read `app_theme_mode_v2`. If the key is **present**: `system/light/dark/tio_dark` → mode; any other value → `null` (existing missing-value behavior ⇒ controller resolves `system`). A present-but-corrupt V2 **does not** fall back to legacy and triggers **no writes**. **V2 always wins**; the legacy value is never consulted while V2 is present.
2. If V2 is **absent**: read legacy `app_theme_mode`. Absent → `null`. Unknown/corrupt → `null`, **no writes**, legacy left untouched.
3. Valid legacy maps with the frozen table and runs the §4.4 migration, then returns the mapped mode.
4. Platform read exceptions propagate unchanged (existing behavior: controller falls back to `system` and records `lastError`).

### 4.4 Legacy compatibility bridge: migration and dual-write (exact)

**Migration (V2 absent, valid legacy present):**

| Legacy `app_theme_mode` | → V2 `app_theme_mode_v2` | Runtime mode |
|---|---|---|
| `system` | `system` | `TioThemeMode.system` |
| `light` | `light` | `TioThemeMode.light` |
| `dark` | `tio_dark` | `TioThemeMode.tioDark` |
| `oled` | `dark` | `TioThemeMode.dark` |

1. `setString('app_theme_mode_v2', <v2 value>)`.
2. On success: **do not delete** the legacy key. It already holds the equivalent old-meaning value and remains the rollback mirror.
3. On failure: swallow the error, **retain** the legacy key, return the mapped mode for this session (never a silent fallback to System), and retry the migration on the next `read()` (next launch). No user-facing error (no UX change in scope).

**New writes — `write(mode)`:**

| Runtime mode | V2 (canonical) | Legacy mirror (old meaning) |
|---|---|---|
| `system` | `system` | `system` |
| `light` | `light` | `light` |
| `dark` | `dark` | `oled` |
| `tioDark` | `tio_dark` | `dark` |

1. `setString('app_theme_mode_v2', <v2 value>)`. If this throws, the error propagates exactly as today (controller does not publish the selection; mirror is not attempted).
2. Only after step 1 succeeds: best-effort `setString('app_theme_mode', <legacy value>)`. A mirror failure is swallowed: the current selection succeeds, V2 stays canonical, current-app behavior is correct; only rollback compatibility may be degraded (a downgraded build would show the previous legacy value).

Invariants: the legacy mirror never determines behavior when a valid V2 exists; legacy strings keep their old meanings (never `tio_dark`, and `dark` in legacy always means navy); this bridge is not a fifth mode and not a per-user flag. A later, separately audited cleanup may remove the mirror once downgrade compatibility is no longer required — out of scope here.

### 4.5 `clear()` / reset rule (exact)

`clear()` removes **both** keys in this order: `app_theme_mode_v2` is removed **last**.

1. `remove('app_theme_mode')` (legacy mirror).
2. `remove('app_theme_mode_v2')` (canonical).

Errors propagate (controller `clear()` already awaits the preference before resetting state). Partial-failure analysis:

- Step 1 fails → nothing changed; V2 still wins; error surfaced. No stale resurrection.
- Step 1 succeeds, step 2 fails → V2 still present and wins (current selection preserved); only the rollback mirror is gone; error surfaced. No stale resurrection.
- Reverse order was rejected: removing V2 first and then failing on legacy would leave only the legacy key, which the next `read()` would migrate back — resurrecting the cleared selection.

On success `read()` returns `null` ⇒ `system`.

### 4.6 User-facing labels and copy (owner-frozen)

Order everywhere: System, Light, Dark, Tio Dark.

| Surface | System | Light | Dark | Tio Dark |
|---|---|---|---|---|
| App Preferences summary (`_themeModeLabel`) | `System` | `Light` | `Dark` | `Tio Dark` |
| `ThemeSettingsPage` segment label | `System` | `Light` | `Dark` | `Tio Dark` |
| Appearance sheet title | `System default` (unchanged) | `Light` (unchanged) | `Dark` | `Tio Dark` |
| Appearance sheet subtitle | unchanged | unchanged | `Pure black appearance` | `Tio's signature midnight navy theme` |
| Appearance sheet key | `theme-option-system` | `theme-option-light` | `theme-option-dark` | `theme-option-tio-dark` (`theme-option-oled` removed) |

Icons and component presentation remain unchanged: icons stay positional (slot 3 `dark_mode_*`, slot 4 `brightness_2_rounded` / `brightness_3_outlined`). Only the option list data changes in the sheet; `_ThemeOptionTile` presentation is untouched (#183).

### 4.7 Baseline visual contract

- Light, navy/slate and pure-black palettes: pixel-identical values (no `TioColors`/`TioShadows` edit).
- Explicit legacy selections render identical pixels after migration (light→Light, dark→Tio Dark, oled→Dark).
- Wear: identical pure-black rendering.
- Accepted visual deltas only: (a) System + OS dark renders pure-black instead of navy; (b) theme option titles/subtitles/labels per §4.6.

### Ownership and Data Flow

```text
Settings UI (labels) -> AppThemeController (unchanged) -> AppThemePreference (unchanged interface)
  -> SharedPreferencesAppThemePreference (canonical V2 + legacy migration + old-meaning legacy mirror) -> SharedPreferencesAsync
TioThemeConfig(mode) -> TioTheme._resolveColors/_resolveShadows -> TioColors/TioShadows (unchanged constants)
Wear: TioThemeConfig(mode: TioThemeMode.dark) -> TioColors.oled
```

### Alternative Rejected

- Reusing `app_theme_mode` with new meaning — rejected (frozen): legacy `dark` ≠ new `dark`.
- Keeping `TioThemeMode.oled` as a hidden 5th value — rejected: migration happens at the storage boundary; no runtime need.
- Rethrowing migration-write failure — rejected: controller would fall back to System and silently change the user's theme.
- Deleting the legacy key after migration (V2-only) — rejected by owner: a rollback/downgraded build would lose every migrated selection.
- Failing a selection when only the legacy mirror write fails — rejected: V2 is canonical; the mirror is best-effort compatibility.
- Palette constant rename (Option B) — rejected, §4.2.

### Failure and Accessibility States

- Corrupt V2/legacy → System (existing behavior). Migration write failure → migrated mode kept for the session, legacy retained, retried next launch. Legacy mirror write failure → selection still succeeds.
- Existing Appearance-sheet dismiss-on-failure behavior unchanged (separate pre-existing gap, not #213).
- Contrast: `tio_theme_accessibility_test` outline-contrast loop already covers all three palettes; high-contrast behavior unchanged.

## 5. Implementation Plan (allowlist)

### 5.1 Production (7)

- [x] `apps/core/lib/src/theme/tio_theme_config.dart`
- [x] `apps/core/lib/src/theme/tio_theme.dart`
- [x] `apps/app/lib/app/shared_preferences_app_theme_preference.dart`
- [x] `apps/features/settings/lib/src/presentation/pages/app_settings_page.dart`
- [x] `apps/features/settings/lib/src/presentation/pages/theme_settings_page.dart`
- [x] `apps/features/settings/lib/src/presentation/widgets/theme_selection_bottom_sheet.dart` (option list data only)
- [x] `apps/wear/lib/wear_app.dart`

### 5.2 Tests (14) — see inventory table in §2

- [x] `apps/app/test/app/shared_preferences_app_theme_preference_test.dart`
- [x] `apps/app/test/app/app_theme_controller_test.dart`
- [x] `apps/app/test/app/app_mode_router_test.dart`
- [x] `apps/app/test/app/meal_logging_modal_theme_test.dart`
- [x] `apps/app/test/app/tio_theme_accessibility_test.dart`
- [x] `apps/core/test/theme/context_accessors_contract_test.dart`
- [x] `apps/core/test/ui/components/tio_date_time_wheel_picker_test.dart`
- [x] `apps/core/test/ui/components/tio_selectable_card_test.dart`
- [x] `apps/features/nutrition/test/meal_diary/archived_meal_categories_test.dart`
- [x] `apps/features/nutrition/test/meal_diary/meal_categories_settings_test.dart`
- [x] `apps/features/nutrition/test/meal_diary/meal_diary_settings_shell_test.dart`
- [x] `apps/features/nutrition/test/meal_logging/meal_diary_add_food_flow_test.dart`
- [x] `apps/features/settings/test/presentation/theme_selection_bottom_sheet_test.dart`
- [x] `apps/features/settings/test/presentation/app_settings_page_test.dart`

### 5.3 Current docs (2)

- [x] `docs/screens/settings.md` — Theme Interaction: System/Light/Dark/Tio Dark; canonical `app_theme_mode_v2`, legacy migration, and `app_theme_mode` as temporary old-meaning rollback mirror.
- [x] `apps/core/lib/src/theme/README.md` — mode→palette resolution map (§4.1) and note that palette constant names are internal roles.

### Counts

| | Old estimate | Proposed exact |
|---|---|---|
| Production | ~9 | **7** (`tio_colors.dart`, `tio_shadows.dart` drop out under Option A) |
| Tests | ~10 | **14** |
| Current docs | ~6 | **2** |
| Total source/test/doc | ~25 | **23** (+ this brief = 24) |

Any file outside this allowlist requires recording a reason here before editing; a new product-visible trigger returns to the Owner Approval Gate.

## 6. Quality Review

### Required test coverage

- Four-mode semantics and exhaustive labels (sheet, compat page, summary).
- Palette mapping: `dark→TioColors.oled`, `tioDark→TioColors.dark`, `light→TioColors.light`, plus shadows.
- System + OS dark → `TioColors.oled` (pure-black); System + OS light → Light; never Tio Dark.

Persistence suite (`shared_preferences_app_theme_preference_test.dart`; failures injected via a fake `SharedPreferencesAsyncPlatform` that throws on a chosen key/operation):

- V1→V2 migration for each of `system/light/dark/oled`, asserting the exact raw V2 string (`system/light/tio_dark/dark`) and the returned runtime mode.
- Migration leaves the legacy compatibility value available and unchanged (raw legacy string still present after successful migration).
- V2 wins over conflicting legacy (e.g. V2 `dark` + legacy `dark` → `TioThemeMode.dark`; V2 `tio_dark` + legacy `oled` → `tioDark`); no writes on read.
- Corrupt V2 (with and without a valid legacy present) → `null`, legacy not consulted, no writes. Corrupt legacy (V2 absent) → `null`, no V2 written, legacy untouched.
- Migration write failure → mapped mode returned, legacy retained, V2 absent; next `read()` with a working store completes the migration.
- `write()` round-trip for all four modes with exact V2 strings.
- New Dark mirrors legacy `oled`; new Tio Dark mirrors legacy `dark`; System/Light mirror `system`/`light` (exact rollback-compatible mapping table, both directions: legacy→V2 on migration, V2→legacy on write).
- Legacy mirror-write failure does not fail a successful V2 selection (`write()` completes; V2 holds the new value; subsequent `read()` returns it).
- V2 write failure propagates and does not touch the legacy mirror.
- Legacy strings never carry new meanings: no write ever stores `tio_dark` in the legacy key.
- `clear()` removes both keys (both-present and legacy-only states); subsequent `read()` → `null`.
- `clear()` partial failures: legacy removal fails → error, both keys intact, `read()` returns prior V2 mode; V2 removal fails after legacy removal → error, `read()` still returns prior V2 mode (no stale legacy resurrection).

Theme/runtime and UI coverage:
- Wear pure-black preservation (`wear_home_hardening_test`, unchanged).

### Validation plan

```text
git diff --check
melos bootstrap && melos analyze
focused: flutter test <each §5.2 file> in its package; flutter test apps/wear/test
full: melos test
device QA (owner): upgrade over a build with each legacy value (system/light/dark/oled);
  confirm pixels for explicit choices unchanged, System+OS-dark now pure-black, Wear unchanged;
  downgrade back to the pre-change build after selecting Dark and Tio Dark: old build shows OLED / Dark palettes;
  Appearance sheet + /settings/theme + App Preferences summary labels at 390px and 320px@1.6x.
```

### Validation Run

Run 2026-09-22 on the uncommitted working tree over base `fec4e05` (Windows, Flutter/Dart SDK 3.12.2 from the local toolchain).

```text
dart format <changed Dart files>        -> applied; then formatter-only churn was reverted in the
                                           7 files that were already unformatted on main
                                           (app_mode_router_test, tio_date_time_wheel_picker_test,
                                           archived_meal_categories_test, meal_categories_settings_test,
                                           meal_diary_add_food_flow_test, app_settings_page,
                                           theme_selection_bottom_sheet) so only semantic hunks remain
                                           (keeps _ThemeOptionTile / #183 territory untouched)
git diff --check                        -> exit 0 (tracked); brief checked with --no-index: no errors

melos bootstrap / melos analyze / melos test -> NOT RUN AS MELOS: installed global melos 8.6.0
  cannot read this melos.yaml workspace (melos >=3 needs a root-pubspec install; CI pins 2.9.0,
  not in the local cache). Global tooling was not changed. Ran the exact per-package commands
  CI's melos exec runs instead, in all 16 workspace packages:
flutter pub get / dart pub get          -> exit 0 in all 16 packages
flutter analyze --no-pub / dart analyze -> "No issues found!" in all 16 packages

focused (14 allowlisted test files + Wear gate):
  apps/core     3 files                 -> +31  All tests passed
  apps/features/settings 2 files        -> +21  All tests passed
  apps/wear     wear_home_hardening_test -> +8  All tests passed (pure-black background under TioThemeMode.dark)
  apps/app      5 files                 -> +68  All tests passed
  apps/features/nutrition 4 files       -> +200 All tests passed

full suite (flutter test --no-pub / dart test, every package with test/):
  app +344 · wear +9 · shared +104 · core +303 · account_setup +38 · auth +159 · home +1 ·
  nutrition +872 · onboarding +450 · profile +68 · progress +51 · settings +236 ·
  splash +12 · workout +14  -> all exit 0, 2661 tests passed, 0 failures

side effects: `flutter pub get` regenerated apps/features/nutrition/pubspec.lock and
  apps/wear/.../GeneratedPluginRegistrant.java (stale on main); both restored to main after
  validation, not part of this slice.
not run: device/emulator acceptance (owner device QA gate); CI (no PR in this gate).
```

### Device QA evidence (owner physical phone)

Gate authorized 2026-09-22. Pre-QA check: branch/base `fec4e05` unchanged, #213 OPEN, TNYX-157 In Progress / Low / TNYX-118, 0 open PRs, working tree = reviewed implementation (no source drift).

Status legend: **OWNER OBSERVED** (owner saw it on a physical device) · **AUTOMATED ONLY** (widget/unit tests only) · **NOT RUN**. Automated coverage is never counted as physical QA.

| # | Check | Expected | Status | Evidence |
|---|---|---|---|---|
| 1a | Appearance options | System default / Light / Dark / Tio Dark; no OLED | **OWNER OBSERVED — PASS** | owner aggregate "PHYSICAL PHONE QA = PASS" (2026-09-22) |
| 1b | Subtitles | Dark `Pure black appearance`; Tio Dark `Tio's signature midnight navy theme` | **OWNER OBSERVED — PASS** (Appearance surface) | owner aggregate PASS |
| 1c | App Preferences summary | System / Light / Dark / Tio Dark | **OWNER OBSERVED — PASS** (Settings summary) | owner aggregate PASS |
| 2a | Light palette | existing Light | **OWNER OBSERVED — PASS** | owner aggregate PASS |
| 2b | Dark palette | pure-black (old OLED) | **OWNER OBSERVED — PASS** | owner aggregate PASS |
| 2c | Tio Dark palette | navy/slate (old Dark) | **OWNER OBSERVED — PASS** | owner aggregate PASS |
| 2d | No unrelated layout/spacing/typography/icon/motion change | unchanged | **OWNER OBSERVED — PASS** (normal phone theme behavior) | owner aggregate PASS; no per-surface detail provided |
| 3a | System + OS Light | Light | **OWNER OBSERVED — PASS** | owner aggregate PASS |
| 3b | System + OS Dark | pure-black Dark, never navy | **OWNER OBSERVED — PASS** | owner aggregate PASS |
| 4 | Restart persistence (Light / Dark / Tio Dark / System) | selection + palette survive full close/reopen | **OWNER OBSERVED — PASS** (item was in the owner's phone QA matrix) | owner aggregate PASS; per-mode detail not provided |
| 5 | `/settings/theme` compatibility page | System / Light / Dark / Tio Dark; no OLED | **OWNER OBSERVED — PASS** (item was in the owner's phone QA matrix) | owner aggregate PASS |
| 6 | Text scale / narrow width smoke | no overflow/clipping; subtitles readable; selected state correct | covered only by owner aggregate PASS; exact text scale / width **not provided** | matrix marked this "if practical" |
| 7a | legacy `system` → System | follow-OS | AUTOMATED ONLY | no old-build/legacy-state device evidence supplied |
| 7b | legacy `light` → Light | same Light | AUTOMATED ONLY | same |
| 7c | legacy `dark` → Tio Dark | same navy | AUTOMATED ONLY | same |
| 7d | legacy `oled` → Dark | same pure-black | AUTOMATED ONLY | same |
| 7e | legacy System + OS Dark | navy → pure-black (accepted) | AUTOMATED ONLY | same |
| 8 | Wear | pure-black under new Dark semantic | NOT RUN physically (AUTOMATED ONLY: `wear_home_hardening_test`) | no Wear device/emulator evidence supplied |
| 9 | Downgrade/re-upgrade | old build shows old OLED/Dark; V2 wins on re-upgrade | NOT RUN | not performed |

Device details: phone model **not provided**, OS version **not provided**, text scale **not provided**. Owner result is an aggregate PASS; no per-check claim beyond it is made.

### Review Findings and Resolution

| ID | Severity | Status | Finding | Observed at SHA | Evidence or follow-up |
|---|---|---|---|---|---|
| R1 | P3 | Deferred | `apps/core/test/theme/context_accessors_contract_test.dart:85-89` shadow assertions cannot distinguish the semantic mapping: `TioShadows.light/dark/oled` currently hold identical values (`tio_shadows.dart:21-34`), so a swapped shadow mapping would still pass. No runtime impact today. Owner accepted as a known non-blocking limitation; not fixed in this slice. | `fec4e05` + uncommitted tree | Bounded review 2026-09-22 (P1 0 / P2 0 / P3 1); follow-up only if shadow values ever diverge per mode |

### Risks

- Hidden navy-specific assertion in a test not caught by the audit grep → mitigated by full `melos test`; fix by the §2 matrix rewrite rule.
- Legacy System users on dark OS see navy→pure-black on upgrade — **accepted by owner**; mention in PR notes.
- In-flight branches using `TioThemeMode.oled` fail to compile after merge (loud, intended). Open PRs: 0 at audit time.
- Swallowed migration/mirror write failures are silent — acceptable for a retried, device-local preference; no UX change authorized.
- Downgrade → change theme in old build → re-upgrade: the old build writes only the legacy key, so the stale V2 wins on re-upgrade and the old-build change is not seen. Accepted consequence of "V2 always wins"; record in PR notes.
- The legacy mirror is temporary; its later removal needs a separate audited cleanup (and must not reuse legacy strings with new meanings).
- Shared file with #183 (`theme_selection_bottom_sheet.dart`): data-only edit; merge-order conflict possible if #183 lands first — rebase keeps both.

### Rollback / recovery

- Code rollback = revert the PR, or an app downgrade. The old build reads `app_theme_mode`, which the new build keeps populated with old-meaning values (retained on migration, mirrored on every successful selection). Result: new Dark → old OLED (same pure-black), new Tio Dark → old Dark (same navy), Light/System unchanged. The V2 key is ignored by the old build. Only a failed mirror write degrades this (old build shows the previous legacy value).
- No server/schema state involved; nothing to migrate back remotely.

## 7. Final Handoff

### Changed Files

Exactly the §5 allowlist (uncommitted, local branch `tnyx/tnyx-157-theme-semantics-migration`, base `fec4e05`) plus this brief:

- Production (7): `tio_theme_config.dart`, `tio_theme.dart`, `shared_preferences_app_theme_preference.dart`, `app_settings_page.dart`, `theme_settings_page.dart`, `theme_selection_bottom_sheet.dart` (option data only), `wear_app.dart`.
- Tests (14): the §5.2 list.
- Docs (2): `docs/screens/settings.md`, `apps/core/lib/src/theme/README.md`.

No file outside the allowlist changed. Not committed, not pushed, no PR.

### Actual Behavior

- `TioThemeMode { system, light, dark, tioDark }`; `oled` removed.
- `light→TioColors.light/TioShadows.light`; `dark→TioColors.oled/TioShadows.oled`; `tioDark→TioColors.dark/TioShadows.dark`; `system`: OS light → Light, OS dark → `TioColors.oled/TioShadows.oled`. Palette/shadow constants unchanged.
- Persistence: V2 `app_theme_mode_v2` canonical and always wins; corrupt V2 → `null` without consulting legacy or writing; V2 absent → legacy migrated (`system→system`, `light→light`, `dark→tio_dark`, `oled→dark`), legacy retained; V2 migration-write failure → mapped mode returned, legacy retained, retried next read; corrupt legacy → `null`, no writes.
- `write()`: V2 first (failure propagates, mirror untouched), then best-effort legacy mirror (`system→system`, `light→light`, `dark→oled`, `tioDark→dark`); mirror failure swallowed.
- `clear()`: legacy removed first, V2 last; errors propagate.
- Labels: summary/compat page `System/Light/Dark/Tio Dark`; sheet `System default/Light/Dark/Tio Dark`, subtitles Dark `Pure black appearance`, Tio Dark `Tio's signature midnight navy theme`; keys `theme-option-system/light/dark/tio-dark`. Icons/presentation unchanged.
- Wear: `TioThemeMode.dark` → same pure-black.

### Known Limitations

- Owner-accepted downgrade caveat: upgrade (V2 written) → downgrade → change theme in the old build (legacy only) → re-upgrade: the existing V2 wins and the old-build change is not picked up. No timestamp/version arbitration in this slice. Must be restated in PR evidence.
- Legacy System users on OS Dark change navy → pure-black after upgrade (owner-accepted).
- Legacy mirror is temporary; removal needs a separate audited cleanup.
- Pre-existing Appearance-sheet dismiss-on-persistence-failure behavior unchanged (not #213).
- `melos` itself could not run locally (see §6); equivalent per-package commands were run.
- Owner physical-phone QA: aggregate PASS (2026-09-22) for normal phone theme behavior (§6 Device QA evidence); device model/OS/text scale not provided. Legacy-upgrade rows are AUTOMATED ONLY; Wear physical QA and downgrade QA NOT RUN.
- R1 (P3, deferred): current shadow mapping assertions cannot distinguish modes because `TioShadows.light/dark/oled` values are identical.

### Publication evidence (2026-09-22)

- Commit: `71256c81b0bc5725925cf7e73a57c79059720010` `refactor(theme): replace OLED mode with Dark and add Tio Dark` (no AI attribution).
- Parent: `main` `fec4e0568f23e65c5d6bb444953f883314491a85`; ahead/behind 1/0; `git merge-base --is-ancestor origin/main HEAD` passed; `git log origin/main..HEAD` = this commit only; `git diff --name-only origin/main...HEAD` = the 24 approved files; `git diff --check origin/main...HEAD` clean. Staged diff hash matched the reviewed tree.
- Pushed: `origin/tnyx/tnyx-157-theme-semantics-migration` = `71256c8` (no force push).
- Draft PR: [#318](https://github.com/im-tnyx/tio-world/pull/318), base `main`, head `tnyx/tnyx-157-theme-semantics-migration`, 24 files, `Closes #213`. Mergeable; merge state `clean` once checks completed.
- CI on head `71256c8`: Analyze and test **pass**, Build Android debug APKs **pass**, Attribution guard runner **pass**, Commit attribution guard **pass**. `github-advanced-security` **failed for an external reason** — the Copilot code-scanning agent could not start a session (`Sessions disabled: not supported for code scanning yet`, then `CAPIError: 400 The requested model is not supported`); `code-scanning/alerts` returns `no analysis found`, so no code/security finding was produced. Branch protection lists only `Commit attribution guard` as a required check, so this failure is not required and no code change was made for it.
- PR review gate (2026-09-22): PR diff verified content-identical to the reviewed tree; P1 0 / P2 0 / P3 1 (R1 deferred); 0 reviews / 0 comments / 0 threads.
- Linear TNYX-157: In Progress → **In Review** after the Draft PR existed; PR #318 attached; priority Low / parent TNYX-118 unchanged (the GitHub link also auto-assigned the issue to santosh). GitHub #213 OPEN (closes only on merge).
- This publication-evidence block was added after the implementation commit and is synced to the branch by the follow-up commit `docs(ai): sync TNYX-157 publication handoff`; its CI lines describe head `71256c8`, and the sync commit re-runs the same workflows on the new head.

### Handoff gate

```text
[done] owner implementation authorization → TNYX-157 In Progress → §5 implemented → §6 automated validation
→ owner review + owner device QA (§6 plan, incl. upgrade from each legacy value and downgrade observation)
→ owner-authorized publication gate: commit / push / PR per docs/PUSH_TEMPLATE.md (not authorized yet)
→ CI on PR head → review/merge gate → then TNYX-157 Done / close #213 (not before)
```

### Final Status

`REVIEW` — implementation + automated validation complete; ready for owner review / device QA / publication gate. TNYX-157 stays In Progress; #213 stays OPEN.
