$ErrorActionPreference = 'Stop'
$base = Split-Path -Parent $PSScriptRoot
$runtime = Join-Path $base 'runtime\node.exe'
$bridge = Join-Path $base 'bridge\index.js'
$game = Join-Path $base 'game\MissionSauvetage.exe'
$logs = Join-Path $env:LOCALAPPDATA 'MissionSauvetageLIVE\logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
if (-not (Test-Path $runtime)) { throw "Runtime integre absent: $runtime" }
if (-not (Test-Path $bridge)) { throw "Passerelle TikTok absente: $bridge" }
if (-not (Test-Path $game)) { throw "Jeu Windows absent: $game" }
$bridgeProcess = $null
try {
  $bridgeProcess = Start-Process -FilePath $runtime -ArgumentList ('"' + $bridge + '"') -WorkingDirectory (Join-Path $base 'bridge') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $logs 'bridge-out.log') -RedirectStandardError (Join-Path $logs 'bridge-error.log')
  for ($i=0; $i -lt 22; $i++) {
    try {
      $health = Invoke-RestMethod -Uri 'http://127.0.0.1:8766/health' -TimeoutSec 1
      if ($health.ok) { break }
    } catch {}
    Start-Sleep -Milliseconds 300
  }
  $process = Start-Process -FilePath $game -WorkingDirectory (Join-Path $base 'game') -PassThru -Wait
  if ($process.ExitCode -ne 0) {
    Write-Warning "Le jeu s'est ferme avec le code $($process.ExitCode). Journaux: $logs"
  }
} finally {
  if ($bridgeProcess -and -not $bridgeProcess.HasExited) {
    Stop-Process -Id $bridgeProcess.Id -Force -ErrorAction SilentlyContinue
  }
}
