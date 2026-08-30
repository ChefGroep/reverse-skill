# Domain coverage map for this package (depth first)

> Compared with the community's "hundreds of micro-skills": we cover the main battlefield with **a few deep skills + routing + ops**.  
> Date: 2026-07-18

## Domain → entry point in this package

| Domain | PRIMARY / module | Notes |
|----|----------------|------|
| Mobile Android | `apk-reverse/` `mobile-reverse/` | |
| Mobile iOS | `mobile-reverse/` | |
| Binary deep-dive | `ida-reverse/` `radare2/` `ghidra-reverse/` | Ghidra = the open-source main path |
| General RE / anti-debug / OLLVM | `reverse-engineering/` | |
| .NET | `dotnet-reverse/` | |
| Front-end JS / signatures | `js-reverse/` | |
| Browser extensions | `browser-extension-reverse/` | |
| DSL / risk-control VM | `reverse-engineering/dsl-vm-reverse/` | |
| Protocols / PCAP protocol recovery | `protocol-reverse/` | |
| Firmware / IoT | `firmware-pentest/` | |
| Malicious samples | `malware-analysis/` | |
| Digital forensics / IR | `digital-forensics/` | |
| Threat hunting / blue team | `threat-hunting/` | |
| Pentest tooling | `pentest-tools/` (+ src-hunter) | |
| Windows / AD | `windows-ad/` | |
| Cloud / containers / K8s | `cloud-k8s/` | |
| Code audit / SAST | `code-audit/` | |
| Wi-Fi / wireless | `wifi-wireless/` | |
| OT / ICS | `ot-ics/` | Passive-first; register writes forbidden by default |
| macOS | `macos-reverse/` | iOS still routes through mobile-reverse |
| Thick clients | `thick-client/` | |
| Go / Rust binaries | `go-rust-reverse/` | |
| Hardware debug ports | `hardware-security/` | Hands off to firmware-pentest |
| Databases | `database-security/` | |
| Email / phishing | `email-security/` | |
| Federated identity / SSO | `identity-federation/` | Complements api-security JWT coverage |
| RF / SDR | `radio-sdr/` | Receive-only by default; non-Wi-Fi |
| Multi-stage attacks | `attack-chain/` | |
| Pwn | `pwn-chain/` | |
| N-day patches | `patch-diff-exploit/` | |
| EDR research | `edr-bypass-re/` | |
| API | `api-security/` | |
| Supply chain / SBOM | `supply-chain-security/` | |
| LLM/Agent | `llm-security/` | + `ops/skill-supply-chain.md` |
| Browser automation | `browser-automation/` | |
| Reports / diagrams | `docs-generator/` `diagram-generator/` | |
| Symbol migration | `binary-diff/` | |
| Operational contracts | `ops/` | **Distinctive** |
| CTF orchestration | `CTF-Sandbox-Orchestrator/` | |
| Cryptographic pattern recognition | `reverse-engineering` pattern docs | Shared with reverse-engineering tasks; no standalone extension package maintained |

## Domains explicitly not merged from external libraries (policy when routing misses)

| Domain | Policy |
|----|------|
| Pure game cheat development | Not a product direction; Unity samples can still go through `reverse-engineering` + seed-014 |
| Deep automotive/aviation certification-grade work | May link externally; this package only has entry-level RF/OT coverage |
| Pure GRC/compliance long-form documents | Does not replace dedicated GRC tools; report templates may reference them |
| 800+ ATT&CK micro-skills | Use this table + optional ATT&CK labels (Finding field) |

## MITRE ATT&CK integration (optional)

The Finding template allows `optional_attack: Txxxx` (see `ops/evidence-finding-path.md`); a full ATT&CK engine is **not required**.
