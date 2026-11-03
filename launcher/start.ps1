$ErrorActionPreference = "Stop"
$base = Split-Path -Parent $PSScriptRoot
$node = Join-Path $base 'runtime\node.exe'
$bridge = Join-Path $base 'bridge\index.js'
$game = Join-Path $base 'game\LiveBattle.exe'

if (-not (Test-Path $node)) { throw "Runtime node.exe manquant." }
if (-not (Test-Path $bridge)) { throw "Passerelle manquante." }
if (-not (Test-Path $game)) { throw "Jeu LiveBattle.exe manquant." }

$bridgeProcess = $null
try {
  $bridgeProcess = Start-Process -FilePath $node -ArgumentList ('"' + $bridge + '"') -WorkingDirectory (Join-Path $base 'bridge') -WindowStyle Hidden -PassThru
  Start-Sleep -Seconds 2
  Start-Process -FilePath $game -WorkingDirectory (Join-Path $base 'game') -Wait
} finally {
  if ($bridgeProcess -and (-not $bridgeProcess.HasExited)) {
    Stop-Process -Id $bridgeProcess.Id -Force -ErrorAction SilentlyContinue
  }
}
