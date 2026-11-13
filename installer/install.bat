@echo off
rem Split Fiction - Arabic translation installer (Saad5400)
rem Double-click to install. Downloads the latest installer script from GitHub and runs it.
title Split Fiction - Arabic translation
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072; try { $s = Invoke-RestMethod -UseBasicParsing 'https://raw.githubusercontent.com/Saad5400/SplitFiction-Arabic/main/installer/install.ps1' } catch { Write-Host ('Could not download the installer: ' + $_.Exception.Message) -ForegroundColor Red; Read-Host 'Press Enter to close'; exit 1 }; & ([scriptblock]::Create($s)) -Pause %*"
