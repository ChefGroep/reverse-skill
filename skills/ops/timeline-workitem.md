# Timeline + WorkItem / Coverage

> Replayable operational record (Z3r0 timeline concept) + coverage checklists (WorkItem concept).  
> Everything lives under **`work/<case>/`** (gitignored in the repo), not inside the skill package body.

## Directory Convention

```text
work/<case>/
  scope.md           # contract (ops/scope-contract.md)
  timeline.md        # append-only; editing historical entries is forbidden
  workitems.md       # work items and coverage
  evidence/          # raw artifacts (screenshots, pcap, logs)
  notes/
  report/            # final report draft or copy
```

Initialization:

```powershell
powershell -File skills\scripts\case-init.ps1 -Hint "full pentest" -CaseName "acme-2026"
```

## timeline.md Format

Every record is **append-only**:

```markdown
## {ISO-8601} | {role} | {phase}
- action:
- command_or_ref:
- result_summary:
- artifacts: []      # relative paths under this case
- evidence_ids: []   # E-xxx when promoted
- decision_delta: [] # only decisions changed since the previous transition
- carry_forward_refs: [scope.md] # unchanged authoritative state is referenced, not re-serialized
- next:
```

**MUST NOT** delete or rewrite existing `##` time blocks (use a new entry + `corrects: {timestamp}` for corrections).

### Decision delta boundary

`scope.md`, `workitems.md`, and existing Evidence are the current authoritative state. `timeline.md` records transitions; it does not copy full snapshots.

- Every real stage/turn transition **MUST** write a `decision_delta`; list only the decisions that genuinely changed from the previous state to the current one and that affect subsequent actions. Write `[]` when nothing changed.
- Unchanged route, auth, scope, network profile, tool capability, and existing hypothesis/Evidence **MUST NOT** be re-expanded for handoff; reference the authoritative files or entries in `carry_forward_refs`.
- The consumer **MUST** parse `carry_forward_refs` first, then apply the `decision_delta` onto the working context; the delta must not be treated as the full state.
- A genuine decision boundary exists only when there are two or more materially different, evidence-supported branches whose user choice would change the next action; deterministic transitions continue directly, without restating context just to create a menu.

Representative transition: `Triage -> Static`, if auth/scope/route are unchanged, records only `decision_delta: [phase=triage->static]` and inherits the rest via `carry_forward_refs: [scope.md, evidence/E-triage.md]`.

## workitems.md Template

```markdown
# Work Items

| ID | title | role | targets | surface | status | evidence | notes |
|----|-------|------|---------|---------|--------|----------|-------|
| WI-001 | Port scan edge | cie | {ip} | network | done | E-001 | |
| WI-002 | Auth bypass check | cpe | /api/login | web | blocked | | need creds |

status: pending | in_progress | blocked | done | cancelled

## Coverage
- [ ] Recon complete for in_scope assets
- [ ] Critical/High candidates triaged
- [ ] Validated findings have Evidence
- [ ] Path documented (attack/call/solve)
- [ ] Timeline continuous (no silent gaps >1 major phase)
- [ ] Report exported via docs-generator
- [ ] field-journal written (anonymized)
```

## attack-chain / pentest Hooks

| Skill | MUST |
|-------|------|
| `attack-chain/` | Multi-stage tasks create a case directory; update workitems + timeline at the end of each stage |
| `pentest-tools/` | At least 1 timeline entry after each tool batch run; findings → Evidence drafts |
| Other RE skills | Timeline recommended; complete the Evidence chain at least before producing the report |

## Highlights

- Agent-friendly plain text, diff/review friendly  
- Cross-referenceable with tool-index command paths  
- No WebSocket live-stream dependency; paste the timeline into the report when needed
