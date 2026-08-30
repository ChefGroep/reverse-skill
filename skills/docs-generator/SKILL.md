---
name: docs-generator
description: |
  Creates task-oriented technical documentation with progressive disclosure. Use when writing READMEs, API docs, architecture docs, or markdown documentation.
  Also use this skill at the END of any completed reverse engineering, penetration testing, CTF, or security analysis task to generate a formal report in the user's project directory.
  Trigger keywords: write report, write docs, generate report, writeup, technical documentation, report, documentation.
---

# Technical Documentation

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: confirm whether the current task falls within this skill's scope
2. `NOW`: read `../tool-index.md`, verify tool availability and real paths
3. `NEXT`: when a tool is missing, call bootstrap; do not guess paths
4. `ACT`: enter the first step of the "workflow" and execute; do not stop at a confirmation state

For writing style, tone, and voice guidance, use `Skill(ce:writer)` with **The Engineer** persona.

## Security/RE task document output

When a reverse engineering / pentest / CTF / security analysis task is completed, this skill generates the formal technical document in the **user's project directory**.

### Trigger points

1. A reverse engineering task is complete and has produced core conclusions (algorithm reconstruction, signature cracking, bypass solutions, etc.)
2. A penetration test is complete and vulnerabilities have been found and verified
3. A CTF challenge is solved and the flag obtained
4. The user explicitly requests "write a report/document/writeup"

### Template selection

| Task type | Template |
|---------|---------|
| APK/binary/so reverse engineering | `references/security-report-templates.md` → reverse engineering report |
| Pentest / vulnerability hunting | `references/security-report-templates.md` → penetration test report |
| CTF solve | `references/security-report-templates.md` → CTF Writeup |
| JS/Web signature reverse engineering | `references/security-report-templates.md` → signature reverse engineering report |
| Malware / APT / virus analysis report | `references/security-report-templates.md` + **`references/vendor-report-rules.md`** |
| General technical documentation | `references/templates.md` → README / API docs |

### Vendor report structure (Issue #65)

Formal security reports **MUST** read `references/vendor-report-rules.md` (structure only; do not copy vendor text). Choose a vendor flavor only when the task evidence or the user explicitly requires it; normal reverse engineering and other tasks use `flavor = null`.

| Flavor / Overlay | When to use | Primary reference skeleton |
|------------------|--------|------------|
| `malware` | Explicit malware samples, trojans, white-plus-black, phishing poisoning | Huorong-style: overview → flow → sample analysis → incident response → IOC |
| `apt` | APT / campaigns / groups / multi-stage infection chains / industry targeting | Kaspersky Securelist-style: summary → infection chain → investigation narrative → Interesting findings → technical analysis → detection and mitigation → IOC |
| `flavor = null` | Normal APK/ELF/PE/Mach-O reverse engineering, algorithm/firmware analysis, pentest / CTF / JS signatures | Original task template + Base common elements; no malware/APT-specific sections |
| thin `vuln` | The user explicitly requests vulnerability/patch/CVE technical analysis | overview → impact/reproduction → crash and patch analysis → protection advice (stacked on null, not a third default full-text flavor) |

Principle: **few but precise templates** — only 2 vendor full-text flavors; `vuln` is only an optional thin overlay, no third default full-text template set.
Takes effect **simultaneously** with §0 Evidence→Finding→Path; on conflict, the Evidence contract wins.

### Output specification

- **Output location**: the user's current project directory (not the skill package directory)
- **Filename format**: `YYYY-MM-DD_[type]-[target-abbreviation]-report.md`
- **If the project has a `docs/` directory**: prefer placing output under `docs/`
- **Encoding**: UTF-8
- **Language**: follow the user's conversation language (Chinese conversation → Chinese report, English conversation → English report)

### Quality requirements

- All code blocks must be directly runnable or have clear context
- No placeholders/TODOs
- Key findings must be supported by evidence
- Reproduction steps must let a third party reproduce independently
- Sensitive information (real tokens, passwords, internal URLs) replaced with placeholders
- **MUST** include the Evidence → Finding → Path chain (see `../ops/evidence-finding-path.md` and template §0)
- **MUST** read `references/vendor-report-rules.md`: choose `malware` / `apt` or `flavor = null` (vulnerability tasks may stack thin `vuln`); with no flavor, output only the original task template and applicable Base elements, no forced IOC/ATT&CK
- **SHOULD** reference the case `scope.md` / `timeline.md` (`../scripts/case-init.ps1`)

### Diagram integration

When generating a report, call the `diagram-generator` skill at appropriate points to create diagrams:

| Report type | Suggested diagrams | Diagram types |
|---------|---------|---------|
| Reverse engineering report | function call graph, data flow diagram | Mermaid flowchart / sequenceDiagram |
| Pentest report | attack path diagram, network topology | Mermaid flowchart / Graphviz |
| CTF Writeup | solve-process flowchart | Mermaid flowchart |
| JS signature reverse engineering report | request-chain sequence diagram, algorithm flowchart | Mermaid sequenceDiagram / flowchart |

Embed diagrams in the report markdown as Mermaid code blocks so they render directly on GitHub/GitLab.

---

## Core Principles

### 1. Progressive Disclosure

Reveal information in layers:

| Layer | Content | User Question |
|-------|---------|---------------|
| 1 | One-sentence description | What is it? |
| 2 | Quick start code block | How do I use it? |
| 3 | Full API reference | What are my options? |
| 4 | Architecture deep dive | How does it work? |

**Warnings, breaking changes, and prerequisites go at the TOP.**

### 2. Task-Oriented Writing

```markdown
<!-- Bad: Feature-oriented -->
## AuthService Class
The AuthService class provides authentication methods...

<!-- Good: Task-oriented -->
## Authenticating Users
To authenticate a user, call login() with credentials:
```

### 3. Show, Don't Tell

Every concept needs a concrete example.

## Formatting Standards

- **Sentence case headings**: "Getting started" not "Getting Started"
- **Max 3 heading levels**: Deeper means split the doc
- **Always specify language** in code blocks
- **Relative paths** for internal links
- **Tables** for structured data with 3+ attributes

## Quality Checklist

- [ ] Code examples tested and runnable
- [ ] No placeholder text or TODOs
- [ ] Matches actual code behavior
- [ ] Scannable without reading everything
- [ ] Reader knows what to do next

## Anti-Patterns

| Problem | Fix |
|---------|-----|
| Wall of text | Break up with headings, bullets, code, tables |
| Buried critical info | Warnings/breaking changes at TOP |
| Missing error docs | Always document what can go wrong |

## Templates

For README, API endpoint, and file organization templates, see [references/templates.md](references/templates.md).

## Related Skills

- `Skill(ce:writer)` - Writing style, tone, and voice (load The Engineer persona)
- `Skill(ce:visualizing-with-mermaid)` - Architecture and flow diagrams


---

## On-Demand Bootstrap

This skill depends on no external tools; it's pure text generation. No bootstrap needed.

If diagrams need rendering for embedding in a report, it calls the `diagram-generator/` skill.

---

## Routing context

**Upstream entries**: all security/RE skills automatically call this skill when their task completes
**Trigger modes**:
- Automatic: executed as step 9 of the behavior chain after a task completes
- Manual: the user says "write a report", "generate docs", "writeup"

**Peer modules**:
- `apk-reverse/` — generates a reverse engineering report after APK reverse engineering completes
- `ida-reverse/` — generates a reverse engineering report after binary analysis completes
- `radare2/` — generates a reverse engineering report after CLI analysis completes
- `js-reverse/` — generates a signature report after JS signature reverse engineering completes
- `reverse-engineering/` — generates a reverse engineering report after general reverse engineering completes
- `field-journal/` — the report content also feeds the evolution log as a data source

**Security report templates**: `references/security-report-templates.md`
**Vendor report rules**: `references/vendor-report-rules.md` (flavor: malware | apt | null; optional overlay: vuln)
**General documentation templates**: `references/templates.md`


## Task completion self-check (MUST pass before claiming completion)

- [ ] Did I execute every step of the workflow (not just read it)?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/reports)?
- [ ] Does the report contain Evidence / Finding / Path (the ops contract)?
- [ ] Did I complete and write back the Checklist items required by RULES?
