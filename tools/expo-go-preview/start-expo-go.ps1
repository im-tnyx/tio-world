# Issue #759: test-only Expo Go Metro QR launcher. Never starts a production build.
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$LanIPv4,
    [switch]$QaHttps
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Push-Location $PSScriptRoot
try {
    if ($QaHttps) {
        $env:EXPO_PUBLIC_FLUTTER_WEB_URL = "https://${LanIPv4}:7358"
        Write-Host "QA HTTPS selected. Verify the locally trusted certificate in iPhone Safari before entering any credentials."
    } else {
        $env:EXPO_PUBLIC_FLUTTER_WEB_URL = "http://${LanIPv4}:7357"
    }
    & node -e "const result = require('./preview-url').resolvePreviewUrl(process.env.EXPO_PUBLIC_FLUTTER_WEB_URL); if (result.error) { console.error(result.error); process.exit(1); }"
    if ($LASTEXITCODE -ne 0) { throw "Pass a canonical private LAN IPv4 address (e.g. -LanIPv4 192.168.1.25)." }

    Write-Host "Checking Expo Go dev-only project. Flutter Web must already be running in the other terminal."
    & npm.cmd install --no-audit --no-fund
    if ($LASTEXITCODE -ne 0) { throw "Expo npm dependency installation failed." }
    & npm.cmd test
    if ($LASTEXITCODE -ne 0) { throw "Expo URL contract tests failed." }
    & npx.cmd expo install --check
    if ($LASTEXITCODE -ne 0) { throw "Expo dependencies are incompatible with SDK 57." }

    Write-Host "Flutter Web: $env:EXPO_PUBLIC_FLUTTER_WEB_URL"
    Write-Host "Keep this terminal running. Scan the QR shown by Expo CLI using Expo Go."
    Write-Host "The Expo QR and Flutter Web port 7357 are separate endpoints on the same private Wi-Fi."
    & npx.cmd expo start --go --lan --clear
    if ($LASTEXITCODE -ne 0) { throw "Expo Metro failed to launch." }
}
finally {
    Pop-Location
}
