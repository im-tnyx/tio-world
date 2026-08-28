# Product Onboarding O10B — Completed-Session Rebootstrap + Canonical Readback

**Status:** Active  
**Tracker:** GitHub Issue #97  
**Parent O10:** #95  
**O10A:** #96 ✅ / CI #1645  
**Starting runtime checkpoint:** `d44d5fec511272e97bf85df8ae3b418ce859d04f`  
**Implementation PR:** #50 Draft/open/unmerged

## Goal

Prove that a successfully completed onboarding account survives a fresh authenticated app/session bootstrap from canonical remote completion, App Preferences and owner data even when stale local App Mode and stale onboarding draft residue exist.

## Acceptance scenario

Use Hybrid `later` so inactive Workout ownership is observable:

- finalize successfully through `CompleteOnboardingUseCase`;
- persist common Profile/Body/Wellness + Nutrition Profile/Targets;
- keep Workout Profile/Targets absent;
- persist canonical Hybrid App Preferences and remote completion;
- reintroduce stale onboarding draft residue after successful completion;
- start a fresh session with stale local App Mode = Workout and non-completed local onboarding status;
- bootstrap from remote completed state;
- restore canonical Hybrid mode + exact active destinations;
- self-heal local onboarding completion to completed;
- clear stale draft best-effort without loading it as semantic authority;
- read canonical owners after bootstrap and prove they remain independent of onboarding draft state;
- completed routing must not restart onboarding.

## Guardrails

- test-only unless a real interaction defect appears;
- no O10C retry expansion;
- no schema/migration/O11 work;
- PR #50 remains Draft/open/unmerged.

## Exit

Freeze exact Flutter/Dart + Android CI, close #97, then continue O10C interruption/retry/resume + duplicate completion protection.