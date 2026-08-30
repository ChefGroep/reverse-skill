# IDA Pro MCP Tool Cheatsheet

> ida-pro-mcp 2.x tools organized by function, with common parameters and typical usage.
> Server name: `idapro`, tool prefix: `idapro_*`, running in HTTP mode. Tool count varies by version (about 66, including `py_eval`).

---

## Startup and Session Management

### Server Startup

```powershell
# Start the MCP HTTP server (silent background; if healthy OK:<n>:reuse)
powershell -File "scripts/start.ps1"
# Output OK:<tool count> means ready (about 66, including py_eval)

# Open the target file (bypasses schema validation)
powershell -File "scripts/open.ps1" -Path "C:\target.exe"
# Output OK:filename:session_id

# Large files / GUI programs recommend a timeout
powershell -File "scripts/open.ps1" -Path "C:\big.exe" -TimeoutSeconds 600

# Skip auto analysis (fast open)
powershell -File "scripts/open.ps1" -Path "C:\huge.sys" -NoAutoAnalysis
```

### Session Tools

| Tool | Purpose | Example |
|------|------|------|
| `idapro_idb_list()` / HTTP `idb_list` | List all sessions | — |
| `idapro_idb_open()` / HTTP `idb_open` | Open a database (prefer `open.ps1`) | Large files go through the script |
| `idapro_idb_save(path)` / HTTP `idb_save` | Save the database | Save analysis progress |
| `idapro_idb_current()` | Currently bound session (if the version provides it) | — |
| `idapro_idb_switch(session_id)` | Switch session | When comparing multiple files |
| `idapro_idb_close(session_id)` | Close session | Release resources |
| `idapro_server_health()` | Server health check | — |
| `idapro_server_warmup()` | Warm up subsystems | Before first use |

---

## Step 1: Global Overview

### survey_binary — Quick Survey

```
idapro_survey_binary(detail_level="minimal")
```

Returns:
- Architecture (x86/x64/ARM/MIPS)
- Entry points
- Total function count
- String statistics
- Segment info
- Import categories (crypto/network/file IO/registry)
- Hot functions with high xref counts

**detail_level options**:
- `"minimal"` — quick survey (recommended first choice)
- `"standard"` — includes more details
- `"full"` — complete information

### Function List

```
# List all functions (paginated)
idapro_list_funcs(queries=[{"offset": 0, "limit": 50}])

# Filter by name
idapro_list_funcs(queries=[{"filter": "crypt", "offset": 0, "limit": 20}])
idapro_list_funcs(queries=[{"filter": "main", "offset": 0, "limit": 10}])
```

### Unified Query

```
# Query import functions
idapro_entity_query(kind="imports", filter="Create")

# Query strings
idapro_entity_query(kind="strings", filter="http")

# Query all named symbols
idapro_entity_query(kind="names", filter="")
```

---

## Decompilation and Disassembly

### Decompilation (Pseudocode)

```
# By function name
idapro_decompile(addr="main")
idapro_decompile(addr="sub_140001000")

# By address
idapro_decompile(addr="0x140001000")
```

### Disassembly

```
# Default instruction count
idapro_disasm(addr="main")

# Specify instruction count
idapro_disasm(addr="0x401000", max_instructions=100)
```

### Comprehensive Analysis (recommended)

```
# One-shot fetch: pseudocode + strings + constants + callers + callees + basic blocks
idapro_analyze_function(addr="main", include_asm=false)

# Include assembly
idapro_analyze_function(addr="sub_401000", include_asm=true)
```

### Function Summary

```
# Batch-fetch function metrics (size, block count, xref count)
idapro_func_profile(queries=["main", "sub_401000", "sub_402000"])
```

---

## Cross-References and Call Graph

### Who References the Target

```
# See who calls a function
idapro_xrefs_to(addrs=["sub_401000"])

# See who references a string/data
idapro_xrefs_to(addrs=["0x404000"])

# Batch query
idapro_xrefs_to(addrs=["CreateFileW", "ReadFile", "WriteFile"])
```

### Advanced xref Query

```
# Specify direction and type
idapro_xref_query(addr="0x401000", direction="to")    # who references me
idapro_xref_query(addr="0x401000", direction="from")  # who do I reference
```

### List of Callees

```
idapro_callees(addrs=["main"])
```

### Call Graph

```
# Starting from main, depth 3
idapro_callgraph(roots=["main"], max_depth=3)

# Multiple roots
idapro_callgraph(roots=["sub_401000", "sub_402000"], max_depth=2)
```

### Data Flow Tracing

```
# Trace backward: where does this value come from
idapro_trace_data_flow(addr="0x401050", direction="backward", max_depth=5)

# Trace forward: where does this value go
idapro_trace_data_flow(addr="0x401050", direction="forward", max_depth=5)
```

---

## Search

### String Search (Regex)

```
# Search URLs
idapro_find_regex(pattern="https?://", limit=20)

# Search file paths
idapro_find_regex(pattern="C:\\\\", limit=20)

# Search error messages
idapro_find_regex(pattern="error|fail|invalid", limit=30)

# Search key/password related
idapro_find_regex(pattern="key|password|secret|token", limit=20)
```

### Disassembly Text Search

```
# Search in the disassembly listing
idapro_search_text(pattern="call    sub_")
idapro_search_text(pattern="xor     eax, eax")
```

### Byte Pattern Search

```
# Exact bytes
idapro_find_bytes(patterns=["48 8B 05"], limit=10)

# With wildcards
idapro_find_bytes(patterns=["48 89 ?? 24 ??"], limit=10)

# Multiple patterns
idapro_find_bytes(patterns=["CC CC CC CC", "90 90 90 90"], limit=5)
```

### Advanced Search

```
# Search immediates
idapro_find(type="immediate", targets=["0xDEADBEEF"])

# Search string references
idapro_find(type="string", targets=["password"])
```

---

## Memory and Data Reading

### Read Raw Bytes

```
idapro_get_bytes(addrs=[{"addr": "0x401000", "size": 64}])
```

### Read Strings

```
idapro_get_string(addrs=["0x404000", "0x404100"])
```

### Read Integers

```
idapro_get_int(queries=[{"addr": "0x405000", "size": 4}])
```

### Read Globals

```
idapro_get_global_value(queries=["g_flag", "g_key_size"])
```

### Read Structs

```
idapro_read_struct(queries=[{"addr": "0x405000", "type": "HEADER"}])
```

### Search Structs

```
idapro_search_structs(filter="FILE")
```

---

## Modification Operations

### Add Comments

```
# Single comment
idapro_set_comments(items=[{"addr": "0x401000", "comment": "decryption function entry"}])

# Batch comments
idapro_set_comments(items=[
    {"addr": "0x401000", "comment": "XOR decryption loop"},
    {"addr": "0x401050", "comment": "key initialization"},
    {"addr": "0x4010A0", "comment": "result verification"}
])

# Append comments (does not overwrite existing)
idapro_append_comments(items=[{"addr": "0x401000", "comment": "note: key length 16"}])
```

### Rename

```
# Rename functions
idapro_rename(batch={"func": [
    {"addr": "sub_401000", "name": "decrypt_payload"},
    {"addr": "sub_402000", "name": "verify_license"}
]})

# Rename global variables
idapro_rename(batch={"global": [
    {"addr": "0x405000", "name": "g_encryption_key"}
]})

# Rename local variables
idapro_rename(batch={"local": [
    {"func": "decrypt_payload", "old": "v1", "name": "plaintext_buf"}
]})
```

### Patch Assembly

```
# NOP out detection code
idapro_patch_asm(items=[{"addr": "0x401050", "asm": "nop"}])

# Modify a jump
idapro_patch_asm(items=[{"addr": "0x401060", "asm": "jmp 0x401080"}])

# Force return true
idapro_patch_asm(items=[
    {"addr": "0x401000", "asm": "mov eax, 1"},
    {"addr": "0x401005", "asm": "ret"}
])
```

### Patch Bytes

```
# Write bytes directly
idapro_patch(patches=[{"addr": "0x401050", "bytes": "9090909090"}])
```

---

## Type System

### Declare Structs

```
idapro_declare_type(decls=[{
    "name": "PacketHeader",
    "decl": "struct PacketHeader { uint32_t magic; uint16_t type; uint16_t length; uint8_t data[0]; };"
}])
```

### Apply Types

```
# Set a prototype for a function
idapro_set_type(edits=[{
    "addr": "sub_401000",
    "type": "int __fastcall decrypt(void *buf, int size, const char *key)"
}])

# Set a type for a global variable
idapro_set_type(edits=[{
    "addr": "0x405000",
    "type": "PacketHeader"
}])
```

### Infer Types

```
idapro_infer_types(addrs=["sub_401000", "sub_402000"])
```

### Query/Inspect Types

```
idapro_type_query(queries=["Packet"])
idapro_type_inspect(queries=["PacketHeader"])
```

---

## Stack Frame Analysis

```
# View function stack frames
idapro_stack_frame(addrs=["main", "sub_401000"])

# Declare stack variables
idapro_declare_stack(items=[{
    "func": "sub_401000",
    "offset": -0x20,
    "name": "local_buf",
    "type": "char [32]"
}])
```

---

## Signature Generation

```
# Generate a unique byte signature for an address
idapro_make_signature(addrs=["0x401000"])

# Generate a signature for the whole function
idapro_make_signature_for_function(addrs=["decrypt_payload"])

# Generate a signature for code referencing an address
idapro_find_xref_signatures(addrs=["0x405000"])
```

---

## Number Base Conversion

```
# Hexadecimal → decimal
idapro_int_convert(inputs=["0x401000"])

# Decimal → hexadecimal
idapro_int_convert(inputs=["4198400"])

# Batch conversion
idapro_int_convert(inputs=["0xDEAD", "0xBEEF", "12345"])
```

> ⚠️ **Always use this tool for number base conversion; do not compute it yourself!**

---

## Export and Scripts

### Export Functions

```
# JSON format
idapro_export_funcs(addrs=["main", "sub_401000"], format="json")

# C header file
idapro_export_funcs(addrs=["main", "sub_401000"], format="c_header")

# Function prototypes
idapro_export_funcs(addrs=["main", "sub_401000"], format="prototypes")
```

### Execute Python Scripts

```
# Execute Python in the IDA context
idapro_py_eval(code="import idautils; print(list(idautils.Functions())[:10])")

# Fetch segment info
idapro_py_eval(code="import idc; print(idc.get_segm_name(0x401000))")

# Batch operations
idapro_py_eval(code="import ida_funcs; f=ida_funcs.get_func(0x401000); print(f.size())")
```

---

## Typical Analysis Workflows

### Malware Analysis

```text
1. survey_binary → look at imports (network APIs? crypto? registry?)
2. find_regex("http|socket|connect") → find network-related strings
3. xrefs_to(network string addresses) → find referencing functions
4. decompile(referencing function) → inspect the communication logic
5. trace_data_flow(crypto parameter, "backward") → trace the key origin
6. set_comments + rename → annotate findings
```

### License Validation Cracking

```text
1. find_regex("serial|license|register|valid") → find validation-related strings
2. xrefs_to(validation string) → locate the validation function
3. analyze_function(validation function) → understand the logic
4. callgraph(validation function, 2) → inspect the call chain
5. patch_asm(conditional jump address, "jmp always_pass") → patch
```

### CTF Reversing

```text
1. survey_binary → confirm architecture and entry
2. decompile("main") → inspect the main logic
3. find_regex("flag|correct|wrong") → find decision points
4. trace_data_flow(decision point, "backward") → trace input transformations
5. use Python to assist computation/decryption → obtain the flag
```

### Vulnerability Analysis

```text
1. entity_query(kind="imports", filter="strcpy|sprintf|gets") → find dangerous functions
2. xrefs_to(dangerous function) → find call sites
3. analyze_function(function containing the call site) → inspect the context
4. stack_frame(function) → confirm buffer sizes
5. trace_data_flow(dangerous parameter, "backward") → confirm user controllability
```

---

## Common Errors and Solutions

| Error | Cause | Solution |
|------|------|------|
| "No database bound" | No file opened | Run `open.ps1` |
| "Failed to open database" | Old database locked | `open.ps1` auto-degrades to Temp |
| schema validation failure | MCP client BUG | Use `open.ps1` instead of `idb_open` |
| Tool timeout | Large file being analyzed | Add `-TimeoutSeconds 600` |
| "ERR:timeout" (start.ps1) | Server startup failed | Check Python/idalib-mcp installation |
| Number base conversion error | Manual computation mistake | Use `idapro_int_convert` |
| Function name not found | Name not precise | Search first with `list_funcs` + filter |
