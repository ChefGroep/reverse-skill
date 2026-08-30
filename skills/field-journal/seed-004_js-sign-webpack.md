# [Seed] JS Signature Reverse Engineering (Webpack + AES + Timestamp)

## Scenario Category
JS signature

## Target Overview
Recover the `sign` parameter generation algorithm of a web application's API endpoints and reproduce it locally.

## Complete Execution Chain

1. Browser traffic capture → the POST request carries `sign` and `timestamp` parameters
2. Search "sign" in the JS source → locate the webpack-bundled chunk file
3. Set a breakpoint at the sign assignment → hits; inspect the call stack
4. Backtrack the call stack → find the signature function (inside a webpack module)
5. Analyze the signature logic: `sign = HmacSHA256(sorted_params + timestamp, secret_key)`
6. Key source: hardcoded in another webpack module
7. Local reproduction in Node.js → the generated sign matches the browser
8. Validation: request the endpoint with the reproduced sign → returns normal data

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| Searching "sign" returns too many results | webpack minification compresses variable names | Search `sign=` instead, or find the request in the network panel and backtrack via initiator | 15min |
| Breakpoint hits but the code is unreadable | webpack minification + variable-name obfuscation | Format with Chrome's Pretty Print, plus SourceMaps (if available) | 10min |
| Local reproduction result differs | Wrong parameter sorting | Read the sort logic in the source carefully (alphabetical by key + special-character handling) | 30min |
| Wrong timestamp precision | The server uses seconds; I used milliseconds | `Math.floor(Date.now() / 1000)` | 5min |
| Key not found | The key is imported from another chunk file via require | Print the key variable with console.log at the breakpoint | 10min |

## Toolchain Findings

- Chrome DevTools' initiator column locates the signature function faster than searching the source
- For webpack-bundled code, Pretty Print + breakpoints beats hard reading
- If a SourceMap (.map file) exists, the original code can be restored directly
- Node.js's `crypto` module can reproduce most signature algorithms directly

## Key Code/Commands

```javascript
// Node.js reproduction
const crypto = require('crypto');

function generateSign(params, timestamp, secretKey) {
    // 1. Sort parameters alphabetically by key
    const sorted = Object.keys(params).sort().map(k => `${k}=${params[k]}`).join('&');
    // 2. Concatenate the timestamp
    const message = sorted + '&timestamp=' + timestamp;
    // 3. HMAC-SHA256
    return crypto.createHmac('sha256', secretKey).update(message).digest('hex');
}

const params = { user_id: '123', action: 'query' };
const timestamp = Math.floor(Date.now() / 1000);
const secretKey = 'hardcoded_key_from_webpack';
console.log(generateSign(params, timestamp, secretKey));
```

## Improvement Suggestions for This Package

- js-reverse's env-patching.md should cover "how to handle dependencies between webpack chunks"
- Add a "common signature algorithm identification" cheat sheet (HMAC-SHA256 vs MD5 vs custom)

## Reusable Patterns/Script Snippets

**Standard JS signature reverse-engineering flow**:
```text
1. Capture the request carrying the signature
2. Locate the signature function via initiator/call stack
3. Analyze the signature logic (parameter sorting + concatenation + encryption)
4. Find the key source (hardcoded / returned by an endpoint / time-derived)
5. Reproduce in Node.js
6. Compare and validate
```

**Common signature patterns**:
```text
- HmacSHA256(sorted_params, key) → most common
- MD5(params + salt + timestamp) → older systems
- AES(JSON.stringify(params), key) → encryption rather than signing
- RSA sign → rare, usually financial
```

## Evolution Actions
- [ ] No routing-matrix update needed
- [ ] No bootstrap-manifest update needed
- [ ] No sub-skill doc update needed

## Environment Info
- OS: Windows
- Tool versions: Chrome DevTools, Node.js 20+
- Target platform: Web (webpack-bundled SPA)

## De-identification Requirement
This entry is seed data written from public technical patterns; it involves no real target.

---
<!-- [Community contribution] Seed data, no PR needed -->
