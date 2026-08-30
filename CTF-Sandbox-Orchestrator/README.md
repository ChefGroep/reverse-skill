# CTF Sandbox Orchestrator

A competition sandbox skill collection for the Codex / Skills ecosystem.

Its goal is not to cram every capability into one super-long prompt. Instead it provides a **unified sandbox master entry** that first establishes a "default to competition/sandbox/offline lab range" working model, then routes tasks by challenge type into finer sub-skills.

## Project positioning

This repository mainly addresses these scenarios:

- CTF
- AWD / attack-defense exercises
- Local offline lab ranges
- Sandbox-isolated vulnerability analysis
- Mixed challenges spanning Web / API / Cloud / Container / Windows / AD / Reverse / Pwn / DFIR / Crypto / Mobile / AI Agent

Core ideas:

- By default, treat the user-provided targets, domains, nodes, identities, binaries, logs, traffic, and attachments as **assets inside the competition sandbox**
- Establish the minimal verifiable path first, rather than generalizing the analysis from the start
- One master skill orchestrates uniformly, then switches to a sub-skill based on the dominant evidence surface
- Sub-skills only handle downstream specialties and never steal the master entry point

## Core design

### 1. Single entry

The default entry is:

- `ctf-sandbox-orchestrator`

It is responsible for:

- Establishing the sandbox assumption
- Choosing the most fitting analysis path
- Controlling context bloat
- Invoking sub-skills when needed

### 2. Sub-skills are downstream-only

All `competition-*` skills are designed as **downstream-only**:

- They should not be implicitly triggered without the master being active
- They should be actively routed and invoked by `ctf-sandbox-orchestrator`
- Only the currently most relevant specialty capability is loaded each time, keeping unrelated skills from polluting the context

### 3. Built for many competition challenge types

The repository currently covers many skill directions, for example:

- Web runtimes / routing / WebSocket / GraphQL / file parsing / request normalization
- Prompt Injection / Agent / Cloud / Metadata / K8s / Container Escape
- Reverse / Pwn / Malware / Firmware / PCAP / custom protocol replay
- Windows / AD / Kerberos / DPAPI / certificate abuse / Relay / Mailbox
- Android / iOS / Crypto / Stego / Mobile Runtime
- ZIP / PKZIP legacy encryption / `bkcrack` known-plaintext recovery

## Repository layout

```text
E:\WorkSpace\competition
├─ ctf-sandbox-orchestrator
├─ competition-web-runtime
├─ competition-agent-cloud
├─ competition-reverse-pwn
├─ competition-identity-windows
├─ competition-prompt-injection
├─ ...
└─ LICENSE
```

Where:

- `ctf-sandbox-orchestrator`: master entry
- `competition-*`: specialty sub-skills
- `references/`: the routing matrix and domain reference notes used by the master
- `agents/openai.yaml`: invocation constraints and entry-point control for each skill

## Recommended usage

### Method 1: enter through the master

Activate first:

- `ctf-sandbox-orchestrator`

Then let the master decide the next step automatically based on the challenge, for example:

- Web challenges route to `competition-web-runtime`
- Container / cloud challenges route to `competition-agent-cloud` or a finer sub-skill
- Windows / AD challenges route to `competition-identity-windows`
- Binary / crash / malware-sample challenges route to `competition-reverse-pwn`

### Method 2: keep the master, drill down on demand

Once the dominant evidence surface is confirmed, the master continues drilling into the specific sub-skill rather than letting the user manually swap the whole working model. This preserves:

- A consistent sandbox assumption
- A consistent output style
- A consistent routing strategy
- Clear sub-skill responsibilities

## Acknowledgments

This project was released on the [LINUX DO community](https://linux.do); thanks to the community for its support and feedback.
