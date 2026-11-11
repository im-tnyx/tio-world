# Owner Decision — Routine Notes Testing-Only Backup Deferral

**Decision date:** 2026-11-02
**Repository:** `im-tnyx/tio-world`
**Supabase project:** `tio-world` (`oykupyiitspujzpwwvuj`)
**Decision status:** Testing-only recovery deferral approved within the stated boundary; production recovery readiness remains **NOT APPROVED**.

**Source:** Owner-provided decision record in the R1 governance handoff, transcribed here without interpretation.

As product owner, I confirm the following decision:

1. The current hosted environment is being used for development and testing only. The present dataset is declared disposable testing data.
2. I accept the possibility of losing this testing data during the approved Routine Notes migration/testing phase.
3. Full production-grade backup, retention, restore rehearsal and RPO/RTO acceptance may be deferred for this explicitly testing-only scope.
4. This exception does not authorize deleting existing data, disabling security controls, bypassing migration validation, or performing an unapproved database reset.
5. Before real-user or production data is accepted, or before production launch, the exception expires. Full database/Auth and Storage recovery readiness, restore testing and the canonical RPO/RTO requirements must be satisfied.
6. This decision does not authorize deployment execution, scheduler activation, database credentials or changes to the existing A–G approval process.
7. Any change in the data classification or intended use of this environment requires a new review before proceeding.

**Decision:** Testing-only recovery deferral approved within the stated boundary. Production recovery readiness remains **NOT APPROVED**.
