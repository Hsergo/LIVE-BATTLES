param([switch]$SmokeTest)
$ErrorActionPreference = 'Stop'
$base = Split-Path -Parent $PSScriptRoot
$runtime = Join-Path $base 'runtime\node.exe'
$bridge = Join-Path $base 'bridge\index.js'
$game = Join-Path $base 'game\MissionSauvetage.exe'
$logs = Join-Path $env:LOCALAPPDATA 'MissionSauvetageLIVE\logs'
New-Item -ItemType Directory -Force -Path $logs | Out-Null
foreach ($file in @($runtime,$bridge,$game)) {
  if (-not (Test-Path $file)) { throw "Fichier du jeu absent : $file. Extraire tout le ZIP ou reinstaller." }
}
function Get-BridgeHealth {
  try { return Invoke-RestMethod -Uri 'http://127.0.0.1:8766/health' -TimeoutSec 1 } catch { return $null }
}
function Test-CompatibleBridge($health) {
  return $health -and $health.ok -and $health.app -eq 'mission-sauvetage-live' -and $health.version -eq '0.5.0'
}
$bridgeProcess = $null
try {
  $health = Get-BridgeHealth
  if ($health -and -not (Test-CompatibleBridge $health)) {
    throw 'Le port local 8766 est occupe par une autre version ou application. Fermer cette application puis relancer le jeu.'
  }
  if (-not $health) {
    $bridgeProcess = Start-Process -FilePath $runtime -ArgumentList ('"' + $bridge + '"') -WorkingDirectory (Join-Path $base 'bridge') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $logs 'bridge-out.log') -RedirectStandardError (Join-Path $logs 'bridge-error.log')
    for ($i=0; $i -lt 30; $i++) {
      $health = Get-BridgeHealth
      if (Test-CompatibleBridge $health) { break }
      if ($bridgeProcess.HasExited) { throw "La passerelle n'a pas demarre. Voir $logs\bridge-error.log" }
      Start-Sleep -Milliseconds 300
    }
  }
  if (-not (Test-CompatibleBridge $health)) { throw "Passerelle indisponible. Journaux : $logs" }
	$gameArgs = @('--log-file', ('"' + (Join-Path $logs 'game.log') + '"'))
	if ($SmokeTest) { $gameArgs += @('--headless','--quit-after','90') }
	$process = Start-Process -FilePath $game -ArgumentList $gameArgs -WorkingDirectory (Join-Path $base 'game') -PassThru -Wait
  if ($process.ExitCode -ne 0) { throw "Le jeu s'est ferme avec le code $($process.ExitCode). Journaux : $logs" }
} finally {
  # Only stop the bridge owned by this launcher, never an existing process.
  if ($bridgeProcess -and -not $bridgeProcess.HasExited) {
    Stop-Process -Id $bridgeProcess.Id -Force -ErrorAction SilentlyContinue
  }
}
