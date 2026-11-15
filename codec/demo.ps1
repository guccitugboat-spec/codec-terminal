# Demo of the /exit sequence: fake session text, then the real outro (closes this tab).
Write-Host 'CODEC // simulated session text' -ForegroundColor Green
Get-ChildItem C:\Windows | Select-Object -First 25 | Format-Table -AutoSize
Start-Sleep 3
& "$PSScriptRoot\outro.ps1"
