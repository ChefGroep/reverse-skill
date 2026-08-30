---
name: radio-sdr
description: Use for authorized RF/SDR security research including signal identification, replay feasibility study in shielded labs, and wireless protocol analysis outside classic Wi-Fi.
---

# RF / SDR Security Research

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: **Spectrum use and transmissions are strictly regulated by law**; authorized bands / shielded rooms / experimental targets only
2. `NOW`: Define devices, frequency bands, and whether transmitting is allowed in scope (default: receive only)
3. `ACT`: Receive-only identification → demodulation analysis → lab reproduction and evaluation

## Applicable Scenarios

- Non-Wi-Fi RF such as wireless remotes/sensors (authorized)
- Protocol research such as ADS-B / RC control (legal receive-only)
- Division of labour with wifi-wireless: this skill covers **general SDR RF**; Wi-Fi attack/defence goes through R29

## Workflow

```text
□ Regulatory and licence confirmation (NL: Agentschap Telecom)
□ Receive only: identify centre frequency and modulation
□ GNU Radio / URH analysis
□ Replay only in a shielded room with written permission
□ Conclusion focus: can it be controlled without authorization? / hardening recommendations
```

## Toolchain

| Tool | Purpose |
|------|---------|
| RTL-SDR / HackRF (compliant) | RX/TX hardware |
| URH / GNU Radio | Analysis |
| Inspectrum | Signals |

## References

- `references/sdr-lab-rules.md`
- `../wifi-wireless/` `../ot-ics/` `../hardware-security/`

## Routing Context

**Upstream**: MASTER R38  
**MUST NOT**: Interfering with public communications, unauthorized transmissions

## Task Completion Self-Check

- [ ] Receive-only by default with regulatory boundaries recorded?
- [ ] Checklist?
