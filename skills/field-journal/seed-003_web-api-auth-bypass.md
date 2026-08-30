# [Seed] Web API Unauthorized Access + IDOR

## Scenario Category
Penetration testing

## Target Overview
Black-box test the REST API of a web application; discover unauthorized access and IDOR vulnerabilities.

## Complete Execution Chain

1. Recon: Nmap scan → port 443 runs Nginx + a backend API
2. Directory discovery: FFUF brute-force → find the `/api/v1/` path
3. API enumeration: visit `/api/v1/docs` → exposed Swagger documentation found
4. Auth analysis: register two test accounts A and B
5. IDOR test: use account A's token to access account B's resources → succeeds (horizontal privilege escalation)
6. Unauthorized-access test: remove the Authorization header → some endpoints still return data (unauthorized access)
7. Impact validation: confirm that any user's personal data (name, email, phone number) can be read
8. Evidence collection: save request/response screenshots, de-identify, and compile the report

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| FFUF blocked by the WAF | Request rate too high, triggers rate limiting | Lower the rate with `-rate 10` and add `-H "User-Agent: Mozilla/5.0..."` | 10min |
| Swagger docs return 404 | The path is not the standard /swagger | Try `/api/v1/docs`, `/api-docs`, `/openapi.json` | 5min |
| IDOR test success uncertain | The returned data lacks an obvious user identifier | Compare the responses of the two accounts; find the user_id field difference | 15min |
| Report rejected by the bug bounty/VDP | Only screenshots were submitted, no complete reproduction steps | Add curl commands + full request/response pairs | 20min |

## Toolchain Findings

- FFUF is faster than Gobuster, but you must control the rate to avoid being blocked
- Exposed Swagger/OpenAPI documentation is the fastest way to enumerate an API
- IDOR tests must use two of your own accounts against each other; never touch other people's data
- A bug bounty report must include reproducible curl commands, not just screenshots

## Key Code/Commands

```bash
# Directory discovery
ffuf -u https://target.example.com/api/v1/FUZZ -w /path/to/SecLists/Discovery/Web-Content/api/api-endpoints.txt -rate 10

# IDOR test
# Use account A's token to access account B's resources
curl -H "Authorization: Bearer <token_A>" https://target.example.com/api/v1/users/USER_B_ID

# Unauthorized-access test
curl https://target.example.com/api/v1/users/USER_B_ID
# If it returns 200 + data → unauthorized access
```

## Improvement Suggestions for This Package

- pentest-tools should add a dedicated "API penetration testing" checklist
- src-hunter's IDOR playbook is very useful, but lacks guidance on "how to determine IDOR impact scope"

## Reusable Patterns/Script Snippets

**Three-step unauthorized-access test for APIs**:
```text
1. Normal request (with token) → record the normal response
2. Remove the token → check whether data is still returned (unauthorized access)
3. Use another user's token → check whether access succeeds (privilege escalation)
```

**Fast IDOR verification**:
```text
1. Register two accounts A and B
2. Get A's resource ID and B's resource ID
3. Request B's resource ID using A's token
4. If B's data comes back → IDOR confirmed
```

## Evolution Actions
- [ ] No routing-matrix update needed
- [ ] No bootstrap-manifest update needed
- [ ] No sub-skill doc update needed

## Environment Info
- OS: Windows (local machine) → target Linux server
- Tool versions: FFUF 2.x, curl, Burp Suite
- Target platform: Web API (REST, JSON)

## De-identification Requirement
This entry is seed data written from public technical patterns; it involves no real target.

---
<!-- [Community contribution] Seed data, no PR needed -->
