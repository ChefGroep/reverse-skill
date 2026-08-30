---
name: thick-client
description: Use for authorized security testing of desktop thick clients including local storage, update channels, IPC, traffic, and client-side trust boundaries.
---

# Thick Client Security Testing

## ACTION REQUIRED (execute immediately after reading)

1. `NOW`: read `../field-journal/precedent-pentest.md`
2. `NOW`: confirm the target is a **desktop thick client** (Win/macOS/Linux GUI or service companion), not pure web
3. `NOW`: case-init; record installer origin and test accounts in scope
4. `NEXT`: tools (Burp upstream proxy, process monitoring, RE tools)
5. `ACT`: trust boundary map → local surface → network surface → updates/supply chain

## Applicable Scenarios

- C/S architecture clients, Electron/Qt/.NET WinForms/WPF
- Local config/credential storage, IPC, named pipes
- Client-side enforcement bypass research (authorized)
- Auto-update channels and code-signing verification

## Workflow

### 1. Map the boundary

```text
□ Process tree, child processes, drivers/services
□ Listening ports and outbound domains
□ Local sensitive paths: %APPDATA%, Keychain, registry
```

### 2. Local attack surface

```text
□ Plaintext configs, hardcoded keys, debug switches
□ DLL hijacking / search order (Windows)
□ Database file (SQLite) permissions and encryption
□ IPC: who can connect? Is it authenticated?
```

### 3. Network surface

```text
□ System proxy / app-custom TLS
□ Certificate pinning → pair with mobile/js methodology or Frida
□ API authz abuse: admin interfaces hidden in the client
```

### 4. RE verification

```text
□ .NET → dotnet-reverse; native → ida/ghidra; Electron → asar + js-reverse
```

## Toolchain

| Tool | Purpose |
|------|------|
| Process Monitor / API Monitor | Behavior |
| Burp / mitmproxy | Traffic |
| dnSpy / IDA / Ghidra | Reverse engineering |
| Sysinternals | Windows surface |
| asar / nexe detection | Electron |

## References

- `references/thick-client-checklist.md`
- `../dotnet-reverse/` `../ida-reverse/` `../js-reverse/` `../api-security/`

## Routing Context

**Upstream**: MASTER R32  
**Downstream**: pure protocol `protocol-reverse`; supply-chain updates `supply-chain-security`

## Completion Self-Check

- [ ] Trust boundary mapped?
- [ ] Local + network surfaces covered?
- [ ] Checklist used?
