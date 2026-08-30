# 2026-08-08 Client-Neutral Structured Routing PR Integration

## Scenario Classification

Code audit / toolchain maintenance / multi-platform routing

## Target Overview

Run incremental value review across multiple high-conflict PRs, and refactor the valuable parts into a client-neutral core before integration.

## Scope Summary (sanitized)

- auth_basis: repository_owner_authorized
- network_profile: authorized_upstream_only
- asset_types: [source_repository, pull_request_refs, local_tests]

## Roles

- lead_role: lead
- specialists: [cae, doc]

## Full Execution Chain

1. Fetch PR refs from remote and compare each PR against the current main line in an isolated worktree.
2. Judge by incremental value first, then keep source relationships with the merge parent, and resolve conflicts semantically.
3. Decouple structured routing from client integration, using JSON as the single source of truth for PowerShell/Bash.
4. For large PRs take only the authorization gate and Bash parity, excluding client-specific and generated assets.
5. Run the full routing, structure gate, language unit tests, syntax, and manifest checks.

## Evidence Chain Summary (sanitized)

| E-id | source_type | Reusable command pattern | Related Finding |
|------|-------------|----------------|--------------|
| E-001 | git diff | `git diff <main>...<pr-ref>` | F-001 |
| E-002 | regression | `test-routing.ps1` + coherence + smoke | F-001 |
| E-003 | unit tests | Python unittest + Node test + Bash parity | F-002 |

## Finding / Path Summary

- top_finding: Client integration is not the core value of structured routing; a single source of truth and automated gates are.
- path_type: callflow
- path_one_liner: any host → optional adapters → routing.json → cross-platform router → unified regression gate

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Large PR mixes client manifest, GIFs, scripts, and docs at once | Concerns not split | Merge only the minimal cross-platform subset | medium |
| Bash router and PowerShell each hardcode separately | Two sources of truth always drift | Bash reads the same JSON through Python | medium |
| New pin gate fails on first run | Kali manifest keeps a floating source | Pin the manifest and make the actual install command use the pin | medium |
| Gradle wrapper download breaks on TLS | External network handshake anomaly | Record and retry in the final verification | low |
| Bash CaseName can write outside the work root | Selective merge missed the path constraints PowerShell already had | Add cross-platform equivalent validation and negative CI | medium |
| Authorized URL is labeled offline | Bash defaults not aligned with PowerShell | Network targets default authorized_target_only; offline only for local samples | low |
| INDEX passes on the dev machine, fails on a clean clone | The generator scanned gitignored local private modules | Enumerate only Git-tracked SKILL.md | medium |

## Toolchain Findings

Git merge parents preserve PR source relationships while allowing semantic deletion inside the merge commit. Supply-chain gates only work when manifest metadata and the actual install command are pinned together.

## Key Code/Commands

```text
git merge --no-ff --no-commit <pr-ref>
powershell -File skills/scripts/test-routing.ps1
powershell -File skills/scripts/verify-routing-coherence.ps1
bash skills/scripts/master-route.sh --hint "case review evidence graph"
```

## Improvement Suggestions for This Package

All client adapters go behind an independent boundary; never write client configuration into the core routing PR. Large PRs must be split by core, adapters, demo assets, and docs.

## Reusable Patterns/Script Snippets

Structured routing parity tests must cover at least ordinary routes, conflict-priority routes, and the newest added routes, preventing a lagging platform entrypoint.

Run a new/old A/B against the same 163-item baseline: the old hardcoded implementation scores 137/163 (84.05%), the structured implementation 163/163 (100%). Only this same-input quantified comparison proves the refactor is a substantive improvement rather than file-count growth.

## Evolution Actions

- [x] Updated routing matrix
- [ ] Updated tool-index
- [x] Updated bootstrap-manifest
- [x] Updated sub-skill docs
- [x] Added pitfalls record
- [ ] No update needed

## Environment Info

- OS: Windows (primary verification) + Linux CI definitions
- Tool versions: Git / PowerShell / Python 3 / Node.js / Bash
- Target platform/version: client-neutral repository core

## Sanitization Requirements

This entry contains no real targets, credentials, internal addresses, or personal identity information.

---
<!-- [Community contribution] Push to main prepared per repository owner instruction. -->
