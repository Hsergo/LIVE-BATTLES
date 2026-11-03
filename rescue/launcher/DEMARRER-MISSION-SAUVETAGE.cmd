@echo off
title MISSION SAUVETAGE LIVE
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0launcher\start.ps1"
if errorlevel 1 (
  echo.
  echo Une erreur a empeche le lancement. Envoyez une capture de ce message.
  pause
)
