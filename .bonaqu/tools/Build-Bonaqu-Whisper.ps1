param(
    [string]$OutputDirectory = '',
    [switch]$Clean
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$WhisperRepository = 'https://github.com/ggml-org/whisper.cpp.git'
$WhisperCommit = '233fe1fc9b48a09e361d3594520838ca266537fe'
$WhisperVersionLabel = '1.9.3-dev-bonaqu-pinned'

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = (Resolve-Path (Join-Path $scriptRoot '..\..')).Path
$cacheRoot = Join-Path $repoRoot '.bonaqu\cache\local-transcription'
$sourceRoot = Join-Path $cacheRoot 'whisper.cpp'
$buildRoot = Join-Path $cacheRoot 'build-whisper-cpu'

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $cacheRoot 'dist'
} elseif (-not [System.IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory = Join-Path $repoRoot $OutputDirectory
}

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [string]$WorkingDirectory = $repoRoot
    )

    Write-Host ('> ' + $FilePath + ' ' + ($Arguments -join ' '))
    $process = Start-Process -FilePath $FilePath -ArgumentList $Arguments -WorkingDirectory $WorkingDirectory -Wait -PassThru -NoNewWindow
    if ($process.ExitCode -ne 0) {
        throw "$FilePath failed with exit code $($process.ExitCode)."
    }
}

if ($Clean -and (Test-Path $cacheRoot)) {
    Remove-Item -Recurse -Force $cacheRoot
}

New-Item -ItemType Directory -Force -Path $cacheRoot | Out-Null

if (-not (Test-Path (Join-Path $sourceRoot '.git'))) {
    Invoke-Checked -FilePath 'git' -Arguments @(
        'clone',
        '--filter=blob:none',
        '--no-checkout',
        $WhisperRepository,
        $sourceRoot
    )
}

Invoke-Checked -FilePath 'git' -WorkingDirectory $sourceRoot -Arguments @(
    'fetch',
    '--depth', '1',
    'origin',
    $WhisperCommit
)
Invoke-Checked -FilePath 'git' -WorkingDirectory $sourceRoot -Arguments @(
    'checkout',
    '--detach',
    '--force',
    $WhisperCommit
)

$resolvedCommit = (& git -C $sourceRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or $resolvedCommit -ne $WhisperCommit) {
    throw "whisper.cpp source pin mismatch. Expected $WhisperCommit, got $resolvedCommit."
}

if (Test-Path $buildRoot) {
    Remove-Item -Recurse -Force $buildRoot
}
New-Item -ItemType Directory -Force -Path $buildRoot | Out-Null

Invoke-Checked -FilePath 'cmake' -Arguments @(
    '-S', $sourceRoot,
    '-B', $buildRoot,
    '-A', 'x64',
    '-D', 'BUILD_SHARED_LIBS=OFF',
    '-D', 'WHISPER_BUILD_TESTS=OFF',
    '-D', 'WHISPER_BUILD_SERVER=OFF',
    '-D', 'WHISPER_BUILD_EXAMPLES=ON',
    '-D', 'WHISPER_CURL=OFF',
    '-D', 'WHISPER_SDL2=OFF',
    '-D', 'GGML_CUDA=OFF',
    '-D', 'GGML_VULKAN=OFF'
)

Invoke-Checked -FilePath 'cmake' -Arguments @(
    '--build', $buildRoot,
    '--config', 'Release',
    '--target', 'whisper-cli',
    '--parallel'
)

$binary = Get-ChildItem -Path $buildRoot -Recurse -File -Filter 'whisper-cli.exe' |
    Select-Object -First 1
if (-not $binary) {
    throw "whisper-cli.exe was not produced under $buildRoot."
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null
$destination = Join-Path $OutputDirectory 'BonaquWhisperWorker.exe'
Copy-Item -Force $binary.FullName $destination

$licenseSource = Join-Path $sourceRoot 'LICENSE'
if (-not (Test-Path $licenseSource)) {
    throw 'Pinned whisper.cpp LICENSE file is missing.'
}
Copy-Item -Force $licenseSource (Join-Path $OutputDirectory 'WHISPER-CPP-LICENSE.txt')

$sha256 = (Get-FileHash -Algorithm SHA256 $destination).Hash.ToLowerInvariant()
@"
Bonaqu local transcription worker foundation
Engine: ggml-org/whisper.cpp
Pinned source commit: $WhisperCommit
Pinned source version label: $WhisperVersionLabel
Build: Windows x64 / Release / CPU baseline / static libraries
Models bundled: no
Worker SHA-256: $sha256

This artifact is an engine foundation only. It does not contain Telegram API
credentials, Telegram account data or a Whisper model. Bonaqu Client must not
ship it as a completed user-facing transcription feature until model management,
audio handoff, process isolation and privacy-safe result handling are integrated.
"@ | Set-Content -Encoding UTF8 (Join-Path $OutputDirectory 'ENGINE-INFO.txt')

"$sha256  BonaquWhisperWorker.exe" |
    Set-Content -Encoding ASCII (Join-Path $OutputDirectory 'SHA256SUMS.txt')

Write-Host ''
Write-Host "Built pinned Bonaqu transcription worker: $destination"
Write-Host "SHA-256: $sha256"
