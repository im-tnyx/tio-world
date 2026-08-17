const GOOGLE_JWKS_URL = 'https://www.googleapis.com/oauth2/v3/certs'
const DEFAULT_GOOGLE_WEB_CLIENT_ID =
  '218403286180-2047ibc6i5r6tb2kftoq4lu6220kl8d9.apps.googleusercontent.com'

const jsonHeaders = {
  'Content-Type': 'application/json',
  'Cache-Control': 'no-store',
}

type GoogleJwtHeader = {
  alg?: string
  kid?: string
}

type GoogleJwtPayload = {
  aud?: string | string[]
  iss?: string
  exp?: number
  email?: string
  email_verified?: boolean
}

type GoogleJwk = JsonWebKey & { kid?: string }

type GoogleJwks = {
  keys?: GoogleJwk[]
}

let cachedJwks: GoogleJwks | null = null
let cachedJwksExpiresAt = 0

function response(body: object, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  })
}

function decodeBase64Url(value: string): Uint8Array {
  const normalized = value.replace(/-/g, '+').replace(/_/g, '/')
  const padded = normalized.padEnd(
    normalized.length + ((4 - (normalized.length % 4)) % 4),
    '=',
  )
  const binary = atob(padded)
  return Uint8Array.from(binary, (character) => character.charCodeAt(0))
}

function decodeJsonSegment<T>(segment: string): T {
  return JSON.parse(new TextDecoder().decode(decodeBase64Url(segment))) as T
}

function cacheMaxAgeSeconds(cacheControl: string | null): number {
  const match = cacheControl?.match(/max-age=(\d+)/i)
  const parsed = match == null ? Number.NaN : Number(match[1])
  return Number.isFinite(parsed) && parsed > 0 ? parsed : 300
}

async function googleJwks(): Promise<GoogleJwks> {
  const now = Date.now()
  if (cachedJwks != null && now < cachedJwksExpiresAt) {
    return cachedJwks
  }

  const jwksResponse = await fetch(GOOGLE_JWKS_URL)
  if (!jwksResponse.ok) {
    throw new Error('Google signing keys are unavailable.')
  }

  const jwks = (await jwksResponse.json()) as GoogleJwks
  if (!Array.isArray(jwks.keys) || jwks.keys.length === 0) {
    throw new Error('Google signing keys response is invalid.')
  }

  const maxAgeSeconds = cacheMaxAgeSeconds(
    jwksResponse.headers.get('cache-control'),
  )
  cachedJwks = jwks
  cachedJwksExpiresAt = now + maxAgeSeconds * 1000
  return jwks
}

function audienceMatches(
  audience: string | string[] | undefined,
  expectedAudience: string,
): boolean {
  if (typeof audience === 'string') return audience === expectedAudience
  return Array.isArray(audience) && audience.includes(expectedAudience)
}

async function verifyGoogleIdToken(idToken: string): Promise<GoogleJwtPayload> {
  const parts = idToken.split('.')
  if (parts.length !== 3) {
    throw new Error('Invalid Google ID token format.')
  }

  const [encodedHeader, encodedPayload, encodedSignature] = parts
  const header = decodeJsonSegment<GoogleJwtHeader>(encodedHeader)
  const payload = decodeJsonSegment<GoogleJwtPayload>(encodedPayload)

  if (header.alg !== 'RS256' || typeof header.kid !== 'string') {
    throw new Error('Unsupported Google ID token signing metadata.')
  }

  const jwks = await googleJwks()
  const jwk = jwks.keys?.find((candidate) => candidate.kid === header.kid)
  if (jwk == null) {
    cachedJwksExpiresAt = 0
    const refreshedJwks = await googleJwks()
    const refreshedJwk = refreshedJwks.keys?.find(
      (candidate) => candidate.kid === header.kid,
    )
    if (refreshedJwk == null) {
      throw new Error('Google signing key was not found.')
    }
    return verifyGoogleIdTokenWithKey(
      encodedHeader,
      encodedPayload,
      encodedSignature,
      payload,
      refreshedJwk,
    )
  }

  return verifyGoogleIdTokenWithKey(
    encodedHeader,
    encodedPayload,
    encodedSignature,
    payload,
    jwk,
  )
}

async function verifyGoogleIdTokenWithKey(
  encodedHeader: string,
  encodedPayload: string,
  encodedSignature: string,
  payload: GoogleJwtPayload,
  jwk: GoogleJwk,
): Promise<GoogleJwtPayload> {
  const key = await crypto.subtle.importKey(
    'jwk',
    jwk,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['verify'],
  )

  const signingInput = new TextEncoder().encode(
    `${encodedHeader}.${encodedPayload}`,
  )
  const signature = decodeBase64Url(encodedSignature)
  const signatureValid = await crypto.subtle.verify(
    'RSASSA-PKCS1-v1_5',
    key,
    signature,
    signingInput,
  )
  if (!signatureValid) {
    throw new Error('Google ID token signature is invalid.')
  }

  const googleClientId =
    Deno.env.get('GOOGLE_WEB_CLIENT_ID') ?? DEFAULT_GOOGLE_WEB_CLIENT_ID
  if (!audienceMatches(payload.aud, googleClientId)) {
    throw new Error('Google ID token audience is invalid.')
  }

  if (
    payload.iss !== 'https://accounts.google.com' &&
    payload.iss !== 'accounts.google.com'
  ) {
    throw new Error('Google ID token issuer is invalid.')
  }

  const nowSeconds = Math.floor(Date.now() / 1000)
  if (typeof payload.exp !== 'number' || payload.exp <= nowSeconds) {
    throw new Error('Google ID token has expired.')
  }

  if (
    payload.email_verified !== true ||
    typeof payload.email !== 'string' ||
    payload.email.trim().length === 0
  ) {
    throw new Error('Google identity does not contain a verified email.')
  }

  return payload
}

function adminApiKey(): string {
  const secretKeysJson = Deno.env.get('SUPABASE_SECRET_KEYS')
  if (secretKeysJson != null && secretKeysJson.length > 0) {
    const secretKeys = JSON.parse(secretKeysJson) as Record<string, string>
    const defaultSecret = secretKeys.default
    if (typeof defaultSecret === 'string' && defaultSecret.length > 0) {
      return defaultSecret
    }
  }

  const legacyServiceRole = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')
  if (legacyServiceRole != null && legacyServiceRole.length > 0) {
    return legacyServiceRole
  }

  throw new Error('Supabase admin API key is unavailable.')
}

async function hasTioAccount(email: string): Promise<boolean> {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')
  if (supabaseUrl == null || supabaseUrl.length === 0) {
    throw new Error('Supabase URL is unavailable.')
  }

  const apiKey = adminApiKey()
  const url = new URL(`${supabaseUrl}/rest/v1/users`)
  url.searchParams.set('select', 'id')
  url.searchParams.set('email', `eq.${email.trim().toLowerCase()}`)
  url.searchParams.set('limit', '1')

  const headers: Record<string, string> = {
    apikey: apiKey,
    Accept: 'application/json',
  }
  if (apiKey.startsWith('eyJ')) {
    headers.Authorization = `Bearer ${apiKey}`
  }

  const accountResponse = await fetch(url, { headers })
  if (!accountResponse.ok) {
    throw new Error('Tio account lookup failed.')
  }

  const rows = (await accountResponse.json()) as unknown
  if (!Array.isArray(rows)) {
    throw new Error('Tio account lookup response is invalid.')
  }
  return rows.length > 0
}

Deno.serve(async (req: Request) => {
  if (req.method !== 'POST') {
    return response({ error: 'method_not_allowed' }, 405)
  }

  try {
    const body = (await req.json()) as { id_token?: unknown }
    if (typeof body.id_token !== 'string' || body.id_token.length === 0) {
      return response({ error: 'invalid_request' }, 400)
    }

    const googleIdentity = await verifyGoogleIdToken(body.id_token)
    const allowed = await hasTioAccount(googleIdentity.email!)
    return response({ allowed })
  } catch (_error) {
    // Never return token details, account metadata, or arbitrary lookup results.
    return response({ error: 'admission_unavailable' }, 503)
  }
})
