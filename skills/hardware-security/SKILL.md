---
name: hardware-security
description: Use for authorized hardware and embedded interface security research including UART/JTAG discovery, debug pad triage, secure boot overview, and offline firmware extraction support.
---

# Hardware / Embedded Interface Security

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Confirm **physical access authorization** and device ownership
2. `NOW`: ESD/power safety; read-only probing by default
3. `NEXT`: Team up with firmware-pentest for image analysis
4. `ACT`: Enclosure and debug-interface identification → consoles → extraction

## Applicable Scenarios

- UART / JTAG / SWD debug-port discovery
- Boot logs, root shells, boot interruption
- Flash extraction together with teardown
- Feasibility assessment of secure boot / encrypted flash (non-destructive first)

## Workflow

```text
□ Teardown of the authorized device; photograph and label test points
□ Multimeter to locate GND/VCC/TX/RX; logic levels 1.8/3.3/5V
□ USB-TTL read-only logs; record the baud rate
□ JTAG: enumerate IDCODE; assess whether the chain is locked
□ Extract image → hand off to firmware-pentest / ghidra
```

## Toolchain

| Tool | Purpose |
|------|---------|
| USB-TTL / logic analyzer | UART |
| J-Link / CMSIS-DAP | Debugging |
| Bus Pirate / Flipper (lab) | Multi-protocol |
| binwalk / flashrom | Extraction |

## References

- `references/debug-interface-triage.md`
- `../firmware-pentest/` `../ot-ics/`

## Routing Context

**Upstream**: MASTER R34  
**MUST NOT**: Unauthorized teardown / damaging other people's devices

## Task Completion Self-Check

- [ ] Interface levels and pinout recorded?
- [ ] Are extracted images hash-preserved?
- [ ] Checklist?
