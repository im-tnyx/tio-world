# Ownership Rules

Use root docs and feature-local docs as the canonical ownership reference.

## Profile

Profile is not the owner of every account-related business domain.

Profile is a Fitness Hub + Account Launcher.

Profile may show:

- User identity summary
- Current plan summary
- Journey card as launcher only
- Progress photos card as launcher only
- Quick actions
- Rewards shortcut
- Resources shortcut
- Settings shortcut

Profile must not own another feature's business logic.

## Progress

Progress owns:

- Journey
- Progress photos
- Measurements
- Weight
- Achievements
- Progress analytics

Profile only launches these screens.

## Nutrition

Nutrition owns:

- Nutrition targets
- Calories
- Macros
- Meal logging
- Water goal
- Glass size
- Food search / meal editor when implemented

Nutrition does not own steps, sleep, or HRV.

## Workout

Workout owns:

- Workout plans
- Exercise selection
- Active workout session
- Sets, reps, weight, RPE
- Rest timer
- Plate calculator
- Previous workout values
- Workout history

Wear OS may provide a lightweight workout companion UI, but core workout ownership stays in Workout.

## Coach

Coach owns:

- AI coaching conversations
- Recommendations
- Insight summaries
- Recovery/nutrition/workout guidance orchestration

Coach can consume Workout, Nutrition, Progress, and Health summaries through public contracts. It should not take ownership of those domains.

## Health

Health is a future integration domain.

Health owns:

- Health Connect
- Samsung Health
- Apple Health
- Garmin
- Fitbit
- Heart rate import/sync contracts
- Steps and sleep integrations when implemented

Profile and Settings may provide shortcuts only.

## Recovery

Recovery is a future module.

Recovery owns:

- Sleep
- HRV
- Readiness
- Recovery score

Sleep must not be placed inside Nutrition.

## Subscription

Subscription business logic belongs to Billing / Entitlement.

Settings is the primary UI entry:

```text
Settings -> Subscription
```

Profile may show a current plan shortcut.

Do not assign subscription ownership to auth controllers, global state, or profile state.

## Personal Information

Personal information belongs to the Profile/account domain.

Onboarding, Profile, and Settings should use the same repository/source of truth when the slice becomes persistent.
