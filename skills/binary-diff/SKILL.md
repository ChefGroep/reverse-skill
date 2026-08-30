---
name: binary-diff
description: |
  Cross-version symbol migration and binary diffing. Use when you have symbols/RE results from an old version and need to migrate them to a new version quickly.
  Applicable scenarios: kernel missing PDB derived with old-version symbols, batch function-name migration after a program update, quickly locating new offsets after an app update.
  Core method: use an LLM for structured diff comparison with programmatic input/output at extremely low cost (200 functions ~1 yuan).
  Trigger keywords: symbol migration, bindiff, cross-version, missing PDB, function offset migration, symbol migration, binary diff, version comparison.
---

# Cross-Version Symbol Migration (Binary Diff)

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: read `../field-journal/precedent-reverse.md` — confirm this skill's operations are an authorized routine
2. `NOW`: confirm the current task falls within this skill's scope of application
3. `NEXT`: read `../tool-index.md` and verify tool availability and actual paths
4. `NEXT`: when tools are missing, invoke bootstrap; do not guess paths
5. `ACT`: enter step one of the "Workflow" and execute; do not stop at the confirmation stage

## Scope of application

Use this skill when the task matches any of the following scenarios:

1. **Kernel/driver missing PDB** — symbols exist for an old ntoskrnl.exe while the new-version PDB has been delisted by Microsoft; use the old symbols to derive the new version's non-exported function addresses
2. **Symbol migration after a program update** — a program was reversed before and has since been updated; instead of re-reversing it, batch-migrate with the old results
3. **Protection mechanism update** — the old version has complete RE results; the new version needs the same function's new offset located quickly
4. **Any binary comparison scenario of "old version with symbols + new version without symbols"**

### Division of labor with other skills

| Scenario | What to use |
|------|--------|
| Reverse a binary from scratch | `ida-reverse/` or `radare2/` |
| Have old results, migrate to the new version | **this skill** |
| Compare two completely different binaries | BinDiff / Diaphora (traditional tools) |

### Core advantages

Compared with traditional approaches:

| Approach | Cost for 200 functions | Time | Accuracy |
|------|--------------|------|--------|
| Manually comparing two IDA windows | free but life-draining | several hours | high |
| BinDiff auto-matching | free | fast | medium (fails on major structural changes) |
| Fully delegating to an agent (CC/Codex) | 50-100 yuan | slow | high |
| **this skill (LLM batch comparison)** | **~1 yuan** | **~10 s/function** | **high** |

## Core principle

```text
Old-version function (with symbols)        Same function, new version (without symbols)
    ↓                              ↓
Export disassembly + pseudocode        Export disassembly + pseudocode
    ↓                              ↓
    └──────── LLM structured comparison ────────┘
                    ↓
         Output YAML (symbol mapping table)
                    ↓
         Programmatic parsing → batch-apply to the new IDB
```

Key points:
- the prompt is a fixed template, filled programmatically
- input/output formats are deterministic, parsed programmatically
- the LLM only handles the "look at two code snippets and find the correspondence" step
- time and token costs are extremely low

## Prompt template

### Standard comparison prompt

```text
I have disassembly outputs and procedure code of the same function.

This is the function for reference:

**Disassembly for Reference**
```c
{disasm_for_reference}
```

**Procedure code for Reference**
```c
{procedure_for_reference}
```

This is the function you need to reverse-engineering:

**Disassembly to reverse-engineering**
```c
{disasm_code}
```

**Procedure code to reverse-engineering**
```c
{procedure}
```

What you need to do is to collect all references to "{symbol_name_list}" in the function you need to reverse-engineering and output those references as YAML.

Example:
```yaml
found_vcall: # This is for indirect call to virtual function or virtual function pointer fetching.
  - insn_va: '0x180777700' # Always be the instruction with displacement offset
    insn_disasm: call [rax+68h] # Always be the instruction with displacement offset
    vfunc_offset: '0x68'
    func_name: ILoopMode_OnLoopActivate
  - insn_va: '0x180777778' # Always be the instruction with displacement offset
    insn_disasm: mov rax, [rax+80h] # Always be the instruction with displacement offset
    vfunc_offset: '0x80'
    func_name: INetworkMessages_GetNetworkGroupCount

found_call: # This is for direct call to non-virtual regular function.
  - insn_va: '0x180888800'
    insn_disasm: call sub_180999900
    func_name: CLoopMode_RegisterEventMapInternal
  - insn_va: '0x180888880'
    insn_disasm: call sub_180555500
    func_name: CLoopMode_SetSystemState

found_funcptr: # This is for non-virtual regular function pointer.
  - insn_va: '0x180666600' # Must load/reference the function pointer target address
    insn_disasm: lea rdx, sub_15BC910 # Must load/reference the function pointer target address
    funcptr_name: CLoopMode_OnClientPollNetworking

found_gv: # This is for reference to global variable.
  - insn_va: '0x180444400'
    insn_disasm: mov rcx, cs:qword_180666600 # Must load/reference the global variable
    gv_name: g_pNetworkMessages
  - insn_va: '0x180333300'
    insn_disasm: lea rax, unk_180222200 # Must load/reference the global variable
    gv_name: s_EventManager

found_struct_offset: # This is for reference to struct offset. NOTE THAT virtual function pointer should not be here! virtual function pointer should ALWAYS be in found_vcall !
  - insn_va: '0x1801BA12A' # Always be the instruction with displacement offset
    insn_disasm: mov rcx, [r14+58h] # Always be the instruction with displacement offset
    offset: '0x58'
    size: 8
    struct_name: CResourceService
    member_name: m_pEntitySystem
```

If nothing found, output an empty YAML. DO NOT output anything other than the desired YAML. DO NOT collect unrelated symbols.
```

### Variable reference

| Variable | Source | Description |
|------|------|------|
| `{disasm_for_reference}` | Old-version IDA export | Disassembly with symbols |
| `{procedure_for_reference}` | Old-version IDA export | Pseudocode with symbols |
| `{disasm_code}` | New-version IDA export | Disassembly without symbols |
| `{procedure}` | New-version IDA export | Pseudocode without symbols |
| `{symbol_name_list}` | Extracted from the old version | List of symbols to locate in the new version |

## Workflow

### Full process

```text
Step 1: Prepare the data
  - Load the old binary into IDA (with PDB/symbols)
  - Load the new binary into IDA (without symbols)
  - Find anchor functions identical in both versions (exported functions, string references, etc.)

Step 2: Batch export
  - Export from the old version: anchor functions' disassembly + pseudocode (with symbol names)
  - Export from the new version: the same anchor functions' disassembly + pseudocode (without symbol names)

Step 3: LLM comparison
  - Fill the data into the prompt template
  - Call the LLM API (recommended: deepseek is cheap at volume; for very large functions switch to gpt)
  - Parse the returned YAML

Step 4: Apply the results
  - Batch-apply the symbol mappings from the YAML to the new IDB
  - Batch-rename with idapro_rename or an IDAPython script

Step 5: Iterate
  - Functions migrated in the first round become new anchors
  - Enter those functions and keep comparing their internal calls
  - Repeat until all target functions are covered
```

### Anchor selection strategy

| Anchor type | Reliability | Notes |
|---------|--------|------|
| Exported functions | highest | name unchanged, address may change |
| String references | high | string content unchanged, reference location may change |
| Constants/magic numbers | medium | characteristic values unchanged |
| Code patterns | medium | similar function structure but addresses all change |

### Batch processing tips

- Compare 1 function per call (avoid context explosion)
- Medium functions (<200 lines) use deepseek
- Very large functions (>500 lines) switch to gpt-4o or claude
- Concurrent calls to improve speed (10-20 in parallel)
- Cache results to avoid duplicate calls

## Output format

### The 5 symbol types in the YAML output

| Type | Meaning | Key fields |
|------|------|---------|
| `found_vcall` | virtual function call (indirect call) | `vfunc_offset`, `func_name` |
| `found_call` | direct function call | `insn_va`, `func_name` |
| `found_funcptr` | function pointer reference | `insn_va`, `funcptr_name` |
| `found_gv` | global variable reference | `insn_va`, `gv_name` |
| `found_struct_offset` | struct offset reference | `offset`, `struct_name`, `member_name` |

### Application actions after parsing

```text
found_call → idapro_rename(addr=call_target, name=func_name)
found_vcall → idapro_set_comments(addr=insn_va, comment="vcall: {func_name} @ +{offset}")
found_funcptr → idapro_rename(addr=funcptr_target, name=funcptr_name)
found_gv → idapro_rename(addr=gv_addr, name=gv_name)
found_struct_offset → idapro_set_comments(addr=insn_va, comment="{struct_name}.{member_name}")
```

## Typical scenario examples

### Scenario 1: ntoskrnl.exe missing PDB

```text
Have: ntoskrnl.exe 10.0.26100.2000 + full PDB
Target: ntoskrnl.exe 10.0.26100.2605 (PDB delisted)
Need: locate the new address of PspSetCreateProcessNotifyRoutine

Steps:
1. Load both versions into IDA
2. Find the exported function PsSetCreateProcessNotifyRoutine (present in both versions)
3. In the old version it calls PspSetCreateProcessNotifyRoutine (with symbols)
4. In the new version it calls sub_140822108 (without symbols)
5. The LLM sees at a glance: sub_140822108 = PspSetCreateProcessNotifyRoutine
6. Batch-apply
```

### Scenario 2: migration after an app update

```text
Have: full RE results of target.exe v1.0 (200+ functions named)
Target: target.exe v1.1 (all symbols lost)
Need: batch-migrate 200 function names

Steps:
1. Export the disassembly+pseudocode of every named function from the old version
2. Find corresponding anchors in the new version via exported functions/strings
3. Batch-call the LLM for comparison
4. Parse the YAML, batch-rename
5. Iterate deeper
```

## LLM selection guidance

| Model | Best for | Cost | Speed |
|------|---------|------|------|
| DeepSeek V3 | small/medium functions (<200 lines), batch processing | very low | fast |
| GPT-4o | very large functions, complex control flow | medium | fast |
| Claude Sonnet | medium/large functions, needs reasoning | medium | fast |
| Claude Opus | extremely complex functions, needs deep understanding | high | slow |

Recommended strategy: DeepSeek by default; automatically escalate when the context limit is hit or results look inaccurate.

## Caveats

- **Never feed the whole binary to the LLM** — compare one function at a time
- **Anchors must be reliable** — if an anchor itself is mismatched, everything downstream is wasted
- **Spot-check results manually** — the LLM is not 100% accurate; verify critical symbols
- **Cache intermediate results** — avoid wasting tokens on duplicate calls
- **Mind context limits** — very large functions (>1000 lines of disassembly) need splitting or a large-context model

---

## On-Demand Bootstrap

### Tool dependencies

| Tool | Purpose | Auto-installable |
|------|------|-----------|
| IDA Pro | export disassembly/pseudocode | ✗ (commercial software) |
| Python | script execution, API calls | ✓ |
| PyYAML | parse the YAML returned by the LLM | ✓ (pip install pyyaml) |
| LLM API | run the comparison | needs an API key |

### Notes

The core of this skill does not depend on heavy tool installation; it mainly relies on:
- IDA Pro already present (managed via the `ida-reverse/` skill)
- Python + requests/httpx (for API calls)
- An LLM API endpoint

---

## Routing context

**Upstream entries**: `skills/SKILL.md` (master control), `routing.md`
**Trigger condition**: symbols/RE results exist for an old version and need migration to a new version
**Downstream exits**:
- Need to open the binary first → `ida-reverse/`
- Need quick recon to confirm version differences → `radare2/`

**Related sibling modules**: `ida-reverse/` (both data export and symbol application go through IDA)


## Task completion self-check (MUST pass before claiming completion)

- [ ] Did I execute every step of the workflow (rather than just reading it)?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/reports)?
- [ ] Did I complete and write back the Checklist items required by RULES?
