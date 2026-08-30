# System Architecture Diagrams

## Full behavior-chain flowchart

```mermaid
flowchart TD
    Start([User submits a security/reverse task]) --> Detect{Keyword gate triggered?}
    Detect -->|yes| ReadRouting[Read SKILL.md + routing.md]
    Detect -->|no| Normal([Normal conversation])

    ReadRouting --> RouteMatch{Routing matrix match?}
    RouteMatch -->|miss| ProposeNew[Propose a new skill<br/>per CONTRIBUTING.md]
    RouteMatch -->|hit| CheckJournal[Check field-journal<br/>for similar past experience]

    CheckJournal --> CheckTools[Read tool-index.md<br/>confirm tool state]
    CheckTools --> ToolOK{Tools available?}

    ToolOK -->|missing| Bootstrap[Invoke bootstrap-reverse.ps1<br/>auto-install]
    ToolOK -->|available| Execute[Enter the skill workflow]

    Bootstrap --> BootOK{Install succeeded?}
    BootOK -->|success| Execute
    BootOK -->|failure| Guide[Print structured guidance<br/>wait for manual handling]
    Guide --> UserConfirm([User confirms installed])
    UserConfirm --> Execute

    Execute --> TaskDone{Task complete?}
    TaskDone -->|no| Execute
    TaskDone -->|yes| ReviewCase[Invoke case-review<br/>audit the evidence graph]
    ReviewCase --> GenReport[Invoke docs-generator<br/>generate report + diagrams]

    GenReport --> WriteJournal[Write back to field-journal<br/>deposit experience]
    WriteJournal --> UpdateIndex[Update index/routing/manifest]
    UpdateIndex --> Output([Print the final result])
```

## Skill module relationship diagram

```mermaid
flowchart LR
    subgraph Routing layer
        SKILL[SKILL.md<br/>master entry]
        Routing[routing.md<br/>routing matrix]
    end

    subgraph Reverse analysis
        APK[apk-reverse<br/>APK reversing]
        IDA[ida-reverse<br/>IDA Pro]
        R2[radare2<br/>CLI analysis]
        RE[reverse-engineering<br/>general methodology]
        BinDiff[binary-diff<br/>symbol migration]
        PatchDiff[patch-diff-exploit<br/>N-day weaponization]
    end

    subgraph Exploitation
        Pwn[pwn-chain<br/>RE→exploit]
        Firmware[firmware-pentest<br/>firmware full chain]
    end

    subgraph Penetration testing
        Pentest[pentest-tools<br/>toolchain + loop framework]
        SrcHunter[src-hunter<br/>19 playbooks]
        EDR[edr-bypass-re<br/>EDR bypass]
    end

    subgraph Web/browser
        JS[js-reverse<br/>JS signature reversing]
        Browser[browser-automation<br/>Playwright+OpenReverse]
    end

    subgraph Infrastructure
        Bootstrap[bootstrap-reverse.ps1<br/>on-demand bootstrap]
        Discovery[ToolDiscovery.ps1<br/>tool discovery]
        ToolIndex[tool-index<br/>state index]
    end

    subgraph Output layer
        Docs[docs-generator<br/>report generation]
        Diagram[diagram-generator<br/>diagram generation]
        Review[case-review<br/>Evidence graph audit]
        Journal[field-journal<br/>self-evolution]
    end

    subgraph External
        CTF[CTF-Sandbox-Orchestrator<br/>40+ sub-skills]
    end

    SKILL --> Routing
    Routing --> APK & IDA & R2 & RE & BinDiff & PatchDiff
    Routing --> Pentest & JS & Browser & Pwn & Firmware & EDR
    Routing --> CTF

    Pentest --> SrcHunter
    APK -->|split off .so| IDA
    APK -->|split off .so| R2
    PatchDiff -->|writes PoC| Pwn
    Firmware -->|finds crash| Pwn
    Pwn -->|merges into| Pentest
    EDR -->|delivery phase| Pentest
    JS -->|browser operations| Browser

    Bootstrap --> Discovery --> ToolIndex

    APK & IDA & R2 & Pentest & JS -->|task complete| Review
    Review --> Docs
    Docs --> Diagram
    Docs --> Journal
```

## Bootstrap flow

```mermaid
flowchart TD
    Need[Missing tool detected] --> ReadManifest[Read bootstrap-manifest.json]
    ReadManifest --> Kind{Install kind?}

    Kind -->|github-release-zip| GH[Download ZIP from GitHub Release<br/>and extract]
    Kind -->|pip-package| Pip[pip install]
    Kind -->|npm-mcp| NPM[Launch via npx + register MCP]
    Kind -->|npm-global| Global[npm install -g<br/>+ postInstall]
    Kind -->|winget-package| Winget[winget install]
    Kind -->|local-http-mcp| HTTP[Register URL + start service]

    GH & Pip & NPM & Global & Winget & HTTP --> Verify{Verify usable?}
    Verify -->|success| AddPath[Add to PATH<br/>refresh tool-index]
    Verify -->|failure| Manual[Print manual install guidance]

    AddPath --> Continue([Continue the task])
    Manual --> Wait([Wait for user confirmation])
```

## Penetration-testing loop

```mermaid
flowchart TD
    Init[Initialize: target/scope/tools] --> Loop

    subgraph Loop[Core loop]
        Align[1. Re-align the objective] --> Review[2. Review known findings]
        Review --> Decide[3. Decide the next action]
        Decide --> Risk{4. Risk gate}
        Risk -->|low/medium/high| Exec[5. Execute the action]
        Risk -->|critical| Ask[Request user approval]
        Ask -->|approved| Exec
        Exec --> Record[6. Record the result]
        Record --> Check{7. Self-check}
        Check -->|continue| Align
        Check -->|done| Done
    end

    Done[8. Completion check] --> Report([Generate the final report])
```

## Self-evolution mechanism

```mermaid
flowchart LR
    Task([Task completed]) --> WriteLog[Write into field-journal<br/>pitfall + solution + code]
    WriteLog --> UpdateIdx[Update _index.md<br/>classify by scenario]
    UpdateIdx --> CheckUpdate{System update needed?}

    CheckUpdate -->|routing gap| FixRoute[Update routing.md]
    CheckUpdate -->|tool drift| FixTool[Refresh tool-index]
    CheckUpdate -->|new tool| FixManifest[Update bootstrap-manifest]
    CheckUpdate -->|no update needed| Done([Done])

    FixRoute & FixTool & FixManifest --> Done

    NewTask([Next similar task]) --> ReadIdx[Read _index.md]
    ReadIdx --> Reuse[Reuse existing experience<br/>avoid repeat pitfalls]
```

## Multi-platform support architecture

```mermaid
flowchart TD
    subgraph Shared["Shared layer (platform-agnostic)"]
        Skills[skills/<br/>SKILL.md + routing.md + references]
        CTF[CTF-Sandbox-Orchestrator/<br/>40+ sub-skills]
        Journal[field-journal/<br/>experience depository]
        Docs[docs-generator + diagram-generator]
    end

    subgraph Windows["Windows platform layer"]
        WinScripts[skills/scripts/*.ps1<br/>PowerShell scripts]
        WinManifest[bootstrap-manifest.json<br/>winget + GitHub ZIP]
        WinRules[RULES.md<br/>Windows-edition rules]
    end

    subgraph Kali["Kali Linux platform layer"]
        KaliScripts[kali/scripts/*.sh<br/>Bash scripts]
        KaliManifest[kali/scripts/bootstrap-manifest.json<br/>apt + pip + GitHub tar]
        KaliRules[kali/RULES-kali.md<br/>Kali-edition rules]
    end

    Skills --> WinScripts & KaliScripts
    CTF --> WinScripts & KaliScripts
    Journal --> WinScripts & KaliScripts

    WinScripts --> WinManifest
    KaliScripts --> KaliManifest

    WinRules --> Skills
    KaliRules --> Skills
```

### Platform selection logic

| Environment | Rules file | Scripts | Package management |
|------|--------------|-----------|--------|
| Windows | `RULES.md` | `skills/scripts/*.ps1` | winget / GitHub Release ZIP |
| Kali Linux | `kali/RULES-kali.md` | `kali/scripts/*.sh` | apt / pip / npm / GitHub tar.gz |

### Kali-edition traits

- **Many tools preinstalled**: nmap, sqlmap, hashcat, hydra, metasploit, radare2, binwalk, burpsuite, and more need no bootstrap
- **Unified apt management**: no winget, no manual ZIP extraction
- **Native bash**: simpler scripts, no PowerShell dependency
- **Path conventions**: `/usr/bin/`, `/opt/`, `~/tools/`; no drive letters or spaces-in-paths problems

## File-read sequence diagram

```mermaid
sequenceDiagram
    participant U as User
    participant AI as AI client
    participant R as RULES.md / RULES-kali.md
    participant SK as SKILL.md
    participant RT as routing.md
    participant TI as tool-index.md
    participant FJ as field-journal
    participant SUB as Sub-skill
    participant BS as bootstrap
    participant DOC as docs-generator

    U->>AI: Submit a security task
    AI->>R: Read routing rules
    AI->>SK: Read the master entry
    AI->>RT: Match routing
    AI->>FJ: Look up similar experience
    AI->>TI: Confirm tool state
    alt Tools missing
        AI->>BS: Auto-install (.ps1 or .sh)
        BS-->>AI: Result
    end
    AI->>SUB: Enter the workflow
    AI-->>U: Task result
    AI->>DOC: Generate the report
    AI->>FJ: Write back experience
    AI-->>U: Done
```
