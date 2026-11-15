# Added by Claude (codec theme): run the Jolly Roger sign-off after Claude Code exits.
function claude {
    & (Get-Command claude -CommandType Application | Select-Object -First 1).Source @args
    if (-not $env:CLAUDECODE) {
        & powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\.claude\codec\outro.ps1"
        exit   # close this tab once the background has gone offline
    }
}
