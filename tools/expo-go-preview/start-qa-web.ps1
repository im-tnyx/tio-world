# Issue #759 -- separate HTTPS-only QA Web build from existing ignored local config.
# Do not use for production projects/accounts, and do not run on public networks.
[CmdletBinding()]
param(
    [string]$QaConfigFile = "G:\projects\Tio-World\apps\app\.runtime.qa.json",
    [Parameter(Mandatory = $true)][string]$LanIPv4,
    [Parameter(Mandatory = $true)][string]$CertFile,
    [Parameter(Mandatory = $true)][string]$KeyFile,
    [string]$FlutterBin = "G:\dev\flutter-sdk\bin\flutter.bat"
)
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
$branch = "tnyx/issue-759-expo-go-preview-spike"
if (-not (Test-Path -LiteralPath $QaConfigFile -PathType Leaf)) { throw "Local ignored apps/app/.runtime.qa.json is missing. No QA config values are requested or generated." }
if (-not (Test-Path -LiteralPath $FlutterBin -PathType Leaf)) { throw "Flutter SDK missing at expected path." }
foreach ($file in @($CertFile, $KeyFile)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { throw "TLS cert/key file missing. Generate locally trusted certificate outside the repository." }
}
$qaPath = (Resolve-Path -LiteralPath $QaConfigFile).Path
$certPath = (Resolve-Path -LiteralPath $CertFile).Path
$keyPath = (Resolve-Path -LiteralPath $KeyFile).Path
if ($qaPath.StartsWith((Resolve-Path $repoRoot).Path + "\", [System.StringComparison]::OrdinalIgnoreCase)) {
    # This is allowed only for the ignored original local QA runtime file.
    $expected = "G:\projects\Tio-World\apps\app\.runtime.qa.json"
    if (-not $qaPath.Equals($expected, [System.StringComparison]::OrdinalIgnoreCase)) { throw "QA config must be from the existing ignored local app path." }
}
& node (Join-Path $PSScriptRoot "qa-config-check.js") $qaPath
if ($LASTEXITCODE -ne 0) { throw "QA client-safe config failed validation; not starting a login preview." }
& node -e "const r=require(process.argv[1]).resolvePreviewUrl('https://' + process.argv[2] + ':7358');if(!r.url)process.exit(1)" (Join-Path $PSScriptRoot "preview-url.js") $LanIPv4
if ($LASTEXITCODE -ne 0) { throw "Private LAN IPv4 is invalid." }

& git -C $repoRoot fetch --no-tags origin "refs/heads/${branch}:refs/remotes/origin/${branch}"
if ($LASTEXITCODE -ne 0) { throw "QA preview branch fetch failed." }
$revision = (& git -C $repoRoot rev-parse "refs/remotes/origin/${branch}").Trim()
$previewDir = Join-Path ([System.IO.Path]::GetTempPath()) ("tio-expo-759-qa-" + [guid]::NewGuid().ToString("N").Substring(0, 8))
& git -C $repoRoot worktree add --detach $previewDir $revision
if ($LASTEXITCODE -ne 0) { throw "Could not create isolated QA worktree." }

Push-Location (Join-Path $previewDir "apps\app")
try {
    & $FlutterBin create --platforms=web --project-name=tio_app .
    if ($LASTEXITCODE -ne 0) { throw "Web runner generation failed." }
    & node (Join-Path $PSScriptRoot "prepare-web-snapshot.js") $previewDir
    if ($LASTEXITCODE -ne 0) { throw "Disposable browser guard failed." }
    & $FlutterBin pub get
    if ($LASTEXITCODE -ne 0) { throw "Flutter dependencies failed." }
    Write-Host "Building QA Web snapshot with client-safe ignored local file (values never printed)."
    & $FlutterBin build web --debug --no-pub "--dart-define-from-file=$qaPath"
    if ($LASTEXITCODE -ne 0) { throw "QA Web compile failed; login has NOT been tested." }
    Write-Host "Serving HTTPS on https://${LanIPv4}:7358. iPhone must trust the tester-supplied certificate."
    Write-Host "Only use an isolated QA account and project. Close this terminal to stop the server."
    & node (Join-Path $PSScriptRoot "qa-https-server.js") (Join-Path (Get-Location).Path "build\web") $certPath $keyPath $LanIPv4
    if ($LASTEXITCODE -ne 0) { throw "HTTPS QA preview server failed." }
} finally {
    Pop-Location
    Write-Host "Temporary QA worktree preserved at $previewDir. Its build embeds client-safe QA endpoint/key."
    Write-Host "After confirming no local changes are needed, securely remove it using git worktree remove; do not upload."
}
