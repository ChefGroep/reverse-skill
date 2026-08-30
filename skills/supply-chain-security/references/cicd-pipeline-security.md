# CI/CD Pipeline Security Audit

## Pipeline attack surface

```text
Threat model (STRIDE):
□ Spoofing: forged builds/signatures/provenance
□ Tampering: modified source code/build artifacts/dependencies
□ Repudiation: malicious operations without audit logs
□ Information disclosure: pipeline logs/build artifacts leaking secrets
□ Denial of service: exhausted CI resources/broken builds
□ Privilege escalation: runner escape/secret theft
```

## Audit checklist

### 1. Pipeline as Code configuration

```yaml
# GitHub Actions audit points
# ❌ Dangerous pattern
on:
  pull_request_target:  # PR trigger with access to secrets
    types: [opened]

# ❌ Script injection
- run: echo "${{ github.event.issue.title }}"  # user input → shell

# ❌ Unrestricted token permissions
permissions: write-all

# ✅ Safe pattern
on:
  pull_request:  # no secrets access
    types: [opened]

# ✅ Pinned to SHA
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683

# ✅ Least privilege
permissions:
  contents: read
```

### 2. Secret management

```bash
# Scan commit history for secrets
gitleaks detect --source . --verbose
trufflehog git file://. --only-verified

# Check Actions Secrets usage
gh secret list
# Confirm: no hardcoded secrets, regular rotation, least privilege

# Runtime secret injection
# ✅ Use OIDC instead of long-lived secrets
# ✅ Expose secrets only to the specific steps that need them
```

### 3. Build integrity

```bash
# Build provenance
# Generate tamper-proof build records (SLSA L2+)
slsa-provenance generate --source . --output provenance.json

# Artifact signing
cosign sign-blob --key cosign.key artifact.tar.gz

# Verification
cosign verify-blob --key cosign.pub --signature artifact.tar.gz.sig artifact.tar.gz
```

### 4. Runner security

```text
□ Are GitHub-hosted runners in use? (recommended; fresh environment on every run)
□ Self-hosted runners: do they run in isolated VMs/containers?
□ Have fork PRs ever been executed? (extremely high risk on self-hosted runners)
□ Are outbound network restrictions in place for runners?
□ Could the build cache leak data across builds?
```

### 5. Dependency pull security

```text
□ npm: is package-lock.json committed? --force / --legacy-peer-deps forbidden
□ pip: are requirements.txt versions frozen? pip install from unverified sources forbidden
□ Docker: is FROM pinned to a digest? latest tag forbidden
□ Go: is go.sum committed?
□ Private packages: do registry credentials use short-lived tokens?
```

## Automated check pipeline

```yaml
# .github/workflows/supply-chain.yml
name: Supply Chain Security
on: [push, pull_request]

jobs:
  sca:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: SBOM Generate
        run: |
          npm install -g @cyclonedx/cdxgen
          cdxgen -o sbom.json
      
      - name: OSV Scan
        run: |
          go install github.com/google/osv-scanner/cmd/osv-scanner@latest
          osv-scanner scan --sbom sbom.json --format sarif > osv-results.sarif
      
      - name: Trivy Scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: fs
          severity: CRITICAL,HIGH
          exit-code: 1
      
      - name: Secret Scan
        run: |
          docker run --rm -v $PWD:/src ghcr.io/gitleaks/gitleaks:latest \
            detect --source /src --verbose
      
      - name: Dependency-Track Upload
        run: |
          curl -X POST https://dtrack.example.com/api/v1/bom \
            -H "X-Api-Key: ${{ secrets.DTRACK_API_KEY }}" \
            -F "autoCreate=true" -F "project=myapp" -F "bom=@sbom.json"
```

## EU/NL notes

- NIS2 (Art. 21) requires affected essential/important entities to manage ICT supply-chain security: pipeline integrity (SLSA + signing), secret hygiene, and dependency-pull controls map directly to those obligations.
- Verify that EU-hosted runners and artifact registries (e.g. AWS eu-central-1 / Azure West Europe / GCP europe-west4) keep build artifacts and logs within the agreed data-residency boundary of the Rules of Engagement.

Source: SLSA Framework, OWASP CI/CD Top 10, GitHub Security Lab
