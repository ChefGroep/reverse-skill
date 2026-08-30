---
name: dotnet-reverse
description: .NET / C# binary reverse engineering. Use when the target is a .NET assembly (PE header with CLR, managed .exe/.dll), a C# compiled artifact (including NativeAOT), red-team Sharp* tools (Rubeus / SharpHound / SharpHound etc.), .NET obfuscated programs (ConfuserEx / SmartAssembly / Babel / Eazfuscator), or .NET loader / info-stealer / wrapped malware. Prefer dnSpyEx + de4dot; when the AI needs to operate directly, link with dnSpy MCP. Not for pure native binaries (use reverse-engineering / ida-reverse).
license: MIT
compatibility: Requires a filesystem-based code agent or CLI with shell access, Windows host preferred (dnSpyEx is a Windows GUI); Linux/macOS can use ILSpy/de4dot CLI + mono/dotnet runtime.
allowed-tools: Bash Read Write Edit Glob Grep Task WebFetch WebSearch
metadata:
  user-invocable: "false"
---

# .NET / C# Reverse Engineering Playbook

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Use DIE/`file`/CLR header to confirm the target is .NET managed (otherwise SWITCH to `ida-reverse/` / `reverse-engineering/`)
2. `NOW`: If obfuscation is suspected → run `de4dot` first, producing `*-clean.exe`; keep the original sample
3. `NEXT`: dnSpyEx (or dnSpy MCP / `ilspycmd`) static: browse C# and check key decisions in the **IL view**
4. `ACT`: Dynamic debug when you need plaintext/C2; when changing logic, **IL patch** takes priority over C# recompilation
5. At the end of the phase, give the user a 3–6 item next-steps menu (including report export)

## Applicable Scope

Prefer this skill when the task falls into these scenarios:

- Identifying and reverse engineering .NET / C# compiled artifacts (managed PE / .exe / .dll)
- Analyzing red-team Sharp* toolchains (Rubeus, SharpHound, SharpShell, etc.)
- Deobfuscating ConfuserEx / SmartAssembly / Babel / Eazfuscator / .NET Reactor shells
- Reverse engineering the decryption and C2 logic of .NET loaders / info-stealers / RATs
- Patching C# programs (change decisions, constants, keygen)
- Analyzing the Mono/Unity managed layer before IL2CPP (note: IL2CPP compiles to native; use `reverse-engineering/` + seed-014)

If the target is a pure native binary (C/C++/Go/Rust compiled, no CLR), switch to `reverse-engineering/`, `ida-reverse/`, or `radare2/`.

## Core Principles

- **Identify before acting**: first confirm it is a .NET managed program (PE header CLR + `#~` / `#Strings` streams + mscoree `_CorExeMain`), then decide dnSpy over IDA
- **IL over C#**: dnSpyEx's C# decompiler loses/distorts information (compiler-generated state machines, async/await, yield); key decisions and patches must switch to the **IL editor**; the C# view is only for quick browsing
- **de4dot first**: when hitting an obfuscator, run `de4dot` once before static analysis, otherwise strings/control flow are a mess
- **MCP integration**: if a dnSpy MCP (`dnspy_*` tools) is registered in the environment, prefer the MCP surface for decompile / IL inspection to avoid GUI switching back and forth
- **Evidence-based output**: deobfuscated artifacts, extracted configs/C2/keys, patch diffs must all be persisted to disk

## Toolchain Mapping

| Capability | First choice | Notes |
|------------|--------------|-------|
| Decompile + debug + patch | **dnSpyEx** | The ace; the only GUI with an IL editor; old dnSpy is unmaintained, use the Ex branch |
| Lightweight CLI / headless decompilation | **ILSpy** (`ilspycmd`) | Good for batch, scripted, Linux/macOS |
| Deobfuscation | **de4dot** | Default solution for ConfuserEx family, SmartAssembly and other mainstream shells |
| Obfuscator identification | **Detect It Easy (DIE)** / **file** | Decide shell type first, then de4dot parameters |
| Programmatic IL manipulation | **dnlib** | Write C# scripts to batch-modify metadata / string decryptors |
| AI direct operation | **dnSpy MCP** | `dnspy_decompile` / `dnspy_inspect_il` tool surfaces |

> Prerequisite: on Windows install dnSpyEx + de4dot (choco or release); on Linux/macOS use `ilspycmd` + `dotnet runtime`. See the install matrix in `references/sharp-tools.md`.

## Six-Phase Workflow

### 1. Identify (.NET identification)

Confirm the target is a managed program; do not analyze a native PE as .NET:

```powershell
# Windows
file target.exe                       # "PE32 executable ... for MS Windows" is not enough
# Key: check for CLR
powershell -c "[System.Reflection.AssemblyName]::GetAssemblyName('target.exe')"
# Or
dnSpyEx drag-and-drop — if it opens, it is managed

# Universal
strings target.exe | grep -iE "mscoree|_CorExeMain|mscorlib|System\\."
```

**.NET identification markers:**
- PE header `Data Directory[14]` (CLR Runtime Header) non-zero
- `mscoree.dll` import / `_CorExeMain` entry
- `#~`, `#Strings`, `#US`, `#GUID`, `#Blob` metadata streams
- `mscorlib` / `System.Private.CoreLib` strings

**NativeAOT exception:** compiled to native, no CLR header, but with `System.Private.CoreLib` strings and reconstructed type metadata — these go through `reverse-engineering/` (IDA/r2); this skill only provides an identification hint.

### 2. Detect (obfuscator detection)

```powershell
# DIE quick identification
diec target.exe                        # Detect It Easy CLI
# Or drag into dnSpyEx and check for garbled class names / control-flow warping
```

Common obfuscators → deobfuscation strategy (details in `references/obfuscators.md`):

| Obfuscator | Characteristics | de4dot handling |
|------------|-----------------|-----------------|
| ConfuserEx (1.0.0 / 2.x) | `<module>` anti-tamper, control-flow warping, string encryption | `de4dot target.exe` usually auto-detects |
| SmartAssembly | `circular`/`string encoding`, resource compression | `de4dot target.exe` |
| Babel.NET | Method-body encryption, control flow | `de4dot target.exe` |
| Eazfuscator.NET | String/resource encryption | `de4dot`; some versions need manual work |
| .NET Reactor | anti-tamper + necrobit | `de4dot`; new versions may fail and need manual work |

### 3. Deobfuscate

```powershell
# de4dot auto-detects most shells by default
de4dot target.exe -o target-clean.exe

# Specify type (when auto-detection fails)
de4dot --type cfze target.exe          # ConfuserEx
de4dot --type sa target.exe            # SmartAssembly

# Multi-layer obfuscation / de4dot reports unknown
de4dot --detect target.exe             # See what it detects it as
# You may need to patch anti-tamper first, then de4dot (see references/obfuscators.md)
```

Output: `target-clean.exe`; use it for all subsequent analysis. **Keep the original sample** for comparison.

### 4. Static Analyze

Load the deobfuscated sample in dnSpyEx:

- **C# view**: quickly browse class structure, method signatures, strings (for locating)
- **IL view**: key decisions, encryption logic, state machines must be checked in IL (right-click → Edit IL or the IL view)
- Find entry: `Main` / `Startup` / module initializer (`Module .cctor`)
- Find key logic: search for `flag`, `password`, `verify`, `check`, `encrypt`, `http`, `Config`

```text
Locate string → cross-reference → find the method using it → check the decision logic in the IL view
```

### 5. Dynamic

dnSpyEx debugger: attach to process / start debugging, set breakpoints on key methods, observe runtime:
- Decrypted plaintext strings (many obfuscators decrypt strings only at runtime)
- C2 addresses, config decryption results
- Exception-driven control flow (anti-debug often hides the real path with `try/catch`)

> .NET dynamic debugging is far friendlier than native — you can directly see object values and string contents. Prefer dynamic over grinding static.

### 6. Patch (modify as needed)

```text
dnSpyEx → right-click method → Edit Method (C#) or Edit IL
  - Change decision: ldc.i4.0 → ldc.i4.1 (false→true)
  - Change constant: edit the string/number directly
  - Remove a check: nop out the whole block
File → Save Module → replace the original file
```

**IL patch reliability > C# patch**: C# recompilation may fail (missing references, syntax), while IL editing almost never distorts. Details in `references/common-workflow.md`.

## Trigger Scenario Routing

Enter this skill when the user says:
- ".NET / C# binary reverse engineering" / "decompile a C# program"
- "dnSpy analysis" / "dnSpyEx patch"
- "ConfuserEx / SmartAssembly / Babel deobfuscation / unpacking"
- "Sharp* tool analysis" (Rubeus / SharpHound / SharpShell)
- ".NET malware / loader / info-stealer reverse engineering"
- "C# program patch / keygen / change a decision"

## When to Switch Out

- IL2CPP-compiled Unity games → `reverse-engineering/` + `seed-014_unity-il2cpp-reverse.md` (IL2CPP is native; do not use dnSpy)
- NativeAOT artifacts → `reverse-engineering/` (same as above, native)
- Pure native PE (no CLR) → `reverse-engineering/` / `ida-reverse/`
- Need to batch migrate symbols/functions to another version → `binary-diff/`
- Need attack path / call-chain diagrams → `diagram-generator/`

## Routing Context

**Upstream entry**: `skills/SKILL.md` (master), `routing.md`
**Downstream exits**:
- IL2CPP / NativeAOT (native) → `reverse-engineering/`
- Deep native .so/.dll section analysis → `ida-reverse/` / `radare2/`
- Need the AI to operate dnSpy directly → register and link dnSpy MCP (see `references/sharp-tools.md`)

**Peer-related modules**:
- `reverse-engineering/languages-compiled.md` (its .NET intro points to this module)
- `apk-reverse/` (Xamarin/MAUI Android reversing can switch back here for the C# layer)

## Reference Documents

- [references/obfuscators.md](references/obfuscators.md) — ConfuserEx / SmartAssembly / Babel / Eazfuscator / .NET Reactor deobfuscation in depth + anti-tamper bypass
- [references/common-workflow.md](references/common-workflow.md) — Full workflow, IL patch reliability, string decryptor extraction, state machine identification
- [references/sharp-tools.md](references/sharp-tools.md) — Red-team Sharp* tool analysis, tool install matrix, dnSpy MCP integration, community resource index

## Task Completion Self-Check

- [ ] Did I confirm the CLR / managed identity (or SWITCH out of this skill)?
- [ ] Did obfuscated samples get de4dot / equivalent unpacking before deep analysis?
- [ ] Did I verify key logic in the IL view (not just the C# pseudocode)?
- [ ] Are artifacts (clean sample / config / patch diff) persisted and reproducible?
- [ ] Did I provide a next-steps menu or report exit?
