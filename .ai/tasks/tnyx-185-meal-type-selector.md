# TNYX-185 — N5C Shared MealLogActionFooter Meal Type selector activation

## 1. Predecessor gate — 2026-09-09

```text
PR #228            MERGED
merge SHA          250990c3478bd2ee8d6efd3a55588e35d8fb9636 (squash)
origin/main        250990c3
post-merge CI      Flutter CI success · Supabase Database CI success
unresolved threads 0
```

`Supabase Database CI` has no `push` trigger — it runs on `pull_request` and
`workflow_dispatch` only — so no post-merge run exists on its own. It was
dispatched on `main` to satisfy the gate honestly. This is not specific to
this merge: no migration has ever been validated on `main` after landing.

Hosted ledger, read-only: `20260908120000_cap_retained_meal_categories` is
**not applied**. `main` enforces the retained ceiling, the minimum-active rule
and the canonical order in Dart; the hosted database enforces none of them
yet. Not applied here — that needs its own owner authorization.

## 2. What main already provides

```text
MealCategoriesController          exported from meal_diary/presentation
mealCategoriesRepositoryProvider  apps/app/lib/app/network_providers.dart:266
MealLogActionFooter               meal_logging/presentation/widgets
QuickAddEditorSheet               its first and only consumer
MealCategory                      id · displayName · active · order
```

The footer's category control is already a `_FooterAction` with a label and a
chevron, inert because no callback is supplied. The shell does not need
rebuilding; it needs a source.

Dependency direction: a feature cannot import `apps/app`, so the repository
comes down through composition — the same route the router already uses for
`resolvedFirstDayOfWeek` and for both Meal Categories pages.

## 3. Ownership

```text
MealCategoriesRepository            app composition
      ↓
MealCategoriesController            feature, per editor session
      ↓ active items, in configured order
MealCategoryOption(id, label)       presentation-safe: no defaultKey, no active
      ↓
MealLogActionFooter                 owns the selector capability
      ↓ selected id
editor session draft
```

The footer owns the selector rather than each consumer, because the goal is
one shared capability the full Meal Editor and every future flow inherit.
Quick Add is the first consumer, not the owner.

`MealCategoryOption` carries an id and a label and nothing else, so no internal
identity can reach the screen even by accident.

## 4. Selector surface — a floating card, not a sheet

Owner-corrected on 2026-09-09. The first implementation used
`showTioEditorSheet`; that is not the direction.

```text
        ┌──────────────────────┐
        │ Breakfast            │
        │ Lunch             ✓  │
        │ Pre Workout          │
        └──────────────────────┘
        ─────────────────────────
        Meal type      Date / time     the footer, unmoved
        [      Log Meal        ]
```

The card floats over the editor body above the control. The footer keeps its
exact position and height, and the editor stays visible behind — asserted, not
assumed: opening the card leaves all three footer control rects identical.

`TioAnchoredPopup` is a new Core primitive holding the placement, the overlay
and the dismissal that any anchored card needs. It was extracted from the
geometry `TioDateTimePickerPopup` already proved, but that widget is left
untouched on owner instruction, so the two currently share a shape rather than
code. Retrofitting the date card onto the shell is a separate, opt-in change.

Sized to its content, capped well below the date card's width: this is a short
list of short names beside one control, not a band across the footer.
`IntrinsicWidth` gives every row the width of the longest label, so the list
does not read as ragged. Its own scroll when eight categories at a large text
scale need more room than the anchor left.

Options are `TioSelectableCard`, so the chosen one carries the component's fill
and outline, plus a tick for a reader who cannot rely on that difference alone.

No Done, Save or Apply: choosing is the whole interaction. A tap selects and
closes; a tap outside closes and changes nothing.

## 5. Initial selection

Audited: Quick Add has no existing selected-category contract, and nothing in
the session model names one. So there is nothing to preserve, and nothing is
invented — no `Breakfast` default, no clock-time inference. The control reads
`Select meal type` until the reader chooses.

## 6. Loading and failure

```text
loading   control disabled, reads `Meal type`
failed    control enabled; opening it shows the failure and Try again
ready     options
```

A failed read never falls back to the canonical four. A NULL stored config
resolving canonical defaults through the repository is a different thing and
stays valid.

## 7. Boundaries

```text
Log Meal            still has no callback — unchanged, honestly disabled
date/time           untouched; separate state, neither mutates the other
reminders           none, and none implied
MealLog persistence none
Supabase            no migration, no schema, no hosted mutation
TNYX-67 source      untouched
```

## 8. One card at a time

The two cards can never both be open. While either is up, its dismiss layer
covers the screen, so the other control cannot be reached until that tap has
closed the first one. Asserted in `the two cards can never be open at once`.

That is the existing date-card behaviour, kept deliberately: switching from one
to the other costs a tap to close and a tap to open. Making it a single tap
means letting the dismiss layer pass a tap through to the sibling control,
which is a change to `TioDateTimePickerPopup` — the widget the owner asked to
leave alone. Raised rather than decided.
