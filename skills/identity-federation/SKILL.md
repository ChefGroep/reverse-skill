---
name: identity-federation
description: Use for authorized assessment of federated identity systems including SAML, OIDC, OAuth2 flows, SSO misconfiguration, and token confusion issues.
---

# Identity Federation (SAML / OIDC / OAuth)

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: read precedent-pentest; SSO test accounts and IdP/SP scope go into the scope
2. `NOW`: no brute-force attempts that lock out real users
3. `NEXT`: packet-capture tools and documentation (metadata URLs)
4. `ACT`: protocol flow mapping → common misconfigurations → validation

## When to Use

- SAML Response signature/assertion tampering surfaces (classic flaw patterns)
- OIDC implicit/authorization code + missing PKCE
- redirect_uri / state / nonce issues
- IdP and SP metadata, multi-tenant issuer confusion
- Complementary to `api-security` JWT attacks (this skill leans federation and SSO flows)

## Workflow

```text
□ Map clearly: User → SP → IdP → Token → SP
□ Collect: /.well-known/openid-configuration, SAML metadata
□ Check: redirect_uri exact match, state binding, PKCE
□ Check: SAML signature coverage, algorithm downgrade
□ Session fixation and logout invalidation
□ NL/EU: DigiD / eIDAS / Entra ID federation hops follow the same flow mapping
```

## Toolchain

| Tool | Purpose |
|------|------|
| Burp + SAML Raider etc. | assertion editing (authorized) |
| jwt_tool | JWT segments |
| Browser DevTools | redirect chains |
| IdP admin logs | audit |

## References

- `references/sso-flow-checklist.md`
- `../api-security/` `../windows-ad/` (enterprise IdPs)

## Routing Context

**Upstream**: MASTER R37  
**Downstream**: pure API JWT → api-security; cloud IdP → cloud-k8s

## Completion Checklist

- [ ] Full SSO flow mapped?
- [ ] Every Finding has reproduction and impact?
- [ ] Checklist?
