---
name: threat-hunting
description: Use for blue-team threat hunting, detection engineering with Sigma/YARA, SIEM query design, and incident detection validation.
---

# Threat Hunting & Detection Engineering

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: confirm blue-team/hunting authorization and data-source scope (SIEM, EDR exports)
2. `NOW`: state the hypothesis before querying data; avoid mindless alert scrolling
3. `NEXT`: tools and data access method
4. `ACT`: hypothesis → query → validate → rule-ize

## Applicable scenarios

- Threat hunting (hypothesis-driven)
- Sigma / YARA detection engineering
- Alert tuning, false-positive analysis
- With `malware-analysis/`: sample-side IOCs → this skill lands the detections
- With `digital-forensics/`: case artifacts → lateral hunting

## Workflow

### 1. State the hypothesis

```text
Example: the attacker uses living-off-the-land for lateral movement
→ data sources: Sysmon 1/3/10, Windows Security 4624/4648
→ success criteria: finding an abnormal parent process or rare account in the log source
```

### 2. Query and stack

```text
□ Baseline: normal admin activity hours and hosts
□ Anomaly: new services, encoded PowerShell, unusual egress
□ Correlation: same account logging into multiple hosts in a short window
```

### 3. Rule-ize

```yaml
# Sigma skeletons: see malware-analysis; this skill emphasizes:
# - the false-positive surface
# - data-source field mapping
# - response playbook links
```

### 4. Validate

```text
□ Atomic tests (Atomic Red Team) only in an authorized lab
□ Replay historical logs to verify recall
```

## Toolchain

| Tool | Purpose |
|------|------|
| Sigma CLI / sigmac | rule conversion |
| YARA | file/memory |
| SIEM (ELK/Splunk etc.) | queries |
| osquery | endpoint hunting |
| Atomic Red Team | detection validation (lab) |

## References

- `references/hunting-loop.md`
- `../malware-analysis/references/yara-sigma-rules.md`
- `../digital-forensics/`

## Routing context

**Upstream**: MASTER R27
**Downstream**: confirmed intrusion → forensics; malware samples → malware-analysis
**MUST NOT**: run attack simulations in unauthorized production environments

## Task completion self-check

- [ ] Is there a clear hypothesis and conclusion?
- [ ] Do the rules note false positives and data sources?
- [ ] Checklist?
