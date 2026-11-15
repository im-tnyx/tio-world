// Issue #759: read-only HTTPS static server for *locally compiled*, disposable
// Flutter Web QA assets. TLS cert/key supplied by tester outside Git checkout.
// Never log request bodies, cookies, credentials or client-safe config.
const fs = require('node:fs');
const path = require('node:path');
const https = require('node:https');
const { resolvePreviewUrl } = require('./preview-url');

const MIME = Object.freeze({
  '.html':'text/html; charset=utf-8', '.js':'text/javascript; charset=utf-8',
  '.mjs':'text/javascript; charset=utf-8', '.css':'text/css; charset=utf-8',
  '.json':'application/json; charset=utf-8', '.wasm':'application/wasm',
  '.png':'image/png', '.jpg':'image/jpeg', '.jpeg':'image/jpeg',
  '.webp':'image/webp', '.svg':'image/svg+xml', '.ico':'image/x-icon',
  '.ttf':'font/ttf', '.otf':'font/otf', '.woff':'font/woff',
  '.woff2':'font/woff2', '.bin':'application/octet-stream', '.frag':'text/plain'
});

function fileForUrl(root, requestedUrl) {
  const rootReal = fs.realpathSync(root);
  let requestPath;
  try { requestPath = decodeURIComponent(new URL(requestedUrl, 'https://example.invalid').pathname); }
  catch (_) { return null; }
  if (requestPath.includes('\\') || requestPath.includes('\0') || requestPath.split('/').includes('..')) return null;
  const joined = path.resolve(rootReal, '.' + requestPath);
  const relative = path.relative(rootReal, joined);
  if (relative.startsWith('..') || path.isAbsolute(relative)) return null;
  const candidate = (requestPath === '/' || !path.extname(requestPath)) ? path.join(rootReal, 'index.html') : joined;
  try {
    const real = fs.realpathSync(candidate);
    const rel = path.relative(rootReal, real);
    if (rel.startsWith('..') || path.isAbsolute(rel) || !fs.statSync(real).isFile()) return null;
    return real;
  } catch (_) { return null; }
}

function run(args) {
  if (args.length !== 4) throw new Error('Usage: node qa-https-server.js BUILD_WEB_DIR CERT_PEM KEY_PEM LAN_IPV4');
  const [root, cert, key, ip] = args;
  // TLS listener is intentionally LAN only; no external hosting.
  if (!resolvePreviewUrl('https://' + ip + ':7358').url) throw new Error('Canonical private LAN IPv4 required.');
  if (!fs.existsSync(path.join(root, 'index.html'))) throw new Error('Compiled Flutter Web index missing.');
  const server = https.createServer({ cert: fs.readFileSync(cert), key: fs.readFileSync(key) }, (req, res) => {
    res.setHeader('Cache-Control', 'no-store');
    res.setHeader('X-Content-Type-Options', 'nosniff');
    res.setHeader('Referrer-Policy', 'no-referrer');
    if (req.method !== 'GET' && req.method !== 'HEAD') { res.writeHead(405); res.end(); return; }
    const file = fileForUrl(root, req.url || '/');
    if (!file) { res.writeHead(404); res.end(); return; }
    res.setHeader('Content-Type', MIME[path.extname(file)] || 'application/octet-stream');
    if (req.method === 'HEAD') { res.writeHead(200); res.end(); return; }
    const stream = fs.createReadStream(file);
    stream.on('error', () => { if (!res.headersSent) res.writeHead(500); res.end(); });
    stream.pipe(res);
  });
  server.on('error', error => { console.error('HTTPS preview unavailable: ' + error.code); process.exitCode = 1; });
  server.listen(7358, ip, () => console.log('QA HTTPS preview listening on private LAN port 7358. Do not expose via public forwarding.'));
  return server;
}
if (require.main === module) {
  try { run(process.argv.slice(2)); }
  catch (error) { console.error('QA HTTPS preview blocked: ' + error.message); process.exitCode = 1; }
}
module.exports = { fileForUrl, run };
