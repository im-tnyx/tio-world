param(
  [Parameter(Mandatory = $true)]
  [string]$ProjectDir,

  [AllowEmptyString()]
  [string]$DeviceId,

  [string]$WatchSubPath = "..",

  [int]$DebounceMs = 400
)

$ErrorActionPreference = "Stop"

$projectPath = (Resolve-Path -LiteralPath $ProjectDir).Path
$watchPath = (Resolve-Path -LiteralPath (Join-Path $projectPath $WatchSubPath)).Path

if (-not (Test-Path -LiteralPath $watchPath)) {
  throw "Watch path not found: $watchPath"
}

if ([string]::IsNullOrWhiteSpace($DeviceId)) {
  try {
    $firstOnlineDevice = & adb devices | Select-String "^\S+\s+device$" | Select-Object -First 1
    if ($firstOnlineDevice) {
      $DeviceId = ($firstOnlineDevice.ToString() -split "\s+")[0]
    }
  } catch {
  }
}

if ([string]::IsNullOrWhiteSpace($DeviceId)) {
  throw "No Android device detected. Connect device and run: adb devices -l"
}

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "flutter"
$psi.Arguments = "run --debug -d $DeviceId"
$psi.WorkingDirectory = $projectPath
$psi.UseShellExecute = $false
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $false
$psi.RedirectStandardError = $false

$flutterProcess = New-Object System.Diagnostics.Process
$flutterProcess.StartInfo = $psi
$null = $flutterProcess.Start()

Write-Host "[auto-reload] Watching $watchPath for *.dart changes..."
Write-Host "[auto-reload] Device: $DeviceId"

$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $watchPath
$watcher.Filter = "*.dart"
$watcher.IncludeSubdirectories = $true
$watcher.NotifyFilter = [System.IO.NotifyFilters]'FileName, LastWrite, Size'

$script:lastReloadAt = [DateTime]::MinValue

$action = {
  if ($flutterProcess.HasExited) { return }

  $now = Get-Date
  if (($now - $script:lastReloadAt).TotalMilliseconds -lt $DebounceMs) { return }
  $script:lastReloadAt = $now

  try {
    $flutterProcess.StandardInput.WriteLine("r")
    $changedFile = $Event.SourceEventArgs.FullPath
    Write-Host "[auto-reload] Sent 'r' after save: $changedFile"
  } catch {
    Write-Warning "[auto-reload] Failed to send hot reload command."
  }
}

$subscriptions = @()

try {
  $watcher.EnableRaisingEvents = $true

  $subscriptions += Register-ObjectEvent -InputObject $watcher -EventName Changed -Action $action
  $subscriptions += Register-ObjectEvent -InputObject $watcher -EventName Created -Action $action
  $subscriptions += Register-ObjectEvent -InputObject $watcher -EventName Renamed -Action $action

  while (-not $flutterProcess.HasExited) {
    Start-Sleep -Milliseconds 200
  }
}
finally {
  foreach ($subscription in $subscriptions) {
    try {
      Unregister-Event -SubscriptionId $subscription.Id -ErrorAction SilentlyContinue
      Remove-Job -Id $subscription.Id -Force -ErrorAction SilentlyContinue
    } catch {
    }
  }

  $watcher.EnableRaisingEvents = $false
  $watcher.Dispose()

  if (-not $flutterProcess.HasExited) {
    try {
      $flutterProcess.Kill()
    } catch {
    }
  }
}
