# Product Onboarding O2E — Integrated Canonical Profile Acceptance

**Status:** In progress  
**Tracker:** GitHub Issue #53  
**Parent tracker:** #40  
**Canonical ownership:** #44  
**Implementation PR:** #50 Draft/open/unmerged  
**Branch:** `agent/onboarding-slice-2-step-1-body-goal-ui`

## Starting checkpoint

O2D is validated:

```text
6843a14b89f0c0bb7d62b1466eb3855ddbef0f64
Flutter CI #1275 / run 32555015103
Flutter analyze ✅
Dart analyze    ✅
Flutter tests   ✅
Dart tests      ✅
```

O2 foundation entering O2E:

```text
O2A UserProfileData + UserProfileRepository               ✅ #1252
O2B SupabaseUserProfileRepository → public.user_profiles   ✅ #1252
O2C Product Onboarding canonical Profile write cutover     ✅ #1268
O2D active userProfile section + legacy resume             ✅ #1275
O2E integrated canonical Profile acceptance                ACTIVE
```

## Outcome

Prove the complete O2 common Profile lifecycle across canonical read/write boundaries, Product Onboarding persistence, active section identity and legacy draft compatibility. Production behavior should change only if integrated acceptance exposes a real O2 contract gap.

O2E is the final O2 validation gate before O3.

## Canonical lifecycle to prove

```text
legacy/existing account context
→ canonical user_profiles read is authoritative for common Profile
→ Product Onboarding draft / userProfile section
→ strict common Profile mapping
→ canonical user_profiles upsert
→ Body owner remains separate
→ persisted/resumed profileBasics checkpoint keeps userProfile identity
→ fresh repository read returns the accepted canonical Profile exactly
```

## Acceptance matrix

- [ ] canonical `UserProfileRepository.read` returns `user_profiles` truth independently of stale legacy `users` Profile mirrors;
- [ ] canonical common Profile write/read round-trip preserves name, gender, DOB, units, height, activity and health fields exactly;
- [ ] Product Onboarding completion path uses canonical Profile upsert before completion publication;
- [ ] canonical Profile write excludes Account/avatar/plan/App Mode/Goal/current/target weight concepts;
- [ ] Body current weight/Goal persistence remains separate and unchanged;
- [ ] active Product Onboarding Profile section is `userProfile` using existing `ProfileSection`;
- [ ] serialized legacy `profileBasics` snapshot resumes to active `userProfile` without losing answers/nested Profile step;
- [ ] canonical Profile failure prevents downstream false completion;
- [ ] unauthenticated canonical Profile access fails closed with no anonymous auth side effect;
- [ ] malformed canonical Profile state fails safely rather than fabricating semantic defaults;
- [ ] no legacy column drop/schema migration;
- [ ] no O3/bodyGoal activation;
- [ ] full Flutter analyze + Dart analyze + Flutter tests + Dart tests green on exact final O2 checkpoint;
- [ ] exact final O2 evidence recorded in #53/#40/#44/PR #50 and repo handoff tasks before O3.

## Read precedence rule

`public.user_profiles` is the canonical common Profile owner. Legacy broad `users` Profile mirrors may remain for compatibility surfaces, but they must never override canonical common Profile reads through `UserProfileRepository`.

An unfinished onboarding draft remains orchestration state, not a competing durable owner. O2E must not invent a permanent `users` ↔ `user_profiles` synchronization layer.

## Guardrails

- preserve existing Profile onboarding UI and picker contracts;
- preserve stable `OnboardingStepId.profileBasics`;
- preserve legacy `OnboardingSectionId.profile` compatibility only; active flow remains `userProfile`;
- Current Weight stays Body-owned;
- no applied migration edits or legacy-column drops;
- no permanent dual-write synchronization;
- no anonymous-auth fallback;
- no fabricated semantic defaults;
- do not start O3 until this task is validated and all canonical trackers are synced.

## Current work

**Add a bounded integrated O2 acceptance harness around the canonical Profile repository/bridge + Product Onboarding owner persistence + serialized resume path. Change production code only if the harness exposes a real gap.**
