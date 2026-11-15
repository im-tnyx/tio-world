// A narrow, fail-closed adaptation of a disposable Flutter Web snapshot only.
// This file MUST NOT mutate the original checkout or the product Dart sources.
const fs = require('node:fs');
const path = require('node:path');

const RULES = Object.freeze([
  { relative: 'apps/features/workout/lib/src/data/repositories/supabase_routine_move_repository.dart', count: 3 },
  { relative: 'apps/features/workout/lib/src/domain/repositories/routine_move_repository.dart', count: 1 }
]);
const OLD = '== 9223372036854775807';
const SAFE_WEB_GUARD = '> 9007199254740991';

function prepareWebSnapshot(snapshotRoot) {
  if (typeof snapshotRoot !== 'string' || !snapshotRoot.trim()) {
    throw new Error('Explicit disposable Git worktree path is required.');
  }
  const root = path.resolve(snapshotRoot);
  const gitPointer = path.join(root, '.git');
  if (!fs.existsSync(gitPointer) || !fs.lstatSync(gitPointer).isFile() ||
      !fs.readFileSync(gitPointer, 'utf8').startsWith('gitdir:')) {
    throw new Error('Refusing to touch a normal repository: expected Git linked-worktree .git file.');
  }
  if (!fs.existsSync(path.join(root, 'apps/app/web/index.html'))) {
    throw new Error('Refusing to patch before generating disposable Flutter Web runner.');
  }

  // Validate EVERY source before writing ANYTHING, preserving fail-closed behavior.
  const edits = RULES.map(({ relative, count }) => {
    const file = path.join(root, relative);
    const before = fs.readFileSync(file, 'utf8');
    const found = before.split(OLD).length - 1;
    if (found !== count) {
      throw new Error(relative + ': expected ' + count + ' literal guards, found ' + found + '; aborting without edits.');
    }
    return { file, after: before.split(OLD).join(SAFE_WEB_GUARD) };
  });

  for (const edit of edits) {
    fs.writeFileSync(edit.file, edit.after, 'utf8');
  }
  return edits.length;
}

if (require.main === module) {
  try {
    const count = prepareWebSnapshot(process.argv[2]);
    console.log('Patched ' + count + ' files in disposable Web snapshot only. Product Flutter code was not changed.');
  } catch (error) {
    console.error('Disposable preview patch blocked: ' + error.message);
    process.exitCode = 1;
  }
}
module.exports = { prepareWebSnapshot, RULES, OLD, SAFE_WEB_GUARD };
