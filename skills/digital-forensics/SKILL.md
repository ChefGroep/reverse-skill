---
name: digital-forensics
description: Use for authorized digital forensics including memory dumps, disk timelines, PCAP investigation, artifact triage, and IR evidence preservation.
---

# Digital Forensics & IR Artifacts

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: read `../field-journal/precedent-pentest.md` or the organization's IR authorization statement (NIS2 entities: NCSC-NL incident-reporting duty)
2. `NOW`: confirm this is **forensics/traceability**, not offensive scanning
3. `NOW`: open the case; prefer read-only copies of evidence (write-protected original media)
4. `NEXT`: tool-index; Volatility etc. are often installed manually
5. `ACT`: preserve hashes → timeline → key artifacts

## When to Use

- Memory dump analysis (Volatility 2/3)
- Disk / E01 / dropped-file timelines
- PCAP tracing and protocol recovery (can pair with `protocol-reverse/`)
- Host artifacts: Prefetch, Shimcache, Event Log, browser history
- IR IOC extraction (paired with `malware-analysis/` / `threat-hunting/`)

## Workflow

### 1. Preservation

```text
□ Compute SHA256; record timezone and collection command
□ Work on copies; originals stay read-only
□ Write chain-of-custody notes into the timeline
□ Personal data in evidence: minimize and process per GDPR (Autoriteit Persoonsgegevens)
```

### 2. Memory

```bash
vol -f mem.dmp windows.info
vol -f mem.dmp windows.pslist
vol -f mem.dmp windows.netscan
vol -f mem.dmp windows.cmdline
```

### 3. Host artifacts

```text
□ Event logs: Security / PowerShell / Sysmon
□ Persistence: Run keys, services, scheduled tasks, WMI
□ Execution traces: Amcache, Prefetch, BAM
```

### 4. Network

```text
□ tshark session and DNS statistics
□ Export suspicious streams → protocol-reverse or malware C2 analysis
```

## Toolchain

| Tool | Purpose |
|------|------|
| Volatility 3 | memory |
| Timeline Explorer / Plaso | super timeline |
| tshark | PCAP |
| Eric Zimmerman toolset | Windows artifacts |
| Autopsy / FTK Imager | disk |

## References

- `references/forensics-triage.md`
- `../malware-analysis/` `../threat-hunting/` `../protocol-reverse/`

## Routing Context

**Upstream**: MASTER R25  
**Downstream**: deep-dive into malicious samples → malware-analysis; detection rules → threat-hunting

## Completion Checklist

- [ ] Hashes and copy strategy preserved?
- [ ] Timeline independently verifiable?
- [ ] IOCs sanitized and severity-classified?
- [ ] Checklist?
