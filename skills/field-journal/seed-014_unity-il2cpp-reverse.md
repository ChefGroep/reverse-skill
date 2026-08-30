# [Seed] Unity IL2CPP Game Reverse Engineering → Restore Metadata + Modify Logic

## Scenario Classification
Game security / mobile reverse engineering

## Target Overview
A Unity-packaged Android game (IL2CPP mode); in-game purchases or core algorithms are written in C# but compiled to native. Need to restore method names, locate key logic, and implement modifications via patching / hooking.

## Complete Execution Path

1. Unpack the APK and confirm it is IL2CPP
   ```bash
   unzip target.apk -d apk
   ls apk/lib/arm64-v8a/        # seeing libil2cpp.so means IL2CPP
   ls apk/assets/bin/Data/Managed/Metadata/
   # Key file: global-metadata.dat
   ```
2. Restore metadata with **Il2CppDumper**
   ```bash
   Il2CppDumper libil2cpp.so global-metadata.dat output/
   # Output: DummyDll/ + script.json + il2cpp.h + dump.cs
   ```
3. Run the IDA IL2CPP script (`ida_with_struct.py`) once
   - Load libil2cpp.so → File → Script File → select ida_with_struct.py → select script.json
   - IDA can now see C# method names, signatures, strings
4. Search dump.cs by business keywords (`AddCoin` / `OnPurchase` / `Verify` / `IsVip` / `CheckSign`)
5. Get the offsets of key methods → jump there in IDA to view disassembly / decompilation
6. Choose the modification approach:
   - **Static patch**: in IDA, change the check to `mov w0, #1; ret` directly
   - **Dynamic hook**: hook il2cpp methods with Frida (use Frida-Il2CppBridge)
7. Repackage verification / injection verification

## Pitfalls Record

| Issue | Cause | Solution | Time |
|------|------|---------|------|
| Il2CppDumper reports unsupported metadata version | Newer Unity changed the metadata format | Upgrade Il2CppDumper to latest / replace with Il2CppInspectorRedux | 30min |
| global-metadata.dat is encrypted | AntiCheatToolkit / custom encryption used | Find the decryption function at game init (usually near il2cpp_init) → dump with Frida after mmap | 2h |
| Method names appear in dump.cs but IDA does not match | script.json inconsistent with the .so | Must use artifacts from the same dump run; clear the IDA cache when switching IDA | 20min |
| Frida hook of IL2CPP methods errors | IL2CPP methods are not standard Java/ObjC; the method offset must be computed | Use the frida-il2cpp-bridge library instead of hand-writing Interceptor.attach | 1h |
| Game crashes after patching | File hash verification or anti-tamper | Patch out the hash-check logic too, or use a hook without modifying files | 2h |
| Startup crash after repackaging | apksigner v2 signature cannot re-sign after bytes changed | Delete META-INF + apktool b + apksigner sign in one go | 30min |

## Toolchain Findings

- **Il2CppDumper** is veteran but still the default choice
- **Il2CppInspectorRedux** is more modern, supports newer Unity, and outputs IDA / Ghidra / Binary Ninja plugin scripts
- **frida-il2cpp-bridge** is the de-facto standard for hooking IL2CPP, far stronger than raw Frida
- **DnSpy** / **dnSpyEx** for viewing DummyDll (the pseudo .NET assemblies dumped out)
- **UnityCheat**-series helper tools (GameGuardian family not covered)

## Key Code/Commands

frida-il2cpp-bridge hook example:

```typescript
// hook.ts
import "frida-il2cpp-bridge";

Il2Cpp.perform(() => {
    const Assembly = Il2Cpp.domain.assembly("Assembly-CSharp").image;

    // hook static method
    const PlayerData = Assembly.class("PlayerData");
    PlayerData.method("AddCoin").implementation = function (n: number) {
        console.log("[+] AddCoin called with:", n);
        return this.method("AddCoin").invoke(99999); // change to 99999
    };

    // hook instance method
    const Purchase = Assembly.class("Purchase");
    Purchase.method("VerifyReceipt").implementation = function () {
        console.log("[+] VerifyReceipt → always true");
        return true;
    };
});
```

```bash
# Compile + inject
npm install frida-il2cpp-bridge
frida-compile hook.ts -o hook.js
frida -U -f com.target.game -l hook.js --no-pause
```

IDA static patch:

```text
1. Open libil2cpp.so and run il2cpp_load_metadata.py
2. Jump to the offset of IsPurchaseValid from dump.cs
3. Change the function prologue to MOV W0, #1; RET (ARM64)
4. Apply Patches → Save → put back into the APK → re-sign
```

## Improvement Suggestions for This Package

- `reverse-engineering/SKILL.md` already covers Unity but lacks an IL2CPP **complete work chain** case
- Write `reverse-engineering/references/il2cpp-cheatsheet.md` as a standalone document: dump tool comparison, frida-bridge template, encrypted metadata handling
- Add frida-il2cpp-bridge to the bootstrap manifest

## Reusable Patterns/Script Snippets

**IL2CPP standard flow**:

```text
1. Confirm IL2CPP (check lib/abi for libil2cpp.so)
2. Locate the metadata (assets/bin/Data/Managed/Metadata/global-metadata.dat, possibly encrypted)
3. Restore with Il2CppDumper / Inspector
4. Bring metadata back with IDA + script
5. Search dump.cs for business keywords
6. Choose patch or hook
7. Verify (startup + real scenario)
```

**Encrypted metadata handling**:

```text
1. Hook the fopen/open syscalls with Frida to see who reads global-metadata.dat
2. After mmap/read, dump the decrypted metadata from memory
3. Feed the dumped memory to Il2CppDumper as the metadata
```

## Evolution Actions
- [ ] Add a complete il2cpp chapter to reverse-engineering/references
- [ ] Add frida-il2cpp-bridge / Il2CppInspectorRedux to the bootstrap-manifest
- [x] The routing matrix already includes Unity / IL2CPP

## Environment Information
- Windows / macOS (for running Il2CppDumper); target device Android arm64
- IDA Pro 7.7+ or Ghidra 11+
- frida-tools 16.x, frida-il2cpp-bridge 0.9+
- Unity versions: 2019.x - 2022.x (metadata format differs slightly across versions)

## Redaction Requirements
This entry is seed data written from public technical patterns and does not involve any real game. The package name `com.target.game` is a placeholder.