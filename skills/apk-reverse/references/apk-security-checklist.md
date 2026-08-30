# APK Security Testing Cheat Sheet

> Compiled from OWASP MASTG (Mobile Application Security Testing Guide).
> Covers six dimensions: static analysis, dynamic analysis, network communication, data storage, authentication/authorization, and code protection.

---

## Static Analysis Checklist

### Manifest Audit

```text
□ android:debuggable="true" → debuggable (should never appear in production)
□ android:allowBackup="true" → data can be backed up and extracted
□ Components with android:exported="true" → exposed Activity/Service/Receiver/Provider
□ Custom permission protectionLevel → normal (should be signature)
□ Schemes in intent-filter → custom deeplinks may be hijackable
□ android:usesCleartextTraffic="true" → allows plaintext HTTP
□ Very low minSdkVersion → may lack security features
```

### Key Code Audit Points

```text
□ Hardcoded keys/tokens (search "key", "secret", "password", "api_key")
□ Insecure randomness (java.util.Random instead of SecureRandom)
□ Insecure crypto (ECB mode, DES, MD5 for passwords)
□ WebView configuration (setJavaScriptEnabled + addJavascriptInterface = RCE risk)
□ SQL injection (rawQuery concatenating user input)
□ Path traversal (ContentProvider openFile without path validation)
□ Log leakage (Log.d/Log.i printing sensitive information)
□ Clipboard leakage (ClipboardManager holding sensitive data)
□ Implicit Intent leakage (sendBroadcast without a package name)
```

### Third-Party Library Audit

```text
□ Outdated OkHttp/Retrofit versions (known vulnerabilities)
□ Outdated WebView engine
□ SDKs with known vulnerabilities (check CVEs)
□ Ad SDK data collection scope
□ Push SDK configuration (token leakage)
```

---

## Dynamic Analysis Checklist

### Priority Frida Hook Targets

| Target | Hook Point | Purpose |
|------|---------|------|
| Login authentication | `LoginActivity.login()` | Observe credential handling |
| Signature generation | `*Sign*`, `*sign*`, `*encrypt*` | Recover the signature algorithm |
| SSL Pinning | `CertificatePinner.check` | Bypass traffic capture |
| Root detection | `*root*`, `*su*`, `*magisk*` | Bypass detection |
| Crypto operations | `javax.crypto.Cipher` | Extract keys/IVs |
| Token storage | `SharedPreferences.getString` | Observe token reads/writes |
| Network requests | `OkHttpClient.newCall` | Observe request construction |

### Common Frida One-Liners

```bash
# Trace all crypto operations
frida-trace -U -f com.target.app -j '*Cipher*!*'

# Trace all HTTP requests
frida-trace -U -f com.target.app -j '*OkHttp*!*'

# Trace SharedPreferences reads/writes
frida-trace -U -f com.target.app -j '*SharedPreferences*!*'

# Trace all native function calls
frida-trace -U -f com.target.app -i 'Java_*'
```

### Objection Quick Commands

```bash
# Connect
objection -g com.target.app explore

# Common commands
android hooking list activities
android hooking list services
android sslpinning disable
android root disable
android clipboard monitor
env                              # view the app directories
sqlite connect <db_path>         # connect to a database
```

---

## Network Communication Security

### Traffic Capture Setup

```text
Method 1: system proxy + Burp/mitmproxy
- Set the WiFi proxy → Burp listening address
- Install the CA certificate on the device
- Android 7+ needs network_security_config or a Frida bypass

Method 2: VPN mode (recommended)
- Use HttpCanary / Packet Capture
- No root and no proxy configuration required
- But cannot decrypt SSL-pinned traffic

Method 3: Frida + r2frida
- Intercept network calls directly inside the process
- Not limited by proxy/VPN
```

### Check Items

```text
□ HTTPS used for all API calls?
□ SSL pinning (certificate binding) present?
□ Certificate validation correct (rejects self-signed)?
□ Certificate Transparency (CT) checks present?
□ API keys transmitted in plaintext in requests?
□ Tokens have an expiry mechanism?
□ Request signing prevents tampering?
□ Replay protection present (nonce/timestamp)?
□ WebSockets encrypted?
□ Sensitive data in URL parameters (which get logged)?
```

---

## Data Storage Security

### Places to Check

| Location | Risk | Check Command |
|------|------|---------|
| SharedPreferences | Tokens/passwords in plaintext | `adb shell cat /data/data/pkg/shared_prefs/*.xml` |
| SQLite databases | Unencrypted sensitive data | `adb pull /data/data/pkg/databases/` |
| External storage | Readable by any app | `adb shell ls /sdcard/Android/data/pkg/` |
| App logs | Leaks debug information | `adb logcat \| grep pkg` |
| Backup files | allowBackup=true | `adb backup -f backup.ab pkg` |
| Keyboard cache | Input history | Check whether `inputType` is `textPassword` |
| Screenshot protection | Sensitive screens can be captured | Check `FLAG_SECURE` |

### Encrypted Storage Options Compared

| Option | Security | Notes |
|------|--------|------|
| SharedPreferences plaintext | ❌ | Readable directly after root |
| EncryptedSharedPreferences | ✓ | AndroidX Security library |
| SQLCipher | ✓ | Encrypted SQLite |
| Android Keystore | ✓✓ | Hardware-level key protection |
| Custom AES encryption | ⚠️ | Depends on key management |

---

## Authentication and Authorization

### Common Vulnerabilities

| Vulnerability | Test Method |
|------|---------|
| Weak password policy | Try 123456, password, etc. |
| No lockout mechanism | Brute-force the login endpoint |
| Tokens never expire | Replay an old token after logout |
| Broken object-level authorization | Change user_id in the request |
| SMS OTP brute-forceable | 4/6-digit codes with no rate limiting |
| OAuth misconfiguration | redirect_uri tamperable |
| Biometric bypass | Hook BiometricPrompt |
| Device binding bypass | Change device_id |

### Test Payloads

```bash
# Authorization bypass test
curl -H "Authorization: Bearer USER_A_TOKEN" \
     "https://api.target.com/users/USER_B_ID/profile"

# Token replay
# 1. Log in normally and capture the token
# 2. Log out
# 3. Request with the old token → should return 401

# SMS OTP brute-force
for code in $(seq 0000 9999); do
    curl -X POST "https://api.target.com/verify" \
         -d "phone=+31612345678&code=$code"
done
```

---

## Code Protection Assessment

| Protection | Detection Method | Bypass Difficulty |
|---------|---------|---------|
| ProGuard obfuscation | jadx — are class names a/b/c | Low (renaming only) |
| String encryption | Find the decryption routine, hook to get plaintext | Medium |
| Anti-debugging | Try attaching a debugger | Medium (Frida can bypass) |
| Root detection | Run on a rooted device | Medium (generic script bypass) |
| Emulator detection | Run in an emulator | Low-medium |
| Integrity checks | Modify the APK and reinstall | Medium (patch the check function) |
| Packers/protectors | Inspect entry classes and .so files | Medium-high (needs unpacking) |
| Native protection | Core logic in .so | High (needs IDA analysis) |
| VMP virtualization | Code executed in a virtualized VM | Very high |

---

## Quick Test Flow (30 Minutes)

```text
1. [5min] Unpack + manifest audit
   apktool d app.apk
   Check debuggable/allowBackup/exported/cleartext

2. [10min] Quick code audit
   jadx -d out app.apk
   Search: password, key, secret, token, http://

3. [5min] Network testing
   Configure the proxy → exercise the app → look for plaintext/weak crypto

4. [5min] Storage checks
   adb shell → inspect shared_prefs and databases

5. [5min] Dynamic verification
   Frida-hook the key functions → confirm findings
```
