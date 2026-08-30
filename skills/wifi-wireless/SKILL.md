---
name: wifi-wireless
description: Use for authorized wireless security assessment including Wi-Fi capture, WPA handshake analysis, rogue AP detection research, and lab-only deauth testing.
---

# Wi-Fi / Wireless Security

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read precedent-pentest; **wireless attacks carry high legal risk** — written authorization and a defined physical scope are mandatory
2. `NOW`: Define target SSID/BSSID/venue in scope; never scan neighbouring networks
3. `NEXT`: Confirm the adapter's monitor-mode capability
4. `ACT`: Reconnaissance → capture → analysis (lab first)

## Applicable Scenarios

- Authorized Wi-Fi security assessments
- WPA/WPA2 handshake capture and offline evaluation
- Rogue AP / evil-twin hotspot detection research
- Enterprise wireless isolation and captive-portal security

## Workflow

```text
□ iwconfig / airmon-ng to enter monitor mode (authorized environment)
□ airodump-ng locked to the target BSSID channel
□ Handshake or PMKID capture (target only)
□ hashcat/aircrack offline evaluation of the password policy
□ Report: encryption type, isolation, portal bypass, recommendations
```

## Toolchain

| Tool | Purpose |
|------|---------|
| aircrack-ng suite | Capture/evaluation |
| hcxdumptool / hcxtools | PMKID |
| hashcat | Password evaluation |
| Wireshark | Management frame analysis |

## References

- `references/wireless-lab-rules.md`
- `../pentest-tools/` `../attack-chain/` (close-access sections)

## Routing Context

**Upstream**: MASTER R29  
**MUST NOT**: Unauthorized deauth, operating against non-target customer networks

## Task Completion Self-Check

- [ ] Is the target BSSID strictly locked down?
- [ ] Does the report include hardening recommendations?
- [ ] Checklist?
