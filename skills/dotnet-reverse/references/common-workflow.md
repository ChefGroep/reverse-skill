# .NET Reverse Engineering Universal Workflow

Full workflow details, IL patch reliability, string decryptor extraction, state machine identification, dnlib scripting.

## Full Workflow (end to end)

```text
1. Identify  → confirm it is a .NET managed program (not native)
2. Detect    → DIE / de4dot --detect identifies the obfuscator
3. Deobf     → de4dot deobfuscation (keep the original sample)
4. Static    → dnSpyEx browse the C# view to locate; IL view for key logic
5. Dynamic   → dnSpyEx debugger breaks on key methods; read runtime plaintext
6. Patch     → IL editor changes; Save Module
```

Persist the artifact of every step: original sample `target.exe` → unpacked `target-clean.exe` → patched `target-patched.exe`.

## IL patch vs C# patch reliability

**Core conclusion: use the IL editor for critical changes, not the C# editor.**

| Dimension | C# editor (Edit Method C#) | IL editor (Edit IL) |
|-----------|----------------------------|---------------------|
| Compilation failure risk | High (missing references, syntax, lambda rewrite failures) | Nearly zero |
| Information fidelity | Compiler regenerates IL, possibly different from the original | Verbatim replacement, instruction by instruction |
| Fits | Changing a string, a constant, simple logic | Changing decisions, removing checks, changing control flow |
| async/await/state machines | Often fails to compile or distorts | Edit state machine fields directly, reliable |

dnSpyEx's C# decompiler is read-only decompilation + attempted recompilation; for compiler-generated code (state machines, closures, `yield`) recompilation fails easily. The IL editor edits instruction by instruction — what you see is what you get.

### Typical IL patch patterns

```text
Change a decision (if (check) → always true):
  Original: call bool Foo::Check()
            brfalse.s SKIP
  Change:   ldc.i4.1            ; push true
            brfalse.s SKIP      ; now never jumps, SKIP not executed
  Or more directly:
            ldc.i4.1
            ret                 ; the method returns true directly

Change a decision (if (check) → always false):
  ldc.i4.0
  ret

Remove a whole check block:
  nop everything, or change to ret + correct return value

Change a string constant:
  Changing strings in the C# editor is usually OK (ldstr swaps the token directly), but if the string lives in resources/encryption you must change the decryption logic

Change a numeric constant:
  ldarg / ldc instructions: change the operand directly
```

## State Machine Identification (async/await / yield)

C#'s `async/await` and `IEnumerator` yield compile into **state machines**: the compiler generates a nested class whose `MoveNext()` uses a `state` field for switch dispatch. dnSpyEx's C# view restores it as async, but decompilation may distort; the IL view of `MoveNext` is the most accurate.

```text
async/await MoveNext structure:
  switch(this.<>1__state) {
    case 0: ... logic before await; this.<>1__state = 1; await MoveNext;
    case 1: ... logic after await;
  }

To patch async logic: change the state transitions in MoveNext or the decisions in a specific case.
The C# editor almost always fails on async → must use IL.
```

## String Decryptor Extraction

Details in `obfuscators.md`. Supplement here: dnlib-scripted batch string decryption:

```csharp
// dnlib script: scan all string decryptor calls, restore at runtime, write back
// Usage: dotnet script decrypt.csproj target.exe 0x06000012
using System;
using System.Reflection;
using dnlib.DotNet;
using dnlib.DotNet.Writer;
using dnlib.DotNet.Emit;

var module = ModuleDefMD.Load(args[0]);
var decryptorToken = uint.Parse(args[1], System.Globalization.NumberStyles.HexNumber);

// Find the decrypt method and call it via reflection (requires loading the assembly into AppDomain)
// Iterate all methods, replacing call Decryptor(token) with ldstr "decryption result"
foreach (var type in module.GetTypes())
    foreach (var method in type.Methods)
    {
        if (!method.HasBody) continue;
        var instrs = method.Body.Instructions;
        for (int i = 0; i < instrs.Count; i++)
        {
            // Identify the call-decryptor pattern, call the decryptor for plaintext, replace with ldstr
            // (reflection boilerplate omitted here; idea: load the original assembly →
            //   MethodInfo.Invoke for plaintext → instrs[i] = OpCodes.Ldstr + operand=plaintext)
        }
    }

var opts = new ModuleWriterOptions(module);
module.Write("target-decrypted.exe", opts);
```

dnlib is the de facto standard for .NET metadata programming — de4dot uses it internally. First choice when writing custom deobfuscation scripts.

## Dynamic Debugging Focus

dnSpyEx's debugger is far friendlier to .NET programs than native:

- **Break at method entry**: right-click method → Add Breakpoint
- **Read object values**: once broken, the Locals / Watch windows show object fields and string contents directly
- **Memory writes**: change runtime variable values directly (Edit Value)
- **Exception breakpoints**: Debug → Exceptions, check the exception types to break on — obfuscators often use exception-driven control flow; breaking on exceptions reveals the real path

### Exception-Driven Control Flow

Some obfuscators stuff normal logic into `try` and use `throw` + `catch` as jumps. Statically it looks like exception handling in IL, but it is really control flow:

```text
try { throw new CustomException(0x42); }
catch (CustomException e) {
    switch(e.Code) {
        case 0x42: real logic A; break;
        case 0x43: real logic B; break;
    }
}
```

Set an exception breakpoint (on `CustomException`) and trace how `Code` values flow — faster than grinding through IL.

## Module Initializer (Module .cctor)

The .NET module's static constructor (`.cctor` of `<module>`) executes first when the assembly loads; obfuscators often place anti-tamper / decryption initialization here. Analysis order:

```text
1. Look at <module>.cctor (Module .cctor) first — decryption/anti-debug initialization
2. Then Program.Main / Startup
3. anti-tamper in .cctor → patch .cctor before unpacking
```

## Universal Pattern for Extracting Config / C2 / Keys

Red-team tools and loaders often embed encrypted configs in resources or fields, decrypted at runtime:

```text
Location flow:
1. strings for plaintext URLs/IPs (usually absent after obfuscation)
2. Find a byte[] field + decrypt method (AES/XOR)
3. Break dynamically at the decrypt method's return point, dump the decrypted plaintext
4. Common: AES-256-CBC with Key==IV (the Codegate 2013 pattern; see reverse-engineering/tools.md .NET section)
```

See `references/sharp-tools.md` for red-team tools' specific config structures.

## Boundary with reverse-engineering

- **IL2CPP / NativeAOT** → compiled to native, no CLR metadata → use `reverse-engineering/` (IDA/r2); this skill only identifies
- **Managed .NET** (standard C# exe/dll, Mono/Unity managed layer, Xamarin) → this skill
- **Hybrid (native loader + .NET payload)** → loader side via `reverse-engineering/`; dump the .NET payload then switch to this skill

## Persisted Artifact Checklist

For each .NET reverse task, produce:
- `target-original.exe` (original sample, untouched)
- `target-clean.exe` (after de4dot unpacking)
- `notes.md` (identified obfuscator, decryptor token, key method addresses, config/C2/key)
- `target-patched.exe` (after patching, if needed)
- `il-diff.txt` (before/after IL comparison, if patching)
