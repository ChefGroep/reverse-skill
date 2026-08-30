# SBOM + SCA Methodology

## SBOM standard comparison

| Standard | Format | Ecosystem | Recommended use |
|------|------|------|---------|
| SPDX | JSON/YAML/tag-value | Linux Foundation, Yocto | License-compliance first |
| CycloneDX | JSON/XML | OWASP, Kubernetes | Security analysis first |
| SWID | XML | ISO standard | Enterprise asset management |

## SBOM generation toolchain

```bash
# cdxgen: generate a CycloneDX SBOM from source
cdxgen -o bom.json -t cyclonedx

# Syft: generate from containers/filesystems
syft nginx:latest -o spdx-json > sbom.spdx.json

# SBOM-Tool: Microsoft toolchain
sbom-tool generate -b ./build -bc ./src -pn MyApp -pv 1.0
```

## SCA tool comparison

| Tool | Free | Speed | Database | Reachability |
|------|:--:|------|--------|:--:|
| OSV-Scanner | ✅ | Very fast | OSV.dev | ❌ |
| Trivy | ✅ | Fast | Multi-source | ❌ |
| Dependency-Track | ✅ | Medium | NVD+OSV+GitHub | ❌ (plugin needed) |
| Snyk | ❌ | Medium | Proprietary | ✅ |
| CodeQL | ✅ | Slow | Code-level | ✅ |

## Vulnerability prioritization strategy

```
CVSS ≥ 9.0 + public PoC + reachable → P0 fix immediately
CVSS ≥ 7.0 + PoC + reachable → P1 fix this week
CVSS ≥ 7.0 + no PoC or unreachable → P2 fix next iteration
The rest → standard process
```

## Three-step manual verification

```bash
# 1. Confirm the version (never blindly trust SBOM fields)
# In a container: dpkg -l | grep <package>
# Node: cat node_modules/<pkg>/package.json | jq .version
# Python: pip show <package>

# 2. Confirm the vulnerability
# Search the CVE: https://osv.dev / https://nvd.nist.gov
# Check the affected version ranges
# Find the GitHub Advisory / oss-security mailing list

# 3. Verify the impact
# Search public PoCs: GitHub/Exploit-DB
# Analyze exploitation preconditions: authentication/local access/specific configuration required?
# Validate in an isolated environment: docker run --rm -it vulnerable-image bash
```

## Continuous monitoring

```yaml
# Daily SBOM update + scan
schedule:
  - cron: "0 6 * * *"  # every day at 6 AM
    steps:
      - cdxgen -o bom.json
      - osv-scanner scan --sbom bom.json
      - trivy fs --exit-code 1 --severity CRITICAL .
```

## EU/NL notes

- The EU Cyber Resilience Act requires manufacturers of products with digital elements to provide an SBOM in a machine-readable format (CycloneDX or SPDX both qualify) and to keep it current for the support period — treat missing or stale SBOMs as compliance findings.
- Under NIS2, affected essential/important entities must manage ICT supply-chain risk; a maintained SBOM plus reachable-vulnerability triage is the core evidence set.

Source: OWASP CycloneDX, SPDX, Google OSV, CISA SBOM Guidance
