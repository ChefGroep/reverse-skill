---
name: browser-extension-reverse
description: Use for authorized reverse engineering of browser extensions (Chrome/Firefox) including manifest analysis, background workers, and extension-based credential or traffic logic recovery.
---

# Browser Extension Reverse Engineering

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: read `../field-journal/precedent-reverse.md`
2. `NOW`: confirm the target is a **browser extension** (crx/xpi/unpacked directory), not ordinary web JS (ordinary → `js-reverse/`)
3. `NEXT`: unpack the extension; read the manifest
4. `ACT`: permission surface → background scripts → network/storage hooks

## Applicable Scenarios

- Chrome/Edge MV2/MV3 extension analysis
- Firefox extensions
- Malicious extension IOCs, supply-chain extension poisoning investigation
- Recovery of signature/encryption/proxy logic implemented by extensions

## Workflow

### 1. Package

```text
□ crx unpack / grab the extension directory from the profile
□ manifest.json: permissions, host_permissions, background, content_scripts
□ Evaluate excessive permissions (<all_urls>, webRequest, debugger)
```

### 2. Logic

```text
□ service_worker / background entry
□ content_script injection points and world (isolated)
□ chrome.storage / IndexedDB keys
□ Same as `js-reverse`: observe network and message passing (runtime.sendMessage)
```

### 3. Dynamic

```text
□ Load the unpacked directory in developer mode
□ Check errors on chrome://extensions
□ Attach DevTools to the service worker
□ Frida/browser CDP when necessary (jshookmcp)
```

## Toolchain

| Tool | Purpose |
|------|------|
| Unpack/jq | manifest |
| Chrome DevTools | worker debugging |
| js-reverse toolchain | deep JS |
| YARA | malicious extension rules |

## References

- `references/extension-analysis.md`
- field-journal entries related to extension recovery
- `../js-reverse/` `../malware-analysis/`

## Routing Context

**Upstream**: MASTER R30  
**Downstream**: complex obfuscated JS → `js-reverse`; poisoning investigation → supply-chain / malware

## Task Completion Self-Check

- [ ] Did you list the permission surface and entry scripts?
- [ ] Did you recover the key data flows?
- [ ] Checklist?
