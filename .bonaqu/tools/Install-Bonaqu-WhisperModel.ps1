param(
    [ValidatePattern('^[a-z0-9][a-z0-9._-]*$')]
    [string]$Model = 'base',
    [string]$DestinationDirectory = '',
    [switch]$List,
    [switch]$VerifyOnly,
    [switch]$Remove,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptRoot '..\..')).Path
$manifestPath = Join-Path $repoRoot '.bonaqu\local-transcription-models.json'
$defaultModelsRoot = Join-Path $repoRoot '.bonaqu\cache\local-transcription\models'

function Read-ModelManifest {
    if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
        throw "Model manifest was not found at $manifestPath."
    }

    $manifest = Get-Content -Raw -LiteralPath $manifestPath | ConvertFrom-Json
    if ($manifest.schema -ne 1) {
        throw "Unsupported model manifest schema '$($manifest.schema)'."
    }
    if ($manifest.source.repository -ne 'https://huggingface.co/ggerganov/whisper.cpp') {
        throw 'Unexpected model source repository.'
    }
    if ($manifest.source.revision -notmatch '^[0-9a-f]{40}$') {
        throw 'Model source revision must be a full immutable commit SHA.'
    }
    if ($manifest.worker.engine_commit -ne '233fe1fc9b48a09e361d3594520838ca266537fe') {
        throw 'Model manifest is not tied to the reviewed Bonaqu whisper.cpp engine commit.'
    }

    $seenIds = @{}
    foreach ($entry in $manifest.models) {
        $id = [string]$entry.id
        if ($id -notmatch '^[a-z0-9][a-z0-9._-]*$') {
            throw "Invalid model id '$id'."
        }
        if ($seenIds.ContainsKey($id)) {
            throw "Duplicate model id '$id' in the model manifest."
        }
        $seenIds[$id] = $true

        $filename = [string]$entry.filename
        if ([System.IO.Path]::GetFileName($filename) -ne $filename) {
            throw "Model '$id' contains an unsafe filename."
        }
        if ($entry.sha256 -notmatch '^[0-9a-f]{64}$') {
            throw "Model '$id' has an invalid SHA-256."
        }
        if ([int64]$entry.bytes -le 0) {
            throw "Model '$id' has an invalid byte size."
        }

        $uri = [Uri][string]$entry.url
        if ($uri.Scheme -ne 'https' -or $uri.Host -ne 'huggingface.co') {
            throw "Model '$id' must use an HTTPS huggingface.co URL."
        }
        $expectedPath = "/ggerganov/whisper.cpp/resolve/$($manifest.source.revision)/$filename"
        if ($uri.AbsolutePath -ne $expectedPath -or $uri.Query -or $uri.Fragment) {
            throw "Model '$id' URL must point exactly to its manifest filename at the pinned source revision."
        }
    }

    return $manifest
}

function Assert-ModelFile {
    param(
        [Parameter(Mandatory = $true)]$Entry,
        [Parameter(Mandatory = $true)][string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Model file is missing: $Path"
    }

    $file = Get-Item -LiteralPath $Path
    if ($file.Length -ne [int64]$Entry.bytes) {
        throw "Model '$($Entry.id)' size mismatch. Expected $($Entry.bytes) bytes, got $($file.Length)."
    }

    $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToLowerInvariant()
    if ($actual -ne [string]$Entry.sha256) {
        throw "Model '$($Entry.id)' SHA-256 mismatch. Expected $($Entry.sha256), got $actual."
    }
}

$manifest = Read-ModelManifest

if ($List) {
    $manifest.models |
        Select-Object id, name, filename, bytes, language_scope, recommended |
        Format-Table -AutoSize
    exit 0
}

$entry = $manifest.models | Where-Object { $_.id -eq $Model } | Select-Object -First 1
if (-not $entry) {
    $available = ($manifest.models.id -join ', ')
    throw "Unknown model '$Model'. Available models: $available"
}

if ([string]::IsNullOrWhiteSpace($DestinationDirectory)) {
    $DestinationDirectory = $defaultModelsRoot
} elseif (-not [System.IO.Path]::IsPathRooted($DestinationDirectory)) {
    $DestinationDirectory = Join-Path $repoRoot $DestinationDirectory
}

New-Item -ItemType Directory -Force -Path $DestinationDirectory | Out-Null
$destination = Join-Path $DestinationDirectory ([string]$entry.filename)

if ((Test-Path -LiteralPath $destination) -and
    -not (Test-Path -LiteralPath $destination -PathType Leaf)) {
    throw "Model destination exists but is not a regular file: $destination"
}

if ($Remove) {
    if (Test-Path -LiteralPath $destination -PathType Leaf) {
        Remove-Item -Force -LiteralPath $destination
        Write-Host "Removed Bonaqu model '$($entry.id)': $destination"
    } else {
        Write-Host "Bonaqu model '$($entry.id)' is not installed at $destination."
    }
    exit 0
}

if ($VerifyOnly) {
    Assert-ModelFile -Entry $entry -Path $destination
    Write-Host "Verified Bonaqu model '$($entry.id)': $destination"
    exit 0
}

if (Test-Path -LiteralPath $destination -PathType Leaf) {
    try {
        Assert-ModelFile -Entry $entry -Path $destination
        Write-Host "Bonaqu model '$($entry.id)' is already installed and verified: $destination"
        exit 0
    } catch {
        if (-not $Force) {
            throw "An existing model file failed verification. Re-run with -Force to replace it. $($_.Exception.Message)"
        }
    }
}

$partial = "$destination.part"
if (Test-Path -LiteralPath $partial) {
    if (-not (Test-Path -LiteralPath $partial -PathType Leaf)) {
        throw "Temporary model path exists but is not a regular file: $partial"
    }
    Remove-Item -Force -LiteralPath $partial
}

try {
    Write-Host "Downloading Bonaqu model '$($entry.id)' from immutable revision $($manifest.source.revision)..."
    Invoke-WebRequest -Uri ([string]$entry.url) -OutFile $partial
    Assert-ModelFile -Entry $entry -Path $partial
    Move-Item -Force -LiteralPath $partial -Destination $destination
} finally {
    if (Test-Path -LiteralPath $partial) {
        Remove-Item -Force -LiteralPath $partial
    }
}

Write-Host "Installed and verified Bonaqu model '$($entry.id)': $destination"
