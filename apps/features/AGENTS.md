# Feature Package Agent Rules

Applies to all Flutter feature packages under `apps/features/*`.

## UI Workflow

Before editing production UI in a feature package:

1. Read `apps/core/lib/src/theme/README.md` first.
2. Import the public core boundary with `package:tio_core/core.dart` unless the package already has an equivalent public import.
3. Prefer reusable core components (`TioButton`, `TioInput`, `TioCard`, `TioAvatar`, shared dialogs/pickers/sheets) before rebuilding the same UI locally.
4. Use the theme README as the normal lookup for spacing, radius, size, typography, color, motion, elevation, shadow, and component ownership.
5. Open internal `apps/core/lib/src/theme/tokens/**` files only when the README does not answer the question, a reusable role appears to be missing, or the task intentionally changes a core design-system contract.

## Feature Boundary

- Screens/widgets render state and emit actions. Keep business decisions in controllers/notifiers/use cases/domain helpers.
- Keep backend, persistence, database, entitlement, and AI-provider assumptions out of presentation widgets.
- Do not create feature-local token/theme/color/layout catalogs to hide visual values.
- For a true one-off composition, consume governed core primitives/semantic roles directly rather than creating a feature token bag.
- If a pattern is reusable across features, move the reusable contract/component to `apps/core` instead of duplicating it.

## Visual Safety

- Preserve current rendered UI unless the active task explicitly approves a visual change.
- Do not replace an exact value with a nearby token merely because the number is similar.
- Use runtime theme values (`context.tioColors`, `context.tioMotion`, `context.tioShadows`, `Theme.of(context).textTheme`) where the README says the value is runtime/theme-dependent.
- Use canonical static tokens (`TioSpacing`, `TioRadius`, `TioSize`, `TioStroke`, `TioElevation`, typography registries) where the README says the value is static.

Create a package-local `AGENTS.md` only when that feature has genuinely unique product/domain rules. Do not duplicate these shared UI rules inside every feature package.
