# 2026-07-14 Android ARM64 Self-Extracting Program Source Recovery

## Scenario Classification

Binary analysis / Android ARM64 / self-extracting shell / control-flow flattening

## Target Overview

Perform read-only source recovery on the user's own local `.sh` delivery package: peel out multi-layer compressed payloads, analyze the ARM64 main program and protection library, and recover business text and high-level pseudo source without running the target.

## Complete Execution Path

1. Triage the input directory read-only for inventory, sizes, magic numbers, and SHA-256; do not read or record credentials in plaintext.
2. Identify layer 1 as "shell preamble + bzip2 trailing stream" and locate the exact offset via a valid `BZh` stream test.
3. Save the preamble, compressed stream, and decompressed payload in a separate clean artifact directory; never execute the payload.
4. Identify layer 2 as the `__ARCHIVE_BELOW__` self-extracting script and safely expand the tar.gz, rejecting absolute paths, `..`, links, and device nodes.
5. Obtain the Android AArch64 PIE main program and AArch64 shared libraries; use pyelftools/Capstone to produce the ELF header, sections, symbols, imports, strings, and entry disassembly.
6. The protection library retains readable C++ symbols; export pseudo-code per function and confirm `/proc` scanning, `TracerPid`, three-stage process termination, and background-thread behavior.
7. The `main` symbol length in the main program is clearly larger than the normal CFG-recognized length, confirming indirect-jump control-flow flattening.
8. Statically solve the jump table: `target = table_entry + fixed_delta`; enumerate all unique real basic blocks.
9. Scan for homogeneous string decryptors and identify the "first N bytes repeating XOR key + next M bytes ciphertext" layout.
10. Run AArch64 constant propagation on every real basic block, resolve the target and `x1` data source of indirect decryptor calls, and recover business text in bulk.
11. Deliver the complete disassembly, per-function pseudo-code, high-level semantic source, Mermaid flowcharts, and a formal report.
12. Recompute the original input hash and confirm it is identical before and after analysis.

## Pitfalls Record

| Issue | Cause | Solution | Time |
|---|---|---|---|
| Bootstrap run directly in PowerShell blocked by the execution policy | System forbids scripts | Use a one-off `powershell.exe -ExecutionPolicy Bypass -File ...`; do not change the permanent policy | Low |
| radare2 bootstrap returns GitHub API 403 | API rate-limited/rejected, but the release page is accessible | Get official assets and the page SHA-256 from the `releases/latest` 302 and `expanded_assets/<tag>`; verify then unzip | Medium |
| winget Rizin silent/user-scope installs both failed to land | Installer scope mismatch | Stop retrying after two failures; switch back to the verified radare2 official ZIP | Low |
| `r2pm -U` stuck for a long time on git clone | Network speed / recursive repositories | Abandon the optional plugin route; keep using `pdc` + Capstone custom recovery | High |
| radare2 only recognizes the `main` prologue CFG | An indirect BR jump table makes normal analysis end at the dispatcher | Enumerate real blocks with the jump-table formula instead of relying on default CFG | Medium |
| Direct string scanning only reveals a few paths | Each string uses its own repeating XOR | Extract key/output lengths from the decryptor instructions and statically replay the algorithm | Medium |

## Toolchain Findings

- The Python 3.13 standard library safely handles bzip2 and tar.gz; `tarfile.extractall` is not as safe as verifying and writing members one by one.
- pyelftools can recover ELF/DYNSYM/RELA; Capstone suits ARM64 constant propagation and dedicated decryptor recognition.
- radare2 6.1.8 `pdc` works on un-obfuscated protection-library functions but only yields local pseudo-code for the indirect-BR flattened main function.
- A GitHub API 403 does not mean official release-page assets are inaccessible; the release page can provide the tag, asset names, and SHA-256.

## Key Code/Commands

```python
# Generic repeating XOR text layout
key = blob[:key_length]
encrypted = blob[key_length:key_length + output_length]
plain = bytes(value ^ key[index % key_length]
              for index, value in enumerate(encrypted))
```

```python
# Indirect jump table static solve
targets = {
    (entry + fixed_delta) & 0xFFFFFFFFFFFFFFFF
    for entry in jump_table_entries
}
```

```powershell
# Read-only fetch of the latest tag when the API returns 403
curl.exe -sS -I '<official-release-url>/radareorg/radare2/releases/latest'
```

## Improvement Suggestions for This Package

- Add a "`.sh` self-extracting disguised binary" target-type route to avoid misjudging it as a pure shell review.
- The Windows GitHub Release bootstrap should fall back to the release page/expanded_assets on API 403 and enforce SHA-256 verification.
- Add a generic "ARM64 jump table + repeating XOR" recovery script template as a low-dependency route when IDA is unavailable.
- When a tool call outlives the foreground window, retain the session id and poll so still-running downloads or export tasks are not lost.

## Reusable Patterns/Script Snippets

1. Scan for valid compressed streams first rather than only looking for magic numbers; fully test decompression in memory for every candidate offset.
2. Always write self-extracting archive members out safely one by one; never execute directly or trust member paths.
3. When the symbol-table-declared function length far exceeds the CFG-recognized length, check BR/BLR indirect tables first.
4. Homogeneous decryptors can be recognized in bulk via combinations of `add x16,x1,#key_len`, `cmp w16,#output_len`, and `ldrb/eor/strb` instructions.
5. Local constant propagation on flattened blocks is usually enough to recover indirect call targets and string source addresses; no full de-flattening needed first.

## Evolution Actions

- [x] Updated the routing matrix
- [x] Updated tool-index
- [ ] Updated bootstrap-manifest
- [ ] Updated child skill documentation
- [x] Added a pitfalls record
- [ ] No update needed

## Environment Information

- OS: Windows
- Tool versions: Python 3.13; radare2 6.1.8; pyelftools; Capstone
- Target platform/version: Android ARM64, NDK r17 / Clang 6.0.2

## Redaction Check

- No software names, author names, real domains, real API endpoints, credentials, fixed signing material, business package names, or local user paths were recorded.
- No sample files or sample hashes attached.
- Only public tool names, versions, and generic algorithm patterns retained.

## Index Sync

Added this record under the "Binary / Firmware / CTF" category in `_index.md` and updated the statistics.

---
<!-- [Community contribution] When done, ask the user whether to PR to the main repo. Process in CONTRIBUTE-BACK.md -->