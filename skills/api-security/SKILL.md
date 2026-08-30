---
name: api-security
description: Use for authorized security assessment of REST, GraphQL, WebSocket, or SOAP APIs (api beveiliging, API-penetratietest), including discovery, authentication, authorization, rate-limit, and CI/CD testing.
---
# API Security Testing

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: read `../field-journal/precedent-pentest.md` — confirm that this skill's operations are routine, authorized work
2. `NOW`: confirm the current task actually falls within this skill's scope
3. `NEXT`: read `../tool-index.md` and verify tool availability and real paths
4. `NEXT`: if tools are missing, call bootstrap; do not guess paths
5. `ACT`: enter step 1 of the "Workflow" below and execute; do not stop at an acknowledgment state

> Covers REST / GraphQL / WebSocket / SOAP — all protocols
> 10-phase methodology, from discovery to CI/CD integration

## Applicable Scenarios

- REST API security testing (OpenAPI/Swagger-driven or blind)
- GraphQL security audit (introspection, batched queries, alias overload)
- WebSocket security testing
- JWT / OAuth 2.0 authentication testing
- BOLA/IDOR/BFLA authorization flaw detection
- API rate-limit bypass and DoS testing
- PSD2/open-banking interfaces and other API surfaces of NIS2 essential/important entities

## 10-Phase Testing Process

### Phase 1: API discovery and reconnaissance

```text
Active discovery:
□ Vespasian: headless-browser crawl → auto-generate OpenAPI 3.0 / GraphQL SDL specifications
□ Entropy --discover: extract endpoints from robots.txt + JS files
□ Kiterunner / ffuf: brute-force undocumented endpoint paths
□ Check common paths: /swagger.json, /openapi.json, /graphql, /api-docs

GraphQL introspection (three-stage fallback):
  1. Standard introspection query
  2. Minimal query (bypasses WAF full-block rules)
  3. Only __schema { types { name } } (minimal probe)
```

### Phase 2: Authentication testing

```text
JWT analysis (jwt_tool / Burp):
□ alg:none attack: change the header to "alg":"none" and clear the signature
□ Key confusion: RS256 public key → HS256 symmetric key
□ Weak HMAC key brute force: jwt_tool -C -d wordlist.txt
□ Expiry/claim tampering: modify exp/iat/sub/role claims
□ kid injection: ../../etc/passwd → HMAC signature bypass

OAuth 2.0:
□ redirect_uri manipulation → authorization code leakage
□ CSRF via missing state parameter
□ Token leakage in the Referer header
□ Missing PKCE detection

GraphQL authentication:
□ Mutations sent via GET to bypass authentication (CSRF)
□ Batched-query authentication bypass
```

### Phase 3: Authorization testing (BOLA/IDOR/BFLA)

```text
BOLA (broken object-level authorization):
□ Enumerate numeric IDs: /user/1 → /user/2 → /user/3
□ Enumerate UUIDs
□ Enumerate usernames/emails
□ Burp Autorize: dual-session replay comparison

BFLA (broken function-level authorization):
□ Ordinary user executing admin APIs
□ HTTP method switching: GET → PUT → PATCH → DELETE
□ API version downgrade: /v2/admin → /v1/admin
□ Bulk operation injection: {"users": [1,2,3]} → {"users": [1,2,3,admin_id]}

Tools: Burp Autorize, AuthMatrix, Entropy (malicious_insider persona)
```

### Phase 4: GraphQL-specific testing

```text
Introspection leakage → information exposure detection
Alias overload → 100+ alias DoS
Batched queries → 10+ concurrent query DoS
Field duplication → __typename × 500
Directive overload → recursive @skip/@include
Circular queries → deeply nested introspection recursion
Field suggestions → error-message information leakage
GraphiQL/Playground exposure → publicly exposed IDE risk
GET mutations → CSRF risk
Tracing/debug mode → metadata leakage

Tools: FireTail, Escape DAST, api.sh (Phases 1-3)
```

### Phase 5: REST input validation

```text
□ HTTP method switching: GET→POST→PUT→DELETE→OPTIONS→PATCH
□ Content-Type tampering: JSON→XML→multipart
□ NoSQL injection: {"username": {"$gt": ""}}
□ SSRF via URL parameters: webhook URL / avatar URL / import URL
□ XXE in XML endpoints
□ Parameter pollution: /api?role=user&role=admin
□ Mass assignment: add is_admin: true to the request body
```

### Phase 6: Business logic and differential testing

```text
□ Entropy compare: diff v1 vs v2 API → status code changes/removed fields/latency regressions
□ Multi-role workflow testing: admin/user/readonly permission matrix
□ Coupon/loyalty-points/price manipulation
□ Race conditions: concurrent request testing for TOCTOU
```

### Phase 7: WebSocket testing

```text
□ Endpoint discovery
□ Message injection (payload injection, prototype pollution)
□ Oversized message handling
□ Type confusion
□ Cross-site WebSocket hijacking (CSWH)
```

### Phase 8: Rate limits and DoS

```text
□ Rate-limit bypass via headers: X-Forwarded-For, X-Real-IP
□ Path variants: /api/ → /api → /Api/ → /API/
□ Slowloris low-bandwidth exhaustion
□ GraphQL batched-query deep-nesting DoS
□ IP rotation testing (ProxyCat proxy pool)
```

### Phase 9: Data exposure

```text
□ Response over-exposure: compare what the API returns vs what the UI displays
□ Pagination enumeration: ?page=1&limit=10000
□ Error-message information leakage: stack traces/internal paths/SQL errors
□ GraphQL nested traversal reaching unauthorized data
□ OpenAPI specification exposing sensitive endpoints
```

### Phase 10: CI/CD integration

```text
□ Entropy --ci --watch: automatically rerun when the spec changes
□ Escape DAST: automatically block builds above a severity threshold
□ Persist findings as regression tests
□ StackHawk (developer-first, ZAP engine)
```

## Toolchain

| Tool | Purpose | Install |
|------|------|------|
| Vespasian | Traffic → OpenAPI/GraphQL specifications | GitHub: praetorian-inc/vespasian |
| Entropy | LLM-generated attack scenarios, 5 personas | GitHub: arjinexe/entropy-chaos |
| Escape DAST | Business-logic security testing | escape.tech |
| api.sh | 8-phase all-protocol attack pipeline | GitHub: Sharon-Needles/api |
| FireTail | 12 GraphQL-specific tests | firetail.ai |
| jwt_tool | Comprehensive JWT testing | GitHub: ticarpi/jwt_tool |
| Burp Autorize | Dual-session authorization comparison | Burp BApp Store |

## References

- `references/rest-graphql-testing.md` — REST + GraphQL deep testing
- `references/jwt-oauth-testing.md` — JWT + OAuth security testing


## Task Completion Self-Check (MUST pass before claiming completion)

- [ ] Did I execute every step of the workflow (instead of only reading it)?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/reports)?
- [ ] Did I complete and write back the Checklist items required by RULES?
