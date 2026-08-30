# 2026-08-08 Open PR Value Triage and Safe Integration

## Scenario Classification

Other / repository maintenance / contribution review

## Target Overview

Sync the upstream main line while preserving uncommitted work-tree content, review multiple open PRs, and safely integrate low-risk, high-reuse-value contributions into the local main line.

## Complete Execution Path

1. Check the remote, how far the branch is behind, and work-tree changes.
2. Isolate user changes with stash, fast-forward to the latest main line, then restore and verify.
3. Fetch open PR refs; compare commits, file scopes, and three-way merge results.
4. Classify contributions containing only redacted field-journal entries as low-risk candidates.
5. For core-script PRs, check conflicting files, change size, and duplicate implementations in the main line.
6. Merge the 4 journal PRs, correct the index uniformly, and run smoke and routing coherence.

## Pitfalls Record

| Issue | Cause | Solution |
|---|---|---|
| Pulling the main line overwrites local index changes | Upstream and the work tree both modify `_index.md` | Isolate with stash; restore after fast-forward |
| Index statistics of old PRs overwrite each other | Multiple PRs based on the same old baseline | After merging content files, recompute the index uniformly |
| A large PR looks high-value but cannot merge directly | The main line has evolved; the core script has content conflicts | Hold it; require a rebase and targeted testing |

## Reusable Patterns

- Layer by "documentation / executable code" first, then sort by reuse value, conflict surface, and test evidence.
- For journal-only PRs, separate content merging from index reconciliation.
- For core-infrastructure PRs, conflicts are not simple text problems; re-verify behavioral equivalence.

## Verification Results

- smoke: all passed.
- routing coherence: all passed.
- User work-tree content: fully restored, no conflicts.

## Redaction Review

Contains no credentials, private targets, user identities, or internal URLs.