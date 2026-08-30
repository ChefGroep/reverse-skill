#Requires -Version 5.1
# Lightweight scope gate before ACT. Exit 0 = ok, 2 = not ready, 1 = usage/error.
# Usage:
#   powershell -File skills/scripts/case-guard.ps1 -CaseRoot work\my-case
#   powershell -File skills/scripts/case-guard.ps1 -CaseRoot work\my-case -Force   # compatibility flag; never bypasses scope hard gates
param(
    [Parameter(Mandatory = $true)]
    [string] $CaseRoot,

    [switch] $Force,
    [switch] $Quiet
)
$ErrorActionPreference = 'Stop'

function Write-Info([string] $m) {
    if (-not $Quiet) { Write-Host $m }
}

if (-not (Test-Path -LiteralPath $CaseRoot)) {
    Write-Host ("ERROR: CaseRoot missing: {0}" -f $CaseRoot) -ForegroundColor Red
    exit 1
}

$scopePath = Join-Path $CaseRoot 'scope.md'
if (-not (Test-Path -LiteralPath $scopePath)) {
    Write-Host ("ERROR: scope.md missing under {0}" -f $CaseRoot) -ForegroundColor Red
    exit 1
}

$scope = Get-Content -LiteralPath $scopePath -Raw -Encoding UTF8
$issues = New-Object System.Collections.Generic.List[string]
. (Join-Path (Join-Path $PSScriptRoot 'lib') 'OwnInfra.ps1')

function Get-ScopeSection([string] $Text, [string] $Name) {
    $pattern = '(?ms)^##\s*' + [regex]::Escape($Name) + '\s*\r?\n(?<body>.*?)(?=^##\s|\z)'
    $match = [regex]::Match($Text, $pattern)
    if ($match.Success) { return $match.Groups['body'].Value }
    return ''
}

function Get-SectionField([string] $Section, [string] $Name) {
    $pattern = '(?m)^\s*-\s*' + [regex]::Escape($Name) + ':\s*(?<value>.*?)\s*$'
    $match = [regex]::Match($Section, $pattern)
    if ($match.Success) { return $match.Groups['value'].Value.Trim() }
    return ''
}

$authSection = Get-ScopeSection -Text $scope -Name 'auth'
$networkSection = Get-ScopeSection -Text $scope -Name 'network_profile'
$signoffSection = Get-ScopeSection -Text $scope -Name 'signoff'

# auth.status
$authGranted = (Get-SectionField -Section $authSection -Name 'status') -eq 'granted'
if (-not $authGranted) { [void]$issues.Add('auth.status is not granted') }

# network_profile.mode
$netMode = Get-SectionField -Section $networkSection -Name 'mode'
$allowedNetworkModes = @('offline', 'lab_only', 'authorized_target_only', 'unrestricted_lab')
if ([string]::IsNullOrWhiteSpace($netMode)) {
    [void]$issues.Add('network_profile.mode missing')
} elseif ($netMode -notin $allowedNetworkModes) {
    [void]$issues.Add("network_profile.mode is unsupported: $netMode")
} elseif ($netMode -eq 'offline') {
    # offline is only OK if a local/offline sample is referenced in assets/notes — soft cue check
    if ($scope -notmatch 'sample|offline.?path|local.?sample|\.apk\b|\.bin\b|\.exe\b') {
        [void]$issues.Add('network_profile.mode is offline without offline sample cue')
    }
}

# in_scope assets: only list items under "- assets:" inside ## in_scope
# Do NOT treat "- assets:" itself, ops_refs, or evidence_of_auth URLs as assets.
$hasAsset = $false
$inScopeSection = Get-ScopeSection -Text $scope -Name 'in_scope'
if ($inScopeSection -and $inScopeSection -match '(?ms)-\s*assets:\s*\r?\n(?<body>(?:\s+.+\r?\n?|\s+\r?\n?)*)') {
    $assetBody = $Matches['body']
    # Require indented list entries: "  - value" where value is not empty [] marker
    if ($assetBody -match '(?m)^\s+-\s+(?!\[\s*\])\S+') {
        $hasAsset = $true
    }
}
if (-not $hasAsset -and $netMode -ne 'offline') {
    [void]$issues.Add('in_scope.assets appears empty')
}

# own-infra defense-in-depth: a scope claiming the own-infra preset (or the
# own_infra auth basis) must list ONLY assets covered by the ownership
# allowlist. Hand-edited scopes are re-verified here (parity with case-guard.sh).
$presetField = (Get-SectionField -Section (Get-ScopeSection -Text $scope -Name 'meta') -Name 'preset').ToLowerInvariant()
$basisField = (Get-SectionField -Section $authSection -Name 'basis').ToLowerInvariant()
if ($authGranted -and ($presetField -in @('own-infra', 'chef-infra') -or $basisField -eq 'own_infra')) {
    $allowListPath = Join-Path (Split-Path -Parent $PSScriptRoot) (Join-Path 'config' 'own-infra.allowlist')
    if (-not (Test-Path -LiteralPath $allowListPath)) {
        [void]$issues.Add("own-infra scope: allowlist missing: $allowListPath")
    } else {
        $oiBody = $null
        if ($inScopeSection -match '(?ms)-\s*assets:\s*\r?\n(?<body>(?:.+\r?\n?)*)') { $oiBody = $Matches['body'] }
        if ($oiBody) {
            foreach ($line in ($oiBody -split "\r?\n")) {
                if ($line -match '^\s+-\s+(.+?)\s*$') {
                    $v = $Matches[1]
                    if ($v -and $v -ne '[]' -and -not (Test-OwnInfraHost -AllowListPath $allowListPath -HostOrIp $v)) {
                        [void]$issues.Add("own-infra scope: asset not in own-infra.allowlist: $v")
                    }
                }
            }
        }
    }
}

# ready_for_act
$ready = (Get-SectionField -Section $signoffSection -Name 'ready_for_act') -eq 'true'
if (-not $ready) { [void]$issues.Add('ready_for_act is not true') }

if ($issues.Count -eq 0) {
    Write-Info ("CASE-GUARD OK: {0}" -f $CaseRoot)
    exit 0
}

Write-Host ("CASE-GUARD NOT READY: {0}" -f $CaseRoot) -ForegroundColor Yellow
foreach ($i in $issues) { Write-Host (" - {0}" -f $i) -ForegroundColor Yellow }

if ($Force) {
    Write-Host 'CASE-GUARD: -Force does not bypass scope hard gates.' -ForegroundColor Yellow
}

Write-Host 'Fix scope (or re-run case-init -AuthGranted -TargetUrl ...).' -ForegroundColor Yellow
exit 2
