---
name: database-security
description: Use for authorized database security assessment covering PostgreSQL/MySQL/MSSQL/Mongo/Redis exposure, authz, UDF/command paths, and misconfiguration review.
---

# Database Security Assessment

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: read precedent-pentest; **destructive statements against production databases are forbidden** unless explicitly allowed
2. `NOW`: scope must state the instances, account privileges, and whether writes/deletes are allowed
3. `NEXT`: client tool paths
4. `ACT`: exposure → authentication → authorization → configuration → exploit-chain validation (safe)

## When to Use

- Unauthenticated database access / weak passwords / wrong binding 0.0.0.0
- Excessive privileges, dangerous features (xp_cmdshell, COPY PROGRAM, UDF)
- Lateral movement: from application account to DBA
- NoSQL injection and Redis file writes etc. (authorized environments)

## Workflow

```text
□ Network exposure and TLS
□ Account roles and grantees
□ Sensitive table access control
□ Dangerous configuration: file_priv, xp_cmdshell, load_file
□ Audit logging enabled?
□ Backup and snapshot privileges
□ Personal data in scope: GDPR applies — minimize evidence and note the breach-reporting duty (Autoriteit Persoonsgegevens)
```

## Toolchain

| Tool | Purpose |
|------|------|
| Official CLIs | connect and enumerate |
| sqlmap | injection validation (authorized) |
| nuclei | known exposure templates |
| Cloud RDS console audit | configuration |

## References

- `references/db-misconfig-checklist.md`
- `../pentest-tools/` `../cloud-k8s/`

## Routing Context

**Upstream**: MASTER R35  
**Downstream**: OS command obtained → attack-chain; cloud-hosted → cloud-k8s

## Completion Checklist

- [ ] Unauthorized writes/deletes avoided?
- [ ] Configuration issues separated from exploitable chains?
- [ ] Checklist?
