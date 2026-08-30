# [Seed] ELF Self-Extracting Loader Reverse Engineering

## Scenario Category
Binary analysis

## Target Overview
Analyze an ARM64 ELF self-extracting loader disguised as a .sh script; recover its decompression algorithm and payload injection flow.

## Complete Execution Chain

1. `file` command confirms the real type (ELF, not a shell script)
2. `readelf -l` to inspect program headers → the 3rd PHDR is deliberately corrupted (padded with 0x0a)
3. `rabin2 -I` to get the architecture (AArch64), entry point, and compiler info
4. Load in IDA/Ghidra → start analysis from the entry point
5. Identify the LZSS decompression loop (bitstream operations + sliding-window back-copy)
6. Identify the mmap → decompress → mprotect → jump injection flow
7. Rewrite the decompressor in Python and dump the payload
8. Analyze the payload contents (contains /proc/self/exe references, indicating a process injector)

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| readelf fails to parse the file | The 3rd PHDR is deliberately padded with 0x0a | Ignore the corrupted PHDR; only inspect the first 2 LOAD segments | 10min |
| IDA decompilation output is unreadable | Dense ARM64 bit manipulation; Hex-Rays handles it poorly | Switch to the disassembly view and analyze manually | 30min |
| The Python decompressor produces wrong output | The pop_bit refill path returns the wrong value (adcs vs adds) | Compare against the assembly carefully; during refill the returned value is bit31 of the newly loaded word | 2h |
| Unsure about the payload entry offset | The meaning of the entry_offset field in the data table is unclear | Trace the loader's `br mmap_base + 0x14`; the entry is confirmed at +0x14 | 20min |

## Toolchain Findings

- The `file` command is step one — never trust file extensions
- `rabin2 -I` is more tolerant than `readelf` (it handles corrupted PHDRs)
- For ARM64 code dense with bit manipulation, the decompiler is inferior to reading the assembly directly
- The Python struct module plus a hand-written decompressor is the standard method for analyzing custom compression

## Key Code/Commands

```bash
# Confirm file type
file LinYuDriverLoader4.9.sh
# ELF 64-bit LSB executable, ARM aarch64

# View program headers
readelf -l binary 2>/dev/null | head -20

# Extract compressed data
dd if=binary bs=1 skip=$((0xa6a24)) count=1981 of=compressed.bin

# Compute the file offset
# vaddr 0x3d66bc → file_offset = 0x3d66bc - 0x330000 = 0xa66bc
```

```python
# LZSS decompressor core (simplified)
def decompress(data):
    shift_reg = 0x80000000
    # ... bitstream reads + literal/match branches
```

## Improvement Suggestions for This Package

- `elf-analysis.md` should add more signatures for "custom compression algorithm identification"
- The ARM64 syscall table should document cache maintenance instructions (dc cvau / ic ivau)
- Add a general methodology for "rewriting assembly algorithms in Python"

## Reusable Patterns/Script Snippets

**Standard pattern for identifying a self-extracting ELF**:
```text
Entry point → minimal init → call decompressor → mmap(RW) → decompress into the mmap region → mprotect(RX) → jump
```

**Generic pattern for ARM64 bitstream reads**:
```text
lsl w4, w4, #1    # shift left (moves the top bit into the carry flag)
cbz w4, refill    # if drained, load a new 32-bit word from the input
```

## Evolution Actions
- [x] Updated sub-skill docs (elf-analysis.md has been added)
- [ ] No routing-matrix update needed
- [ ] No bootstrap-manifest update needed

## Environment Info
- OS: Linux/Android ARM64 target
- Tool versions: IDA Pro / Ghidra + radare2
- Target platform: Android ARM64 (AArch64)

## De-identification Requirement
This entry is seed data written from public technical patterns; it involves no real target.

---
<!-- [Community contribution] Seed data, no PR needed -->
