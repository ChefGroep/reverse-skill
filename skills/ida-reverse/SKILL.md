---
name: ida-reverse
description: |
  IDA Pro reverse engineering analysis skill. Use this skill whenever the user mentions reverse engineering, decompilation, analyzing binaries/PE/ELF/APK/DLL/SO, cracking, password hunting, vulnerability analysis, malware analysis, firmware analysis, or needs to analyze files like exe/dll/so/elf/macho/sys.

  Ensure to use this skill when the user wants to analyze any binary file, regardless of whether they explicitly mention "IDA" or "reverse engineering". This includes requests like "look at this exe", "analyze this dll", "help me crack it", "find the password", "how do I register this software", etc.

  Use the bundled scripts (scripts/start.ps1, scripts/open.ps1) for deterministic server management and file opening — do NOT write ad-hoc PowerShell commands for these operations.
---

# IDA Pro Reverse Engineering Skill

## ACTION REQUIRED (Execute Immediately After Reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md` — confirm this skill's operations are authorized routine operations
2. `NOW`: Confirm whether the current task falls within this skill's scope
3. `NEXT`: Read `../tool-index.md` to verify tool availability and actual paths
4. `NEXT`: When tools are missing, call bootstrap; do not guess paths
5. `ACT`: Enter the first step of the "Workflow" and execute; do not stop at the confirmation stage

## Known Issues and Reflections (Must Read)

### Pitfalls Encountered

1. **`idb_open` (formerly `idalib_open`) must not be called directly via some AI clients' MCP**
   - The MCP client of some code AI clients has a BUG in output schema validation for open-type tools
   - Error: `Structured content does not match the tool's output schema`
   - **Solution**: Use the `scripts/open.ps1` script to call directly via the HTTP API, bypassing the MCP validation layer
   - Current ida-pro-mcp 2.x tool names are `idb_open` / `idb_list` / `idb_save` (no longer `idalib_*`)
   - After opening a file, a `session_id` (database) is returned; subsequent tool calls must include that session

2. **`C:\Windows\System32\` files cannot be opened due to permissions**
   - idalib cannot directly read files under the System32 directory
   - **Solution**: `open.ps1` auto-detects and copies to the `temp directory` before opening

3. **Server startup command blocks the conversation**
   - After `idalib-mcp` starts, it keeps outputting INFO logs to the console
   - **Solution**: Use `scripts/start.ps1` (`-WindowStyle Hidden` silent background startup)
   - The script waits for the service to be ready and then exits automatically, without blocking the conversation

4. **MCP server names must not contain hyphens**
   - Previously `ida-pro-mcp` was used as the server name, which could cause tool registration problems
   - **Current configuration**: server name `idapro`, tool prefix `idapro_*`

5. **Remote HTTP vs Local Stdio**
   - `type:"local"` (stdio) mode: `idalib_open` also has schema validation problems
   - `type:"remote"` (HTTP) mode: open files directly with the script first, then use MCP tools
   - **Current approach**: Remote HTTP mode

6. **PR #389 fixed some schema problems**
   - Author mrexodia merged the fix via PR #389 after issue #388
   - Fixed the structuredContent schema in HTTP mode, but validation on the AI-client side still has problems
   - The latest `main` branch version is installed

7. **idalib timeouts leave orphan worker process lock files**
   - After the first `open.ps1` timeout, idalib's python worker child process may become an orphan, holding on to `.id0`/`.id1`/`.nam`
   - Any subsequent tool or manually dragging into the IDA GUI will report "insufficient permissions"
   - **Never** use `taskkill /F /T` to kill the process tree — `/T` would also kill the GUI `ida.exe` child process
   - **Solution**: `start.ps1` replaces the managed supervisor only when nobody listens on the port, or when `tools/list` returns quickly but lacks `py_eval` (old supervisor); treat an RPC timeout with 13337 still listening as busy, and do not kill
   - **Fallback**: when `open.ps1` detects the old database is locked, it automatically copies to Temp with a GUID prefix

8. **Opening with auto analysis looks like a hang**
   - `idalib_open(run_auto_analysis=true)` may not respond for a long time, but the backend is actually still opening and analyzing
   - Previously the user side saw "PowerShell with no output", easily misjudged as the script hanging
   - **Current solution**: `open.ps1` adds `-TimeoutSeconds`, and switches to a background request + foreground polling + periodic progress output
   - When polling finds the session ready, it returns early with `OK:filename:session_id`; on timeout it returns `ERR:open_timeout_xxs`

9. **HTTP MCP silently exits after login**
   - Cursor/Claude's `type: http` does not spawn the process for you; the old scheduled task only ran once at login
   - `pythonw` has no console, and the Application log is empty when it crashes
   - **Solution**: `start.ps1` reuses by default if healthy; `watchdog.ps1` checks every minute; logs at `%LOCALAPPDATA%\reverse-skill\ida-mcp\`
   - Install: `scripts/install-autostart.ps1`. If the port is not yet up when Cursor starts, you still need to manually refresh once in the MCP panel

### Workflow Principles

| Step | What | Tool |
|------|--------|--------|
| 1 | Ensure the HTTP server is running | `scripts/start.ps1` (no arguments) |
| 2 | Open the target binary | `scripts/open.ps1 -Path "xxx.exe"` |
| 3 | Use the MCP analysis tools | Call `idapro_*` / HTTP tools directly (about 65, depending on version) |
| 4 | Analysis finished | Tools are automatically available |

## Script Resources

### start.ps1 — Start the MCP HTTP Server

Path: `scripts/start.ps1`

- Auto-resolves `IDADIR` (environment variable / portable desktop path / common install paths)
- Prefers IDA's bundled `Python314\python.exe -m ida_pro_mcp.idalib_supervisor`
- By default probes `http://127.0.0.1:13337/mcp` first; if healthy outputs `OK:<n>:reuse` and exits
- If 13337 is listening but `tools/list` times out → `WARN:busy` / `OK:busy:reuse`; **never kill** (the supervisor is single-threaded and cannot respond while opening a database)
- Replaces the managed supervisor only when nobody listens on the port, or when it returns quickly and lacks `py_eval`; **never kill `ida.exe`, never use `taskkill /T`**
- When the GUI occupies 13337, outputs `WARN:gui_busy` and exits without starting another supervisor
- On success outputs `OK:<tool count>` (currently about 66), on failure outputs `ERR:timeout`
- Supervisor log: `%LOCALAPPDATA%\reverse-skill\ida-mcp\supervisor.log`
- The server runs in the background without blocking the conversation

**Invocation**:
```
powershell -File "<skill-root>\ida-reverse\scripts\start.ps1"
```

### watchdog.ps1 / install-autostart.ps1 — Keep-Alive

- `watchdog.ps1`: probes 13337; if healthy outputs `OK:<n>:reuse`, only calls `start.ps1` when it is down
- `install-autostart.ps1`: registers the scheduled task `reverse-skill-ida-mcp` (at login + every minute)
- Log: `%LOCALAPPDATA%\reverse-skill\ida-mcp\watchdog.log`

### open.ps1 — Open a Binary File

Path: `scripts/open.ps1`

- Calls `idb_open` directly via the HTTP API, bypassing MCP schema validation
- Auto-detects System32 paths and copies to a temp directory
- Automatically cleans up old same-named database files (`.id0`/`.id1`/`.nam`/`.til`/`.i64`)
- Auto-degrades when the old database is locked: copies to Temp with a GUID prefix and opens it, without errors
- Runs the open request in the background, avoiding long synchronous waits that leave the script unresponsive
- Supports `-TimeoutSeconds`; on timeout returns `ERR:open_timeout_xxs` and never hangs forever
- Outputs `INFO:opening:<elapsed>/<timeout>s` every 10 seconds, making it easy to tell that analysis is still in progress
- On success outputs `OK:filename:session_id`, with a `(temp copy)` marker when degraded
- On failure automatically retries via the Temp copy

**Invocation**:
```
powershell -File "<skill-root>\ida-reverse\scripts\open.ps1" -Path "C:\path\to\file.exe"
```

**Optional parameters**:
```
# Specify SessionId
powershell -File "scripts\open.ps1" -Path "file.exe" -SessionId "my_session"

# Skip auto analysis (recommended for large files)
powershell -File "scripts\open.ps1" -Path "large.exe" -NoAutoAnalysis

# Set a timeout to avoid long waits without output when auto analysis is enabled
powershell -File "scripts\open.ps1" -Path "file.exe" -TimeoutSeconds 600
```

**Output conventions**:
```
# Analysis in progress (output once every 10 seconds)
INFO:opening:11/600s

# Opened successfully
OK:sample.exe:abcd1234

# Opened successfully, but degraded to a Temp copy due to a lock file
OK:1234abcd-sample.exe:abcd1234 (temp copy)

# Reached the timeout limit
ERR:open_timeout_600s
```

**Field test notes**:
- Field test: `Snipaste.exe` with auto analysis took about `324s` to return success — that is "analysis takes long", not "script deadlock"
- Therefore, when facing GUI programs or more complex samples, prefer explicitly setting `-TimeoutSeconds 600`

## Core Tool List

### Survey Analysis (First Step)
- `idapro_survey_binary(detail_level="minimal")` — quick survey: function count, strings, segments, entry points, import categories (crypto/network/file IO)
- `idapro_list_funcs(queries)` — list functions (paginated, filtered by name)
- `idapro_list_globals(queries)` — list globals
- `idapro_entity_query(kind, filter)` — unified query: functions/globals/imports/strings/names

### Decompilation and Disassembly
- `idapro_decompile(addr)` — decompile to pseudocode
- `idapro_disasm(addr, max_instructions=N)` — disassemble
- `idapro_analyze_function(addr, include_asm=false)` — comprehensive analysis (pseudocode+strings+constants+callers+callees+blocks)
- `idapro_func_profile(queries)` — function summary metrics

### Cross-References and Data Flow
- `idapro_xrefs_to(addrs)` — find who references the target address
- `idapro_xref_query(addr, direction)` — advanced xref query (direction/type filtering)
- `idapro_callees(addrs)` — list of callees (sub-functions)
- `idapro_callgraph(roots, max_depth)` — call graph
- `idapro_trace_data_flow(addr, direction, max_depth)` — data flow tracing (forward/backward)

### Search
- `idapro_find_regex(pattern, limit)` — regex search over strings
- `idapro_search_text(pattern)` — search text in the disassembly listing
- `idapro_find_bytes(patterns, limit)` — byte pattern search (supports ?? wildcards)
- `idapro_find(type, targets)` — advanced search (immediates/strings/references)

### Memory and Data
- `idapro_get_bytes(addrs)` — read raw bytes
- `idapro_get_string(addrs)` — read strings
- `idapro_get_int(queries)` — read integer values
- `idapro_get_global_value(queries)` — read global variable values
- `idapro_read_struct(queries)` — read struct field values
- `idapro_search_structs(filter)` — search structs

### Modification Operations
- `idapro_set_comments(items)` — add comments (two-way sync between disassembly and decompilation)
- `idapro_append_comments(items)` — append comments
- `idapro_rename(batch)` — batch rename (functions/globals/locals/stack variables)
- `idapro_patch_asm(items)` — patch assembly instructions
- `idapro_patch(patches)` — patch bytes
- `idapro_define_func(items)` — define functions
- `idapro_undefine(items)` — undefine
- `idapro_define_code(items)` — convert bytes to code

### Type System
- `idapro_declare_type(decls)` — declare C structs/enums/unions
- `idapro_set_type(edits)` — apply types to functions/globals/locals
- `idapro_infer_types(addrs)` — infer types
- `idapro_type_query(queries)` — query declared types
- `idapro_type_inspect(queries)` — inspect type details

### Stack Frames
- `idapro_stack_frame(addrs)` — view stack frame variables
- `idapro_declare_stack(items)` — declare stack variables
- `idapro_delete_stack(items)` — delete stack variables

### Signatures
- `idapro_make_signature(addrs)` — generate a unique byte signature for addresses
- `idapro_make_signature_for_function(addrs)` — generate a signature for functions
- `idapro_find_xref_signatures(addrs)` — generate signatures for code referencing the addresses

### Debugger (requires ?ext=dbg)
- `idapro_open_file(file_path)` — open a file in the GUI IDA instance
- Debugger tools are hidden by default and can be enabled via the URL parameter `?ext=dbg`

### Session Management (ida-pro-mcp 2.x)
- `idapro_idb_open` / HTTP `idb_open` — ⚠️ prefer opening with `open.ps1`
- `idapro_idb_list` / HTTP `idb_list` — list all sessions
- `idapro_idb_save` / HTTP `idb_save` — save the database
- Most analysis tools require the `database=<session_id>` parameter (the session output by open.ps1)

### Miscellaneous
- `idapro_int_convert(inputs)` — number base conversion (**must use this; do not compute bases yourself!**)
- `idapro_export_funcs(addrs, format)` — export functions (json/c_header/prototypes)
- `idapro_py_eval(code)` — execute Python in the IDA context
- `idapro_server_health()` — server health check
- `idapro_server_warmup()` — warm up subsystems (string cache, Hex-Rays, etc.)

## Complete Reverse Engineering Workflow

### Step 1: Start the Server

**Path A — Headless idalib (requires a valid license)**
```
powershell -File "scripts/start.ps1"
```
Output `OK:<tool count>` (currently about 65) means ready.

**Path B — GUI + plugin (when the idalib license fails or interactive analysis is needed)**
```
powershell -File "scripts/start-gui.ps1" -Path "C:\target.exe"
```
Or double-click the portable `Launch-IDA-Pro.cmd` and open the sample in IDA.

After confirming `[MCP] ... port=13337` appears in the Output window, the MCP tools are usable.

See `LOCAL-SETUP.md` for generic integration steps.

### Step 2: Open the File

Headless:
```
powershell -File "scripts/open.ps1" -Path "C:\target.exe" -TimeoutSeconds 600
```
Output `OK:filename:session_id` means success (a trailing `(temp copy)` means auto-degraded to a temp copy).

If `ERR:idalib_license:...` appears, switch to Path B (GUI mode); do not keep retrying open.ps1.

GUI mode: just Open the sample directly in IDA; open.ps1 is not needed.

### Step 3: Global Overview (with the import table hard gate)
```
idapro_survey_binary(detail_level="minimal")
```
Focus on:
- Architecture (x86/x64/ARM)
- Entry points (main/WinMain/DllMain)
- Interesting strings (URLs, paths, error messages)
- **Import categories (MUST)**: crypto functions / network APIs / file operations / process injection / registry — must be written into Evidence (suggested id: `E-imports`), using `idapro_entity_query(kind="imports")` or the imports section of the survey output
- **DLL/SYS**: exports table alongside the imports table (Evidence `E-exports`)
- **.NET**: when there is no traditional IAT, use the module/metadata/managed reference summary as an equivalent anchor written into the E-imports semantic slot
- **Clean import table**: note suspicion of dynamic loading and push for dynamic API breakpoint verification
- Hot functions (functions with high xref counts are usually the key logic)

**Hard gate**: before the imports view/category summary (or a legitimate equivalent anchor) is written into Evidence, MUST NOT enter Step 4 for deep-dive conclusions, and MUST NOT claim the survey is complete. When the import table is empty or the query fails, the failure MUST still be recorded. When packed-IAT repair fails, MUST record `E-iat-repair-fail` and switch to dynamic debugging to catch APIs; grinding statically is forbidden. When the user asks to redo the import table/IAT check, the named step MUST be redone (when blocked, feasibility latch: explain + confirm; if forced, mark quality=unreadable); swapping in unrelated steps is forbidden.

### Step 4: Deep-Dive into Key Functions
```
idapro_analyze_function(addr="key function name")
```
Or:
```
idapro_decompile(addr="function name")
idapro_disasm(addr="function name", max_instructions=50)
```

### Step 5: Data Flow and Cross-References
```
idapro_xrefs_to(addrs="key addresses/strings")
idapro_callgraph(roots=["key function"], max_depth=3)
idapro_trace_data_flow(addr="key address", direction="backward", max_depth=5)
```

### Step 6: Record and Refine
```
idapro_set_comments(items=[{"addr": "0x140001000", "comment": "your understanding"}])
idapro_rename(batch={"func": [{"addr": "function address", "name": "meaningful name"}]})
```

### Step 7: Output the Report
After the analysis is complete, generate `report.md` recording findings and steps.

## Prompt Engineering Guidelines

1. **Never compute number bases manually** — whenever you need to convert a number, use `idapro_int_convert`
2. **Survey first, then deep-dive** — look at the overview before targeted analysis
3. **Keep adding comments and renaming** — continuously update function and variable names during analysis to improve the accuracy of later analysis
4. **Follow cross-references** — when you find interesting data/strings, use `xrefs_to` to see who references them
5. **When facing obfuscated code** — do preprocessing first such as string decryption, import hash removal, control flow flattening removal
6. **C++ STL code** — use FLIRT/Lumina to identify library functions, then analyze the business logic
7. **Do not brute-force** — the analysis should derive the solution from the disassembly, using simple Python to assist with computation
8. **When facing "No database bound"** — no binary has been opened yet; run `open.ps1` first
9. **When facing "Failed to open database"** — an old database file may be locked; `open.ps1` will auto-degrade to a Temp copy (output includes the `(temp copy)` marker)
10. **When opening GUI/complex samples with auto analysis** — add `-TimeoutSeconds 600` by default; do not misjudge long-running `INFO:opening:...` as the script hanging

---

## Routing Context

**Upstream entry**: `skills/SKILL.md` (master control), `routing.md`
**Upstream alternative**: `radare2/` (if you do not want to open IDA, you can do quick recon with r2 first)
**Downstream exits**:
- Need Frida dynamic verification → `reverse-engineering/tools-dynamic.md`
- Need symbolic execution/angr → `reverse-engineering/tools-dynamic.md`
- Need generic reverse engineering methodology → `reverse-engineering/SKILL.md`

**Sibling related module**: `radare2/` (alternative when IDA is unavailable)

---

## On-Demand Bootstrap

This skill's entry scripts are already wired into the unified bootstrap system.

### Automation Capability Boundaries

| Tool | Auto-installable | Install method | Notes |
|------|-----------|---------|------|
| idalib-mcp | ✓ | pip install (from GitHub) | auto-installed when `start.ps1` finds it missing |
| IDA Pro itself | ✗ | Commercial software, requires manual installation | Set the `IDADIR` environment variable to the install directory |

### Installation Steps (verified)

```cmd
# 1. Set the IDA path (replace with your actual IDA install directory)
setx IDADIR "<your IDA install directory>"

# 2. Install ida-pro-mcp from GitHub (the ida-mcp on PyPI is a different project, do not install the wrong one!)
pip install git+https://github.com/mrexodia/ida-pro-mcp.git

# 3. Install the IDA plugin (choose Streamable HTTP + Global + select all clients)
ida-pro-mcp --install

# 4. Restart IDA Pro and open the target file
# The plugin automatically listens on 127.0.0.1:13337

# 5. Verify
ida-pro-mcp --config
```

> ⚠️ **Note**: the `ida-mcp` package on PyPI (author jtsylve) is a different project, not the one we need.
> Install `mrexodia/ida-pro-mcp` from GitHub.

### Bootstrap Trigger Points

- `scripts/start.ps1`: automatically calls `bootstrap-reverse.ps1` when `idalib-mcp` is missing
- MCP registration: bootstrap automatically writes `idapro` into the Claude MCP configuration

### Prerequisites

- IDA Pro is installed and the `IDADIR` environment variable is set (or the default path inside the script is correct)
- Prefer the `ida-pro-mcp` from IDA's bundled Python314 (already built into the portable version)
- Common local configuration:
  - User env `IDADIR` → IDA install directory (contains `ida.exe`)
  - Optional `~\Tools\bin\idalib-mcp.cmd` / `ida-pro-mcp.cmd` wrappers
  - Client MCP server name keeps only `idapro` → `http://127.0.0.1:13337/mcp`


## Task Completion Self-Check (MUST pass before claiming completion)

- [ ] Did I execute every step of the workflow (rather than just reading)?
- [ ] Are survey/imports written into Evidence (E-imports or equivalent)? Do DLL/SYS include E-exports? Is IAT failure recorded as E-iat-repair-fail?
- [ ] If the user asked to redo the import table/IAT, did I redo the same step?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/report)?
- [ ] Did I complete and write back the Checklist items required by RULES?
