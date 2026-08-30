# Kernel Driver Reversing Reference

> Covers Windows/Linux kernel driver reversing, rootkit analysis, and C/C++ binary pattern recognition.

---

## Windows Driver Reversing

### Driver Types

| Type | Signatures | Analysis focus |
|------|------|---------|
| WDM (Windows Driver Model) | Old-style driver, manually managed IRPs | DriverEntry -> device creation -> dispatch routines |
| KMDF (Kernel Mode Driver Framework) | Modern framework, event-driven | EvtDriverDeviceAdd -> Queue -> I/O callbacks |
| WDF (Windows Driver Foundation) | Umbrella term for KMDF + UMDF | Look for WdfDriverCreate calls |
| Minifilter | Filesystem filter driver | FltRegisterFilter -> Pre/Post callbacks |

### WDM Driver Analysis Flow

```text
1. Find DriverEntry (the entry point)
   - IDA identifies it automatically, or search for IoCreateDevice / IoCreateSymbolicLink

2. Find the device name and symbolic link
   - IoCreateDevice -> DeviceName (e.g., \Device\MyDriver)
   - IoCreateSymbolicLink -> SymLink (e.g., \DosDevices\MyDriver)

3. Find the dispatch routines
   - DriverObject->MajorFunction[IRP_MJ_DEVICE_CONTROL] = DispatchIoctl
   - This is the entry user-mode code reaches via DeviceIoControl

4. Analyze IOCTL handling
   - switch(IoControlCode) dispatches different functions
   - IOCTL encoding: CTL_CODE(DeviceType, Function, Method, Access)
   - Method: METHOD_BUFFERED / METHOD_IN_DIRECT / METHOD_OUT_DIRECT / METHOD_NEITHER

5. Find vulnerabilities
   - User-controlled buffer with unvalidated length -> overflow
   - METHOD_NEITHER uses user pointers directly -> arbitrary read/write
   - Unchecked IOCTL access rights -> callable by unprivileged users
```

### IOCTL Encoding Parsing

```python
# Parse an IOCTL code
def decode_ioctl(code):
    device_type = (code >> 16) & 0xFFFF
    access = (code >> 14) & 0x3
    function = (code >> 2) & 0xFFF
    method = code & 0x3
    
    methods = {0: "BUFFERED", 1: "IN_DIRECT", 2: "OUT_DIRECT", 3: "NEITHER"}
    access_types = {0: "ANY", 1: "READ", 2: "WRITE", 3: "READ|WRITE"}
    
    return f"DevType=0x{device_type:X} Func=0x{function:X} Method={methods[method]} Access={access_types[access]}"

# Example
decode_ioctl(0x80002034)
# DevType=0x8000 Func=0x80D Method=BUFFERED Access=ANY
```

### IDA Plugins

| Plugin | Purpose | Link |
|------|------|------|
| **Driver Buddy Reloaded** | Auto-identifies IOCTLs, dispatch routines, device names | https://github.com/VoidSec/DriverBuddyReloaded |
| **WinDbg + IDA** | Kernel debugging combined with static analysis | Built-in |
| **FLIRT/Lumina** | Identifies WDK library functions | Built into IDA |

### Reference Articles

- [Windows Drivers RE Methodology (VoidSec)](https://voidsec.com/windows-drivers-reverse-engineering-methodology/) — the most complete WDM driver reversing methodology
- [Driver Reversing 101](https://eversinc33.com/posts/driver-reversing.html) — WDM vs KMDF comparison
- [Methodology of Reversing Vulnerable Killer Drivers](https://whiteknightlabs.com/2025/10/28/methodology-of-reversing-vulnerable-killer-drivers/) — vulnerable driver analysis

---

## Linux Kernel Module Reversing

### LKM (Loadable Kernel Module) Structure

```text
Key functions:
- init_module / module_init -> executes on module load
- cleanup_module / module_exit -> executes on module unload

Key structures:
- struct file_operations -> char device open/read/write/ioctl
- struct net_device_ops -> network device operations
- struct block_device_operations -> block device operations
```

### Analysis Flow

```text
1. Confirm it is a kernel module
   file module.ko -> "ELF 64-bit ... relocatable" (note: relocatable, not executable)

2. Find the init/exit functions
   readelf -s module.ko | grep -E "init_module|cleanup_module"
   Or find module metadata in the .modinfo section

3. Find the file_operations structure
   Search for register_chrdev / cdev_add / misc_register
   -> locate the fops struct -> find the ioctl/read/write handlers

4. Analyze the ioctl handler
   unlocked_ioctl / compat_ioctl functions
   -> switch(cmd) dispatch

5. Look for rootkit behavior
   - Modifying sys_call_table -> syscall hook
   - Modifying the /proc filesystem -> hiding processes/files
   - Registering netfilter hooks -> hiding network connections
   - Modifying the VFS layer -> hiding files
```

### Common Rootkit Techniques

| Technique | Signature | Detection |
|------|------|---------|
| syscall table hook | Modifies `sys_call_table` entries | Compare the in-memory table against on-disk vmlinux |
| VFS hook | Modifies `file_operations` function pointers | Check whether fops pointers point outside the kernel code segment |
| Netfilter hook | `nf_register_net_hook` | Walk the netfilter hook list |
| kprobe/ftrace hook | Registers kprobe or ftrace callbacks | Check the ftrace registration list |
| eBPF rootkit | Loads a malicious BPF program | `bpftool prog list` |
| DKOM | Directly modifies kernel objects (process list) | Walk the task_struct list and compare against /proc |

### Tools

| Tool | Purpose |
|------|------|
| `crash` | Kernel dump analysis |
| `volatility3` | Memory forensics (Linux profile) |
| `dmesg` / `journalctl` | Kernel logs |
| `lsmod` / `/proc/modules` | Loaded module list |
| `modinfo` | Module metadata |
| `strace` | Syscall tracing (user-mode view) |

---

## C/C++ Pattern Recognition

### Common C Patterns

| Source pattern | Disassembly signature |
|---------|-----------|
| `if-else` | `cmp` + `jcc` (conditional jumps) |
| `switch-case` | Jump table (`jmp [rax*8 + table]`) or a chain of `cmp`s |
| `for` loop | `cmp` + `jl/jle` + loop body + `inc/add` + back-jump `jmp` |
| `while` loop | Condition test at the top of the loop |
| `do-while` | Condition test at the bottom of the loop |
| Function pointer call | `call rax` or `call [reg+offset]` |
| `struct` access | `[reg+fixed offset]` (e.g., `[rdi+0x10]`) |
| `malloc` + use | `call malloc` -> return value stored in a register -> later accesses via that register+offset |
| String comparison | `call strcmp` or `repe cmpsb` |

### C++-Specific Patterns

| Source pattern | Disassembly signature |
|---------|-----------|
| **Virtual call** | `mov rax, [rcx]` (fetch vtable) -> `call [rax+offset]` (call the virtual function) |
| **Constructor** | Allocate memory -> write the vtable pointer -> initialize members |
| **Destructor** | Clean up members -> may call `operator delete` |
| **this pointer** | First argument (rcx/rdi) is the object pointer |
| **Inheritance** | The vtable contains the parent's virtual functions + the child's overrides |
| **Multiple inheritance** | Multiple vtable pointers inside the object (at different offsets) |
| **RTTI** | A `type_info` pointer sits in front of the vtable |
| **Exception handling** | `__cxa_throw` / `_CxxThrowException` |
| **STL containers** | `std::vector`: `{begin, end, capacity}` three-pointer struct |
| **std::string** | Small string optimization (SSO): short strings inlined, long strings heap-allocated |

### vtable Reversing Method

```text
1. Find the vtable
   - Search for consecutive function pointer arrays (in .rodata or .rdata)
   - The constructor writes it with `mov [rcx], offset vtable`

2. Determine the class hierarchy
   - Offset -8 before the vtable is usually the RTTI pointer (if not stripped)
   - Multiple vtables sharing the first entries -> inheritance

3. Annotate the virtual functions
   - vtable[0] is usually the destructor (or deleting destructor)
   - Annotate the rest by offset: vtable[1] = func1, vtable[2] = func2...

4. IDA operations
   - Create a struct at the vtable address (each field a function pointer)
   - Comment `call [rax+offset]` sites with the virtual function being called
```

### Struct Recovery

```text
Method 1: infer from access patterns
  mov eax, [rdi+0x00]  -> field_0: int/ptr (4/8 bytes)
  mov ecx, [rdi+0x08]  -> field_8: int/ptr
  movss xmm0, [rdi+0x10] -> field_10: float

Method 2: infer from sizeof
  call malloc(0x30) -> struct size 0x30 (48 bytes)

Method 3: infer from the constructor
  The constructor initializes every field -> field types and offsets at a glance

Method 4: IDA's "Create struct" feature
  Select the access patterns -> Edit -> Struct -> Create struct from selection
```

---

## Common Compiler Signatures

| Compiler | Identifying signatures |
|--------|---------|
| MSVC | `_security_cookie` checks, `__fastcall` calling convention, Rich Header |
| GCC | `__stack_chk_fail`, `-fstack-protector`, `.note.GNU-stack` |
| Clang/LLVM | Similar to GCC but different optimization shapes, `__asan_*` (if sanitizers are enabled) |
| MinGW | GCC signatures + Windows API calls |
| AOSP Clang | Android-specific `__android_log_print`, PGO markers |

### Optimization Level Identification

| Level | Signature |
|---------|------|
| -O0 | Redundant movs, every variable on the stack, no inlining |
| -O1 | Basic optimization, some variables in registers |
| -O2 | Loop unrolling, function inlining, tail-call optimization |
| -O3 / -Os | Aggressive inlining, vectorization (SIMD), hard-to-read code |
| PGO | Hot-path optimization, cold code split into `.text.cold` |
| LTO | Cross-module inlining, global dead-code elimination |

---

## Kernel Debugging Environments

### Windows

```text
Debugger: WinDbg Preview
Connection: network debugging (recommended) or serial

Target machine setup:
bcdedit /debug on
bcdedit /dbgsettings net hostip:192.168.x.x port:50000

Debugger connection:
WinDbg -> File -> Attach to Kernel -> Net -> Port:50000 Key:xxx

Common commands:
!analyze -v          # Auto-analyze a crash
lm                   # List loaded modules
!drvobj \Driver\xxx  # Inspect a driver object
dt nt!_DRIVER_OBJECT # Display the struct
bp module!function   # Set a breakpoint
```

### Linux

```text
Debugger: GDB + QEMU or kgdb

QEMU kernel debugging:
qemu-system-x86_64 -kernel bzImage -s -S ...
gdb vmlinux -ex "target remote :1234"

Common commands:
info threads         # Kernel threads
lx-symbols           # Load kernel symbols (needs scripts/gdb/)
p init_task          # Inspect the init process
lx-dmesg             # Kernel log
```

---

## Agent Action Anchors (Issue #65 U-AV)

Aligned with `references/nonpe-format-cookbook.md` §5 (short table, does not replace the flow above):

| ID | Action | Evidence |
|----|------|----------|
| AG | `DriverEntry` is short -> scan `MajorFunction` non-empty slots, prioritizing DEVICE_CONTROL/CREATE | `E-driver-irp-handlers` |
| AH | Build the IOCTL control-code -> handler table with METHOD_* | `E-driver-ioctl` |
| AI | BYOVD suspected: check public vulnerable-driver lists; record name/hash/signature and usage intent; **never write exploit steps** | `E-driver-byovd` |

## References

| Resource | Description | Link |
|------|------|------|
| VoidSec driver RE methodology | Complete Windows WDM driver analysis flow | https://voidsec.com/windows-drivers-reverse-engineering-methodology/ |
| Elastic rootkit series | Linux rootkit taxonomy + detection | https://security-labs.elastic.co/security-labs/linux-rootkits-1-hooked-on-linux |
| Driver Buddy Reloaded | IDA driver analysis plugin | https://github.com/VoidSec/DriverBuddyReloaded |
| LOLDrivers | Known vulnerable driver list | https://www.loldrivers.io/ |
| Windows Driver Samples | Microsoft official driver samples | https://github.com/microsoft/Windows-driver-samples |
| Linux Kernel Module Programming | Kernel module development tutorial | https://sysprog21.github.io/lkmpg/ |
| Trail of Bits - Devirtualizing C++ | vtable reversing method | https://blog.trailofbits.com/2017/02/13/devirtualizing-c-with-binary-ninja/ |
