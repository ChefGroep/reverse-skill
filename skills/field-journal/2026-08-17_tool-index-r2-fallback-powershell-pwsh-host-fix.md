# 2026-08-17 reverse-skill

## Scenario Classification
Toolchain & environment (bootstrap-stage defect fixes)

## Target Overview
Fix three classes of defects layered over one another during local bootstrap: tool-index falsely reporting the radare2 main analyzer `r2` as no; multiple test scripts hardcoding `powershell` subprocess invocations that fail on machines with only PowerShell 7+; and the pin-gate StrictMode property-access bug masked by that failure.

## Scope Summary (sanitized)
- auth_basis: own_system (this repository itself)
- network_profile: offline / no external-target ACT
- asset_types: [local scripts and tool index]

## Roles
- lead_role: lead
- specialists: [bootstrap, test-infra]

## Full Execution Chain

1. Run bootstrap per section 0 of `README_AI.md`: `refresh-tool-index.ps1` generates tool-index.md (37 tools).
2. Reading `tool-index.md` reveals an anomaly: `r2` (radare2 main analyzer) = no, but same-directory `rabin2/rasm2/radiff2/rahash2/rax2/r2pm` are all = yes.
3. List `C:\Users\{username}\Tools\radare2\bin` to confirm: `r2.bat` exists (21 bytes, contents `@"%~dp0\radare2" %*`) alongside `radare2.exe`, **no `r2.exe`**.
4. Read `lib/ToolDiscovery.ps1:131-141`: the `r2` Fallbacks only look for `r2.exe`, missing `r2.bat`/`radare2.exe`. By contrast, `jadx`/`apktool`/`analyzeHeadless` all have fallbacks configured for `.bat` tools.
5. Fix: add `r2.bat` and `radare2.exe` paths to the `r2` Fallbacks (covering three locations: `%USERPROFILE%\Tools\radare2\bin`, the repo root, and `C:\Tools\`), keeping the original `r2.exe` fallback for compatibility with other machines.
6. Rerun `refresh-tool-index.ps1`: `r2` flips to yes, path `r2.bat`, version `radare2 6.2.0`, source `FallbackPath`.
7. Run `smoke.ps1`, still FAIL: `verify-routing-coherence exit 1`. Run verify directly to see the error — traced to `verify-routing-coherence.ps1:257` hardcoding `& powershell`; this machine has no `powershell` (only `pwsh` 7.6.4).
8. Grep all `.ps1` files in the repo for `powershell\s(-NoProfile|-ExecutionPolicy|-File|-Command)`: 5 scripts with 20+ hardcoded `& powershell` subprocess invocations (verify 7 / test-p0-friction 18 / test-routing 1 / case-init 1; the rest are comment examples).
9. Found that `smoke.ps1:31-46` already correctly uses `$SmokeHostExe` (current process path first → pwsh → Windows PowerShell path fallback). Extract that proven logic into a shared function `Resolve-ReverseHostExe` in a new `lib/HostRuntime.ps1`; resolution order: current process → `pwsh` → `powershell` → `%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe`.
10. The 4 sub-scripts dot-source `HostRuntime.ps1` and define `$HostExe`; replaceAll turns `& powershell -NoProfile -ExecutionPolicy Bypass -File` → `& $HostExe -NoProfile -ExecutionPolicy Bypass -File`; `test-p0-friction.ps1:244`'s `cmd /c "powershell ..."` is separately changed to `cmd /c "`"$HostExe`" ..."` (the path may contain spaces and needs quoting).
11. Rerun smoke: verify passes line 257, but exposes `verify-routing-coherence.ps1:414` — the pin gate accesses nonexistent properties like `$cap.pinnedVersion` under `Set-StrictMode -Version Latest` and errors out — a pre-existing bug masked until now by the powershell bug.
12. Fix 414: convert `$cap` to a hashtable (`$capMap`); indexed access to a missing key returns `$null` without erroring, pin-gate semantics unchanged.
13. Rerun smoke → ALL PASS (VERIFY_EXIT=0 / PARSE 11/11 / ROUTE 9/9).
14. Run `test-routing.ps1` → 166/166 ALL PASS.
15. Run `test-p0-friction.ps1` → mostly passing, but `:343` and `:364` hit `Start-Process -FilePath 'powershell.exe'` again (the earlier grep pattern `powershell\s+(-NoProfile...)` missed the literal `powershell.exe`).
16. Grep `powershell\.exe`: confirm only test-p0-friction's 343/364 are hardcoded Start-Process invocations (the rest are compatibility lookups or fallback paths); replaceAll changes them to `Start-Process -FilePath $HostExe`.
17. Rerun `test-p0-friction.ps1` → ALL PASS (FAIL_COUNT=0). All three suites green.

## Evidence Chain Summary (sanitized)
> This run was a bootstrap fix on this repository itself, no external-target ACT, no evidence files produced under a case directory. The following are reproducible verification commands (equivalent Evidence).

| E-id | severity | status | source_type | Reusable command pattern | Related Finding |
|------|----------|--------|-------------|----------------|--------------|
| E-r2 | info | validated | command | After `pwsh -File skills/scripts/refresh-tool-index.ps1`, the `r2` line in tool-index.md = yes | F-r2 |
| E-smoke | info | validated | command | `pwsh -File skills/scripts/smoke.ps1` → `OVERALL: ALL PASS` | F-host |
| E-route | info | validated | command | `pwsh -File skills/scripts/test-routing.ps1` → `166/166 ALL PASS` | F-host |
| E-p0 | info | validated | command | `pwsh -File skills/scripts/test-p0-friction.ps1` → `OVERALL: ALL PASS` | F-host |

## Finding / Path Summary
- top_finding: Three defect classes layered over one another — the `r2` fallback misses the `.bat` entrypoint → verify's hardcoded `powershell` fails and aborts → masking the pin-gate StrictMode property-access bug; a follow-up compatibility grep then also missed the literal `powershell.exe`.
- path_type: solve
- path_one_liner: Unify subprocess entrypoints with a shared `Resolve-ReverseHostExe` (current process first), add `.bat`/`radare2.exe` fallbacks for `r2`, and access optional PSCustomObject properties safely via a hashtable.

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| tool-index marks `r2` no while other same-dir r2* tools are yes | `ToolDiscovery.ps1`'s `r2` Fallbacks only look for `r2.exe`, but the radare2 Windows distribution wraps `radare2.exe` with `r2.bat` and ships no `r2.exe` | Add `r2.bat` and `radare2.exe` path fallbacks | short |
| smoke still FAILs: verify exit 1 | verify internally hardcodes `& powershell`; this machine has only pwsh 7+, no `powershell` | Add `Resolve-ReverseHostExe` in a new `lib/HostRuntime.ps1`; replace in 4 scripts with `& $HostExe` | medium |
| After fixing powershell, verify fails again at 414 | Pre-existing bug masked by the line-257 powershell bug: accessing nonexistent properties like `$cap.pinnedVersion` under StrictMode errors out | Convert `$cap` to hashtable `$capMap`; indexed access doesn't error | short |
| test-p0-friction fails again at 343/364 | `Start-Process -FilePath 'powershell.exe'` hardcoded; the earlier grep pattern `powershell\s+(-NoProfile...)` missed the literal `powershell.exe` | Extend the scan with grep `powershell\.exe`, switch to `$HostExe` | short |
| test-p0-friction spews `Exception: case-init.ps1:54` | Test 14b deliberately uses an illegal CaseName to trigger a case-init exception; expected | No action needed; final FAIL_COUNT=0 counts as pass | — |

## Toolchain Findings
- **radare2 Windows distribution layout**: the main program is `radare2.exe`, and `r2.bat` (`@"%~dp0\radare2" %*`) is its batch wrapper — **there is no `r2.exe`**. Any tool scan probing `r2.exe` misreports. Same-directory `rabin2.exe`/`rasm2.exe` etc. are standalone `.exe` files and probe fine.
- **PowerShell 7+-only environment**: this machine has `pwsh` 7.6.4 (path `C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.4.0_x64__8wekyb3d8bbwe\pwsh.exe`), **no `powershell` / `powershell.exe`**. Every `& powershell ...` subprocess invocation fails outright in this environment.
- **StrictMode property access**: under `Set-StrictMode -Version Latest`, accessing a nonexistent `PSCustomObject` property throws; indexed access on a hashtable returns `$null` for a missing key — the safe pattern for pin-gate-style "many optional properties" scenarios.
- **Blind spots in grep compatibility scans**: a pattern like `powershell\s+(-NoProfile...)` only catches the `& powershell -File` form, missing `Start-Process -FilePath 'powershell.exe'` and `cmd /c "powershell ..."`. Compatibility scans should cover both `powershell\s` and `powershell\.exe`.

## Key Code/Commands

```powershell
# lib/HostRuntime.ps1 —— unified subprocess PowerShell entrypoint (current process first)
function Resolve-ReverseHostExe {
    [CmdletBinding()] [OutputType([string])] param()
    $hostExe = $null
    try { $p = (Get-Process -Id $PID -ErrorAction Stop).Path; if ($p -and (Test-Path -LiteralPath $p)) { $hostExe = $p } } catch { }
    if (-not $hostExe) { $c = Get-Command pwsh -ErrorAction SilentlyContinue; if ($c -and $c.Source) { $hostExe = $c.Source } }
    if (-not $hostExe) { $c = Get-Command powershell -ErrorAction SilentlyContinue; if ($c -and $c.Source) { $hostExe = $c.Source } }
    if (-not $hostExe -and $env:SystemRoot) { $f = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'; if (Test-Path -LiteralPath $f) { $hostExe = $f } }
    if (-not $hostExe) { throw 'No usable PowerShell host executable found.' }
    return $hostExe
}

# ToolDiscovery.ps1 r2 Fallbacks —— add .bat/.exe entrypoints
Fallbacks = @(
    @{ Type = 'command'; Value = 'r2' },
    @{ Type = 'command'; Value = 'radare2' },
    @{ Type = 'path'; Value = (Join-Path $userProfile 'Tools\radare2\bin\r2.bat') },
    @{ Type = 'path'; Value = (Join-Path $userProfile 'Tools\radare2\bin\radare2.exe') },
    @{ Type = 'path'; Value = (Join-Path $userProfile 'Tools\radare2\bin\r2.exe') }
    # ... root and C:\Tools mirrors
)

# verify-routing-coherence.ps1:412 —— safe pin-gate property access
foreach ($cap in $mc.capabilities) {
    $capMap = @{}
    foreach ($prop in $cap.PSObject.Properties) { $capMap[$prop.Name] = $prop.Value }
    if (-not $capMap['canAutoInstall']) { continue }
    $hasPin = ($capMap['pinnedVersion'] -or $capMap['pinnedCommit'] -or $capMap['pinPolicy'])
    # ... switch ($capMap['bootstrapKind']) ...
}
```

## Improvement Suggestions for This Package
- **Script the compatibility scan**: in `verify-routing-coherence.ps1` or a standalone lint, scan all `.ps1` subprocess invocations, forbid bare `powershell` / `powershell.exe`, and require everything to go through `Resolve-ReverseHostExe`. This round relied on manual greps, which easily miss things (the `powershell.exe` blind spot was already hit).
- **`.bat` convention in the tool catalog**: on Windows, `jadx`/`apktool`/`r2`/`analyzeHeadless` are all `.bat` wrappers around `.exe`; the catalog should pair every such tool with both `.bat` and matching `.exe` fallbacks to avoid tripping over each one.
- **CI should include a "pwsh-only" matrix**: on GitHub Actions `windows-latest`, this class of bug surfaces if Windows PowerShell 5.1 is not preinstalled. `smoke.ps1` already does the right thing with `$SmokeHostExe`, but the sub-scripts don't reuse it.
- **Iterating PSCustomObject under StrictMode**: for pin-gate-style checks with "loose object schemas", uniformly convert to hashtables for access, or provide a `Get-SafeProp` helper.

## Reusable Patterns/Script Snippets
- `Resolve-ReverseHostExe`: whenever a script needs to spawn a child PowerShell process, dot-source `lib/HostRuntime.ps1` then `& $HostExe -NoProfile -ExecutionPolicy Bypass -File <script> ...`; works on pwsh-only / powershell-only / mixed installs.
- `$capMap` conversion: iterate a `PSCustomObject`'s properties into a hashtable, then access by index to avoid StrictMode missing-property exceptions.
- `r2.bat` → `radare2.exe` passthrough: version detection via `r2.bat -v` correctly returns `radare2 6.2.0`, proving the `.bat` wrapper passes arguments through — safe to use as a catalog entrypoint.

## Evolution Actions
- [x] Updated tool-index (r2 flips to yes, path r2.bat)
- [x] Added `skills/scripts/lib/HostRuntime.ps1`
- [x] Fixed `ToolDiscovery.ps1` r2 Fallbacks
- [x] Fixed `verify-routing-coherence.ps1` powershell hardcoding + pin-gate StrictMode
- [x] Fixed `case-init.ps1` / `test-routing.ps1` / `test-p0-friction.ps1` powershell hardcoding
- [ ] Updated routing matrix (none)
- [ ] Updated bootstrap-manifest (none)
- [ ] Added pitfalls record (this entry)

## Environment Info
- OS: Windows (win32)
- Shell/Host: pwsh 7.6.4 (`C:\Program Files\WindowsApps\Microsoft.PowerShell_7.6.4.0_x64__8wekyb3d8bbwe\pwsh.exe`); no `powershell` / `powershell.exe` on this machine
- radare2: 6.2.0 +1 abi:132 @ windows-x86_64 (installed at `C:\Users\{username}\Tools\radare2\bin\`)
- Repo root: `D:\Sources\reverse-skill`

## Sanitization Requirements
This run was a fix of this repository's own scripts; no real target domains/IPs/credentials involved, no sanitization needed.

## Index Sync (last step before commit)

After writing this journal, sync `_index.md`:
1. Add one line under the "Toolchain & Environment" section ✓
2. Append this filename under "High-Frequency Success Patterns" (unified PowerShell subprocess entrypoint) ✓
3. Append this filename under "Entity Inverted Index" (reverse-skill bootstrap scripts) ✓
4. Update the "Statistics" totals and last-updated date ✓

---
<!-- [Evolution stats] Package cumulative completed items: 19 | New patterns this run: 1 (Resolve-ReverseHostExe unified subprocess entrypoint) | Toolchain issues fixed this run: 3 (r2 fallback / powershell hardcoding / pin-gate StrictMode) -->
<!-- [Community contribution] This fix is a bootstrap-defect fix on the repository itself, qualifying as a fix-type PR per CONTRIBUTING.md; ask the user whether to submit when done. -->
