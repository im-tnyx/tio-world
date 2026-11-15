// Dev-only boundary: an Expo Go WebView may load a no-auth Flutter preview on
// a private LAN address. Do not accept a hosted URL, localhost, credentials,
// a path, query, fragment, or an arbitrary public service.
function resolvePreviewUrl(raw) {
  if (!raw || typeof raw !== 'string') {
    return { url: null, error: 'Set EXPO_PUBLIC_FLUTTER_WEB_URL to http://YOUR_PRIVATE_LAN_IP:7357 before starting Expo.' };
  }
  const value = raw.trim();
  // Match the raw authority before URL parsing: WHATWG URL normalizes
  // leading-zero IPv4 octets (e.g. 192.168.01.2 → 192.168.1.2).
  const match = /^http:\/\/((?:\d{1,3}\.){3}\d{1,3}):7357\/?$/.exec(value);
  if (!match) {
    return { url: null, error: 'Only http://PRIVATE_LAN_IPV4:7357 is allowed; no credentials, paths, query or public hosts.' };
  }
  const octets = match[1].split('.');
  const isIpv4 = octets.every((part) => String(Number(part)) === part && Number(part) <= 255);
  if (!isIpv4) {
    return { url: null, error: 'Flutter preview URL is not a canonical IPv4 address.' };
  }

  const first = Number(octets[0]);
  const second = Number(octets[1]);
  const isPrivate = first === 10 ||
    (first === 172 && second >= 16 && second <= 31) ||
    (first === 192 && second === 168);
  if (!isPrivate) {
    return { url: null, error: 'Use your computer private Wi-Fi/LAN IPv4 address, not localhost or a public URL.' };
  }
  return { url: 'http://' + match[1] + ':7357/', error: null };
}

module.exports = { resolvePreviewUrl };
