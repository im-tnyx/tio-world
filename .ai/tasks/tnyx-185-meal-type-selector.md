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

Options are plain menu rows, not `TioSelectableCard`. That component is a card
— its own outline, its own padding — and a column of them inside the popup's
card read as cards nested in a card, at roughly twice the height a line of text
needs. A menu's rows are rows: the chosen one is a soft fill and a tick, and
the surface around them belongs to the card. Selection is reported through
semantics as well, so it is never carried by colour alone.

The footer keeps the layout it had. The category control sits at its natural
width on the leading edge and the date stays on the trailing edge; a bound on
how wide the category may grow is what stops a long custom name overflowing the
row, rather than making it flexible — a flexible control shared the row evenly
with the date and pulled it off the trailing edge.

No Done, Save or Apply: choosing is the whole interaction. A tap selects and
closes; a tap outside closes and changes nothing.

## 5. Initial selection — a time-based suggestion

**Owner decision, 2026-09-09, reversing the earlier lock.** The brief and the
TNYX-185 prompt both said no clock inference and no invented default; the owner
has replaced that with a convenience suggestion. Recorded as a reversal rather
than quietly applied.

```text
04:00 – 10:59   breakfast
11:00 – 15:59   lunch
18:00 – 22:59   dinner
everything else snacks
```

Five rules make it a convenience rather than a restriction.

**The draft's own consumed time decides, never the device clock.** Someone
logging last night's dinner over breakfast has already said when they ate; the
editor follows that. This is also what makes late logging work — the case that
sank a plain clock-based guess.

**Canonical roles, never names.** The match is on `defaultKey`, so a reader who
renamed Lunch to `Midday Meal` still gets that category at 13:00. A custom
category is never suggested: `Pre Workout` could be 06:00 or 18:00, and reading
a schedule out of a name the reader invented would be guessing about their day.

**A stable id, like every other selection here.**

**The reader's choice always wins, and wins permanently.** Before they choose,
changing the time refreshes the suggestion. After they choose, nothing moves it
— including accepting the suggested one, which is an answer rather than
silence.

**Nothing is ever forced or refused.** Every active category stays one tap
away at every hour, and when the suggested canonical category is archived the
control simply reads `Select meal type` again rather than substituting
something else.

The gaps in the table are deliberate: late afternoon is nobody's lunch or
dinner and the small hours are nobody's dinner, so both fall to snacks instead
of stretching an anchor over time it does not own.

Nothing is stored on a `MealCategory` — the mapping is computed. TNYX-70 will
let the reader state their own meal times, and may improve or replace this
heuristic when it does; their answer beats ours.

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

## 8. Two switches, one card

Left is Meal Type, right is Date / time. Two independent controls, not a pair
of tabs: neither card is ever forced to be the open one. Pressing a control
whose card is showing closes it and opens nothing, and a tap away from both
closes without opening either.

They can never both be open, and moving between them costs **one** tap.

That took a change to the dismiss layer. A popup's barrier covers the screen so
a tap anywhere outside closes it — which also meant the tap never reached the
other control, so swapping cost two taps. `TioPopupDismissBarrier` now takes an
optional hole: the sibling control's rect is cut out of the barrier, so nothing
in the overlay is hit-testable there and the tap lands on the control beneath.

`TioDateTimePickerPopup` gained the same option. Additive and default-off, so
its behaviour for every other caller is exactly what it was. One further change
was unavoidable: the overlay was wrapped in a screen-wide `Material`, which
hit-tests as a solid sheet and swallowed the tap the hole exists to let
through. That `Material` now wraps the card instead. Nothing about the card's
appearance changes.

Raised before implementing, because the owner had asked for that widget to be
left alone; the owner then specified the one-tap behaviour in both directions,
which is what required it.

### Validation

```text
flutter analyze  core / nutrition / app     No issues found
flutter test     core 266 · nutrition 494 · app 305    all passed
git diff --check origin/main...HEAD         clean
```
