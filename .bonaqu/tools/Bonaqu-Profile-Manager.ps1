param(
    [Parameter(Position = 0)]
    [string]$ProfileName,

    [switch]$List,
    [switch]$OpenProfilesFolder
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
if (Split-Path -Leaf $root -eq 'tools') {
    # When launched from the repository tree.
    $root = Resolve-Path (Join-Path $root '..\..')
}

# In a packaged build the script is copied next to BonaquClient.exe.
$client = Join-Path $root 'BonaquClient.exe'
$profiles = Join-Path $root 'Profiles'

if (-not (Test-Path $profiles)) {
    New-Item -ItemType Directory -Path $profiles | Out-Null
}

if ($OpenProfilesFolder) {
    Start-Process explorer.exe -ArgumentList @($profiles)
    exit 0
}

$existing = @(
    Get-ChildItem -Path $profiles -Directory -ErrorAction SilentlyContinue |
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

if (-not (Test-Path $client)) {
    throw "BonaquClient.exe was not found next to the profile manager: $client"
}

$profilePath = Join-Path $profiles $ProfileName
if (-not (Test-Path $profilePath)) {
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
