# Release Checklist

> Work through each item before every release. Version source of truth: the VERSION file must match the latest release version in CHANGELOG.md (the CI version-check job enforces this automatically; mismatches turn CI red).

## Release Steps

1. [ ] Confirm the CHANGELOG.md [Unreleased] section is complete (Keep a Changelog groups: Added / Fixed / Security / Removed)
2. [ ] Change ## [Unreleased] to ## [x.y.z] — YYYY-MM-DD, and update the compare link from ...HEAD to the new tag
3. [ ] Update the VERSION file to x.y.z in the same commit
4. [ ] For milestone versions (e.g. v1.0.0 / v1.1.0), also update docs/RELEASE_NOTES_v<x.y.z>.md
5. [ ] Tag the release: git tag v<x.y.z> + git push --tags
6. [ ] After pushing, confirm CI is fully green (routing 173 baseline + coherence + pin gate + version-check)

## Metadata Sync (Do While Releasing)

- Add/remove a bootstrap capability → sync the capability lists in RULES.md / skills/SKILL.md (skills/scripts/bootstrap-manifest.json is the single source of truth, currently 25 items)
- Add a field-journal entry → update the three sections of skills/field-journal/_index.md (scenario categories / high-frequency patterns / entity inverted index) plus the statistics
- Routing rule changes → edit only skills/config/routing.json (docs are maintained by the generator script or kept consistent manually)

> Note: the <!-- [evolution stats] --> cumulative comment at the bottom of journal entries is no longer maintained by hand (removed on 2026-08-10; the numbers could not be maintained reliably); counts are authoritative in _index.md.
