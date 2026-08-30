# Expert Role → Skill Mapping (No Multi-Agent Server)

> The role codes are inspired by the Z3r0 specialist team; the **implementation** is the reverse-skill routing and handoff protocol, not process orchestration.

## Role Table

| Code | Name (localizable) | Responsibilities | PRIMARY / tool skill |
|------|------------------|------|----------------------|
| **lead** | Lead / commander | Split tasks, set scope, stage gating, compile reports | `attack-chain/` or the current PRIMARY hub; when finished → `docs-generator/` |
| **cie** | Intelligence collection | Asset discovery, exposure surface, relationships | `pentest-tools/` (recon); browser → `browser-automation/`; cloud surface → `cloud-k8s/` |
| **cpe** | Pentest validation | Scanning, exploit validation, impact confirmation | `pentest-tools/`; API → `api-security/`; AD → `windows-ad/`; wireless → `wifi-wireless/`; databases → `database-security/`; SSO → `identity-federation/`; OT → `ot-ics/` |
| **cre** | Reverse analysis | Binaries/firmware/mobile/frontend logic | `ida-reverse/` `ghidra-reverse/` `radare2/` `apk-reverse/` `mobile-reverse/` `macos-reverse/` `js-reverse/` `browser-extension-reverse/` `dotnet-reverse/` `go-rust-reverse/` `firmware-pentest/` `hardware-security/` `malware-analysis/` `protocol-reverse/` `thick-client/` `reverse-engineering/` |
| **cae** | Code audit | Source/deps/supply chain | `code-audit/` + `supply-chain-security/` |
| **cbe** | Blue team/forensics | Hunting, detection, IR artifacts | `threat-hunting/` `digital-forensics/` |
| **cce** | Cryptography | Algorithm/protocol/key misuse | `reverse-engineering` pattern docs |
| **llm** | AI security | Prompt/Agent | `llm-security/` |
| **doc** | Documentation officer | Reports/writeups/diagrams | `docs-generator/` + `diagram-generator/` |

## Lead Mandatory Protocol

```text
1. Output the PRIMARY (master-route) + lead_role=lead
2. Write scope.md (ops/scope-contract)
3. Specify specialist_roles[] and handoff conditions
4. At the end of each stage: update the timeline + workitems; decide to continue / switch role / produce the report
5. Skipping the scope to let cpe scan production directly is forbidden
```

## Handoff Rules

| From → To | Trigger | Deliverable |
|---------|------|--------|
| lead → cie | Asset surface needed | scope + known domains/IPs |
| cie → cpe | Live surfaces/services found | assets list + ports/URLs |
| cpe → cre | Reverse validation/client logic needed | sample paths + suspicious points |
| cre → cpe | Protocol/keys/validation logic recovered | algorithm description + reproduction commands |
| any → doc | Stage or task complete | Evidence/Finding/Path drafts |
| any → lead | Blocked / out of scope / path change | timeline note + blocked reason |

## How a Single-Agent Session Uses This (Highlight)

You do not need to actually spawn 6 agents:

```text
Within the same session:
  [lead] plans
  [cie] runs the recon skill
  [cpe] switches to pentest-tools
  …
Prefix output labels with the role for easy timeline retrieval:
  [cpe] nuclei high findings → E-003
```

## Relationship to master-route

- `master-route` decides the **PRIMARY skill**  
- `role-map` decides **who is responsible in the current stage** (can be written into scope.md)  
- For multi-stage tasks the PRIMARY is often `attack-chain/`, which the lead distributes further

## MUST NOT

- Do not assume a Z3r0 session API exists
- Do not launch extra scans against unauthorized targets for a role
