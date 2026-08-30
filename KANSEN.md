# KANSEN — gemiste kansen + uitbreidingen (2026-08-29)

Inventaris naar aanleiding van Joeps vraag "wat zijn mogelijkheden/kansen die we missen + mee uitbreiden". Status per punt, prioriteit, waar het asset hoort (compound-engineering-doctrine).

## 1. Compound-engineering doctrine — OVERGENOMEN ✅
Every's filosofie (Plan→Work→Review→Compound→Repeat) overgenomen als skill `~/.dsh/skills/compound-engineering/SKILL.md` — alle sessies (joep-agent + osint-nl-red) pikken die live op. Harde regel: taak zonder compound-asset = bug.

## 2. Flash-subagent-fanout — GEREED ✅
tool-subagent + tool-subagent-fork in beide presets staan op `agentOptions {provider: cloudflare-workers-ai, model: @cf/zai-org/glm-5.3-flash}`; settings `agent-default-model` al op flash. Effect na `restart_harness`. Gebruik: goedkope parallelle review/research-rondes (P1/P2/P3-review, fan-out 2-5).

## 3. Capability-router over de 46 Redteam-skills — GEREED ✅
Skill `redteam-dsh-router` live in `~/.dsh/skills` (operator-global): DSH-sessies routeren via `bash /home/chef/Redteam/skills/scripts/master-route.sh --hint "<taak>"` (score-based SSOT, live 3/3 hints bewezen, schrijft meteen route-scope.md). Geen gokken uit 46 namen meer.

## 4. Router-benchmark-fuzzing door flash — GEREED ✅ (192 → 228 cases)
Flash-fuzz-workflow `router-benchmark-fuzz` (5 agents × 12 cases, 36 kandidaten): 27 direct gevalideerd + 9 na router-fix = 36/36 in de benchmark, **228/228 PASS**, commit 64e8083 op chefgroep-tuning. Router-vondst: R18 `edr`-keyword had geen word-boundary — NL "bedrijf" matchte EDR. Gefixed + 9 NL/EN-spreektalen-regels (verborgen data→R43, geheugendump→R25, naar root→R42, publiek te vinden→R44, suspicious binary→R9, handtekening→R3, echt of nep→R36, schuifcijfer→R45, container-to-host→R23).
- Terugkerend patroon: na ELKE routing.json-wijziging de workflow `router-benchmark-fuzz` opnieuw draaien.

## 5. Gap-monitor-framework generiek — OPEN
KommaGo gap-monitor (6-uurlijks cron, statuswijzigingen-alert, raw/gap_monitor_changes.md) is KommaGo-specifiek. Kans: generaliseren naar elke target/dossier — eigen infra, fleet-health, CI-rood, dossier-veranderingen. Eén framework, N-monitoren.
- Asset: skill `gap-monitor-generic` in ~/.dsh/skills + herbruik cron-sjabloon.

## 6. bkcrack Linux-build — OPEN (klein)
Manifest-asset is win64-only. Kans: Linux-binair bouwen uit dezelfde gepinde release (cmake + make, éénmalig, in ~/tools/bkcrack).
- Asset: bootstrap-manifest capability row + tool-index.

## 7. MCP-registraties per case — OPEN (per-case beslissing)
xquik (X/Twitter), jshookmcp (JS-hook), anything-analyzer, pentestswarm:OAuth/API-key-gated. Kans: registratie op osint-nl-red via `--mcp-host` per dossier, niet globaal (geen idle-daemons).
- Asset: dossier-doc + preset-wijziging per case.

## 8. DuckDB-dossierketening — DEELS ✅ (lessons zijn skills)
R25-lessons (SCP-pipeline, GROUP_CONCAT-aggregatie, build.duckdb/odido.duckdb-paden) zitten als lessons in memory. Kans: één herbruikbaar dossier-tool-script `dossier-duckdb.sh` dat SQL-naar-file→scp→duckdb-input als één pad aanbiedt.
- Asset: script in ~/.dsh/skills/dossier-tools/scripts/.

## 9. Ghidra-headless live pad — OPEN (klein)
ghidra-reverse-skill verwijst naar Ghidra maar het live analyzeHeadless-pad staat pas in tool-index na refresh. Kans: SKILL.md een concrete headless-opdracht meegeven (project-dir, script-pad) zodat elke sessie zonder opzoeken kan pakken.
- Asset: edit op `~/.agents/skills/ghidra-reverse/SKILL.md` (vendor-dir; niet symlinken).

## 10. Ralph-loops voor reverse-skill-cases — OPEN
Ralph (fresh-agent iteratie, workspace-geheugen) is nog niet gekoppeld aan de reverse-skill-workflow. Kans: CTF/exploit-rondes als Ralph-loop draaien met work/<case>/scope.md als state-bestand per ronde.
- Asset: uitbreiding op ctf-sandbox/redteam-orchestrator met ralph-koppeling.

## Volgorde (nu na restart)
1. Verificatie-subagent (flash-bewijs) ✅ na restart
2. Kans 3 (capability-router) — hoogste waarde per uur
3. Kans 4 (fuzzing) — goedkoop, flash-fanout
4. Kans 5 (gap-monitor) — fleet-breed
5. Kansen 6+8 (bkcrack, duckdb-script) — kleine permanente assets
