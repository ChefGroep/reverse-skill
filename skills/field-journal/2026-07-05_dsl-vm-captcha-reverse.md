---
name: dsl-vm-captcha-reverse-2026-07-05
description: Complete reverse-engineering analysis of a CAPTCHA system — JS frontend modules + DSL VM risk-control engine
metadata:
  type: project
  tags: [captcha, reverse, dsl-vm, wasm, frontend]
  date: 2026-07-05
  status: completed
---

# Complete Reverse Engineering of a CAPTCHA System

## Scenario
Goal: reverse-engineer a large CAPTCHA system in order to fully understand how it works and how its verification flow operates.

## Target Entities
- **nc.js** (72KB) — Webpack-bundled slider core (9 modules)
- **fireyejs.js** (583KB) — DSL VM interpreter (custom instruction set of 26 opcodes)
- **awsc.js** (9KB) — module loader
- **secaptcha.js** (72KB) — WASM compiled from C (emscripten)
- **et_f.js** (262KB) — another DSL VM-type file

## Validated Technical Approaches

### Approach A: Selenium + CDP Drag (Recommended)
Send native mouse events via CDP `Input.dispatchMouseEvent` and complete the verification in a real browser.
- Success rate: high
- Dependencies: Chrome + Selenium/Playwright

### Approach B: Playwright Headless Browser Runner
Load the DSL VM and the module loader inside Playwright and expose the token through an HTTP API.
- Success rate: medium (depends on the WASM initialization environment)

### Approach C: Pure requests Protocol Validation
Call the API endpoints directly through HTTP requests to complete verification.
- Success rate: **extremely low** (the token is tightly bound to browser TLS/IP/fingerprint)
- Not recommended

## Key Findings

1. **The token cannot be used outside the browser** — when a DSL VM-generated token is submitted, the server validates context consistency (TLS JA3, IP, Cookies, Referer, etc.)

2. **fireyejs.js is not a WASM binary but a DSL VM** — a custom virtual machine implemented in 583KB of pure JS that executes encoded instructions through an interpreter loop over 26 opcodes

3. **All 9 modules of nc.js are 100% reverse-engineered** — including API endpoints, slider UI, interaction logic, the ncSessionID algorithm, multi-language support, etc.

4. **The real WASM compilation artifact is secaptcha.js** — 72KB, using SharedArrayBuffer + Atomics, with C code compiled by emscripten

## Pitfalls

1. A test appkey does not trigger real verification; you must use the appkey from the real page
2. `initialize` returning a specific status code means slider mode; returning `success` is only a session-creation acknowledgement
3. JSONP request URL events in the performance log may be captured incompletely depending on how the script tag is injected
4. Exported function names do not exist in the DSL VM files (they are encoded by the VM); the real exports are exposed through the module registry

## Reusable Patterns

- **DSL VM reverse-engineering pattern**: `case extraction → opcode classification → constant table analysis → function tracing → export extraction`
- **Generic CAPTCHA system architecture**: `entry JS → module loader (WASM/DSL) → API communication layer → frontend UI → server-side verification`
- **CDP native event bypass**: `Input.dispatchMouseEvent` bypasses detection and is unrelated to WebDriver

## Toolchain

- Selenium + CDP: browser automation + native mouse events
- Playwright: headless browser + route interception
- Python requests: pure API calls (verification failed)
- Node.js + Playwright: Runner service

## File Structure

```
project_root/
├── slider_v3.py                # improved CDP drag version
├── protocol_v2.py               # pure protocol version (verification failed)
├── phase3_final.py              # complete Playwright capture
├── monitor_inject.js            # page monitoring Hook
├── runner/                      # Node.js Runner
├── captured_js/                 # captured JS files
├── hook_data/                   # data captured by the Hook
├── wasm_output/                 # WASM extraction output
└── COMPLETE_REVERSE_REPORT.md   # complete reverse-engineering report
```

## References

- [[dsl-vm-reverse]] — DSL VM reverse-engineering skill doc
