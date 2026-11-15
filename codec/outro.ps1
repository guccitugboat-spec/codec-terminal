# Codec sign-off, run after Claude Code exits.
# Wipes all text, swaps the Terminal background to offline.hlsl (rain fades, Jolly Roger falls off screen),
# then ends so the tab/window closes. A hidden helper puts matrix.hlsl back a few seconds later.
# Test without closing anything: outro.ps1 -NoClose
param([switch]$NoClose)
$ErrorActionPreference = 'SilentlyContinue'
$e = [char]27
[Console]::Write("$e[?25l$e[3J$e[H$e[2J")      # hide cursor, wipe scrollback + screen

& "$PSScriptRoot\shader-swap.ps1" -To offline
Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$PSScriptRoot\shader-swap.ps1`"",'-To','matrix','-Delay','4'

Start-Sleep -Milliseconds 2200                  # let the Jolly Roger fall
$w = $Host.UI.RawUI.WindowSize.Width;  if ($w -lt 10) { $w = 120 }
$h = $Host.UI.RawUI.WindowSize.Height; if ($h -lt 5)  { $h = 30 }
$msg = 'O F F L I N E'
[Console]::Write("$e[$([int]($h / 2));$([int](($w - $msg.Length) / 2) + 1)H$e[1;38;2;230;60;50m$msg$e[0m")
Start-Sleep -Milliseconds 1600                  # hold OFFLINE, then close
[Console]::Write("$e[?25h")
if (-not $NoClose) { exit 0 }
