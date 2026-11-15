const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { prepareWebSnapshot, RULES, OLD, SAFE_WEB_GUARD } = require('./prepare-web-snapshot');

function withFixture(callback) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'tio-expo-759-test-'));
  try {
    fs.writeFileSync(path.join(root, '.git'), 'gitdir: /temporary-test');
    const webDir = path.join(root, 'apps/app/web');
    fs.mkdirSync(webDir, { recursive: true });
    fs.writeFileSync(path.join(webDir, 'index.html'), '<html></html>');
    for (const rule of RULES) {
      const file = path.join(root, rule.relative);
      fs.mkdirSync(path.dirname(file), { recursive: true });
      fs.writeFileSync(file, ('revision ' + OLD + '\n').repeat(rule.count));
    }
    callback(root);
  } finally {
    fs.rmSync(root, { recursive: true, force: true });
  }
}

test('changes only known int64 sentinel checks in a disposable linked worktree', () => {
  withFixture(root => {
    assert.equal(prepareWebSnapshot(root), RULES.length);
    for (const rule of RULES) {
      const content = fs.readFileSync(path.join(root, rule.relative), 'utf8');
      assert.equal(content.split(SAFE_WEB_GUARD).length - 1, rule.count);
      assert.ok(!content.includes(OLD));
    }
  });
});

test('refuses ordinary .git directory even when web runner exists', () => {
  withFixture(root => {
    fs.rmSync(path.join(root, '.git'));
    fs.mkdirSync(path.join(root, '.git'));
    assert.throws(() => prepareWebSnapshot(root), /normal repository/);
  });
});

test('refuses missing web runner', () => {
  withFixture(root => {
    fs.rmSync(path.join(root, 'apps/app/web'), { recursive: true });
    assert.throws(() => prepareWebSnapshot(root), /Web runner/);
  });
});

test('fails atomically if expected sentinel count has changed', () => {
  withFixture(root => {
    const last = RULES[RULES.length - 1];
    fs.writeFileSync(path.join(root, last.relative), 'source no longer contains sentinel');
    assert.throws(() => prepareWebSnapshot(root), /expected 1 literal guards/);
    const first = fs.readFileSync(path.join(root, RULES[0].relative), 'utf8');
    assert.ok(first.includes(OLD));
    assert.ok(!first.includes(SAFE_WEB_GUARD));
  });
});
