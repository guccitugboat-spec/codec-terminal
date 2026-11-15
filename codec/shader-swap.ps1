# Points Windows Terminal's background shader at matrix.hlsl (normal) or offline.hlsl (exit animation).
param([ValidateSet('matrix','offline')][string]$To = 'matrix', [int]$Delay = 0)
$ErrorActionPreference = 'SilentlyContinue'
if ($Delay -gt 0) { Start-Sleep -Seconds $Delay }
$p = Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json'
$t = [IO.File]::ReadAllText($p)
$from = if ($To -eq 'matrix') { 'offline.hlsl' } else { 'matrix.hlsl' }
$n = $t -replace "codec\\\\$([regex]::Escape($from))`"", "codec\\$To.hlsl`""
if ($n -ne $t) { [IO.File]::WriteAllText($p, $n, (New-Object Text.UTF8Encoding($false))) }
