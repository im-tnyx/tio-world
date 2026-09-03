# Supabase migration-lineage reconciliation (tio-world)

**Status:** Awaiting review
**Scope:** Repository only. No hosted mutation of any kind.
**Hosted project:** `oykupyiitspujzpwwvuj` (tio-world)
**PR:** #203, Draft

## Owner Approval and Scope Boundary

**Approval status:** Approved, decisions frozen 2026-09-03.
**Approved boundaries:** Add one forward reconciliation migration; rename eight
drifted migration files to the versions hosted already recorded; update
repository documentation the renames would otherwise falsify.
**Explicit non-changes:** No hosted DDL. No `supabase db push`. No
`supabase migration repair`. No ledger mutation. No production data change. No
RLS/RPC/policy change. No change to PR #202 or its branch. No historical
migration edited in place.

## 1. The model this branch uses

```text
historical migration files preserved byte-for-byte
+ one new forward reconciliation migration
+ eight timestamp identity repairs
```

Nothing else. In particular, **no historical migration body is rewritten**.

### Why the first approach was rejected (audit history, kept deliberately)

The first version of this branch corrected two divergences by **editing the
historical migrations in place**: it deleted the retired-table blocks from
`20260814000001` and changed `20260814000002` from 5 MB to 10 MB.

That was wrong, and review caught it. `docs/DATABASE_BACKUP_RECOVERY.md`
("Migration Ownership") states the rule plainly:

- *never edit an already applied migration to change production history;*
- *add a new forward migration for corrections;*
- *The current project already has a live migration history, so historical
  files are evidence, not templates to rewrite.*

Two concrete harms followed from the original approach:

1. **It made provenance less truthful.** The early lineage's physical effects
   are demonstrably present in the database, and the ledger is precisely the
   thing under reconciliation. Rewriting the old file to describe today's state
   erases the record of what was actually run.
2. **It changed replay for any environment that did use those files.** A
   developer database built from the original history would silently diverge
   from one built after the edit, with nothing recording the change.

Both historical files are now restored to their exact `origin/main` bytes, and
the corrections live in a new forward migration instead. The retained value of
the original analysis — *what* diverged and *why* it matters — is unchanged; only
the mechanism changed.

## 2. Why the early files diverge from hosted history

The hosted ledger holds 26 rows and begins at `20260817090811`. The repository
holds 38 migrations (37 historical + the new forward one). Compared by *logical
name* rather than by version:

| Group | Count | Meaning |
|---|---|---|
| Exact version match | 18 | file and ledger agree |
| Version drift | 8 | same logical migration, different timestamp |
| No ledger row at all | 11 | the `20260814000001`-`20260816000004` range |

An earlier audit recorded only **3** drifted migrations. Re-reading both ledgers
fresh found **8**. The five previously missed are
`create_username_availability_rpc`, `harden_username_policy`,
`refine_username_impersonation_policy`, `cleanup_legacy_canonical_mirrors` and
`provision_account_root_from_auth_users`. This is not cosmetic: `supabase db
push` selects work by **version**, so before this reconciliation it would have
treated 20 migrations as pending, not 12.

### The replay hazard is silent, not loud

Replaying the 11 unrecorded migrations does not fail noisily against existing
objects. Every one is idempotent — `IF NOT EXISTS`, `DROP POLICY IF EXISTS`
before each `CREATE POLICY`, `CREATE OR REPLACE FUNCTION`, guarded `DO` blocks.
They would **succeed**, and in succeeding would undo later, deliberate
decisions. That is what the forward migration now converges instead.

## 3. Why the two legacy tables are retired

`public.user_targets` and `public.user_workout_preferences` were created only by
`20260814000001_create_onboarding_owner_tables.sql`. Neither exists on hosted,
and **no migration anywhere in this repository drops them** — so their absence
is not the result of a recorded retirement, and a fresh replay of the historical
file would leave two dead tables behind.

Their replacements are `public.user_nutrition_targets`,
`public.user_wellness_targets` and `public.user_workout_targets`, introduced by
`20260821161923_create_canonical_owner_tables.sql`.

The forward migration retires them **fail-closed**, erring toward caution
rather than convenience:

| State | Behaviour |
|---|---|
| table absent | no-op, so replay converges |
| table present **with rows** | `RAISE` and abort — another environment may hold real data |
| table present and empty | `DROP TABLE`, **no `CASCADE`** |

`CASCADE` is deliberately excluded. If a view, foreign key or other dependency
still points at a legacy table, the drop fails loudly rather than silently
taking the dependent object with it.

## 4. Why the avatars bucket is 10 MB

`20260814000002_create_profile_storage_bucket.sql` creates the bucket at
`5242880` (5 MB) **and re-asserts it through `ON CONFLICT (id) DO UPDATE`**.
Hosted has long been `10485760` (10 MB), with no migration recording that
decision.

The historical file keeps its 5 MB body. The forward migration supplies the
missing source-control evidence for the 10 MB decision, so a fresh replay
converges 5 MB → 10 MB along the same forward sequence production must follow.
It is fail-closed: a missing `avatars` bucket aborts rather than being created.
Only `file_size_limit` is touched — the `public` flag, `allowed_mime_types`, the
Storage RLS policies and object ownership semantics are all left alone.

## 5. Why `app_build` INTEGER is still a real pending migration

`20260816000004_reconcile_user_devices_app_build_type.sql` converts
`public.user_devices.app_build` from `TEXT` to `INTEGER` inside a guarded `DO`
block. Hosted inspection confirms the column is **still `text`**.

It is byte-identical to `origin/main`, is **not** folded into the forward
reconciliation migration, and is **not** marked obsolete. It remains a genuinely
pending historical migration whose conversion requires its own hosted execution
gate. Marking it applied would permanently strand a real schema change.

## 6. The eight timestamp mappings

Repo-side rename was chosen over ledger repair because it needs **zero hosted
mutation**; repairing both sides would have meant 8 inserts plus 8 deletes
against the production ledger to reach the same 1:1 state.

| Repo (was) | Repo (now) = hosted | Logical migration |
|---|---|---|
| 20260817000001 | **20260817090811** | create_username_availability_rpc |
| 20260817000002 | **20260817100424** | harden_username_policy |
| 20260817000003 | **20260817101532** | refine_username_impersonation_policy |
| 20260824070300 | **20260824070233** | cleanup_legacy_canonical_mirrors |
| 20260824180400 | **20260824180611** | provision_account_root_from_auth_users |
| 20260826072000 | **20260826075218** | refine_username_suggestions |
| 20260830055341 | **20260830074411** | set_active_body_goal_rpc |
| 20260831064500 | **20260831064841** | add_nutrition_other_free_text |

Only `20260824070233` moves *earlier* than its old repo version; directory order
is still strictly ascending and no target version collided with an existing file.

### Bodies verified quote-aware, not by a global punctuation fold

`supabase_migrations.schema_migrations` stores the applied SQL in a `statements`
column, so each renamed file is compared against **what hosted actually ran**.

An earlier proof folded whitespace around `( ) , ;` across the *whole* text.
That is unsafe: those characters also occur inside single-quoted literals, so
the fold could have masked a real difference in a reserved-username list, a
policy name or an error message. The verification now produces **two independent
digests** per migration:

- **`lits_md5`** — every single-quoted literal, in order, hashed **verbatim**:
  no case folding, no whitespace folding, no punctuation folding. A change
  inside any quoted string surfaces here and cannot be normalized away.
- **`code_md5`** — the code skeleton *after* literals are replaced by `@`, then
  lowercased and whitespace/punctuation-spacing folded. Folding is only sound
  here because the literals are already gone.

Two normalization asymmetries were found and localized manually rather than
assumed away:

1. Hosted strips leading `--` header comments for most migrations but **retained
   them** for `20260824070233`, `20260826075218` and `20260830074411`. Comment
   lines are now stripped on **both** sides.
2. Before that fix, `20260830074411` reported a **literal** mismatch — caused by
   an apostrophe inside a retained comment being read as the start of a string.
   That was the verification's own artifact, and it is exactly the kind of
   signal the earlier global fold would have hidden.

With both sides treated identically, **all eight match on literals and on code**.
The three migrations confirmed by a direct server-side comparison act as controls
proving the local and Postgres implementations agree.

## 7. Sibling-project lineage: evidence-bounded

Several of the 11 unrecorded migrations carry names suggestive of the sibling
`tnyx-hub` project (`create_tnyxhub_canonical_tables`, `create_user_devices_table`,
`add_plan_to_users_table`).

**That provenance is not proven, and this brief no longer claims it.** A fresh
read-only check of the current `tnyx-hub` ledger (`hmxylzecbsleovcmbdhm`) shows
only **seven** migrations, all in the `20260810` range
(`nutrition_meal_logs` through `harden_profile_nutrition_owner_access`), and
**none** of these eleven versions or names.

The filenames suggest possible sibling or local-lineage provenance, but the
current `tnyx-hub` ledger does not contain these migrations, so their origin is
not established. Reconciliation is based only on tio-world's own ledger and
physical schema evidence. `tnyx-hub` was not modified.

## 8. Timestamp consequence for PR #202 (recorded, not acted on)

The new forward migration is `20260903052101_reconcile_legacy_lineage_state.sql`.
Its timestamp is **later** than PR #202's still-unapplied
`20260902041627_add_nutrition_additional_nutrient_goals.sql`.

Therefore, **after** PR #203 is accepted and merged and PR #202 rebases onto the
new `main`, the TNYX-141 migration must receive a fresh canonical timestamp
later than `20260903052101` before it is applied to hosted. Otherwise it would
sort before a migration that had already run.

This is safe precisely because the TNYX-141 migration is still unapplied — its
version has never been recorded in any ledger, so renaming it costs nothing.

**That rename is deliberately not performed in PR #203.** PR #202 is untouched
here.

## 9. Result

- Repository migrations: **38**, strictly ascending, **0 duplicate versions**.
- `20260903052101_reconcile_legacy_lineage_state.sql` is the latest migration.
- Historical migrations `20260814000001`, `20260814000002` and `20260816000004`
  are byte-identical to `origin/main`.
- The 26 historical files from `20260817090811` onward map **1:1** onto the 26
  hosted ledger rows.
- Exactly the 11 known-unrecorded legacy migrations remain unmatched, which is
  the expected end state of a repo-only pass.

## 10. Hosted Supabase was NOT mutated

No DDL, no `db push`, no `migration repair`, no ledger write, no data change, no
RLS or RPC change. Every hosted interaction was a read-only `SELECT`.

## 11. Next step requires explicit owner authorization

This branch makes the *repository* honest. It does not make hosted consistent.
Still outstanding, all owner-gated:

1. Decide the disposition of the 11 unrecorded migrations — 8 are verified
   physically present and are repair-as-applied candidates; `20260816000004`
   must be **executed**, not marked.
2. Repair the ledger.
3. Apply `20260903052101_reconcile_legacy_lineage_state.sql`.
4. Re-timestamp and apply the TNYX-141 migration (PR #202), which remains Draft
   and unchanged.

No hosted step is authorized by this task.
