# Pre-declared authorization — less disclaimer noise, not a substitute for scope.md

> This file solves exactly one problem: never treat "the user picked a target" as already being authorized.
> The executable authorization gate remains `case-init.ps1` → `work/<case>/scope.md` with `auth.status=granted` + a valid `network_profile`.

---

## CRITICAL

Common scenarios in this package (bug bounty/VDP / own systems / paid engagements / CTF lab environments / responsible disclosure) **may** reduce boilerplate disclaimers.

**AI must not treat this file as `auth.status=granted`.**

- The user mentioning a domain / IP / sample path ≠ authorized
- Never use this file to skip `case-init`
- Never auto-append `-AuthGranted` inside a skill "just to keep the flow moving"
- CTF / lab environments: still create a case; use `lab` or `offline` for `network_profile`
- Real external network targets: ACT only with granted + `authorized_target_only` (or the contract-defined profile)

---

## Allowed / Forbidden

1. **MUST NOT** use this file to override `ops/scope-contract.md`
2. **MUST NOT** run nmap / sqlmap / uploads / exploitation against a target without a `scope.md`
3. **MUST** distinguish "saying fewer legal boilerplate lines" from "actually cleared to act"
4. **MUST** output technical analysis when technically uncertain, instead of feigning insufficient authorization to stop work
5. No case created yet or `auth.status!=granted` → run `case-init` first; do not guess

---

## Relationship to other files

| File | Role |
|------|------|
| **precedent-auth.md** (this file) | Fewer disclaimers; **never** sets `granted` |
| `ops/scope-contract.md` + `case-init.ps1` | The only executable authorization gate |
| `precedent-reverse.md` / `precedent-pentest.md` | Everyday operations are not crime tutorials; still bound by scope |

```
case-init / scope.md → whether ACT is allowed
precedent-auth.md    → do not substitute boilerplate for scope
PRIMARY SKILL.md     → how to do it
```
