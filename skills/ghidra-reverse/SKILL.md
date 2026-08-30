---
name: ghidra-reverse
description: Use for free/open reverse engineering with Ghidra (headless or GUI), including decompile, cross-refs, and optional Ghidra MCP workflows when IDA is unavailable.
---

# Ghidra Reverse Engineering

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md`
2. `NOW`: Confirm **Ghidra** is needed (no IDA license / preference for open source / bulk headless runs)
3. `NEXT`: Read `../tool-index.md` for the ghidra / ghidra-mcp paths
4. `NEXT`: Missing tool → bootstrap `ghidra-mcp` (if the manifest supports it) or install Ghidra manually
5. `ACT`: Import sample → auto-analysis → export key function decompilations

## When to Use

- The primary reverse-engineering entry when no IDA license is available
- Bulk headless analysis / decompilation in CI
- Ghidra scripting (Java/Python Jython/PyGhidra) automation
- Pairing with `binary-diff` / `patch-diff-exploit` via ghidriff

## Division of Labor with IDA

| Need | Prefer |
|------|--------|
| Deep dive with existing IDA MCP | `ida-reverse/` |
| Open source / bulk / teaching | **This skill** |
| Quick CLI-only recon | `radare2/` |

## Workflow

### 1. Project and Auto-Analysis

```text
□ Create a new Project → Import file → Analyze (default analyzers)
□ Record language/compiler identification results and the base address
□ Mark entry points, export tables, and string xrefs
```

### 2. Key Functions

```text
□ Work backward from strings / imported APIs
□ Restore algorithms in the Decompile window
□ Rename functions/variables; write Plate comments
□ When dynamics are needed, hand off to Frida/GDB (dynamic chapter of reverse-engineering)
```

### 3. Headless (Bulk)

```bash
# Example: the analyzeHeadless path varies by install; MUST be taken from tool-index
analyzeHeadless /path/to/project Proj -import sample.bin -postScript ExportDecomp.py
```

### 4. MCP (If Configured)

```text
□ Confirm the ghidra MCP port (commonly 8765; tool-index is authoritative)
□ Use MCP tools to pull decompilation / xrefs; never guess the port
```

## Toolchain

| Tool | Purpose | Bootstrap |
|------|---------|-----------|
| Ghidra | Main decompilation tool | Manual release / package manager |
| ghidra-mcp | AI bridge | bootstrap capability name `ghidra-mcp` |
| ghidriff | Patch diffing | See `patch-diff-exploit` |

## References

- `references/ghidra-cheatsheet.md`
- `../ida-reverse/`, `../radare2/`, `../binary-diff/`

## Routing Context

**Upstream**: MASTER R22  
**Downstream**: dynamic verification → Frida/GDB; exploitation → `pwn-chain`  
**Peer**: `ida-reverse` (commercial deep dive)

## Completion Self-Check

- [ ] Based on real Ghidra/tool-index paths?
- [ ] Function addresses annotated and names renamed?
- [ ] Reproducible steps included?
- [ ] Checklist / journal updated?
