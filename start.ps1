# Start the local server and open the app in the default browser.
# Usage:  .\start.ps1            (port 8765)
#         .\start.ps1 -Port 9000
param([int]$Port = 8765)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$node = (Get-Command node -ErrorAction Stop).Source
$url = "http://127.0.0.1:$Port/"

Start-Process -WindowStyle Hidden -FilePath $node -ArgumentList @((Join-Path $here 'serve.mjs'), "$Port") -WorkingDirectory $here
Start-Sleep -Milliseconds 900
Start-Process $url
Write-Host "Open: $url"
Write-Host "To stop: Get-Process node | Stop-Process  (or close the hidden node window)"
