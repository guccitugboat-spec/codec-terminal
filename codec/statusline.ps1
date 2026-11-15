# Codec-style status line for Claude Code. Reads session JSON on stdin.
$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$raw = [Console]::In.ReadToEnd()
try { $j = $raw | ConvertFrom-Json } catch { $j = $null }
$codec = Join-Path $env:USERPROFILE '.claude\codec'

$e = [char]27
$g  = "$e[38;2;142;227;166m" # soft codec green
$dg = "$e[38;2;94;122;104m"  # muted grey-green
$am = "$e[38;2;224;180;79m"  # soft amber
$rd = "$e[38;2;230;100;90m"  # alert red
$r  = "$e[0m"
$sep = " $dg//$r "

$model = if ($j.model.display_name) { $j.model.display_name } else { 'UNKNOWN' }
$dir   = if ($j.workspace.current_dir) { Split-Path $j.workspace.current_dir -Leaf } else { 'BASE' }
$ms    = [double]$j.cost.total_duration_ms
$ts    = [TimeSpan]::FromMilliseconds($ms)
$clock = '{0:00}:{1:00}:{2:00}' -f [int]$ts.TotalHours, $ts.Minutes, $ts.Seconds

# A stable fake "frequency" per model, like 140.85
$sum = 0; foreach ($c in $model.ToCharArray()) { $sum += [int]$c }
$freq = '{0}.{1:00}' -f (140 + ($sum % 3)), ($sum % 100)

$operative = 'WHALE CUMSHOT'
$left = "$dg[$r$g CODEC $freq $r$dg]$r$sep" + "OP $am$operative$r$sep" + "FREQ $g$($model.ToUpper())$r$sep" + "AREA $g$($dir.ToUpper())$r$sep" + "MISSION $g$clock$r"

# ---- Weather (cached; refreshed in the background every 20 min) ----
$wxFile  = Join-Path $codec 'weather.txt'
$wxStamp = Join-Path $codec 'weather.attempt'
$now = Get-Date
$fresh = (Test-Path $wxFile) -and (($now - (Get-Item $wxFile).LastWriteTime).TotalMinutes -lt 20)
$recentTry = (Test-Path $wxStamp) -and (($now - (Get-Item $wxStamp).LastWriteTime).TotalMinutes -lt 2)
if (-not $fresh -and -not $recentTry) {
  Set-Content $wxStamp ''
  Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"`"$(Join-Path $codec 'weather.ps1')`""
}
$wx = ''
if (Test-Path $wxFile) {
  $parts = ([IO.File]::ReadAllText($wxFile, [Text.Encoding]::UTF8)).Trim() -split '\|'
  if ($parts.Count -ge 2) { $wx = "WX $g$($parts[0].Trim().ToUpper()) $($parts[1].Trim().TrimStart('+'))$r" }
}

# ---- Usage bar (plan rate limits) ----
function Bar([double]$pct, [int]$cells = 10) {
  $pct = [Math]::Max(0, [Math]::Min(100, $pct))
  $fill = [int][Math]::Round($pct / 100 * $cells)
  $col = if ($pct -ge 85) { $rd } elseif ($pct -ge 60) { $am } else { $g }
  "$dg[$r$col" + ([string][char]0x2588 * $fill) + "$dg" + ([string][char]0x2591 * ($cells - $fill)) + "$dg]$r $col$([int]$pct)%$r"
}
$usage = @()
$rl = $j.rate_limits
if ($rl.five_hour) {
  $reset = ''
  if ($rl.five_hour.resets_at) {
    $t = [DateTimeOffset]::FromUnixTimeSeconds([long]$rl.five_hour.resets_at).ToLocalTime()
    $reset = " $dg" + [char]0x21BB + " $($t.ToString('h:mmtt').ToLower())$r"
  }
  $usage += "5H $(Bar $rl.five_hour.used_percentage)$reset"
}
if ($rl.seven_day) { $usage += "7D $(Bar $rl.seven_day.used_percentage 6)" }
if ($null -ne $j.context_window.used_percentage) { $usage += "CTX $g$([int]$j.context_window.used_percentage)%$r" }

$right = (@($wx) + $usage | Where-Object { $_ }) -join $sep

# ---- Right-align when the terminal width is known ----
$width = 0
if ([int]$env:COLUMNS -gt 0) { $width = [int]$env:COLUMNS }
else { try { $width = [Console]::WindowWidth } catch { $width = 0 } }
$visible = { param($s) ($s -replace "$e\[[0-9;]*m", '').Length }
$gap = $width - (& $visible $left) - (& $visible $right) - 4
if ($width -gt 0 -and $gap -ge 2) {
  $left + (' ' * $gap) + $right
} else {
  $pad = [Math]::Max(0, $width - (& $visible $right) - 4)
  "$left`n" + (' ' * $pad) + $right
}
