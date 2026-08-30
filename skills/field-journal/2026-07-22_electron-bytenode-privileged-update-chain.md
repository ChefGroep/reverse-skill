# 2026-07-22 Electron Bytenode Privileged Update Chain Analysis

## Scenario Classification

Binary analysis / Electron / Bytenode / update chain security audit

## Target Overview

Completed a cross-layer reverse of a Windows x86 Electron desktop application — from the NSIS installer, ASAR, and Bytenode JSC through to the native game SDK and the remotely rendered pages — confirming the permission boundaries, IPC capabilities, and the update-package trust model.

## Complete Execution Chain

1. Performed SHA-256, Authenticode, manifest, sections, overlay, and mitigations checks on the outer PE of `{electron_app}`, confirming the installer type and elevation level.
2. Used 7-Zip to expand the NSIS read-only, locating the inner archive and rebuilding the file inventory; continued extracting the raw `app.asar`, preserving logical offsets, sizes, and per-file hashes.
3. Identified Electron 22.0.0, Node 16.17.1, and Bytenode 1.5.7 from `package.json`, runtime resources, and JSC strings; distinguished the raw extraction directory from the pre-existing modified directory.
4. Loaded `main.jsc` and `preload.jsc` using the sample's own Electron `ELECTRON_RUN_AS_NODE=1` mode, resolving the host Node/V8 ABI incompatibility.
5. Mocked Electron, network, file writes, archives, FFI, child processes, and exit in the probes; recorded window options, 21 main-process IPC handlers, 29 preload bridge members, and lifecycle callbacks.
6. Froze a static resource snapshot of `{remote_ui_domain}`, tracing how the `updateUrl` returned by `https://{update_api_domain}/api/user/v1/check_ver` enters the local `checkUpdates`.
7. Drove the update handler with a loopback HTTP fixture, confirming the URL reception, download, extraction, and detached updater launch sequence; recorded the absent whitelist, hash, package signature, and Authenticode verification respectively as "not observed in the controlled path".
8. Performed a static review of `{native_game_sdk}`'s exports, imports, strings, PE protections, signatures, and key addresses, distinguishing ABI forwarding, callback FIFOs, state watchdogs, and third-party platform installation branches.
9. Used "conditional capability" wording for services, drivers, hosts, root certificates, proxies, and platform registry operations; described capabilities only when call-chain evidence existed, and did not infer that this run had already executed them.
10. Produced the formal report, three data-flow diagrams, structured IOCs, reproduction commands, and an evidence index, and in the conclusions separated high-confidence static facts, controlled dynamic facts, and the remote snapshot's staleness boundary.

## Pitfall Records

| Problem | Cause | Solution | Time Spent |
|---|---|---|---|
| Host Node directly loading JSC failed | Bytenode bytecode binds a specific V8/Node ABI | Executed using the sample's own Electron RunAsNode mode | Medium |
| Timers and exit logic in the launch probe interfered with results | The main process contains lifecycle callbacks, watchdogs, and `process.exit` | Added `--run-timeouts`, mocking timers, exit, and the four app callback types | Medium |
| The update handler needed to simultaneously trigger network, disk-write, and child-process paths | Merely enumerating handlers only proves registration, not the data flow | Added the `--update-url` fixture, recording parameters and side effects across the full chain | Medium |
| The analysis directory contained pre-existing modified artifacts | Modified ASAR/JSC would pollute the raw conclusions | Treated only `{sample_dir}` and `{extracted_original_dir}` as raw evidence sources | Low |
| The status of dual-signed DLLs is easily misjudged | Each signature's certificate, timestamp, and current verification status may differ | Checked signature by signature with `signtool verify /pa /all /v` | Low |
| Native strings displayed high-privilege system capabilities | Strings and imports do not mean the current path was executed | Combined xref/call chains and labelled "conditional capability" | Medium |
| The remote UI changes constantly | The current chunks and API behavior are not permanently fixed assets | Saved dated resource snapshots, hashes, and fetch times | Low |

## Toolchain Findings

- The sample's own Electron is the most stable ABI container for executing Bytenode JSC; `ELECTRON_RUN_AS_NODE=1` runs probes without launching the business GUI.
- Electron module mocks need to cover `app.whenReady/on/quit`, `BrowserWindow`, `ipcMain.handle/on`, `shell`, `session`, and `webContents`, otherwise you only get an incomplete registration surface.
- Update chain verification should record the input URL, request library, target file, extraction directory, and final `spawn` parameters together, to build the renderer-to-updater evidence loop.
- PE signature audits should describe "certificate exists", "certificate within validity period", "has trusted timestamp", and "current chain verification succeeded" separately.
- For large third-party DLLs, first partition capabilities with imports/exports and strings, then do address-level review of high-risk branches like services, network, certificates, and process creation.

## Key Code/Commands

```powershell
$env:ELECTRON_RUN_AS_NODE = '1'
$env:__COMPAT_LAYER = 'RunAsInvoker'

& '{electron_exe}' '{probe_script}' '{main_jsc}' `
  --execute --exercise=all --run-timeouts --quiet `
  --out='{main_probe_json}'

& '{electron_exe}' '{probe_script}' '{main_jsc}' `
  --execute --exercise=all --run-timeouts `
  --update-url='http://127.0.0.1:{port}/update.zip' --quiet `
  --out='{update_probe_json}'

& '{electron_exe}' '{probe_script}' '{preload_jsc}' `
  --execute --exercise=bridge --quiet `
  --out='{preload_probe_json}'

signtool verify /pa /all /v '{native_game_sdk}'
```

## Improvement Suggestions for This Package

1. Add a Bytenode ABI decision tree in the Electron/JS reverse route: after host Node fails, prefer the target Electron's RunAsNode mode.
2. Add a generic Electron mock coverage matrix and an IPC registration/invocation consistency check script.
3. Fix checks in the updater audit template for URL constraints, transport protocol, manifest signature, package hash, signature chain, extraction traversal, and final execution parameters.
4. Add mandatory split columns in the report template for "conditional capability" and "observed behavior", reducing the risk of over-inference from imports/strings.

## Reusable Patterns/Script Fragments

1. **Three-layer trusted boundary**: raw installer -> raw ASAR/JSC -> remote page snapshot, establishing hashes and timestamps separately for each layer.
2. **Registration surface vs execution surface separation**: first enumerate IPC/preload APIs, then invoke high-risk handlers with mock fixtures and capture side effects.
3. **Update chain five-tuple**: `source URL -> downloader -> archive path -> extractor -> executable`, saving evidence at every node.
4. **Native capability grading**: imports/strings as clues, xref/call chains as capability evidence, and only real dynamic events as executed facts.
5. **Signature four-state model**: report signature existence, certificate validity, timestamp, and current trust verification separately.

## Evolution Actions

- [x] Added pitfalls records
- [x] Updated the experience index
- [ ] Updated the routing matrix
- [ ] Updated tool-index
- [ ] Updated bootstrap-manifest
- [ ] Updated the sub-skill docs

## Environment Info

- OS: Windows 11 x64
- Tool versions: Electron 22.0.0, Node 16.17.1, Bytenode 1.5.7, Python 3.12
- Target platform/version: Windows x86 / Electron desktop app

## De-identification Requirements

This article retains only generic versions, API path structures, orders of magnitude, and analysis methods. Sample name, publisher, real domains, case directories, hashes, configuration keys, tokens, and user identifiers have all been replaced or omitted; no sample files are attached.

---
<!-- [Community contribution] After finishing, ask the user whether to PR to the main repository. See CONTRIBUTE-BACK.md for the process -->