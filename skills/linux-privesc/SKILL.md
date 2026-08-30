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

Linux privilege-escalation skill for authorized audits and your own lab environments.
Focus: systematic enumeration → quick wins → kernel → container → evidence.

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: confirm authorization — on live systems `work/<case>/scope.md` must have
   `auth.status=granted` (`../ops/scope-contract.md`), backed by a signed Rules of
   Engagement under the Dutch Computer Crime Act III (Wet computercriminaliteit III).
   Without a grant, only report the enumeration commands you ARE allowed to run;
   execute nothing.
2. `NOW`: check that this skill is the right one — Windows/AD escalation belongs to
   `../windows-ad/SKILL.md`, containers-as-target-system to `../cloud-k8s/SKILL.md`.
3. `NEXT`: read `../tool-index.md` for real tool paths (find/sudo/getcap/docker/python3/gcc).
4. `NEXT`: missing tool → bootstrap (`../scripts/bootstrap-reverse.sh`), never guess paths.
5. `ACT`: start Phase 1 below; do not linger in confirmation mode.

## Scope

- Authorized privesc audit on your own hosts, lab VMs, CTF boxes, containers.
- Post-exploitation analysis inside an authorized attack chain (chained with `../attack-chain/SKILL.md`).
- Hardening review: prove THAT a route exists (evidence), without running it on subject infrastructure.

Hard boundary: subject/third-party systems without a written grant → document only
the enumeration commands and expected results; NO execution.

## Workflow

### Phase 1 — Basic enumeration (no root required)

```bash
id; uname -a; cat /etc/os-release
sudo -n -l 2>/dev/null || echo "sudo prompts for a password"
find / -xdev \( -perm -4000 -o -perm -2000 \) -type f 2>/dev/null | sort
getcap -r / 2>/dev/null
crontab -l 2>/dev/null; ls -la /etc/cron* /var/spool/cron 2>/dev/null
systemctl list-timers --all 2>/dev/null | head -30
ls -la /etc/sudoers /etc/sudoers.d/ 2>/dev/null
find / -xdev -writable -type d 2>/dev/null | grep -v '^/tmp\|^/proc\|^/run' | head -30
echo "$PATH"; env | grep -iE 'token|key|secret|pass'
ls -la /var/backups/ /opt/ /home/ 2>/dev/null
```

Record every finding immediately as evidence (command + raw output),
see `../ops/evidence-finding-path.md`.

### Phase 2 — Quick wins (match on GTFOBins)

- **SUID/SGID binary**: look up each binary path on gtfobins.github.io → SUID section;
  classics: `env`, `find`, `vim`, `bash`, `less`, `cp`, `python3`, `openssl`.
- **sudo -l rules**: wildcards (`sudo less /var/log/*` → `!/bin/sh` in file),
  `env_keep+LD_PRELOAD`, `sudoedit` on files with shell metacharacters,
  `NOPASSWD` on scripts using `curl|tar|cp` (GTFOBins sudo section).
- **Capabilities**: `cap_setuid` on python/perl/openssl → uid 0 one-liner;
  `cap_dac_read_search` → read any file.
- **Cron**: scripts running as root that you can write to; wildcard abuse
  (`tar --checkpoint` with `tar cf *`); `PATH=`-hijack in cron scripts without absolute paths.
- **Writable /etc/passwd** (via another bug): `openssl passwd -1` + append a line.
- **Group membership**: `docker` → `docker run -v /:/host -it alpine`;
  `lxd`/`disk` → equivalent escape paths; `snap` → snapcraft poisoning.
- **NFS** `no_root_squash` in `/etc/exports` → setuid binary from the client.

### Phase 3 — Kernel exploits

Match the kernel version exactly; run candidates only after verification (own host/lab):

| Kernel range | Candidate |
|---|---|
| 5.8 – 5.16.10 | Dirty Pipe (CVE-2022-0847) |
| ≤ 5.10.22 / ≤ 5.11 (older) | PwnKit (CVE-2021-4034, polkit pkexec) |
| 5.8 – 5.10 | OverlayFS (CVE-2021-3493, Ubuntu-specific) |
| ≤ 4.8.3 | Dirty COW (CVE-2016-5195) |
| 5.14+ with io_uring | check io_uring CVEs per version |
| 5.15+ | check DirtyFIFO / DirtyPipe variants |

Exploit source only from your own mirror or a clean upstream; verify the sha256 before building.

### Phase 4 — Container escape (if inside a container)

```bash
cat /proc/1/cgroup; ls -la /.dockerenv 2>/dev/null
capsh --print 2>/dev/null || grep Cap /proc/self/status
mount | grep -E 'docker|overlay|kube'
ls -la /var/run/secrets/kubernetes.io/ 2>/dev/null
```

- Privileged container → `fdisk -l`, mount the host block device.
- `cap_sys_admin` → mount host root; `cap_sys_ptrace` → inject into host proc.
- Docker socket mounted → `docker run -v /:/host`.
- runc ≤ 1.0-rc6 (CVE-2019-5736) → report as a finding only; do not run blindly.
- k8s ServiceAccount token → check the role, report the escalation path.

### Phase 5 — Reporting

- Per route: Finding (title + CVSS direction), Evidence commands, Impact, Fix
  (least privilege, stricter sudoers, SUID scrub, kernel patch).
- Keep the timeline/workitems up to date (`../ops/timeline-workitem.md`).
- Exploit only until proof (id=0 + one file-tampering marker),
  then roll back whatever can be rolled back.

## Tool Matrix (Linux)

| Tool | Use | Available via |
|---|---|---|
| find/sudo/getcap/capsh | enumeration | base system |
| docker | group escape | apt `docker.io` |
| python3/gcc | exploit build | apt |
| linpeas/pspy | optional deep enum | own mirror, run offline |

## Boundaries

- No execution on third-party systems without `auth.status=granted`.
- Kernel exploits can destabilize a host — own lab only; on subject hosts leave the
  version finding plus the exploit candidate in place as evidence.
- Report persistence recommendations (cron/SSH key); never place them yourself outside your mandate.
