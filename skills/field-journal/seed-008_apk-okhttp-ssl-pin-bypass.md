# [Seed] APK Frida Bypass of OkHttp SSL Pinning

## Scenario Category
APK reverse engineering / mobile security testing

## Target Overview
For an Android app using OkHttp + a custom CertificatePinner, use Frida to bypass certificate validation dynamically so Burp can capture plaintext traffic.

## Complete Execution Chain

1. Install Frida + frida-server, start the target app, confirm the process name
   ```bash
   adb shell "ps -A | grep com.target.app"
   frida-ps -U | grep target
   ```
2. Try capturing with Burp → a certificate error comes back, meaning pinning is enabled
3. Open the APK with jadx and decompile → search `CertificatePinner` or `checkServerTrusted`
4. Determine whether it is OkHttp's built-in `CertificatePinner` or a custom `X509TrustManager`
5. Write a Frida script hooking the key validation points
6. Start Frida injection: `frida -U -f com.target.app -l bypass.js --no-pause`
7. Capture traffic again → Burp can see plaintext HTTPS

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Frida startup error `unable to connect to remote frida-server` | Server not started or port occupied | `adb forward tcp:27042 tcp:27042` + start the server | 10min |
| Hook does not take effect | The app starts too fast; Frida injects too late | Use `-f` spawn mode with `--no-pause` | 15min |
| Some requests still show SSL errors after hooking | The app uses both OkHttp and native HttpsURLConnection | Add hooks for `X509TrustManager.checkServerTrusted` and `HostnameVerifier.verify` | 20min |
| Anti-detection: the app exits when it detects Frida | The app self-checks the frida-server port / `/data/local/tmp/re.frida.server` | Switch to frida-gadget (inject a .so into the APK) or magisk + zygisk-frida | 30min+ |
| ProGuard-obfuscated class names cannot be found | Class names become short names like `a.b.c` | In jadx use `Find Usages` to trace back who instantiates OkHttpClient.Builder | 25min |

## Toolchain Findings

- **objection** ships with `android sslpinning disable` — one command handles 80% of scenarios, no need to write your own Frida script
- **frida-multiple-unpinning** (GitHub: WithSecureLabs) covers OkHttp 3/4, Retrofit, HttpsURLConnection, Conscrypt, Cordova — the universal script
- The **MEDUSA** framework ships with all kinds of Android bypass modules; faster to get started with than raw Frida

## Key Code/Commands

Minimal working OkHttp pin bypass script:

```javascript
Java.perform(function () {
    // 1. OkHttp 3/4 built-in CertificatePinner
    try {
        var CertificatePinner = Java.use('okhttp3.CertificatePinner');
        CertificatePinner.check.overload('java.lang.String', 'java.util.List').implementation = function (host, peers) {
            console.log('[+] OkHttp CertificatePinner.check bypassed: ' + host);
            return;
        };
    } catch (e) {}

    // 2. Custom X509TrustManager.checkServerTrusted
    try {
        var TrustManagerImpl = Java.use('com.android.org.conscrypt.TrustManagerImpl');
        TrustManagerImpl.verifyChain.implementation = function (untrusted, holdHost, host, clientAuth, ocspData, tlsSctData) {
            console.log('[+] TrustManagerImpl.verifyChain bypassed: ' + host);
            return untrusted;
        };
    } catch (e) {}

    // 3. HostnameVerifier all-pass
    var HostnameVerifier = Java.use('javax.net.ssl.HostnameVerifier');
    // Complete with objection's bundled template...
});
```

One-shot command (recommended):

```bash
objection --gadget com.target.app explore -s "android sslpinning disable"
```

## Improvement Suggestions for This Package

- `apk-reverse/references/` should have a dedicated `ssl-pinning-bypass.md` merging the four mainstream cases — OkHttp 3/4, Conscrypt, custom TrustManager, Flutter (boringssl) — into one cheat sheet
- Add `objection` (pip package) to the bootstrap manifest

## Reusable Patterns/Script Snippets

**Generic bypass flow**:

```text
1. Capture traffic → identify the error type (CertPin / Hostname / TrustManager)
2. Search the key classes with jadx (CertificatePinner / X509TrustManager / HostnameVerifier)
3. Try objection one-shot first → then frida-multiple-unpinning → then hand-write
4. If anti-Frida detection exists → switch to frida-gadget or zygisk
5. Handle Flutter apps separately (hook libflutter.so's ssl_verify_peer_cert)
```

## Evolution Actions
- [x] Routing matrix already covered (apk-reverse + Frida)
- [x] frida status checked in tool-index
- [ ] Suggest adding the ssl-pinning-bypass.md cheat sheet

## Environment Info
- Kali / Windows + adb + frida-tools 16.x
- Target Android: 8-14 (TrustManagerImpl paths differ across versions)
- Injection method: USB debugging + frida-server / or zygisk-frida for hiding

## De-identification Requirement
This entry is seed data written from public technical patterns; it involves no real target. The package name `com.target.app` is a placeholder.
