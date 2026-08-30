# 2026-06-29 burp-mcp-full Full Test and Fix

## Scenario Classification
BurpSuite extension development/testing

## Target Overview
Full runtime availability testing of the burp-mcp-full extension (Burp Suite Professional MCP Full Control, 63 tools), discovering and fixing 3 bugs + 1 bridge-layer race condition.

## Complete Execution Chain

1. Static verification: check Java dispatch table / getToolList() / bridge buildToolDefinitions for 63-tool consistency in all three places
2. Compilation: build.bat automated fat-jar packaging (JDK 21, montoya-api 2025.5, gson 2.11.0, nanohttpd 2.3.1)
3. Loading: load the extension in Burp Suite Professional 2026.4.2, confirm [MCP] Server started
4. Runtime testing: call 127.0.0.1:9876 directly via a node http client, in 5 batches:
   - Batch 1: 30 read-only/codec/query tools (zero side effects)
   - Batch 2: network-sending tools (send_request / repeater / intruder, target scanme.nmap.org)
   - Batch 3: Intruder 7 variants (attack/async/wordlist/pitchfork/cluster_bomb/battering_ram/with_options, small-scope enumeration)
   - Batch 4: Scope/configuration/rules/handler/add_issue/compare
   - Batch 5: crawl + proxy_clear
5. Discovered and fixed 3 bugs, regression verification passed

## Pitfall Records

| Problem | Cause | Solution | Time Spent |
|------|------|---------|------|
| `scan()` request_count always 0 | AuditConfiguration does not accept a seed URL; the code misses the addRequest call | Parse host/port/path from the url, construct a GET HttpRequest and feed it to activeAudit.addRequest() | 2h (including verification) |
| `send_to_intruder()` reports HttpRequest must have an HttpService | Use the HttpRequest.httpRequest(raw) overload without a service | Added buildRequestWithService(): parse host/port/https from the Host header regex → HttpService, use the httpRequest(HttpService, raw) overload | 20min |
| `set_upstream_proxy()` null-pointer NPE when the parameter is missing | params.get("proxy_host") returns null → .getAsString() NPE | Add a null check: if (!params.has("proxy_host")) return a clear error | 5min |
| mcp-bridge.js API async race condition: with 4 rapid requests the 4th loses its response | process.exit(0) on stdin close kills unfinished HTTP requests | pending counter + stdinClosed flag → exit only after all requests complete | 1h (including mock testing) |
| curl HTTP_CODE=000 cannot probe the port | curl is sandbox-forbidden on this machine | Switch to the node http module for probing | 5min |
| Montoya API Audit package path guessed wrongly | Based on the online javadoc, Audit was assumed to be under the scanner package | javap decompile the real montoya-api-2025.5.jar, confirm it is under the scanner.audit package | 30min |
| File encoding issue caused the Edit tool match failure | UTF-8 with BOM Chinese content displays with broken encoding layers in the terminal | Switch to Python for the replacement, specifying utf-8-sig | 10min |

## Toolchain Findings

- montoya-api 2025.5: Audit is at `burp.api.montoya.scanner.audit.Audit` (not scanner.Audit)
- AuditConfiguration factory methods do not accept a seed URL; seeds must be fed in via Audit.addRequest(HttpRequest)
- HttpRequest.httpRequest(raw), the overload without a service, is enough for Repeater, but Intruder requires one with HttpService
- Intruder.sendToIntruder(HttpRequest) requires the request to have a service attached
- api.burpSuite().version(): major()/minor()/build() went deprecation→removal in 2025.5; use buildNumber()/edition()/toString() instead
- send_request goes through http.sendRequest() and does not enter proxy history
- Local curl is sandbox-blocked; use node http for probing
- IDA MCP port is not fixed at 13337 (increments between instances), but the Burp MCP port is configurable via system properties/env and stays fixed

## Key Code/Commands

### Full Test Script Pattern
```javascript
const http = require('http');
function call(tool, params={}, timeoutMs=30000) {
  return new Promise((resolve) => {
    const body = JSON.stringify({tool, params});
    const req = http.request({hostname:'127.0.0.1',port:9876,path:'/',method:'POST',
      headers:{'Content-Type':'application/json','Content-Length':Buffer.byteLength(body)}}, (res)=>{
      let d=''; res.on('data',c=>d+=c); res.on('end',()=>{ try{resolve(JSON.parse(d));}catch(e){resolve({__raw:d.slice(0,200)});} });
    });
    req.on('error', e => resolve({__err: e.message}));
    req.on('timeout', () => { req.destroy(); resolve({__timeout:true}); });
    req.setTimeout(timeoutMs);
    req.write(body); req.end();
  });
}
```

### buildRequestWithService (Core Fix)
```java
private HttpRequest buildRequestWithService(String rawRequest) {
    java.util.regex.Matcher m = java.util.regex.Pattern.compile(
            "(?im)^Host:\\s*([^:\r\n]+)(?::(\\d+))?\\s*$").matcher(rawRequest);
    if (!m.find()) return HttpRequest.httpRequest(rawRequest);
    String host = m.group(1).trim();
    boolean isHttps = rawRequest.contains("https://") || rawRequest.contains(":443");
    int port = m.group(2) != null ? Integer.parseInt(m.group(2))
              : (isHttps ? 443 : 80);
    HttpService svc = HttpService.httpService(host, port, isHttps);
    return HttpRequest.httpRequest(svc, rawRequest);
}
```

### Bridge-Layer Race Condition Fix (mcp-bridge.js)
```javascript
let pending = 0;
let stdinClosed = false;
rl.on('line', async (line) => { ... pending++; ... finally { pending--; if (stdinClosed && pending === 0) process.exit(0); } });
rl.on('close', () => { stdinClosed = true; if (pending === 0) process.exit(0); });
```

### scan() Seed Fix
```java
// Construct a GET seed request from the URL and feed it to the audit
java.net.URL u = new java.net.URL(url);
String host = u.getHost();
boolean isHttps = "https".equalsIgnoreCase(u.getProtocol());
int port = u.getPort() > 0 ? u.getPort() : (isHttps ? 443 : 80);
String path = (u.getPath() == null || u.getPath().isEmpty()) ? "/" : u.getPath();
String pathQuery = u.getQuery() != null ? path + "?" + u.getQuery() : path;
HttpService svc = HttpService.httpService(host, port, isHttps);
HttpRequest seedReq = HttpRequest.httpRequest(svc,
    "GET " + pathQuery + " HTTP/1.1\r\nHost: " + host + "\r\nConnection: close\r\n\r\n");
activeAudit.addRequest(seedReq);
```

## Improvement Suggestions for This Package

- The routing matrix already covers BurpSuite MCP; no changes needed
- `burpsuite-mcp-guide.md` has appended an update log (3 fixes + bridge layer + full verification results)
- The tools table has been updated for Scanner (scan gains the mode parameter) and Intruder (send_to_intruder Host header requirement)
- No new bootstrap entries needed (the build script build.bat is self-contained)
- IDA MCP port is not fixed; suggest noting it in the MCP service management table

## Reusable Patterns/Script Fragments

- 63-tool full availability test script pattern (see the key code above). Suitable for regression testing of any HTTP-based MCP extension.
- buildRequestWithService pattern: parse HttpService from the Host header. Suitable for all Montoya API scenarios that need to construct HttpRequest + HttpService from a raw request.

## Evolution Actions
- [x] Updated the routing matrix (already covered; no changes needed)
- [ ] Updated tool-index (uses .template; no changes needed)
- [ ] Updated bootstrap-manifest (no new tools)
- [x] Updated the sub-skill docs (burpsuite-mcp-guide.md appended update log)
- [x] Added a pitfall record (this entry)
- [ ] No updates needed

## Environment Info
- OS: Windows 11 Pro for Workstations 10.0.26200
- Tool versions: JDK 21.0.11+10 / Burp Suite Professional 2026.4.2 (20260402000047704)
- Target platform: montoya-api 2025.5 / gson 2.11.0 / nanohttpd 2.3.1
- Test target: scanme.nmap.org (authorized test site)

## De-identification Requirements
The test target is the public test site scanme.nmap.org; no de-identification needed. Contains no real domains/IPs/tokens/usernames.

## Index Sync (last step before commit)

After writing this log, `_index.md` must be synced and updated:

1. Add a line in the matching subsection under "by scenario classification" (with date, keywords)
2. Update the "cumulative statistics" counts and "most recent update" date

---
<!-- [Community contribution] After finishing, ask the user whether to PR to the main repository. See CONTRIBUTE-BACK.md for the process -->