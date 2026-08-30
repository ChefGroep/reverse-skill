# 2026-08-06 Self-Keyed Rotate/XOR Wrapping of a Cortex-M Virtual-Disk Upgrade Firmware

## Scenario Classification

Binary / firmware reverse engineering

## Target Overview

Analyze a Cortex-M debug tool upgrade package, identify its custom wrapping algorithm, and distinguish the application image inside the upgrade package from the USB Mass Storage bootloader resident on the device.

## Scope Summary (desensitized)

- auth_basis: own_system
- network_profile: authorized_target_only (actually a local offline sample)
- asset_types: [firmware_container, cortex_m_application, usb_msc_updater]

## Roles

- lead_role: lead
- specialists: [cre, cce, doc]

## Full Execution Chain

1. Ran length, entropy, tail-periodicity, and block statistics on the original package; found the file size is an integer multiple of 1 KiB and the tail has a 7-byte period.
2. Starting from Cortex-M vector table constraints, enumerated single-byte rotate/XOR relations and recovered the first block.
3. Found that every 1 KiB block resets the rotation phase, and the first ciphertext byte of a block can directly serve as that block's XOR mask.
4. Decoded each block with `P[i] = ROR8(C[i], (3*i) mod 7) XOR C[0]` and rebuilt the original package byte by byte using the inverse transform.
5. Cross-validated against a second official firmware from the same series: the same format recovered a legitimate vector table, version strings, and readable code; the first plaintext byte of every block is zero.
6. Derived the application base address from the vector target addresses and file offsets, confirming the upgrade package contains no preceding bootloader.
7. Combined with the official "enter bootloader / emulate USB drive" documentation, reconstructed the external flow of copying an MSC file to Flash write, and marked the bootloader internals as inferred.
8. Tested common CRCs, the STM32 hardware CRC, Adler, and simple accumulation against the trailing 32-bit field; no match, so it remains an unresolved integrity field.

## Evidence Chain Summary (desensitized)

| E-id | source_type | Reproducible command pattern | Linked Finding |
|---|---|---|---|
| E-001 | local_binary | block entropy, periodic tail, vector constraints | F-001 |
| E-002 | derived_algorithm | first-byte mask + ROR/XOR + round-trip | F-001 |
| E-003 | static_analysis | vectors, strings, Thumb disassembly | F-002 |

## Finding / Path Summary

- top_finding: Some high-entropy firmware packages are merely self-keyed ROR/XOR obfuscation that resets every 1 KiB and should not be prematurely classified as standard encryption.
- path_type: solve/callflow
- path_one_liner: Periodicity and block structure → vector table crib → first-block recovery → block-boundary reset → second-firmware cross-validation → application/bootloader boundary → external MSC upgrade flow.

## Pitfalls

| Issue | Cause | Solution | Time |
|---|---|---|---|
| Initially used each block's "most common byte after derotation" as the mask; a few blocks still decoded to garbage | The most common plaintext byte of a text-dense block is not necessarily zero | Compared first-byte mask models; the garbage disappeared and reproduced on the second firmware | Medium |
| A single whole-file XOR/rotate only worked at the start | The rotation phase and mask reset every 1 KiB | Explicitly chunked by `0x400` | Low |
| IDA and radare2 failed to start | No local IDA path; the r2 bootstrap installer misbehaved | Verified the Cortex-M entry point with Python + Capstone | Medium |
| Saw `firmware_crc32` and assumed the tail was a standard CRC32 | The string is a metadata key; it proves nothing about the tail parameter or its coverage | Kept it unknown after systematically ruling out common checksum families instead of forcing a name | Low |

## Toolchain Findings

- Python is well suited to bitwise transform enumeration, round-trips, and cross-sample invariant verification.
- Capstone is sufficient to verify the Cortex-M vector entry point and local control flow when IDA/Ghidra/radare2 are unavailable.
- String recovery quality is a strong signal when comparing candidate mask models, but it must be combined with absolute pointers and disassembly to avoid relying on "looks readable" alone.

## Key Algorithm

```text
block_size = 0x400
mask = packed_block[0]
rotation(i) = (3 * i) mod 7
plain[i] = ROR8(packed[i], rotation(i)) XOR mask
```

The inverse transform uses `ROL8`; the validation criterion is that the encoded result is byte-identical to the original package.

## Improvement Suggestions for This Package

- Add a "does the block boundary reset the period" check to firmware-pentest's container identification stage.
- When the heuristic zero-byte crib fails on a few blocks, test self-describing masks at the block start/end first.
- For "upgrade package contains only the application" cases, the report must label bootloader-internal behavior separately from behavior guaranteed at the protocol layer.

## Reusable Patterns

1. First check whether the period resets at common Flash/transfer block sizes (256, 512, 1024, 2048, 4096).
2. Use the Cortex-M SRAM stack pointer and Thumb Reset Vector as a strong crib.
3. Run three validations per candidate model: whole-file round-trip, reproduction on a second sample, and consistent absolute address references.
4. When the tail field matches no common checksum, do not treat a variable name or string as algorithm evidence.

## Evolution Actions

- [x] Added a field-journal record
- [x] Updated the field-journal index
- [ ] Updated the routing matrix
- [ ] Updated the tool-index
- [ ] Updated the bootstrap-manifest
- [ ] Updated sub-skill docs

## Environment Info

- OS: Windows
- Tool versions: Python 3.12, Capstone 5.0.6
- Target platform/version: Cortex-M3 / F1-compatible MCU, application-area firmware

## Desensitization Check

- [x] No real domains, IPs, credentials, tokens, or PII
- [x] No local absolute paths
- [x] No sample file bodies or sample hashes
- [x] Vendor, product, and version information generalized
