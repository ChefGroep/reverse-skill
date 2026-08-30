# Security/RE/Pentest technical document templates

This file provides document templates for security-class projects: reverse engineering, penetration testing, vulnerability analysis, etc. After a task completes, the AI should create the document in the user's project directory and output it per the corresponding template.

---

## 0. Evidence Chain (all security reports MUST contain)

> Full contract: `skills/ops/evidence-finding-path.md`
> Case directory: `work/<case>/` (`case-init.ps1`)

The report body **MUST** contain the sections below (they may be merged into "key findings" but no fields may be omitted):

### 0.1 Scope summary
- Link to `scope.md`: `auth` / `in_scope` / `network_profile`
- No scope → do not claim the task is complete

### 0.2 Evidence
At least 1, fields: `E-id` / `source_ref` / `repro_command` / `content_hash|n/a`

### 0.3 Findings
Each: `F-id` / `severity|n/a_re` / `evidence_ids` / `confidence` / `location` / `status`

### 0.4 Path
At least 1 `P-id`: `path_type=attack|callflow|solve`; steps may attach E/F

### 0.5 Timeline summary
Link to `timeline.md` or embed the key 3–10 appended records

---

---

## 0.6 Vendor structure overlay (professional vendor report structure)

> Full rules: `references/vendor-report-rules.md` (Issue #65)
> **MUST** read and select when generating formal security reports; **structure only, copying vendor text/IOC instances is forbidden**.

| Flavor / Overlay | Scenario | Skeleton in one sentence |
|------------------|------|------------|
| `malware` | Explicit malware samples/ordinary trojans/white-plus-black | Huorong-style: overview → flow → sample analysis → incident response → IOC |
| `apt` | APT / campaigns / multi-stage chains | Kaspersky-style: summary → infection chain → investigation → Interesting findings → technical analysis → detection and mitigation → IOC |
| `flavor = null` | Normal RE / pentest / CTF / JS signatures | this section's task template + applicable Base common elements |
| thin `vuln` | Vulnerability/patch/CVE technical analysis (explicit) | overview → impact/reproduction → crash and patch analysis → protection advice |

**Common elements (G1–G7) summary**: G1 executive summary MUST · G2 Scope MUST · G3 E/F/P MUST · G4 IOC `malware`/`apt` MUST · G5 recommendations `malware`/`apt`/`vuln` MUST · G6 appendix SHOULD · G7 ATT&CK `apt` MUST

Selection and section order follow `vendor-report-rules.md`; on conflict with §0.1–0.5, the **Evidence contract wins**.

## 1. Reverse engineering report template

```markdown
# [Target name] Reverse Analysis Report

> Analysis date: YYYY-MM-DD
> Analyst: [AI / human]
> Toolchain: [jadx / IDA / radare2 / Frida / ...]

## 1. Target overview

| Property | Value |
|------|---|
| Filename | |
| File type | APK / ELF / PE / Mach-O / ... |
| Size | |
| MD5 | |
| SHA256 | |
| Package name/entry | |

## 2. Analysis goals

<!-- The core questions this reverse analysis must answer -->

## 3. Static analysis

### 3.1 Basic information
<!-- architecture, compiler, protection mechanisms, string signatures -->

### 3.1.1 Import table / dependencies (binary MUST)
<!-- write the E-imports / E-triage-imports summary; record Evidence even on failure, never skip -->

### 3.2 Key functions/classes
<!-- list the key logic located, with code snippets -->

### 3.3 Crypto/signature algorithms
<!-- if crypto is involved, state the algorithm, key source, parameter construction -->

## 4. Dynamic analysis

### 4.1 Hook records
<!-- targets and results of Frida / xposed / other hooks -->

### 4.2 Runtime behavior
<!-- network requests, file operations, process behavior -->

## 5. Key findings

<!-- list key conclusions numbered -->

1. ...
2. ...
3. ...

## 6. Reproduction steps

<!-- let others reproduce your analysis results -->

```bash
# key commands
```

## 7. Open issues

<!-- points not fully resolved -->

## 8. Appendix

<!-- hook scripts, decryption code, screenshots, etc. -->
```

---

---

## 1b. Malware / APT report (vendor flavor)

When the task is malware analysis, a virus report, or APT/campaign analysis, do **not** just hand in the "reverse engineering" skeleton above; normal RE tasks keep the original template and do not automatically select a vendor flavor:

1. Read `vendor-report-rules.md` and choose `malware` or `apt`
2. Output per the corresponding section order
3. It still **MUST** contain the §0 Evidence chain; the `malware` / `apt` flavors additionally **MUST** contain an IOC table
4. Static analysis of binary samples **MUST** contain import-table Evidence (consistent with the radare2/ida/malware hard gates)

## 1c. Vulnerability technical analysis report (thin `vuln` overlay)

When the task is **OS/component vulnerabilities, patch comparison, CVE technical analysis**, or the user explicitly requests a "vulnerability technical analysis report":

1. Read `vendor-report-rules.md` §3b and use the thin `vuln` section order (**not** a malware/apt full-text flavor)
2. **MUST** contain: affected scope, authorized reproduction or explicit n/a, crash/root-cause or patch-diff Evidence, protection/patch advice
3. **MUST** contain §0 Evidence→Finding→Path
4. **MUST NOT** extend PoCs on unauthorized targets, or copy external weaponization details

## 2. Penetration test report template

```markdown
# [Target] Penetration Test Report

> Test date: YYYY-MM-DD
> Test scope: [URL / IP / application name]
> Authorization status: [authorized / CTF / learning environment]

## 1. Executive summary

<!-- one paragraph: what was tested, what was found, risk level -->

## 2. Test scope

| Item | Details |
|------|------|
| Target | |
| Test type | black box / gray box / white box |
| Test time | |
| Tools | |

## 3. Findings summary

| # | Vulnerability name | Risk level | Status |
|---|---------|---------|------|
| 1 | | high/medium/low/info | verified/unconfirmed |

## 4. Vulnerability details

### 4.1 [Vulnerability name]

**Risk level**: high / medium / low

**Description**:

**Impact**:

**Reproduction steps**:

1. ...
2. ...
3. ...

**Evidence**:

```
<!-- request/response/screenshot/payload -->
```

**Remediation advice**:

## 5. Attack path

<!-- if there is a complete attack chain, draw the path -->

```
entry → recon → exploitation → privilege escalation → objective achieved
```

## 6. Tools and environment

| Tool | Version | Purpose |
|------|------|------|
| | | |

## 7. Remediation summary

| Priority | Recommendation |
|--------|------|
| P0 | |
| P1 | |
| P2 | |

## 8. Appendix

<!-- complete payloads, scripts, configuration files, etc. -->
```

---

## 3. CTF Writeup template

```markdown
# [Contest name] - [Challenge name] Writeup

> Category: Web / Reverse / Pwn / Crypto / Misc / Forensics
> Difficulty: Easy / Medium / Hard
> Points: N pts
> Solve time:

## Challenge description

<!-- original challenge text -->

## Solve approach

### Step 1: Recon
<!-- what was observed -->

### Step 2: Vulnerability / foothold
<!-- which key point was found -->

### Step 3: Exploitation
<!-- how it was exploited -->

## Key code/Payload

```python
# exploit code
```

## Flag

```
flag{...}
```

## Pitfalls encountered

<!-- detours taken -->

## Takeaways

<!-- the knowledge points this challenge covers, for later review -->
```

---

## 4. JS/Web signature reverse engineering report template

```markdown
# [Site/application] Signature Parameter Reverse Report

> Analysis date: YYYY-MM-DD
> Target endpoint: [URL]
> Signature field: [field name]

## 1. Target request

```http
POST /api/xxx HTTP/1.1
Host: example.com

param1=xxx&sign=<target field>
```

## 2. Locating process

### 2.1 Breakpoint/Hook approach
<!-- how the signature generation location was found -->

### 2.2 Call stack
<!-- key call chain -->

## 3. Algorithm reconstruction

### 3.1 Algorithm type
<!-- HMAC-SHA256 / AES / custom / ... -->

### 3.2 Parameter construction
<!-- which fields participate in the signature, ordering rules, separators -->

### 3.3 Key source
<!-- hardcoded / returned by an endpoint / timestamp-derived / ... -->

## 4. Local reproduction code

```javascript
// Node.js reproduction
```

## 5. Verification results

<!-- compare signatures generated by the reproduction code with the actual requests -->

## 6. Anti-scraping/risk-control notes

<!-- rate limits, device fingerprints, environment detection, etc. -->
```

---

## 5. Document output specification

### Output location

- Documents default to the **user's current project directory** (not the skill package directory)
- Filename format: `YYYY-MM-DD_[type]-[target-abbreviation]-report.md`
- If the user's project has a `docs/` directory, prefer placing output under `docs/`

### Output timing

The AI automatically calls this skill to generate documents at these points:

1. A reverse engineering task is complete and has produced core conclusions
2. A penetration test is complete and vulnerabilities have been found and verified
3. A CTF challenge is solved and the flag obtained
4. The user explicitly requests "write a report/document"

### Quality requirements

- All code blocks must be directly runnable or have clear context
- No placeholders/TODOs (if a part is genuinely incomplete, mark it "to be completed" and state the reason)
- Key findings must be supported by evidence (command output, screenshot descriptions, code snippets)
- Reproduction steps must let a third party reproduce independently
