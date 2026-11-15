# Fetches current weather (location auto-detected by wttr.in from IP) into weather.txt.
# Launched in the background by statusline.ps1 when the cache is stale.
$ErrorActionPreference = 'Stop'
$out = Join-Path $PSScriptRoot 'weather.txt'
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
  $wc = New-Object Net.WebClient
  $wc.Encoding = [Text.Encoding]::UTF8
  $wc.Headers.Add('User-Agent', 'curl/8.0')
  $txt = $wc.DownloadString('https://wttr.in/?format=%C|%t').Trim()
  if ($txt -and $txt -notmatch 'Unknown|error|<') {
    [IO.File]::WriteAllText($out, $txt, [Text.Encoding]::UTF8)
  }
} catch { }
