---
name: code-audit
description: Use for authorized source-code security review and SAST workflows including Semgrep, CodeQL patterns, dangerous API hunting, and fix verification (broncode-audit, SAST).
---

# Source Code Security Audit

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: read `../field-journal/precedent-pentest.md` or the code-audit authorization
2. `NOW`: confirm **source code / repository access** (binary-only target → switch to the RE skill)
3. `NOW`: clarify the language stack and scope (directories/services/PR diff)
4. `NEXT`: tool-index; semgrep etc.
5. `ACT`: threat-model sketch → automated scan → manual verification

## Applicable Scenarios

- White-box audits, PR/differential security review
- SAST with Semgrep / CodeQL / Bandit / gosec etc.
- Dangerous APIs, injection points, missing authorization, crypto misuse
- Division of labour with `supply-chain-security/`: this skill covers **own-code logic**; supply chain covers dependencies and pipelines

## Workflow

### 1. Scope and threat model

```text
□ Trust boundaries: user input, files, deserialization, SSRF, auth middleware
□ High-value assets: authentication, payments, admin panels, secret handling
```

### 2. Automated scanning

```bash
semgrep --config auto .
# or project rule packs
semgrep --config p/owasp-top-ten .
```

### 3. Manual verification (MUST)

```text
□ Every SAST hit: reachable? exploitable? false positive?
□ Authorization: IDOR/privilege abuse, missing checks, broken multi-tenant isolation
□ Injection: SQL/command/template/LDAP
□ Crypto: hardcoded keys, ECB, homemade crypto
```

### 4. Deliverables

```text
Finding: location + data flow + PoC + remediation advice
Optional ATT&CK / CWE identifiers
```

## Toolchain

| Tool | Languages/use case |
|------|-----------|
| Semgrep | Multi-language quick rules |
| CodeQL | Deep data flow (GitHub) |
| Bandit | Python |
| gosec / staticcheck | Go |
| SpotBugs / FindSecBugs | Java |

## References

- `references/sast-review-checklist.md`
- `../supply-chain-security/` `../api-security/` `../llm-security/` (agent code)

## Routing context

**Upstream**: MASTER R26  
**Role**: `ops/role-map.md` cae  
**Downstream**: dependency vulnerabilities → supply-chain; runtime verification → pentest-tools

## Task Completion Self-Check

- [ ] Was everything manually verified rather than pasting scanner output?
- [ ] Does every finding include remediation advice?
- [ ] Was work strictly limited to authorized repositories?
- [ ] Checklist?
