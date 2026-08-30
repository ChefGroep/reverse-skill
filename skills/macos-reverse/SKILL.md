---
name: macos-reverse
description: Use for authorized macOS and Mach-O reverse engineering including codesign, Objective-C/Swift recovery, endpoint security surfaces, and Apple platform malware analysis.
---

# macOS / Mach-O Reverse Engineering

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md`
2. `NOW`: Confirm the target is a macOS/Mach-O/App bundle (iOS IPA → `mobile-reverse/`)
3. `NEXT`: tool-index; jtool2/lldb, etc.
4. `ACT`: Signature and loading info → static → dynamic (lldb/Frida)

## When to Use

- Mach-O executables / dylibs / frameworks
- .app bundles, LaunchAgents/Daemons
- Objective-C / Swift symbols and runtime
- Notarization/signing, Hardened Runtime, TCC-related behavior analysis
- macOS malware static/dynamic analysis (pair with malware-analysis)

## Workflow

### 1. Bundle and Signature

```bash
file target
codesign -dv --verbose=4 target
spctl -a -vv target 2>&1
otool -L target
```

### 2. Static

```text
□ class-dump / swift-demangle / Hopper / Ghidra / IDA
□ Strings and XPC service names, sensitive TCC APIs
□ LC_LOAD_dylib dependencies and rpath
```

### 3. Dynamic

```text
□ lldb / Frida
□ fs_usage / log stream observation
□ Network: pair with protocol-reverse or a proxy
```

## Toolchain

| Tool | Purpose |
|------|---------|
| otool / nm / codesign | Ships with the system |
| Hopper / Ghidra / IDA | Decompilation |
| class-dump / dsdump | ObjC |
| Frida / lldb | Dynamic |
| jtool2 | Mach-O |

## References

- `references/macho-triage.md`
- `../mobile-reverse/` (iOS), `../ghidra-reverse/`, `../malware-analysis/`

## Routing Context

**Upstream**: MASTER R31  
**Downstream**: iOS → mobile-reverse; generic samples → malware-analysis

## Completion Self-Check

- [ ] Signature/Hardened Runtime status recorded?
- [ ] Address-level/symbol-level conclusions?
- [ ] Checklist done?
