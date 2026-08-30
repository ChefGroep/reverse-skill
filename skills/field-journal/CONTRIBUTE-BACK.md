# Community Evolution: Contributing Experience to the Main Repository

## Mechanism

After you finish a project and generate a field-journal entry, the AI will ask:

```
✅ Experience recorded in field-journal/

📤 Contribute this experience to the community main repository?
- Data has been de-identified per the template requirements (domains/IPs/tokens/PII replaced)
- Only new files under field-journal/ will be submitted
- Your tool-index, scope, findings, and other private files will not be submitted
- After contributing, other users can reuse your experience

Reply "yes" to submit; reply "no" to skip.
```

## Contribution Flow

```text
1. The AI generates a field-journal entry (de-identified)
2. The AI asks the user whether to contribute
3. The user agrees → the AI performs these steps:
   a. Verify de-identification is complete (double-check no real domains/IPs/tokens)
   b. Check for duplicates against existing main-repo entries (read _index.md only, ~200 tokens)
   c. If not a duplicate → create a PR against the main repository
   d. PR title format: [field-journal] YYYY-MM-DD scenario type - keywords
4. GitHub Actions automatic review:
   - ✓ Only field-journal/*.md modified
   - ✓ No prompt-injection signatures
   - ✓ No un-de-identified API keys/tokens
   - ✓ No executable code
   - ✓ File size < 50KB
5. Review passes → auto-merge (no maintainer action needed)
6. Review fails → an automatic comment explains the reason; the PR stays open awaiting fixes
```

### Safeguards

| Threat | Protection |
|------|------|
| Modifying non-journal files | Actions checks a changed-files whitelist |
| Prompt injection | Regex detection of "ignore previous"/"you are now" and similar signatures |
| Malicious code disguise | Detects `#!/`, `import`, `exec(`, `eval(` etc. |
| Un-de-identified tokens | Regex detection of AWS key/npm token/GitHub token patterns |
| Junk data | 50KB per-file cap |
| Flood of junk PRs | GitHub's built-in rate limit + optional CODEOWNERS review |

## Technical Implementation

### Method 1: GitHub CLI (Recommended)

```bash
# 1. Fork the main repository (if not forked yet)
gh repo fork &lt;your-GitHub-username&gt;/&lt;repo-name&gt; --clone=false

# 2. Create the contribution branch locally
git checkout -b contribute/journal-YYYY-MM-DD-keyword

# 3. Add only the field-journal files
git add skills/field-journal/YYYY-MM-DD_*.md
git add skills/field-journal/_index.md

# 4. Commit
git commit -m "[field-journal] scenario type: keyword summary"

# 5. Push to the fork
git push origin contribute/journal-YYYY-MM-DD-keyword

# 6. Create the PR
gh pr create --repo &lt;your-GitHub-username&gt;/&lt;repo-name&gt; \
  --title "[field-journal] YYYY-MM-DD scenario type - keywords" \
  --body "## Contribution\n- Scenario: xxx\n- Keywords: xxx\n- De-identification confirmed: ✓\n\n## Data-safety statement\nThis entry was de-identified per the template requirements and contains no real target information."
```

### Method 2: Direct Push (If the User Has Write Access to the Main Repository)

```bash
git checkout -b contribute/journal-YYYY-MM-DD-keyword
git add skills/field-journal/YYYY-MM-DD_*.md
git add skills/field-journal/_index.md
git commit -m "[field-journal] scenario type: keyword summary"
git push origin contribute/journal-YYYY-MM-DD-keyword
gh pr create --repo &lt;your-GitHub-username&gt;/&lt;repo-name&gt; \
  --title "[field-journal] YYYY-MM-DD scenario type - keywords" \
  --body "De-identification confirmed: ✓"
```

## Deduplication Rules (Low Token Cost)

Before submitting, the AI **only needs to read one file, `_index.md`**, for deduplication; there is no need to read the full content of every journal entry.

### Deduplication Flow

```text
1. Read the main repository's field-journal/_index.md (usually only a few dozen lines)
2. Extract this entry's: scenario category + keyword list
3. Search _index.md for existing entries in similar scenarios
4. Keyword matching:
   - Overlap ≥ 3 keywords → treated as duplicate; do not submit
   - Overlap 1-2 keywords → possibly a variant; may submit
   - No overlap → brand-new scenario; submit directly
```

### Why This Is Enough

- The `_index.md` format is fixed: `- [date] short name — keywords: k1, k2, k3`
- Each entry is a single line; 100 entries of experience is just 100 lines
- The AI only needs string matching; there is no need to understand the full content
- Token cost: reading _index.md ≈ 200-500 tokens (vs reading all journals ≈ 10000+ tokens)

### If _index.md Is Unavailable

If the main repository's _index.md cannot be fetched (network problems etc.), submit directly and let the main-repo maintainers deduplicate manually.

## Files Allowed for Submission

**Whitelist** (only these files may appear in the PR):
- `skills/field-journal/YYYY-MM-DD_*.md` (new experience entries)
- `skills/field-journal/_index.md` (index update)

**Blacklist** (must never appear in the PR):
- `tool-index.*` (contains local machine paths)
- `pentest-tools/templates/scope.md` (contains target information)
- `pentest-tools/templates/findings.md` (contains vulnerability details)
- `pentest-tools/templates/progress.md` (contains operation records)
- `.claude/` (user configuration)
- `.kiro/` (user configuration)
- Any `.env`, `*.key`, `*.pem` files

## De-identification Double-Check

Before submitting, the AI must scan the files to be submitted and confirm they contain none of:

- [ ] Real domains (other than `example.com`/`target.example.com`)
- [ ] Real IPs (other than `10.x.x.x`/`192.168.x.x`)
- [ ] Raw tokens/cookies/API keys
- [ ] Raw phone numbers/emails/usernames
- [ ] Company/product names (if the target is a bug bounty program)

If any item fails de-identification, stop the submission and prompt the user to fix it.

## Value to the User

- The experience you contribute helps other users avoid the same pitfalls
- The richer the main repository's field-journal, the smarter every user's AI becomes
- Your contribution is preserved in _index.md (anonymized; only the scenario and keywords)
