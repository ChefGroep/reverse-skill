# EDR Hook Survey Cheatsheet

> Authorized red team / adversarial exercises / own-product testing only; use against unauthorized targets is forbidden.

This document summarizes the user-mode and kernel-mode monitoring points of mainstream EDR / AV, letting the red team reconnaissance stage quickly locate "what to handle".

## 1. Mainstream EDR Fingerprints and Hook Patterns Cheatsheet

| Vendor / Product | User-Mode Components | Kernel Drivers | Main Monitoring Surfaces |
|------------|-----------|---------|-----------|
| CrowdStrike Falcon | `CSFalconService.exe`, `CSAgent.sys` injected into target processes | `CSAgent.sys`, `CSBoot.sys` | Heavy kernel callbacks + ETW-TI; fewer user-mode hooks (cloud protection) |
| Microsoft Defender for Endpoint (MDE) | `MsMpEng.exe`, `MpClient.dll` | `WdFilter.sys`, `WdBoot.sys`, `WdNisDrv.sys` | Full coverage: AMSI + ETW-TI + ntdll inline hooks + kernel callbacks |
| SentinelOne | `SentinelAgent.exe`, `SentinelHelperService.exe` | `SentinelMonitor.sys`, `SentinelDeviceControl.sys` | Heavy ntdll user-mode hooks + kernel callbacks + own ETW provider |
| Elastic Defend (formerly Endpoint Security) | `elastic-endpoint.exe` | `elastic-endpoint-driver.sys` | Mostly ETW + a few ntdll hooks, paired with Elastic Agent uploads |
| ESET | `ekrn.exe`, `eamsi.dll` | `eamonm.sys`, `epfwwfp.sys` | Very many user-mode hooks (NtCreateFile / NtOpenProcess etc.) |
| Sophos Intercept X | `SophosFileScanner.exe`, `SophosNtpService.exe` | `SophosED.sys`, `hmpalert.sys` | ntdll hooks + HMPA memory protection + kernel callbacks |
| Kaspersky | `avp.exe`, `klif.sys` | `klif.sys`, `klhk.sys` | Heavy user-mode hooks + KLIF own minifilter + network filter drivers |
| Trend Micro Apex One | `TmListen.exe`, `TmCCSF.dll` | `tmcomm.sys`, `tmactmon.sys` | User-mode hooks + behavioral monitoring drivers |
| Carbon Black | `RepMgr.exe`, `RepWAV.exe` | `ParityDriver.sys` | Kernel-callback heavy + ETW |

### Quick Fingerprint Script

```powershell
$edrSigs = @{
    'CSAgent'           = 'CrowdStrike Falcon'
    'SentinelAgent'     = 'SentinelOne'
    'elastic-endpoint'  = 'Elastic Defend'
    'ekrn'              = 'ESET'
    'MsMpEng'           = 'Microsoft Defender'
    'SophosFileScanner' = 'Sophos Intercept X'
    'avp'               = 'Kaspersky'
    'TmListen'          = 'Trend Micro Apex One'
    'cb'                = 'Carbon Black'
}

Get-Process | ForEach-Object {
    foreach ($k in $edrSigs.Keys) {
        if ($_.ProcessName -match $k) {
            "[+] $($edrSigs[$k]) detected: $($_.ProcessName) (PID $($_.Id))"
        }
    }
}

Get-ChildItem 'C:\Windows\System32\drivers\*.sys' |
    Where-Object { $_.Name -match 'CSAgent|Sentinel|elastic|eam|WdFilter|Sophos|klif|tmcomm|Parity' } |
    Select-Object Name, VersionInfo
```

## 2. User-Mode ntdll Hook Priority Functions

`ntdll.dll` exports the EDR almost certainly hooks (grouped by ATT&CK behavior):

| Function | Monitored Behavior | ATT&CK |
|------|-----------|--------|
| `NtCreateThreadEx` | Remote thread injection, QueueUserAPC injection | T1055.002 / T1055.004 |
| `NtAllocateVirtualMemory` | Shellcode requesting RWX memory | T1055 |
| `NtAllocateVirtualMemoryEx` | Cross-process memory requests (Win10+ new API) | T1055 |
| `NtProtectVirtualMemory` | Changing page protection RW→RX | T1055 |
| `NtWriteVirtualMemory` | Writing shellcode cross-process | T1055.012 |
| `NtMapViewOfSection` | Section-based injection (Process Doppelganging / Ghosting) | T1055.013 |
| `NtCreateSection` | Pairs with MapViewOfSection | T1055.013 |
| `NtOpenProcess` | Opening the target process for a handle | T1057 |
| `NtQueueApcThread` / `NtQueueApcThreadEx` | APC injection | T1055.004 |
| `NtCreateProcess` / `NtCreateProcessEx` / `NtCreateUserProcess` | Creating child processes (incl. PPID spoof) | T1106 |
| `NtSetContextThread` | Changing thread context (thread hijack injection) | T1055.003 |
| `NtResumeThread` | Resuming the thread after injection | T1055 |
| `NtQuerySystemInformation` | Enumerating processes / drivers / handles | T1057 / T1082 |
| `NtAdjustPrivilegesToken` | Elevating to SeDebugPrivilege etc. | T1134 |
| `NtLoadDriver` | Loading kernel drivers (BYOVD) | T1543.003 |

### Verifying Whether a Hook Exists

```powershell
# Simple: disassemble and diff the disk ntdll against the current process's ntdll
# 1. Get the disk ntdll
copy C:\Windows\System32\ntdll.dll C:\temp\ntdll_clean.dll

# 2. In windbg, attach to any process and dump the current ntdll's .text section
# .writemem c:\temp\ntdll_live.bin ntdll!.text L?<size>

# 3. Disassemble NtAllocateVirtualMemory with IDA / radare2; normally it should be:
#    mov r10, rcx
#    mov eax, <SSN>
#    test byte ptr [...]
#    jne ...
#    syscall
#    ret
# If the first instruction becomes jmp <some address>, that's a hook
```

## 3. Kernel Callback Monitoring Points

Common kernel callbacks the EDR registers (all can be unregistered via the BYOVD route in `attack-chain`, but at high cost):

| API | When the Callback Fires | Defender's Purpose |
|-----|--------------|-----------|
| `PsSetCreateProcessNotifyRoutineEx` | Process creation / exit | Block suspicious child processes |
| `PsSetCreateThreadNotifyRoutine` | Thread creation / exit | Detect remote thread injection |
| `PsSetLoadImageNotifyRoutine` | DLL / EXE loaded into any process | Module integrity / unsigned blocking |
| `CmRegisterCallback` / `CmRegisterCallbackEx` | Registry operations | Persistence detection |
| `ObRegisterCallbacks` | `OpenProcess` / `OpenThread` handle requests | Prevent LSASS handle acquisition (T1003.001) |
| `MmRegisterPhysicalMemoryCallback` | Physical memory mapping | Anti-DMA / anti-memory forensics |
| `IoRegisterFsRegistrationChange` | File system registration | Minifilter coordination |
| `KeRegisterNmiCallback` | NMI (very few EDRs use it) | Anomaly monitoring |
| `EtwRegister` (kernel side) | Kernel ETW reporting | Coexists with ETW-TI |

### Enumerating Registered Callbacks with windbg

```text
0: kd> dx -r1 nt!PspCreateProcessNotifyRoutine
0: kd> dx -r1 nt!PspCreateThreadNotifyRoutine
0: kd> dx -r1 nt!PspLoadImageNotifyRoutine

0: kd> !object \Callback
0: kd> !object \Callback\ProcessObject
```

Or use tools like PChunter / DRVHV to view the callback list visually as a normal user.

## 4. Statically Dumping the Hook Table (IDA + windbg Procedure)

### Procedure A: Single-Process Comparison

```text
1. Find a process with EDR user-mode components injected (any running process)
2. windbg attach (-pn target.exe)
3. lm m ntdll  → get the module base
4. .writemem c:\temp\ntdll_live.bin ntdll+0x0 L?<image size>
5. Copy C:\Windows\System32\ntdll.dll to c:\temp\ntdll_disk.dll
6. Load both files in IDA and jump to NtAllocateVirtualMemory:
     - disk: standard prologue
     - live: first instruction jmp <0x7FFE000000xx>
7. Follow the jmp target address → that's the EDR's trampoline; dump it
8. Step into the trampoline to see which DLL it finally lands in, confirming the EDR module name
```

### Procedure B: Batch Hook Table Generation

Use `HookHunter` or a self-written script:

```powershell
# pseudo workflow; see the scripts mentioned in references for details
$disk = Get-Content C:\Windows\System32\ntdll.dll -Encoding Byte
$live = # obtained via OpenProcess + ReadProcessMemory
# Compare the first 16 bytes of each export in the .text section
```

## 5. pe-sieve Automated Detection

`pe-sieve` is the first choice for recon of EDR hooks and implant self-checks:

```powershell
# Basic scan
pe-sieve64.exe /pid 1234

# Recommended combination (includes shellcode and hook detection)
pe-sieve64.exe /pid 1234 /shellc 3 /modules 3 /imp 3 /data 3 /dir hooks_dump

# Key parameters:
#   /shellc N    shellcode scan level (0-3)
#   /modules N   module integrity check (0-3)
#   /imp N       IAT hook check
#   /data N      data section scan
#   /dir <path>  dump output directory
```

The output produces `*.tag` files under `hooks_dump/<pid>.<name>/` listing hook addresses:

```text
modified_modules.tag example:
71f10000;ntdll.dll
71f1a3b0;hook;jmp_far
71f1c020;hook;jmp_near
```

Feed these directly to IDA and jump to the corresponding RVA for further analysis.

### Embedding pe-sieve in the Implant (Self-Check)

In practice `pe-sieve` is often compiled as a lib (`libpe-sieve`) so the implant self-checks at startup: if ntdll has hooks, trigger the unhook flow; if it finds itself being hooked, be careful — it may be inside a sandbox.

## 6. API Monitor v2 Dynamic Observation

API Monitor v2 (Rohitab) suits lab work to see when and where the EDR inserts hooks:

```text
1. Start API Monitor v2 (as administrator)
2. In the API Filter, check:
     - NT Native API → Memory Management
     - NT Native API → Process and Thread
     - Windows Defender / AMSI (if visible)
3. Monitor New Process → pick the implant test sample
4. Observe:
     - NtAllocateVirtualMemory call order
     - Whether calls are relayed through the EDR DLL
5. In the Modules tab, see which EDR DLLs were LoadLibrary-injected
```

## 7. Common EDR DLLs (User-Mode) Cheatsheet

| DLL | Vendor | Notes |
|-----|------|------|
| `umppc*.dll` | Microsoft Defender | MpClient userland |
| `mpoav.dll` | Microsoft Defender | AMSI provider |
| `aswAMSI.dll` | Avast | AMSI provider |
| `eamsi.dll` | ESET | AMSI provider |
| `IDPMServiceClient.dll` | Sophos | HMPA injection |
| `klsihk64.dll` | Kaspersky | Injected into the target process |
| `CrowdStrike.Sensor.dll` | CrowdStrike | Older versions; newer versions rely mostly on the kernel |
| `SentinelInjection64.dll` | SentinelOne | User-mode injection |
| `TmUmEvt64.dll` | Trend Micro | Behavioral monitoring |

After confirming the target EDR, decide which DLL to reverse for the hook table.

## Reference Links

- pe-sieve: <https://github.com/hasherezade/pe-sieve>
- HollowsHunter: <https://github.com/hasherezade/hollows_hunter>
- API Monitor v2: <http://www.rohitab.com/apimonitor>
- MITRE ATT&CK T1562: <https://attack.mitre.org/techniques/T1562/>
- MITRE ATT&CK T1055: <https://attack.mitre.org/techniques/T1055/>
- ired.team EDR notes: <https://www.ired.team/offensive-security/defense-evasion>

## Routing Callback

After completing the hook survey, return to `SKILL.md` Step 3 to choose the bypass technique combination, then execute per `references/unhook-techniques.md` and `references/telemetry-blinding.md`.
