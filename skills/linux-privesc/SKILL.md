---
name: linux-privesc
description: |
  Linux privilege escalation audit and exploitation: SUID/SGID hunting, sudo
  misconfigurations, GTFOBins lookups, file capabilities, cron/writable-path
  abuse, PATH hijack, kernel exploit selection (Dirty Pipe, PwnKit, OverlayFS),
  and container escape paths (docker group, privileged containers, runc).
  Use when the task mentions privesc, privilege escalation on Linux, sudo -l,
  SUID, GTFOBins, getcap, sudoers, pkexec, or "rechten verhogen".
---

# linux-privesc

Linux privilege-escalatie skill voor geautoriseerde audits en eigen lab-omgevingen.
Focus: systematische enumeratie → quick wins → kernel → container → bewijs.

## ACTION REQUIRED（读完后立刻执行）

1. `NOW`: bevestig autorisatie — bij levende systemen moet `work/<case>/scope.md`
   `auth.status=granted` hebben (`../ops/scope-contract.md`). Zonder grant alleen
   enumeratie-opdrachten rapporteren die je wél mag draaien, niets uitvoeren.
2. `NOW`: check dat deze skill de juiste is — Windows/AD-escalatie hoort bij
   `../windows-ad/SKILL.md`, containers-als-doelstelsel bij `../cloud-k8s/SKILL.md`.
3. `NEXT`: lees `../tool-index.md` voor echte tool-paden (find/sudo/getcap/docker/python3/gcc).
4. `NEXT`: ontbrekende tool → bootstrap (`../scripts/bootstrap-reverse.sh`), nooit paden gokken.
5. `ACT`: start Fase 1 hieronder; niet blijven hangen in bevestigingsmodus.

## Toepassingsgebied

- Geautoriseerde privesc-audit op eigen hosts, lab-VM's, CTF-boxen, containers.
- Post-exploitatie-analyse binnen een geautoriseerde attack-chain (ket met `../attack-chain/SKILL.md`).
- Hardening-review: aantonen dát een route bestaat (bewijs), zonder hem op subject-infra uit te voeren.

Hard grens: subject-/derden-systemen zonder schriftelijke grant → alleen de
enumeratie-opdrachten en verwachte resultaten documenteren; GEEN uitvoering.

## Werkwijze

### Fase 1 — Basisenumeratie (geen root nodig)

```bash
id; uname -a; cat /etc/os-release
sudo -n -l 2>/dev/null || echo "sudo vraagt wachtwoord"
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null | sort
getcap -r / 2>/dev/null
crontab -l 2>/dev/null; ls -la /etc/cron* /var/spool/cron 2>/dev/null
systemctl list-timers --all 2>/dev/null | head -30
ls -la /etc/sudoers /etc/sudoers.d/ 2>/dev/null
find / -xdev -writable -type d 2>/dev/null | grep -v '^/tmp\|^/proc\|^/run' | head -30
echo "$PATH"; env | grep -iE 'token|key|secret|pass'
ls -la /var/backups/ /opt/ /home/ 2>/dev/null
```

Elke finding direct als evidence vastleggen (command + raw output),
zie `../ops/evidence-finding-path.md`.

### Fase 2 — Quick wins (match op GTFOBins)

- **SUID/SGID-binary**: zoek elk binary-pad op gtfobins.github.io → sectie SUID;
  klassiekers: `env`, `find`, `vim`, `bash`, `less`, `cp`, `python3`, `openssl`.
- **sudo -l regels**: wildcards (`sudo less /var/log/*` → `!/bin/sh` in file),
  `env_keep+LD_PRELOAD`, `sudoedit` op bestanden met shell-metachars,
  `NOPASSWD` op scripts met `curl|tar|cp` (GTFOBins sudo-sectie).
- **Capabilities**: `cap_setuid` op python/perl/openssl → uid 0 one-liner;
  `cap_dac_read_search` → lees elk bestand.
- **Cron**: scripts die root draait en door jou beschrijfbaar zijn; wildcard-abuse
  (`tar --checkpoint` bij `tar cf *`); `PATH=`-hijack in cron-scripts zonder absolute paden.
- **Writable /etc/passwd** (via andere bug): `openssl passwd -1` + regel toevoegen.
- **Groepslidmaatschap**: `docker` → `docker run -v /:/host -it alpine`;
  `lxd`/`disk` → gelijkwaardige escape-paden; `snap` → snapcraft-poisoning.
- **NFS** `no_root_squash` in `/etc/exports` → setuid-binary vanaf client.

### Fase 3 — Kernel-exploits

Kernel-versie exact matchen; kandidaten pas na verificatie draaien (eigen host/lab):

| Kernel-bereik | Kandidaat |
|---|---|
| 5.8 – 5.16.10 | Dirty Pipe (CVE-2022-0847) |
| ≤ 5.10.22 / ≤ 5.11 (oude) | PwnKit (CVE-2021-4034, polkit pkexec) |
| 5.8 – 5.10 | OverlayFS (CVE-2021-3493, Ubuntu-specifiek) |
| ≤ 4.8.3 | Dirty COW (CVE-2016-5195) |
| 5.14+ met io_uring | check io_uring-CVE-per-versie |
| 5.15+ | DirtyFIFO / DirtyPipe-varianten checken |

Exploit-bron alleen uit eigen mirror of schone upstream; sha256 verifiëren vóór build.

### Fase 4 — Container-escape (indien in container)

```bash
cat /proc/1/cgroup; ls -la /.dockerenv 2>/dev/null
capsh --print 2>/dev/null || grep Cap /proc/self/status
mount | grep -E 'docker|overlay|kube'
ls -la /var/run/secrets/kubernetes.io/ 2>/dev/null
```

- Privileged container → `fdisk -l`, host-blockdevice mounten.
- `cap_sys_admin` → mount host-root; `cap_sys_ptrace` → host-proc injecteren.
- Docker-socket gemount → `docker run -v /:/host`.
- runc ≤ 1.0-rc6 (CVE-2019-5736) → alleen vermelden als finding, niet blind draaien.
- k8s ServiceAccount-token → rolcheck, escalation-pad rapporteren.

### Fase 5 — Rapportage

- Per route: Finding (titel + CVSS-richting), Evidence-commando's, Impact, Fix
  (least privilege, sudoers-streng, SUID-schrub, kernel-patch).
- Timeline/workitems bijhouden (`../ops/timeline-workitem.md`).
- Exploitatie alleen tot bewijs (id=0 + een bestandsaantasting-markering),
  daarna terugdraaien wat terugdraaibaar is.

## Toolmatrix (Linux)

| Tool | Gebruik | Beschikbaar via |
|---|---|---|
| find/sudo/getcap/capsh | enumeratie | basissysteem |
| docker | group-escape | apt `docker.io` |
| python3/gcc | exploit-build | apt |
| linpeas/pspy | optioneel diep-enum | eigen mirror, offline draaien |

## Grenzen

- Geen uitvoering op derden-systemen zonder `auth.status=granted`.
- Kernel-exploits kunnen host destabiliseren — alleen op eigen lab, en bij
  subject-hosts de versie-finding met exploit-candidaat als bewijs laten staan.
- Persistence-aanbevelingen rapporteren (cron/SSH-key), nooit zelf plaatsen buiten mandaat.
