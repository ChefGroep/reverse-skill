---
name: ot-ics
description: Use for authorized OT/ICS security assessment covering Purdue model zoning, PLC/SCADA exposure, industrial protocol discovery, and safe passive-first evaluation.
---

# OT / ICS Security

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-pentest.md` — **operator error in an ICS environment can cause physical harm**
2. `NOW`: Written authorization must clearly state: site, network segments, whether active scanning / register writes are permitted
3. `NOW`: case-init; default **passive-first**; no write operations against PLCs before `ready_for_act`
4. `NEXT`: tool-index; most ICS tooling requires manual setup and an isolated lab network
5. `ACT`: Asset and zone identification → exposure surface → read-only verification

## Applicable Scenarios

- ICS/SCADA/DCS security assessments (authorized) — e.g. NL grid operators (Alliander, TenneT, KPN) and industrial sites
- Purdue model zoning and cross-zone paths
- Modbus/DNP3/S7/EtherNet/IP protocol exposure
- Engineering workstations, HMIs, historians, jump hosts
- IT/OT convergence boundaries (firewall rules, unidirectional gateways)

## Safety Iron Rules (MUST)

```text
MUST NOT unless explicitly permitted:
- Write coils/registers on PLCs
- High-rate scans across production OT networks
- Interrupt paths associated with the safety instrumented system (SIS)
Prefer: read-only identification, traffic mirroring, offline firmware/configuration analysis
```

## Workflow

### Phase 1 — Zoning and assets

```text
□ Purdue L0–L5 sketch: field devices → control → supervisory → site DMZ → enterprise
□ Asset inventory: PLC/RTU/HMI/engineering workstation/historian/jump host
□ Protocol and port baseline (authorized segments only)
```

### Phase 2 — Passive and read-only

```text
□ SPAN/mirrored PCAP → protocol-reverse / Wireshark ICS dissectors
□ Offline audit of configurations and engineering files (TIA/RSLogix exports, etc.)
□ Record default credentials and cleartext protocols (Modbus has no authentication) as Findings; never write values to the PLC
```

### Phase 3 — Constrained active (authorized only)

```text
□ Low-rate identification, during maintenance windows
□ Read-only function codes first
□ Evidence at every step; stop and escalate immediately on anomalies
```

### Phase 4 — Firmware/patch surface

```text
□ Controller firmware versions → CVE mapping (never blind-flash firmware)
□ Team up with firmware-pentest for offline image analysis
```

## Toolchain

| Tool | Purpose | Notes |
|------|---------|-------|
| Wireshark ICS dissectors | Passive parsing | Mirrored traffic |
| Nmap NSE (restricted) | Identification | Rate and time window |
| Claroty/Nozomi and similar | Asset discovery | Commercial/on-site |
| PLC vendor engineering software | Configuration audit | Offline first |
| binwalk / Ghidra | Firmware | Offline |

## References

- `references/ot-safe-assessment.md`
- `../firmware-pentest/` `../protocol-reverse/` `../network` via pentest-tools

## Routing Context

**Upstream**: MASTER R28  
**Downstream**: firmware deep-dive `firmware-pentest`; protocols `protocol-reverse`; IT lateral movement `windows-ad`/`attack-chain`  
**Peer**: never hit OT with default-parameter generic web scanning

## Task Completion Self-Check

- [ ] Passive/read-only by default with the authorization boundary recorded?
- [ ] Write operations against control loops avoided (unless explicitly permitted)?
- [ ] Do Findings include physical/process impact statements?
- [ ] Checklist / journal?
