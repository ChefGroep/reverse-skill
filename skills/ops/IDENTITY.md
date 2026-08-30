# reverse-skill Identity Declaration (relative to Z3r0)

> This document pins down **who we are**. We absorb Z3r0's evidence/scope/role-division/timeline ideas, but we are **not** a Z3r0 platform.

## We Are

| Dimension | reverse-skill |
|------|----------------|
| Form | **Skill routing package** — methodology + tool bootstrap for any AI client (Claude/Cursor/Codex…) |
| Entry | `RULES.md` → `MASTER-ROUTING` / `master-route.ps1` → sub-skills |
| Tool truth | `tool-index.md` + `bootstrap-manifest.json` (local paths, never guessed) |
| Evolution | `field-journal/` anonymized experience write-back |
| Deliverables | Markdown reports + `work/<case>/` local working directories (gitignored) |
| Deployment | A `git clone` is enough; no mandatory PG/UI/Docker pool |

## We Are Not

| Z3r0 has | reverse-skill **deliberately skips** |
|---------|---------------------------|
| React operations console | ❌ |
| FastAPI control plane + WebSocket sessions | ❌ |
| PostgreSQL evidence store | ❌ |
| LightRAG service | ❌ |
| Docker host pool / noVNC control proxy | ❌ (but we **document** an optional sandbox profile) |
| Multi-agent process runtime | ❌ (only **role→skill mapping + handoff protocol**) |

## What We Learn from Z3r0 (slimmed-down implementation)

| Idea | reverse-skill shape |
|------|-------------------|
| Authorization and case boundary | `ops/scope-contract.md` → per-case `scope.md` |
| Evidence→Finding→Path | `ops/evidence-finding-path.md` + report templates |
| Specialist division of labor | `ops/role-map.md` (Lead/cie/cpe/cre…→ skill) |
| Replayability | `work/<case>/timeline.md` append-only writing |
| WorkItem/coverage | `workitems.md` + coverage checkboxes |
| Sandbox tool parity | `ops/sandbox-profile.md` vs bootstrap-manifest |
| Egress control | `network_profile` field (offline/lab/authorized) |

## Signature Features (must be kept)

1. **Three-axis routing + PRIMARY fast path** (target type / intent / toolchain)  
2. **Bootstrap installs tools on demand**, across Windows/Kali/Linux/macOS  
3. **MCP-friendly** (IDA/Burp/jshook/anything-analyzer)  
4. **Anonymized field-journal evolution**  
5. **Compliance engineering**: ACTION REQUIRED / completion self-check / no fake stops

## Healthy Relationship with Z3r0

```text
Z3r0 = red-team operating system / team collaboration platform
reverse-skill = the agent's security-work router + instruction manual

Optional future: mount this package's skill content into Z3r0 sandbox-local skills
Today: this package works fully with zero dependency on Z3r0
```

## Relationship with "800+ community micro-skills"

- **Do not** submodule a giant skill library (poisoning surface and maintenance cost, see `skill-supply-chain.md`)  
- **Do** maintain `references/community-security-skills.md` as index and borrowing rules  
- **Do** use `domain-coverage-map.md` to prove: deep skills + routing > fragmented skill stacking  
- External skill installation: AST10 mindset + trust curated sources only (e.g. Trail of Bits curated)