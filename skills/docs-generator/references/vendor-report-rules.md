# Vendor Report Rules (professional vendor report structure overlay)

> Issue #65 question 2.
> **Extract structure and writing rules only; copying any vendor report body, charts, real IOC instances, or large verbatim passages is forbidden.**
> This file is an **overlay**: it does not replace the task templates in `security-report-templates.md` and does not weaken §0 Evidence→Finding→Path.

Structure references (public samples, skeleton only):

| Flavor | Primary reference | Scenario |
|--------|--------|------|
| `malware` | Huorong Security virus/technical analysis reports | Explicit ordinary trojans, white-plus-black, phishing poisoning, malware samples |
| `apt` | Kaspersky Securelist / APT campaign reports (e.g. MATA) | APT, group campaigns, multi-stage infection chains, industry targeting |

Principle: **few but precise templates** — only 2 vendor full-text flavors (`malware` / `apt`) + Base common elements + an **optional thin overlay** (e.g. `vuln` vulnerability technical analysis). Normal RE, pentest, CTF, and JS reports keep their task templates and are not dressed up as malware reports by default; `vuln` is **not** a third default full-text flavor.

---

## 0. When to enable

When `docs-generator` generates a **security-class** report (RE / malware / pentest wrap-up / the user explicitly requests a "professional report" or "vendor style"), it **MUST** read this file. Choose a vendor flavor only when the task evidence or the user explicitly requires it; otherwise use `flavor = null`, stacking only the common professional elements and the original task template.

| Signal | Flavor / Overlay |
|------|------------------|
| APT / group / campaign / multi-stage C2 / industry targeting / ICS / spear-phish campaigns | `apt` |
| Explicit malware samples, trojans, info-stealers, white-plus-black, spoofed sites | `malware` |
| The user explicitly requests vulnerability/patch/CVE technical analysis, or the task evidence is OS/component vulnerability research | `flavor = null` + **thin overlay `vuln`** (see §3b) |
| Normal APK/ELF/PE/Mach-O reverse engineering, algorithm analysis, firmware analysis, pentest, CTF, JS signatures | `flavor = null`; use the original task template and a minimal set of common professional elements |

When the user explicitly specifies "Kaspersky/APT style", "Huorong/virus report style", or "vulnerability technical analysis style", that overrides automatic selection.
**Forbidden**: defaulting normal malware/APT/normal RE into the `vuln` overlay.

---

## 1. Common professional elements (Base)

Apply the Base elements below by report type. **MUST** items are not omissible; flavor-specific elements must not appear in irrelevant tasks just to fill the template. When nothing applies, use `n/a` and state the reason.

| # | Element | Requirement |
|---|------|------|
| G1 | Executive summary / overview | **MUST**: 3–8 sentences: what was analyzed, the most severe conclusion, blast radius, recommended actions |
| G2 | Scope and authorization | **MUST**: link to the case `scope.md` (see template §0.1) |
| G3 | Evidence→Finding→Path | **MUST**: see `security-report-templates.md` §0 and `skills/ops/evidence-finding-path.md` |
| G4 | IOC table | `malware` / `apt` **MUST**; other tasks only when relevant indicators exist |
| G5 | Recommendations / response | `malware` / `apt` **MUST**: at least 1 actionable recommendation; other tasks follow the original task template |
| G6 | Appendix metadata | **SHOULD**: tools and versions, sample hashes, full reproduction commands |
| G7 | ATT&CK mapping | **MUST** (under `apt`; use `n/a` + reason when no applicable technique exists); other tasks **SHOULD** |

### 1.1 IOC table minimal columns

```markdown
| Type | Value | Context | First/last seen | Source evidence | Confidence |
|------|----|--------|---------------|----------|--------|
| file_sha256 / file_md5 / domain / ip:port / url / mutex / path / registry | … | where found | YYYY-MM-DD / n/a | E-id | high/med/low |
```

### 1.2 Copyright and safety boundaries

- Do not paste vendor PDF/web-page body paragraphs or captions as your own analysis.
- Use placeholders for real tokens, internal URLs, and customer identifiers.
- For unauthorized targets, do not output directly exploitable attack-step details (follow case scope / RULES).

---

## 2. Flavor: `malware` (Huorong style · explicit selection)

**Narrative goal**: let the reader understand within 5 minutes "what it is → how it got in → what the sample does → how to respond → which IOCs".

### 2.1 Recommended section order

```markdown
# [Title: one-sentence threat characterization]

> Analysis date / analyst / sample identifier (hash)

## 1. Overview
(G1: discovery channel, disguise techniques, core technical points, whether products detect it — write n/a if unknown)

## 2. Attack / infection flow
(flowchart: Mermaid or step list; corresponds to Path `path_type=attack`)

## 3. Sample analysis
### 3.1 Sample provenance
### 3.2 Static analysis
(**MUST** include import-table / basic-identity Evidence: E-imports or equivalent; see the radare2/ida/malware hard gates)
### 3.3 Dynamic analysis / behavior
(n/a + reason if dynamic conditions are unavailable)
### 3.4 Key findings (Findings table or numbered list, carrying evidence_ids)

## 4. Incident response
(execute only within the authorized scope: confirm scope and preserve evidence first — sample, memory, process tree, network connections, logs — then isolate the host; only after approval by the responsible owner, terminate processes, quarantine/clean files, check hosts/startup items, run a full scan, and re-verify. Never delete files before evidence preservation.)

## 5. Summary notes
(risk reminders and prevention for ordinary users/ops)

## 6. IOC information
(G4 table)

## 7. Evidence chain summary
(§0: E / F / P / Timeline; may be merged with §3.4 but no fields omitted)

## 8. Appendix
(tool versions, reproduction commands, script paths)
```

### 2.2 Style

- Default to Chinese for Chinese users; conclusions first, details after.
- Layer static analysis by "component/stage"; avoid pasting unstructured long logs.
- Response steps must be independently executable; no "raise security awareness" filler.

---

## 3. Flavor: `apt` (Kaspersky Securelist style)

**Narrative goal**: tell the campaign-level story clearly — who struck whom, with which chain, when; how the investigation progressed; how components divide the work; what defenders can use to detect it.

### 3.1 Recommended section order

```markdown
# [Campaign/cluster name]: [one-sentence impact]

> Date / team / industry and regional scope (if known)

## 1. Executive summary
(G1: time window, victim profile, entry point, family/cluster attribution, duration, most important conclusion)

## 2. The infection chain
(by stage: delivery → exploit/loader → main trojan → post-exploitation/theft; mark unknown stages explicitly as "limited visibility"
corresponding Path; a chain diagram recommended)

## 3. Incident investigation
(investigation narrative: key turns, internal proxy/C2 signatures, how the scope was widened; attach Timeline)

## 4. Interesting findings
(3–7 non-obvious points, each carrying an E-id / F-id where possible)

## 5. Technical analysis
### 5.1 Component overview table (loader / trojan / stealer / …)
### 5.2 Per-component behavior and configuration
### 5.3 Static essentials (including import-table/packing/persistence Evidence)
### 5.4 Network and C2
(ATT&CK table G7 may be attached)

## 6. Detection and mitigation
(detection ideas / hunting leads / mitigation priorities; no empty slogans)

## 7. IOC
(G4; grouped by type)

## 8. Evidence chain summary
(§0 fields)

## 9. Appendix
(sample list and hashes, tool versions, public reference IDs; do not copy external report text)
```

### 3.2 Style

- Write the timeline and "visibility limits" honestly.
- Interesting findings ≠ restating the overview; write the anomalies that really mattered during the investigation.
- Use tables for component analysis: role / persistence / C2 / dependencies, then expand.

---


## 3b. Thin overlay: `vuln` (vulnerability technical analysis · optional)

> Issue #65 addendum. The structure references public "OS/component vulnerability technical analysis" report tables of contents; **extract the section skeleton only**; copying PoC packets, exploitation details, or unauthorized attack steps from screenshots/text is forbidden.
> It is **not** a third default vendor full-text flavor; stack it only on vulnerability research tasks or when the user explicitly requests it.

**Narrative goal**: the reader can quickly see "who is affected → how to confirm/reproduce (within authorization) → root cause and patch diff → how to mitigate".

### Recommended section order

```markdown
## 1. Vulnerability overview
### 1.1 Affected scope (versions/components/configuration prerequisites)
### 1.2 Vulnerability reproduction (authorized environment; steps a third party can repeat; no weaponization-tutorial tone)

## 2. Vulnerability analysis
### 2.1 Crash / anomaly analysis (Evidence: crash logs, trigger conditions)
### 2.2 Patch analysis (diff/guard conditions/fix points — attach E-*)
### 2.3 PoC or trigger analysis (only material already within the authorized scope; explaining at the protocol/input-construction level suffices)

## 3. Protection recommendations
### 3.1 Mitigations (configuration/mitigation switches, etc.)
### 3.2 Official patch and verification

## 4. Evidence → Finding → Path (may be merged into the sections above or a separate table)
```

### Hard constraints

- **MUST** scope/authorization: reproduction and PoC extensions are forbidden on unauthorized targets
- **MUST** E/F/P: reproduction, crash, and patch conclusions all carry evidence_ids
- **MUST NOT** treat `vuln` as the default shell for malware/APT
- **MUST NOT** copy exploitation code or complete weaponization steps from external reports/screenshots
- IOC table: only when network/file indicators exist; otherwise n/a or omit

---
## 4. Hooking into the existing task templates

| Task template (`security-report-templates.md`) | Overlay |
|------------------------------------------|----------|
| 1. Reverse engineering report | default `flavor = null`, keep the original "static/dynamic/reproduction" skeleton and hard-gate Evidence such as the import table; apply §2 only for explicit malware samples |
| 2. Pentest report | `flavor = null`; add the applicable G1–G3 from Base, align attack paths with §0 Path, do not force IOC |
| 3. CTF Writeup | `flavor = null`; keep the original challenge, solve narrative, and reproduction structure, do not force IOC/ATT&CK |
| 4. JS/Web signature reverse engineering | `flavor = null`; use the original overview → locate → algorithm → reproduction skeleton, no malware shell |
| Malware / APT specials | explicitly choose the `malware` or `apt` full-text skeleton |

**Conflict resolution**: §0 Evidence chain fields and the scope gate **always win**; flavor only changes narrative order and the professional dressing and may not remove E/F/P.

---

## 5. Selection pseudocode

```
if user_requests_kaspersky or apt or threat_campaign:
    flavor = apt
elif user_requests_huorong or vir_report or explicit_malware:
    flavor = malware
else:
    flavor = null  # original task template + applicable Base elements
overlay = null
if user_requests_vuln_tech_report or cve_patch_analysis:
    overlay = vuln  # thin only; never a third default full flavor
emit(base_report)
if flavor in (malware, apt):
    emit(report with flavor outline)
elif overlay == vuln:
    emit(report with vuln thin outline)
```

---

## 6. Completion checklist (self-check at the end of report writing)

- [ ] A flavor was chosen or an explicit "task template + minimal set"
- [ ] G1 overview exists and is not filler
- [ ] §0 E/F/P fields complete
- [ ] `malware` / `apt` reports have an IOC table (or n/a + reason)
- [ ] `malware` / `apt` reports have actionable recommendations/response
- [ ] Flavorless tasks were not fitted with malware/APT-specific sections
- [ ] vuln enabled only on vulnerability tasks; contains the overview/analysis/protection skeleton and E/F/P; no unauthorized PoC weaponization
- [ ] No vendor text pasted, no placeholders/TODOs
- [ ] Hard-gate Evidence such as the import table entered the static/technical analysis (if binary analysis was performed this task)

---

## 7. Source registry

- Kaspersky Securelist, "Updated MATA attacks industrial companies in Eastern Europe": <https://securelist.com/updated-mata-attacks-industrial-companies-in-eastern-europe/110829> (structure reference; access date: 2026-08-11)
- Huorong Security public technical articles entry point: <https://www.huorong.cn/> (site entry; access date: 2026-08-11. The actual article URL, title, and access date should be registered at the time of actual citation)
- ATT&CK technique IDs serve only as normalized mapping and must be supported by this task's Evidence; do not auto-import IOCs from external reports into the current one.

---

## 8. Non-goals

- No additional full-text templates maintained for Mandiant/CrowdStrike/QiAnXin etc. (the dual flavors + optional thin overlay already cover common needs).
- No upgrading `vuln` into a default full-text flavor alongside malware/apt.
- No automatic crawling of vendor sites to fill reports.
- No lowering of the Evidence contract or the authorized scope because of a flavor.
