param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$manager = Join-Path $repoRoot '.bonaqu\tools\Bonaqu-Profile-Manager.ps1'
$profiles = Join-Path $repoRoot 'Profiles'
$client = Join-Path $repoRoot 'BonaquClient.exe'
$junctionTarget = Join-Path $repoRoot 'ProfileManagerTestTarget'

function Invoke-Manager {
    param([string[]]$Arguments = @())

    $output = @(
        & (Join-Path $PSHOME 'pwsh.exe') -NoProfile -NonInteractive -ExecutionPolicy Bypass -File $manager @Arguments 2>&1
    )
    [pscustomobject]@{
        ExitCode = $LASTEXITCODE
        Output = ($output | Out-String).Trim()
    }
}

function Remove-TestPath {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return
    }

    for ($attempt = 1; $attempt -le 20; $attempt++) {
        try {
            $item = Get-Item -LiteralPath $Path -Force
            $isReparsePoint = (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
            if ($item.PSIsContainer -and -not $isReparsePoint) {
                Remove-Item -LiteralPath $Path -Recurse -Force -ErrorAction Stop
            } else {
                Remove-Item -LiteralPath $Path -Force -ErrorAction Stop
            }
            return
        } catch {
            if ($attempt -eq 20) {
                throw
            }
            Start-Sleep -Milliseconds 100
        }
    }
}

function Assert-Succeeds {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [string[]]$Arguments = @()
    )

    $result = Invoke-Manager -Arguments $Arguments
    if ($result.ExitCode -ne 0) {
        throw "$Name failed with exit code $($result.ExitCode): $($result.Output)"
    }
    Write-Host "[PASS] $Name"
}

function Assert-FailsLike {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [Parameter(Mandatory = $true)][string]$Pattern
    )

    $result = Invoke-Manager -Arguments $Arguments
    if ($result.ExitCode -eq 0) {
        throw "$Name unexpectedly succeeded."
    }
    if ($result.Output -notmatch $Pattern) {
        throw "$Name failed for the wrong reason. Output: $($result.Output)"
    }
    Write-Host "[PASS] $Name"
}

try {
    if (-not (Test-Path -LiteralPath $manager -PathType Leaf)) {
        throw "Profile Manager script was not found at $manager."
    }

    foreach ($path in @($profiles, $client, $junctionTarget)) {
        if (Test-Path -LiteralPath $path) {
            Remove-TestPath -Path $path
        }
    }

    Assert-Succeeds -Name 'Empty profile list' -Arguments @('-List')

    Assert-FailsLike -Name 'Reject single dot' -Arguments @('.') -Pattern 'Dot path segments'
    Assert-FailsLike -Name 'Reject parent dot segment' -Arguments @('..') -Pattern 'Dot path segments'
    Assert-FailsLike -Name 'Reject trailing-dot profile name' -Arguments @('Work.') -Pattern 'must not end with a dot'
    Assert-FailsLike -Name 'Reject reserved CON name' -Arguments @('CON') -Pattern 'reserved device name'
    Assert-FailsLike -Name 'Reject reserved device stem with extension' -Arguments @('nul.test') -Pattern 'reserved device name'
    Assert-FailsLike -Name 'Reject slash/path traversal syntax' -Arguments @('Bad/Name') -Pattern 'Use only English letters'
    Assert-FailsLike -Name 'Reject overlong profile name' -Arguments @(('a' * 49)) -Pattern 'Use only English letters'

    Remove-TestPath -Path $profiles
    Set-Content -LiteralPath $profiles -Value 'not a directory'
    Assert-FailsLike -Name 'Reject Profiles root that is a file' -Arguments @('-List') -Pattern 'Profiles root exists but is not a directory'
    Remove-TestPath -Path $profiles

    New-Item -ItemType Directory -Path $junctionTarget | Out-Null
    New-Item -ItemType Junction -Path $profiles -Target $junctionTarget | Out-Null
    Assert-FailsLike -Name 'Reject junction Profiles root' -Arguments @('-List') -Pattern 'must not be a symbolic link or junction'
    Remove-TestPath -Path $profiles
    Remove-TestPath -Path $junctionTarget

    New-Item -ItemType Directory -Path $profiles | Out-Null
    Copy-Item -LiteralPath (Join-Path $env:WINDIR 'System32\where.exe') -Destination $client

    New-Item -ItemType Directory -Path $junctionTarget | Out-Null
    New-Item -ItemType Junction -Path (Join-Path $profiles 'Alias') -Target $junctionTarget | Out-Null
    Assert-FailsLike -Name 'Reject junction profile directory' -Arguments @('Alias') -Pattern 'must not be a symbolic link or junction'
    Remove-TestPath -Path (Join-Path $profiles 'Alias')
    Remove-TestPath -Path $junctionTarget

    Assert-Succeeds -Name 'Create safe profile' -Arguments @('Work-1.2')
    if (-not (Test-Path -LiteralPath (Join-Path $profiles 'Work-1.2') -PathType Container)) {
        throw 'Safe profile was not created under the Profiles root.'
    }
    Write-Host '[PASS] Safe profile stayed under Profiles root'
} finally {
    foreach ($path in @($profiles, $client, $junctionTarget)) {
        if (Test-Path -LiteralPath $path) {
            Remove-TestPath -Path $path
        }
    }
}
