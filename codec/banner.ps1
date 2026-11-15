# Codec startup banner (added by Claude). Run by the Windows PowerShell profile in Windows Terminal.
if ($Host.Name -eq 'ConsoleHost' -and -not $env:CLAUDECODE) {
    $e = [char]27
    Write-Host ""
    Write-Host "$e[38;2;94;122;104m  ===============================================$e[0m"
    Write-Host "$e[38;2;142;227;166m   CODEC LINK ESTABLISHED  //  FREQ 140.85$e[0m"
    Write-Host "$e[38;2;94;122;104m   OPERATIVE: Whale Cumshot  //  $(Get-Date -Format 'HH:mm')  //  STANDING BY$e[0m"
    Write-Host "$e[38;2;94;122;104m  ===============================================$e[0m"
    Write-Host ""
}
