---
name: lumine-reverse-2026-05-15
description: Full reverse-engineering recovery of lumine v0.9.1, a Go 1.24.5 TLS fragmentation proxy, including source reconstruction of 7 packages
metadata:
  type: project
---

# lumine v0.9.1 — Go TLS Fragmentation Proxy Reverse Engineering

**Date**: 2026-05-15
**Target**: `lumine_v0.9.1_windows_amd64.exe` (PE32+, Go 1.24.5, 11.6 MB)
**Original write-up**: `REVERSE_REPORT.md`

## Background

The user asked to recover readable Go source code from the binary. The target is an anti-DPI TLS proxy tool whose technique originates from the Python [TlsFragment](https://github.com/maoist2009/TlsFragment).

## Process

1. **Toolchain setup**: Python + capstone disassembly, GoReSym to recover the symbol table (1944 Go functions, 269 of them from the project)
2. **Package structure identification**: inferred 12 packages from GoReSym's `package.function` naming
3. **Type recovery**: derived the JSON deserialization types from `config.json` and recovered fields using function references
4. **Source reconstruction**: wrote readable Go code package by package, preserving logic rather than restoring line by line
5. **Sub-package completion**: dial (outbound binding), errors (error types), format (string utilities)

## Key Findings

- Core anti-DPI mechanism: TLS record fragmentation + noise injection + wait for ACK + OOB + Fake TTL
- Policy engine: domain Trie + IP Trie → Policy matching
- Depends on `go-freelru` (LRU cache) for DNS/TTL caching
- The source repository `github.com/moi-si/lumine` returns 404, so recovery had to rely entirely on the binary

## Tools

| Tool | Purpose | Version |
|---|---|---|
| GoReSym | Go symbol recovery | v1.7.1 (Mandiant) |
| Capstone | Disassembly engine | latest |
| pefile | PE structure parsing | latest |

## Pitfalls

1. **Python3 path issue**: the WindowsApps stub python3 does not support pip install capstone; you need the full CPython path
2. **GoReSym subprocess path**: `~` is not expanded automatically; use `os.path.expanduser()`
3. **Mixed tabs/spaces**: the auto-generated Python decompilation scripts mixed tabs and spaces, producing malformed Go source; the v3 version fixed this by using spaces only
4. **vendor-less GoReSym**: when a Go 1.24.5 binary carries no vendor symbols, GoReSym can still extract function names, but parameters and local variables cannot be recovered
5. **String noise**: large amounts of Go standard library string constants are mixed in; careful package-level filtering is required

## Artifacts

- `REVERSE_REPORT.md` — full reverse-engineering analysis report
- `reconstructed_src_v3/` — 7 Go source files, core engine + 3 sub-packages
