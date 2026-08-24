# #5 Production hardening — startup binding + single hydration owner

Status: ACTIVE

## Audit checkpoint

Current PR head audited:

```text
68fe50c1f18b8bc18390f7f62fa954800863aa0d
```

Reproducible findings:

1. `apps/app/lib/main.dart` performs Supabase/plugin-backed initialization before `WidgetsFlutterBinding.ensureInitialized()`.
2. `bootstrap()` currently owns binding + `SystemChrome`, so binding happens too late for pre-bootstrap async/plugin work.
3. `main()` already awaits App Mode, Onboarding Status, and Theme controller hydration.
4. `AppThemeBootstrap` and `AppModeBootstrap` then call `load()` again post-frame, creating a second hydration owner.
5. `OnboardingStatusController.load()` reads `AppModeController.selectedMode`, so Onboarding Status is not independent of App Mode and must remain ordered after App Mode hydration.

## Bounded implementation

- make `WidgetsFlutterBinding.ensureInitialized()` the first statement in `main()`;
- apply edge-to-edge `SystemChrome` only after binding initialization;
- reduce `bootstrap()` to app launch / `runApp()` responsibility;
- keep startup hydration owned by `main()` only;
- hydrate independent App Mode + Theme controllers together;
- hydrate Onboarding Status only after App Mode completes;
- remove post-frame duplicate App Mode / Theme hydration and obsolete bootstrap wrappers after zero-reference verification;
- add focused regression coverage for single-read hydration / dependency ordering where practical.

## Guardrails

- no Supabase schema/migration change;
- no canonical owner-map change;
- no auth-provider change;
- no onboarding flow/order change;
- no routing redesign;
- no visual redesign;
- do not execute stale #5 canonical-table recommendations; #44/O11 owner map is authoritative;
- PR #50 remains Draft/open/unmerged; Ready/merge requires explicit user authorization.

## Acceptance

- [ ] binding initialized before any async/plugin initialization;
- [ ] `SystemChrome` runs after binding;
- [ ] exactly one startup hydration owner for App Mode and Theme;
- [ ] Onboarding Status hydrates after App Mode because it consumes selected mode;
- [ ] no post-frame duplicate `load()` calls remain;
- [ ] focused tests green;
- [ ] full Flutter/Dart analyze + tests green;
- [ ] Android native CI green on exact final SHA.
