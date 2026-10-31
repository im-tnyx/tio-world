-- TNYX-81 / PR #717
-- Fail closed when legacy mutation receipts do not have immutable results.
-- No historical result can be reconstructed safely from live Note rows.

-- Serialize the precondition check with the existing receipt write path. The
-- migration runner executes this file in one transaction, so the lock and
-- guard are atomic with the migration ledger entry.
lock table private.user_workout_routine_note_mutations in access exclusive mode;

do $$
begin
  if exists (
    select 1
    from private.user_workout_routine_note_mutations
    where result_snapshot is null
  ) then
    raise exception 'routine_note_legacy_receipt_snapshot_required'
      using
        errcode = 'P0001',
        detail = 'Existing mutation receipts are missing immutable result snapshots; this migration does not backfill historical results.',
        hint = 'Resolve the legacy receipt set under the approved release procedure, then rerun the migration.';
  end if;
end;
$$;
