# 2026-07-20 Complete Windows Reverse Toolchain Bootstrap

## Scenario Classification

Other / toolchain & environment

## Target Overview

Install and verify on a Windows 24H2 host a reverse engineering toolchain covering native, managed, Android, firmware, protocol, forensics, browser, and MCP.

## Full Execution Chain

1. Read the shared tool-index and reuse already-installed tools first.
2. Run the generic PATH probe and fill gaps in static, dynamic, firmware, and protocol tools.
3. For large files, extract URLs and SHA-256 from trusted manifests and download directly with aria2 (IPv6 disabled).
4. Establish `{user_profile}\Tools\reverse-bin` as the unified entrypoint for portable tools.
5. Build and register Ghidra, IDA, JS, browser traffic, and Burp MCP.
6. Verify tools against real PE/APK/.NET/PYC/WASM/firmware fixtures, not just version commands.
7. Refresh the shared tool-index and output a formal install report and flowchart.

## Pitfall Log

| Problem | Cause | Solution | Time |
|---|---|---|---|
| winget large-file download stuck without progress for a long time | Delivery Optimization and the default IPv6 path are unstable | Take the official URL/hash from winget metadata, use `aria2c --disable-ipv6=true` | high |
| anything-analyzer SQLite ABI mismatch | A plain `pnpm rebuild better-sqlite3` builds the Node ABI, while Electron needs the Electron ABI | Use the project's `pnpm run postinstall` | medium |
| WSL service 1053, system feature not present | The Windows image was trimmed of WSL, VirtualMachinePlatform, and Hyper-V feature packages | Keep the real Linux command gap; switch to Windows native tools and QEMU full-system | medium |
| Dr. Memory version fine but injection crashes | Windows 11 24H2 build 26100 compatibility issue | Record the upstream issue; use AppVerifier/PageHeap/UMDH/CDB/Frida | medium |
| Codex TOML fails to load | Garbled historical project paths caused missing quotes, invalid escapes, and duplicate keys | Fix only the table-header syntax and validate with `codex mcp list` | low |
| Burp MCP registered but no tools | Burp GUI hasn't loaded the extension yet; 9876 not listening | Build a pinned JAR, record the GUI loading condition | low |

## Toolchain Findings

- The generic probe ends at 57/64; all 7 gaps are Linux userspace or kernel capabilities.
- Windows SDK Debugging Tools are an important supplement when Dr. Memory is incompatible: CDB, GFlags, UMDH, NTSD, KD.
- MCP should verify "stdio/HTTP initialization" and "GUI backend online" separately; successful registration does not mean the tools are callable.
- IDA Free works for local interactive analysis, but cannot replace a legitimately licensed IDA Pro idalib/Hex-Rays MCP backend.

## Key Code/Commands

```powershell
python "{skill_root}\scripts\toolchain_probe.py" --format markdown
aria2c --disable-ipv6=true --max-connection-per-server=16 --split=16 "{official_url}"
powershell -NoProfile -ExecutionPolicy Bypass -File "{package_root}\skills\scripts\refresh-tool-index.ps1"
codex mcp list
cdb -g -G C:\Windows\System32\where.exe cmd
```

## Improvement Suggestions for This Package

- Include Dr. Memory, CDB, GFlags, UMDH, DTC, SquashFS, flashrom, and Frida Trace in the Windows tool-index catalog.
- Capability status should distinguish `installed`, `bridge-ready`, `backend-online`, and `runtime-verified`.
- For trimmed Windows editions, document the Linux-only gaps explicitly instead of generating same-named fake wrappers.

## Reusable Patterns/Script Snippets

Fixed large-file download pattern: first verify version, URL, and SHA-256 from the official package metadata, then download with aria2 and IPv6 disabled; after download, verify both the hash and Authenticode (when applicable).

## Evolution Actions

- [ ] Updated routing matrix
- [x] Updated tool-index
- [ ] Updated bootstrap-manifest
- [ ] Updated sub-skill docs
- [x] Added pitfalls record
- [ ] No update needed

## Environment Info

- OS: Windows NT build 26100.4946, 24H2, x64
- Tool versions: see the local formal install report and tool-index for details
- Target platform/version: Windows native toolchain, also covering Android, Linux/ELF static analysis, and full-system emulation

## Sanitization Requirements

This record contains no real targets, credentials, tokens, internal URLs, or usernames; all paths use placeholders.

## Index Sync

Updated the `_index.md` stats and the "Toolchain & Environment" category.

---
<!-- [Community contribution] Local record completed. -->
