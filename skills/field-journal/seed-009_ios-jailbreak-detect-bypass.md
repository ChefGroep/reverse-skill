# [Seed] iOS Jailbreak Detection Bypass + Traffic Capture

## Scenario Category
iOS reverse engineering / mobile security testing

## Target Overview
An iOS app crashes on launch or shows "environment abnormal" on a jailbroken device; the jailbreak detection must be bypassed before its HTTP requests can be analyzed further.

## Complete Execution Chain

1. Prepare the jailbroken device (Dopamine / palera1n / unc0ver) → install frida-server (Cydia repo `build.frida.re`)
2. Drag the IPA onto the machine, install AppSync Unified for signing → launch and confirm `frida-ps -U` works
3. Start the app → crashes or pops "environment abnormal"
4. Use `frida-trace -U -i 'open' -i 'stat' -i 'access' -i 'fork' com.target.app` to observe the detection calls
5. Common hits: probing `/Applications/Cydia.app`, `/private/var/lib/apt`, `/usr/sbin/sshd`, whether `fork()` succeeds, `/etc/apt`
6. One-shot bypass with objection: `objection --gadget com.target.app explore -s "ios jailbreak disable"`
7. Once started, hook NSURLSession with frida to capture traffic, or pair with mitmproxy after installing a system certificate

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| The app still crashes after the objection bypass | The app uses SSL pinning + jailbreak detection together | Enable both `ios sslpinning disable` and `ios jailbreak disable` | 15min |
| The app detects before launch; hooks are too late | Jailbreak detection runs in `+load` or `__attribute__((constructor))` | Use `-f` spawn mode + `frida-trace --aux 'spawn=1'` | 20min |
| The app hangs after hooking stat | Hooking stat also affects some system calls | Only hook stat triggered by code inside the app bundle (filter by caller) | 30min |
| The app still detects Frida after frida-server starts | The app checks port 27042 and frida strings | Rename `frida-server` + change the default port (`-l 0.0.0.0:1234`); the client uses `-H ip:1234` | 25min |
| Still SSL errors after installing the mitmproxy certificate | On iOS 14+ system certificates need an extra toggle under "General → About → Certificate Trust Settings" | After installing the certificate, enable it in the trust settings | 10min |

## Toolchain Findings

- **objection** is the Swiss army knife of iOS security testing, with built-in jailbreak / sslpin / clipboard / keychain dump modules
- **r2frida** connects radare2 to frida, enabling runtime disassembly + register modification — much stronger than plain frida
- **Hopper / IDA** decompile iOS binaries (iOS Mach-O works with IDA 7+ or Ghidra)
- **dumpdecrypted** is outdated; use **frida-ios-dump** for decryption now

## Key Code/Commands

Generic jailbreak-detection hook template:

```javascript
// Intercept NSFileManager fileExistsAtPath to hide jailbreak directories
var NSFileManager = ObjC.classes.NSFileManager;
Interceptor.attach(NSFileManager['- fileExistsAtPath:'].implementation, {
    onEnter: function (args) {
        var path = ObjC.Object(args[2]).toString();
        var jbPaths = [
            '/Applications/Cydia.app',
            '/Library/MobileSubstrate/MobileSubstrate.dylib',
            '/bin/bash', '/usr/sbin/sshd',
            '/etc/apt', '/private/var/lib/apt/'
        ];
        if (jbPaths.indexOf(path) !== -1) {
            this.shouldFake = true;
            console.log('[+] Hide JB path: ' + path);
        }
    },
    onLeave: function (retval) {
        if (this.shouldFake) retval.replace(0);
    }
});

// Intercept fork() — jailbroken devices can fork; non-jailbroken returns -1
var fork = Module.findExportByName(null, 'fork');
Interceptor.replace(fork, new NativeCallback(function () {
    return -1;
}, 'int', []));
```

One-shot decryption (for later decompilation with jadx etc.):

```bash
frida-ios-dump -l com.target.app
# Outputs Payload/TargetApp.app + the decrypted Mach-O
```

## Improvement Suggestions for This Package

- Add a sub-skill `ios-reverse/` (parallel to `apk-reverse/`) covering: decryption, jailbreak detection bypass, SSL pin, Keychain dump, frida-ios-dump, `+load` timing
- The existing `apk-reverse/` should not carry iOS content, to avoid confusion

## Reusable Patterns/Script Snippets

**iOS security testing quick reference**:

```text
1. Prepare the jailbroken environment (Dopamine 16.x / palera1n for older devices)
2. Decrypt with frida-ios-dump
3. Inspect class hierarchies with otool / class-dump
4. Start the objection console
5. ios jailbreak disable
6. ios sslpinning disable
7. Capture traffic with mitmproxy (system certificate + trust setting both enabled)
8. After locating the key logic, dig deeper statically with IDA / Hopper
```

## Evolution Actions
- [ ] **Suggest adding an ios-reverse skill** (the current routing matrix sends iOS to reverse-engineering/platforms.md, which is not detailed enough)
- [ ] Add frida-ios-dump to the bootstrap manifest
- [ ] Add an "iOS security testing checklist" to references/

## Environment Info
- Jailbroken device: iPhone X (iOS 16.5) + Dopamine 1.1.7
- Host: macOS 13+ / Kali (mitmproxy + frida-tools)
- frida-server-ios: 16.x

## De-identification Requirement
This entry is seed data written from public technical patterns; it involves no real target. The Bundle ID `com.target.app` is a placeholder.
