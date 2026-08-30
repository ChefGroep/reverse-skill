---
name: windows-ad
description: Use for authorized Active Directory and Windows identity attacks including Kerberos, AD CS, BloodHound paths, NTLM relay, and domain privilege escalation research.
---

# Windows / Active Directory Security

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: read `../field-journal/precedent-pentest.md`
2. `NOW`: **domain/AD testing requires an explicitly authorized scope** (signed Rules of Engagement, `work/<case>/scope.md` with `auth.status=granted`), including DCs and whether poisoning/relay is allowed — under the Dutch Computer Crime Act III (Wet computercriminaliteit III) testing without a grant is a criminal offence
3. `NOW`: case-init; write the network_profile and prohibited actions down clearly
4. `NEXT`: tool-index (impacket/certipy/bloodhound etc. are often installed manually)
5. `ACT`: start from identity enumeration and the BloodHound graph; do not jump to destructive exploitation first

## When to Use

- Domain pentest, Kerberoasting, AS-REP roasting, delegation
- AD CS (ESC1–ESC8 etc.) certificate attacks
- BloodHound / SharpHound attack paths
- NTLM Relay / Coercer forced authentication
- Local-to-domain privilege escalation paths (Potato-class as a stepping stone)

## Relationship with attack-chain

- **Multi-stage from external network to domain controller** → PRIMARY can remain `attack-chain/`; this skill is the **AD specialist**
- **Already inside the domain, focused on identity** → PRIMARY = this skill

## Workflow

### 1. Enumeration

```bash
# Example Impacket / built-in (requires credentials and authorization)
nxc smb <range> -u user -p pass
bloodhound-python -d domain.local -u user -p pass -c All -ns <DC>
```

### 2. Common paths (map before exploitation)

```text
□ Kerberoast / AS-REP → offline cracking
□ ACL abuse (GenericAll/WriteDacl)
□ Delegation (unconstrained/constrained/resource-based)
□ AD CS template misconfiguration → Certipy
□ Relay: LLMNR/NBT-NS + ntlmrelayx (confirm authorization)
```

### 3. Credentials and lateral movement

```text
□ secretsdump / lsassy / mimikatz (strict authorization and cleanup)
□ PtH / PtT / golden tickets only within an authorized red team scope
□ Write Evidence at every step; confirm with the user before high-impact actions
```

## Toolchain

| Tool | Purpose |
|------|------|
| BloodHound / SharpHound | path graph |
| Certipy | AD CS |
| Impacket / NetExec | lateral movement and enumeration |
| Rubeus / Mimikatz | tickets and credentials (authorized) |
| Coercer / Responder | forced authentication / poisoning |

## References

- `references/ad-attack-paths.md`
- `../pentest-tools/references/network-attack-defense.md`
- `../attack-chain/`
- seeds: `field-journal/seed-005_ad-certipy-esc1.md` `seed-007_ntlm-relay-coercer.md` `seed-013_kerberoasting-spn.md`

## Routing Context

**Upstream**: MASTER R24  
**Downstream**: reporting via `docs-generator`; EDR research via `edr-bypass-re`  
**MUST NOT**: unauthorized DCSync / golden tickets against production

## Completion Checklist

- [ ] Graph/enumeration before exploitation?
- [ ] Reproducible commands recorded and sanitized?
- [ ] Scope prohibitions respected?
- [ ] Checklist?
