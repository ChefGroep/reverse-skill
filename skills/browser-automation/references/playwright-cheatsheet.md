# Browser & Desktop Automation Cheatsheet

> Covers common commands and patterns for Playwright (browser automation) and OpenReverse (Windows desktop automation).
> Aimed at penetration testing, reverse engineering, and automated collection scenarios.

---

## Playwright / agent-browser Command Cheatsheet

### Navigation & Lifecycle

```bash
# Open a page
agent-browser open "https://target.com/login"

# Wait for page load to complete
agent-browser wait --load networkidle

# Close the browser (must run, otherwise the process leaks)
agent-browser close
```

### Page Snapshots

```bash
# Full accessibility tree (for debugging)
agent-browser snapshot

# Interactive elements only (recommended; returns @e1, @e2... references)
agent-browser snapshot -i
```

### Element Interaction

```bash
# Click
agent-browser click @e1

# Fill a text box
agent-browser fill @e2 "admin"

# Type character by character (for inputs with JS listeners)
agent-browser type @e2 "password123"

# Keypress
agent-browser press Enter
agent-browser press Tab
agent-browser press Escape

# Scrolling
agent-browser scroll down 500
agent-browser scroll up 300
```

### Getting Information

```bash
# Get an element's text
agent-browser get text @e1

# Get the page title
agent-browser get title

# Get the current URL
agent-browser get url
```

### Waiting Strategies

```bash
# Wait for an element to appear
agent-browser wait @e1

# Wait a fixed time (milliseconds)
agent-browser wait 2000

# Wait for network idle
agent-browser wait --load networkidle

# Wait for navigation to complete
agent-browser wait --load domcontentloaded
```

---

## Common Pentest Patterns

### Automated Login

```bash
agent-browser open "https://target.com/login"
agent-browser snapshot -i
agent-browser fill @username "admin"
agent-browser fill @password "password123"
agent-browser click @login_button
agent-browser wait --load networkidle
agent-browser get url                    # confirm whether it redirected to the dashboard
```

### XSS Payload Injection

```bash
agent-browser open "https://target.com/search"
agent-browser snapshot -i
agent-browser fill @search_input "<script>alert(1)</script>"
agent-browser click @search_button
agent-browser wait --load networkidle
agent-browser snapshot                   # check whether the payload rendered
```

### Batch Form Submission (with a script)

```powershell
$payloads = @("' OR 1=1--", "<img src=x onerror=alert(1)>", "{{7*7}}")
foreach ($p in $payloads) {
    agent-browser open "https://target.com/form"
    agent-browser snapshot -i
    agent-browser fill @input "$p"
    agent-browser click @submit
    agent-browser wait --load networkidle
    agent-browser snapshot              # check the response
}
agent-browser close
```

### Cookie / LocalStorage Extraction

```bash
# Via the Playwright API (Node.js script mode)
# agent-browser does not expose cookies directly; use script mode
```

```javascript
// playwright-extract.js
const { chromium } = require('playwright');
(async () => {
    const browser = await chromium.launch();
    const context = await browser.newContext();
    const page = await context.newPage();
    await page.goto('https://target.com');
    
    // Extract cookies
    const cookies = await context.cookies();
    console.log(JSON.stringify(cookies, null, 2));
    
    // Extract localStorage
    const storage = await page.evaluate(() => JSON.stringify(localStorage));
    console.log(storage);
    
    await browser.close();
})();
```

### Screenshot Evidence

```bash
# agent-browser mode
agent-browser open "https://target.com/admin"
agent-browser wait --load networkidle
# Screenshot capability depends on the agent-browser version
```

```javascript
// playwright script mode
await page.screenshot({ path: 'evidence.png', fullPage: true });
```

---

## Playwright Node.js API Cheatsheet

### Basic Template

```javascript
const { chromium } = require('playwright');

(async () => {
    const browser = await chromium.launch({
        headless: true,           // headless mode
        // proxy: { server: 'http://127.0.0.1:8080' }  // route through Burp proxy
    });
    const context = await browser.newContext({
        ignoreHTTPSErrors: true,  // ignore certificate errors
        userAgent: 'Mozilla/5.0 ...',
    });
    const page = await context.newPage();
    
    await page.goto('https://target.com');
    // ... operations ...
    
    await browser.close();
})();
```

### Common Selectors

```javascript
// CSS selectors
await page.click('#login-btn');
await page.fill('input[name="username"]', 'admin');

// Text selectors
await page.click('text=Submit');
await page.click('button:has-text("Login")');

// XPath
await page.click('xpath=//button[@type="submit"]');

// Combined
await page.click('form >> input[type="submit"]');
```

### Network Interception

```javascript
// Intercept requests
await page.route('**/api/**', route => {
    console.log('API call:', route.request().url());
    route.continue();
});

// Modify requests
await page.route('**/api/auth', route => {
    route.continue({
        headers: { ...route.request().headers(), 'X-Admin': 'true' }
    });
});

// Intercept responses
await page.route('**/api/user', async route => {
    const response = await route.fetch();
    const json = await response.json();
    json.role = 'admin';  // tamper with the response
    route.fulfill({ response, json });
});
```

### Waiting & Assertions

```javascript
// Wait for elements
await page.waitForSelector('#result');
await page.waitForSelector('.error', { state: 'visible' });

// Wait for a network request
const [response] = await Promise.all([
    page.waitForResponse('**/api/login'),
    page.click('#login-btn'),
]);
console.log(response.status(), await response.json());

// Wait for navigation
await Promise.all([
    page.waitForNavigation(),
    page.click('a[href="/admin"]'),
]);
```

---

## OpenReverse Desktop Automation Cheatsheet

### Mode Selection

| Mode | Command Prefix | Suited To |
|------|---------|---------|
| UIA | `openreverse uia ...` | Standard Windows controls (buttons, text boxes, lists) |
| CUA | `openreverse cua ...` | Complex / non-standard GUIs (IDA disassembly view, custom-rendered UIs) |

### UIA Mode (Structured Control Operation)

```bash
# Launch the application
openreverse uia launch "C:\Tools\x64dbg\x64dbg.exe"

# Get the window tree
openreverse uia tree

# Click a button
openreverse uia click "Button:Open"

# Fill a text box
openreverse uia fill "Edit:FilePath" "C:\sample.exe"

# Select a menu
openreverse uia menu "File > Open"

# Get a control's text
openreverse uia get-text "Edit:Output"
```

### CUA Mode (Vision-Driven Interaction)

```bash
# Screenshot the current screen
openreverse cua screenshot

# Click at screen coordinates
openreverse cua click 500 300

# Double click
openreverse cua dblclick 500 300

# Type text
openreverse cua type "search string"

# Keypress
openreverse cua key "ctrl+g"    # IDA: Go to address
openreverse cua key "F5"        # IDA: Decompile
openreverse cua key "F9"        # x64dbg: Run
```

### Network Observation (mitmproxy)

```bash
# Start proxy-mode observation
openreverse network start --mode proxy --port 8888

# Start local capture mode
openreverse network start --mode local --filter "target.exe"

# Get captured requests
openreverse network list

# Export to HAR
openreverse network export har output.har

# Stop observation
openreverse network stop
```

---

## Reverse Engineering Tool Automation Combinations

### IDA Pro Automation (OpenReverse + ida-reverse)

```text
Scenario: batch-analyze multiple samples

1. openreverse cua launch "ida64.exe"
2. For each sample:
   a. openreverse cua key "ctrl+o"        # open file dialog
   b. openreverse uia fill "Edit:FileName" "sample_N.exe"
   c. openreverse uia click "Button:Open"
   d. Wait for analysis to finish (poll IDA's title bar)
   e. Extract results via the ida-reverse MCP tools
   f. openreverse cua key "ctrl+w"        # close the database
```

### x64dbg Automated Debugging

```text
Scenario: automated breakpoint setup and data collection

1. openreverse uia launch "x64dbg.exe"
2. openreverse cua key "F3"               # open file
3. openreverse uia fill "Edit:FileName" "target.exe"
4. openreverse uia click "Button:Open"
5. openreverse cua key "ctrl+g"           # Go to address
6. openreverse cua type "0x401000"
7. openreverse cua key "F2"               # set breakpoint
8. openreverse cua key "F9"               # run
9. openreverse cua screenshot             # screenshot to preserve state
```

---

## Troubleshooting

| Problem | Cause | Fix |
|------|------|------|
| agent-browser unresponsive | Process leak | `agent-browser close` first, then re-open |
| Element references stale | Page refreshed | Re-run `snapshot -i` to get fresh references |
| Form fill has no effect | JS listens on input events | Use `type` instead of `fill` |
| HTTPS certificate error | Self-signed certificate | Playwright: `ignoreHTTPSErrors: true` |
| Page load timeout | Slow network / heavy resources | Increase timeout or use `domcontentloaded` |
| UIA cannot find controls | Application uses owner-drawn controls | Switch to CUA mode |
| CUA clicks land offset | Resolution/DPI mismatch | Take a screenshot first to confirm coordinates |

---

## Installation & Dependencies

### Playwright

```powershell
# Install Node.js (if missing)
winget install OpenJS.NodeJS.LTS

# Install Playwright
npm install -g playwright
npx playwright install          # download the browser engine

# Install the agent-browser CLI
npm install -g agent-browser
```

### OpenReverse

```powershell
git clone https://github.com/zhexulong/openreverse.git
cd openreverse
npm install
npm run init:agents -- --target=all <project path>

# Optional: CUA runtime
npm run install:cua-runtime
npm run doctor:cua-runtime

# Optional: network observation
npm run install:mitmproxy
npm run doctor:network
```

---

## Related Resources

| Resource | Description | Link |
|------|------|------|
| Playwright official docs | API reference | https://playwright.dev/docs/intro |
| OpenReverse | Desktop automation framework | https://github.com/zhexulong/openreverse |
| mitmproxy | HTTP/HTTPS proxy | https://mitmproxy.org/ |
| Windows UI Automation | UIA documentation | https://learn.microsoft.com/en-us/windows/win32/winauto/entry-uiauto-win32 |
