# [Date] [Project Short Name]

## Scenario Category
<!-- APK reverse engineering / JS signature / binary analysis / pentest / CTF / traffic-capture analysis / other -->

## Target Overview
<!-- One sentence on what is being done -->

## Scope Summary (De-identified)
<!-- auth.basis / network_profile.mode / in_scope asset types (do not write real domains/IPs) -->
- auth_basis:
- network_profile:
- asset_types: []

## Roles
<!-- lead / cie / cpe / cre / … see skills/ops/role-map.md -->
- lead_role: lead
- specialists: []

## Complete Execution Chain
<!-- The complete steps from receiving the target to producing the result, including dead ends -->

1. ...
2. ...
3. ...

## Evidence Chain Summary (De-identified)
<!-- At most 3: E-id + command pattern + conclusion type; full evidence lives in the user project -->
<!-- Fields align with the skills/case-review/scripts/review_case.py contract (see notes below) -->
| E-id | severity | status | source_type | Reusable command pattern | Linked Finding |
|------|----------|--------|-------------|----------------|--------------|
| E-001 | info | observed | command | `checksec --file=./pwn1` | F-001 |
| E-002 | high | validated | command | `python3 exploit.py REMOTE` | F-001 |

> **Contract alignment (review_case.py)**: if this case produced a standalone evidence directory (`evidence/E-xxx.md`),
> each evidence item must satisfy the field contract of `skills/case-review/scripts/review_case.py`, otherwise `--strict` validation will FAIL:
>
> - Title: `### E-xxx` (must match the filename, e.g. `E-001.md` → `### E-001`)
> - `- severity:` ∈ critical / high / medium / low / info / n/a
> - `- status:` ∈ observed / candidate / validated / false_positive / accepted_risk
> - `- repro_command:` required (offline scenarios may note offline in the notes field for an exemption)
> - `- content_hash:` sha256 or n/a; when filled with sha256, include `- artifact_path:` (case-relative path)
> - `- linked_workitem:` optional; a WI-xxx must really exist
>
> Self-check: `python skills/case-review/scripts/review_case.py <case_root> --verify-hashes --strict`

## Finding / Path Summary
- top_finding:
- path_type: attack | callflow | solve
- path_one_liner:

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| ... | ... | ... | ... |

## Toolchain Findings
<!-- Which tools were used, which worked well, which had pitfalls, version compatibility issues -->

## Key Code/Commands

```
<!-- Paste the key commands, hook scripts, and decryption logic actually used -->
```

## Improvement Suggestions for This Package
<!-- Was routing accurate? Is bootstrap missing anything? Do docs need additions? Do new tools need to join the manifest? -->

## Reusable Patterns/Script Snippets
<!-- If this produced reusable hook scripts, decryption logic, or bypass solutions, paste them here -->

## Evolution Actions
<!-- Which updates were actually executed during this write-back -->
- [ ] Updated the routing matrix
- [ ] Updated tool-index
- [ ] Updated bootstrap-manifest
- [ ] Updated sub-skill docs
- [ ] Added a pitfalls record
- [ ] No update needed

## Environment Info
<!-- Record the key environment of the moment -->
- OS:
- Tool versions:
- Target platform/version:

## De-identification Requirement

> **This file may be synced with the repo to a remote and must be de-identified. For the full specification see [`anonymization.md`](anonymization.md) (placeholder table + automatic detection script).**

- Target domains/IPs: replace with `{target_domain}` / `{target_ip}` (see `anonymization.md` for details)
- Real URL paths: keep the structure, replace the domain
- Tokens/Cookies/passwords/JWTs/API keys: use `{token}` / `{password}` / `{api_key}` placeholders
- Usernames/phone numbers/emails: use `{username}` / `{phone}` / `{user_email}` placeholders
- Internal IPs/ports: keep the first two octets of internal IP ranges (`10.0.x.x`)
- Vulnerability payloads: technical content may be kept, but replace target-specific parameters (e.g. `?id={user_id}`)

Before submitting, run a regex scan against the **Field-Journal mandatory checklist** at the end of `anonymization.md`.

If this is a private repo and you confirm it will not be made public, the above restrictions may be relaxed, but de-identification is still recommended.

## Index Synchronization (Last Step Before Submitting)

After writing this log, `_index.md` must be synchronized:

1. Add a line in the matching scenario section under "By Scenario" (with date and keywords)
2. Append this filename under the matching technique in "High-Frequency Success Patterns (By Technique)"
3. Append this filename under the matching entity in "Entity Inverted Index (By Target Characteristics)"
4. Update the totals in "Cumulative Statistics" and the "Last updated" date

---
<!-- [Evolution stats] Packages completed projects to date: N | New patterns this time: X | Toolchain issues fixed this time: Y -->
<!-- [Community contribution] After finishing, ask the user whether to PR to the main repo. See CONTRIBUTE-BACK.md for the flow -->
