# Reverse / Pentest / Security Task Auto-Routing Rules (Kali Linux Edition)

> **This file is the Kali path adaptation layer, not a second behavior chain.** Behavior and authorization are governed by the repository-root `RULES.md`.
> The core knowledge base (`skills/config/routing.json`, SKILL.md, references) is shared with the Windows edition.
> **Never** write this file into `~/.claude/CLAUDE.md` or any other client's global configuration. Core scripts must not write client global files.

Hot path (same as `RULES.md`): `skills/scripts/master-route.sh` → `case-init.sh` (no ACT against a target before `auth.status=granted`) → PRIMARY `SKILL.md`. Identity: `skills/ops/IDENTITY.md`. Scripts use this directory's `kali/scripts/*.sh`.

---

## Trigger keywords (identical to the Windows edition)

- APK, Android reverse engineering, decompilation, smali, jadx, apktool, Frida, Hook
- Binary analysis, IDA, radare2, r2, disassembly, reverse engineering, RE, source recovery, source-code reconstruction
- Frontend signatures, encrypted parameters, JS reverse engineering, jshookmcp, CDP, SourceMap
- Traffic capture, HTTP capture, request replay, anything-analyzer
- CTF, Pwn, Web penetration, exploitation, privilege escalation
- MCP reverse-engineering tools, idalib-mcp
- Repackaging, signing, certificate validation, root detection, anti-debugging
- .so analysis, native hook, JNI
- Penetration testing, red team, security assessment, blue team, incident response
- Write a report, write documentation, generate a report, writeup, technical documentation, pentest report, reverse-engineering report
- Browser automation, open web pages, form filling, scraping, screenshots, automated login, Playwright, agent-browser, headless
- Symbol migration, bindiff, cross-version, missing PDB, function-offset migration, symbol migration, version comparison, legacy symbols
- N-day, Nday, patch diff, patch diffing, patch tuesday, 1day, CVE reproduction, vulnerability reconstruction, ghidriff, Diaphora, DeepDiff, patch analysis
- pwn, stack overflow, heap overflow, ROP, ret2libc, ret2csu, one_gadget, libc-database, tcache, fastbin, kernel pwn, SMEP, SMAP, KASLR, modprobe_path, commit_creds, pwntools, GEF, pwndbg
- Firmware, IoT, binwalk, unblob, squashfs, UBI, JFFS2, Firmadyne, FAT, QEMU full-system emulation, EMBA, firmware pentesting, router firmware, embedded exploitation, AFL++, boofuzz, UART, JTAG
- BurpSuite, Burp MCP, Intruder, Repeater, Collaborator, proxy history analysis
- LLM security, AI security testing, prompt injection, jailbreak, Agent security, garak, PyRIT
- API security testing, GraphQL security, JWT attacks, supply-chain security, SBOM, Trivy
- iOS reverse engineering, Objection, YARA, malware analysis, AI decompilation, LLM4Decompile
- Agent not working, lazy AI, skipped steps, prompt engineering, agent compliance
- EDR bypass, AV bypass, AMSI evasion, unhook, direct syscall, indirect syscall, Hell's Gate, SysWhispers, ETW patch, AMSI patch, call stack spoofing, MITRE T1562, CrowdStrike bypass, Defender bypass, SentinelOne bypass, pe-sieve
- Port scanning, Nmap, vulnerability scanning, Nuclei, SQL injection, SQLMap, directory brute force, FFUF, password cracking, Hashcat, Hydra, Metasploit, Impacket, pentestMCP
- Bug bounty (HackerOne, YesWeHack, Intigriti), crowdsourced security testing, vulnerability reward programs, WAF bypass, WAF evasion, IDOR, broken access control, arbitrary account access
- Diagramming, flowcharts, architecture diagrams, attack-path diagrams, sequence diagrams, state diagrams, data-flow diagrams, Mermaid, Graphviz, PlantUML, diagram
- Malware analysis, virus analysis, sample analysis, sandboxing, YARA, IOC
- Kernel drivers, rootkits, LKM, IOCTL, DeviceIoControl
- Cryptography, encryption/decryption, AES, RSA, hash collisions, signature verification
- Protocol reverse engineering, custom protocols, Protobuf, serialization
- Firmware reverse engineering, IoT, binwalk, ARM, MIPS, embedded
- WASM, WebAssembly, Python bytecode, pyc, .NET, dnSpy, IL
- macOS, iOS, Mach-O, ObjC, Swift, Frida iOS
- Go reverse engineering, Rust reverse engineering, stripped binary, GoReSym
- Memory dumps, memory dump, forensics, forensic, steganography
- Cloud security, container escape, K8s, Docker, AWS, Azure
- Prompt injection, AI security, Agent security, LLM attacks
- Internal-network pentesting, lateral movement, Pass-the-Hash, domain pentesting, AD attacks, BloodHound
- Privilege escalation, privesc, SUID, Potato, UAC bypass
- Credential extraction, Mimikatz, Kerberoasting, DCSync, LSASS
- C2, remote access, persistence, backdoors, Cobalt Strike, reverse shell
- Blue team, detection, defense, incident response, SIEM, EDR, threat hunting, IOC
- Mobile security testing, OWASP MASTG, app security, unpacking, hardening analysis
- SSTI, template injection, SSTImap, XSS, XSStrike, cross-site scripting
- WordPress, WPScan, WPProbe, CMS pentesting
- AdaptixC2, C2 frameworks, adversary emulation, red-team simulation, Atomic Red Team
- WiFi attacks, wireless pentesting, Fluxion, aircrack-ng, deauth
- NTLM relay, Coercer, authentication coercion, PetitPotam
- WinRM, evil-winrm, Windows remote execution
- NetExec, nxc, CrackMapExec, SMB enumeration
- AI-driven pentesting, HexStrike, MetasploitMCP, mcp-kali-server
- Pentest Swarm, pentestswarm, swarm pentesting, Swarm AI, autonomous scanning, stigmergy
- Bug bounty automation, attack-surface management, ASM, continuous monitoring
- GEF, GDB enhancement, debugging frameworks
- Wireshark, tshark, PCAP analysis, traffic-capture analysis
- BurpSuite, web proxy, request interception, Intruder
- Responder, LLMNR poisoning, NBT-NS, MDNS
- BloodHound, AD paths, attack graphs, SharpHound
- Certipy, AD CS, certificate attacks, ESC1, ESC8
- wfuzz, parameter fuzzing, web fuzzing
- objdump, strings, file, static analysis
- ProxyCat, proxy pools, IP rotation
- Red team, threat-led penetration testing (TLPT), attack/defense exercises, initial access, perimeter breach
- Full-chain pentest, end-to-end pentest, from external network to internal network, from outside to domain controller
- Attack-surface assessment, attack-path planning, attack chains, kill chain
- Next steps after shell, post-exploitation, foothold expansion, deep penetration
- Close-access pentesting, BadUSB, Rubber Ducky, WiFi Pineapple, Proxmark3, RFID cloning
- EDR bypass, AMSI evasion, AV bypass, shellcode loaders, fileless attacks
- Phishing email, social engineering, OAuth phishing, HTML smuggling
- Supply-chain attacks, dependency poisoning, third-party pentesting
- Trace cleanup, anti-forensics, log wiping, timestamp tampering
- Cobalt Strike, Sliver, Havoc, Mythic, C2 frameworks

---

## Routing entry

> **Detection method**: the parent directory of the directory containing this file (`RULES-kali.md`) is the package root.

Hot path (same as `RULES.md` / `routing.json`):

1. `skills/scripts/master-route.sh -Hint "<task>"` — PRIMARY
2. `skills/scripts/case-init.sh` — `scope.md`; no ACT against a target before `auth.status=granted`
3. PRIMARY `SKILL.md` ACTION REQUIRED
4. `skills/tool-index.md` — real paths; if missing, run `kali/scripts/bootstrap-reverse.sh`

---

## Execution principles (same as the Windows edition; only the commands differ)

### Tool usage
- **Never guess tool paths**; read `tool-index.md` first
- When a tool is missing, call `bootstrap-reverse.sh` first to repair it automatically
- Many tools ship preinstalled on Kali, so bootstrap failure is far less likely than on Windows
- After the same tool fails to auto-install twice, stop retrying and print manual steps
- When MCP service ports do not match, ask the user for the actual port and help update the config

### Routing decisions
- When routing misses, **do not force the task into an existing skill**; proactively propose a new one
- If one path fails, switch: static fails → go dynamic; Java layer fails → look at the .so; IDA fails → switch to r2
- For cross-module tasks, combine multiple skills per the "path intersections" section of `routing.md`

### Experience reuse
- Before every routing entry, **always check** `field-journal/_index.md` first
- When a similar experience exists, read the corresponding log first and reuse the proven approach
- If the historical approach does not apply, state the reason in the new log

### Safety boundaries
- All operations must stay within the user's authorization
- Pentesting requires confirmed lawful authorization (bug bounty / owned systems / CTF lab / written engagement mandate under EU/NL rules)
- Never proactively expand the attack surface or go beyond the user-specified target scope
- When a high-severity vulnerability is found, notify the user immediately and wait for instructions before continuing
- Never keep unredacted sensitive information in reports or logs

### Output quality
- Key operations must include reproducible commands (not just step descriptions)
- Reverse-engineering analysis must cite addresses/offsets/function names (not just "some function")
- Pentesting must include a complete PoC (curl command / script / screenshot path)
- Uncertain conclusions must state their confidence level

---

## Complete behavior chain

```
1. Recognize the task as security/reverse-engineering related
2. Package root = the parent directory of this file
3. master-route.sh → PRIMARY (routing.json)
4. case-init.sh / scope.md — no ACT against a target before auth.status=granted
5. Open the PRIMARY SKILL.md
6. Missing tools → kali/scripts/bootstrap-reverse.sh
7. Do not write client global configuration
```

---

## Bootstrap commands (Kali edition)

```bash
bash "<this-package-root>/kali/scripts/bootstrap-reverse.sh" <capability1> [capability2] ... [--start-services]
```

### Common combinations

```bash
# One-shot setup of the Kali-native MCP tools (recommended on first use)
bash kali/scripts/bootstrap-reverse.sh mcp-kali-server metasploitmcp hexstrike-ai

# Install all 2026.1 new tools
bash kali/scripts/bootstrap-reverse.sh adaptixc2 atomic-operator sstimap xsstrike wpprobe fluxion gef

# AD/internal-network pentest toolchain
bash kali/scripts/bootstrap-reverse.sh coercer evil-winrm-py netexec responder bloodhound certipy

# Reverse-engineering toolchain
bash kali/scripts/bootstrap-reverse.sh jadx frida gef ghidra-mcp

# Web pentest toolchain
bash kali/scripts/bootstrap-reverse.sh sstimap xsstrike wpprobe nuclei
```

All supported capability names: jadx, apktool, frida, idalib-mcp, jshookmcp, xquik-mcp, anything-analyzer, idapro, r2, rabin2, adb, agent-browser, ghidra-mcp, nmap, sqlmap, hashcat, hydra, gobuster, ffuf, msfconsole, nuclei, seclists, proxycat, mcp-kali-server, metasploitmcp, hexstrike-ai, pentestswarm, adaptixc2, atomic-operator, sstimap, xsstrike, wpprobe, fluxion, gef, evil-winrm-py, coercer, netexec, responder, crackmapexec, bloodhound, certipy, wfuzz, aircrack-ng

## Refresh the tool index

```bash
bash "<this-package-root>/kali/scripts/refresh-tool-index.sh"
```

---

## MCP service management

### Kali-native MCP (direct apt install, no extra configuration)

| Service | Package | Port | Purpose | Start command |
|------|------|------|------|---------|
| mcp-kali-server | mcp-kali-server | 5000 | Official Kali MCP; the AI calls terminal tools directly | `kali-server-mcp --port 5000` |
| MetasploitMCP | metasploitmcp | 8085/stdio | MCP interface for Metasploit Framework | `metasploitmcp --transport stdio` |
| HexStrike AI | hexstrike-ai | — | MCP automation platform across 150+ security tools | `hexstrike-ai` |

### Third-party MCP services

| Service | Port | Purpose | Start command |
|------|------|------|---------|
| Pentest Swarm AI | stdio | Swarm-intelligence autonomous pentest (recon→classify→exploit→report) | `pentestswarm mcp serve` |
| idapro | 13337-13350 | IDA Pro reverse-engineering tools | `bash kali/scripts/ida-start.sh` |
| anything-analyzer | 23816 | Browser automation + HTTP capture | `cd ~/tools/anything-analyzer && pnpm dev` |
| jshookmcp | — | JS Hook/CDP/Network/AST | `npx -y @jshookmcp/jshook@0.3.4` (stdio) |
| ghidra | 8765 | Free Ghidra decompilation | Starts listening automatically once the Ghidra GUI is up |
| burpsuite | 9876 | BurpSuite web proxy | Started by the BurpSuite extension |

### MCP priority recommendations (Kali 2026.1)

For pentest scenarios, the recommended MCP usage priority:

1. **pentestswarm** — fully automated swarm pentesting; fits large-scale targets (1000+ subdomains) and continuous bug-bounty monitoring
2. **mcp-kali-server** — the most general; can call any terminal tool on Kali
3. **metasploitmcp** — Metasploit-specific: exploit/payload/session management
4. **hexstrike-ai** — automated orchestration; fits multi-tool coordination
5. **jshookmcp** — dedicated to web/JS reverse engineering

One-shot setup of all pentest MCP tools:
```bash
bash kali/scripts/bootstrap-reverse.sh mcp-kali-server metasploitmcp hexstrike-ai pentestswarm
```

---

## Error-handling strategy

| Scenario | What the AI should do |
|------|-------------|
| Bootstrap succeeds | Continue the task |
| apt install fails | Check network/sources, run `apt update`, retry once |
| pip install fails | Try adding `--break-system-packages`, or suggest a venv |
| GitHub download fails | Check network/proxy and provide a manual download link |
| Service port mismatch | Ask for the actual port and help update the MCP config |
| The same tool failed twice | Provide complete manual steps; stop retrying |

---

## Kali-specific advantage notes

The AI should know the following in a Kali 2026.1 environment:

1. **Many tools preinstalled** — nmap/sqlmap/hashcat/hydra/metasploit/gobuster/ffuf/radare2/binwalk/burpsuite/wireshark/nikto/impacket/netexec/responder/bloodhound need no installation
2. **Native MCP support** — `mcp-kali-server`, `metasploitmcp`, `hexstrike-ai` are in the official Kali repository; a single `apt install` suffices
3. **New 2026.1 tools** — AdaptixC2 (C2 framework), Atomic-Operator (red-team testing), SSTImap (SSTI detection), XSStrike (XSS scanning), WPProbe (WP enumeration), Fluxion (WiFi social engineering), GEF (GDB enhancement)
4. **New 2025.4 tools** — evil-winrm-py (WinRM remote execution), hexstrike-ai (AI security automation), bpf-linker
5. **Kernel 6.18** — supports the latest hardware, including NetHunter wireless-injection patches (QCACLD-3.0)
6. **Full Wayland support** — GNOME 49 + KDE Plasma 6.5, Wayland also works in VMs
7. **Rich apt sources** — `apt install ghidra`, `apt install seclists`, `apt install coercer`, all one-liners
8. **Complete Python environment** — python3/pip3 preinstalled; frida-tools installs directly with pip
9. **No permission friction** — defaults to root or passwordless sudo
10. **Full networking toolkit** — nc/curl/wget/socat/proxychains/chisel preinstalled
11. **SecLists path** — after apt install: `/usr/share/seclists/`
12. **Wordlists** — `/usr/share/wordlists/` includes rockyou and other common lists
13. **LLM integration** — the official Kali blog has a local LLM integration tutorial for Claude Desktop + Ollama + 5ire
14. **Undercover mode** — `kali-undercover --backtrack` switches to the classic BackTrack 5 look (social-engineering scenarios)

---

## Forbidden behaviors (same as the Windows edition)

- ❌ Do not start reverse-engineering/pentest operations without reading routing.md
- ❌ Do not guess tool paths; always get them from the tool index
- ❌ Do not skip the field-journal check and jump straight into the task
- ❌ Do not skip the checklist when the task is complete
- ❌ Do not keep unredacted real target information in reports
- ❌ Do not expand pentest scope without user authorization
- ❌ Do not repeatedly retry an auto-install that already failed twice
- ❌ Do not stay silent — any problem must be reported to the user immediately
- ❌ Do not invent tool version numbers or capability descriptions

---

## Mandatory post-task checklist (cannot be skipped)

After the task is complete (vulnerability verified / reverse engineering done / flag captured), the AI **must** execute each item:

```text
□ 1. Produce the formal report (docs-generator skill)
     - Use the matching template (reverse-engineering report / pentest report / CTF writeup / signature report)
     - Must include: target overview, full steps, key evidence, reproduction commands
     - Output to the user's project directory (not inside the skill package)

□ 2. Produce diagrams (diagram-generator skill)
     - At least 1 flowchart embedded in the report
     - Type choice: pentest → attack-path diagram / reverse engineering → call-graph / JS → sequence diagram / CTF → solve flow

□ 3. Write back to field-journal (sanitized)
     - Follow the field-journal/_template.md format
     - Must include: pitfalls, reusable patterns, toolchain findings, environment info
     - Sanitization check: no real domains/IPs/tokens/usernames

□ 4. Persist searched knowledge (if this task used web search)
     - Write valuable findings into the matching skill's references/
     - Record the source URL and date
     - New tool found → update bootstrap-manifest.json
     - New scenario found → update routing.md + RULES-kali.md keywords

□ 5. Ask about community contribution
     - "Should this experience be contributed to the community main repository? The data is sanitized; only the field-journal file is submitted."
     - User agrees → create a PR per the CONTRIBUTE-BACK.md flow
     - User declines → skip

□ 6. Update the system index
     - Update field-journal/_index.md (add the new entry)
     - Check whether routing.md / bootstrap-manifest / tool-index need updates
     - New tool or new scenario found → execute the matching update
```

If the AI finishes a task without running this checklist, the user may remind it: "You forgot the report and the experience write-back", and the AI must complete them immediately.

---

## Multi-task and interruption handling

- If the user switches topics mid-task, first save current progress to field-journal (marked as "unfinished")
- When the user returns, restore context from field-journal
- If the user issues several security tasks at once, execute them one by one by priority; do not run them in parallel (avoids tool conflicts)
- For long tasks (e.g., large-file IDA analysis), report progress regularly so the user does not think it is stuck

---

## Web knowledge supplements (must be used when search is available)

When the AI has web search capability, it **must proactively search** in these scenarios:

| Scenario | What to search | What to do with the results |
|------|---------|-------------|
| Unknown packer/protection/obfuscation | Search for unpacking methods and tools for that packer | Write the method into the matching skill's references/ |
| Unknown framework/protocol | Search for ways to reverse/pentest that framework | Write into references/ or propose a new skill |
| Tool errors/incompatibility | Search the error message + version compatibility | Write into field-journal pitfall records |
| New CVE/vulnerability found | Search for PoCs and exploitation methods | Write into pentest-tools/references/ |
| Routing miss (brand-new scenario) | Search that domain's methodology and tools | Propose a new skill with the gathered references |
| A specific Frida script is needed | Search GitHub/CodeShare for existing scripts | Write into apk-reverse/references/ or use directly |
| A specific payload is needed | Search PayloadsAllTheThings/HackTricks | Write into pentest-tools/payloads/ |
| Tool version too old | Search the latest version and breaking changes | Update bootstrap-manifest and the docs |

### Knowledge-persistence flow after searching

```text
1. Search and collect information
2. Verify reliability (official docs > GitHub > blogs > forums)
3. Extract actionable content (commands/scripts/configs/steps)
4. Write it into the matching location in this package:
   - General methodology → the matching skill's references/*.md
   - Tool-specific usage → the matching skill's references/ or SKILL.md
   - Pitfalls → field-journal/
   - New tool discovered → kali/scripts/bootstrap-manifest.json + tool-discovery.sh
   - New scenario discovered → routing.md + RULES-kali.md keywords
5. Record the source (URL + date) so freshness can be re-verified later
6. If the volume of information is large (a new domain), propose a dedicated new skill
```

### Search quality requirements

- **Never just hand the user a link** — extract the key content into this package
- **Never blindly trust search results** — cross-check against official documentation and state confidence
- **Prefer resources in the user's language** (match the language the user writes in) — but English official documentation remains authoritative for technical details
- **Record freshness** — security changes fast; note the search date and mark stale content `[possibly outdated]`

---

## Adding new skills

When the routing matrix cannot cover the current task type, add a skill per the `CONTRIBUTING.md` flow.

Path: `<this-package-root>/skills/CONTRIBUTING.md`

After adding, you must also update: routing.md, kali/scripts/bootstrap-manifest.json, kali/scripts/lib/tool-discovery.sh, kali/scripts/refresh-tool-index.sh.
