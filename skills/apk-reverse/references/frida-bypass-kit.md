# Frida Bypass Kit — Android Universal Security Bypass Framework

> Source: [FridaBypassKit](https://github.com/okankurtuluss/FridaBypassKit) (2025)
> Applicable scenarios: when APK dynamic analysis needs to bypass root detection, SSL pinning, emulator detection, or anti-debugging

## Overview

FridaBypassKit is a Frida script that integrates four major bypass capabilities. It requires no customization for a specific app and works out of the box.

## Four Major Bypass Capabilities

### 1. Root Detection Bypass

- Hook `File.exists()` to hide the su binary
- Intercept `Runtime.exec()` root-check invocations
- Hide root-related packages (Magisk, SuperSU, etc.) from PackageManager
- Modify system properties so the device appears unrooted

### 2. SSL Pinning Bypass

- Hook `TrustManagerImpl.verifyChain()`
- Hook `TrustManagerImpl.checkTrustedRecursive()`
- Bypass certificate chain validation
- Return an empty certificate chain to avoid verification
- Compatible with OkHttp, Retrofit, and custom implementations

### 3. Emulator Detection Bypass

- Spoof TelephonyManager return values
- Return fake phone numbers and carrier names
- Modify Build properties

### 4. Anti-Debug Bypass

- Hook `Debug.isDebuggerConnected()`
- Block debugger detection
- Bypass anti-debugging checks

## Usage

```bash
# Prerequisites
pip install frida-tools
adb push frida-server /data/local/tmp/
adb shell chmod 755 /data/local/tmp/frida-server
adb shell su -c /data/local/tmp/frida-server &

# Inject into the target app
frida -U -f com.example.app -l FridaBypassKit.js
```

## Other Recommended Frida Bypass Scripts

| Project | Highlights | Link |
|------|------|------|
| httptoolkit/frida-interception-and-unpinning | MitM all HTTPS traffic directly | [GitHub](https://github.com/httptoolkit/frida-interception-and-unpinning) |
| 0xCD4/SSL-bypass | Universal non-customized SSL bypass | [GitHub](https://github.com/0xCD4/SSL-bypass) |
| incogbyte/ssl-bypass gist | Bypasses common SSL pinning methods | [Gist](https://gist.github.com/incogbyte/1e0e2f38b5602e72b1380f21ba04b15e) |
| Zero3141/Frida-OkHttp-Bypass | Specifically targets OkHttp CertificatePinner | [GitHub](https://github.com/Zero3141/Frida-OkHttp-Bypass) |

## Integration With This Skill

Within the `apk-reverse` workflow, use it in the following situations:

1. The app detects root and refuses to run → enable Root Detection Bypass
2. HTTPS requests show no plaintext while capturing → enable SSL Pinning Bypass
3. The app detects the emulator and refuses to run → enable Emulator Detection Bypass
4. The app crashes after attaching Frida → enable Debug Detection Bypass

Recommended combination: run the full FridaBypassKit first, then fine-tune per target.
