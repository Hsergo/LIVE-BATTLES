@echo off
title LIVE BATTLES
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0launcher\start.ps1"
if errorlevel 1 (
  echo.
  echo Erreur au lancement. Contacter le support avec le message d'erreur.
  pause
)
