# 2026-08-20 Flutter APK Server-Driven Ad Removal (Third-Party Clone Package)

## Scenario Classification
APK reverse / Flutter AOT patching

## Target Overview
A locally owned APK (`{target_app}` 1.0.8, third-party clone package): remove server-driven banner/popup ads and re-sign for output.

## Scope Summary (sanitized)
- auth_basis: user's own local file, modification for personal use
- network_profile: pure static analysis + local build, no external-system ACT
- asset_types: [android_apk, flutter_aot_libapp.so]

## Roles
- lead_role: lead
- specialists: []

## Full Execution Chain

1. Target identification: `{target}.apk` — Flutter 3.4.4 (libapp.so 13MB) + 360 packer (`com.frezrik.jiagu.StubApp`, real dex encrypted in the classes.dex tail payload, 2.58MB)
2. Static recon: apktool d / jadx → manifest has no third-party ad SDK; scanning libapp.so strings → reveals the server-driven ad system (`ad_slot_key`/`ad_show:`/`wcstream_*` slots, `system/banner/bannerListByMAcct` API)
3. Toolchain setup: prebuilt blutter from gitee is ARM64-Linux (unusable) → download blutter-unmgr source → Windows MSVC build (VS2026 BuildTools + cmake + ninja) → compile the dartvm3.4.4_android_arm64 static library (~15min) → blutter.exe analyzes libapp.so → outputs pp.txt/objs.txt/asm/ + frida scripts
4. Ad system recovery: classes `qya` (ad model, 11 fields), `pya` (banner list), `GBg` (Map<String,dynamic>→Map<String,List<qya>> parser), all slot keys and API endpoints
5. Patch design (v2 revision): **equal-length string replacement** (31 ad strings × 2 ABIs): JSON keys→garbage strings (parses to null), slot keys→garbage strings (table lookup fails), reporting tags→garbage strings. **API path strings are kept, not replaced** (after the initial version replaced them, the real device 404'd and stalled at startup; see the last pitfall row). Client stays self-consistent while the server contract breaks.
6. String table format adaptation: arm64 packed table `[0x80|(len<<1)][chars]`; armv7 object table `[len*2 u32le][chars]`. Prefix validation + longest-string-first ordering to avoid substring overlap (welfare_ad_top/welfare_ad, ad_click:/ad_click).
7. Repack: Python zipfile copying 1010 entries (replacing libapp.so×2, removing the old signature) → zipalign -p 4 → apksigner v1+v2+v3 (debug keystore)
8. Verification: Blutter re-analysis of the patched libapp.so passes (snapshot intact); apksigner verify passes; aapt badging consistent; zip diff shows only libapp.so + signature; 0 ad strings remaining in the APK
9. **Real-device runtime verification (supplement)**: install on an arm64 device → main UI opens normally, ads gone; logcat confirms zero Flutter exceptions (details in the pitfall log)

## Evidence Chain Summary
| E-id | source_type | Reusable command pattern | Related Finding |
|------|-------------|----------------|--------------|
| E-001 | blutter_out/pp.txt | `[pp+0x210a8] String: "wcstream_banner_top"` | F-001 |
| E-002 | patch script | `work/patch_libapp.py` | F-001 |
| E-003 | Blutter re-analysis | `python blutter.py <patched_dir> <out>` exit 0 | F-002 |

## Finding / Path Summary
- top_finding: For Flutter apps with server-driven ads, removing ads needs no code-logic changes — equal-length replacement of JSON keys/slot keys in the string table is enough, leaving the client internally self-consistent while the server contract fails; **but API path strings must not be replaced** (startup-flow request hits a 404 → jsonDecode exception → stalled startup)
- path_type: solve
- path_one_liner: Locate the string table → equal-length-replace ad JSON keys/slot keys (keep API paths) → repack and sign → verify on a real device via logcat

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| 360 packer: real Java dex encrypted | jadx only shows stub classes (com.frezrik.jiagu + a.*) | Ad logic lives in the Flutter Dart layer (libapp.so); no need to unpack | 0.5h |
| gitee prebuilt blutter won't run | Binary is ARM64-Linux (for Termux) | Download blutter-unmgr source and build x64 yourself | 1h |
| Windows build: cmake can't find cl | %PATH% is expanded at parse time in cmd, clobbering the vcvars environment | `cmd /V:ON` + `set PATH=...;!PATH!` delayed expansion | 0.2h |
| `string(REPLACE "/EHsc" ...)` CMake error | With CMAKE_CXX_FLAGS empty, REPLACE has too few arguments (newer CMake) | Patch in an `if(CMAKE_CXX_FLAGS)` guard (template + generated files) | 0.2h |
| Obfuscated app ad functions missing from asm (size=-1) | Blutter fails to analyze obfuscated/complex functions | Abandon code-level patching; switch to string-table replacement | 0.5h |
| Manual pool-entry reference hunting failed | Snapshot pool entries use compressed-pointer encoding, offsets relative to the pool base | Abandon hand-encoded reverse engineering; use Blutter's pp.txt directly to locate string objects | 1h |
| Substring mismatches | "welfare_ad" matched inside "welfare_ad_top" | Replace longest strings first + validate prefix bytes (arm64: 0x80\|len<<1; armv7: len*2) | 0.3h |
| ⚠️ **After replacing API paths, real device stuck on the startup logo** | The initial version also replaced `system/banner/bannerListByMAcct` → the startup ad-fetch request hit a nonexistent endpoint → server 404 (error body is not valid JSON) → startup-flow `jsonDecode` threw `FormatException` (logcat `E flutter`) → the Future entering the home page was interrupted, UI stuck on the splash forever | **Do not replace API path/URL strings**; replace only JSON keys/slot keys/reporting tags. Isolate the cause with variable isolation (re-sign a comparison package only) + `adb logcat -d \| grep "E flutter"`; MIUI install blocking needs `settings put global verifier_verify_adb_installs 0` | 1h |

## Toolchain Findings
- blutter-unmgr (gitee.com/fest_1/blutter-unmgr): prebuilt package is ARM64-Linux; the source includes `blutter.py` (Dart version auto-detection + build + run in one step)
- Blutter Windows build dependencies: VS BuildTools (with cl) + cmake (≥3.20) + ninja + ICU/capstone (auto-downloaded by init_env_win.py)
- The CMakeLists REPLACE bug needs patching (see above)

## Reusable Patterns
**Generic server-driven ad removal flow** (Flutter or native):
1. Decompile and find ad API endpoints/model keys/slot-key strings
2. Confirm the string table format (arm64 packed / armv7 object / generic length-prefixed)
3. Equal-length ASCII replacement of **JSON keys/slot keys/reporting tags** (preserving offsets) → server contract breaks; **keep API paths**
4. Repack + zipalign + apksigner (remember to strip the old signature first)
5. Install on a real device + `adb logcat` verification (watch for `E flutter` uncaught exceptions; make sure the startup flow has no 404s)
