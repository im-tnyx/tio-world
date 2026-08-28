# #5 Production hardening — startup binding + single hydration owner

Status: ✅ COMPLETE / FROZEN

## Audit checkpoint

Initial audited PR head:

```text
68fe50c1f18b8bc18390f7f62fa954800863aa0d
```

Reproduced findings:

1. `apps/app/lib/main.dart` performed Supabase/plugin-backed initialization before `WidgetsFlutterBinding.ensureInitialized()`.
2. `bootstrap()` owned binding + `SystemChrome`, so binding happened too late for pre-bootstrap async/plugin work.
3. `main()` already awaited App Mode, Onboarding Status, and Theme controller hydration.
4. `AppThemeBootstrap` and `AppModeBootstrap` then called `load()` again post-frame, creating a second hydration owner.
5. `OnboardingStatusController.load()` reads `AppModeController.selectedMode`, so Onboarding Status must remain ordered after App Mode hydration.

## Accepted implementation

- `WidgetsFlutterBinding.ensureInitialized()` is now the first statement in `main()`.
- Edge-to-edge `SystemChrome` is applied only after binding initialization.
- `bootstrap()` is now `runApp()`-only.
- Startup controller hydration has one owner: `main()` via `hydrateStartupControllers()`.
- App Mode + Theme reads start together.
- Onboarding Status starts after App Mode finishes, while a slower Theme read may continue concurrently.
- obsolete App Mode / Theme post-frame bootstrap wrappers and exports were removed.
- focused regression coverage proves dependency ordering and one read per controller across repeated hydration calls.

## Exact accepted source/test checkpoint

```text
b4470e729def5caae6d72308680ae17ba04fc0be
Flutter CI #1833 / run 32751847135 ✅
Android Native CI #245 / run 32751846592 ✅

Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
Android debug APK/native compile ✅
```

An intermediate head failed only on an `unnecessary_import` analyzer lint; the redundant import was removed without changing runtime behavior before this accepted checkpoint.

## Guardrails preserved

- no Supabase schema/migration change;
- no canonical owner-map change;
- no auth-provider change;
- no onboarding flow/order change;
- no routing redesign;
- no visual redesign;
- stale #5 canonical-table recommendations were not executed; #44/O11 owner map remains authoritative;
- PR #50 remains Draft/open/unmerged; Ready/merge requires explicit user authorization.

## Acceptance

- [x] binding initialized before any async/plugin initialization;
- [x] `SystemChrome` runs after binding;
- [x] exactly one startup hydration owner for App Mode and Theme;
- [x] Onboarding Status hydrates after App Mode because it consumes selected mode;
- [x] no post-frame duplicate `load()` calls remain;
- [x] focused startup-order/single-read test green;
- [x] full Flutter/Dart analyze + tests green;
- [x] Android native CI green on exact final SHA.
