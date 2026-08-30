# reverse-skill × DSH Ops Koppeling

Geïnstalleerd: 2026-08-29 door Joep Agent op chef-platform-aws-01.
Volledig geüpgraded: 2026-08-29 (tuning-rondes: NL-routing, 3 nieuwe skills, volledige tool-stack, osint-nl-red-koppeling).

## Wat is geïnstalleerd

- **Repo**: https://github.com/zhaoxuya520/reverse-skill.git → `/home/chef/Redteam/`
- **Versie**: v1.0.1 (VERSION file), sync met origin/main
- **Lokale branch**: `chefgroep-tuning` (upstream-wijzigingen blijven merge-baar)
- **46 skills** met SKILL.md frontmatter (43 upstream + 3 ChefGroep-eigen)
- **Routing**: 46 regels in `skills/config/routing.json`, **228 benchmark cases, 228/228 PASS**
- **Regression suites**: test-routing.sh, test-bootstrap-manifest.sh, test-bash-workflow.sh,
  test-client-neutral-bootstrap.sh — allemaal groen

## ChefGroep-eigen toevoegingen (2026-08-29)

| Nieuw | Route | Dekking |
|---|---|---|
| `linux-privesc` | R42 | SUID/sudo/GTFOBins/capabilities/cron/kernel/container-escape |
| `stego-analysis` | R43 | LSB/JPEG-DCT/spectrogram/whitespace/binwalk-extractie |
| `crypto-puzzle` | R45 | RSA-attacks/XOR/length-extension/padding-oracle/JWT-brute |

Alle drie: scope-gate bovenaan (auth=granted vóór ACT op levende systemen),
evidence-finding-path verwijzing, tool-verificatie via tool-index (geen pad-gokken).

## NL-routing (keyword-aliases in routing.json)

Deze NL-hints routeren nu correct (was: R0-fallback):

- "sql injectie", "wachtwoorden kraken", "poort scan", "kwetsbaarheden scannen",
  "penetratietest" → R11 pentest-tools
- "aanvalsketen van buiten naar domeincontroller" → R10 attack-chain
- "forensisch onderzoek" → R25 digital-forensics
- "javascript reverse" → R3 js-reverse
- "DNS tunneling" / "verkeersanalyse" → R21 protocol-reverse
- "rechten verhogen" → R42 linux-privesc
- "steganografie" → R43

Negatieve test bewaakt: "windows privilege escalation" blijft R11 (niet R42).

## Tool-stack (alles geverifieerd in login-shell)

| Tool | Versie | Pad | Bron |
|---|---|---|---|
| jadx | 1.5.6 | ~/tools/jadx/bin | bootstrap (sha-pinned) |
| apktool | 3.0.2 | ~/tools/apktool | bootstrap (sha-pinned) |
| Ghidra | 12.1.3 | ~/tools/ghidra (analyzeHeadless in support/) | bootstrap (API-digest) |
| radare2 + rabin2 | 5.5.0 | /usr/bin | apt |
| frida / frida-ps | 14.10.4 | ~/.local/bin | bootstrap via pipx (pinned) |
| pwntools | 4.15.0 | ~/.local/bin (pwn) | bootstrap via pipx (pinned) |
| semgrep | 1.175.0 | ~/.local/bin | pipx |
| volatility3 | 2.28.0 | ~/.local/bin (vol) | pipx |
| impacket | 0.13.1 | ~/.local/bin (secretsdump.py e.d.) | pipx |
| nmap, adb, yara, binwalk, sqlmap, hashcat, john, graphviz, plantuml, steghide | — | /usr/bin | apt |
| ffuf, nuclei, subfinder, dnsx, katana, httpx | — | ~/.local/bin | bestaand (R24) |
| SecLists | — | /usr/share/seclists + $SECLISTS_PATH | bestaand |

PATH permanent: `/etc/profile.d/chef-tools.sh` + `~/.bashrc` (redundant) —
`/home/chef/tools/jadx/bin:/home/chef/tools/apktool:/home/chef/tools/ghidra/support` toegevoegd.
Verify altijd met `bash -lc 'command -v <tool>'`.

## PEP 668 / pipx-noot (Ubuntu 24.04)

`bootstrap-reverse.sh` pinnt `pipx==1.16.5`; apt levert alleen 1.4.3 en
`pip install --user` weigert op externally-managed Python. Fix die de
manifest-route heel laat:

```bash
python3 -m pip install --user --break-system-packages --upgrade pipx==1.16.5
bash skills/scripts/bootstrap-reverse.sh frida frida-ps pwntools --skip-refresh
```

## Bewust NIET geïnstalleerd / niet geregistreerd

- **idapro / idalib-mcp / jeb-pro / reqable-mcp / burpsuite-mcp**: Windows-GUI of
  commercieel; headless writer heeft hier niets aan (Burp-gat is gedekt door
  `burp-mcp-full` bridge + pentest-headless-stack skill).
- **xquik-mcp / jshookmcp / anything-analyzer / pentestswarm**: MCP-registraties
  (OAuth/API-key nodig) — bewust niet geregistreerd in DSH; later per case te
  activeren via `--mcp-host`.
- **bkcrack**: manifest-asset is win64-only; Linux-binary later handmatig uit
  dezelfde pinned release als nodig.

## DSH Skill-Discovery Koppeling

`joep-agent` preset (agent.cordis.yml) — customSkillDirs:

```yaml
customSkillDirs:
  - /home/chef/.dsh/.agent-presets/joep-agent/skills
  - /home/chef/.agents/skills
  - /home/chef/Redteam/skills          # ← reverse-skill (46 skills)
```

**osint-nl-red preset** (sinds 2026-08-29 ook):

```yaml
customSkillDirs:
  - /home/chef/.dsh/skills
  - /home/chef/Redteam/skills          # ← toegevoegd: red-team sessies volledig bewapend
```

Default roots (~/.dsh/skills, ~/.agents/skills) blijven actief. DSH scant elke
customSkillDir op depth-1 subdirectories met SKILL.md. Nieuwe sessies zien alle
46 skills automatisch; in deze sessie zijn de 3 nieuwe direct live opgepakt.

Niet door DSH ontdekt (en geen probleem): depth-0 master router
`skills/SKILL.md` (via master-route.sh bereikbaar) en depth-2 geneste
sub-skills (`reverse-engineering/dsl-vm-reverse/`, `pentest-tools/src-hunter/`).

## Routing gebruiken

```bash
cd /home/chef/Redteam
bash skills/scripts/master-route.sh --hint "linux privilege escalation suid"   # → R42
bash skills/scripts/master-route.sh --hint "steganografie in png"               # → R43
bash skills/scripts/master-route.sh --hint "ctf crypto rsa"                     # → R45
```

## Tools bootstrap (manifest-capabilities only)

```bash
bash skills/scripts/bootstrap-reverse.sh <capability> --skip-refresh   # geen MCP-registratie
bash skills/scripts/bootstrap-reverse.sh --list                        # 24 capabilities
```

## Case initialisatie (scope.md gate — hard)

```bash
bash skills/scripts/case-init.sh --hint "authorized pentest target X"
```

Zonder `auth.status=granted` + `network_profile` (of offline-sample preset) is
ACT verboden; `case-guard --force` omzeilt deze gate niet.

## Wijzigingen in deze repo doorvoeren (workflow)

1. Route-wijziging: alleen `skills/config/routing.json` + benchmark-case in
   `skills/tests/routing-benchmark.json` + prioriteitsrij in
   `skills/MASTER-ROUTING.md` (die drie blijven 1:1 in sync).
2. Daarna: `bash skills/scripts/test-routing.sh` moet 228/228 blijven.
3. Commit op `chefgroep-tuning`; upstream-sync via merge met origin/main.
