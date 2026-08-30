#Requires -Version 5.1
# Generates skills/INDEX.md: extracts name+description from each module SKILL.md frontmatter to build the navigation index.
# Idempotent: repeated runs produce identical output (CI verifies with git diff to prevent drift).
# Usage:
#   powershell -NoProfile -ExecutionPolicy Bypass -File skills/scripts/extract-summaries.ps1
#   powershell -File skills/scripts/extract-summaries.ps1 -Check   # verify only, no write (CI mode; exit 1 on mismatch)
param(
    [switch] $Check
)
$ErrorActionPreference = 'Stop'

$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path }
$skillsRoot = Split-Path -Parent $scriptDir
$indexPath = Join-Path $skillsRoot 'INDEX.md'

# Scan module SKILL.md files tracked in the repo (excludes local ignored/private trees so clean clones and dev machines stay idempotent).
$skipDirs = @('ops', 'scripts', 'config', 'tests', 'field-journal', 'references')
$packageRoot = Split-Path -Parent $skillsRoot
$trackedSkillFiles = @()
$git = Get-Command git -ErrorAction SilentlyContinue
if ($git) {
    $trackedPaths = @(& $git.Source -C $packageRoot ls-files -- 'skills/**/SKILL.md')
    if ($LASTEXITCODE -eq 0) {
        $trackedSkillFiles = @($trackedPaths | ForEach-Object {
            $fullPath = Join-Path $packageRoot ($_ -replace '/', [IO.Path]::DirectorySeparatorChar)
            if (Test-Path -LiteralPath $fullPath -PathType Leaf) { Get-Item -LiteralPath $fullPath }
        })
    }
}
$candidateSkillFiles = if ($trackedSkillFiles.Count -gt 0) {
    $trackedSkillFiles
} else {
    @(Get-ChildItem -Path $skillsRoot -Recurse -Filter 'SKILL.md')
}
$skillFiles = $candidateSkillFiles | Where-Object {
    $rel = $_.FullName.Substring($skillsRoot.Length + 1)
    $rel -ne 'SKILL.md' -and -not ($skipDirs | Where-Object { $rel.StartsWith($_ + '\') -or $rel.StartsWith($_ + '/') })
} | Sort-Object { $_.FullName.Substring($skillsRoot.Length + 1) }

$rows = New-Object System.Collections.ArrayList
foreach ($sf in $skillFiles) {
    $rel = $sf.FullName.Substring($skillsRoot.Length + 1)
    # Support both Windows (\) and Linux/macOS (/) path separators
    $dir = $rel.Split(@('\', '/'))[0]
    $head = Get-Content -LiteralPath $sf.FullName -TotalCount 15 -Encoding UTF8
    $name = ''; $desc = ''; $blockMode = $false; $inFm = $false
    foreach ($line in $head) {
        if ($line -match '^---') {
            if ($inFm) { break }   # the second --- closes the frontmatter
            $inFm = $true; continue
        }
        if (-not $inFm) { continue }
        if ($line -match '^name:\s*(.+)$') { $name = $Matches[1].Trim(); continue }
        if ($line -match '^description:\s*\|') { $blockMode = $true; continue }
        if ($line -match '^description:\s*(.+)$') { $desc = $Matches[1].Trim(); continue }
        if ($blockMode) {
            # YAML block: join indented text lines (take the first line, truncate when too long)
            if ($line -match '^\s{2,}(.+)$') {
                if (-not $desc) { $desc = $Matches[1].Trim() }
            } elseif ($line -match '^\S') { $blockMode = $false }
        }
    }
    if (-not $name) { $name = $dir }
    if (-not $desc) { $desc = '(no summary)' }
    if ($desc.Length -gt 160) { $desc = $desc.Substring(0, 157) + '...' }
    [void]$rows.Add([pscustomobject]@{
        Dir  = $dir
        Name = $name
        Desc = $desc
        Path = $rel
    })
}

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('# reverse-skill Skill Navigation Index')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('> This file is generated automatically by `skills/scripts/extract-summaries.ps1`; **do not edit by hand**.')
[void]$sb.AppendLine('> To change a summary, edit the frontmatter `description` of the matching module `SKILL.md`, then rerun the script.')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Module Overview')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('| Module | Summary |')
[void]$sb.AppendLine('|------|------|')
foreach ($r in $rows) {
    $esc = $r.Desc -replace '\|', '\|'
    [void]$sb.AppendLine(("| [{0}]({1}) | {2} |" -f $r.Name, ($r.Path -replace '\\', '/'), $esc))
}
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Directory Tree')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('```')
foreach ($r in $rows) {
    [void]$sb.AppendLine(("skills/{0}/" -f ($r.Path -replace '\\', '/')))
}
[void]$sb.AppendLine('```')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('## Routing')
[void]$sb.AppendLine('')
[void]$sb.AppendLine('PRIMARY routing is driven by `skills/config/routing.json` (single source of truth); triage with `master-route.ps1 -Hint "<task>"`.')
[void]$sb.AppendLine('For ambiguous cases read the full matrix in `skills/routing.md`; multi-type CTF tasks go through `CTF-Sandbox-Orchestrator/`.')

$newContent = $sb.ToString()
# Normalize to LF line endings: matches .gitattributes (*.md eol=lf) so -Check stays idempotent after clone
$newContent = $newContent -replace "`r`n", "`n"
$utf8 = New-Object System.Text.UTF8Encoding $true

if ($Check) {
    if (-not (Test-Path -LiteralPath $indexPath)) {
        Write-Host '[CHECK] INDEX.md missing' -ForegroundColor Red
        exit 1
    }
    # Line-ending immunity: on autocrlf=true machines the worktree may be CRLF; normalize before comparing
    $old = ([System.IO.File]::ReadAllText($indexPath)) -replace "`r`n", "`n"
    if ($old -eq $newContent) {
        Write-Host '[CHECK] INDEX.md up to date' -ForegroundColor Green
        exit 0
    }
    Write-Host '[CHECK] INDEX.md out of date (run extract-summaries.ps1)' -ForegroundColor Red
    exit 1
}

[System.IO.File]::WriteAllText($indexPath, $newContent, $utf8)
Write-Host ("INDEX.md regenerated: {0} modules" -f $rows.Count) -ForegroundColor Green
