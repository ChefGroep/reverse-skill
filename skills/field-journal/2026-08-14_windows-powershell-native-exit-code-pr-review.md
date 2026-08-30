# 2026-08-14 Windows PowerShell Native Command Exit Code PR Review

## Scenario Classification

Other (toolchain, supply-chain bootstrap scripts, open PR review)

## Target Overview

Evaluate a bootstrap-script PR with a pinned source and commit, and verify that under Windows PowerShell 5.1 it stays fail-closed without falsely rejecting legitimate checkouts.

## Scope Summary (sanitized)

- auth_basis: repository maintainer authorized reviewing a public PR and submitting a review
- network_profile: public code-hosting platform; read-only during the evidence-gathering stage, review submitted after conclusions confirmed
- asset_types: [public source code, CI results, Windows PowerShell bootstrap scripts]

## Roles

- lead_role: lead
- specialists: [supply-chain-reviewer, windows-compatibility-reviewer]

## Full Execution Chain

1. Pin the PR head commit; read the changes, discussion, CI, and target script to avoid reviewing a moving target.
2. Split the security goals into six items: source pinning, commit pinning, atomic replacement, dirty-directory rejection, lockfile installation, and platform compatibility.
3. Confirm the design direction holds for a single-source manifest, staged checkout, dirty-tree fail-closed, and frozen lockfile.
4. Locate the checkout verification function; execute the native command and the piped version with `Select-Object` separately under Windows PowerShell 5.1.
5. Observe that both executions return the same commit text, but the piped version reads a `$LASTEXITCODE` of `-1`, causing legitimate checkouts to be falsely rejected.
6. Run the supply-chain test script; confirm the failure happens before the expected dirty-tree assertion, ruling out the test fixture itself.
7. Submit a changes-requested review on the PR: save the native command's exit code before processing output, and add Windows PowerShell 5.1 verification.
8. Write the reproduction method and review criteria back in sanitized form for reuse in later PowerShell bootstrap-script reviews.

## Evidence Chain Summary (sanitized)

| E-id | severity | status | source_type | Reusable command pattern | Related Finding |
|------|----------|--------|-------------|----------------|--------------|
| E-001 | info | observed | command | `powershell.exe -NoProfile -Command "& git -C {install_dir} rev-parse HEAD; $LASTEXITCODE"` | F-001 |
| E-002 | medium | validated | command | `powershell.exe -NoProfile -Command "& git -C {install_dir} rev-parse HEAD \| Select-Object -First 1; $LASTEXITCODE"` | F-001 |
| E-003 | medium | validated | command | `powershell.exe -NoProfile -File skills/scripts/tests/test-bootstrap-supply-chain.ps1` | F-001 |

## Finding / Path Summary

- top_finding: In Windows PowerShell 5.1, after native command output is fed into an object pipeline, reading `$LASTEXITCODE` may yield `-1`; even when the output commit matches the pinned value exactly, a false checkout verification failure is triggered.
- path_type: callflow
- path_one_liner: `git rev-parse` succeeds → output enters `Select-Object` → `$LASTEXITCODE` is overwritten → legitimate checkout falsely rejected by the fail-closed branch

## Pitfall Log

| Problem | Cause | Solution | Time |
|------|------|---------|------|
| All existing CI passes yet Windows still regresses | CI covers newer PowerShell and Bash, but not the native-command pipeline semantics of Windows PowerShell 5.1 | Run the minimal repro and the full supply-chain test with `powershell.exe` | ~20 min |
| Commit text identical yet judged inconsistent | The verification logic depends on both the output and a deferred read of `$LASTEXITCODE` | Save the exit code immediately after the native command returns, then normalize the output separately | ~10 min |
| PR shows clean, easily mistaken as directly mergeable | `mergeable` only reflects Git merge status; it does not prove target-runtime compatibility | Treat base freshness, platform matrix, and local reproduction as independent gates | ~5 min |

## Toolchain Findings

- The GitHub API is well suited to pinning PR heads and reading CI and review status; review records should be bound to the verified commit.
- `powershell.exe` and `pwsh` are not interchangeable test hosts. Scripts targeting Windows PowerShell 5.1 must be tested under the matching host.
- `$LASTEXITCODE` is mutable session state; any subsequent pipeline or command can make a deferred read lose the native command's semantics.

## Key Code/Commands

```powershell
# Capture the native command's output first, and save the exit code immediately.
$output = & git -C $CheckoutPath rev-parse HEAD 2>$null
$gitExitCode = $LASTEXITCODE
$resolvedCommit = [string]($output | Select-Object -First 1)

if ($gitExitCode -ne 0 -or $resolvedCommit.Trim() -ne $PinnedCommit) {
    throw "Checkout verification failed"
}
```

## Improvement Suggestions for This Package

- Add a `powershell.exe` 5.1 test job for PRs that modify PowerShell bootstrap scripts, so coverage doesn't come only from `pwsh`.
- Add "was the native command's exit code saved before the next command?" to the supply-chain review checklist.
- Before merging, check the PR head, the latest diff against main, and target-platform tests together; don't substitute GitHub's clean status for runtime verification.

## Reusable Patterns/Script Snippets

Apply a three-step pattern to every PowerShell native command: execute and capture the output, immediately save `$LASTEXITCODE`, and only then parse the output through PowerShell pipelines. Error decisions may use only the saved exit code.

## Evolution Actions

- [ ] Updated routing matrix
- [ ] Updated tool-index
- [ ] Updated bootstrap-manifest
- [ ] Updated sub-skill docs
- [x] Added pitfalls record
- [ ] No update needed

## Environment Info

- OS: Windows
- Tool versions: Windows PowerShell 5.1, Git 2.x
- Target platform/version: PowerShell-compatible bootstrap script, public PR head commit

## Sanitization Check

- [x] No real domains, IPs, credentials, tokens, cookies, or PII
- [x] Local install paths replaced with `{install_dir}`
- [x] No user project files or private repository content attached

---
<!-- [Evolution stats] Package cumulative completed items: 18 | New patterns this run: 1 | Toolchain issues fixed this run: 0 -->
<!-- [Community contribution] The user has authorized writing this sanitized lesson back via a separate PR. -->
