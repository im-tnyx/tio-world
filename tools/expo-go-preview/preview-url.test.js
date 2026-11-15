const test = require('node:test');
const assert = require('node:assert/strict');
const { resolvePreviewUrl } = require('./preview-url');

for (const valid of [
  'http://192.168.0.10:7357',
  'http://10.0.0.8:7357/',
  'http://172.16.1.2:7357',
  'http://172.31.255.254:7357'
]) {
  test('accepts private LAN URL ' + valid, () => {
    const result = resolvePreviewUrl(valid);
    assert.equal(result.error, null);
    assert.ok(result.url.startsWith('http://'));
    assert.ok(result.url.endsWith('/'));
  });
}

for (const invalid of [
  '', 'http://localhost:7357', 'http://127.0.0.1:7357',
  'http://8.8.8.8:7357', 'https://192.168.1.3:7357',
  'http://192.168.1.3:8080', 'http://192.168.1.3:7357/login',
  'http://192.168.1.3:7357/?token=abc',
  'http://user:pass@192.168.1.3:7357',
  'http://192.168.1.3:7357/#private',
  'http://172.32.0.1:7357', 'http://192.169.0.1:7357',
  'http://192.168.0.999:7357', 'http://192.168.01.2:7357',
  'http://example.com:7357', 'file:///private', 'javascript:alert(1)'
]) {
  test('rejects unsafe/non-LAN URL ' + invalid, () => {
    const result = resolvePreviewUrl(invalid);
    assert.equal(result.url, null);
    assert.ok(result.error);
  });
}
