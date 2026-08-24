# Body Goal Follow-up Refinement

**Status:** ACTIVE — #113 execution
**Scope:** Goal vocabulary/selection + Target Weight/Goal Pace follow-up semantics
**PR:** #50 remains Draft/open/unmerged

## Product/UI contract

Keep the existing Tio Goal screen presentation: onboarding chrome, large rounded icon cards, selected border/check treatment, spacing and theme tokens.

Visible goal vocabulary:

```text
Lose Weight
Gain Weight
Maintain Weight
Build Muscle
Boost Strength
Improve Endurance
Keep Fit
```

Underlying legacy enum/storage names may remain stable where renaming would break draft compatibility (`getStronger` renders as Boost Strength; `stayFit` renders as Keep Fit). `recomposition` remains decode-compatible but is no longer a visible active card.

Mode visibility:

```text
Nutrition: Lose Weight, Gain Weight, Maintain Weight
Workout:   all 7
Hybrid:    all 7
```

Selection policy:
- weight-state goals Lose/Gain/Maintain: max 1;
- training goals Build/Strength/Endurance/Fit: max 2;
- Body and Workout selections remain independently mappable;
- Workout/Hybrid can therefore hold one Body goal plus up to two training goals;
- mode reconciliation must not fabricate hidden goals.

## Canonical audit correction for follow-ups

The live canonical Body contract has `user_body_goals_nondirectional_followups_null`, so `maintain_weight`/`recomposition` cannot persist Target Weight or weekly pace. No schema mutation is authorized in #113.

Therefore the executable no-schema rule is:

```text
Explicit Maintain Weight selected -> hide Target Weight + Goal Pace
Lose Weight                       -> show both, explicit loss direction
Gain Weight                       -> show both, explicit gain direction
Training-only selection           -> show both; target answer derives direction
Body Lose/Gain + training         -> show both; explicit Body direction wins
```

Training labels never imply Body direction. For a training-only path, comparing the user's actual target weight to current weight establishes the Body direction:
- target < current -> loss;
- target > current -> gain;
- target == current -> no direction; Target Weight step stays invalid until a non-zero target change is chosen because Goal Pace would otherwise be meaningless.

When training-only Target Weight establishes loss/gain, canonical Body persistence may store that direction as the active Body goal with `intentRank = null` to indicate it came from the explicit Target Weight answer rather than a Goal card. This does not infer direction from Build Muscle/Strength/Endurance/Fit.

## Goal Pace info UX

Add a Body-owned `How goal pace works` info affordance covering weekly target-weight change, target-date projection, sustainable ranges and warnings. Do not restore calorie/BMR/TDEE ownership into Body Goal. Keep the existing aggressive-pace Attention sheet separate.

## Guardrails

- no Supabase migration or constraint change;
- no fake loss/gain from training labels, BMI, defaults or calorie logic;
- Target Weight + Goal Pace remain paired;
- Maintain Body goal remains non-directional;
- canonical Workout target cardinality remains primary + supporting;
- existing Tio Goal card visual style remains.

## Acceptance

- [ ] 7-card visible vocabulary/mode matrix
- [ ] max 1 weight-state + max 2 training selections
- [ ] tertiary draft selection round-trips without breaking older snapshots
- [ ] Maintain selected hides both Body follow-ups
- [ ] training-only shows both and derives direction only from actual Target Weight
- [ ] zero-delta Target Weight explicitly blocked on training-only follow-up path
- [ ] Body/Workout canonical mappers remain independent and lossless
- [ ] Nutrition recommendation consumes effective target direction when active
- [ ] Goal Pace info sheet is Body-owned
- [ ] focused tests + full Flutter/Dart + Android CI green on one exact source SHA
