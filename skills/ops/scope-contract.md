# Generic Scope Contract (Hard Gate at Task Start)

> **MUST**: any security/reverse-engineering/pentest task must, **before ACT**, land a `scope.md` in the current analysis project's `work/<case>/` directory.
> Without a scope → only document reading/routing is allowed; active scanning, hooking, or exploitation of the target is **forbidden**.
> The template may be copied; keep field names as English keys so scripts can validate them.

## How to Initialize

Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File skills\scripts\case-init.ps1 -Hint "<one-line task description>" -CaseName "my-case"
# Default output: the current analysis project's work/<case>/scope.md etc.
# When invoking the skill from another directory, specify explicitly: -ProjectRoot "C:\path\to\analysis-project"

# Legitimate local offline sample: auth granted + offline + explicit sample → ready_for_act=true
powershell -NoProfile -ExecutionPolicy Bypass -File skills\scripts\case-init.ps1 `
  -Hint "offline apk" -CaseName "my-sample" -Preset offline-sample -Sample ".\app.apk"
```

Linux / macOS / Kali:

```bash
bash skills/scripts/case-init.sh --hint "<one-line task description>" --case-name "my-case"
# Default output: the caller's analysis project's work/<case>/scope.md etc.
# When called from another directory, specify explicitly: --project-root "/path/to/analysis-project"

# Legitimate local offline sample
bash skills/scripts/case-init.sh \
  --hint "offline apk" --case-name "my-sample" \
  --preset offline-sample --sample ./app.apk
```

`-PackageRoot` / `--package-root` remain as compatibility parameters; the new flow should use `ProjectRoot` / `--project-root` to denote the project that owns the case artifacts.

## Full scope.md Template

```markdown
# Case Scope

## meta
- case_id: {YYYYMMDD-short}
- created: {ISO-8601}
- operator: {name or local}
- project_root: {caller analysis project}
- primary_skill: {from master-route}
- lead_role: lead   # see ops/role-map.md
- specialist_roles: []  # e.g. cie, cpe, cre

## auth
- status: granted | pending | denied
- basis: written_contract | bug_bounty_scope | ctf_public | own_system | lab_only
- evidence_of_auth: {ticket/path or "CTF public" or "owner-operated"}
- MUST NOT proceed if status != granted

## in_scope
- assets: []          # hosts, domains, APK paths, binaries, URLs
- surfaces: []        # web, mobile, binary, network, api
- activities: []      # recon, reverse, exploit_validate, report

## out_of_scope
- assets: []
- activities: []      # e.g. DoS, phishing real users, data exfil

## network_profile
- mode: offline | lab_only | authorized_target_only | unrestricted_lab
- notes: |
    offline = no outbound packets (pure static/local samples)
    lab_only = lab/VM IP ranges only
    authorized_target_only = in_scope assets only
- MUST NOT use unrestricted against production without written auth

## deliverables
- report: true
- field_journal: true
- diagrams: true
- timeline: true

## constraints
- timebox: {}
- stealth: low | medium | high
- data_handling: anonymize | no_user_pii

## signoff
- ready_for_act: false
- checklist:
  - [ ] auth.status = granted
  - [ ] in_scope.assets non-empty OR offline sample path set
  - [ ] network_profile.mode chosen
  - [ ] out_of_scope reviewed
```

## Routing Hook (AI Must Execute)

```text
RULES / MASTER-ROUTING / SKILL:
  1) master-route → PRIMARY
  2) Platform-native case-init or a hand-written scope.md
  3) auth not granted → STOP; only authorization material may be added
  4) ready_for_act = true → open the PRIMARY SKILL.md → ACT
```

`case-guard -Force` / `case-guard --force` are compatibility parameters and **must not** bypass the `auth.status`, valid scope, network profile, or `ready_for_act` hard gates.

## network_profile Quick Reference

| mode | Allowed | Forbidden |
|------|------|------|
| `offline` | Static analysis, local files, emulation | Arbitrary outbound connections, public RPC |
| `lab_only` | Lab/CTF target network ranges | Production/unauthorized IPs |
| `authorized_target_only` | in_scope list | Assets outside the list |
| `unrestricted_lab` | Isolated lab network (with written authorization) | Internet production |

## Highlights

- Pure Markdown, **no database**
- Orthogonal to `tool-index` / bootstrap: the scope governs "whether you may strike", the tool-index governs "what you strike with"
