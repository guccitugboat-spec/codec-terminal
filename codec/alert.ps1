# Alert sounds + on-screen notice for Claude Code hooks.
# Usage: alert.ps1 -Kind alert   (Claude needs you)   |   alert.ps1 -Kind clear (task finished)
param([string]$Kind = 'alert')
$ErrorActionPreference = 'SilentlyContinue'
$null = [Console]::In.ReadToEnd()

if ($Kind -eq 'alert') {
    $msg = '[ ! ] ALERT - Your input is required.'
} else {
    $msg = '[ MISSION UPDATE ] Objective complete. Awaiting orders.'
}
@{ systemMessage = $msg } | ConvertTo-Json -Compress
