# Community Security Skill Ecosystem Comparison (2026-07)

> Source research date: **2026-07-17**  
> Purpose: let reverse-skill **know what exists outside**, borrow as needed, and **not** merge entire external mega-repositories into this package.  
> This package's identity: routing + tool bootstrap + evidence/scope contracts + field journal (see `ops/IDENTITY.md`).

## 1. High-value external repositories (learn from them; do not install blindly)

| Repository | Size/positioning | Value to this package | Risk |
|------|-----------|------------|------|
| [trailofbits/skills](https://github.com/trailofbits/skills) | Trail of Bits security-research Claude plugin marketplace | Quality benchmark for audit/vulnerability-analysis/RE plugins | Must be installed via the ToB marketplace; never trust non-curated copies by default |
| [trailofbits/skills-curated](https://github.com/trailofbits/skills-curated) | Reviewed plugin list | Prefer over arbitrary community skills | Same as above |
| [Orizon-eu/claude-code-pentest](https://github.com/Orizon-eu/claude-code-pentest) | 6 pentest lifecycle skills + pure Python scripts | Recon→exploit→report pipeline comparable to our `attack-chain`+`pentest-tools` | Authorization boundaries need self-checking; scripts require sandboxing |
| [trilwu/secskills](https://github.com/trilwu/secskills) | 16 skills + 6 expert subagents | Multi-role division of labor comparable to `ops/role-map.md` | Plugin-form layout, unlike this package's monorepo |
| [Masriyan/Claude-Code-CyberSecurity-Skill](https://github.com/Masriyan/Claude-Code-CyberSecurity-Skill) | ~15–19 domain skills (incl. RE/OT/CSOC) | Domain-coverage checklist | Shallower than this package's single-domain skills |
| [mukul975/Anthropic-Cybersecurity-Skills](https://github.com/mukul975/Anthropic-Cybersecurity-Skills) | **800+** skills with ATT&CK/NIST mappings | Framework mappings and domain catalogs are worth referencing; avoid depending on the whole library | Enormous volume; huge maintenance and poisoning surface |
| [Eyadkelleh/awesome-skills-security](https://github.com/Eyadkelleh/awesome-claude-skills-security) | SecLists packaged as agent skills | Wordlist/payload entry point | Overlaps with the seclists bootstrap |
| [securityfortech/awesome-security-skills](https://github.com/securityfortech/awesome-security-skills) | Curated list of security skills | Index for discovering new skills | List-only; audit each entry individually |
| [VoltAgent/awesome-agent-skills](https://github.com/VoltAgent/awesome-agent-skills) | 1000+ cross-vendor skill index | Discover official/community skills | Not security-specific |
| [anthropics/claude-code-security-review](https://github.com/anthropics/claude-code-security-review) | PR security review GitHub Action | Maps to our docs/report-side "change audit" scenario | A CI product, not RE routing |
| [agentskills.io](https://agentskills.io) | Open standard for Agent Skills | Aligns frontmatter/directory conventions | The standard itself contains no attack/defense content |

### 1.1 Second-round research additions (searched again 2026-07-17)

| Repository / resource | Positioning | Landing point in this package |
|-------------|------|----------|
| [trailofbits/skills](https://github.com/trailofbits/skills) plugins: `audit-context-building` `differential-review` `semgrep-rule-creator` `sharp-edges` `dwarf-expert` `burpsuite-project-parser` | Audit context building, differential security review, dangerous APIs, DWARF, Burp project parsing | Cross-reference `ida-reverse`/`docs-generator`/audit workflows; do **not** merge the whole library |
| [HexRaysSA/ida-claude-code-plugins](https://github.com/HexRaysSA/ida-claude-code-plugins) | Official IDA Claude plugins (including domain automation, marked unsafe) | Cross-reference for the `ida-reverse` MCP path; unsafe plugins are not enabled by default |
| [P4nda0s/reverse-skills](https://github.com/P4nda0s/reverse-skills) | IDA-NO-MCP: export decompilation and analyze afterward; rev-frida/dex-dump/u3d | Complements our "offline export when MCP is unavailable" approach |
| [2389-research/binary-re](https://github.com/2389-research/binary-re) | triage→static(r2/Ghidra)→dynamic(QEMU/GDB/Frida)→synthesis | Stage gates for `reverse-engineering` are in `re-agent-workflow.md` |
| [incogbyte/android-reverse-engineering-claude-skill](https://github.com/incogbyte/android-reverse-engineering-claude-skill) | APK unpacking, endpoint extraction, adaptive Frida bypasses | Compare with `apk-reverse`; dynamic scripts require scope |
| [OwenPawl/cerberus-re-skill](https://github.com/OwenPawl/cerberus-re-skill) | Apple-targeted Ghidra+LLDB+Frida triple loop | Reference for the macOS/iOS dynamic loop |
| [ljagiello/ctf-skills](https://github.com/ljagiello/ctf-skills) | CTF reverse/pwn; tools installed on demand | Compare with CTF-Sandbox + `pwn-chain` |
| [shuvonsec/claude-bug-bounty](https://github.com/shuvonsec/claude-bug-bounty) | /recon→/hunt→/validate→/report | Compare with `recon-pipeline.md` + the scope gate |
| [PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings) | Web payloads + a Prompt Injection section | Prefer `pentest-tools/payloads`; for LLM see `llm-security` |
| [HackTricks](https://hacktricks.wiki/) | Pentest methodology + **AI/MCP abuse** | See the MCP section of skill-supply-chain |
| [appsecsanta AI pentesting agents 2026](https://appsecsanta.com/research/ai-pentesting-agents-2026) | Taxonomy of 39+ open-source AI pentest agent architectures | Multi-agent ≠ required; we use role-map |
| Snyk review: "more skills ≠ better" | Skill stacking can degrade audit quality | Reinforces the "deep skill + routing" strategy |

## 2. Security standards and threats (2025–2026)

| Source | Key points | Landing point in this package |
|------|------|----------|
| [OWASP Agentic Skills Top 10](https://owasp.org/www-project-agentic-skills-top-10/) | Malicious skills, supply chain, permission abuse, memory poisoning, and more | `ops/skill-supply-chain.md` |
| [Anthropic Agent Skills engineering article](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | Install only from trusted sources; review scripts and dependencies | Same as above + bootstrap never guesses paths |
| ClawHavoc and similar poisoning campaigns (documented in AST10) | Malicious skills at registry scale | Never one-click install from an unknown registry into this package |

## 3. What this package already has vs external "broad" coverage

| Domain | reverse-skill | Common externally, and why we don't merge the whole library |
|------|---------------|--------------------------------|
| APK/JS/IDA/r2/firmware/pwn | **Deep** skills + scripts | Preserves depth and the tool-index binding |
| Pentest / attack chain / bug bounty (VDP) | pentest-tools + attack-chain + src-hunter | Orizon-style repos serve as methodology cross-references |
| LLM/Agent security | llm-security | AST10 hardens the security of skills themselves |
| Evidence/scope/roles | **ops/** (distinctive) | Most skill packages lack a case contract |
| OT/ICS / pure GRC / fraud F3 | No standalone skill | If routing misses → propose a new skill or an external link; never force-fit |
| 800+ micro-skills | Not copied | Replace fragmentation with MASTER routing + domain skills |

## 4. Borrowing rules (MUST)

```text
1. Never pull an entire 800+ skills library as a runtime dependency via git submodule
2. When borrowing: extract the phase/checklist/command patterns and write them into this package's references or an existing skill
3. External scripts: first inspect dependencies and network behavior in an isolated environment, then consider bootstrap-manifest
4. New scenarios: add a skill via CONTRIBUTING and update routing + RULES keywords
5. Record the source URL + research date (in this file's format)
6. Run the ops/skill-supply-chain.md checklist before installing/merging
7. At runtime, load only the MASTER-ROUTING PRIMARY (+ required secondaries) to avoid skill-stacking overload
```

## 4.1 Distilled "borrowing products" already in this package (not external-library dependencies)

| Product | Path |
|------|------|
| RE four-phase workflow | `reverse-engineering/references/re-agent-workflow.md` |
| Authorized recon | `pentest-tools/references/recon-pipeline.md` |
| Attack-chain gates | `attack-chain/references/lifecycle-checklist.md` |
| Skill supply chain | `ops/skill-supply-chain.md` |
| Domain coverage | `references/domain-coverage-map.md` |

## 5. Suggested priorities (future iterations)

| Priority | Action |
|--------|------|
| P0 done | ops contracts, MASTER routing, skill supply-chain security docs |
| P1 | Cross-reference Orizon/ToB to add pentest phase checklists to the attack-chain references |
| P2 | Optional "external skill allowlist" configuration, kept off the default path |
