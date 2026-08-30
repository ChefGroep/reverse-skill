# Agent Skill Supply-Chain Security (Package Highlight)

> Sources synthesized from: OWASP Agentic Skills Top 10 (AST10), Anthropic Agent Skills security guidance, and public poisoning incidents (e.g. ClawHavoc, see the AST10 timeline)  
> Retrieval date: 2026-07-17  
> Applies to: installing/writing/merging **any** skill, MCP, or bootstrap script

The static audit of this package's **executable script surface** (backdoors / destructive commands / pipe execution): [`docs/PACKAGE-SECURITY-AUDIT.md`](../../docs/PACKAGE-SECURITY-AUDIT.md).

## 1. Why reverse-skill Manages This Separately

This package:

- Instructs the AI to **execute commands and bootstrap downloads**
- Reaches local and network resources through MCP
- Writes field-journal / reports

A malicious skill can cause: credential theft, persistent prompt injection, supply-chain backdoors.  
We use **documentation latches + a tool source-of-truth**, not another skill app store.

## 2. Threat Matrix (Condensed AST10 Approach)

| Risk class | Manifestation | Package control |
|--------|------|----------|
| Malicious/poisoned skill | Induces exfiltration, writes memory/backdoors | Only trust this repo + external sources with the user's written authorization; for external sources, first read SKILL.md and scripts manually |
| Excessive permissions | Indiscriminate `curl \| bash`, full-disk reads | Bootstrap only manifest capabilities; scope `network_profile` |
| Dependency poisoning | Malicious pip/npm packages | Prefer official releases; record versions in tool-index |
| Blind MCP trust | Unaudited MCP servers | tool-index registration status + port probing; do not trust remote MCPs by default |
| MCP/CLI auto-execution poisoning | A repo `.env` changes `CODEX_HOME` etc., causing a malicious MCP to execute at startup (HackTricks / CVE-style cases) | Do not trust in-repo default MCP configuration; check env and the MCP list before starting the agent |
| Prompt injection into a skill | SKILL body hides covert instructions | Review diffs; "execution instructions hidden in HTML comments" must never pass without the user |
| Scope drift | Skill induces broader scanning / "fully compromise a whole domain automatically" | ops/scope-contract: out_of_scope + auth; wide scans without in_scope are forbidden |
| Skill-stacking overload | Mounting too many skills at once actually increases misses (public benchmark observations) | Load only the PRIMARY + necessary secondary skills (MASTER-ROUTING) |

## 3. MUST Checklist for Installing External Skills

```text
□ Source: official org / audited list (e.g. curated) / user-owned
□ Read all SKILL.md + scripts/* + package dependencies
□ No mysterious outbound connections, no default steps reading ~/.ssh / browser stores
□ On conflict with this package's routing: this package's MASTER-ROUTING + scope prevails
□ Do not copy into the monorepo except via CONTRIBUTING and de-identification
□ Update skills/references/community-security-skills.md with source and date
```

## 4. Boundary with bootstrap / MCP

| Action | Allowed | Forbidden |
|------|------|------|
| `bootstrap-reverse.ps1 -Capability X` | X ∈ bootstrap-manifest.json | Any new name without changing the manifest |
| Registering MCP | User confirmation + tool-index refresh | Silently writing a global MCP pointing to an unknown URL |
| Running community one-click pentest Python | Authorized lab + after reading the source | Direct production targets + unknown scripts |

## 5. Package Authors/Contributors

- New skill: CONTRIBUTING + ACTION REQUIRED + completion self-check  
- Quoting community content: annotate URL + date (this file / community-security-skills.md)  
- Discovering suspicious behavior: stop execution, tell the user, never "try to bypass" automatically

## 6. Quick Self-Check (Before Merging Any External Material)

```powershell
# List the script extensions being introduced
Get-ChildItem -Recurse -Include *.ps1,*.sh,*.py,*.js | Select-Object FullName
# Coarse search for dangerous patterns (manual review; not exhaustive)
# Run in the external directory: Select-String -Pattern 'Invoke-WebRequest|curl .\||wget .\||~/.ssh|exfil'
```

## 7. Related

- Identity: `IDENTITY.md`  
- External catalog: `../references/community-security-skills.md`  
- Authorization: `scope-contract.md` + `field-journal/precedent-auth.md`
