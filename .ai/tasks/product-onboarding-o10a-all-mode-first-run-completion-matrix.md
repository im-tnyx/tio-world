# Product Onboarding O10A — All-Mode First-Run Completion Matrix

**Status:** Active  
**Tracker:** GitHub Issue #96  
**Parent O10:** #95  
**Starting runtime checkpoint:** `86870c0a4164500455877af05f67ba5f2a197e2d` / Flutter #1641 / Android #53 ✅  
**Implementation PR:** #50 Draft/open/unmerged

## Goal

Execute the full `CompleteOnboardingUseCase` boundary for all supported first-run mode/branch variants rather than validating Hybrid setupNow only.

## Matrix

```text
Workout          → Nutrition Targets + Workout Profile/Targets
Nutrition        → Nutrition Profile/Targets; no Workout owners
Hybrid setupNow  → Nutrition + Workout owners
Hybrid later     → Nutrition owners; no active Workout owners
```

Every variant must also persist common Profile/Body/Wellness owners, canonical App Preferences (`appMode` + exact guided destinations), remote/local completion and successful draft cleanup.

## Acceptance

- [ ] all four variants complete through the same finalization use case;
- [ ] active/inactive owner publication matches O9C exactly;
- [ ] Nutrition recommendation remains canonical `recommended` + `source=onboarding`;
- [ ] canonical App Preferences match `AppMode.guidedDestinations` exactly;
- [ ] confirmed mode, remote completion and local completion match the selected mode;
- [ ] successful draft cleanup occurs for every variant;
- [ ] Congratulations remains allowed and stale completed onboarding falls Home;
- [ ] no production source/schema/migration change unless a real defect appears;
- [ ] Flutter/Dart analyze/tests + Android native build green on exact O10A source SHA.

## Exit

Freeze O10A, close #96 and continue O10B completed-session rebootstrap + canonical readback.