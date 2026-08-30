---
name: reverse-skill-router
description: Routes reverse engineering, exploitation, penetration testing, malware, mobile, firmware, browser automation, documentation, and security tasks to the appropriate specialist skill. Use when a task spans modules or the correct reverse-skill entrypoint is unclear.
---
# Reverse Engineering Skills Master Control

This directory contains a set of reverse-engineering skill modules. Each subdirectory is a standalone module with a `SKILL.md` describing its use cases, toolchain, and workflow.

## CRITICAL: Routing Execution Contract (must run immediately)

After reading this file, replying only "read/understood" is NOT allowed. Execute in order:

1. `NOW`: run the platform-native router (Windows `scripts/master-route.ps1`; Linux/macOS/Kali `scripts/master-route.sh`) to determine PRIMARY from `config/routing.json`; for ambiguous cases, read the `routing.md` three-axis appendix.
2. `NOW`: run the platform-native `case-init` to land `work/<case>/scope.md` in the current analysis project; **no ACT on the target until auth is granted**. For local offline samples use the `offline-sample` preset + an explicit sample; Force must not bypass the hard gate.
3. `ACT`: open the PRIMARY `SKILL.md` immediately and execute its ACTION REQUIRED.
4. `NEXT`: tool paths come only from `tool-index.md`; if a tool is missing → platform-native bootstrap (manifest only).
5. Conclusions follow Evidence→Finding→Path. Reports/journals are SHOULD unless the user asks for deliverables.

**Identity**: see `ops/IDENTITY.md` (lightweight routing package + tool bootstrap + journal; **not** a Z3r0-style platform).

If routing cannot hit, first research methodology online and propose a new skill; never force the task into a mismatched module.

## Directive Semantics (RFC 2119)

- `MUST`: mandatory; violating it fails the task.
- `MUST NOT`: forbidden; violating it is a security violation.
- `SHOULD`: should be done in principle; not doing it requires an explanation.
- `MAY`: optional action.

## Current Modules

| Module | Directory | Use cases |
|------|------|---------|
| **General reverse engineering** | `reverse-engineering/` | GDB / Frida / angr / Unicorn / Qiling / anti-analysis / all-language-platform RE / CTF pattern library |
| **APK reverse engineering** | `apk-reverse/` | Android APK unpacking, jadx decompilation, smali modification, Frida hooking, repack-sign-install |
| **.NET / C# reverse engineering** | `dotnet-reverse/` | Managed PE RE, dnSpyEx + de4dot deobfuscation (ConfuserEx/SmartAssembly/Babel), IL patching, Sharp* red-team tool analysis, dnSpy MCP integration |
| **IDA Pro reverse engineering** | `ida-reverse/` | IDA Pro MCP HTTP server (72 tools): decompilation, disassembly, data-flow tracing, cross-references |
| **Frontend JS reverse engineering** | `js-reverse/` | Browser-side signing location, encrypted-param analysis, runtime sampling, Node env reproduction; prefer existing `js-reverse_*` first, plug in jshookmcp when a stronger browser/CDP/Hook surface is needed, but only after that MCP server is downloaded/registered/enabled |
| **radare2 analysis** | `radare2/` | CLI binary recon, disassembly, patching: r2 / rabin2 / rasm2 / radiff2 |
| **CTF entrypoint** | `ctf-sandbox/` | Single PRIMARY; downstream stays in sidecar `../CTF-Sandbox-Orchestrator/` |
| **Technical documentation** | `docs-generator/` | Auto-generate reverse reports, pentest reports, CTF writeups, signing-RE reports after task completion |
| **Evidence-graph review** | `case-review/` | Validate scope, Evidence→Finding→Path traceability, workitems, timeline, and artifact hashes |
| **Browser and desktop automation** | `browser-automation/` | Browser automation (Playwright) + Windows desktop app automation (OpenReverse UIA/CUA) + network observation |
| **Cross-version symbol migration** | `binary-diff/` | Migrate symbols from an old version to a new one, derive missing PDBs, batch-migrate function names after updates |
| **N-day patch-diff → exploitation** | `patch-diff-exploit/` | Locate vulnerability points from vendor patches, write PoCs, N-day weaponization (vs binary-diff: this skill is attack-side) |
| **RE → exploit chain** | `pwn-chain/` | From reverse results to a working exploit: stack/heap/kernel pwn, pwntools, libc-database, stabilization from CTF to real remote |
| **Firmware pentest chain** | `firmware-pentest/` | Nine OWASP FSTM stages: extraction→EMBA automation→Firmadyne/QEMU emulation→AFL++ fuzzing→physical exploitation |
| **EDR bypass RE** | `edr-bypass-re/` | Red-team: reverse EDR hook tables/ETW/AMSI → direct syscall / Hell's Gate / hardware breakpoints / call-stack spoofing |
| **Pentest toolchain** | `pentest-tools/` | 20+ pentest tools (Nmap/Nuclei/SQLMap/FFUF/Hashcat/Pentest Swarm etc.), exposed to AI via MCP |
| **Diagram generation** | `diagram-generator/` | Generate Mermaid/Graphviz/PlantUML diagrams from natural language (attack-path diagrams, data-flow, architecture, state machines) |
| **Attack-chain orchestration** | `attack-chain/` | Command center for multi-stage attack-path planning and execution; cross-stage tasks such as full pentests, HW drills, outside→domain-controller start here |
| **LLM/AI security testing** | `llm-security/` | OWASP LLM + ASI Top 10: prompt injection, tool abuse, memory poisoning, agent hijacking, system-prompt extraction, **agent compliance engineering** |
| **API security testing** | `api-security/` | REST/GraphQL/WebSocket full protocol: BOLA/IDOR, JWT/OAuth attacks, 10-stage methodology |
| **Supply-chain security** | `supply-chain-security/` | SBOM/SCA/CI-CD pipelines: dependency scanning, container security, build integrity, vulnerability reachability |
| **Mobile reverse engineering** | `mobile-reverse/` | Android + iOS: Frida/Objection dynamic instrumentation, SSL pinning/root/jailbreak-detection bypass, OWASP MASTG |
| **Malware analysis** | `malware-analysis/` | Six-stage sample analysis, YARA/Sigma, anti-analysis detection, sandbox orchestration |
| **DSL VM reverse engineering** | `reverse-engineering/dsl-vm-reverse/` | JS custom-instruction-set VMs (IIFE + switch-case opcode); risk-control / captcha engines etc. |
| **Operations contract ops** | `ops/` | Scope / evidence chain / roles / timeline / identity / skill supply-chain security |
| **Community skill mapping** | `references/community-security-skills.md` | External security skill index and adoption rules (no blind installs) |
| **Skill supply chain** | `ops/skill-supply-chain.md` | External skill/MCP installation gate (AST10 distilled) |
| **RE stage gate** | `reverse-engineering/references/re-agent-workflow.md` | triage→static→dynamic→synthesis |
| **Authorized recon pipeline** | `pentest-tools/references/recon-pipeline.md` | scope gate + hit ≠ verification |
| **Protocol reverse engineering** | `protocol-reverse/` | Custom binary protocols / Protobuf / gRPC / PCAP frame layouts |
| **Ghidra reverse engineering** | `ghidra-reverse/` | Open-source decompilation, headless, Ghidra MCP (main entry without IDA) |
| **Cloud / containers / K8s** | `cloud-k8s/` | IMDS/IAM, container escape surfaces, Kubernetes RBAC |
| **Windows / AD** | `windows-ad/` | Kerberos, AD CS, BloodHound, relay and domain paths |
| **Digital forensics** | `digital-forensics/` | Memory/disk timelines, PCAP attribution, IR preservation |
| **Code audit / SAST** | `code-audit/` | Semgrep/CodeQL, white-box, dangerous API and authz review |
| **Threat intel / OSINT** | `threat-intelligence/` | Public-source IOC enrichment, campaign correlation, independent verification and intel handoff |
| **Threat hunting** | `threat-hunting/` | Hypothesis-driven hunting, Sigma detection engineering, blue-team validation |
| **OT / ICS / industrial control** | `ot-ics/` | Purdue zoning, PLC/SCADA, passive-first assessment |
| **Wi-Fi / wireless** | `wifi-wireless/` | Authorized wireless assessment, handshakes/PMKID, lab rules |
| **Browser extension RE** | `browser-extension-reverse/` | Chrome/Firefox extensions, MV3 workers, permission surfaces |
| **macOS / Mach-O** | `macos-reverse/` | Codesigning, ObjC/Swift, LaunchAgent, macOS samples |
| **Thick client** | `thick-client/` | Desktop C/S, local storage, IPC, update channels |
| **Go / Rust RE** | `go-rust-reverse/` | Stripped Go/Rust, pclntab, panic strings |
| **Hardware debug interfaces** | `hardware-security/` | UART/JTAG/SWD, read-only extraction, firmware handoff |
| **Database security** | `database-security/` | MySQL/PG/MSSQL/Mongo/Redis exposure and configuration |
| **Email security** | `email-security/` | Phishing teardown, SPF/DKIM/DMARC, BEC |
| **Federated identity** | `identity-federation/` | SAML/OIDC/OAuth SSO flows and misconfigurations |
| **RF / SDR** | `radio-sdr/` | Authorized RF research, receive-only by default |

## Unified Entrypoint

For RE, CTF, packet captures, frontend signing, APK repackaging, and binary-analysis tasks, enter in this order:

1. Platform-native router (Windows `scripts/master-route.ps1`; Linux/macOS/Kali `scripts/master-route.sh`) → PRIMARY (`config/routing.json`)
2. Platform-native `case-init` → `scope.md`
3. Open the PRIMARY `SKILL.md`
4. Read `routing.md` for ambiguous cases; read `tool-index.md` when you need local tool paths

## Working Approach

These modules can be combined as needed:

1. **Get a target** → first identify the file type, pick the matching analysis tool
2. **Quick win** → strings / rabin2 -z / ltrace to look for direct clues
3. **Deep analysis** → IDA for decompilation; Frida for dynamic hooking; angr for symbolic execution
4. **Try another path when one fails** → dynamic when static fails, inspect the .so when the Java layer fails, use breakpoints when page observation isn't enough

## Next-Step Menu Pattern

Child skills MUST offer 3-6 numbered options only at a **genuine decision boundary** (two or more materially different, evidence-supported branches where the user's choice changes the next action). If the next step is uniquely determined by a gate / Evidence, the skill MUST continue directly and, per `ops/timeline-workitem.md`, record only `decision_delta` + `carry_forward_refs`; it MUST NOT re-emit unchanged route/scope/auth/context just to fabricate a menu.

Format requirements:
- Number each option (1-6 range)
- Each option describes one concrete executable action (not an abstract direction)
- At least one "export report / write writeup" option
- At least one "continue deeper analysis" or "try a different method" option
- Include a "stop / pause / ask another question" exit when needed

Example:
```
## Suggested next step (pick a number)

1. Deep-decompile sub_140001000 to recover the algorithm
2. Use Frida dynamic hooking to verify the parameter hypothesis
3. Export the currently named functions and generate a symbol-migration YAML
4. Generate an analysis report for the current stage
5. Switch to radare2 for lightweight recon comparison
6. Pause — let me confirm the evidence so far first
```

## This Directory Grows Dynamically

This directory keeps growing. When you discover a new subdirectory, read its `SKILL.md` to quickly understand its purpose.

When adding a skill, follow the standard process in `CONTRIBUTING.md`, ensuring:
- The routing matrix routes it correctly
- The bootstrap system can fill in its dependencies automatically
- tool-index reflects the new tool's status

## Related Resources

- This machine also runs an **anything-analyzer** (port 23816) MCP server providing browser automation, HTTP capture, and AI analysis
- `tool-index.md` records which local RE tools are available, their actual paths, versions, and script references
- The `Readme.md` at the package root provides generic install and integration instructions for Claude Code, Codex CLI, and other code-AI clients

## On-Demand Bootstrap

When a workflow finds a tool missing, don't error out. Unifiedly call the platform-native bootstrap:

Windows:
```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<skill-root>\scripts\bootstrap-reverse.ps1" -Capability @('tool name') -StartServices
```

Linux / macOS:
```bash
bash <skill-root>/scripts/bootstrap-reverse.sh <tool> --start-services
```

Kali:
```bash
bash <package-root>/kali/scripts/bootstrap-reverse.sh <tool> --start-services
```

Supported capabilities (per `scripts/bootstrap-manifest.json`): jadx, apktool, jeb-pro, frida, frida-ps, idalib-mcp, reqable-mcp, jshookmcp, xquik-mcp, anything-analyzer, idapro, r2, rabin2, adb, agent-browser, ghidra-mcp, seclists, proxycat, burpsuite-mcp, nmap, pentestswarm, binwalk, yara, pwntools, bkcrack

> JEB Pro is registered as a **manual-license-install** capability: bootstrap only prints guidance and NEVER downloads or circumvents commercial licensing. Reqable MCP only registers a pinned official runtime; users must still install the Reqable desktop client themselves.
>
> Tools not registered in the manifest (e.g. unblob/EMBA) MUST be installed manually via the skill docs; pretending they can be bootstrapped is forbidden.

After bootstrap completes, tool-index refreshes automatically.

## Precedent Files

Before any RE/pentest operation, MUST read in order:

| Order | File | When to read |
|------|------|--------|
| **#1** | `ops/scope-contract.md` + `case-init.ps1` | Executable auth gate. `precedent-auth.md` does not grant |
| **#2** | `field-journal/precedent-reverse.md` or `precedent-pentest.md` | On demand — load only when the AI hesitates |

**#1 upfront, #2 lazy-loaded.**

## Automatic Evolution

After every completed RE/pentest task, you MUST write back the experience to the `field-journal/` directory. See the "hard checklist after task completion" in `RULES.md`.

- Template: `field-journal/_template.md`
- Index: `field-journal/_index.md`
- Precedents: `field-journal/precedent-auth.md` → `precedent-reverse.md` → `precedent-pentest.md`
- Check index and precedents before starting new tasks; reuse accumulated experience

## Task-Completion Self-Check (MUST pass before claiming done)

- [ ] Did I complete the three-axis routing match (target type + user intent + toolchain)?
- [ ] Did I read the target skill's SKILL.md after a successful route?
- [ ] When routing missed, did I propose a new skill instead of forcing a match?
- [ ] Did I use real tool paths from `tool-index`?