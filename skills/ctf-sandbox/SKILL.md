---
name: ctf-sandbox
description: Thin PRIMARY for CTF / AWD / lab-range multi-type orchestration. Hands off to the sidecar CTF-Sandbox-Orchestrator. Use when the user says CTF, AWD, lab range, or competition challenge and no more specific pwn/APK/IDA route already won.
---

# CTF sandbox entry (sidecar, not a second router)

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: run `../scripts/case-init.ps1`; ACT against the real internet is forbidden until `auth.status=granted`. For competitions/lab ranges use `-NetworkProfile lab` or `offline`.
2. `NOW`: open `../../CTF-Sandbox-Orchestrator/ctf-sandbox-orchestrator/SKILL.md` under the package root and continue following its sandbox assumptions.
3. `MUST NOT` write the 40+ `competition-*` sub-skills into `routing.json`. This entry is only a single PRIMARY gate.
4. `ACT`: the orchestrator picks one downstream `competition-*`. When the challenge type is already clear (pwn/ROP, APK, IDA), a more specific `routing.json` rule should already have won; do not compete with it.

## Why a separate layer

`CTF-Sandbox-Orchestrator/` is a **GPL sidecar package**; authorization defaults to inside the sandbox. The core routing package remains MIT + the `scope.md` gate. This skill is only a keyword entry point and does not merge the competition tree into the core.

## Task completion self-check (MUST pass before claiming completion)

- [ ] Did I run case-init / scope first, instead of treating "the user said CTF" as authorization for the real internet?
- [ ] Did I open the sidecar orchestrator, instead of treating the 40 sub-skills as PRIMARY?
- [ ] If the task is actually pwn/APK/IDA, did I let the more specific PRIMARY take over?
