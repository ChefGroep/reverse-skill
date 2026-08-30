# reverse-skill — Platform-Independent Project Entry

This repository is a **security task skill-routing package** (reverse engineering / penetration testing / security analysis). `RULES.md` is the single source of truth for the behavior chain.

## Routing

When a user task matches a security/reverse keyword:

1. `skills/MASTER-ROUTING.md` or the platform entry point → PRIMARY:
   - Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File skills/scripts/master-route.ps1 -Hint "<task>"`
   - Linux / macOS / Kali: `bash skills/scripts/master-route.sh --hint "<task>"`
2. When ambiguous, read the full `skills/routing.md` matrix (three axes: target type / user intent / toolchain)
3. Single source of truth for routing rules: `skills/config/routing.json` (change routing only here)

## Authorization Gate (Hard)

- Before touching any target, initialize the current analysis project's `work/<case>/scope.md` per platform:
  - Windows: `powershell -File skills/scripts/case-init.ps1 -Hint "<task>"`
  - Linux / macOS / Kali: `bash skills/scripts/case-init.sh --hint "<task>"`
- Local offline samples may use the `offline-sample` preset; `auth.status=granted` + an explicit sample are required before entering ACT.
- ACT is forbidden until `auth.status=granted` + a valid `network_profile` / offline sample is ready; `case-guard --force` / `-Force` must never bypass this hard gate.
- Evidence chain: `skills/ops/evidence-finding-path.md`; roles: `skills/ops/role-map.md`

## First Run

`skills/tool-index.md` is a gitignored generated file. Before first use, run it per platform:

```text
Windows:           powershell -NoProfile -ExecutionPolicy Bypass -File skills/scripts/refresh-tool-index.ps1
Linux / macOS:     bash skills/scripts/refresh-tool-index.sh
Kali:              bash kali/scripts/refresh-tool-index.sh
```

Missing tools → use the same-platform bootstrap: Windows `skills/scripts/bootstrap-reverse.ps1`; Linux / macOS `skills/scripts/bootstrap-reverse.sh`; Kali `kali/scripts/bootstrap-reverse.sh` (manifest capabilities only, never guess paths).

## Tests (MUST run after changes)

```text
Windows / PowerShell (routing regression reads routing-benchmark.json):
  powershell -NoProfile -ExecutionPolicy Bypass -File skills/scripts/test-routing.ps1
  powershell -NoProfile -ExecutionPolicy Bypass -File skills/scripts/verify-routing-coherence.ps1
  powershell -NoProfile -ExecutionPolicy Bypass -File skills/scripts/smoke.ps1

Linux / macOS routing parity:
  bash skills/scripts/test-routing.sh
  bash skills/scripts/test-bootstrap-manifest.sh
```

## Client Boundary

- The routing core, tests and tool manifest must stay decoupled from any specific AI client.
- Claude Code, Codex, Cursor, OpenCode and other clients may only connect through their own adapter layer, and must never become the repository's default identity or core-configuration dependency.
- `skills/INDEX.md` is generated dynamically by `extract-summaries.ps1` from every `SKILL.md`; no clients or module counts are hardcoded.