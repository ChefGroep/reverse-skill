# Go Binary Reverse Engineering Guide

> Go-compiled binaries pose unique challenges: static linking makes them huge, function counts run into the tens of thousands, string formats are special, and symbol recovery after stripping is hard.
> This document covers the toolchain, recovery techniques, and practical workflows.

---

## Identifying Go Binaries

Quickly determine whether a binary was compiled with Go:

```bash
# String signatures
strings binary | grep -E "runtime\.|go\.buildid|GOROOT"

# rabin2 reconnaissance
rabin2 -z binary | grep -i "runtime"

# Abnormally large file size (statically linked runtime)
# Typical Hello World: C ~20KB, Go ~2MB
```

Common signatures:
- Many functions with the `runtime.` prefix
- A `go.buildid` section
- `GOROOT` / `GOPATH` path strings
- Function counts of 5000-50000+ (the entire runtime and standard library included)

---

## Core Toolchain

### Symbol Recovery

| Tool | Purpose | Link |
|------|------|------|
| **GoReSym** | From Mandiant; parses Go symbol information (pclntab/moduledata) | https://github.com/mandiant/GoReSym |
| **GoResolver** | From Volexity; automatically de-obfuscates Garble binaries via CFG similarity | https://github.com/volexity/GoResolver |
| **redress** | Analyzes stripped Go binaries; recovers types/interfaces/package structure | https://github.com/goretk/redress |
| **GoStringUngarbler** | From Google; specifically recovers Garble-obfuscated strings | https://github.com/mandiant/GoStringUngarbler |

### IDA Plugins

| Tool | Purpose | Link |
|------|------|------|
| **go_parser** | IDA plugin; parses moduledata/pclntab/type information | https://github.com/0xjiayu/go_parser |
| **IDAGolangHelper** | IDA script collection; parses Go type information | https://github.com/sibears/IDAGolangHelper |
| **AlphaGolang** | SentinelLabs IDAPython script collection | https://github.com/SentineLabs/AlphaGolang |
| **IDA 9.2+ native support** | Hex-Rays official Go decompiler improvements | https://hex-rays.com/blog/stop-guessing-and-start-going |

### Ghidra Plugins

| Tool | Purpose | Link |
|------|------|------|
| **Ghidra + GoReSym output** | Export symbols with GoReSym, then import into Ghidra | Used together |
| **golang_loader_assist** | Ghidra Go loading helper | Community script |

### Standalone Analysis Tools

| Tool | Purpose | Link |
|------|------|------|
| **gore** | Go reverse engineering library (the layer under redress) | https://github.com/goretk/gore |
| **garble** | Go obfuscator (understand it to fight it) | https://github.com/burrowers/garble |

---

## Key Structures in Go Binaries

### pclntab (PC Line Table)

The most important structure in a Go binary. It contains:
- The name/address mapping of all functions
- Source file paths
- Line number information
- Stack frame sizes

Even after symbols are stripped, pclntab usually remains (the Go runtime depends on it).

```text
How to locate it:
1. Search for magic bytes: 0xFFFFFFF0 (Go 1.16+) or 0xFFFFFFFB (Go 1.18+)
2. Locate automatically with GoReSym
3. Parse automatically with the go_parser IDA plugin
```

### moduledata

Contains:
- pclntab pointer
- Type information tables
- itab (interface tables)
- Global variable information

### String Format

Go strings are not C-style null-terminated; they are `(pointer, length)` structs:

```text
C string:   "hello\0"
Go string:  struct { ptr *byte; len int } -> ptr points to "hello" (no \0)
```

This causes IDA/Ghidra's default string detection to miss large numbers of Go strings.

**Solutions**:
- Use `go_parser` to detect Go strings automatically
- Use GoReSym to export a string list
- Manually: find `runtime.stringtable` or locate strings via cross-references

---

## Practical Workflows

### Scenario 1: Non-stripped Go binary

```text
1. GoReSym -t -d -p binary > symbols.json
   -> Exports all function names, types, and source file paths
2. Load into IDA/Ghidra
3. Import the GoReSym symbol information
4. Filter out runtime.* and standard-library functions; focus on user code
5. Start analysis from main.main
```

### Scenario 2: Stripped Go binary

```text
1. GoReSym -t -d -p binary > symbols.json
   -> Even when stripped, pclntab is usually still present
2. If GoReSym fails -> use redress
   redress -src binary    # Recover source file paths
   redress -pkg binary    # Recover package structure
   redress -type binary   # Recover type information
3. Load into IDA + go_parser plugin
4. Run go_parser automatic recovery
5. Start from the recovered main.main
```

### Scenario 3: Garble-obfuscated Go binary

```text
Garble does:
- Randomize function names (main.main -> main.a3f2b1c)
- Encrypt strings
- Remove file path information
- Obfuscate package names

Countermeasures:
1. GoResolver (CFG signature matching)
   -> Recovers standard-library function names via control-flow-graph similarity
2. GoStringUngarbler (string decryption)
   -> Automatically identifies Garble's string encryption patterns and decrypts
3. Dynamic analysis (Frida/dlv)
   -> Hook runtime functions and observe actual behavior
4. Comparative analysis
   -> Compile a Hello World with the same Go version and compare the runtime portion with binary-diff
```

### Scenario 4: Mixed CGo builds

```text
1. Identify CGo boundaries (_cgo_* functions)
2. Recover the Go portions with go_parser
3. Analyze the C portions with standard IDA workflow
4. Pay attention to bridging functions like _cgo_topofstack and crosscall2
```

---

## Command Cheat Sheet

```bash
# GoReSym: export symbols
GoReSym -t -d -p binary > symbols.json
GoReSym -t -d -p binary -o ida_script.py  # Generate an IDA script

# redress: analyze stripped binaries
redress -src binary          # Source file paths
redress -pkg binary          # Package structure
redress -type binary         # Type information
redress -interface binary    # Interface information
redress -filepath binary     # Full file paths

# GoResolver: de-obfuscate Garble
GoResolver -binary binary -output resolved.json

# GoStringUngarbler: decrypt Garble strings
GoStringUngarbler -i binary -o deobfuscated_binary

# Quickly determine the Go version
strings binary | grep "go1\."
GoReSym -p binary | grep "Version"
```

---

## Go Analysis Flow in IDA

```text
1. Load the binary (choose the correct architecture)
2. Wait for auto-analysis to finish
3. Run the go_parser plugin:
   - File -> Script File -> go_parser.py
   - Or Edit -> Plugins -> Go Parser
4. The plugin will automatically:
   - Parse pclntab
   - Recover function names
   - Mark Go strings
   - Parse type information
5. Filter the view:
   - Hide runtime.* functions
   - Focus on main.* and third-party packages
6. Start reversing from main.main
```

---

## Common Pitfalls

| Pitfall | Description | Solution |
|------|------|------|
| Too many functions to review | Go's static linking produces 5000-50000 functions | Filter by package name; only look at main.* and business packages |
| Incomplete string detection | Go strings are not null-terminated | Recover with go_parser or GoReSym |
| Hard-to-read decompilation | Go's defer/goroutine/interface make pseudocode messy | IDA 9.2+ improved this, or assist with dynamic analysis |
| Garble obfuscation | Function names/strings fully randomized | GoResolver + GoStringUngarbler |
| Version differences | pclntab format differs across Go versions | GoReSym supports Go 1.2-1.23+ |
| CGo boundaries | Go and C code are mixed | Identify _cgo_* functions as the boundary line |

---

## Working With Other Skills

| Need | What to use |
|------|--------|
| Deep IDA analysis of a Go binary | `ida-reverse/` + go_parser plugin |
| Ghidra analysis (free) | Ghidra + GoReSym symbol import |
| Quick reconnaissance | `radare2/` — `rabin2 -z` for strings |
| Dynamic hooking | Frida (hook runtime functions) or dlv (Go's native debugger) |
| Cross-version comparison | `binary-diff/` — migrate symbols from an old version to the new one |
| Garble de-obfuscation | GoResolver + GoStringUngarbler |
