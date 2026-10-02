param(
    [Parameter(Position = 0)]
    [string]$ProfileName,

    [switch]$List,
    [switch]$OpenProfilesFolder
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
if ((Split-Path -Leaf $root) -eq 'tools') {
    # When launched from the repository tree.
    $root = Resolve-Path (Join-Path $root '..\..')
}

# In a packaged build the script is copied next to BonaquClient.exe.
$client = Join-Path $root 'BonaquClient.exe'
$profiles = Join-Path $root 'Profiles'

if (-not (Test-Path -LiteralPath $profiles)) {
    New-Item -ItemType Directory -Path $profiles | Out-Null
}

$profiles = [System.IO.Path]::GetFullPath($profiles)
$profilesItem = Get-Item -LiteralPath $profiles -Force
if (-not $profilesItem.PSIsContainer) {
    throw "The Bonaqu Profiles root exists but is not a directory: $profiles"
}
if (($profilesItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
    throw 'The Bonaqu Profiles root must not be a symbolic link or junction.'
}

if ($OpenProfilesFolder) {
    Start-Process explorer.exe -ArgumentList @('"{0}"' -f $profiles)
    exit 0
}

$existing = @(
    Get-ChildItem -LiteralPath $profiles -Directory -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object -ExpandProperty Name
)

if ($List) {
    if ($existing.Count -eq 0) {
        Write-Host 'No Bonaqu profiles exist yet.'
    } else {
        $existing | ForEach-Object { Write-Host $_ }
    }
    exit 0
}

if (-not $ProfileName) {
    Write-Host ''
    Write-Host 'Bonaqu Client - Profile Manager'
    Write-Host '--------------------------------'
    if ($existing.Count -gt 0) {
        Write-Host 'Existing profiles:'
        for ($i = 0; $i -lt $existing.Count; $i++) {
            Write-Host ("  {0}. {1}" -f ($i + 1), $existing[$i])
        }
        Write-Host ''
    }
    $ProfileName = Read-Host 'Profile name (for example: Personal, Work, Alt)'
}

$ProfileName = $ProfileName.Trim()
if (-not $ProfileName) {
    throw 'Profile name cannot be empty.'
}
if ($ProfileName -notmatch '^[A-Za-z0-9._-]{1,48}$') {
    throw 'Use only English letters, digits, dot, underscore or hyphen (max 48 characters).'
}
if ($ProfileName -eq '.' -or $ProfileName -eq '..') {
    throw 'Dot path segments are not valid Bonaqu profile names.'
}

$deviceStem = ($ProfileName -split '\.', 2)[0]
if ($deviceStem -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') {
    throw "Windows reserved device name '$deviceStem' cannot be used as a Bonaqu profile."
}

$profilePath = [System.IO.Path]::GetFullPath((Join-Path $profiles $ProfileName))
$profileParent = [System.IO.Path]::GetDirectoryName($profilePath)
if (-not [string]::Equals(
        $profileParent,
        $profiles,
        [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Resolved profile path escaped the Bonaqu Profiles root.'
}

if (-not (Test-Path -LiteralPath $client -PathType Leaf)) {
    throw "BonaquClient.exe was not found next to the profile manager: $client"
}

if (Test-Path -LiteralPath $profilePath) {
    $profileItem = Get-Item -LiteralPath $profilePath -Force
    if (-not $profileItem.PSIsContainer) {
        throw "Profile path exists but is not a directory: $profilePath"
    }
    if (($profileItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Profile '$ProfileName' must not be a symbolic link or junction."
    }
} else {
    New-Item -ItemType Directory -Path $profilePath | Out-Null
    Write-Host "Created profile: $ProfileName"
}

Write-Host "Starting Bonaqu Client profile '$ProfileName'..."
$arguments = @(
    '-many',
    '-workdir',
    ('"{0}"' -f $profilePath),
    '-noupdate'
)
Start-Process -FilePath $client -WorkingDirectory $root -ArgumentList $arguments
