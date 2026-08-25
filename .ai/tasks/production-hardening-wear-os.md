# Production Hardening — Wear OS

**Status:** In progress  
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
- Wear already depends on `tio_shared` but currently does not consume App Mode at all.
- Android manifest correctly declares `android.hardware.type.watch`.
- Existing Wear test only statically checks design-system literal ownership; there is no behavior test for App Mode, display shape, or theme.
- Existing `Android Native CI` watches/builds only `apps/app`; Wear Android changes neither trigger it nor compile the Wear APK.

### Reproducible findings

1. `WearHomeScreen.tiles` is a fixed mixed Workout + Nutrition menu. There is no App Mode injection boundary, despite the shared App Mode contract being the accepted cross-feature vocabulary.
2. Cross-device phone-watch sync is explicitly future scope. Therefore this slice must not pretend to synchronize state by copying the phone's device-local preference into the watch app. The correct bounded hardening is an App Mode-aware presentation/composition boundary that remains `null`/unfiltered until a real sync adapter exists.
3. Current Wear layout uses `SafeArea + ListView` with fixed horizontal padding only. No runtime signal or test handles circular display geometry, so content can sit inside clipped edge regions on round watches.
4. Android `Configuration.isScreenRound()` is available from the existing native `MainActivity`, but no Flutter boundary exposes it.
5. `TioWearApp` sets outer `ThemeData.dark()` and then wraps the Navigator child in default/system `TioTheme`. The inner theme wins for descendants, so the declared dark theme is not the actual canonical owner. Meanwhile the screen intentionally forces pure black physical background/tile colors. A deterministic OLED `TioTheme` matches that frozen visual contract and removes theme ambiguity.
6. Prior design-system Slice G intentionally froze `TioPalette.black`, `gray022`, and `gray036` exact Wear visuals. Do not replace those physical values with different semantic colors in this slice.
7. Native Wear hardening currently lacks a native compile gate because `.github/workflows/android-native-ci.yml` only triggers on/builds the phone app.

## 3. Decisions

| Decision | Status | Rationale |
|---|---|---|
| Add nullable `AppMode` injection at Wear composition/presentation boundary | Made | prepares canonical mode-aware UI without fabricating cross-device sync |
| Preserve current mixed menu when App Mode is unavailable | Made | current runtime/product baseline remains unchanged until real sync exists |
| Filter mode-specific placeholder tiles via shared `AppDestination` eligibility | Made | reuse canonical mode vocabulary instead of another local mode switch |
| Expose `Configuration.isScreenRound()` over a minimal MethodChannel | Made | accurate platform shape signal without a new plugin dependency |
| Use inscribed-square geometry for round horizontal safe inset | Made | mathematically keeps rectangular list content inside a circular display |
| Use canonical OLED `TioTheme` as Wear runtime theme | Made | matches pure-black frozen watch visual baseline and removes outer/inner theme conflict |
| Keep exact physical Wear tile colors | Made | accepted design-system visual freeze |
| Extend Android Native CI to compile both phone and Wear debug APKs and trigger on Wear native/runtime changes | Made | exact-SHA native validation must cover the native code changed by this slice |

## 4. Scope

- `apps/wear/lib/main.dart`
- `apps/wear/lib/wear_app.dart`
- `apps/wear/lib/src/device/wear_display_shape.dart` (new)
- `apps/wear/lib/src/home/presentation/model/wear_home_tile.dart`
- `apps/wear/lib/src/home/presentation/wear_home_screen.dart`
- `apps/wear/android/app/src/main/java/com/tnyx/wear/MainActivity.java`
- focused Wear behavior tests
- `.github/workflows/android-native-ci.yml` only as required to compile Wear native/runtime changes

## 5. Non-Goals

- no Google Data Layer / phone-watch message transport;
- no Supabase/Auth/watch storage work;
- no live workout or nutrition workflow implementation;
- no Apple Watch work;
- no placeholder copy/action redesign;
- no new design token catalog;
- no change to phone App Mode persistence;
- no CI platform/toolchain redesign beyond adding Wear to the existing Android native gate.

## 6. Implementation Plan

- [ ] add accurate Wear display-shape platform boundary;
- [ ] initialize display shape before composing Wear app;
- [ ] add nullable canonical App Mode injection boundary;
- [ ] make current placeholder tiles mode-eligible through shared destination vocabulary while preserving all tiles when mode is unavailable;
- [ ] add round-safe horizontal inset and rectangular baseline preservation;
- [ ] make OLED `TioTheme` the deterministic Wear theme owner;
- [ ] add focused App Mode / round layout / theme regressions;
- [ ] extend existing Android Native CI to resolve/build Wear debug APK as well as phone app;
- [ ] run full exact-SHA Flutter/Dart + Android CI;
- [ ] freeze accepted checkpoint in #5.

## 7. Quality Review

Pending.

## 8. Final Handoff

Pending.
