# Modern Web Lab Friction → Skill Hardening

> Date: 2026-07-18  
> Scenario: legitimate public lab (PortSwigger-style scanner-eval / OWASP Juice Shop demo)  
> Desensitized: no real business-domain exploit details

## Conclusion (for the next Agent)

**Not fully breaching ≠ the package is invalid.** You must deliver: a surface map, a sink list, the reason for each blocker, Evidence(observed|validated).  
Failures go into the timeline and feed back into the playbook.

## Pitfalls

| Pitfall | Symptom | Fix/Discipline |
|----|------|-----------|
| case-init authorization gets polluted | status becomes a weird string after `-AuthGranted` | Only allow pending/granted/denied/unknown; validate AuthStatus via `PSBoundParameters` |
| lab_only not ready | ready_for_act is false when network=lab_only | lab_only + granted + assets → ready |
| Windows curl `[]` | `bad range in position` | **Must** use `curl.exe --globoff` |
| append-evidence special characters | RawExcerpt containing quotes/XML throws errors | Block indentation + strip control characters |
| Public demo 503 | Juice Shop on Heroku is down | Switch to local Docker or another legitimate lab; don't grind on it |
| DOM XSS false positive | Any innerHTML sink gets reported as validated | Exploitation requires a 200 with a non-numeric body; otherwise observed |
| agent-browser ref stale | click fails | Re-snapshot after the page changes |

## Reusable Patterns

1. Surface → Sink → Chain (see `pentest-tools/references/client-side-lab-playbook.md`)  
2. Stock-style `innerHTML = fetchBody`: prove the sink first, then find a 200 with a non-numeric body  
3. Static rg sink + agent-browser eval as dual evidence  

## Toolchain

- case-init / case-guard / append-evidence / smoke  
- agent-browser (CDP)  
- curl --globoff  

## Environment

- Windows + PowerShell 5.1  
- Docker Desktop daemon may not be ready  
