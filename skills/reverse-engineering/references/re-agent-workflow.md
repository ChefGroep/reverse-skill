# RE Agent Workflow Gate (static↔dynamic)

> Inspired by: binary-re stage division, community RE skills (Frida/r2/Ghidra/IDA loops), Cerberus triple-head ring (static/dynamic/instrumentation)
> Issue #65 increment: IAT repair iron rule, six-phase mapping, .NET/DLL·SYS equivalent paths; user-instruction feasibility gate; bypass patches 6-10; anti-debug/deobfuscation recipes A-T; non-PE multi-format recipes U-AV (2026-08-12)
> Applies to: `reverse-engineering/`, `ida-reverse/`, `radare2/`, `malware-analysis/`, and handoff to the cre role

## 0. Launch

```text
□ scope.md: offline sample path or authorized device/target
□ tool-index: actual paths for file/strings/r2/ida/frida etc.
□ Role: cre (ops/role-map)
```

## 0.1 Transition handoff (decision delta)

Do not re-inject the full case context between phases. `scope.md` / `workitems.md` / Evidence remain authoritative; `timeline.md` only carries the transition delta:

1. At the end of each stage/turn, write only the `decision_delta` that actually changes downstream action; write `[]` when nothing changed.
2. Unchanged route/auth/scope/network profile/tool state/hypothesis go only into `carry_forward_refs`; the consumer reads them via references instead of re-serializing/emitting.
3. `decision_delta` is not a full state; the consumer must first inherit the references, then apply the delta.
4. Stop at a next-step menu only when two or more evidence-supported branches lead to different downstream actions; a deterministic gate advances directly.

Example: when Triage is complete and the only legitimate next step is Static, the transition only needs `decision_delta: [phase=triage->static]` + `carry_forward_refs: [scope.md, evidence/E-triage.md]`.

## 0.5 User-Instruction Feasibility Gate (Issue #65)

**Principle**: obey the user's **goal**, not blindly the user's **step order**. Before skipping a step, state the prerequisite and ask for confirmation; after confirmation the mandated step must be done, and Evidence quality must be labeled honestly.

| Situation | Agent MUST |
|------|------------|
| User wants X and the current state can yield **valid** Evidence | Execute X and update Evidence |
| User wants X but there is a **known blocking prerequisite** (e.g., already judged packed and the static IAT is unreadable) | **Do not** pretend the IAT was meaningfully completed: ① State the blocker in one sentence; ② Give a recommended order (unpack/repair the IAT first, or go straight to dynamic API capture); ③ **Ask the user to confirm** whether to still mandate the current step or follow the recommended order |
| User explicitly **mandates** the current step (e.g., see the IAT even though it is still packed) | Execute it and record Evidence, MUST labeling `quality=unreadable` / `packed` (or equivalent); **Do not** draw conclusions like "no network capability" from it |
| User accepts the recommended order | Do the prerequisite steps first; once complete, do X automatically or on further request; **Do not** use the prerequisite step (e.g., unpacking) to **pose as** "import-table check complete" |

**Relation to "redo X"**: redoing X still means redoing the named step (or its confirmed legitimate prerequisite negotiation outcome); do not substitute unrelated steps. Unpacking is a **prerequisite** for the import table, not a **substitute** for it.

Typical conflict: the user says on a packed sample "don't unpack first, look at the import table" -> the packer usually tampers the import directory/encrypted descriptors, so the static table is garbage and meaningless -> walk this table's "blocking prerequisite" row: do not silently unpack and pose as complete, and do not silently hand over the garbage table as completion.

## 1. Triage (5-15 minutes · mandated starting point)

```text
□ Compute the sample hash (MD5/SHA256) -> unique ID
□ Identify the file type: EXE / DLL / SYS / ELF / Mach-O / .NET / script (bat/ps1/vba) / JS / APK etc.
□ Non-PE/script/APK/driver specialization: see §3.4 and `references/nonpe-format-cookbook.md` (U-AV)
□ file / DiE / entropy / packer signatures (PEiD / DiE / Exeinfo etc.)
□ Architecture: x86 / x64 / ARM; compiled-language leads (VC++ / Delphi / .NET / Go / Rust)
□ Packer-type leads: UPX / ASPack / VMProtect / Themida / unknown obfuscation
□ strings / rabin2 -z quick wins
□ MUST complete the import/export anchor (see "Import-Table Hard Gate and Equivalent Paths" below); if the user pre-empts and a packer is present -> walk §0.5 first
□ Output: E-triage (MUST contain an imports-or-equivalent anchor classification summary with a quality label when applicable) + hypothesis list
```

**Stage gate (Triage → Static/Dynamic)**: until imports **or** a legitimate equivalent anchor summary is recorded in E-triage, MUST NOT enter Dynamic (unless IAT repair failure was already recorded and a dynamic bypass was chosen, see §1.2), and MUST NOT claim "basic triage complete". When parsing fails, the failure output still MUST be written into Evidence — never skip. When the user asks to "redo the import-table check", MUST redo the imports/equivalent steps themselves (or first complete the §0.5 negotiated prerequisites); do not substitute other analysis steps to pose as completion.

### 1.1 Import-table hard gate and equivalent paths

| Sample type | MUST anchor (Evidence) | Notes |
|----------|----------------------|------|
| Native PE/ELF/Mach-O (IAT readable) | `E-imports` / `E-triage-imports`: import classification summary | `rabin2 -i` / IDA imports / equivalent |
| DLL / SYS / shared library | **Both** `E-imports` + `E-exports` (`rabin2 -i` + `rabin2 -E`) | The export table has priority equal to the import table (the external entry) |
| .NET managed (no classic IAT) | **Equivalent path**: dnSpy/IL/metadata/assembly references and sensitive API summary -> still written into the `E-imports` or `E-triage-imports` semantic slot | **Do not** leave the hard gate empty because "there is no IAT"; dnSpy inspection = native "inspect import table" |
| Import-table parse failure / empty / packed garbage table | Record the failure or garbage-table output as Evidence with a `quality` label | Never silently skip; a garbage table cannot support capability-denial conclusions |

**Clean import-table warning (MUST warn)**: if the import table is "too clean" (only kernel32/ntdll and other base DLLs, almost no business API), suspect `LoadLibrary` + `GetProcAddress` dynamic loading -> note the suspicion in Evidence and **SHOULD** transition to Dynamic to capture in-memory APIs; do not claim "no network/no file capability" from the static IAT alone.

**High-risk API combinations (patch 8 · SHOULD)**: when the import table is long, output the **malicious-combination clustering** first and filter out base system calls. Examples (not exhaustive):

- High-risk cluster: `FindWindowA/W` + `WriteProcessMemory` + `CreateRemoteThread` (injection)
- High-risk cluster: `CryptEncrypt` / `CryptAcquireContext` + many `FindFirstFile` / `DeleteFile` (ransomware tendency)
- High-risk cluster: `InternetOpen` / `WinHttp` / `URLDownloadToFile` + persistence APIs (`RegSetValue` / `CreateService`)
- Lone `CreateFile` / `ReadFile` etc. are mostly benign noise unless co-occurring with the clusters above

### 1.2 Unpacking and IAT handling (high-risk fork · Issue #65)

```text
Branch A: unpacked / .NET managed
  -> Enter §2 Static directly (.NET uses equivalent anchors)

Branch B: packed / heavy obfuscation
  Step 1: attempt unpacking (automatic unpacker / manually find OEP) — must be in an authorized, isolated environment
  Step 2: attempt IAT repair
    Tools: x86 -> ImportREC (or equivalent); x64 -> Scylla (or equivalent). Never grind a 64-bit sample with ImportREC.
    Situation B1: repair succeeds and parses -> record E-imports (post-repair) -> §2 Static
    Situation B2: ImportREC/Scylla reports errors, the repaired binary fails to run, or the IAT is fully garbled (VMP/encrypted packers)
      -> [IAT repair iron rule] Immediately terminate further static IAT repair
      -> MUST record E-iat-repair-fail (commands, tools, failure phenomena, decision to go dynamic)
      -> Enter §3 Dynamic directly: API breakpoints / hardware breakpoints / memory search to capture imports
      -> This is not "skipping the import table": the import-table path was attempted and recorded as Evidence
    Situation B3 (patch 6): after unpacking and IAT repair, double-click crashes instantly / blue screen (suspected file CRC/size self-check)
      -> Abandon further static file repair; record E-self-check-crash or fold into E-iat-repair-fail
      -> Transition to §3 Dynamic: break on CreateFile / GetFileSize / hash-related APIs to locate the self-check bypass point
```

**IAT repair iron rule (MUST)**: prefer automatic/semi-automatic repair; as soon as the repair tool reports an error or the repaired binary fails to run, **stop immediately** grinding the static import table, switch to dynamic debugging, and use API breakpoints (e.g., `bp CreateFile` / key network APIs) to capture imported functions at runtime.

## 2. Static (base static anchors → deep dive)

| Tool | When |
|------|------|
| radare2 / rabin2 | Fast functions/imports/strings (imports already MUST-completed at Triage, or an already-recorded failure bypass) |
| IDA / Ghidra (MCP or headless) | Deep dive, cross-references, types; re-verify the imports classification at the survey stage |
| jadx / dnSpy | Android / .NET |
| OLLVM documentation | Control-flow flattening suspected |

```text
□ Confirm E-imports / E-triage already contains import-table or equivalent anchor Evidence (fill it in first if missing — never retro-fill)
□ If DLL/SYS: confirm E-exports was recorded
□ Sensitive API grouping + high-risk combination clustering (patch 8)
□ Hardcoded domain/IP/URL strings; whether the resource section hides payloads
□ Locate key functions (crypto/self-check/network/license) -> write addresses/symbols into Evidence
□ One path dead ends -> switch tools (IDA↔r2↔Ghidra)
□ Time-box (patch 9 · SHOULD default): after ~15 minutes of static deep dive with no key path -> mandate transition to §3 Dynamic (user/task may override the duration)
```

**Without MCP**: export decompiled text and analyze it (the P4nda0s reverse-skills / IDA-NO-MCP approach), still writing the Evidence path.

## 3. Dynamic (cross-verification loop zone)

Core idea: **static provides leads -> dynamic verifies -> verification dead-ends -> back to static for re-review** (no fixed unique order).

### 3.0 Breakpoint opening sequence (patches 7 + 10 · MUST order)

Before launching the sample in a user-mode debugger (x64dbg etc.), preset breakpoints in the "four-stage rocket" order (names may differ per architecture/tool; the order does not):

1. **TLS callbacks** breakpoints (the debugger's EP may have already run past them)
2. **Entry point (EP)** breakpoint
3. **Sensitive APIs** breakpoints (e.g., `CreateRemoteThread` / network / file writes)
4. **Safety net**: `ExitProcess` / process-exit-path breakpoints (patch 10) — as soon as anti-debug causes a direct exit, **do not rush to restart**; dump memory immediately and write the pre-crash image path into Evidence for string/data recovery

```text
□ Frida / x64dbg / gdb / emulator: verify static hypotheses
□ Preset breakpoints per §3.0 before running; single-step through stack/registers (white-box)
□ Behavior monitoring: sandbox / Procmon / RegShot (black-box)
□ IAT repair failure / self-check crash samples: hardware breakpoints or memory search to force-capture APIs; CreateFile/GetFileSize for CRC
□ Anti-debug / anti-Frida -> reverse-engineering/anti-analysis
□ Android: generate root-detection / SSL-pinning bypass scripts on demand, **on an authorized device**
□ Crash logs drive the next round of hooking (adaptive loop)
□ Time-box (patch 9 · SHOULD default): after single-stepping ~200 instructions with no malicious-behavior leads -> mandate back to static string search / anchor switch (may override)
```

### 3.1 Sandbox / dynamic no-behavior emergency branch (MUST)

```text
No behavior or instant exit / infinite sleep
  -> Check anti-debug / anti-VM routines (CPUID, high-precision timing, sandbox artifacts etc.)
  -> Try hardware-breakpoint bypass, patching the detection points, or switching to a physical machine / higher-fidelity environment
  -> Write "no behavior + suspected anti-VM" into Evidence; never write "sample is benign" without conditions
```

### 3.2 Time-box strategy (patch 9 · SHOULD)

| Phase | Default threshold (user/task may override) | Action |
|------|------------------------------|------|
| Static deep dive with no key path | ~15 minutes | Transition to Dynamic |
| Dynamic single-step with no progress | ~200 instructions | Back to Static strings/cross-references to re-anchor |
| Any path repeatedly failing | Record Evidence, then switch tool or bypass | Never idle on the same failing method |

### 3.3 Anti-debug / deobfuscation bypass cheat sheet (Issue #65 patches A-T · high-frequency)

Full index and action details: `reverse-engineering/anti-analysis.md` "Agent Response Recipes A-T". Here only **P0 must-checks + common transitions**. Default: **authorized isolated lab**; patching/changing flag bits is not an unauthorized production action.

| Trigger signature | First action (summary) | Evidence |
|----------|------------------|----------|
| `cpuid` followed by jz/jnz (A) | Lab: change flag bits or patch to walk the real branch; record the detection-point address | `E-anti-debug-cpuid` |
| `rdtsc` + sub/cmp (B) | bp rdtsc or hook the time source; never idle forever waiting for sandbox timeout and call it "benign" | `E-anti-debug-rdtsc` |
| PEB BeingDebugged / NtGlobalFlag (K) | ScyllaHide or manually edit the PEB; patch the conditional jump | `E-anti-debug-peb` |
| `NtQueryInformationProcess` DebugPort/Flags/Object (P) | ScyllaHide / hook the return value; record the class parameter | `E-anti-debug-ntqip` |
| Very few imports but rich behavior -> API hashing (N) | bp GetProcAddress; hash-reverse-lookup and re-annotate in IDA | `E-api-hash` |
| Empty strings but network/file behavior -> string encryption (I) | Find the decode routine xref; decrypt, dump, and re-annotate | `E-string-decrypt` |
| A signature but suspicious source (F) | SigCheck: valid/revoked/timestamp; **invalid does not lower** the threat level | `E-sig-forge` |
| Standard strings have no IOC -> try wide characters (T) | `strings -el` / UTF-16LE; alt+A unicode | `E-wide-strings` |
| Debugger-name strings / Toolhelp scanning (C) | bp CreateToolhelp32Snapshot chain | `E-anti-debug-procscan` |
| AddVectoredExceptionHandler + deliberate exceptions (D) | bp the VEH registration; analyze the handler | `E-anti-debug-veh` |
| int3 / DR0-DR7 (M) | patch int3; soft breakpoints or ScyllaHide to hide hardware BPs | `E-anti-debug-bp` |
| Multi-PE headers/overlapping sections (G) | Section-table real mapping + entropy; never trust section names | `E-pe-anomaly` |
| File end > section sum Overlay (J) | Extract the overlay; file/entropy; find the load-offset xref | `E-overlay` |
| .rsrc abnormally large / high-entropy RT_RCDATA (Q) | Extract resources; FindResource chain + decrypt and dump | `E-rsrc-payload` |
| DLL loaded only at runtime (R) | Check Delay Imports; bp the delay-load helper | `E-delay-import` |
| while+switch star-shaped CFG (H) | **See** `ollvm-deobfuscation.md`; if plugins fail, go the dynamic path | `E-cff` |
| Always-true/always-false branches (S) | **See** ollvm / symbolic execution; dynamic verdicts win | `E-opaque-pred` |
| `/proc/self/status` TracerPid (L) | **Linux/ELF**; hook or patch; not mandated on the Windows main path | `E-anti-debug-tracerpid` |

**Constraints**: bypass failures also record Evidence; never write "anti-debug triggered exit" as "sample is benign". Full A-T and P2 (E compile-time, O garbage instruction) live in the anti-analysis recipe section.

### 3.4 Non-PE / multi-format bypass (Issue #65 patches U-AV · routing)

Full index: `reverse-engineering/references/nonpe-format-cookbook.md`. Here only **type → entry**; action details live in the cookbook / corresponding skill.

| Type | Jump | P0 Evidence anchor (example) |
|------|------|---------------------------|
| BAT/CMD | cookbook §1 + malware | `E-batch-deobf` |
| PowerShell | cookbook §2 + malware | `E-ps-decode-layer-N` |
| VBA macros | cookbook §3 + malware | `E-vba-pcode` |
| JS heavy obfuscation / JSVMP | **js-reverse** + cookbook §4 | `E-js-vmp` / `E-js-deobf` |
| SYS driver | kernel-driver-reverse + cookbook §5 | `E-driver-irp-handlers` / `E-driver-ioctl` |
| DLL specifics | cookbook §6 (AM≡A-T **R**) | `E-dll-tls-dllmain` / `E-exports` |
| Android device-wiper / hidden icons | **apk-reverse** + cookbook §7-8 | `E-android-wiper-*` / `E-android-hidden-icon-*` |

**Constraints**: do not start a parallel "non-PE six-phase"; division of labor with §3.3 A-T (PE anti-debug vs multi-format). Authorized lab; device-wipers/BYOVD/reflective = detection and forensics language.


## 4. Synthesis (IOCs / attack chain / report)

### Decision quality overlay (Issue #77)

Before closing Synthesis, apply [analysis-decision-framework.md](../../ops/analysis-decision-framework.md) **P0 checklist**: R41 grounded claims, R4* validated sufficiency, R1 confidence->dynamic, R2 hypothesis exit, R43 deadlock replan (under feasibility gate), R8/R23 no default malice/IOC. Multi-module -> R50; anti-analysis effort -> R51 + A-T cookbook.

Blindspots (Rust/Go/VMP/injection/OLE/PDF/agent-meta): [analysis-blindspot-cookbook.md](../../ops/analysis-blindspot-cookbook.md) R52-R81 — detection-oriented; not a parallel master flow.

```text
□ Finding: algorithm / self-check logic / exploitable point / behavioral conclusion
□ Path: callflow or solve steps anchored to E-*
□ IOC: network fingerprints + host fingerprints (record when present; when absent n/a + reason)
□ Report docs-generator (malware/apt/null/vuln overlay selected per task) + optional figures
□ Optional: YARA / Snort·Suricata rule artifacts
□ field-journal de-identification
```

## 5. Six-Phase Practical Mapping (Issue #65 mind-map → this file)

| Practical phase | This file's section | Hard gate / iron rule |
|----------|------------|-------------|
| 1 Initial fast assessment | §0-§1 Triage | Hash, architecture, file type, packer check; imports/equivalent anchors; §0.5 instruction gate |
| 2 Unpacking and IAT | §1.2 | IAT iron rule; failure / self-check crash -> Evidence -> Dynamic |
| 3 Base static anchors | §2 Static | High-risk API combinations; time-box SHOULD |
| 4 Deep cross-verification | §3 Dynamic | Four-stage rocket breakpoints; no-behavior emergency; time-box; §3.3 A-T; §3.4 U-AV type routing |
| 5 IOC and attack-chain extraction | §4 Synthesis | IOC + Kill Chain / Path |
| 6 Archiving and rule artifacts | §4 + docs-generator / YARA | Structured report; rules optional |

## 6. Differences from "RE skill plugin stacks"

- This pack uses **stage gates + tool-index**; it does not enable Hex-Rays "unsafe full-auto execution"-style plugins by default
- Dynamic instrumentation defaults to the **offline/lab** network_profile
- IAT/import table: **attempt + record** preferred over "infinite static grinding" or "silent skipping"
- User instructions: **goal first + prerequisite negotiation**; do not pose with unrelated steps as the named step
