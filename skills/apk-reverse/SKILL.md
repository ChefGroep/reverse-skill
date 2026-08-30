---
name: apk-reverse
description: Use when performing Android APK reverse engineering in a CLI environment. Covers APK unpacking, Java decompilation (decompileren), smali modification, repackaging, Frida dynamic hooking, and switching to so/native analysis on demand. Prefers locally installed jadx, apktool, frida, adb, ida-reverse, radare2.
---

## ACTION REQUIRED (execute immediately after reading)

> For community-skill cross-references such as endpoint extraction and Frida adaptation: ../references/community-security-skills.md; dynamic analysis requires a device authorized in scope.

1. `NOW`: read `../field-journal/precedent-reverse.md` — confirm this skill's operations are authorized routine operations
2. `NOW`: confirm the current task falls within this skill's scope
3. `NEXT`: read `../tool-index.md` and verify tool availability and real paths
4. `NEXT`: when a tool is missing, call bootstrap; do not guess paths
5. `ACT`: move to step 1 of the workflow and execute it; do not stay in a confirmation state

# APK Reverse Engineering CLI Playbook

## Scope

Prefer this skill when the task involves:

- Analyzing the Java business logic of an APK
- Locating login, signature, fraud/risk-control, certificate validation, and root detection
- Viewing and modifying `AndroidManifest.xml`
- Viewing and modifying smali
- Repackaging the APK
- Dynamic Java/native hooking with Frida
- Switching to native analysis when the APK contains `.so`

## CLI tools verified on the current machine

- `jadx` `1.5.5`
- `apktool` `3.0.2`
- `frida-ps` `17.9.6`
- `adb`
- `java`

## When to prefer the bundled scripts

The following flows are frequent and error-prone in their parameters; prefer the skill's bundled scripts:

- Run `jadx` + `apktool` in one pass, write to disk, and produce a summary: `scripts/decode.ps1`
- Frida device checks, process listing, spawn/attach injection: `scripts/frida-run.ps1`
- Rebuild, align, sign, and install the APK: `scripts/rebuild-sign-install.ps1`
- Quickly extract key manifest components and permissions: `scripts/manifest-summary.ps1`

The following one-liners stay as direct invocations and are not wrapped separately:

- `adb devices`
- `adb logcat`
- `frida-ps -U`
- `jadx --version`
- `apktool --version`

## Bundled scripts

### `scripts/decode.ps1`

Purpose:

- Runs `jadx` and `apktool` through one entry point
- Creates the task output directory next to the original APK by default
- Emits a summary with `package`, `java_files`, `smali_dirs`, `so_files`, and more
- Tolerates `jadx` partial decompilation errors while still having usable artifacts

Examples:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\decode.ps1" -ApkPath "D:\DOWNLOAD\app.apk" -Clean
pwsh -File "<skill-root>\apk-reverse\scripts\decode.ps1" -ApkPath "D:\DOWNLOAD\app.apk" -Name demo -SkipJadx
```

### `scripts/frida-run.ps1`

Purpose:

- Single entry point for Frida devices, processes, and spawn/attach
- Avoids confusing `-f`, `-n`, `-U` when writing parameters by hand

Examples:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\frida-run.ps1" -ListDevices
pwsh -File "<skill-root>\apk-reverse\scripts\frida-run.ps1" -Usb -ListProcesses
pwsh -File "<skill-root>\apk-reverse\scripts\frida-run.ps1" -Usb -Spawn -Package com.example.app -ScriptPath "D:\hooks\test.js"
```

### `scripts/rebuild-sign-install.ps1`

Purpose:

- `apktool b` rebuilds the APK
- `zipalign` aligns it
- `apksigner` signs and verifies
- Optionally installs directly via `adb install`

Examples:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\rebuild-sign-install.ps1" -ProjectDir "C:\work\apktool_out" -Clean
pwsh -File "<skill-root>\apk-reverse\scripts\rebuild-sign-install.ps1" -ProjectDir "C:\work\apktool_out" -Install -Reinstall -DeviceSerial "127.0.0.1:7555"
```

Notes:

- Generates and reuses a debug keystore by default
- Outputs next to `ProjectDir` by default, keeping it together with the original package and unpacked directory

### `scripts/manifest-summary.ps1`

Purpose:

- Extracts the package name
- Lists permissions
- Lists activity/service/receiver/provider
- Marks the main launcher activity

Examples:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\manifest-summary.ps1" -ManifestPath "C:\work\apktool_out\AndroidManifest.xml"
```

When analyzing `.so`, `lib/arm64-v8a/*.so`, `lib/armeabi-v7a/*.so`, also combine with:

- `ida-reverse`
- `radare2`

## Tool division of labor

### `jadx`

Used for:

- Reading decompiled Java
- Searching package, class, and method names
- Understanding the APK from high-level logic first

Common commands:

```bash
jadx -d jadx_out app.apk
jadx --single-class com.example.LoginActivity -d jadx_out app.apk
jadx --deobf -d jadx_out app.apk
```

### `JEB Pro` (optional commercial tool)

Used for:

- Cross-validation and deep decompilation of Android DEX / APK / ARM
- Supplementing static analysis when JADX output is incomplete or heavily obfuscated
- Second-toolchain verification of classes, methods, and call relationships on the same target

Boundaries:

- JEB Pro is commercial software; the user must obtain and install a valid license themselves. This package does not download, crack, or circumvent licensing.
- Invoke only when `tool-index` confirms local JEB availability; otherwise keep using `jadx`, `apktool`, Ghidra, IDA, or radare2.
- A third-party JEB MCP bridge is not a package dependency. Before installation, review its source, permissions, network behavior, and version per `../ops/skill-supply-chain.md`, and have the user explicitly confirm registration.

### `apktool`

Used for:

- Unpacking the APK
- Viewing and modifying `AndroidManifest.xml`
- Viewing and modifying smali
- Rebuilding the APK

Common commands:

```bash
apktool d app.apk -o apktool_out
apktool b apktool_out -o rebuilt.apk
```

### `frida`

Used for:

- Observing Java method calls dynamically
- Hooking native exported functions
- Bypassing root detection, certificate validation, and debug detection

Common commands:

```bash
frida-ps -U
frida -U -f com.example.app -l hook.js
frida-trace -U -f com.example.app -j '*!*certificate*'
```

### `adb`

Used for:

- Device connection
- Installing the APK
- Reading logs
- Pulling files

Common commands:

```bash
adb devices
adb install -r app.apk
adb shell pm list packages
adb logcat
adb pull /data/local/tmp/file .
```

## Recommended workflow

### 1. Triage

First establish the APK's overall composition; do not rush into patching or hooking.

Suggested actions:

1. Export Java code with `jadx -d jadx_out app.apk`
2. Export smali and resources with `apktool d app.apk -o apktool_out`
3. Look first at:
   - `AndroidManifest.xml`
   - the main `package`
   - `application`, `activity`, `service`, `receiver`
   - whether `lib/` contains `.so`
4. Issue #65 threat-pattern quick reference (authorized samples/devices; details in `../reverse-engineering/references/nonpe-format-cookbook.md` §7–8):
   - Transparent/hidden icons (AU): `aapt dump badging` + manifest theme/label/icon → `E-android-hidden-icon-manifest`
   - Magisk/script-based device-wipe traits and remote `curl|sh` (AR/AS) → record traits and URLs as evidence; do **not** execute destructive commands
   - Persistence paths (AT): `service.d` / `priv-app` and similar → `E-android-persistence`

### 2. Java logic observation

Read from `jadx_out` first:

- `MainActivity`
- `Application`
- login, network, crypto, and fraud-control related classes
- third-party SDK initialization classes

Common keywords:

- `login`
- `sign`
- `encrypt`
- `cipher`
- `token`
- `root`
- `certificate`
- `trust`
- `okhttp`
- `retrofit`
- `webview`

If the Java code is readable, locate the business logic here first.

### 3. Smali and resource layer confirmation

When `jadx` results are incomplete, heavily obfuscated, or an actual patch is needed, switch to `apktool_out`:

- Inspect `smali*/`
- Inspect `res/values/strings.xml`
- Inspect `AndroidManifest.xml`

Prefer patching:

- `android:exported`
- debug flags
- root-detection return values
- login validation logic
- certificate validation branches

### 4. Rebuild and install

After modifications:

```bash
apktool b apktool_out -o rebuilt.apk
```

Or close the loop directly with the script:

```powershell
pwsh -File "<skill-root>\apk-reverse\scripts\rebuild-sign-install.ps1" -ProjectDir "apktool_out" -Install -Reinstall -DeviceSerial "127.0.0.1:7555"
```

Notes:

- This skill only guarantees the `apktool` rebuild chain
- A proper install on a device usually also requires a signing flow
- If the task enters signing/alignment, add `apksigner` / `zipalign`

### 5. Dynamic hooking

When static analysis is insufficient, use Frida:

- Hook login functions
- Hook key points in `OkHttp` / `Retrofit` / `WebView`
- Hook `javax.crypto`, `MessageDigest`
- Hook root-detection functions
- Hook SSL pinning logic

Principles:

- Hook the Java layer first, then judge whether native hooking is needed
- Print arguments and return values first, then decide whether to actively modify return values

Recommendations:

- Simple one-shot commands go directly through `frida-*`
- For reusable injection flows prefer `scripts/frida-run.ps1`

### 6. Native `.so` routing

If the APK contains critical `.so`:

- Locate `lib/**/*.so` with `apktool` or `jadx`
- For export symbols, strings, and quick triage, `radare2` suffices
- For long-term deep analysis, decompilation, renaming, and type recovery, use `ida-reverse`

Switch to native quickly on these signals:

- The Java layer is only a JNI wrapper
- Core signature logic is not in Java
- Critical logic disappears after `System.loadLibrary()`
- Certificate validation / fraud control lives in the `.so`

## Output requirements

The final output must at least state:

- Entry components and key classes
- Whether key logic lives in Java, smali, or `.so`
- Confirmed sensitive points: login, signature, root, SSL, WebView, JNI
- If patched, what was changed
- If hooked, which class/method/exported function was hooked

## Do not

- Do not blindly patch smali right away
- Do not write hooks before reading the manifest and main entry point
- Do not equate incomplete Java decompilation with "logic is unanalyzable"
- Do not keep grinding the Java layer when the `.so` clearly carries the core logic

## Quick command reference

```bash
# Decompile Java
jadx -d jadx_out app.apk

# Unpack the APK
apktool d app.apk -o apktool_out

# Rebuild the APK
apktool b apktool_out -o rebuilt.apk

# Devices and processes
adb devices
frida-ps -U

# Spawn and inject
frida -U -f com.example.app -l hook.js
```

---

## Routing context

**Upstream entry**: `skills/SKILL.md` (master control), `routing.md`
**Downstream exits**:
- Core logic in `.so` → `ida-reverse/` or `radare2/`
- Dynamic hook/verification needed → `reverse-engineering/tools-dynamic.md` (Frida chapter)
- General reverse methodology → `reverse-engineering/SKILL.md`

**Peer modules**: `reverse-engineering/` (.so analysis and advanced Frida usage)

---

## On-Demand Bootstrap

This skill's entry scripts are wired into the unified bootstrap system. When a tool is missing, they do not fail outright but attempt automatic installation.

### Automation capability boundaries

| Tool | Auto-install | Install method | Notes |
|------|-----------|---------|------|
| jadx | ✓ | GitHub Release ZIP | Auto-downloads and extracts to `%USERPROFILE%\Tools\jadx\` |
| apktool | ✓ | GitHub Release JAR + wrapper | Auto-downloads the jar and generates a bat wrapper to `%USERPROFILE%\Tools\apktool\` |
| JEB Pro | ✗ | User installs manually with a valid license | Optional Android / ARM cross-validation tool; third-party MCP bridges need a separate audit |
| frida / frida-ps | ✓ | pip install frida-tools | Requires Python installed |
| adb | ✓ | winget / fallback path | Auto-installs Android Platform-Tools |
| zipalign | ✗ | Requires manual Android Build-Tools install | `sdkmanager "build-tools;35.0.0"` |
| apksigner | ✗ | Requires manual Android Build-Tools install | same as above |

### Bootstrap trigger points

- `scripts/decode.ps1`: auto-invokes `bootstrap-reverse.ps1` when jadx or apktool is missing
- `scripts/rebuild-sign-install.ps1`: auto-invokes bootstrap when adb or apktool is missing
- `scripts/frida-run.ps1`: currently a manual check (frida is usually installed via pip)

### When bootstrap fails

If automatic installation fails, the script raises a clear error with manual-install links. Common causes:
- No network (GitHub API / PyPI unreachable)
- winget unavailable (Windows version too old)
- Java not installed (apktool requires a JDK)


## Task completion checklist (MUST pass before claiming done)

- [ ] Did I execute every step of the workflow (rather than only reading)?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/report)?
- [ ] Did I complete and write back the checklist items RULES requires?
- [ ] If hidden-icon/device-wipe/persistence clues were hit: did I record `E-android-*` evidence per the U–AV cookbook (within authorization)?
