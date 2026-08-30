# IDA ↔ reverse-skill Integration (Portable)

This page contains generic steps and does not include any machine's absolute paths. The local readiness report stays at the repository root in `LOCAL-READINESS.md` (gitignored).

## Target Form

| Item | Convention |
|----|------|
| IDA install directory | Environment variable `IDADIR` (directory contains `ida.exe` or `ida.dll`) |
| HTTP MCP | `http://127.0.0.1:13337/mcp` |
| Client server name | Keep only **`idapro`** (do not also register `ida-pro-mcp`) |
| Startup | `scripts/start.ps1` (`--unsafe`, without `?ext=dbg`) |
| Opening | For large files prefer `scripts/open.ps1`; do not call `idb_open` directly via some clients |

Two MCP names pointing at the same 13337 register the tools twice and race the port with the idalib worker.

## Installation

```powershell
setx IDADIR "<your IDA install directory>"

# Must use mrexodia/ida-pro-mcp; do not install the PyPI ida-mcp
python -m pip install "git+https://github.com/mrexodia/ida-pro-mcp.git"

# Activate idalib (adjust the path to your local IDA)
python "<IDADIR>\idalib\python\py-activate-idalib.py" -d "<IDADIR>"

# Install plugin + client configuration
python -m ida_pro_mcp --install --transport streamable-http --scope global
```

## Startup and Keep-Alive

`type: http` MCP entries do not spawn the process for you. When 13337 is not listening, all clients report error.

| Script | Effect |
|------|------|
| `scripts/start.ps1` | If healthy `OK:<n>:reuse`; port listening but RPC timeout is treated as busy, never kill; replaces the managed supervisor only when nobody listens or `py_eval` is missing; never kill `ida.exe` |
| `scripts/watchdog.ps1` | Checks every minute; reuses when busy/healthy; only calls `start.ps1` when down/stale |
| `scripts/install-autostart.ps1` | Registers the scheduled task `reverse-skill-ida-mcp` (at login + every minute) |
| `scripts/start-gui.ps1` | Opens the GUI plugin when the idalib license fails |
| `scripts/open.ps1` | Calls `idb_open` via HTTP, bypassing some clients' schema validation |

Logs: `%LOCALAPPDATA%\reverse-skill\ida-mcp\supervisor.log` and `watchdog.log`.

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "skills\ida-reverse\scripts\start.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -File "skills\ida-reverse\scripts\open.ps1" -Path "C:\path\to\target.exe" -TimeoutSeconds 600
powershell -NoProfile -ExecutionPolicy Bypass -File "skills\ida-reverse\scripts\install-autostart.ps1"
```

When the GUI occupies 13337 but does not respond for a moment, `start.ps1` outputs `WARN:gui_busy` and exits, avoiding killing the IDA instance that is analyzing.

## Clients

All point to Streamable HTTP: `http://127.0.0.1:13337/mcp`, server name `idapro`.

You must start a new session after changing configuration. If the port is not listening at Cursor startup, bringing the service up afterwards will **not auto-reconnect**; refresh manually in the MCP panel.

## Known Caveats

1. System32 files: `open.ps1` copies to a temp path (output includes `(temp copy)`)
2. Do not call `idb_open` directly via some clients' MCP
3. `start.ps1` prefers `python -m ida_pro_mcp.idalib_supervisor`; more stable than `.cmd` wrappers
4. When the formal installation coexists with the desktop portable package, `IDADIR` is authoritative
5. Do not add `?ext=dbg` (debugger tools are not exposed by default)
