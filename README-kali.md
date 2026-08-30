# Kali Linux Entry (Short Jump)

> **For details, always defer to [kali/README-kali.md](kali/README-kali.md).**
> This file is only the Kali quick entry at the repository root, to avoid maintaining duplicate content under `kali/`.

## AI: Execute immediately after reading

```text
1. Detect the package root (a directory containing README.md / skills/)
2. Read kali/README-kali.md → then read kali/RULES-kali.md and execute it
3. bash kali/scripts/refresh-tool-index.sh
4. Task routing is shared with Windows: skills/MASTER-ROUTING.md, skills/ops/ (scope gate)
5. Report the setup result to the user
```

## Human: 30-second start

```bash
cd /path/to/reverse-skill
bash kali/scripts/refresh-tool-index.sh
# Full bootstrap / MCP details: kali/README-kali.md
```

## Relationship to the main package

| Content | Location |
|------|------|
| Shared skills / routing / ops | `skills/`, `RULES.md` |
| Kali scripts and manifest | `kali/scripts/` |
| Full Kali documentation | **[kali/README-kali.md](kali/README-kali.md)** |

For general AI onboarding, see [README_AI.md](README_AI.md) (switch to the docs in this directory when Kali is detected).
