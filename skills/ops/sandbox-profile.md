# Optional Sandbox Tool Profile (Cross-Reference with bootstrap-manifest)

> The default Z3r0 image is comprehensive; reverse-skill **does not bundle an image** — use this table for "coverage comparison" and optional Docker suggestions.

## Capabilities reverse-skill Can Auto-Bootstrap

Source: `skills/scripts/bootstrap-manifest.json` (the file is authoritative):

| Capability | Typical Scenario |
|------|----------|
| jadx / apktool / adb / frida / frida-ps | Android |
| r2 / rabin2 | Binary CLI |
| idalib-mcp / idapro | IDA MCP |
| jeb-pro | Commercial Android / ARM decompiler (manual licensed install) |
| jshookmcp / reqable-mcp / anything-analyzer / agent-browser | Web/JS/traffic capture/browser |
| ghidra-mcp | Ghidra |
| nmap / seclists / proxycat / burpsuite-mcp / pentestswarm | Pentest |
| binwalk / pwntools / yara | Firmware/pwn/malware |

```powershell
powershell -File skills\scripts\bootstrap-reverse.ps1 -Capability @('jadx','nmap','yara') -StartServices
powershell -File skills\scripts\refresh-tool-index.ps1
```

## Common in the Z3r0 Sandbox but Not Auto-Installed by This Package's Manifest

| Tool | reverse-skill Policy |
|------|-------------------|
| subfinder / amass / httpx / ffuf / nuclei / sqlmap | Documented install / Kali script / external MCP; **do not pretend the bootstrap already has them** |
| Full Ghidra GUI | ghidra-mcp capability + manual plugin steps |
| gdb / pwndbg | Manual per platform docs; pwntools can be bootstrapped |
| hydra / hashcat | Manual or Kali |
| JEB Pro | Manual install after the user holds a license; any third-party MCP bridge must pass a supply-chain review first |
| Reqable desktop client | Manual install by the user; `reqable-mcp` only registers the official pinned-version MCP runtime |
| SecLists | seclists capability |

## Recommended "Lightweight Docker Ops" Profile (Optional, Not a Dependency)

Only when the user **themselves** has Docker and an authorized lab:

```text
Minimum: nmap + nuclei + sqlmap containers or a pentestMCP-style image
Mobile: jadx + apktool + frida on the host
Reverse: host IDA/r2 + tool-index
```

**MUST NOT** require the user to install Z3r0 in order to use reverse-skill.

## network_profile Interaction

Scans inside the sandbox remain bound by the case `scope.md`'s `network_profile`:

- `offline` → starting outbound-scanning containers is not recommended  
- `authorized_target_only` → containers may only target in_scope
