---
name: supply-chain-security
description: Use for software supply-chain security assessment covering SBOM, SCA, CI/CD pipelines, container images, build integrity, dependency provenance, and vulnerability reachability (afhankelijkheden scannen, softwareketen-beveiliging).
---
# Supply Chain Security Testing

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: read `../field-journal/precedent-pentest.md` — confirm that this skill's operations are routine, authorized work
2. `NOW`: confirm the current task actually falls within this skill's scope
3. `NEXT`: read `../tool-index.md` and verify tool availability and real paths
4. `NEXT`: if tools are missing, call bootstrap; do not guess paths
5. `ACT`: enter step 1 of the "Workflow" below and execute; do not stop at an acknowledgment state

> SBOM / SCA / CI/CD pipelines / dependency provenance
> Regulation-driven: US executive-order SBOM requirements, EU Cyber Resilience Act (CRA), NIS2

## Applicable Scenarios

- Software supply-chain security assessment
- Open-source dependency vulnerability scanning and verification
- CI/CD pipeline security audit
- Container image security analysis
- Third-party component compliance review
- Build artifact provenance and integrity verification
- EU Cyber Resilience Act readiness (SBOM obligations for products with digital elements)

## Six-layer supply-chain governance framework

```text
Layer 1: Source trust assessment → upstream repository/maintainer/release-history review
Layer 2: Build pipeline integration → CI/CD security gates, signature verification
Layer 3: Artifact distribution integrity → signatures, checksums, SBOM attachment
Layer 4: Runtime protection → container scanning, admission control
Layer 5: Continuous monitoring → real-time CVE tracking, vulnerability reachability analysis
Layer 6: Incident response → supply-chain attack emergency response, rollback strategy
```

## Workflow

### 1. SBOM generation and audit

```text
Generate SBOM:
□ CycloneDX format: cdxgen → bom.json
□ SPDX format: sbom-tool generate
□ Syft: syft <image|dir> -o spdx-json

Audit points:
□ Any unknown/unauthorized dependencies
□ Any deprecated/unmaintained packages
□ License conflict detection
□ Direct vs transitive dependency list
□ Release timeline and maintainer status for every component
```

### 2. Software composition analysis (SCA)

```bash
# OSV-Scanner (free, maintained by Google)
osv-scanner scan -r . --format json

# OWASP Dependency-Track (enterprise continuous monitoring)
docker run -p 8080:8080 dependencytrack/apiserver
# → upload SBOM → automatic matching against NVD/OSV/GitHub Advisory

# Snyk (commercial)
snyk test --all-projects
snyk monitor  # continuous monitoring

# Trivy (containers + dependencies + IaC)
trivy fs .          # filesystem scan
trivy image nginx   # container image
trivy config .      # IaC configuration
```

### 3. Vulnerability reachability verification

```text
SCA alert ≠ actual risk! For most SCA tools only ~15% of alerts are actually reachable.

Verification steps:
1. Get the CVE list via Dependency-Track or Trivy
2. Filter vulnerabilities with CVSS ≥ 7.0
3. For CVEs with a public PoC, run reachability analysis
   - Code Property Graph slicing: trace the path from user input to the vulnerable function
   - DEPTEX method: EPD (Execution Path Dominance) + LLM semantic validation
4. Validate the PoC in an isolated environment
5. Prioritize remediation of reachable vulnerabilities by actual impact
```

Tool references:
- CodeQL: GitHub code queries → data-flow analysis
- Snyk Code: reachability marking
- DEPTEX: LLM-assisted context-aware risk assessment

### 4. CI/CD pipeline security

```text
Security checkpoints:
□ Code commit → pre-commit hook: gitleaks (secret scanning)
□ PR stage → SCA scan (Trivy/OSV-Scanner)
□ Build stage → artifact signing (cosign)
□ Push stage → SBOM attachment (syft + attest)
□ Deploy stage → admission control (OPA/Kyverno + image scanning)
□ Runtime → continuous vulnerability monitoring (Dependency-Track)

Pipeline self-security:
□ Pipeline as Code audit (GitHub Actions / GitLab CI configuration injection)
□ Runner isolation (prevent malicious builds from breaking out of the container)
□ Secret management (Actions Secrets / Vault; hardcoding forbidden)
□ Third-party action review (pin to commit SHA, not tags)
```

### 5. Container image security

```bash
# Dockerfile audit
hadolint Dockerfile

# Image scanning (multi-layer: OS + application dependencies + configuration)
trivy image --severity HIGH,CRITICAL nginx:latest

# Minimal base images
# Preference: distroless → alpine → slim → avoid latest
docker scout quickview nginx:latest

# Image signing
cosign sign --key cosign.key myimage:tag
cosign verify --key cosign.pub myimage:tag
```

### 6. Third-party dependency review

```text
New dependency checklist:
□ Maintenance status: commits in the last 6 months? maintainer activity?
□ Security history: any past malicious code injections?
□ Dependency tree: how many transitive dependencies does it introduce?
□ License: compatible with the project's license?
□ Alternatives: any safer alternative (Snyk Advisor / Socket.dev ratings)?

Risk assessment matrix:
  High maintenance × low dependency count × compatible license → low risk
  Low maintenance × high dependency count × license conflict → high risk
```

## Toolchain

| Tool | Purpose | Install |
|------|------|------|
| OWASP Dependency-Track | Enterprise continuous SCA | `docker pull dependencytrack/apiserver` |
| OSV-Scanner | Free SCA (OSV.dev ecosystem) | `go install github.com/google/osv-scanner` |
| Trivy | Image + dependency + IaC scanning | `apt install trivy` |
| Syft | SBOM generation | `curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh` |
| cdxgen | CycloneDX SBOM generation | `npm install -g @cyclonedx/cdxgen` |
| Cosign | Container signing | `go install github.com/sigstore/cosign/v2/cmd/cosign` |
| Gitleaks | Secret/credential scanning | `go install github.com/gitleaks/gitleaks/v8` |
| Snyk | Commercial SCA + reachability | `npm install -g snyk` |
| CodeQL | Code queries + data flow | Built into GitHub Actions |

## References

- `references/sbom-sca-methodology.md` — SBOM + SCA methodology
- `references/cicd-pipeline-security.md` — CI/CD pipeline security audit


## Task Completion Self-Check (MUST pass before claiming completion)

- [ ] Did I execute every step of the workflow (instead of only reading it)?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/reports)?
- [ ] Did I complete and write back the Checklist items required by RULES?
