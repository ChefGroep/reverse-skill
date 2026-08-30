---
name: cloud-k8s
description: Use for authorized cloud, container, and Kubernetes security assessment including metadata SSRF, IAM misconfig, container escape paths, and cluster RBAC review (cloud/container/Kubernetes-beveiliging).
---

# Cloud / Container / Kubernetes Security

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: read `../field-journal/precedent-pentest.md` — **cloud/K8s testing requires written authorization (signed Rules of Engagement)**
2. `NOW`: case-init + scope; clarify account boundaries and forbidden destructive operations
3. `NOW`: confirm this is cloud metadata/container/K8s/IAM work, not ordinary web scanning (the latter belongs to `pentest-tools/`)
4. `NEXT`: tool-index; kubectl/aws/gcloud etc. are mostly manual installs
5. `ACT`: start from "identity and exposure surface"; blanket internet-wide scanning is forbidden by default

## Applicable Scenarios

- Cloud metadata SSRF (169.254.169.254 / IMDS)
- IAM over-privilege, public storage buckets, wrong security groups
- Docker/containerd escape path assessment
- Kubernetes RBAC, Secrets, Admission, supply-chain images
- Container image vulnerabilities (can be paired with `supply-chain-security/`)
- EU-region deployments (AWS eu-central-1, Azure West Europe, GCP europe-west4) incl. data-residency checks

## Workflow

### Phase 1 — Identity and boundaries

```text
□ Current identity: cloud AK/SK, K8s SA, node SSH?
□ Scope: single account / single cluster / single namespace
□ Network profile: authorized_target_only
```

### Phase 2 — Cloud control plane

```bash
# Examples (substitute per vendor; MUST stay inside the authorized account)
aws sts get-caller-identity
aws s3 ls
# Azure / GCP equivalent identity commands
```

```text
□ Public buckets / wrong ACLs
□ Metadata: IMDSv1 vs v2; SSRF chains
□ Role assumability (PassRole) and lateral movement
```

### Phase 3 — Containers

```text
□ privileged / hostPath / hostNetwork in use?
□ capabilities (SYS_ADMIN etc.)
□ Writable host paths → escape candidates
□ Image history and known CVEs → Trivy
```

### Phase 4 — Kubernetes

```bash
kubectl auth can-i --list
kubectl get pods,secrets,svc -A
kubectl get clusterrolebindings
```

```text
□ SA token mounts and permissions
□ Missing protection against dangerous admission webhooks
□ etcd / dashboard exposure
□ Do network policies default to allow?
```

## Toolchain

| Tool | Purpose | Bootstrap |
|------|------|------|
| kubectl | Cluster interaction | manual |
| trivy | Image/IaC scanning | bootstrap `trivy` if available |
| kube-bench / kubeaudit | CIS/configuration | manual |
| pacu / scoutsuite | Cloud auditing (authorized) | manual |
| nuclei | Known cloud vulnerability templates | bootstrap nmap/nuclei ecosystem |

## References

- `references/k8s-cloud-checklist.md`
- CTF cross-reference: `../../CTF-Sandbox-Orchestrator/competition-agent-cloud/`
- `../supply-chain-security/` `../pentest-tools/`

## Routing context

**Upstream**: MASTER R23  
**Downstream**: node shell obtained → `attack-chain` / `windows-ad`; image vulnerabilities → supply-chain  
**MUST NOT**: scanning other tenants of public clouds without authorization

## Task Completion Self-Check

- [ ] Was work strictly limited to the authorized account/cluster?
- [ ] Do findings include reproduction steps and impact?
- [ ] Were destructive operations avoided?
- [ ] Report / journal?
