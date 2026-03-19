@echo off
title Synology Drive - Exclude node_modules
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0synology-exclude-node-modules.ps1"
echo.
echo Press any key to close this window...
pause >nul
