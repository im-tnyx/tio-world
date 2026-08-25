# Production Hardening — Wear OS

**Status:** Complete / Frozen  
**Primary owner:** `apps/wear` watch composition + `apps/shared` App Mode vocabulary  
**Tracking:** production hardening #5 item 22

## Global Guardrail

Wear remains a watch-first Flutter surface. Do not reuse phone screens, add live phone-watch transport, invent backend sync, or redesign the current placeholder menu in this slice. Preserve current labels/actions and exact black/gray visual baseline except for intentional round-display safe-area hardening.

## 1. Discovery

### User Outcome

The existing Wear companion should have a safe architecture boundary for canonical App Mode, correctly protect content from round-screen edge clipping, and have one deterministic watch theme owner while preserving the current placeholder product scope.

### Success Criteria

- Wear presentation can consume the shared canonical `AppMode` vocabulary without duplicating mode enum/switch ownership;
- current runtime remains backward-compatible while phone-watch App Mode transport is still a future feature;
- round Wear OS devices use a real platform shape signal and apply geometry-safe horizontal content inset;
- non-round devices preserve current `TioSpacing.md` horizontal padding;
- watch rendering uses deterministic canonical OLED theme ownership rather than contradictory outer dark + inner system themes;
- current placeholder copy/actions and exact black/gray tile colors remain unchanged;
- Wear Android native code is compiled in CI rather than relying only on phone APK validation;
- focused Wear regressions + full Flutter/Dart + Android exact-SHA CI are green.

## 2. Fresh Current-Head Audit

Audit head:

```text
8aa68ce793ca950be2710b66214b18ccde8ccb2a
```

### Verified architecture

- `apps/wear` is the active Flutter Wear OS package; README explicitly says not to replace it with native Kotlin.
- Current product scope is a placeholder Samsung-style action list; detailed watch flows and phone-watch sync are future work.
- `apps/shared` already owns canonical `AppMode`, `AppDestination`, and `AppMode.watchCards` vocabulary.
- Wear already depends on `tio_shared` but did not consume App Mode at all.
- Android manifest correctly declares `android.hardware.type.watch`.
- Existing Wear test only statically checked design-system literal ownership; there was no behavior test for App Mode, display shape, or theme.
- Existing `Android Native CI` watched/built only `apps/app`; Wear Android changes neither triggered it nor compiled the Wear APK.

### Reproducible findings

1. `WearHomeScreen.tiles` was a fixed mixed Workout + Nutrition menu with no App Mode injection boundary despite the accepted shared App Mode vocabulary.
2. Cross-device phone-watch sync is explicitly future scope. Therefore this slice must not pretend to synchronize state by copying the phone's device-local preference into the watch app.
3. Current Wear layout used `SafeArea + ListView` with fixed horizontal padding only. No runtime signal or test handled circular display geometry.
4. Android `Configuration.isScreenRound()` was available from the existing native `MainActivity`, but no Flutter boundary exposed it.
5. `TioWearApp` set outer `ThemeData.dark()` and then wrapped the Navigator child in default/system `TioTheme`, creating ambiguous theme ownership while the screen intentionally used a pure-black physical baseline.
6. Prior design-system Slice G intentionally froze `TioPalette.black`, `gray022`, and `gray036` exact Wear visuals.
7. Native Wear hardening lacked a native compile gate because `.github/workflows/android-native-ci.yml` only triggered on/built the phone app.

## 3. Decisions

| Decision | Status | Rationale |
|---|---|---|
| Add nullable `AppMode` injection at Wear composition/presentation boundary | Made | prepares canonical mode-aware UI without fabricating cross-device sync |
| Preserve current mixed menu when App Mode is unavailable | Made | current runtime/product baseline remains unchanged until real sync exists |
| Filter mode-specific placeholder tiles via shared `AppDestination` eligibility | Made | reuse canonical mode vocabulary instead of another local mode enum/switch |
| Expose `Configuration.isScreenRound()` over a minimal MethodChannel | Made | accurate platform shape signal without a new plugin dependency |
| Use inscribed-square geometry for round horizontal safe inset | Made | keeps rectangular list content inside circular-display safe geometry |
| Use canonical OLED `TioTheme` as Wear runtime theme | Made | matches pure-black frozen watch visual baseline and removes theme ambiguity |
| Keep exact physical Wear tile colors | Made | preserves accepted design-system visual freeze |
| Extend Android Native CI to compile both phone and Wear debug APKs and trigger on Wear native/runtime changes | Made | exact-SHA native validation must cover native code changed by this slice |

## 4. Implemented Scope

Production / composition:
- `apps/wear/lib/main.dart`
- `apps/wear/lib/wear_app.dart`
- `apps/wear/lib/src/device/wear_display_shape.dart`
- `apps/wear/lib/src/home/presentation/model/wear_home_tile.dart`
- `apps/wear/lib/src/home/presentation/wear_home_screen.dart`
- `apps/wear/android/app/src/main/java/com/tnyx/wear/MainActivity.java`

Validation:
- `apps/wear/test/wear_home_hardening_test.dart`
- existing `apps/wear/test/wear_design_system_ownership_test.dart`
- `.github/workflows/android-native-ci.yml` now resolves/builds both phone and Wear debug APKs and triggers for Wear native/runtime paths.

## 5. Non-Goals Preserved

- no Google Data Layer / phone-watch message transport;
- no Supabase/Auth/watch storage work;
- no live workout or nutrition workflow implementation;
- no Apple Watch work;
- no placeholder copy/action redesign;
- no new design token catalog;
- no change to phone App Mode persistence;
- no CI platform/toolchain redesign beyond adding Wear to the existing Android native gate.

## 6. Completed Implementation

- [x] added accurate Wear display-shape platform boundary;
- [x] initialized display shape before composing Wear app;
- [x] added nullable canonical App Mode injection boundary;
- [x] made current placeholder tiles mode-eligible through shared destination vocabulary while preserving all seven tiles when mode is unavailable;
- [x] added round-safe horizontal inset and rectangular baseline preservation;
- [x] made OLED `TioTheme` the deterministic Wear theme owner;
- [x] added focused App Mode / round layout / theme regressions;
- [x] extended existing Android Native CI to resolve/build Wear debug APK as well as phone app;
- [x] ran full exact-SHA Flutter/Dart + Android validation;
- [x] froze accepted checkpoint in #5.

## 7. Quality Review

Accepted runtime/source-test checkpoint:

```text
fbce90673873723968e73b3e3f75056171842252
```

Exact-SHA validation:

```text
Flutter CI #1995 / run 32848817091 ✅
  Flutter analyze ✅
  Dart analyze    ✅
  Flutter tests   ✅
  Dart tests      ✅

Android Native CI #407 / run 32848817097 ✅
  Phone Android debug APK ✅
  Wear Android debug APK  ✅
```

Focused regression coverage proves:
- missing App Mode preserves the existing seven-tile mixed placeholder menu;
- Workout mode removes Nutrition-only placeholders;
- Nutrition mode removes Workout-only placeholders;
- Hybrid mode retains both current lanes;
- rectangular display keeps existing `TioSpacing.md` horizontal inset;
- round display uses the computed inscribed-square safe inset and applies it to the action list;
- Wear descendants receive the canonical OLED Tio theme with pure-black background ownership.

Compare audit from `8aa68ce793ca950be2710b66214b18ccde8ccb2a` to accepted runtime SHA showed only the bounded Item 22 task brief, Wear runtime/native/test files, and the existing Android CI gate update.

## 8. Final Handoff

**Complete / Frozen.**

The runtime acceptance SHA remains `fbce90673873723968e73b3e3f75056171842252`. Any later documentation-only closeout commit does not replace that accepted runtime/source-test checkpoint.

Future phone-watch App Mode transport remains intentionally deferred until a real sync adapter is designed; this slice only provides the canonical nullable injection boundary. Detailed live workout/nutrition watch flows remain future product work.
