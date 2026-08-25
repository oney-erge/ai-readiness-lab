@echo off
title AI Readiness Lab
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0run.ps1" %*
if errorlevel 1 (echo. & echo AI Readiness Lab did not start. Review the error above. & pause)
