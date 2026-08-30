# Cybersecurity Skills Router — Kali Linux Edition

> This directory is the optimized adaptation layer for Kali Linux 2026.1. It is tuned specifically for Kali 2026.1 (released March 2026, kernel 6.18).
> The core knowledge base (skills/, CTF-Sandbox-Orchestrator/) is shared with the Windows edition; the Kali-specific README and Bash entrypoints must cover the Windows core capability names while additionally providing Kali-native tool/MCP capabilities.
> The root-level [README-kali.md](../README-kali.md) is only a short jump; **this file is authoritative**.

---

## AI: Execute immediately after reading

```text
1. Detect the package root (a repository root containing skills/ and kali/)
2. Read kali/RULES-kali.md → global injection and tool scan
3. bash kali/scripts/refresh-tool-index.sh
4. Share the main package's operations chain:
   - skills/MASTER-ROUTING.md (or pwsh skills/scripts/master-route.ps1)
   - skills/scripts/case-init.ps1 → work/<case>/scope.md
   - ACT against a target only after auth.status=granted + network_profile
   - skills/ops/ (evidence chain / roles / timeline / IDENTITY)
5. Report the setup result to the user
```

For general agent onboarding, see the repository-root [README_AI.md](../README_AI.md) (read this file when Kali is detected).

---

## 0. Relationship to the Windows edition (capability-name alignment)

```text
project-root/
├── skills/                    # Shared: SKILL, routing, MASTER-ROUTING, ops, scripts, field-journal
├── CTF-Sandbox-Orchestrator/  # Shared: 40+ CTF sub-skills
├── kali/                      # ← you are here
│   ├── scripts/
│   │   ├── bootstrap-reverse.sh
│   │   ├── refresh-tool-index.sh
│   │   ├── bootstrap-manifest.json
│   │   └── lib/
│   │       └── tool-discovery.sh
│   ├── RULES-kali.md
│   └── README-kali.md
├── RULES.md                   # Windows-edition rules
└── Readme.md                  # Windows-edition readme
```


### 0.1 Alignment principle

The Kali-specific entry is not a copy of the Windows README; it is **the same set of core capability names + extra Kali capabilities**:

- Windows: `skills/scripts/bootstrap-reverse.ps1`
- Kali: `kali/scripts/bootstrap-reverse.sh`
- Regular Linux/macOS: `skills/scripts/bootstrap-reverse.sh`

JEB Pro is a commercial tool that users license and install themselves; Reqable MCP uses the officially pinned `reqable-mcp-server`, but still requires the Reqable desktop client to be installed separately.

Kali scripts should cover the core capability names from the Windows manifest, such as `jadx`, `apktool`, `frida`, `jshookmcp`, `xquik-mcp`, `anything-analyzer`, `idapro`, `r2`, `adb`, `ghidra-mcp`, `seclists`, `burpsuite-mcp`, `nmap`, `pentestswarm`; they may additionally support Kali-native tools such as `mcp-kali-server`, `metasploitmcp`, `hexstrike-ai`, `sstimap`, `xsstrike`, `netexec`.

**Shared parts** (no changes needed):
- All `SKILL.md`, `routing.md`, `MASTER-ROUTING.md`
- `skills/ops/` operations contracts (scope / evidence chain / roles / timeline)
- All `references/` knowledge bases
- `field-journal/` self-evolution mechanism
- Everything in `CTF-Sandbox-Orchestrator/`
- `docs-generator/`, `diagram-generator/`
- `skills/scripts/case-init.ps1`, `master-route.ps1` (callable via pwsh)

**Kali-specific parts**:
- All scripts are bash (`.sh`)
- Package management goes through `apt`
- Path conventions are Linux-style (`/opt/`, `~/tools/`, `/usr/bin/`)
- Many tools ship preinstalled on Kali, which greatly simplifies bootstrap logic

---

## 1. Kali's natural advantages

The following tools work **out of the box** on Kali 2026.1 (no bootstrap needed):

### Classic preinstalled tools

| Tool | Kali package | Status |
|------|----------|------|
| nmap | nmap | Preinstalled |
| sqlmap | sqlmap | Preinstalled |
| hashcat | hashcat | Preinstalled |
| john | john | Preinstalled |
| hydra | hydra | Preinstalled |
| metasploit | metasploit-framework | Preinstalled |
| gobuster | gobuster | Preinstalled |
| ffuf | ffuf | Preinstalled |
| radare2 | radare2 | Preinstalled |
| binwalk | binwalk | Preinstalled |
| frida | python3-frida-tools | Preinstalled or pip |
| burpsuite | burpsuite | Preinstalled |
| wireshark | wireshark | Preinstalled |
| nikto | nikto | Preinstalled |
| wfuzz | wfuzz | Preinstalled |
| impacket | impacket-scripts | Preinstalled |
| netexec | netexec | Preinstalled |
| responder | responder | Preinstalled |
| aircrack-ng | aircrack-ng | Preinstalled |
| bloodhound | bloodhound | Installable via apt |
| ghidra | ghidra | Installable via apt |

### New tools in Kali 2026.1 (March 2026)

| Tool | Package | Purpose |
|------|------|------|
| AdaptixC2 | adaptixc2 | Post-exploitation and adversary emulation framework |
| Atomic-Operator | atomic-operator | Cross-platform Atomic Red Team test execution |
| Fluxion | fluxion | WiFi security auditing and social engineering |
| GEF | gef | Modern enhanced debugging framework for GDB |
| MetasploitMCP | metasploitmcp | MCP server interface for Metasploit |
| SSTImap | sstimap | Automated SSTI detection and exploitation |
| WPProbe | wpprobe | Fast WordPress plugin enumeration |
| XSStrike | xsstrike | Advanced XSS scanner |

### New tools in Kali 2025.4 (December 2025)

| Tool | Package | Purpose |
|------|------|------|
| evil-winrm-py | evil-winrm-py | Python-based WinRM remote command execution |
| hexstrike-ai | hexstrike-ai | AI MCP security automation platform (150+ tools) |
| bpf-linker | bpf-linker | BPF static linker |

### Kali-native MCP tools (key focus)

| Tool | Package | Purpose | Install |
|------|------|------|------|
| mcp-kali-server | mcp-kali-server | Official Kali MCP; lets the AI call terminal tools directly | `apt install mcp-kali-server` |
| MetasploitMCP | metasploitmcp | Metasploit MCP interface | `apt install metasploitmcp` |
| HexStrike AI | hexstrike-ai | MCP automation across 150+ security tools | `apt install hexstrike-ai` |

> **This is the Kali edition's biggest advantage over the Windows edition**: the three MCP tools install straight from apt, with no manual GitHub/npm/Docker setup.

This means `bootstrap-reverse.sh` has far less work to do on Kali than on Windows.

---

## 2. Quick start

### 2.0 One-shot setup (recommended for fresh systems)

```bash
# One-shot configuration of a fresh Kali 2026.1 system (requires root)
sudo bash kali/scripts/quick-setup.sh

# Skip the system update (slow networks)
sudo bash kali/scripts/quick-setup.sh --skip-update

# Minimal install (skips AD/internal-network tools)
sudo bash kali/scripts/quick-setup.sh --minimal
```

This script automatically: system update → install the 2026.1 new tools → configure native MCP → install reverse-engineering tools → refresh the index → print a report.

### 2.1 First-time setup

```bash
# 1. Enter the project root
cd /path/to/cybersecurity-skills-router

# 2. Make the scripts executable
chmod +x kali/scripts/*.sh kali/scripts/lib/*.sh

# 3. Refresh the tool index (detects local tool status)
bash kali/scripts/refresh-tool-index.sh

# 4. Inspect the result
cat skills/tool-index.md
```

### 2.2 One-shot setup of the Kali-native MCP tools (strongly recommended)

```bash
# Install the three official Kali MCP tools
bash kali/scripts/bootstrap-reverse.sh mcp-kali-server metasploitmcp hexstrike-ai

# After installation the MCP config is written to ~/.claude/mcp.json automatically
# If you use Kiro, copy it manually to ~/.kiro/settings/mcp.json
```

### 2.3 Install the 2026.1 new tools

```bash
# Install all new tools in one shot
bash kali/scripts/bootstrap-reverse.sh adaptixc2 atomic-operator sstimap xsstrike wpprobe fluxion gef

# AD/internal-network pentest suite
bash kali/scripts/bootstrap-reverse.sh coercer evil-winrm-py netexec responder bloodhound certipy
```

### 2.4 Install missing tools

```bash
# Install a single tool
bash kali/scripts/bootstrap-reverse.sh jadx

# Install multiple tools
bash kali/scripts/bootstrap-reverse.sh jadx apktool frida jshookmcp

# Install and start services
bash kali/scripts/bootstrap-reverse.sh idapro --start-services
```

### 2.5 Let the AI client route automatically

Tell your AI client to read `kali/RULES-kali.md`; it will complete the global injection on its own.

---

## 3. Path conventions

| Purpose | Kali path |
|------|----------|
| Tool install directory | `~/tools/` or `/opt/` |
| jadx | `/opt/jadx/` or `~/tools/jadx/` |
| apktool | `/usr/local/bin/apktool` (apt) or `~/tools/apktool/` |
| Ghidra | `/opt/ghidra/` or `~/tools/ghidra/` |
| IDA Pro | `/opt/idapro/` (if the Linux build is installed) |
| Android SDK | `~/Android/Sdk/` |
| SecLists | `/usr/share/seclists/` (apt) or `~/tools/SecLists/` |
| Node.js | `/usr/bin/node` (apt/nvm) |
| Python | `/usr/bin/python3` (system-provided) |
| MCP config | `~/.claude/mcp.json` or `~/.kiro/settings/mcp.json` |

---

## 4. Summary of differences from the Windows edition

| Dimension | Windows edition | Kali edition |
|------|-----------|---------|
| Script language | PowerShell (.ps1) | Bash (.sh) |
| Package management | winget / GitHub Release ZIP | apt / pip / npm / GitHub Release tar.gz |
| Path separator | `\` | `/` |
| Environment variable | `%USERPROFILE%` | `$HOME` |
| Preinstalled tools | Almost none | Many security tools preinstalled |
| Starting IDA | `start.ps1` | Start the Linux IDA build manually; the script only registers/checks MCP unless you add a launcher yourself |
| MCP config path | `%USERPROFILE%\.claude\mcp.json` | `~/.claude/mcp.json` |
| Port detection | `TcpClient` | `nc -z` or `ss` |

---

## 5. Verification checklist

```bash
# ─── Basic commands ───
java -version
python3 --version
pip3 --version
node -v
npx -v

# ─── Reverse-engineering tools ───
jadx --version
apktool --version
adb version
frida --version
r2 -v
gdb --version          # GEF auto-loads

# ─── Pentest tools (preinstalled on Kali) ───
nmap --version
sqlmap --version
hashcat --version
hydra -h | head -1
msfconsole --version
gobuster version
ffuf -V
nuclei -version

# ─── Kali 2026.1 new tools ───
sstimap -h 2>&1 | head -3
xsstrike -h 2>&1 | head -3
wpprobe --help 2>&1 | head -3
coercer -h 2>&1 | head -3
evil-winrm-py -h 2>&1 | head -3

# ─── AD/internal-network tools ───
netexec --help 2>&1 | head -3
responder -h 2>&1 | head -3
certipy --version 2>&1 | head -1

# ─── Kali-native MCP ───
which kali-server-mcp && echo "mcp-kali-server OK"
which metasploitmcp && echo "metasploitmcp OK"
which hexstrike-ai && echo "hexstrike-ai OK"

# ─── Refresh the tool index ───
bash kali/scripts/refresh-tool-index.sh

# ─── Check MCP services (if configured) ───
nc -z 127.0.0.1 5000 && echo "mcp-kali-server OK" || echo "mcp-kali-server offline"
nc -z 127.0.0.1 8085 && echo "metasploitmcp OK" || echo "metasploitmcp offline"
nc -z 127.0.0.1 13337 && echo "IDA MCP OK" || echo "IDA MCP offline"
nc -z 127.0.0.1 23816 && echo "anything-analyzer OK" || echo "anything-analyzer offline"
```

---

## 6. FAQ

### Q: The radare2 bundled with Kali is too old. What now?

```bash
# Install the latest version from the official source
bash kali/scripts/bootstrap-reverse.sh r2
# The Kali edition prefers apt to install/repair radare2 by default; for the latest version, switch to GitHub/source per the platform docs
```

### Q: I use Parrot OS / BlackArch. Does this work?

Yes. The scripts only check whether commands exist; they are not tied to a specific distribution. Just be aware that `apt`-based auto-install may need to become `pacman` (BlackArch).

### Q: How do I configure IDA Pro for Linux?

Install IDA into `/opt/idapro/`, then update the `startScript` path of `idapro` in `kali/scripts/bootstrap-manifest.json`.

### Q: I want to use this system on both Windows and Kali

No problem. `skills/` syncs through Git, and `field-journal/` experience is shared on both sides. Just remember: on Windows run `skills/scripts/*.ps1`, on Kali run `kali/scripts/*.sh`.
