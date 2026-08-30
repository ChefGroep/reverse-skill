---
name: browser-automation
description: |
  Unified automation entry. Covers browser automation (Playwright) and Windows desktop application automation (OpenReverse).
  Browser scenarios: open web pages, click, fill forms, scrape, screenshot, automated login, pentest page interaction.
  Desktop scenarios: operate GUI tools such as IDA/x64dbg, Windows UI Automation, vision-driven interaction, desktop application network capture.
  Trigger keywords: browser automation, desktop automation, open web page, fill form, scrape, screenshot, automated login, Playwright, agent-browser, headless, OpenReverse, UIA, CUA, desktop operation, Windows automation.
---

# Automated Operation (Desktop & Browser Automation)

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: Confirm whether the current task falls within this skill's scope
2. `NOW`: Read `../tool-index.md` and verify tool availability and real paths
3. `NEXT`: When a tool is missing, call bootstrap; never guess paths
4. `ACT`: Enter step 1 of the "Workflow" and execute; do not stop at confirmation state

## Scope

Use this skill when the task falls into the following scenarios:

### Browser scenarios (Playwright / agent-browser)
- Open web pages and operate page elements (click, fill, submit)
- Scrape page content or take screenshots
- Automate login flows
- Interact with web pages during penetration testing (submit payloads, trigger XSS)
- Automated handling of CAPTCHA pages
- Batch form submission

### Desktop application scenarios (OpenReverse)
- Operate Windows desktop applications (IDA Pro, x64dbg, Wireshark, etc.)
- Vision-driven interaction required (CUA mode)
- Structured UI operation required (UIA mode)
- Desktop application network traffic observation (built-in mitmproxy)
- GUI operation of automated reverse engineering tools
- Black-box testing of desktop software

### Division of Labor with Other Tools

| Scenario | What to Use |
|------|--------|
| Operate web pages (in browser) | **Playwright / agent-browser** |
| Operate desktop applications (Windows GUI) | **OpenReverse** |
| Packet analysis, HTTP request capture | anything-analyzer or OpenReverse network lane |
| JS breakpoints, hooks, CDP debugging | jshookmcp |
| Locate signing algorithms, reproduce JS environments | js-reverse |

Simple rule:
- Target is a web page → Playwright
- Target is a Windows desktop application → OpenReverse
- Both needed → combine them

---

## Part 1: Browser Automation (Playwright / agent-browser)

### Core Workflow

```bash
# 1. Open the page
agent-browser open <url>

# 2. Get interactive elements (returns @e1, @e2... references)
agent-browser snapshot -i

# 3. Operate elements by reference
agent-browser click @e1
agent-browser fill @e2 "text"

# 4. Close when done
agent-browser close
```

### Command Reference

```bash
# Navigation
agent-browser open <url>
agent-browser close

# Page snapshot
agent-browser snapshot        # full accessibility tree
agent-browser snapshot -i     # interactive elements only (recommended)

# Interactive operations
agent-browser click @e1
agent-browser fill @e2 "text"
agent-browser type @e2 "text"
agent-browser press Enter
agent-browser scroll down 500

# Get information
agent-browser get text @e1
agent-browser get title
agent-browser get url

# Waiting
agent-browser wait @e1
agent-browser wait 2000
agent-browser wait --load networkidle
```

### Notes
- Always run `agent-browser close`, otherwise the process leaks
- Take a snapshot before operating; never guess element references
- After submitting a form, use `wait --load networkidle` to let the page settle

---

## Part 2: Desktop Application Automation (OpenReverse)

### Overview

[OpenReverse](https://github.com/zhexulong/openreverse) is a desktop interaction and evidence collection framework for AI Agents, supporting:
- **UIA mode**: Windows UI Automation, structured desktop control operation
- **CUA mode**: vision-driven interaction (Computer Use Agent), suited to complex GUIs
- **Network observation**: built-in mitmproxy proxy + local capture

### Choosing the Interaction Mode

| Mode | Suited To | Underlying Layer |
|------|---------|------|
| UIA | Target application has standard Windows controls (buttons, text boxes, lists) | Windows UI Automation API |
| CUA | Target application UI is complex or non-standard (IDA's disassembly view, custom-rendered UIs) | Vision recognition + mouse & keyboard |

### Choosing the Network Observation Mode

| Mode | Suited To |
|------|---------|
| Proxy Lane | Target application can be configured with a proxy (recommended) |
| Local Lane | Target application cannot use a proxy and needs local capture |

### Installation & Configuration

```bash
# 1. Clone the project
git clone https://github.com/zhexulong/openreverse.git
cd openreverse

# 2. Install dependencies
npm install

# 3. Hook up the agent host (Claude Code / Codex / Zed)
npm run init:agents -- --target=all /path/to/project

# 4. Install the CUA runtime (if the vision-driven mode is needed)
npm run install:cua-runtime
npm run doctor:cua-runtime

# 5. Install network observation dependencies (if packet capture is needed)
npm run install:mitmproxy
npm run doctor:network
```

### Common Combinations

| Requirement | Configuration |
|------|------|
| Operate desktop applications only | UIA or CUA, no network lane |
| Operate desktop applications + packet capture | UIA/CUA + proxy lane |
| Operate desktop applications + local capture | UIA/CUA + local lane |

### Reverse Engineering Scenario Examples

```text
Scenario: automate IDA Pro for batch analysis

1. Open IDA Pro in OpenReverse CUA mode
2. Let the target binary load automatically
3. Wait for analysis to complete
4. Export the function list through UI operations
5. Simultaneously use the network lane to observe IDA's network behavior (e.g. Lumina requests)
```

```text
Scenario: automate x64dbg debugging

1. Start x64dbg in OpenReverse UIA mode
2. Load the target program
3. Set breakpoints
4. Run and observe register/memory changes
5. Take screenshots to preserve evidence
```

---

## On-Demand Bootstrap

### Automation Capability Boundaries

| Tool | Auto-installable | Install Method | Purpose |
|------|-----------|---------|------|
| Playwright | ✓ | npm + npx playwright install | Browser automation engine |
| agent-browser CLI | ✓ | npm install -g agent-browser | Browser operation CLI |
| Node.js | ✓ | winget | Prerequisite dependency |
| OpenReverse | ✗ | Manual clone + npm install | Experimental stage, heavy dependencies |
| mitmproxy | ✗ | Manual install | OpenReverse network observation dependency |

### Bootstrap Triggers

- Browser operation missing Playwright → bootstrap automatically
- Desktop operation needs OpenReverse → guide the user through manual installation (provide complete steps)

### OpenReverse Manual Installation Guide

If the AI detects a need for desktop application automation but OpenReverse is not installed:

```markdown
⚠️ **OpenReverse is required for desktop application automation**

**Installation steps**:
1. `git clone https://github.com/zhexulong/openreverse.git`
2. `cd openreverse && npm install`
3. `npm run init:agents -- --target=all <your project path>`
4. For vision mode: `npm run install:cua-runtime`
5. For network observation: `npm run install:mitmproxy`

**Verification**: `npm run doctor:cua-runtime` and `npm run doctor:network`
```

---

## Routing Context

**Upstream entries**: `skills/SKILL.md` (master), `routing.md`
**Applicable scenarios**: any task requiring automated operation of a browser or desktop application
**Downstream exits**:
- Captured requests needing analysis → `anything-analyzer` or `js-reverse`
- JS debugging/hooks needed → `jshookmcp`
- Signing algorithm recovery needed → `js-reverse`
- The desktop application is a reverse engineering tool → `ida-reverse/`

**Peer modules**: `js-reverse` (JS analysis may follow browser operations), `ida-reverse` (OpenReverse can automate the IDA GUI)


## Task Completion Self-Check (MUST pass before claiming completion)

- [ ] Did I execute every step of the workflow (rather than only reading)?
- [ ] Did I use real tool paths based on `tool-index`?
- [ ] Did I produce reproducible evidence (commands/scripts/screenshots/reports)?
- [ ] Did I complete and write back the checklist items required by RULES?
