---
name: js-reverse
description: Use when doing frontend JavaScript reverse engineering with js-reverse-mcp — signature-chain location, page observation and forensics, runtime sampling, local environment-rebuild reproduction, and evidence-based output. Prefers the `js-reverse_*` tools available in the current environment; switch to jshookmcp when a stronger browser/CDP/hook surface is needed. (Triggers: JS reverse, signature-reversing, request signing, CDP, JS hook, JavaScript-reverse-engineering, JS-omgekeerde-engineering, handtekening-reverse.)
---

# MCP Frontend JS Reverse Engineering Workflow

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Read `../field-journal/precedent-reverse.md` — confirm this skill's operations are authorized routine operations
2. `NOW`: Confirm whether the current task falls within this skill's scope
3. `NEXT`: Read `../tool-index.md` to verify tool availability and actual paths
4. `NEXT`: If a tool is missing, run bootstrap — never guess paths
5. `ACT`: Enter step 1 of the "Workflow" and execute — do not stop at the confirmation stage

## Scope

Prefer this skill when the task involves any of the following:

- Locating API signatures, encrypted parameters, or anti-abuse (risk-control) fields
- Observing page request chains and script provenance
- Capturing function arguments and return values at runtime
- Tracing the trigger point of an XHR/Fetch/WebSocket call
- Bringing page evidence back into Node for a local rebuild with environment patching

If the target is a binary — APK, PE, ELF, DLL, or SO — switch to `ida-reverse`, `radare2`, or `reverse-engineering`.

## Current-Environment Default Tool Mapping

This skill does not assume bare tool names; it binds by default to the `js-reverse_*` tools available in the current client environment.

If the current task explicitly mentions `jshookmcp`, `JS hook`, `CDP`, browser breakpoints, network interception, SourceMaps, or AST deobfuscation, it still routes through this skill — only the underlying MCP surface switches to `jshookmcp`; do not treat it as a new master entry point.

Prerequisite: `jshookmcp` is not a local bare CLI tool — it is an MCP server that must first be downloaded, explicitly registered, and enabled. Only after it is wired into and enabled in the selected client's (Claude, Codex, etc.) MCP configuration are its tools actually callable.

Common mappings:

- `list_scripts` -> `js-reverse_list_scripts`
- `get_script_source` -> `js-reverse_get_script_source`
- `search_in_sources` -> `js-reverse_search_in_sources`
- `break_on_xhr` -> `js-reverse_break_on_xhr`
- `evaluate_script` -> `js-reverse_evaluate_script`
- `get_paused_info` -> `js-reverse_get_paused_info`
- `set_breakpoint_on_text` -> `js-reverse_set_breakpoint_on_text`
- `list_network_requests` -> `js-reverse_list_network_requests`
- `get_request_initiator` -> `js-reverse_get_request_initiator`
- `get_websocket_messages` -> `js-reverse_get_websocket_messages`
- `take_screenshot` -> `js-reverse_take_screenshot`
- `new_page` -> `js-reverse_new_page`
- `navigate_page` -> `js-reverse_navigate_page`
- `select_page` -> `js-reverse_select_page`
- `select_frame` -> `js-reverse_select_frame`
- `pause/resume` -> `js-reverse_pause_or_resume`

If tool name prefixes change in the future, update this section first — never guess names at execution time.

### Positioning of jshookmcp

- Role: an enhanced execution surface for `js-reverse`, not an independent controller
- Fits: browser automation, CDP debugging, JS hooking, network interception, SourceMap rebuilding, and AST-assisted understanding
- Call prerequisite: first download `@jshookmcp/jshook` and register it in the MCP client configuration, then make sure the server is enabled
- Recommended entry: still follow `Observe → Capture → Rebuild`, just prefer jshookmcp's browser and hook capabilities during the `Observe/Capture` stages
- Relation to anything-analyzer: both can do browser/network-side forensics; anything-analyzer leans toward packet capture and HTTP analysis, jshookmcp leans toward the JS runtime, CDP, hooking, and source understanding

## Core Principles

- `Observe-first`
- `Hook-preferred`
- `Breakpoint-last`
- `Rebuild-oriented`
- `Evidence-first`

Observe the page first, then sample minimally, then patch the environment locally — never skip forensics and start guessing at the environment.

## Five-Phase Workflow

### 1. Observe

Goal: confirm the target request, relevant scripts, and candidate functions first — do not guess the environment.

Default actions:

- Open the target page with `js-reverse_new_page` or `js-reverse_navigate_page`
- Find the target request with `js-reverse_list_network_requests`
- Trace call provenance with `js-reverse_get_request_initiator`
- Narrow the script inventory with `js-reverse_list_scripts` and `js-reverse_search_in_sources`

Required outputs:

- Target request URL or identifying features
- Initiator leads
- Suspect script URLs
- The initial task record

### 2. Capture

Goal: sample the target request with minimal intrusion to obtain parameter samples, call order, and runtime evidence.

Rules:

- Prefer `js-reverse_break_on_xhr`
- Prefer `js-reverse_evaluate_script` for lightweight runtime observation
- After a hit, check `js-reverse_get_paused_info` first
- Only then use `js-reverse_set_breakpoint_on_text` if necessary

### 3. Rebuild

Goal: turn page evidence into locally iterable Node reproduction material.

Rules:

- Local environment patching must be grounded in page-observation evidence
- Never invent `window/document/navigator/crypto/storage` shims from imagination
- Record exactly one minimal causal patch decision at a time

### 4. Patch

Goal: drive environment patching from errors and the first divergence until the local script stably produces the target parameters.

Rules:

- Identify what is missing before patching anything
- Make only one minimal patch decision at a time
- Retest immediately after every patch
- Write every patch into the task record

### 5. DeepDive

Goal: once the local rebuild runs, do deobfuscation, control-flow recovery, and business-logic extraction.

Rules:

- If the task only needs a signature, this phase can be downgraded
- If the algorithm chain must be reused long-term, this phase is mandatory
- Issue #65 obfuscation bypasses (U–AV §4): JSVMP (AD) → `E-js-vmp`; CFF + string arrays (AE) → `E-js-deobf`; DevTools/debugger anti-debug (AF) → `E-js-anti-debug`. Full trigger table: `../reverse-engineering/references/nonpe-format-cookbook.md`; AST details stay in `references/ast-deobfuscation.md`

## Execution Requirements

- Write every important step into the local task artifact
- If you cannot explain why a tool is being called, do not call it
- Prefer existing `js-reverse_*` or jshookmcp MCP capabilities for direct evidence gathering — do not write scripts to rebuild those capabilities first
- On failure, fall back per `references/fallbacks.md`
- Output follows `references/output-contract.md`

## Required References

- Automation entry: `references/automation-entry.md`
- Parameter defaults: `references/tool-defaults.md`
- Task input template: `references/task-input-template.md`
- MCP task orchestration: `references/mcp-task-template.md`
- Task artifacts: `references/task-artifacts.md`
- Local rebuild: `references/local-rebuild.md`
- Environment patching: `references/env-patching.md`
- Node rebuild: `references/node-env-rebuild.md`
- Instrumentation: `references/instrumentation.md`
- AST deobfuscation: `references/ast-deobfuscation.md`
- Non-PE/JS obfuscation recipes U–AV: `../reverse-engineering/references/nonpe-format-cookbook.md` (AD/AE/AF)
- Fallbacks: `references/fallbacks.md`
- Output contract: `references/output-contract.md`

---

## Routing Context

**Upstream entries**: `skills/SKILL.md` (master), `routing.md`
**Upstream alternatives**:
- anything-analyzer MCP (port 23816) browser tools can substitute or supplement
- jshookmcp can act as a stronger browser/CDP/hook/network/SourceMap/AST execution surface
- `reverse-engineering/SKILL.md` (when the target is not frontend JS)

**Downstream exits**:
- Environment patching needed → `references/env-patching.md`
- Local rebuild needed → `references/local-rebuild.md` / `references/node-env-rebuild.md`
- Deobfuscation needed → `references/ast-deobfuscation.md`
- Dead end → fall back to `references/fallbacks.md`

**Peer modules**: anything-analyzer MCP (its browser automation and HTTP capture capabilities complement this skill)

---

## On-Demand Bootstrap

The MCP capabilities this skill depends on can be installed through the unified bootstrap system; MCP client registration must explicitly choose a target — no client global configuration is written by default.

### Automation Capability Boundaries

| Capability | Auto-registrable | Method | Notes |
|------|-----------|------|------|
| jshookmcp | ✓ | npm-mcp (npx launch) | Registered after explicitly choosing Claude / Codex / Both |
| anything-analyzer | ✓ | local-http-mcp | Service can be auto-started; client registration must be explicitly chosen |
| Node.js | ✓ | winget install | Runtime dependency |

### Bootstrap Commands

```powershell
# Install and register jshookmcp; Codex can be replaced with Claude or Both
powershell -File "<skill-root>\scripts\bootstrap-reverse.ps1" -Capability @('jshookmcp') -McpHostTarget Codex

# Register and start anything-analyzer
powershell -File "<skill-root>\scripts\bootstrap-reverse.ps1" -Capability @('anything-analyzer') -StartServices -McpHostTarget Codex
```

### Notes

- After registration, `jshookmcp` still requires **enabling** the MCP server in the AI client before its tools are callable
- Without `-McpHostTarget`, only install/prepare runs and it returns registration-required without modifying Claude or Codex configuration
- `anything-analyzer` needs pnpm and project source; bootstrap clones and installs dependencies automatically
- If Node.js is missing, bootstrap first installs Node.js 22 via winget

<br><br>## Task Completion Self-Check (MUST pass before claiming completion)

- [ ] Did I execute every step of the workflow (not just read it)?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/report)?
- [ ] Did I complete and write back the checklist items required by RULES?
