# Evidence → Finding → Path Evidence Chain

> Inspired by the Z3r0 Evidence Plane, implemented as a **Markdown field contract**.  
> reverse-skill highlights: bound to `docs-generator` report templates, `field-journal` anonymized write-back, and reproducible commands.

## 1. Evidence (Immutable Observation)

Each piece of evidence gets its own block or table row:

```markdown
### E-{nnn}
- title:
- observed_at:
- source_type: command | screenshot | file | log | memory | network | manual
- source_ref: {path or command id}
- content_hash: {sha256 of artifact if file, else n/a}
- artifact_path: {relative path under case root when content_hash is recorded, else n/a}
- repro_command: |
    {exact command}
- raw_excerpt: |
    {de-identified excerpt}
- linked_workitem: WI-{nnn} | n/a
- supersedes: E-{nnn} | none
```

**MUST**: a Finding must reference at least 1 piece of Evidence; the `repro_command` must be runnable by a third party or state its offline limitation.

**CLI helper** (writes `work/<case>/evidence/E-*.md`):

```powershell
powershell -File skills/scripts/append-evidence.ps1 -CaseRoot work/<case> `
  -Id E-001 -Title "..." -ReproCommand "..." -Severity info -Status observed
```

When the evidence is a case-local file, pass `-ArtifactPath` to record a SHA-256 fixity value and a relative artifact path. Review the complete case graph before handoff:

```bash
python3 skills/case-review/scripts/review_case.py work/<case> --verify-hashes --strict
```

The review is read-only and checks scope fields, Evidence records, work item and timeline references, structured Findings, Paths, and artifact hash matches.

## 2. Finding (Security/Reverse-Engineering Conclusion)

```markdown
### F-{nnn}
- title:
- severity: critical | high | medium | low | info | n/a_re
- category: vuln | misconfig | design | reverse_algo | bypass | other
- status: candidate | validated | false_positive | accepted_risk
- evidence_ids: [E-001, E-002]
- location: {file:line | addr | url | class.method}
- impact:
- confidence: high | medium | low
- repro_steps:
  1.
  2.
- remediation: {or n/a for pure RE}
- optional_attack: {ATT&CK ID or empty}
```

**MUST**: `evidence_ids` must be non-empty; when `status=validated`, confidence must not be low (unless a residual risk is noted).

## 3. Path (Attack Path / Call Path / Solve Path)

Uniformly called **Path**, interpreted by task type:

| Task | Path meaning |
|------|-----------|
| Pentest / attack chain | Attack path steps |
| Reverse engineering | Key call/data-flow steps |
| CTF | Solve steps |

```markdown
### P-{nnn}
- title:
- path_type: attack | callflow | solve
- start:
- goal:
- steps:
  1. action: — evidence: E-xxx — finding: F-xxx | none
  2. action: — evidence: E-xxx — finding: F-yyy | none
- residual_risks:
```

**MUST**: every step must be linkable to Evidence; if the endpoint Finding of an attack path claims "obtained privileges/data", it must have validated evidence.

## 4. Position in the Report

A `docs-generator` security report **MUST** contain:

1. Scope summary (linked to the case `scope.md`)  
2. Evidence table or section  
3. Findings list (with evidence_ids)  
4. At least 1 Path (attack/call/solve)  
5. Timeline summary (optionally linking the full text to `timeline.md`)

See the **Evidence Chain** section in `docs-generator/references/security-report-templates.md` for details.

## 5. field-journal Hook

When writing back to the journal **SHOULD** excerpt:

- 3 key Evidence ids + commands  
- 1 core Finding  
- One sentence on the reusable Path pattern  

Full sensitive content belongs only in the user's project report; the journal **MUST** be de-identified (`anonymization.md`).

## 6. Differences from Z3r0 (Highlight)

| Z3r0 | reverse-skill |
|------|----------------|
| PG immutable rows + API | Markdown files + hash fields |
| UI review queue | Report + next-step menu + journal |
| Deep ATT&CK binding | Optional tags, no forced UI |


## Validated sufficiency (Issue #77 / R4*)

Global bind rule remains: every Finding references **>=1** Evidence.

Promotion to status=validated is stricter (decision cookbook):

| status | Evidence bar |
|--------|----------------|
| preliminary / candidate | >=1 (unchanged) |
| **validated** | **SHOULD >=2 independent** Evidence (best: 1 static + 1 dynamic). A single Evidence item alone MUST NOT silently promote to validated — keep candidate/preliminary, or record residual_risk + human confirm. |
| blocked promotion | record Evidence E-insufficient-evidence |

Full recipes: [nalysis-decision-framework.md](analysis-decision-framework.md) (R4*, R1, R41, R44).
