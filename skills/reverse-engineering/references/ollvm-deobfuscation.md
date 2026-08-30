# OLLVM Deobfuscation / Obfuscator-LLVM Deobfuscation

> OLLVM de-obfuscation workflow for APK .so files, ELF binaries, and control-flow flattening scenarios.
> Tool and variant information is based on a 2026 survey of active community projects, not training memory.
> Applies to: Android NDK hardening, CTF reversing, packed .so analysis, and commercial obfuscator countermeasures.

---

## 0. Quick Decision: Which Tool Should I Use?

Match your situation and your judgment of the target's obfuscation type directly:

| Your situation | First choice | Alternative | Notes |
|---------|---------|------|------|
| IDA Pro 7.5-7.7 + Hex-Rays, want one-click unflattening | **obpo-plugin** | d810-ng | obpo uses microcode + data flow + concolic, strongest effect, but a cloud plugin (needs network, core closed source) |
| IDA Pro (any recent version), want local one-stop deobfuscation | **d810-ng** | original D-810 | Local, open source, integrated Z3, covers OLLVM/Tigress/Hodur/Approov variants |
| Binary Ninja | **ollvm-breaker** | — | Practical for Android .so (hardening samples like libvdog) |
| No IDA/BN, pure scripts, target x86/x64 | **ollvm-unflattener** (Miasm) | angr deflat | Based on Miasm symbolic execution, multi-layer BFS processing |
| Pure Python symbolic execution, CTF scenario | **angr** Deobfuscator | Triton | GUI-free, scriptable |
| Target is an ARM64 .so without IDA | **deollvm** (Unicorn) | angr | Unicorn-based ARM64 deflat |
| Hit BR obfuscation (indirect branches) | **DeObfBR** | set data segment read-only | Goron/Arkari-style BR obfuscation is simply countered by a read-only data segment |
| Hit Tigress obfuscation | d810-ng `UnflattenerSwitchCase`/`UnflattenerTigressIndirect` | — | d810-ng ships Tigress-specific unflatteners |
| EU/NL handling of sensitive samples | local tools only (d810-ng) | angr/Triton | Never upload unreleased vulnerability research to third-party cloud services |

> **Core recommendation:** Prefer **d810-ng** (local, actively maintained, broad variant coverage). **obpo-plugin** works best when cloud is acceptable. If both fail, go to **angr/Miasm** symbolic execution for a custom approach.

---

## 1. The Modern OLLVM Variant Ecosystem (2026 Community Survey)

OLLVM long ago stopped being that original 2017 repository. The following are the currently active obfuscator branches. **You must identify the variant before de-obfuscating**, because countermeasures differ greatly between variants:

### 1.1 Obfuscator Branch Lineage

| Variant | Base LLVM | New features vs original OLLVM | Countermeasure notes |
|------|----------|----------------------|---------|
| **Obfuscator** (original) | 3.3~4.0 | sub + bcf + fla (the three base passes) | Standard tools all handle it |
| **Hikari** | 6~8 | Anti Class Dump, Function Call Obfuscate, Function Wrapper, Indirect Branching, Split BB, String Encryption | Decrypt strings first + fix indirect jumps |
| **Hikari-LLVM15** | 15~19 | + Anti Debugging, Anti Hook, Constant Encryption | Now closed source; Constant Encryption raises static-analysis difficulty |
| **goron** | 7~10 | Indirect Branch/Call/GlobalVariable | ⚠️ Goron-style indirect obfuscation is simply countered by "set data segment read-only" |
| **Arkari** (komimoe/Hikari) | 14~latest | Based on goron, actively maintained | Same as goron; read-only data segment partially counters it |
| **Pluto** | 14 | MBA Obfuscation, Random CF, Split BB, **Trap Angr** (specifically to trap angr) | ⚠️ The Trap Angr pass breaks angr symbolic execution; switch tools or bypass the trap |
| **Polaris** (formerly Pluto) | 16 | Alias Access, Indirect Branch/Call, String Encryption, Merge Function, Linear MBA, Dirty Bytes Insertion, Function Splitting, Junk Insertion | Combines Hikari+Pluto; the nastiest; needs layered handling |
| **O-MVLL** | open-obfuscator | Python-driven pass manager; Anti Hooking, Arithmetic (MBA), BB Duplicate, CF Breaking, Function Outline, Indirect Branch/Call, Opaque Constants | Common in modern Android hardening; Python config is easy to customize |
| **amice** (Rust) | Rust implementation | Full set + VM Flatten, Instruction Virtualization, Delayed Offset Loading, Parameter Aggregation | Includes VM-ization; needs VM handler recovery, not just deflat |
| **VMP family** (SmallVmp/VMPilot/xVMP/VMPacker) | — | Instruction virtualization | **Outside the OLLVM scope**; needs VM reversing; see VM-specific tooling |

### 1.2 Key Decision Leads

- **Trap Angr** (Pluto/Polaris): if angr blows up mid-run or explodes in path count, suspect the Trap Angr pass -> switch to d810-ng or Unicorn dynamic methods
- **Goron/Arkari indirect jumps**: if the dispatcher uses indirect jumps (BR x8 instead of a switch), first try setting the relevant data segment read-only; indirect jump targets often become statically solvable
- **Constant Encryption** (Hikari-LLVM15/Polaris/O-MVLL): constants decrypt at runtime; pure static analysis never sees the real values -> use Unicorn to execute the decryption stub dynamically
- **VM Flatten** (amice): control flow becomes a VM dispatch loop; **do not treat it as ordinary fla** — identify the VM handler table first

---

## 2. OLLVM Obfuscation Type Detection

Identification signatures of the three core OLLVM passes:

### 2.1 Control Flow Flattening (`fla`)

**IDA view signatures:**
- The function entry first jumps to the single dispatcher block
- The main logic is split into many basic blocks, each ending with a jump back to the dispatcher
- The dispatcher decides the next block via a **state variable**
- A huge `switch` structure with logically unrelated cases

```
Original:             OLLVM flattened:
  block_A               entry -> dispatcher
  block_B                 ↓
  block_C              state_machine:
                         switch(state):
                           0 → block_A
                           1 → block_B
                           2 → block_C
```

**Variant shapes (dispatchers identified by d810-ng):**
- O-LLVM: switch / if-chain + state variable
- Tigress: `m_jtbl` (switch-case) or `m_ijmp` (indirect jump, needs `goto_table_info` configuration)
- Hodur (PlugX): nested `while(1)` state machine, `jnz state, #CONST`, **no switch dispatcher**
- Approov: `while(v8 != C)`, state constants concentrated in `0xF6000–0xF6FFF`

### 2.2 Bogus Control Flow (`bcf`)

- **Unreachable fake branches** inserted between each real branch
- Fake branches protected by **opaque predicates** (always-true/always-false conditions that static analysis cannot directly prove)
- Large amounts of dead code inflate the function size

```c
// Classic opaque predicate: x(x+1) is always even, but the compiler can't prove it
if (x * (x + 1) % 2 == 0) {
    // Real logic
} else {
    // Unreachable garbage code
}
```

### 2.3 Instruction Substitution (`sub`) -> MBA

- Simple arithmetic/bit operations replaced with equivalent complex expressions (MBA, Mixed Boolean-Arithmetic)

```
a + b  →  (a ^ b) + 2*(a & b)
a ^ b  →  (a | b) - (a & b)
a - b  →  a + (~b) + 1
```

### 2.4 Quick Classification Table

| Obfuscation type | IDA signature | Primary countermeasure |
|---------|---------|------------|
| fla (flattening) | Huge switch + dispatcher | obpo / d810-ng / deflat |
| bcf (bogus control flow) | Unreachable branches + dead code | d810-ng opaque predicate removal / symbolic execution |
| sub/MBA | Complex arithmetic expressions | d810-ng MBA simplifier / SiMBA (Z3) |
| fla + bcf + sub | All at once, massive inflation | **Layered deobfuscation (bcf first, then fla, then sub)** |

---

## 3. Mainstream Tools in Detail (Active Community Projects)

### 3.1 obpo-plugin — Strongest effect, cloud plugin

> [obpo-project/obpo-plugin](https://github.com/obpo-project/obpo-plugin) · 629⭐ · active 2026-06

A pseudocode optimizer based on Hex-Rays **microcode**, using **data-flow tracking + program slicing + concolic execution** to rebuild flattened control flow. Widely regarded as one of the most effective.

**Key features:**
- Operates at the microcode layer, directly optimizing decompiler output (not ASM)
- Supports IDA 7.5.0 / 7.6.0 / 7.7.0 + Hex-Rays
- Architectures: ARM, ARM64, x86, x86_64, PowerPC, PowerPC64, MIPS (7.6/7.5)
- **Cloud plugin**: the target function's binary is uploaded to obpo-server for processing (core closed source, plugin free/open source)
- The server is maintained at the author's own expense; 600s timeout; **no multi-threading/malicious calls**

**Installation and usage:**
```text
1. Download obpo_plugin.py and the obpoplugin directory
2. Copy into the IDA plugins path
3. Restart IDA and open the target binary
4. Locate the dispatcher block in the CFG; it usually looks like this:
   [see assets/dispatchblock.png in the repo]
5. Right-click -> OBPO -> Mark and process function
6. Refresh the decompiler after processing completes
7. Optionally mark newly appearing dispatcher blocks (iterative handling of nested fla)
```

**Use cases and limits:**
- ✅ Standard and nested fla; good results
- ⚠️ Requires network; be careful with sensitive samples (unreleased vulnerabilities, trade secrets) — the binary gets uploaded
- ⚠️ The server may be down; depends on the author's maintenance
- ❌ Cannot solve every obfuscation (the author explicitly states this)

### 3.2 d810-ng — Local one-stop first choice

> [w00tzenheimer/d810-ng](https://github.com/w00tzenheimer/d810-ng) · 223⭐ · updated 2026-06-26

A modern, maintained/rebuilt version of D-810 (Next Generation). Runs locally, open source, integrates the **Z3 SMT** solver, and has the broadest variant coverage.

**Core capabilities (per the d810-ng README):**

*Instruction-level optimization:*
| Category | Notes |
|------|------|
| MBA simplification | `(a+b)-2*(a&b) => a^b`, Z3-verified DSL rules |
| Hacker's Delight | Bit-operation equivalences (from the Hacker's Delight book) |
| O-LLVM patterns | Obfuscator-LLVM-specific MBA patterns |
| Constant folding | 22 constant-simplification rules |
| Predicate simplification | Opaque predicate removal (setz/setnz/lnot/smod) |
| Z3 rules | SMT solving when template matching fails |
| Hodur-specific | MBA patterns from PlugX (Hodur) malware |

*Control-flow unflattener (categorized by target obfuscation):*
| Unflattener | Target | Notes |
|------------|------|------|
| `Unflattener` | O-LLVM | Standard switch/if-chain + state variable |
| `UnflattenerSwitchCase` | Tigress | Tigress switch-case dispatch (`m_jtbl`) |
| `UnflattenerTigressIndirect` | Tigress | Tigress indirect jumps (`m_ijmp`), needs `goto_table_info` configuration |
| `HodurUnflattener` | Hodur (PlugX) | Nested `while(1)` + `jnz state, #CONST`, no switch |
| `BadWhileLoop` | Approov | `while(v8 != C)`, state constants in 0xF6000–0xF6FFF |
| `UnflattenerFakeJump` | Generic | Removes always-true/always-false conditional jumps |
| `SingleIterationLoopUnflattener` | Residue | Cleans up single-iteration loops where `INIT == CHECK` and `UPDATE != CHECK` |
| `UnflattenControlFlowRule` (experimental) | Generic | Path-emulation-based CFG unflattener |

**Installation and usage:**
```text
1. clone d810-ng
2. Install dependencies (including Z3)
3. Copy into the IDA plugins directory
4. Load the plugin in IDA with Ctrl-Shift-D
5. Tick the rule sets to apply in the GUI
6. Apply to the target functions
```

**Why d810-ng over the original D-810:**
- The original D-810 is less maintained
- d810-ng has CI tests, refactored code, and new Tigress/Hodur/Approov-specific unflatteners
- Integrates Z3; falls back to SMT solving when template matching fails, for a higher success rate

### 3.3 ollvm-unflattener — Miasm symbolic execution, pure script

> [cdong1012/ollvm-unflattener](https://github.com/cdong1012/ollvm-unflattener) · 265⭐ · active 2026-06

Based on the **Miasm** symbolic execution engine; no IDA/BN dependency, pure Python CLI.

**Features:**
- Uses Miasm symbolic execution to recover the original control flow (unlike MODeflattener's purely static method)
- **BFS multi-layer processing**: automatically follows the target function's calls and recursively de-obfuscates
- Supports Windows/Linux x86/x64
- Outputs a new de-obfuscated binary

**Installation and usage:**
```bash
git clone https://github.com/cdong1012/ollvm-unflattener.git
cd ollvm-unflattener
pip install -r requirements.txt   # miasm, graphviz, keystone-engine

# Basic usage
python unflattener -i <input.bin> -o <output.bin> -t <function_addr> -a
# -a: automatically follow calls for multi-layer processing
```

**Fits:** no IDA, x86/x64 targets, batch scriptable processing.

### 3.4 ollvm-breaker — Binary Ninja practice

> [amimo/ollvm-breaker](https://github.com/amimo/ollvm-breaker) · 441⭐

Uses **Binary Ninja** to unflatten; the repo ships the Android hardening sample `libvdog.so` as a test case, with JNI_OnLoad, crazy::GetPackageName, and prevent_attach_one already fixed.

**Fits:** Binary Ninja users, hands-on Android .so work.

### 3.5 deollvm — ARM64 Unicorn

> [GeT1t/deollvm](https://github.com/GeT1t/deollvm) · 34⭐ · 2026-04

Unicorn-based ARM64 OLLVM deflat. A fallback for handling ARM64 .so without IDA.

### 3.6 DeObfBR — BR obfuscation specialist

> [Mrack/DeObfBR](https://github.com/Mrack/DeObfBR) · 96⭐ · 2026-06-25

Removes **BR obfuscation** (indirect-branch obfuscation, Goron/Arkari style) specifically.

**⚠️ Simple countermeasure tip (from awesome-ollvm):** Goron/Arkari-style indirect-related obfuscation can be simply countered by **setting the data segment read-only** — indirect jump targets often depend on a writable data segment; read-only makes them statically solvable.

### 3.7 angr — General symbolic-execution framework

```python
import angr

proj = angr.Project("target.so", auto_load_libs=False)
cfg = proj.analyses.CFGFast()
func = proj.kb.functions[0x12345]

# Built-in Deobfuscator
deob = proj.analyses.Deobfuscator(func=func)
deob.normalize()
```

**⚠️ Pluto/Polaris's Trap Angr pass:** these two variants include traps specifically designed to defeat angr symbolic execution. If angr path-explodes or throws, suspect Trap Angr -> switch to d810-ng or Unicorn dynamic methods.

---

## 4. Full De-Obfuscation Workflow (By Scenario)

### 4.1 General decision tree

```
Target binary
  ↓
1. Identify the OLLVM variant (see leads in 1.2)
   ├── Original OLLVM / Hikari / O-MVLL  -> standard fla/bcf/sub
   ├── Pluto / Polaris                   -> watch for Trap Angr; avoid angr
   ├── Goron / Arkari                    -> try read-only data segment first, then handle BR
   ├── Tigress                           -> d810-ng Tigress unflattener
   ├── Hodur (PlugX)                     -> d810-ng HodurUnflattener
   └── amice (with VM)                   -> not plain fla; needs VM handler recovery
  ↓
2. Choose the tool (see the decision table in section 0)
   ├── IDA + network OK + non-sensitive sample -> obpo-plugin
   ├── IDA + local                              -> d810-ng
   ├── Binary Ninja                             -> ollvm-breaker
   ├── No GUI + x86/x64                         -> ollvm-unflattener (Miasm)
   ├── No GUI + ARM64                           -> deollvm (Unicorn) / angr
   └── Pure symbolic execution / CTF            -> angr
  ↓
3. Layered deobfuscation (order matters)
   a) Remove opaque predicates first (bcf) -> d810-ng opaque predicate removal
   b) Then remove flattening (fla)         -> unflattener
   c) Finally simplify MBA (sub)           -> d810-ng MBA simplifier / SiMBA
  ↓
4. Verify
   ├── Function size significantly reduced?
   ├── CFG went from star-shaped/radial to chain/tree-shaped?
   └── Frida-hooked key functions show correct logic?
```

### 4.2 Android NDK .so Specialization

OLLVM-hardened .so files from the Android NDK are the most common APK reversing scenario.

**Step 1 — Extract the .so:**
```bash
adb pull /data/app/~~/lib/arm64/libnative.so
# Or extract straight from the APK: unzip target.apk -d out/ ; find out -name "*.so"
```

**Step 2 — Identify OLLVM and the variant:**
```bash
readelf -a libnative.so | grep -E "Size|text"   # Abnormally large .text but few functions -> likely OLLVM
# Open in IDA and check function signatures:
#   Huge switch -> fla
#   Unreachable branches -> bcf
#   Complex arithmetic -> sub/MBA
#   Indirect jump BR x8 -> Goron/Arkari; try read-only data segment
#   while(1) + jnz state -> Hodur; use d810-ng HodurUnflattener
```

**Step 3 — De-obfuscate (layered):**
```
a) bcf: d810-ng opaque predicate removal  (or obpo handles it automatically)
b) fla: d810-ng Unflattener / obpo-plugin / deollvm (ARM64)
c) sub: d810-ng MBA simplifier
```

**Step 4 — Frida dynamic verification:**
```javascript
// Trace the OLLVM state variable to help deflat locate its address
const target = Module.findBaseAddress("libnative.so");
console.log("[+] libnative.so @", target);

// Hook at the dispatcher entry and observe the state change sequence
Interceptor.attach(target.add(0x1234), {  // dispatcher offset
    onEnter(args) {
        // Read the state variable (determine register/stack slot from the decompilation)
        console.log("[state]", this.context.x8);  // assume state is in x8
    }
});
```

### 4.3 CTF Fast De-Obfuscation

CTF time is tight; prefer the fastest path:

```python
#!/usr/bin/env python3
"""CTF OLLVM quick deflat with angr"""
import angr

proj = angr.Project("challenge", auto_load_libs=False)
cfg = proj.analyses.CFGFast()

# Find the largest functions (most likely the obfuscated ones)
funcs = sorted(cfg.functions.values(), key=lambda f: f.size, reverse=True)[:5]
for func in funcs:
    print(f"[*] {func.name} @ {hex(func.addr)} size={hex(func.size)}")
    try:
        deob = proj.analyses.Deobfuscator(func=func)
        deob.normalize()
        print(f"    [+] deobfuscated")
    except Exception as e:
        print(f"    [-] failed: {e}")
        # angr failed -> suspect Trap Angr -> switch to d810-ng / Unicorn
```

---

## 5. MBA Expression Simplification

### 5.1 Common OLLVM MBA Patterns

```python
# These identities are the simplification targets of expressions produced by the OLLVM sub pass
"(a | b) + (a & b)"        # -> a + b
"(a | b) - (a & b)"        # -> a ^ b
"(a ^ b) + 2*(a & b)"      # -> a + b
"(a | b) & ~(a & b)"       # -> a ^ b
"~(~a & ~b)"               # -> a | b (De Morgan)
```

### 5.2 Tool Selection

| Tool | Method | Fits |
|------|------|------|
| **d810-ng MBA simplifier** | Batch inside IDA, Z3-verified | First choice, integrated in the decompilation flow |
| **SiMBA** (`pip install simba-simplifier`) | CLI/library | Pure expression simplification, batch processing |
| **Arybo** | Symbolic bit-vectors | Large numbers of MBA expressions |
| **Z3 direct solving** | SMT | Most general, when all template matching fails |

```python
# SiMBA example
from simba import simplify_mba
exprs = ["(a | b) + (a & b)", "(a ^ b) + 2*(a & b)"]
for e in exprs:
    print(f"{e}  →  {simplify_mba(e)}")
```

---

## 6. Complete Case Pipeline Script

```bash
#!/bin/bash
# OLLVM deobfuscation pipeline (2026 community tools)
# Fits ELF/.so hardened with standard OLLVM / Hikari / O-MVLL

BINARY=$1

echo "[*] Stage 0: basic analysis and variant identification"
file $BINARY
readelf -h $BINARY 2>/dev/null | head -5
echo "    -> Confirm the variant in IDA (see section 1)"

echo "[*] Stage 1: d810-ng local deobfuscation (first choice)"
echo "    IDA -> Ctrl-Shift-D to load d810-ng"
echo "    Tick: MBA + Opaque predicate + Unflattener"
echo "    Apply to target functions"
echo "    Save the IDB"

echo "[*] Stage 2: obpo-plugin (if d810-ng is insufficient and cloud is acceptable)"
echo "    IDA -> right-click dispatcher -> OBPO -> Mark and process"
echo "    ⚠️ Do not use for sensitive samples (the binary is uploaded to a cloud service)"

echo "[*] Stage 3: no-IDA alternative (x86/x64)"
echo "    python unflattener -i $BINARY -o deobf.bin -t <func_addr> -a"

echo "[*] Stage 4: ARM64 .so no-IDA alternative"
echo "    deollvm (Unicorn) or angr Deobfuscator"

echo "[+] Done. Re-analyze in IDA to verify."
```

---

## 7. Common Pitfalls (Community Practice Summary)

| Problem | Cause | Solution |
|------|------|---------|
| angr path explosion/abnormal exit | Pluto/Polaris's **Trap Angr** pass | Switch to d810-ng or Unicorn dynamic methods |
| obpo-plugin cannot connect | Server is self-funded and may be down | Switch to local d810-ng; you can file an issue in the obpo repo |
| Goron/Arkari indirect-jump deflat fails | Dispatcher uses BR x8 instead of a switch | Set the data segment read-only first, then use DeObfBR |
| Function still messy after d810-ng | OLLVM customized pass parameters/seed | Use symbolic execution to remove opaque predicates first, then unflatten |
| Nested fla (multi-layer flattening) not fully cleared in one pass | obpo/d810-ng only clears one layer per run | **Iterate**: mark each newly appearing dispatcher |
| ARM64 .so errors with old deflat | Old deflat scripts only support x86 | Use d810-ng / obpo (supports ARM64) / deollvm |
| Hikari strings invisible | String Encryption pass | Emulate the decryption stub with Unicorn and dump the decrypted strings |
| amice target: deflat totally ineffective | Contains VM Flatten / Instruction Virtualization | **Not OLLVM fla**; needs VM handler recovery (see VM reversing) |
| Hodur (PlugX) sample has no switch dispatcher | Nested while(1) + jnz state | Use d810-ng **HodurUnflattener**, not the plain Unflattener |
| Approov sample state constants look random | Constants concentrated in 0xF6000–0xF6FFF | Use d810-ng **BadWhileLoop** unflattener |
| Sensitive sample accidentally sent through obpo | Binary uploaded to a cloud service | Classified/unpublished-vulnerability samples use **local tools only** (d810-ng/angr) |
| Frida hooking an OLLVM function hangs | The state variable changed, causing an infinite loop | Add a conditional breakpoint at the dispatcher entry to cap the iteration count |

---

## 8. Tool Cheat Sheet (2026 Community Activity)

| Tool | Platform | Method | Stars/price | Last update | Open source | Notes |
|------|------|------|---------|---------|------|------|
| **obpo-plugin** | IDA | microcode+concolic (cloud) | 629 | 2026-06 | plugin open/core closed | Strongest effect; needs network |
| **ollvm-breaker** | Binary Ninja | BN API | 441 | 2026-06 | ✅ | Practical Android .so |
| **ollvm-unflattener** | CLI | Miasm symbolic execution | 265 | 2026-06 | ✅ | x86/x64, BFS multi-layer |
| **d810-ng** | IDA | microcode+Z3 | 223 | 2026-06 | ✅ | **Local first choice**, broad variant coverage |
| **DeObfBR** | — | BR obfuscation specialist | 96 | 2026-06 | ✅ | Goron/Arkari indirect branches |
| **IDA_Ollvm-unflattener** | IDA | Miasm plugin port | 90 | 2026-04 | ✅ | IDA plugin wrapper of ollvm-unflattener |
| **deollvm** | CLI | Unicorn | 34 | 2026-04 | ✅ | ARM64 specialist |
| **angr** | CLI | Symbolic execution | — | active | ✅ | General; countered by Trap Angr |
| **SiMBA** | CLI/library | MBA simplification | — | — | ✅ | Expression simplification |
| **Triton** | CLI | Symbolic execution + taint | — | active | ✅ | Dynamic symbolic execution |

---

## 9. References

**Obfuscators (to understand what you are countering):**
- [obfuscator-llvm/obfuscator](https://github.com/obfuscator-llvm/obfuscator) — original OLLVM
- [HikariObfuscator/Hikari](https://github.com/HikariObfuscator/Hikari) — Hikari
- [komimoe/Hikari](https://github.com/komimoe/Hikari) — Arkari (based on goron, LLVM 14+)
- [amimo/goron](https://github.com/amimo/goron) — goron
- [bluesadi/Pluto](https://github.com/bluesadi/Pluto) — Pluto
- [za233/Polaris-Obfuscator](https://github.com/za233/Polaris-Obfuscator) — Polaris (formerly Pluto)
- [open-obfuscator/o-mvll](https://github.com/open-obfuscator/o-mvll) — O-MVLL
- [fuqiuluo/amice](https://github.com/fuqiuluo/amice) — Rust implementation of OLLVM passes
- [lich4/awesome-ollvm](https://github.com/lich4/awesome-ollvm) — **variant ecosystem overview (strongly recommended first read)**

**Deobfuscation tools:**
- [obpo-project/obpo-plugin](https://github.com/obpo-project/obpo-plugin) — strongest cloud plugin
- [w00tzenheimer/d810-ng](https://github.com/w00tzenheimer/d810-ng) — local first choice
- [cdong1012/ollvm-unflattener](https://github.com/cdong1012/ollvm-unflattener) — Miasm pure script
- [amimo/ollvm-breaker](https://github.com/amimo/ollvm-breaker) — Binary Ninja
- [GeT1t/deollvm](https://github.com/GeT1t/deollvm) — ARM64 Unicorn
- [Mrack/DeObfBR](https://github.com/Mrack/DeObfBR) — BR obfuscation specialist
- [maskelihileci/IDA_Ollvm-unflattener](https://github.com/maskelihileci/IDA_Ollvm-unflattener) — IDA plugin port
- [angr](https://angr.io/) — symbolic execution framework
- [SiMBA](https://github.com/tech-srl/simba) — MBA simplification

**Academic/blog:**
- [Quarkslab: Deobfuscation: Recovering an OLLVM-protected program](https://blog.quarkslab.com/deobfuscation-recovering-an-ollvm-protected-program.html) — classic deflat principles
- [MODeflattener](https://github.com/mrT4ntr4/MODeflattener) — static deflat (the counterpoint to ollvm-unflattener)

> Related documents: [[anti-analysis.md]] (anti-debug/anti-analysis master table), [[tools-advanced.md]] (advanced toolset), [[elf-analysis.md]] (ELF file analysis), [[ai-assisted-re.md]] (AI-assisted reversing)
