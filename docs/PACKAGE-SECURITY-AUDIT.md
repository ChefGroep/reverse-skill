# reverse-skill In-Package Security Audit (Executable Surface)

> Date: 2026-08-02
> Scope: executable scripts and the bootstrap manifest across `skills/**/scripts`, `skills/scripts`, `kali/scripts`, `burp-mcp-full`  
> **Excludes**: `src-hunter` / payloader and similar **educational payload documents** (their DROP/injection samples are methodology, not auto-executed)

## Conclusions (Overall)

| Level | Verdict |
|------|------|
| **Backdoors / deliberate database wiping / disk formatting** | **Not found** |
| **Piped download-and-execute (curl\|sh / IEX DownloadString)** | **Not found** |
| **Hardcoded cloud keys / private keys** | **Not found** (the `sk-` / `BEGIN RSA` strings in docs are detection examples) |
| **Residual supply-chain risk** | **Partially hardened (medium-low → low)**: `@latest` pinned; GitHub downloads now support **manifest SHA256 + API digest** |

**Overall: the executable skill-script surface currently shows no implanted backdoors or "one-click database wipe" logic; dangerous deletions are confined to tool-reinstall temp directories / case output directories.**

### 2026-07-18 Hardening (This Commit)

| Item | Action |
|----|------|
| jshookmcp | `@latest` → `@0.3.4` |
| pentestswarm | `@latest` / docker `:latest` → `@v0.1.0` / `:v0.1.0` |
| jadx | pin `v1.5.6` + `assetSha256` |
| apktool | pin `v3.0.2` + `assetSha256` |
| bootstrap PS/sh | After download, `Assert-DownloadedFileIntegrity` / `verify_sha256`; prefer manifest hashes, fall back to the GitHub `digest`; on failure delete the file and abort |
| Releases without a pinned hash | Still installable, but **WARN** and print the actual sha256 |

### 2026-08-02 Security Fixes

| Item | Fix |
|----|------|
| Kali quick setup | Use `getent` to resolve the sudo user's home; removed `eval` |
| Frida process listing | Use a `frida-ps` argument array; removed inline Python string concatenation |
| Burp MCP token | Atomic replacement via a restricted temp file; POSIX file permissions fixed at `0600` |
| Burp MCP bridge | Parse newline-delimited MCP messages and reconnect on demand after Burp starts |
| Anything Analyzer MCP | Bearer auth enabled by default in bootstrap; credentials registered through an optional host adapter |
| IDA MCP startup | Kill stale processes one by one, avoiding multi-PID argument expansion errors |

## Scan Method

For executable extensions (`.ps1` / `.sh` / `.py` / `.js` / `.java`), search for:

- `Invoke-Expression` / `IEX` / `FromBase64String` / `DownloadString`
- `curl|bash` / `wget|sh` pipe-to-shell execution
- `DROP DATABASE|TABLE`, `rm -rf /`, `Remove-Item ... C:\Windows`
- Reverse-shell patterns (`/dev/tcp` abuse, `TcpClient` callbacks)
- Hidden-window launches (re-checked for intent)

Second pass: manual reading of `bootstrap-reverse.ps1/.sh` download and delete paths, `mcp-bridge.js`, and the charting/cryptography Python scripts.

## Detailed Findings

### 1. Deletion Operations (All Expected Cleanup, Not Database Wipes)

| Location | Behavior | Risk |
|------|------|------|
| `bootstrap-reverse.ps1` `Expand-ArchiveIntoDirectory` | Deletes the target install directory and reinstalls; deletes `%TEMP%\reverse-bootstrap-*` | Tool install paths only, not user data |
| `bootstrap-reverse.ps1` anything-analyzer | On failure, `Remove-Item node_modules` then `pnpm install` | Confined to the cloned tool repo |
| `apk-reverse/scripts/decode.*` | Cleans task output directories jadx/apktool out | Confined to the task root |
| `case-init.ps1` | Cleans temp directories | Temp only |
| `bootstrap-reverse.sh` | Same class of temp / install-target cleanup | Same as above |

**Not found**: any executable `DROP`/`TRUNCATE` logic targeting `C:\`, system directories, or arbitrary database connection strings.

### 2. Network Behavior (Tool Bootstrapping, Not C2)

| Location | Behavior | Notes |
|------|------|------|
| `bootstrap-reverse.ps1` | Pulls releases from `api.github.com`; downloads zip/jar via `Invoke-WebRequest` | Repository names come from the **manifest whitelist** |
| `bootstrap-reverse.sh` | `curl` / `git clone` / `pipx` / `npm` | Same as above |
| `mcp-bridge.js` | Only `127.0.0.1:9876` HTTP → Burp | Local loopback |
| `ToolDiscovery.ps1` | Probes `http://host:port/mcp` | Health check |
| `kali/.../tool-discovery.sh` | `(echo >/dev/tcp/$host/$port)` | **Port probing**, not a reverse shell |

### 3. Hidden Windows

| Location | Purpose |
|------|------|
| `bootstrap-reverse.ps1` `Start-Process ... -WindowStyle Hidden` | Starts `pnpm dev` in the background (anything-analyzer) |
| `ida-reverse/scripts/start.ps1` | Starts IDA-related processes (must stay in the background) |

This is service-launch behavior; no hidden download of malicious payloads was found.

### 4. "Dangerous Wording" in Docs / Payloads (Not Auto-Executed)

`pentest-tools/src-hunter`, `attack-chain`, and similar **Markdown/JSON teaching material** contain SQL injection, `DROP` examples, and log-cleaning **red-team methodology**.  
These are **not executed automatically by bootstrap or master-route**; execution depends on the AI/human choosing them under an **authorized scope**.

Related constraints: `ops/scope-contract.md`, `ops/skill-supply-chain.md`, `field-journal/precedent-*.md`.

### 5. Residual Supply-Chain Risk (Recommended Future Hardening, Not a Proven Backdoor)

| Item | Risk | Recommendation |
|----|------|------|
| `@jshookmcp/jshook@0.3.4`, `pentestswarm@v0.1.0` in `bootstrap-manifest.json` | Tag drift / supply-chain poisoning surface | Pin version numbers + checksums |
| GitHub release zips have **no SHA256 verification** | A swapped release would go unnoticed | Add `assetSha256` to the manifest and verify it in bootstrap |
| `npm install -g` / `pip` default registries | Inherent dependency-ecosystem risk | Install only manifest capabilities; use a private registry/lockfile in production |

## Executable Script Inventory (Audit Baseline)

```
skills/scripts/*.ps1|*.sh + lib/ToolDiscovery.ps1
skills/apk-reverse/scripts/*
skills/radare2/scripts/*
skills/ida-reverse/scripts/*
skills/browser-automation/scripts/*
skills/diagram-generator/scripts/*.py
skills/case-review/scripts/*.py
kali/scripts/*
burp-mcp-full/mcp-bridge.js (+ Java extension sources)
```

## Recommended Ongoing Checks

```powershell
# Quick health check of the executable surface (example)
rg -n "Invoke-Expression|FromBase64String|DownloadString|rm -rf /|DROP DATABASE" skills/scripts skills/*/scripts kali/scripts burp-mcp-full -g "*.ps1" -g "*.sh" -g "*.py" -g "*.js"
```

New skills with **executable scripts** should re-run this checklist before merging; Markdown-only methodology changes are exempt.

## Sign-Off

- Audit execution: repository-local static scanning + manual review of key paths  
- Result: no backdoors / no automatic database wiping; supply-chain hardening listed as a follow-up improvement item
