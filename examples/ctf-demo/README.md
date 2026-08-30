# examples/ctf-demo — Full workflow example

> This directory demonstrates the reverse-skill standard operating flow: **routing → authorization gate → timeline → evidence chain → report**.
> The content is a fictional example (CTF lab range), only to show how the workflow operates.

## Flow demonstration

```text
1. User task: "Analyze this CTF pwn challenge, stack overflow via gets"
2. Routing: master-route.ps1 -Hint "CTF pwn stack overflow" → PRIMARY R17 (pwn-chain)
3. Authorization: case-init.ps1 -Hint ... -CaseName ctf-demo -AuthGranted → scope.md
4. Execute: timeline appends + evidence E-001/E-002 + workitems updates
5. Output: report (docs-generator) + sanitized field-journal deposit
```

## Files

| File | Description |
|------|------|
| `scope.md` | Case scope (auth granted / target / network_profile) |
| `timeline.md` | Append-only timeline |
| `workitems.md` | Work items and coverage |
| `evidence/` | Evidence record examples (E-001 reproduction command, E-002 crash output) |
| `report/` | Final report structure example |

## Real usage

```powershell
# Initialize a real case (authorized target)
powershell -NoProfile -ExecutionPolicy Bypass -File skills/scripts/case-init.ps1 `
  -Hint "your task" -CaseName my-case -AuthGranted -TargetUrl "https://target/" `
  -NetworkProfile authorized_target_only

# Append evidence
powershell -File skills/scripts/append-evidence.ps1 -CaseRoot work\my-case `
  -Id E-001 -Title "..." -ReproCommand "..."
```

> Note: real cases belong in `work/<case>/` (gitignored, to prevent leaks); this example directory stays in git for reference.
