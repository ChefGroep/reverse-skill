---
name: pwn-chain
description: "Full-chain engineering methodology from reverse engineering to a working exploit. Use when you have the binary, a vulnerability point, and the target environment and need an exploit that reliably lands (not a script that only reproduces locally and crashes against the remote). Covers three tracks: stack overflow, heap exploitation, kernel pwn. Emphasizes the engineering gap between 'works locally in CTF' and 'reliably lands on the real remote': libc version mismatch, heap spray timing, SMEP/SMAP/KASLR, stack alignment, remote buffering. Core toolchain: pwntools + GEF/pwndbg + ROPgadget/Ropper + one_gadget + libc-database + qemu-system kernel debugging. Trigger keywords: pwn, stack overflow, heap overflow, ROP, ret2libc, ret2csu, one_gadget, libc-database, heap exploitation, tcache, fastbin, unsorted bin, kernel pwn, kROP, SMEP, SMAP, KASLR, modprobe_path, pwntools, GEF, pwndbg."
---

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md` — confirm this skill's operations are authorized routine operations
2. `NOW`: Confirm whether the current task falls within this skill's scope
3. `NEXT`: Read `../tool-index.md` and verify tool availability and actual paths
4. `NEXT`: When a tool is missing, invoke bootstrap; do not guess paths
5. `ACT`: Enter step 1 of the "Core Workflow" and execute; do not stop at the confirmation stage

# From Vulnerability Point to Working Exploit (Pwn Chain)

## When to Use

Use this skill when the task matches one of the following scenarios:

1. **Binary in hand + known vulnerability point** — static analysis/audit/fuzzing already found an overflow/UAF/double free; need to go from trigger to shell
2. **CTF challenge works locally but fails remotely** — remote environment differences break the script; needs stabilization
3. **Binary exploitation against real targets** — SRC / red team context where a memory corruption vulnerability has been identified and RCE must be built
4. **ioctl bug in a Linux kernel driver** — triggered from userspace, goal is privilege escalation to root

**Prerequisite**: you already know "where it breaks". This skill does not find vulnerabilities (that is fuzzing / auditing); it only covers "writing an exploit from the vulnerability point".

### Division of Labor with Other Skills

| Scenario | Use |
|------|--------|
| Identifying custom VM / anti-debug / complex obfuscation | `reverse-engineering/` |
| Opening a binary from scratch for static analysis | `ida-reverse/` or `radare2/` |
| **Vulnerability point in hand; write an exploit that lands remotely** | **This skill** |
| Integrating the pwn shell into a full attack chain | `attack-chain/` (downstream) |

`reverse-engineering/` focuses on "understanding what the program does" (pattern recognition, protocol recovery, decoding odd mechanisms in CTF challenges); this skill focuses on "turning an already-understood vulnerability into an executable attack". The two are often used together, but with a clear division of labor.

## Core Workflow

```text
Step 1: Confirm vulnerability type + protections
   ├─ checksec ./vuln (NX / Canary / PIE / RELRO / Fortify)
   ├─ file ./vuln  + readelf -d ./vuln
   ├─ Classify the bug: stack overflow / format string / heap (UAF/DF/OF) / integer / race condition / kernel
   └─ → decide which references/ to follow

Step 2: Choose the exploitation strategy
   ├─ NX off + no ASLR → direct shellcode
   ├─ NX on + libc provided → ret2libc / one_gadget
   ├─ NX on + libc not provided → leak, then identify with libc-database
   ├─ Heap → technique matched to the glibc version (tcache/fastbin/unsorted/large)
   └─ Kernel → commit_creds / modprobe_path / core_pattern

Step 3: Prepare libc + gadgets
   ├─ libc-database: ./find puts 0x6f0
   ├─ ROPgadget --binary ./libc.so.6 --only "pop|ret"
   ├─ one_gadget ./libc.so.6
   └─ Compute base: leak_addr - libc.sym['puts']

Step 4: Write the pwntools template (local process)
   ├─ context.binary = ELF('./vuln')
   ├─ p = process('./vuln')  /  p = gdb.debug('./vuln','b *main+xx')
   ├─ payload = cyclic(N) + p64(ret) + ...
   └─ p.interactive()

Step 5: Get it working locally
   ├─ Repeatedly attach + inspect registers + tune offsets
   ├─ Use pwndbg/GEF's vmmap / heap / bins / telescope
   └─ Once it works locally, switch to remote()

Step 6: Stabilize on the remote
   ├─ libc offsets: identify the leak with libc-database; never guess
   ├─ Stack alignment: 16-byte misalignment → movaps crash → add one ret gadget
   ├─ Remote network latency → recvuntil on exact anchor strings; no fuzzy sleep
   ├─ Remote buffering: sendlineafter is more stable than sendline
   ├─ Heap spray success rate: scale up the spray count + leave padding chunks to prevent coalescing
   └─ Run it many times: loop with while True and verify a ≥ 95% success rate
```

## Typical Scenarios

### Scenario 1: Remote 64-bit binary (NX+PIE+canary, libc provided)

```text
Given: ./vuln (64-bit ELF, NX, PIE, canary) + ./libc.so.6 + nc host port
Bug: read(buf, 0x200) but buf is only 0x40 bytes → stack overflow
Protections: canary blocks the direct path; PIE randomizes .text

Strategy:
1. First leak the canary (stack / format string / partial read)
2. Then leak a libc function address (puts@got)
3. Compute the libc base with libc.address = leaked - libc.sym['puts']
4. Run one_gadget ./libc.so.6 and pick a magic gadget whose constraints you can satisfy
5. payload = padding + canary + saved_rbp + (pop_rdi + bin_sh + system), or one_gadget directly
6. Add one ret gadget to fix stack alignment (critical!)
```

For the full template see `references/stack-pwn.md`.

### Scenario 2: Linux kernel driver ioctl out-of-bounds write → root

```text
Given: vmlinux + bzImage + initramfs.cpio.gz + custom vuln.ko
Bug: copy_from_user inside ioctl(0x1337, ptr) with attacker-controlled length → kernel heap overflow (kmalloc-64 slab)
Protections: SMEP, SMAP, KASLR, KPTI

Strategy:
1. Patch the init script for a root shell (CTF) or leak the KASLR base first and continue (real world)
2. Leak the kernel base via /proc/kallsyms (may be permission-restricted) or an uninitialized heap spray
3. Spray tty_struct / msg_msg / pipe_buffer into the kmalloc-64 slab
4. Overwrite the vtable pointer to point into userspace → blocked by SMEP; switch to stack pivot + kernel ROP
5. ROP chain: prepare_kernel_cred(0) → commit_creds → swapgs+iretq → userspace execve("/bin/sh")
6. Or the cheaper route: overwrite modprobe_path with "/tmp/x", write /tmp/x, then trigger modprobe
```

For the full template see `references/kernel-pwn.md`.

## On-Demand Bootstrap

### Tool Dependencies

| Tool | Purpose | Installation |
|------|------|---------|
| pwntools | exploit development framework | `pip install pwntools` |
| GEF | enhanced gdb (recommended for kernel + userspace) | `git clone https://github.com/bata24/gef` (actively maintained fork) |
| pwndbg | enhanced gdb (best heap debugging experience) | `git clone https://github.com/pwndbg/pwndbg && ./setup.sh` |
| ROPgadget | gadget search | `pip install ropgadget` |
| Ropper | gadget search (alternative, supports more architectures) | `pip install ropper` |
| one_gadget | find libc magic gadgets | `gem install one_gadget` (requires ruby) |
| libc-database | identify libc from a leak | `git clone https://github.com/niklasb/libc-database && ./get` |
| qemu-system-x86_64 | kernel challenge debugging | `apt install qemu-system-x86` |
| binwalk / cpio | initramfs unpacking | `apt install binwalk cpio` |
| patchelf | switch libc versions | `apt install patchelf` |

### Bootstrap Check Script

```bash
# One-shot check + install core tools
for t in pwntools ropgadget ropper; do
  pip show $t >/dev/null 2>&1 || pip install $t
done

command -v one_gadget >/dev/null || gem install one_gadget

[ -d ~/tools/libc-database ] || git clone https://github.com/niklasb/libc-database ~/tools/libc-database
[ -d ~/tools/libc-database/db ] || (cd ~/tools/libc-database && ./get ubuntu debian)

[ -d ~/tools/pwndbg ] || (git clone https://github.com/pwndbg/pwndbg ~/tools/pwndbg && cd ~/tools/pwndbg && ./setup.sh)
```

### After the Same Tool Fails to Auto-Install 2 Times

Stop retrying and output structured manual installation steps (pip index / gem source / git mirror / apt mirror) for the user to confirm.

## Routing Context

**Upstream entrypoints**: `skills/SKILL.md` (master control), `routing.md`
**Trigger condition**: binary in hand + an identified vulnerability point; an exploit must be written

**Upstream skills (use these first, then return to this skill)**:
- Haven't understood what the binary does yet → `reverse-engineering/`
- Need detailed static analysis → `ida-reverse/`
- Quick recon to confirm architecture/protections → `radare2/`

**Downstream skills (after getting a shell)**:
- Integrate into a full attack chain (lateral movement, privilege escalation, persistence) → `attack-chain/`

**Submodule navigation**:
- Stack-based exploitation (ret2libc / ret2csu / one_gadget / stack alignment) → `references/stack-pwn.md`
- Heap-based exploitation (tcache / fastbin / unsorted / large bin / FILE struct) → `references/heap-pwn.md`
- Kernel pwn (kROP / SMEP-SMAP bypass / KASLR leak / modprobe_path) → `references/kernel-pwn.md`

## Important Notes

- **Don't call it done when it works locally** — local libc / ASLR / network environment all differ from the remote; you must run it 20+ consecutive times in remote mode to verify stability
- **The libc version must be confirmed** — verify with a leak + libc-database lookup; never assume the Ubuntu 22.04 default libc
- **Stack alignment is a classic 64-bit pitfall** — `movaps xmm0, [rsp]` segfaults when rsp is not 16-byte aligned; adding an empty `ret` gadget fixes it
- **Heap exploitation is extremely sensitive to the glibc version** — tcache arrived in 2.27, safe-linking in 2.32, hooks were removed in 2.34; each version has different exploitation paths
- **For kernel pwn, confirm the CPU flags first** — whether the qemu boot arguments include +smep +smap +pku directly determines how the ROP chain is written
- **One KASLR leak is enough** — once you have a single kernel address, compute every other address as an offset; do not leak repeatedly

## Task Completion Self-Check (MUST pass before claiming completion)

- [ ] Did I execute every step of the workflow (rather than only reading)?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/report)?
- [ ] Did I complete and write back the Checklist items required by RULES?
