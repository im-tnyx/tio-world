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

for (const valid of ['https://192.168.1.12:7358', 'https://10.20.1.10:7358/', 'https://172.20.2.2:7358']) {
  test('accepts trusted HTTPS private QA preview ' + valid, () => {
    assert.equal(resolvePreviewUrl(valid).url, valid.endsWith('/') ? valid : valid + '/');
  });
}
for (const invalid of [
  'http://192.168.1.12:7358', 'https://192.168.1.12:7357',
  'https://8.8.8.8:7358', 'https://192.168.01.12:7358',
  'https://192.168.1.12:7358/?token=x',
  'https://user@192.168.1.12:7358'
]) {
  test('refuses unsafe QA address ' + invalid, () => assert.equal(resolvePreviewUrl(invalid).url, null));
}
