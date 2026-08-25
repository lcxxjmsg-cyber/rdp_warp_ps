@echo off
setlocal
title rdpwarp - TermWraps
REM Fast launcher: calls rdpwarps.ps1, which self-elevates via UAC when needed.
REM If it does not auto-elevate, right-click this file and choose "Run as administrator".
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0rdpwarps.ps1" %*
if errorlevel 1 pause
