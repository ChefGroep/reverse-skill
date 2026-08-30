---
name: email-security
description: Use for authorized email security review including phishing analysis, header authentication (SPF/DKIM/DMARC), BEC patterns, and mailbox token abuse research.
---

# Email Security & Phishing Analysis

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: confirm authorization (analyzing sample emails / tenant configuration review; `work/<case>/scope.md` with `auth.status=granted` under Wet computercriminaliteit III)
2. `NOW`: never redeliver malicious samples to real users
3. `ACT`: header authentication → content/URL → attachment sandbox → tenant control-plane recommendations

## When to Use

- Phishing email teardown and IOCs
- SPF/DKIM/DMARC configuration assessment
- BEC (business email compromise) patterns
- OAuth app phishing / mailbox token abuse (paired with llm/cloud identity skills)
- Security awareness exercise design (authorized)

## Workflow

```text
□ Full raw headers: Received chain, From/Return-Path consistency
□ SPF/DKIM/DMARC alignment results
□ URL sandboxing and attachment statics (paired with malware-analysis)
□ Spoofed brands and reply-address discrepancies
□ Tenant: anti-phishing policy, external tagging, MFA, OAuth app consent
□ BEC fraud: victim organizations report to Politie / Openbaar Ministerie; spoofed .nl domains via SIDN abuse reporting
```

## Toolchain

| Tool | Purpose |
|------|------|
| Mail client "View source" | headers |
| dig/nslookup | SPF/DMARC records |
| urlscan / sandbox | links and attachments |
| Tenant admin center | policies |

## References

- `references/email-auth-checklist.md`
- `../malware-analysis/` `../attack-chain/` (phishing stage) `../windows-ad/` (tokens)

## Routing Context

**Upstream**: MASTER R36  
**MUST NOT**: sending test phishing to third-party domains without authorization

## Completion Checklist

- [ ] Header-authentication conclusion complete?
- [ ] IOCs turned into detections (paired with threat-hunting)?
- [ ] Checklist?
