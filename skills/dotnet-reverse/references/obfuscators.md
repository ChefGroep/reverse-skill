# .NET Obfuscator Deobfuscation In Depth

Identification, unpacking, and anti-tamper bypass for mainstream .NET obfuscators. Core tools: **de4dot** (auto-detects most shells) + **dnSpyEx** (manual patching) + **dnlib** (scripting).

## Master Decision Table

| Obfuscator | de4dot type | Typical characteristics | Auto unpack | Manual focus |
|------------|-------------|--------------------------|-------------|--------------|
| ConfuserEx 1.x/2.x | `cfze` | anti-tamper, control-flow warping, string encryption, anti-debug | ✅ mostly automatic | New versions need anti-tamper patched first |
| ConfuserEx 3.x / private mods | `cfze` | Same as above + custom protector | ⚠️ partial | Runtime dump / dnlib |
| SmartAssembly | `sa` | String encoding, resource compression, method-call hiding | ✅ automatic | Resource decompression |
| Babel.NET | `babel` | Method-body encryption, control flow, strings | ✅ automatic | — |
| Eazfuscator.NET | `eaz` | String/resource encryption, expression obfuscation | ⚠️ partial | String decryptor |
| .NET Reactor | `reactor` | necrobit (code-section encryption) + anti-tamper | ⚠️ hard on new versions | Dump + metadata reconstruction |
| Themida .NET | — | Outer shell + virtualization | ❌ de4dot fails | Dump memory; take the native route |
| Agile.NET / CliSecure | `agile` | Method-body encryption | ✅ automatic | — |

## de4dot Standard Usage

```powershell
# Auto-detect (sufficient in most cases)
de4dot target.exe -o target-clean.exe

# Explicitly specify type (when auto-detection fails)
de4dot --type cfze target.exe -o target-clean.exe

# Probe shell type first
de4dot --detect target.exe

# Batch
de4dot *.exe

# Strings only, leave control flow alone (minimal intervention)
de4dot --strtyp delegate --strtok METHOD_TOKEN target.exe
```

de4dot's `--strtyp` / `strtok` mode: only solves the string decryptor (specifies the decrypt method token), keeping the original control flow. Fits the scenario of "just want to see the plaintext strings without touching anti-tamper".

---

## ConfuserEx (most common)

### Characteristic Identification

- The entry `<module>` class carries an anti-tamper check with `[MethodImpl(NoInlining)]`
- Heavy `Dictionary<string, T>` string decryptor calls
- Control-flow flattening (switch dispatch + state variable)
- `.cmp` compressed resources embedded in resources
- dnSpyEx C# view: garbled class/method names (`\uXXXX` or meaningless characters), method bodies full of `int num = ...; switch(num)`

### Unpacking Process

```powershell
# 1. Standard unpacking
de4dot target.exe -o target-clean.exe

# 2. If de4dot reports "unknown" or the unpacked binary won't open → new/private ConfuserEx
#    Confirm anti-tamper first:
Open in dnSpyEx → find the integrity check in Module .cctor or Main
```

### Anti-Tamper Bypass (common on newer ConfuserEx)

ConfuserEx's `anti tamper` validates method-body hashes at runtime and crashes when modified. de4dot usually handles old versions; new versions need manual work:

```text
Method A — patch the check function directly in dnSpyEx:
  1. Find the anti-tamper validation method (usually called from <module>'s static constructor)
  2. IL edit: change the validation method body to ret (return immediately)
  3. Save → feed to de4dot again

Method B — runtime dump:
  1. Run the program with MegaDumper / ExtremeDumper and dump the in-memory assembly
  2. The dump is already decrypted; use de4dot to clean up leftovers
```

### After Control-Flow Restoration

de4dot restores the flattened switch dispatch into normal if/while. If restoration is incomplete (residual state machines visible), run de4dot once more or trace the IL manually.

---

## SmartAssembly

```powershell
de4dot --type sa target.exe -o target-clean.exe
```

Characteristics:
- Strings encoded with the `SmartAssembly.Runtime.Strong` family
- Resource compression (`{assembly}.Resources`)
- Method-call hiding (`ProcessCaller` / indirect calls)

de4dot has the best SmartAssembly compatibility — basically one click.

---

## .NET Reactor (necrobit)

`.NET Reactor`'s **necrobit** encrypts the real method bodies into resources, decrypts and injects them at runtime; the original method bodies are empty shells. de4dot works on old versions; 4.x+ often fails.

```text
When de4dot fails:
1. Let the program run (dotnet target.exe or double-click)
2. MegaDumper / ExtremeDumper dump the process memory → export the decrypted assembly
3. Use de4dot to clean residual obfuscation from the dump
4. If metadata is damaged, rebuild with dnlib (see common-workflow.md)
```

---

## Manual String Decryptor Extraction

Obfuscators encrypt strings and call decrypt methods at runtime to restore them. de4dot auto-detects most decryptors; when detection fails, do it manually:

```text
1. Find the decrypt method in dnSpyEx (usually a fixed signature: static string Decrypt(int) or Decrypt(string, int))
   - Characteristics: heavily called, numeric-constant arguments, returns string
2. Note the method token (e.g. 0x06000012)
3. Point de4dot at the decryptor:
   de4dot --strtyp delegate --strtok 0x06000012 target.exe -o target-clean.exe
```

If the decrypt method itself is also obfuscated (control-flow flattening), deobfuscate the control flow first before locating the decryptor.

## Common Anti-Debug Techniques

| Technique | Location | Bypass |
|-----------|----------|--------|
| `Debugger.IsAttached` check | Any method | IL change to `ldc.i4.0; ret` or patch the getter |
| `Debugger.IsLogging` | — | Same as above |
| Timing check (`DateTime.Now` delta) | Method entry | Patch out the delta comparison |
| `CheckRemoteDebuggerPresent` P/Invoke | — | nop out the call |
| Exception-driven control flow (try/catch path selection) | Main logic | Cannot simply nop; analyze the catch block's real path |

> .NET anti-debug is simpler than native — mostly managed API calls; a single dnSpyEx IL line change suffices.

## Fallbacks When de4dot Fails

1. **de4dot --detect** check the detection result against the table above
2. **Runtime dump** (MegaDumper / ExtremeDumper / Process Hacker module export)
3. **dnlib scripts** solve manually (see the dnlib section of common-workflow.md)
4. **Dynamic first**: run it, break at the decrypt point, read plaintext directly — you can gather intel without unpacking

Community references: Washi's blog "misconceptions-about-dotnet" (common IL-analysis misconceptions), Kanxue .NET RE section, Guided Hacking "Top 5 .NET RE Tools".
