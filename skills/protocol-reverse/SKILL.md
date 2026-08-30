---
name: protocol-reverse
description: Use for authorized reverse engineering of custom binary protocols, Protobuf/gRPC, WebSocket frames, and PCAP-driven protocol recovery.
---

# Protocol Reverse Engineering

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md` — confirm authorization and standard operating boundaries
2. `NOW`: Confirm whether the task is **protocol / traffic / serialization format** reverse engineering (not pure Web parameter signing → route to `js-reverse/`)
3. `NOW`: If there is target network interaction → `../scripts/case-init.ps1` to establish scope; ACT against the target is forbidden until `auth` is granted
4. `NEXT`: Read `../tool-index.md`; bootstrap missing tools (tshark/wireshark may need manual installation)
5. `ACT`: Enter workflow Phase 1, produce a frame layout or message dictionary draft

## Applicable scenarios

- Custom TCP/UDP binary protocols
- Protobuf / gRPC / FlatBuffers / MessagePack
- WebSocket / MQTT / private RPC
- Recovering fields and state machines from PCAP / PCAPNG
- Client-server validation, sequence numbers, encrypted frame headers

## Do not route here

| Situation | Go to |
|------|------|
| HTTP parameter signing / JS crypto only | `js-reverse/` |
| TLS certificate issues only | `pentest-tools/` or a browser proxy |
| Deep protocol stack inside firmware + emulation | `firmware-pentest/` first, then return to this skill |

## Workflow

### Phase 1 — Collection and triage

```text
□ Obtain samples: PCAP / proxy export / client logs / binaries
□ Mark direction: C→S / S→C; handshake, heartbeat, reconnect present?
□ Fixed header? Magic number? Length field? TLV? Fixed-length?
□ Compressed (zlib/gzip/lz4) or encrypted (AES/ChaCha within the frame)?
□ tshark -r cap.pcap -T fields -e frame.number -e ip.src -e tcp.payload
```

### Phase 2 — Frame layout recovery

```text
□ Align multiple messages of the same type; find invariant bytes / auto-incrementing sequence numbers
□ Length field: big-endian/little-endian, includes header or not
□ Integrity: CRC16/32, checksum, HMAC position
□ Draw the state machine: Connect → Auth → Ready → Request/Response → Close
□ Tools: Wireshark custom dissector draft / ImHex / 010 Editor template / Kaitai Struct
```

### Phase 3 — Serialization and encryption

```text
□ Protobuf: recover the .proto (blackboxprotobuf / pbtk / protoc --decode_raw)
□ gRPC: HTTP/2 headers + protobuf body
□ Encryption: find key derivation (client so/dll/JS) → combine with ida-reverse / js-reverse / apk-reverse
□ Replay: only within the authorized scope; harmless fields first, sensitive operations later
```

### Phase 4 — Deliverables

```text
MUST deliver:
- Message type table (name / opcode / fields)
- At least 1 reproducible decode command or script
- Evidence: raw hex excerpt + decode result (redacted)
```

## Toolchain

| Tool | Required | Purpose | Bootstrap |
|------|------|------|------|
| tshark / Wireshark | Strongly recommended | PCAP parsing | Manual / winget |
| Python3 | Yes | Decode scripts | System |
| blackboxprotobuf | Optional | Unknown protobuf | pip |
| ImHex / 010 | Optional | Structure templates | Manual |
| IDA / r2 / Ghidra | On demand | Client serialization functions | See the corresponding skill |

## References

- `references/protocol-workflow.md` — Frame layout and Protobuf quick reference
- Related: `../ida-reverse/` `../js-reverse/` `../firmware-pentest/` `../pentest-tools/`

## Routing context

**Upstream**: `MASTER-ROUTING` R21 · `routing.md`  
**Downstream**: client-side algorithms needed → `ida-reverse`/`js-reverse`; exploit replay needed → `pentest-tools`/`api-security`  
**Siblings**: `malware-analysis` (C2 protocols), `digital-forensics` (traffic forensics)

## Task completion self-check

- [ ] Was a message layout or state machine recovered (not just pasted hex)?
- [ ] Is there a reproducible decode command?
- [ ] Were scope / redaction respected?
- [ ] Was the field-journal / report checklist written back?
