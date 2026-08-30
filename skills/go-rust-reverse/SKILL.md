---
name: go-rust-reverse
description: Use for reverse engineering stripped Go and Rust binaries including runtime recognition, pclntab/moduel data recovery, panic strings, and idiomatic decompilation recovery.
---

# Go / Rust Binary Reverse Engineering

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: read `../field-journal/precedent-reverse.md`
2. `NOW`: confirm the sample is a Go/Rust build artifact (`file`/strings/runtime traits)
3. `NEXT`: whether GoReSym / related plugins are available
4. `ACT`: runtime recognition → symbol/metadata recovery → business logic

## Applicable scenarios

- Stripped Go malware/tools
- Rust release binaries, panic-string-driven analysis
- Language-specific methods complementing generic ida/ghidra

## Workflow

### Go

```text
□ Recognize go.buildid, residual runtime symbols, pclntab
□ GoReSym / redress / IDA Go plugins to recover function names
□ Watch how interface, slice, and string structures appear in the decompilation
□ Network/crypto library paths: crypto/* net/http
```

### Rust

```text
□ Panic strings, rust_begin_unwind, crate-path hints
□ Code bloat caused by generic instantiation; locate string xrefs first
□ Async/tokio state machines need cross-references
```

### Dynamic

```text
□ Frida still works; watch the Go stack and scheduler
□ Prefer log and config strings to drive breakpoints
```

## Toolchain

| Tool | Purpose |
|------|------|
| GoReSym | Go metadata |
| IDA/Ghidra + Go/Rust plugins | decompilation |
| radare2 | quick strings |
| strings / rabin2 | triage |

## References

- `references/go-rust-notes.md`
- `../reverse-engineering/go-reverse.md` `../ida-reverse/` `../ghidra-reverse/`
- seed: `field-journal/seed-002_go-malware-stripped.md`

## Routing context

**Upstream**: MASTER R33  
**Downstream**: malware sample flow `malware-analysis`; general RE `reverse-engineering`

## Task completion self-check

- [ ] Recovered key function names or an equivalent mapping?
- [ ] Annotated language/runtime evidence?
- [ ] Checklist?
