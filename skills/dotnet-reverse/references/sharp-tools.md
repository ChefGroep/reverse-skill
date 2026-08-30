# Red-Team Sharp* Tool Analysis & Tool Install Matrix & dnSpy MCP

## Red-Team Sharp* Tool Analysis

Red-team tools are heavily written in C# (the Sharp* family); reverse engineering them is a common scenario: understanding detection logic, changing signatures, extracting embedded configs.

### Common Sharp* Tools Quick Reference

| Tool | Function | RE focus |
|------|----------|----------|
| **Rubeus** | Kerberos attacks (AS-REP roast / Kerberoast / S4U / pass-the-ticket) | Rubeus's project structure is fixed; find the `Interop.*` P/Invoke section to see native calls |
| **SharpHound** | BloodHound data collector | LDAP query logic, collected attribute sets |
| **SharpShell / SharpWS** | Remote execution, lateral movement | WMI / WinRM calls, command obfuscation |
| **Seatbelt** | Information gathering | Collection item list, decision logic |
| **SharpRoast** | Kerberoasting | Ticket request/parsing |
| **Inveigh / SharpSploit** | Man-in-the-middle / general exploitation framework | Reflection loading, API call chains |

### Universal Analysis Playbook

```text
1. Open in dnSpyEx (usually unobfuscated; a few teams add ConfuserEx)
2. Look at Program.Main or the entry command dispatch (Rubeus is a switch(command) structure)
3. Find the implementation class/method of the target command
4. Look at the P/Invoke section (Interop.* namespaces) — native API calls live here
5. Extract embedded resources (some tools embed configs/templates)
6. If signatures need changing (EDR evasion): change command strings, API calls, string constants
```

### Rubeus Structure Example

Rubeus uses command dispatch, one class per subcommand. Finding the Kerberoasting logic:

```text
Entry: Rubeus.CommandLineParser → parse args
Dispatch: switch(command) → "kerberoast" → execute Ask.TGS(...)
P/Invoke: Rubeus.Interop.Lsa* / Native.cs → native Kerberos API
Key: LsaCallAuthenticationPackage (KERB_RETRIEVE_TKT_REQUEST)
```

Signature changes (evasion): rename the command string `"kerberoast"` to a custom name, change the `Rubeus` banner string, reorder P/Invoke calls.

### Embedded Config Extraction

Many loaders/tools embed encrypted C2, keys, certificates in resources or fields:

```powershell
# Look at Resources in dnSpyEx (resource tree)
# Or from the command line
powershell -c "[System.Reflection.Assembly]::LoadFile('target.exe').GetManifestResourceNames()"
# Once found, right-click the resource in dnSpyEx → Extract / Save
```

Runtime-decrypted configs → break dynamically at the decrypt method's return point and dump the plaintext (see `common-workflow.md`).

---

## Tool Install Matrix

### Windows (preferred; dnSpyEx is a GUI)

```powershell
# Option A: Chocolatey
choco install dnspy ilspy de4dot detect-it-easy

# Option B: manual release download (recommended, version-controlled)
# dnSpyEx:    https://github.com/dnSpyEx/dnSpy/releases
# de4dot:     https://github.com/de4dot/de4dot/releases
# ILSpy:      https://github.com/icsharpcode/ILSpy/releases
# DIE:        https://github.com/horsicq/Detect-It-Easy/releases
# dnlib:      dotnet add package dnlib  (NuGet)
```

### Linux / macOS (no dnSpyEx GUI; use CLI)

```bash
# ILSpy CLI decompilation
dotnet tool install -g ilspycmd
ilspycmd target.exe -p -o outdir/         # decompile into a directory

# de4dot cross-platform (needs mono or dotnet)
# Download de4dot's release .dll artifacts and run with dotnet
dotnet de4dot.dll target.exe -o target-clean.exe

# dnlib (scripted, needs dotnet SDK)
dotnet new console -o dnclean && cd dnclean
dotnet add package dnlib

# DIE CLI (diec)
# Linux: install from https://github.com/horsicq/Detect-It-Easy
diec target.exe
```

### .NET Runtime Prerequisite

```bash
# Linux
sudo apt install dotnet-runtime-8.0        # or 6.0/7.0 depending on the target
# macOS
brew install --cask dotnet-sdk
```

> dnSpyEx (with IL editor + debugger) exists only as a Windows GUI. On Linux/macOS, .NET reverse engineering is limited to `ilspycmd` decompilation + `dnlib` script patching, with no equivalent interactive debugging GUI. Prefer Windows when patching.

---

## dnSpy MCP Integration

The community already has several dnSpy MCP projects exposing dnSpy's decompilation/IL inspection as MCP tools the AI can call directly — fully aligned with reverse-skill's MCP philosophy.

### Mainstream dnSpy MCP Projects

| Project | Features | Fit |
|---------|----------|-----|
| **soufianetahiri/dnspy-mcp** | Core MCP Server exposing decompile, IL inspection and other tools | Claude Code / Cursor |
| **AgentSmithers/DnSpy-MCPserver-Extension** | Runs as a dnSpyEx extension, deeply integrated with the GUI | Loaded inside dnSpyEx |
| **malwarecakefactory/dnspy-mcp-extension** | 33 tools covering the full triage → deobfuscation flow | Full-process automation |

### Registering in the Claude MCP Config

After installing the dnSpyEx extension per the project's README, register it in `~/.claude/mcp.json` (exact command/args per the project README):

```json
{
  "mcpServers": {
    "dnspy": {
      "command": "dotnet",
      "args": ["path/to/dnspy-mcp.dll"]
    }
  }
}
```

After registration, this skill's AI integration path: user says "analyze this .NET" → route to `dotnet-reverse/` → call the `dnspy_decompile` / `dnspy_inspect_il` tool surfaces first → fall back to the GUI if that fails.

> dnSpy MCP is not a built-in reverse-skill bootstrap capability; the user must install the extension and register it manually per the project README. Consider adding it to `bootstrap-manifest.json` later.

---

## Community Resource Index

### Strongly Recommended

- **Washi's blog** — .NET RE expert: https://blog.washi.dev/posts/misconceptions-about-dotnet/
  - Core point: **do not over-rely on dnSpy's C# decompiler; get familiar with the IL editor** (consistent with this project's IL-first principle)
- **dnSpyEx** — actively maintained dnSpy fork: https://github.com/dnSpyEx/dnSpy
- **de4dot** — .NET deobfuscation: https://github.com/de4dot/de4dot
- **dnlib** — metadata programming: https://github.com/dnlib/dnlib

### Hands-On Tutorials

- Medium "De-obfuscating and reversing a .NET/C# spyware" — dnSpy + de4dot hands-on info-stealer deobfuscation
- YouTube "dnSpy Patch .NET EXEs & DLLs" — step-by-step patching + keygen
- Kanxue forum's .NET RE section — search ".net reverse" / "dnSpy" / "ConfuserEx" for many hands-on threads, Nuitka reversing, AV-evasion discussions
- Guided Hacking "Top 5 .NET Reverse Engineering Tools" — dnSpy still ranks first
- StackExchange / Reverse Engineering — advanced topics such as `DynamicMethod` debugging

### Existing .NET Resources in This Repo (integration)

- `reverse-engineering/tools.md` `.NET Analysis` section — dnSpy/ILSpy quick reference + the Codegate 2013 two-phase XOR+AES-CBC pattern
- `reverse-engineering/field-notes.md` `.NET` section — tool notes
- `reverse-engineering/awesome-re-resources.md` — de4dot listed
- `field-journal/seed-014_unity-il2cpp-reverse.md` — Unity IL2CPP (native side; complements the .NET managed layer)

Deep .NET RE content converges in this module; keep only quick-reference indexes in `reverse-engineering/`.
