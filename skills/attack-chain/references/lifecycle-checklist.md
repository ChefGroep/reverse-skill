# Pentest / Attack Chain Lifecycle Checklist

> Compares community pentest skill packages (e.g. Orizon claude-code-pentest's six stages) with this package's `attack-chain` + `ops` integration.
> Source inspiration: public Claude pentest lifecycle skills (retrieved 2026-07); **commands and authorization follow this package's scope**.
> Date: 2026-07-17

## Before Use

- [ ] `case-init` done, `auth.status=granted`
- [ ] `network_profile` ≠ unrestricted misused against production
- [ ] `lead` has assigned specialist_roles (`ops/role-map.md`)

## Stage Gates

| Stage | Role | This Package's Skill | Completion Standard |
|------|------|------------|----------|
| 0 Scope | lead | ops/scope-contract | ready_for_act |
| 1 Recon | cie | pentest-tools | assets list + timeline |
| 2 Enum/Vuln | cpe | pentest-tools / api-security | candidate F-* drafts |
| 3 Validate | cpe | pentest-tools | E-* + validated Finding |
| 4 Post-ex (if authorized) | cpe/lead | attack-chain second half | never exceeds out_of_scope |
| 5 RE support | cre | ida/apk/js/… | only when clients/binaries are needed |
| 6 Report | doc | docs-generator | Evidence→Finding→Path |
| 7 Journal | lead | field-journal | sanitized |

## Differences from "Fully Automatic Domain Break-In" Style Skills (Our Edge)

| Common in External Automation Packages | reverse-skill |
|------------------|---------------|
| By default hammers the domain with scans | Requires the scoped asset list |
| Weak evidence written straight into reports | Enforces the E/F/P chain |
| Single session, no roles | role-map handoff |
| No tool index | tool-index + bootstrap |

## At Least One Timeline Entry Per Stage

See `ops/timeline-workitem.md` for the format.
