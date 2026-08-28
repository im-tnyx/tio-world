# Production Hardening — Welcome / Home Architecture

**Status:** Complete / Frozen — no production defect reproduced
**Primary owner:** Welcome feature + Home feature + app shell composition
**Tracking:** production hardening #5 item 20

## Global UI / Design-System Guardrail

No Welcome or Home redesign is authorized. Preserve the current Welcome hero and the intentionally empty Home feature baseline. Do not restore the old Welcome Terms/Privacy footer and do not invent dashboard UI under a hardening task.

## 1. Discovery

### User Outcome

Keep Welcome and Home ownership explicit and production-safe without reviving removed UI or fabricating Home product behavior that has not been designed/authorized.

### Success Criteria

- verify the old Welcome Terms/Privacy footer and its dead state are absent on current head;
- verify Welcome rendering/action/navigation ownership is bounded;
- verify Home shell routing delegates to the Home feature rather than implementing a dashboard in the router;
- verify the empty Home surface is intentional and regression-protected;
- change production source only if a current reproducible architecture defect exists.

### Non-Goals

- no Welcome visual/copy redesign;
- no Terms/Privacy footer restoration;
- no Home dashboard/product implementation;
- no shell/navigation redesign;
- no auth/onboarding flow change;
- no Supabase/schema/persistence work;
- no generic deletion of empty architecture directories without a concrete runtime need.

## 2. Codebase Exploration

Fresh audit head:

```text
044e7ee1bbd74b6d73bc6f663611146a4491f196
```

### Welcome findings

Current `apps/features/welcome/lib/src/presentation/widgets/` contains only:

```text
welcome_backdrop.dart
welcome_feature_tile.dart
welcome_top_bar.dart
```

Historical `welcome_disclaimer.dart` is already absent.

Current `WelcomeUiState` contains only:

```text
localeCode
skipText
featureLines
ctaText
```

Historical `termsPrefix`, `termsText`, `andText`, and `privacyText` fields are already absent.

`WelcomeScreen` imports no disclaimer/legal widget and renders the accepted hero, feature panel, Get Started action and Log In link. The old Terms/Privacy footer is not rendered.

`WelcomeRoute` owns route-level action handling:

```text
Get Started → App Mode setup
Log In      → Login
Skip        → Login
```

`WelcomeScreen` remains render/action-emission only. `WelcomeViewModel` owns the immutable UI state but has no external data/auth/database side effects.

The empty Welcome `data/domain/navigation` scaffolding contains no runtime implementation and does not create a current ownership violation. Removing empty folders is not justified as production hardening by itself.

### Home findings

Current `HomePage` is intentionally:

```dart
return const SizedBox.expand(
  key: ValueKey('home-page'),
);
```

The accepted design-system task already records that Home has no product-visible visual contract and explicitly rejected a fake Home token/UI migration.

App shell composition delegates the Home branch to the feature:

```dart
if (branch.tab == ShellTab.home) {
  return const HomePage();
}
```

The router therefore does not own Home dashboard rendering.

## 3. Existing Regression Evidence

Current tests already lock the relevant boundaries:

- `apps/app/test/app/welcome_accessibility_test.dart`
  - accepted Welcome visual/accessibility baseline;
  - reduced-motion behavior;
  - explicitly verifies legal/footer copy is omitted.
- `apps/features/home/test/presentation/home_page_test.dart`
  - explicitly verifies `HomePage` stays visually empty.
- `apps/app/test/app/app_mode_router_test.dart`
  - verifies hidden-mode branch redirect resolves to Home;
  - verifies a real `HomePage` is composed by the router/shell path.

No missing focused regression was found that would justify another production/test change.

## 4. Architecture Decision

```text
App Router / Shell
   ├─ auth path → WelcomeRoute
   │               └─ WelcomeScreen + WelcomeUiState
   └─ Home branch → HomePage feature stub
```

This is sufficient for the current product state. Future Home dashboard work requires its own product/design/domain slice and must not be inferred from #5.

## 5. Implementation

No production or test source change is required.

Historical Welcome dead-code cleanup is already present on current head, while Home emptiness is an intentional, tested baseline. Broad refactoring would create work without a reproduced defect.

## 6. Quality Review

Acceptance requires full Flutter/Dart + Android CI on this audit-only task commit before tracker freeze. CI evidence is recorded in #5 so this file does not require a second documentation-only SHA after acceptance.

## 7. Final Handoff

### Actual Behavior

- Welcome remains visually unchanged and contains no old Terms/Privacy footer.
- Welcome navigation stays route-owned.
- Home remains an intentionally empty feature surface.
- Router delegates the Home shell branch to `HomePage`.
- No dashboard, Supabase, auth, onboarding, routing, or UI redesign was introduced.

### Final Status

`COMPLETE / FROZEN — NO LONGER REPRODUCIBLE`
