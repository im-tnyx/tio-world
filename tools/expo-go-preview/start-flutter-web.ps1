# Issue #759: generate Flutter Web only in a disposable external Git worktree.
# The normal Flutter checkout and platform folders are not modified.
[CmdletBinding()]
param(
    [string]$FlutterBin = "G:\dev\flutter-sdk\bin\flutter.bat"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$branch = "tnyx/issue-759-expo-go-preview-spike"
$port = 7357

if (-not (Test-Path -LiteralPath $FlutterBin -PathType Leaf)) {
    $command = Get-Command flutter -ErrorAction SilentlyContinue
    if ($null -eq $command) {
        throw "Flutter SDK not found. Pass -FlutterBin 'G:\dev\flutter-sdk\bin\flutter.bat' or add Flutter to PATH."
    }
    $FlutterBin = $command.Source
}

& git -C $repoRoot rev-parse --is-inside-work-tree | Out-Null
if ($LASTEXITCODE -ne 0) { throw "This script must be run from the Tio-world repository." }
Write-Host "Fetching only issue #759 branch. Existing worktrees are not reset, switched or cleaned."
& git -C $repoRoot fetch --no-tags origin "refs/heads/${branch}:refs/remotes/origin/${branch}"
if ($LASTEXITCODE -ne 0) { throw "Unable to fetch issue #759 branch." }

$revision = (& git -C $repoRoot rev-parse "refs/remotes/origin/${branch}").Trim()
if ($LASTEXITCODE -ne 0 -or $revision.Length -ne 40) { throw "Unable to resolve test branch HEAD." }

$previewDir = Join-Path ([System.IO.Path]::GetTempPath()) ("tio-expo-759-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
Write-Host "Creating disposable preview checkout: $previewDir"
& git -C $repoRoot worktree add --detach $previewDir $revision
if ($LASTEXITCODE -ne 0) { throw "Could not create temporary worktree." }

Push-Location (Join-Path $previewDir "apps\app")
try {
    Write-Host "Generating Web runner in disposable worktree ONLY (not in main Flutter checkout)."
    & $FlutterBin create --platforms=web --project-name=tio_app .
    if ($LASTEXITCODE -ne 0) { throw "Flutter Web runner generation failed. Preview not ready." }

    & $FlutterBin pub get
    if ($LASTEXITCODE -ne 0) { throw "Flutter dependency resolution failed. Preview not ready." }

    Write-Host ""
    Write-Host "Dev Web server on port $port, LAN only. No Supabase credentials supplied."
    Write-Host "Find your PC's private IPv4 with: Get-NetIPAddress -AddressFamily IPv4"
    Write-Host "Open http://YOUR_PC_PRIVATE_IP:${port} on the phone first to check browser reachability."
    Write-Host "Keep this terminal running while testing through Expo Go."
    Write-Host ""
    & $FlutterBin run -d web-server --web-hostname=0.0.0.0 --web-port=$port --debug
    if ($LASTEXITCODE -ne 0) { throw "Flutter Web compile/run failed; inspect the compiler output. Do not edit production Flutter code for this experiment." }
}
finally {
    Pop-Location
    Write-Host ""
    Write-Host "Disposable worktree remains at: $previewDir"
    Write-Host "No automatic deletion/reset of your files was performed."
    Write-Host "Once you confirm it contains no work you want to keep, clean it manually with:"
    Write-Host ('git -C "{0}" worktree remove "{1}" --force' -f $repoRoot, $previewDir)
}
