# Product Onboarding O9E — Integrated Finalization Acceptance

**Status:** Active  
**Tracker:** GitHub Issue #94  
**Parent O9:** #88  
**O9A:** #89 ✅ / CI #1627  
**O9B:** #90 ✅ / CI #1630  
**O9C:** #91 ✅ / CI #1634  
**O9D:** #93 ✅ / CI #1638  
**Implementation PR:** #50 Draft/open/unmerged

## Starting exact validated checkpoint

```text
1537c6f3a8d7b7b8d369f8b4a4d65456d695ae3c
Flutter CI #1638 / run 32637962253 / job 97190475798 ✅
Android Native CI #50 / run 32637962231 / job 97190450781 ✅
```

## Scope

Final cross-slice O9 acceptance only. Do not add O10 behavior.

Integrated Hybrid `setupNow` scenario must prove:

1. finalization writes every active canonical owner;
2. Nutrition recommendation is published canonically;
3. Workout publication remains profile + target constraints only;
4. canonical Hybrid app preferences are persisted;
5. backend completion precedes/aligns with local completion;
6. successful completion clears the obsolete draft;
7. post-completion Congratulations route remains valid;
8. stale completed onboarding route falls back Home.

Full CI on the exact checkpoint must keep O9A–O9D focused tests green.

## Acceptance

- [ ] active canonical Profile/Body/Wellness/Nutrition/Workout owners persisted;
- [ ] Nutrition recommendation state/metadata canonical;
- [ ] Workout target constraints preserved;
- [ ] Hybrid guided App Preferences persisted;
- [ ] remote + local completion published;
- [ ] draft cleared after success;
- [ ] Congratulations route valid after completion;
- [ ] stale onboarding route redirects Home;
- [ ] no new owner/schema/migration/generated-plan architecture;
- [ ] all Flutter/Dart gates + Android native build green on exact SHA.

## Exit

Freeze O9E, close #94 + parent #88, align #40/#44/PR #50 to O9 complete, then activate O10 Integrated Final Acceptance.
