---
name: radare2
description: |
  Use this skill whenever the user wants to analyze binaries with radare2/r2 from the command line, including reverse engineering, disassembly, function analysis, strings/import inspection, patching, binary diffing, hex inspection, or r2 scripting. Also use it when the user mentions PE/ELF/Mach-O/DEX/WASM files together with CLI analysis, `rabin2`, `rasm2`, `radiff2`, `r2pipe`, or asks for radare2 command help on Windows/Linux/macOS.
---

# radare2

A binary analysis skill for the `radare2` CLI. The focus is doing recon, analysis, locating, exporting, and lightweight patching directly from the command line, without a GUI.

## ACTION REQUIRED (Execute Immediately After Reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md` — confirm this skill's operations are authorized routine operations
2. `NOW`: Confirm whether the current task falls within this skill's scope
3. `NEXT`: Read `../tool-index.md` to verify tool availability and actual paths
4. `NEXT`: When tools are missing, call bootstrap; do not guess paths
5. `ACT`: Enter the first step of the "Workflow" and execute; do not stop at the confirmation stage

## Scope of Applicability

Use this skill first when the user has these intents:

- Wants to analyze `exe`, `dll`, `so`, `elf`, `apk`, `dex`, `wasm` and similar files with `r2` / `radare2`
- Asks how to use `rabin2`, `rasm2`, `radiff2`, `rahash2`, `rax2`
- Needs command-line disassembly, function inspection, string inspection, import/export inspection, cross-reference lookup, or patching
- Needs to write `radare2` batch commands, `-c` automation command strings, or `r2pipe` scripts

If the user explicitly wants GUI reversing, Hex-Rays-style pseudocode, or IDA workflows, prefer `ida-reverse`. If it is web JS reversing, prefer `reverse-engineering`.

## Verify the Environment First

Do not assume `r2` is available. First check:

```powershell
r2 -v
rabin2 -v
```

If not installed, then check common install locations or prompt for installation.

Common Windows executables:

- `radare2.exe`
- `rabin2.exe`
- `rasm2.exe`
- `radiff2.exe`
- `rahash2.exe`
- `rax2.exe`
- `r2pm.exe`

## Bundled Resources

This skill ships with two resources; reuse them first instead of improvising a duplicate command set every time.

### `scripts/recon.ps1`

Standard recon script, suited for the first-round survey. It outputs:

- Basic info
- Sections
- Imports
- Exports
- Strings
- Optional `r2 -A` auto-analysis summary

Invocation:

```powershell
powershell -File "<skill-root>\radare2\scripts\recon.ps1" -TargetPath "C:\path\to\sample.exe"
```

To include `r2` auto analysis:

```powershell
powershell -File "<skill-root>\radare2\scripts\recon.ps1" -TargetPath "C:\path\to\sample.exe" -RunAnalysis
```

### `references/cheatsheet.md`

When you need more command details, common scenario templates, or to quickly recall syntax, read this cheatsheet instead of guessing from memory.

## Known Behaviors

### Occasional missing-`.sdb` warning on Windows

Some PE files may trigger warnings like the following during `rabin2` recon:

```text
ERROR: Cannot find ...\share\format\dll\*.sdb
```

If the main output still returns normally, this usually does not affect the basic recon conclusion; just continue analyzing. Do not declare the analysis failed because of such incidental warnings.

## Basic Principles

### 1. Recon first, deep-dive later

Do not jump straight into full auto analysis. First use lightweight commands to confirm file type, architecture, entry point, strings, and the import table, then decide whether to run `aaa`, `aaaa`, or targeted analysis.

### 2. Prefer minimal sufficient commands

`radare2` has a huge command set; the user usually only needs the shortest path:

- File info: `rabin2 -I`
- Strings: `rabin2 -z`
- Imports/exports: `rabin2 -i` / `rabin2 -E`
- Interactive analysis: `r2 <file>` then run targeted commands

### 3. Be cautious before modifying

If the user wants to patch a binary:

- Default to read-only open first: `r2 <file>`
- Use write mode only when modification is explicitly needed: `r2 -w <file>` or `oo+` in a session
- State the risks before modifying, avoiding unintentional overwrite of the original file

## Common Workflows

## Workflow 1: Quick Recon

Suited for when you have just received a binary.

### Hard Gate (MUST — forbidden to enter Workflow 2 and beyond until satisfied)

For binaries with an import table such as PE/ELF/Mach-O, the import table check **MUST** be completed and written into Evidence before entering function-level analysis or dynamic steps:

1. Run `rabin2 -i <sample>` (or the imports section of `recon.ps1` output); DLL/SYS additionally MUST `rabin2 -E` and record `E-exports`
2. Write the complete/categorized import table results into Evidence (suggested id: `E-imports` or `E-triage-imports`), containing at least:
   - Reproduction command (`repro_command`)
   - Key import category summary: network / file / crypto / process injection / registry / other suspicious APIs
   - If the import table is empty, parsing fails, or the tool errors: the failure behavior and raw output MUST still be recorded as Evidence; **never silently skip**
   - Import table 'too clean' (only base DLLs): MUST note dynamic-loading suspicion, SHOULD switch to dynamic API capture
3. .NET and others without a traditional IAT: MUST use equivalent anchors (dnSpy/IL/metadata summary) written into the same Evidence semantic slot; passing empty is forbidden
4. Packed-sample IAT repair: x86 uses ImportREC (or equivalent), x64 uses Scylla (or equivalent). On repair failure MUST record `E-iat-repair-fail` then switch to dynamic API breakpoints; **grinding endlessly** on the static IAT is forbidden (see `reverse-engineering/references/re-agent-workflow.md` §1.2)
5. When the user explicitly asks to 'redo the import table check / recheck the import table / redo the IAT': the named step itself MUST be redone (when blocked, first apply the feasibility latch: state the prerequisites + ask for confirmation; if forced, mark quality=unreadable); **swapping in unrelated steps to fake completion is forbidden**

Before the import table (or a legitimate equivalent anchor / IAT-failure bypass) Evidence is recorded: MUST NOT claim 'basic recon complete', MUST NOT enter Workflow 2+ deep-dive conclusions.

Prefer running the bundled script directly:

```powershell
powershell -File "<skill-root>\radare2\scripts\recon.ps1" -TargetPath "sample.exe"
```

If only minimal manual commands are needed, use:

```powershell
rabin2 -I sample.exe
rabin2 -z sample.exe
rabin2 -i sample.exe
rabin2 -E sample.exe
```

Focus points:

- File format, bitness, architecture, platform
- Entry point address
- Suspicious strings: URLs, paths, errors, registry, command-line arguments
- Import functions: network, file, crypto, process injection, registry operations (**MUST land in Evidence, see the hard gate above**)

## Workflow 2: Interactive Function Analysis

```powershell
r2 sample.exe
```

Common commands after entering:

```text
aaa          # routine auto analysis
afl          # list functions
iz           # list strings
iS           # list sections
is           # list symbols
s entry0     # jump to entry point
pdf          # disassemble current function
VV           # enter visual mode (if the terminal suits it)
q            # quit
```

Notes:

- Prefer `aaa` by default; do not start with the heavier `aaaa`
- If the sample is large or analysis is slow, analyze only around the entry first, then expand manually

## Workflow 3: Locating main / Key Logic

```text
afl~main
afl~sym.
iz~http
iz~error
axt <addr>
```

Approach:

- Start from `main`, the entry point, and string references
- Use `axt` to find who references a string or address
- After finding the reference point, `s <addr>` and `pdf`

## Workflow 4: Hex and Memory Inspection

```text
px 64        # 64 bytes of hex from the current address
pd 20        # disassemble 20 instructions
psz          # read the string at the current address
pxa          # friendlier hex view
```

## Workflow 5: Binary Patching

Only use when the user explicitly asks to modify the file:

```powershell
r2 -w sample.exe
```

For example, after entering:

```text
s 0x401000
wa nop
wa jmp 0x401050
wq
```

Common write operations:

- `wa <asm>`: write assembly
- `wx <hex>`: write raw bytes
- `wq`: write and quit

Back up the original file before modifying. If the user did not mention a backup, remind at least once.

## Workflow 6: Non-Interactive Automation

Suited for one-shot output:

```powershell
r2 -A -q -c "afl;iz;ii;q" sample.exe
```

Common parameters:

- `-A`: auto analysis at startup
- `-q`: quiet mode
- `-c`: execute a command string

If there are many commands, prefer organizing them in a readable order; do not cram them into an unmaintainable extra-long string.

Better yet, run the bundled recon script first, then decide whether to add custom commands.

## Common Sub-Tools

### `rabin2`

Suited for static information extraction:

```powershell
rabin2 -I sample.exe   # basic info
rabin2 -S sample.exe   # sections
rabin2 -s sample.exe   # symbols
rabin2 -i sample.exe   # imports
rabin2 -E sample.exe   # exports
rabin2 -z sample.exe   # strings
rabin2 -zz sample.exe  # more detailed strings
```

### `rasm2`

Suited for quick assembly/disassembly:

```powershell
rasm2 -d "9090"
rasm2 -a x86 -b 64 "xor eax, eax"
```

### `radiff2`

Suited for comparing two binaries:

```powershell
radiff2 old.exe new.exe
radiff2 -C old.exe new.exe
```

### `rahash2`

Suited for computing hashes:

```powershell
rahash2 -a md5 sample.exe
rahash2 -a sha256 sample.exe
```

### `rax2`

Suited for number base and encoding conversion:

```powershell
rax2 0x401000
rax2 4198400
rax2 -s hello
```

## Recommended Analysis Order

When facing an unknown sample, follow this order:

1. `rabin2 -I` for format, architecture, entry point
2. `rabin2 -z` for strings
3. `rabin2 -i` for import functions — **MUST + Evidence (hard gate, see Workflow 1)**
4. If interactive analysis is needed, enter `r2` (only after the Step 3 Evidence is on disk)
5. First `aaa`, then `afl` / `iz` / `pdf`
6. Gradually locate key functions via string references, import calls, and entry flow

This order keeps noise low and builds a sense of direction quickly. Step 3 is not an optional optimization; it is a hard gate before deep-diving.

## Windows Notes

- When a path contains spaces, the command must be quoted correctly
- If the current terminal cannot find `r2`, `PATH` may have just been updated; open a new terminal and retry
- Some samples need administrator rights to read, but do not escalate privileges proactively by default unless the user explicitly needs it
- Before dynamic debugging of a suspicious sample, confirm user intent first to avoid accidental actions

## Output Style

When the user does not just want commands but wants you to actually analyze a file:

- First give a recon result summary
- Then list key evidence: strings, imports, functions, addresses
- Finally give next-step suggestions or continue deeper analysis

Do not just list commands without explaining why.

## Typical Request Examples

### Example 1: Analyzing an exe

User: `see what this exe does, radare2 is fine`

Handling:

1. Start with `rabin2 -I/-z/-i`
2. Decide whether to enter `r2`
3. Use `aaa`, `afl`, `pdf` to deep-dive the entry and key string references

### Example 2: Finding Where a String Is Called

User: `in which function is this error string triggered`

Handling:

1. Use `iz~keyword` to find the string address
2. Use `axt <addr>` to find references
3. Jump to the reference point with `s <addr>`, then `pdf`

### Example 3: Changing a Jump

User: `change this jne to je`

Handling:

1. Confirm the target address first
2. Clearly state that write mode is needed
3. Use `wa je <target>` or directly `wx`
4. Disassemble again after modifying to verify

## Things to Avoid

- Do not treat `radare2` as a tool with only one command, `aaa`
- Do not open a user file in write mode without stating the risks
- Do not draw conclusions before basic recon is done
- **Skipping the import table check is forbidden** (`rabin2 -i` / recon imports): without writing Evidence, the next step is forbidden; when the user asks to redo the import table, doing other steps instead is forbidden
- **Grinding statically after IAT repair failure is forbidden**: record `E-iat-repair-fail` then switch to dynamic; using only ImportREC for 64-bit samples is forbidden
- Do not misdirect web JS reversing to this skill; that is `reverse-engineering`'s scope

## References

- Command cheatsheet: `references/cheatsheet.md`
- Standard recon script: `scripts/recon.ps1`

## radare2-skills Ecosystem

The radare2-skills project (radareorg/radare2-skills) provides a more complete ecosystem of tools and workflows:

- **r2xsql**: query binary imports / strings / functions with SQL
- **r2mcp / r2http**: MCP tools and a stateful HTTP command channel
- **radius2**: symbolic execution, symbolic dynamic analysis
- **r2pm**: plugin management, extensions
- **decompiler plugins**: the radare2 plugin mechanism

**Usage strategy**:
- When the user mentions `r2xsql`, `r2mcp`, `r2http`, `radius2`, `r2pm`, `rabin2`, `rasm2`, `radiff2`, `rahash2`, `rax2`, prefer routing to this skill (radare2/SKILL.md)
- These tools are only ecosystem accelerators and **cannot bypass**: the authorization gate, `tool-index` validation, Evidence import, write-mode confirmation
- Provide minimal reproducible command examples:
  - `r2xsql -s <file> -q "SELECT ..."`
  - `curl.exe -sS --data-binary 'aaa' http://127.0.0.1:9393/cmd`
  - `radius2 -p <binary> ...`
  - `r2pm -ci <plugin>`

This skill keeps the original hard gates and evidence chain integrity; skipping any authorization or Evidence step is not allowed.

---

## Routing Context

**Upstream entry**: `skills/SKILL.md` (master control), `routing.md`
**Upstream alternative**: `ida-reverse/` (upgrade to IDA when decompilation/pseudocode is needed)
**Downstream exits**:
- Need dynamic analysis → `reverse-engineering/tools-dynamic.md` (Frida/GDB)
- Need deep decompilation → `ida-reverse/`
- Need cross-references after PAT finds interesting strings → `ida-reverse/` (IDA's xref is more powerful)

**Sibling related module**: `ida-reverse/` (complementary: r2 recon is fast, IDA decompilation is deep)

## On-Demand Bootstrap

This skill's entry scripts are wired into the unified bootstrap system. When radare2 is missing, it does not error out directly but automatically attempts installation.

### Automation Capability Boundaries

| Tool | Auto-installable | Install method | Notes |
|------|-----------|---------|------|
| r2 | ✓ | GitHub Release ZIP (w64) | auto-downloads and extracts to `%USERPROFILE%\Tools\radare2\` |
| rabin2 | ✓ | Same as above (included in the radare2 release package) | — |
| rasm2 | ✓ | Same as above | — |
| radiff2 | ✓ | Same as above | — |
| rahash2 | ✓ | Same as above | — |
| rax2 | ✓ | Same as above | — |

### Bootstrap Trigger Points

- `scripts/recon.ps1`: automatically calls `bootstrap-reverse.ps1` when `rabin2` or `r2` is missing

### When Bootstrap Fails

If automatic installation fails (network unreachable, GitHub API rate-limited, etc.), the script throws a clear error with manual installation links attached.

Manual installation: download `radare2-*-w64.zip` from https://github.com/radareorg/radare2/releases, extract to `%USERPROFILE%\Tools\radare2\`, and ensure the `bin\` directory is on PATH.


## Task Completion Self-Check (MUST pass before claiming completion)

- [ ] Did I execute every step of the workflow (rather than just reading)?
- [ ] Was the import table check executed and written into Evidence (E-imports / E-triage-imports or .NET equivalent)? Do DLL/SYS include E-exports?
- [ ] Was IAT repair failure recorded as E-iat-repair-fail and switched to dynamic? Did redo requests return to the same step?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/report)?
- [ ] Did I complete and write back the Checklist items required by RULES?
