# [Seed] PCAP Custom Binary Protocol Reverse

## Scenario Classification
Packet-capture analysis / protocol reverse

## Target Overview
An IoT device/desktop client speaks a custom TCP binary protocol (not HTTP); a PCAP segment was captured. Frame structure, field meanings, encryption layer (if any) need to be recovered, plus a local client/server reproduction.

## Full Execution Chain

1. Open the PCAP in Wireshark, start with basic statistics
   - `Statistics → Conversations` for IP/port pairs
   - `Statistics → I/O Graphs` for data rhythm
2. Identify the real application-layer streams (strip standard layers like TLS)
3. On one TCP stream → `Follow → TCP Stream` → switch to RAW mode → export
4. Binary-level observation: are the first few bytes of each frame a fixed magic / length field?
   ```bash
   xxd dump.bin | head -20
   ```
5. Use hex mode to look for patterns: fixed header, length, TLV, CRC
6. Write a Python parser (struct + scapy) and decode frame by frame
7. In parallel, cross-check protocol fields from the binary decompilation (IDA / Ghidra, look at structs around send/recv)
8. Verify: start your own client, send one frame → server responds consistently

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Wireshark doesn't recognize the protocol, only shows "Data" | It's a private protocol with no dissector | Write a Wireshark Lua dissector or do direct Python offline analysis | 30min |
| Looks random, every frame differs | There's a compression or encryption layer | Use entropy analysis (`ent dump.bin`) to judge encryption; look for nonce/IV fields | 1h |
| Length field computes wrong | Length may be little-endian / big-endian / with-or-without itself | Take several frames of different lengths, set up equations and solve | 40min |
| TLS captured but cannot be decoded | Client doesn't leave an SSLKEYLOGFILE | Hook at the client process layer (Frida on ssl_read/ssl_write) to grab plaintext | 1.5h |
| Data correct but server doesn't respond | Protocol carries an incrementing seq / nonce; replay is rejected | Work out the seq computation (usually a hash of the previous frame or an incrementing counter) | 50min |

## Toolchain Findings

- **Wireshark Lua Dissector**: < 100 lines turns a private protocol into Wireshark visual output
- **scapy**: just define a `Packet` subclass when writing a Python parser
- **Kaitai Struct**: describe the protocol in YAML and generate multi-language parsers (Python/Java/C++/JS); good for long-term reuse
- **NetworkMiner**: better than Wireshark for "after-the-fact forensics" (automatic file carving, credential identification)
- **ent / binwalk -E**: entropy; >7.5 almost certainly encrypted

## Key Code/Commands

scapy custom protocol example (TLV):

```python
from scapy.all import *

class MyMsg(Packet):
    name = "MyProto"
    fields_desc = [
        StrFixedLenField("magic", b"\xab\xcd", 2),
        ByteField("version", 1),
        ByteField("type", 0),
        LenField("length", None, fmt="H"),     # H = uint16 BE
        XIntField("seq", 0),
        StrLenField("payload", "", length_from=lambda p: p.length - 8),
        XShortField("crc", 0),
    ]

# Parse the PCAP
pkts = rdpcap('dump.pcap')
for p in pkts:
    if TCP in p and p[TCP].dport == 9527 and p.payload:
        msg = MyMsg(bytes(p[TCP].payload))
        msg.show()
```

Kaitai Struct YAML (preferred for long-lived projects):

```yaml
# myproto.ksy
meta:
  id: myproto
  endian: be
seq:
  - id: magic
    contents: [0xab, 0xcd]
  - id: version
    type: u1
  - id: type
    type: u1
  - id: length
    type: u2
  - id: seq_no
    type: u4
  - id: payload
    size: length - 8
  - id: crc
    type: u2
```

Entropy analysis:

```bash
binwalk -E dump.bin             # entropy graph
ent dump.bin                    # numeric value
```

## Improvement Suggestions for This Package

- Add a "custom protocol reverse 4-step method" section to `reverse-engineering/platforms.md`
- Add a `reverse-engineering/references/kaitai-cheatsheet.md` quick reference
- Add scapy (pip) and binwalk to the bootstrap manifest

## Reusable Patterns/Script Snippets

**Custom protocol reverse 4-step method**:

```text
1. Read the rhythm (I/O graphs + Conversations to find session boundaries)
2. Find frame boundaries (magic / length / terminator)
3. Split fields (fixed header, length, payload, checksum)
4. Verify encryption (entropy + look for nonce + cross-check the send function in the binary)
```

**Trick for finding the frame length**:

Export all PSH packets of the same stream → look at each TCP segment's total length, and test whether the length field (try positions i, i+1, i+2) can derive the segment length.

## Evolution Actions
- [ ] Add a protocol-reverse section to reverse-engineering/platforms.md
- [ ] Add scapy / binwalk to bootstrap-manifest
- [ ] Add a Kaitai Struct quick reference

## Environment Info
- Kali / Ubuntu, Wireshark 4.x, Python 3.10+, scapy 2.5
- Target protocol: custom TCP binary (TLV / length prefix)
- Encryption layer: situation-dependent (commonly AES-CTR / ChaCha20)

## Sanitization Requirements
This entry is seed data written from public protocol-reverse methodology; no real product involved.
