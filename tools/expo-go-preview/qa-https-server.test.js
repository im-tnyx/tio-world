const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { fileForUrl } = require('./qa-https-server');
test('serves real assets and SPA fallback but blocks traversal and absent assets', () => {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), 'tio-qa-static-'));
  try {
    fs.writeFileSync(path.join(root, 'index.html'), 'html');
    fs.writeFileSync(path.join(root, 'main.dart.js'), 'js');
    assert.equal(fileForUrl(root, '/'), path.join(root,'index.html'));
    assert.equal(fileForUrl(root, '/login'), path.join(root,'index.html'));
    assert.equal(fileForUrl(root, '/main.dart.js'), path.join(root,'main.dart.js'));
    assert.equal(fileForUrl(root, '/missing.png'), null);
    for (const bad of ['/..%2f..%2fsecrets.txt', '/%2e%2e%2foutside', '/foo%5cbar.txt']) {
      assert.equal(fileForUrl(root, bad), null);
    }
  } finally { fs.rmSync(root,{recursive:true,force:true}); }
});
