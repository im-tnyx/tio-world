# S0-B — Health & Goals / Daily Wellness readiness

## Status

**READY for S0-B1 Daily Wellness implementation.**

Default Glass Size remains a separate **NEEDS DECISION** item and does not block S0-B1.

This brief completes TNYX-128 as a GitHub-only readiness audit after explicit user authorization to substitute remote GitHub evidence for the unavailable local Windows worktree preflight. No Flutter implementation, Supabase mutation, schema change, PR, or tracker status mutation is part of this brief.

## Tracking anchors

- Parent: `TNYX-118` — S0 App Settings pre-implementation audit / IA / ownership readiness gate
- Active child: `TNYX-128` — S0-B Health & Goals / Daily Wellness edit-parity readiness & Glass Size ownership
- GitHub planning anchor: `#45` — common body, weight and wellness goal settings
- Related aggregate tracker: `TNYX-74` — Current Journey / Health & Goals cross-domain targets overview
- Nutrition Settings boundary: `TNYX-63`
- Nutrition Targets boundary: `TNYX-69`
- Profile health guardrail: GitHub `#157`

## Frozen repository baseline

Canonical GitHub `main` SHA:

```text
3af0ba0c665cd39a2a8ff2413b0195efcb93e44e
```

This is the merge result of S0-A (`#168`) and is the baseline used for this audit.

### Git preflight result

Local path `G:\projects\Tio-World` was not accessible from the execution runtime, so local `git status`, local `main`, `origin/main`, local branches/worktrees, and unrelated local dirty/untracked work could not be observed directly.

The user explicitly authorized a GitHub-only completion of this audit. Under that substitution:

- GitHub `main` matches the expected frozen SHA exactly.
- No open PR overlap was found at audit time.
- The isolated audit branch was created directly from the frozen `main` SHA.
- This brief is the only intended repository change on the audit branch.
- `main` remains untouched.

Audit branch:

```text
codex/settings-s0b-health-goals-readiness
```

## Remote source confirmation

The earlier architecture audit was rechecked against the current GitHub `main` baseline. No source evidence contradicted the frozen conclusions.

Relevant source boundaries include:

- `apps/features/settings/lib/src/presentation/pages/settings_page.dart`
- `apps/features/progress/lib/src/domain/wellness_targets.dart`
- `apps/features/progress/lib/src/data/supabase_wellness_targets_repository.dart`
- `apps/app/lib/app/network_providers.dart`
- `apps/features/progress/lib/src/domain/body_setup.dart`
- `apps/features/progress/lib/src/data/supabase_body_setup_repository.dart`
- `apps/features/profile/lib/src/domain/models/user_profile_data.dart`
- `apps/features/settings/lib/src/presentation/pages/profile_settings_page.dart`
- `apps/app/lib/app/profile/profile_settings_route.dart`
- `apps/core/lib/src/units/unit_preferences.dart`
- onboarding Step / Water / Sleep target presentation under `apps/features/onboarding/`
- applicable Progress / Profile / Settings tests
- `docs/MODULE_OWNERSHIP.md`

## Canonical owner matrix

| Concept | Canonical owner | Settings role |
| --- | --- | --- |
| Common Profile | `public.user_profiles` / Profile repository | edit owner-backed Profile fields only |
| Activity Level | Profile / `UserProfileData.activityLevel` | Profile-owned editor; optional deep-link from Health & Goals later |
| Current Weight | `public.body_weight_logs` / Body repository | append canonical history through post-onboarding Body command |
| Body Goal | `public.user_body_goals` / Body repository | requires dedicated post-onboarding command before S0-C |
| Step Goal | `public.user_wellness_targets.steps_target` | edit same Wellness owner |
| Water Goal | `public.user_wellness_targets.water_target_ml` | edit same Wellness owner |
| Sleep Goal | `public.user_wellness_targets.sleep_target_minutes` | edit same Wellness owner |
| Bedtime | `public.user_wellness_targets.bed_time` | edit same Wellness owner |
| Wake Time | `public.user_wellness_targets.wake_up_time` | edit same Wellness owner |
| Default Glass Size | unresolved hydration logging preference boundary | not a Wellness target; implementation deferred |
| Nutrition Profile | Nutrition-owned | remain in Nutrition Settings lane |
| Nutrition Targets | Nutrition-owned (`TNYX-69`) | remain outside generic Health & Goals |
| Current Journey | aggregate/read model (`TNYX-74`) | navigation + aggregation only, never target authority |

## Final Health & Goals IA recommendation

```text
Settings
├─ Profile Settings
├─ Health & Goals
│  ├─ Body & Weight
│  │  ├─ Current Weight
│  │  ├─ Body Goal
│  │  ├─ Target Weight
│  │  └─ Goal Pace
│  └─ Daily Wellness
│     ├─ Step Goal
│     ├─ Water Goal
│     ├─ Default Glass Size   [deferred ownership decision]
│     ├─ Sleep Goal
│     ├─ Bedtime
│     └─ Wake Time
├─ App Preferences
├─ Nutrition Settings
└─ Log Out
```

The IA may show Default Glass Size beside Water Goal because they are related hydration experiences, but that visual grouping must not make Glass Size part of `user_wellness_targets`.

## Daily Wellness read/write matrix

Canonical contract:

```text
public.user_wellness_targets
├─ steps_target
├─ water_target_ml
├─ sleep_target_minutes
├─ bed_time
└─ wake_up_time
```

| Setting | Domain representation | Read path | Write path | Null semantics | S0-B1 readiness |
| --- | --- | --- | --- | --- | --- |
| Step Goal | nullable integer steps | `WellnessTargetsRepository.read()` | `WellnessTargetsRepository.upsert(...)` | `null` = unknown/unset | READY |
| Water Goal | nullable integer canonical ml | same | same | `null` = unknown/unset | READY |
| Sleep Goal | nullable integer minutes | same | same | `null` = unknown/unset | READY |
| Bedtime | nullable minute-of-day / SQL `TIME` | same | same | `null` = unknown/unset | READY |
| Wake Time | nullable minute-of-day / SQL `TIME` | same | same | `null` = unknown/unset | READY |

### Read/write guardrails

- Settings must use the existing canonical Wellness repository/provider.
- Do not introduce a Settings-owned target repository or duplicate persistence.
- Missing canonical values must stay unknown/unset.
- Do not hydrate absent values with onboarding visual defaults and then persist them silently.
- Water remains canonical in `ml`; display conversion is presentation-only.
- Bedtime/Wake Time remain canonical local clock values through the existing minute-of-day/SQL `TIME` boundary.
- After a successful save, dependent canonical read state should be invalidated/refetched rather than trusting screen-local state as durable truth.

## S0-B1 readiness

The following fields can proceed independently through the existing canonical owner/read-write path:

```text
S0-B1 — Daily Wellness editor
- Step Goal       READY
- Water Goal      READY
- Sleep Goal      READY
- Bedtime         READY
- Wake Time       READY
```

**S0-B1 Daily Wellness = READY.**

## Default Glass Size

**Default Glass Size = NEEDS DECISION.**

Recommended semantic owner:

```text
hydration logging preference
```

It is explicitly **not**:

- the Daily Water Goal;
- `UnitPreferences.volumeUnit`;
- automatically a field on `user_wellness_targets`;
- a reason to block S0-B1.

Recommended semantic behavior:

```text
Water Goal = 3000 ml
Default Glass Size = 250 ml

change Glass Size -> 300 ml

Water Goal remains 3000 ml
future +1 glass action logs 300 ml
```

A future backend-neutral API should preserve semantic quantity, for example:

```text
logHydration(
  amountMl: resolvedDefaultGlassSizeMl,
  source: glass,
)
```

### Glass Size unresolved decisions

The audit intentionally does not invent answers for:

1. persistence location / repository boundary;
2. sync class: account-synced vs device-local;
3. default for existing users;
4. null/unset behavior;
5. allowed product range;
6. step size / presets vs arbitrary numeric entry;
7. migration requirement, if any.

Canonical semantic unit should be `ml` if/when persisted; `UnitPreferences.volumeUnit` should affect display/conversion only.

No `glass_size` / `glassSize` contract exists in the current repository baseline, so implementation must wait for this contract freeze.

## Body Goal post-onboarding command gap

Current Body ownership is correctly split between canonical weight history and active Body Goal state.

`BodyRepository.recordCurrentWeight(...)` is already a valid post-onboarding history command for Current Weight.

The repository does **not** expose an equivalent dedicated post-onboarding Body Goal mutation command. `saveBodySetup(...)` contains onboarding reconciliation behavior and must not be treated as a generic Settings Body Goal editor API.

Before S0-C, introduce/freeze a backend-neutral command with semantics equivalent to:

```text
setActiveBodyGoal(BodyGoalUpdate command)
```

Required behavior:

```text
same active direction
→ update allowed target/pace fields safely

changed direction
→ supersede old active goal
→ create new active goal

maintain / recomposition
→ Target Weight = null
→ Goal Pace = null

starting weight
→ derive from canonical BodyState/latestWeight
→ never fabricate a UI default
```

No schema change is implied by this gap.

## Profile Settings UnitPreferences parity gap

Canonical `UnitPreferences` independently owns:

```text
weight
height
distance
volume
```

Current Profile Settings presentation initializes local unit display state instead of hydrating Weight/Height display directly from canonical `UnitPreferences`.

Therefore:

**Profile Settings currently has a UnitPreferences display/edit parity gap.**

This should be fixed in a separate bounded parity slice. It is not part of S0-B1 and must not expand the Daily Wellness implementation scope.

## Activity Level ownership

`Activity Level` is a canonical Profile concern through `UserProfileData.activityLevel`.

Recommended first authority:

```text
Profile Settings → Activity Level
```

If Health & Goals later exposes Activity Level for discoverability, it should deep-link to the same Profile-owned editor/state rather than introduce a second owner.

GitHub `#157` remains the guardrail for active Profile health-condition schema/refactor work. Health Conditions are outside S0-B1.

## Current Journey classification

`TNYX-74` should remain:

```text
aggregate read model
+ cross-domain summaries
+ deep links to canonical owner editors
```

It must not become:

```text
CurrentJourneyTargets
current_journey_targets
or any new canonical target repository/table
```

Sequencing:

```text
owner-specific editors/read-write contracts
→ stable domain state
→ Current Journey aggregate
```

Therefore Current Journey follows S0-B1 and later owner-specific editor work.

## Nutrition ownership boundary

`TNYX-63` defines Nutrition Settings as a Nutrition-owned hub and keeps global Units app-owned.

`TNYX-69` owns the canonical Nutrition Targets editor for Calories, Protein, Carbs, Fat, Fiber, and dependent target representations.

Nutrition target concepts must not be moved into generic Health & Goals simply because Nutrition consumes Body/Wellness context.

Water remains Wellness-owned even when Nutrition calculations consume it.

## UI reuse findings

Existing onboarding target screens provide useful interaction/domain patterns but should not be transplanted wholesale into Settings.

Classification:

| Existing pattern | Recommendation |
| --- | --- |
| Step validation / target constraints | REUSE DOMAIN LOGIC |
| Step slider + exact numeric entry pattern | PROMOTE/SHARE where justified |
| Water conversion / formatting | REUSE existing unit APIs |
| Water onboarding screen wrapper | DO NOT REUSE wholesale |
| Sleep duration/schedule validation | REUSE DOMAIN LOGIC |
| Bedtime/Wake time picker behavior | reuse interaction primitives, Settings-specific wrapper |
| onboarding `TargetsScreenScaffold` | DO NOT REUSE for Settings |
| governed loading/error/button primitives | REUSE DIRECTLY |

Settings needs its own read/edit/save lifecycle while consuming the same canonical domain contracts.

## Documentation drift

`docs/MODULE_OWNERSHIP.md` contains stale ownership language that can imply Nutrition ownership of Water.

Current runtime contracts are more specific and authoritative:

```text
Water Goal → Wellness canonical owner
Nutrition → consumer where required
```

This documentation drift should be corrected in a separate documentation/governance cleanup or alongside a narrowly approved future change. It must not be used to justify duplicate Nutrition or Settings ownership.

## Exact implementation split

```text
S0-B1 — Daily Wellness editor
→ Step / Water / Sleep / Bedtime / Wake Time
→ existing WellnessTargetsRepository
→ READY

S0-B2 — Default Glass Size
→ hydration logging preference contract
→ only after owner/storage/sync/default/range freeze
→ NEEDS DECISION

S0-C — Body & Weight editor
→ Current Weight through existing history command
→ Body Goal only after dedicated post-onboarding command freeze

Profile parity follow-up
→ hydrate Weight/Height display from canonical UnitPreferences

Current Journey
→ later aggregate/read model after owner-specific editors are stable

Nutrition Settings / Nutrition Targets
→ continue through TNYX-63 / TNYX-69
```

## Proposed S0-B1 allowlist

Only the following areas should be eligible when S0-B1 implementation is explicitly authorized:

```text
apps/features/settings/
  bounded Health & Goals / Daily Wellness presentation and focused tests

apps/app/
  required route/composition/provider wiring and focused tests

apps/features/progress/
  consume existing Wellness contracts
  only narrowly required Wellness tests/fixes if implementation proves necessary

apps/core/
  existing governed reusable target/unit primitives only
  promotion of a reusable primitive only if clearly justified

.ai/tasks/
  this readiness brief / narrowly related execution notes
```

Existing canonical contracts should remain the authority:

```text
WellnessTargetsData
WellnessTargetsRepository
SupabaseWellnessTargetsRepository
wellnessTargetsRepositoryProvider
```

## Forbidden list

S0-B1 must not include:

- Default Glass Size persistence;
- `glass_size` / `glassSize` schema fields;
- new hydration preference repository without a frozen contract;
- Supabase DDL or migration;
- Supabase data mutation for this audit;
- Body Goal lifecycle implementation;
- changes to Body repository semantics;
- Profile Settings UnitPreferences parity implementation;
- UnitPreferences ownership changes;
- Activity Level ownership migration;
- Health Conditions / GitHub `#157` implementation;
- Nutrition Calories/Macros/Fiber or meal calorie goals;
- Current Journey persistence;
- `Start a new journey` flow;
- recalculate/optimize engine;
- onboarding redesign;
- broad visual redesign;
- duplicate Wellness/Nutrition/Body target stores.

## Validation plan for S0-B1

When S0-B1 implementation is separately authorized, validation should include:

1. focused unit tests for nullable `WellnessTargetsData` edit semantics;
2. repository tests proving reads/writes target only `user_wellness_targets` canonical fields;
3. Settings widget tests for loading, populated, null/unset, validation, error, and save states;
4. unit display tests proving Water canonical `ml` identity survives `ml/L ↔ fl oz` display changes;
5. Bedtime/Wake Time round-trip tests through minute-of-day / SQL `TIME` conversion;
6. regression test proving absent canonical values are not replaced/persisted by onboarding defaults;
7. app composition/provider tests confirming Settings uses the existing Wellness owner;
8. targeted Flutter analyze/test for touched packages;
9. broader relevant CI after focused tests pass;
10. real-device authenticated persistence acceptance: edit → save → navigate away/restart/refetch → same canonical values;
11. verify no Nutrition/Profile/Body target table receives duplicate Wellness writes;
12. verify App Mode changes do not erase common Wellness targets.

## Final readiness conclusion

```text
S0-B1 Daily Wellness = READY
Default Glass Size   = NEEDS DECISION
```

Overall `TNYX-128` should **not** be marked BLOCKED merely because Default Glass Size is deferred. S0-B1 has an independent, existing canonical Wellness owner/read-write path and can safely proceed as the next bounded implementation slice once implementation is explicitly authorized.
