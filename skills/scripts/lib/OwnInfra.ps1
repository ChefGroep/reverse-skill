# Own-infra allowlist matcher (PowerShell parity of lib/own-infra-match.sh).
# Used by case-init.ps1 and case-guard.ps1 for the own-infra preset.
# Bash parity: skills/scripts/lib/own-infra-match.sh

function Test-IpInCidr {
    param([string] $Ip, [string] $Cidr)
    $parts = $Cidr -split '/'
    if ($parts.Count -ne 2) { return $false }
    $bits = 0
    if (-not [int]::TryParse($parts[1].Trim(), [ref]$bits)) { return $false }
    if ($bits -lt 0 -or $bits -gt 32) { return $false }
    $ipObj = $null
    $baseObj = $null
    if (-not [System.Net.IPAddress]::TryParse($Ip.Trim(), [ref]$ipObj)) { return $false }
    if (-not [System.Net.IPAddress]::TryParse($parts[0].Trim(), [ref]$baseObj)) { return $false }
    $ipBytes = $ipObj.GetAddressBytes()
    $baseBytes = $baseObj.GetAddressBytes()
    if ($ipBytes.Length -ne 4 -or $baseBytes.Length -ne 4) { return $false }
    $fullBytes = [math]::Floor($bits / 8)
    $remBits = $bits % 8
    for ($i = 0; $i -lt $fullBytes; $i++) {
        if ($ipBytes[$i] -ne $baseBytes[$i]) { return $false }
    }
    if ($remBits -gt 0) {
        $mask = [byte]((0xFF -shl (8 - $remBits)) -band 0xFF)
        if ((($ipBytes[$fullBytes]) -band $mask) -ne (($baseBytes[$fullBytes]) -band $mask)) { return $false }
    }
    return $true
}

function ConvertTo-OwnInfraHost {
    param([string] $Asset)
    if ([string]::IsNullOrWhiteSpace($Asset)) { return '' }
    $h = $Asset.Trim().ToLowerInvariant()
    $h = $h -replace '^[a-z0-9+.\-]+://', ''
    $h = ($h -split '@')[-1]
    $h = ($h -split '/')[0]
    $h = ($h -split '\?')[0]
    $h = ($h -split ':')[0]
    return $h.Trim('.')
}

function Test-OwnInfraHost {
    param([string] $AllowListPath, [string] $HostOrIp)
    $h = ConvertTo-OwnInfraHost -Asset $HostOrIp
    if (-not $h -or -not (Test-Path -LiteralPath $AllowListPath)) { return $false }
    $isIp = $h -match '^\d{1,3}(\.\d{1,3}){3}$'
    foreach ($raw in (Get-Content -LiteralPath $AllowListPath -Encoding UTF8)) {
        $entry = (($raw -split '#')[0]).Trim().ToLowerInvariant()
        if (-not $entry) { continue }
        if ($entry.StartsWith('cidr:')) {
            if ($isIp -and (Test-IpInCidr -Ip $h -Cidr $entry.Substring(5).Trim())) { return $true }
        } elseif ($isIp) {
            if ($h -eq $entry) { return $true }
        } else {
            if ($h -eq $entry -or $h.EndsWith('.' + $entry)) { return $true }
        }
    }
    return $false
}
