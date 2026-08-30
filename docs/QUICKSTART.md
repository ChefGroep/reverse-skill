# reverse-skill Quick Start and Community Issue Notes

## Project Positioning

`reverse-skill` is a collection of reverse-engineering and security-research skills, rules, and tool documents that AI clients can read — it is not a single executable application. Before using it, confirm that you have explicit authorization for the analysis target, or that you are working in a legitimate CTF, educational, or test environment.

## Basic Usage

Download the project first:

    git clone https://github.com/zhaoxuya520/reverse-skill.git
    cd reverse-skill

Then hand the project directory to your AI client as the workspace or document source. Core files include:

- `RULES.md`: general rules and safety boundaries.
- `skills/MASTER-ROUTING.md`: skill routing and task triage.
- `skills/*/SKILL.md`: skill notes for each specialist domain.
- `docs/platforms/`: tool installation notes for different operating systems.

This project stays client-neutral, so the actual loading procedure for OpenCode, Codex, Cursor, Claude Code, and other clients follows each client's official documentation; do not assume that one client's plugin or sync format applies to the others.

## OpenCode, Codex, and Sync Issues

If the client shows `Not Synchronizable` or fails to sync, first check that the workspace points at the full repository root, that file permissions allow reading, and that the client supports that directory format. The most reliable alternative is to open the repository directly in a local workspace and explicitly reference the required rule or skill files in the conversation. If the issue still reproduces, include the client version, operating system, full error message, and minimal reproduction steps when reporting it.

## AI Refusing to Handle an Analysis Request

An AI's safety policy does not automatically allow every operation just because a prompt says "I am authorized". Work only on legally authorized targets, and avoid requesting unauthorized intrusion, credential theft, persistence, or destructive operations; scope requests to code understanding, sample analysis, vulnerability patching, CTF play, or defensive verification. For a specific APK, website, or account, prepare a verifiable authorization scope and test environment first.

## Python Tools and uv

For standalone command-line tools, use:

    uv tool install PACKAGE_NAME

For project dependencies, use an isolated environment:

    uv venv
    uv pip install -r requirements.txt

Do not mechanically replace every `pip` string with `uv pip`; `python -m pip`, `pipx` bootstrap, and pre-existing virtual environments each serve different purposes. If `uv` is not installed yet, use the operating-system package manager or an explicitly created virtual environment, and never install security tools directly into the system-wide Python.

For more complete installation and archive-safety notes, see [Installation and Download Security Guidance](UV-AND-DOWNLOAD-SECURITY.md).

## ZIP Antivirus Flags and Download Safety

Reverse-engineering tools may contain binaries, debuggers, packed files, or test data that easily trigger antivirus heuristics. An antivirus warning proves neither safety nor malice. Do not disable antivirus software or blindly skip warnings.

Before opening an archive, download it from the expected HTTPS repository or release page, verify the checksum or release digest (if provided), inspect the archive contents, and scan it with up-to-date security software. Do not run unknown binaries, scripts, or installers found inside an archive just because the download succeeded.

## Accounts, Contributions, and Non-Specific Reports

Follow the terms of service of your AI client, GitHub, tool vendors, and the target environment. The repository itself cannot guarantee that third-party platforms will not restrict accounts, nor can it decide platform account policy. To contribute radare2 or other skills, read `skills/CONTRIBUTING.md` first and submit small, verifiable Pull Requests.

Only issues that include the full error message, environment information, and reproduction steps are suitable for further fixing. Reports that say only "virus", "gaha", or "test" should be amended with the file name, download URL, scanning product, version, and reproduction steps.
