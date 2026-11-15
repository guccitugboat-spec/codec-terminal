# Codec login gate (added by Claude). Run by the Windows Terminal default profile.
# First run: asks you to set a password. Later runs: asks for it, then starts Claude Code.
# Password is stored only as a salted PBKDF2-SHA256 hash in login.dat (same folder).
#   Change password:  powershell -ExecutionPolicy Bypass -File login.ps1 -Reset
#   Forgot password:  delete ~\.claude\codec\login.dat (next launch asks for a new one)
param([switch]$Reset)
$ErrorActionPreference = 'Stop'
$e      = [char]27
$green  = "$e[38;2;142;227;166m"
$dim    = "$e[38;2;94;122;104m"
$red    = "$e[1;38;2;230;60;50m"
$off    = "$e[0m"
$store  = Join-Path $PSScriptRoot 'login.dat'
$iters  = 200000

function Get-Hash([string]$pw, [byte[]]$salt, [int]$n) {
    $kdf = New-Object System.Security.Cryptography.Rfc2898DeriveBytes($pw, $salt, $n, [System.Security.Cryptography.HashAlgorithmName]::SHA256)
    try { return $kdf.GetBytes(32) } finally { $kdf.Dispose() }
}

function Same([byte[]]$a, [byte[]]$b) {          # constant-time compare
    if ($a.Length -ne $b.Length) { return $false }
    $d = 0; for ($i = 0; $i -lt $a.Length; $i++) { $d = $d -bor ($a[$i] -bxor $b[$i]) }
    return $d -eq 0
}

function Read-Masked([string]$label) {           # masked input; Ctrl+C can't break out to a shell
    Write-Host -NoNewline "$green  $label$off "
    $sb = New-Object System.Text.StringBuilder
    while ($true) {
        $k = [Console]::ReadKey($true)
        if ($k.Key -eq 'Enter') { break }
        if ($k.Key -eq 'Backspace') {
            if ($sb.Length -gt 0) { [void]$sb.Remove($sb.Length - 1, 1); Write-Host -NoNewline "`b `b" }
            continue
        }
        if (($k.Modifiers -band [ConsoleModifiers]::Control) -and $k.Key -eq 'C') { [Environment]::Exit(1) }
        if ($k.KeyChar -ge ' ') { [void]$sb.Append($k.KeyChar); Write-Host -NoNewline "$dim*$off" }
    }
    Write-Host ""
    return $sb.ToString()
}

function Show-Screen([string]$status) {
    [Console]::Write("$e[3J$e[H$e[2J")
    Write-Host ""
    Write-Host "$dim  ===============================================$off"
    Write-Host "$green   CODEC SECURE LINK  //  FREQ 140.85$off"
    Write-Host "$dim   $(Get-Date -Format 'yyyy-MM-dd HH:mm')  //  $status$off"
    Write-Host "$dim  ===============================================$off"
    Write-Host ""
}

function Set-Password {
    while ($true) {
        $a = Read-Masked 'NEW PASSWORD  >'
        if ($a.Length -lt 4) { Write-Host "$red  Too short (min 4 characters).$off"; continue }
        $b = Read-Masked 'CONFIRM       >'
        if ($a -ne $b) { Write-Host "$red  Passwords don't match. Try again.$off"; continue }
        $salt = New-Object byte[] 16
        [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($salt)
        $rec = @{ salt = [Convert]::ToBase64String($salt); hash = [Convert]::ToBase64String((Get-Hash $a $salt $iters)); iter = $iters }
        $rec | ConvertTo-Json | Set-Content -Path $store -Encoding ASCII
        Write-Host "$green  Password set.$off"
        Start-Sleep -Milliseconds 700
        return
    }
}

function Test-Login {
    $rec  = Get-Content $store -Raw | ConvertFrom-Json
    $salt = [Convert]::FromBase64String($rec.salt)
    $want = [Convert]::FromBase64String($rec.hash)
    for ($try = 1; $try -le 3; $try++) {
        $pw = Read-Masked 'PASSWORD >'
        if (Same (Get-Hash $pw $salt ([int]$rec.iter)) $want) { return $true }
        Write-Host "$red  ACCESS DENIED  ($try/3)$off"
        Start-Sleep -Seconds $try                  # slow down guessing
    }
    return $false
}

[Console]::TreatControlCAsInput = $true

if (-not (Test-Path $store)) {
    Show-Screen 'NO PASSWORD ON FILE - SET ONE NOW'
    Set-Password
} elseif ($Reset) {
    Show-Screen 'PASSWORD CHANGE - VERIFY CURRENT'
    if (-not (Test-Login)) { Write-Host "$red  LOCKED OUT$off"; Start-Sleep 3; [Environment]::Exit(1) }
    Set-Password
    [Environment]::Exit(0)
}

Show-Screen 'AUTHENTICATION REQUIRED'
if (-not (Test-Login)) {
    Write-Host ""
    Write-Host "$red  LOCKED OUT - CLOSING LINK$off"
    Start-Sleep -Seconds 3
    [Environment]::Exit(1)
}

[Console]::TreatControlCAsInput = $false
Write-Host ""
Write-Host "$green  ACCESS GRANTED  //  OPERATIVE: Whale Cumshot$off"
Start-Sleep -Milliseconds 600
[Console]::Write("$e[3J$e[H$e[2J")

# Start Claude Code, then the usual offline sign-off; the tab closes afterward.
$exe = (Get-Command claude -CommandType Application | Select-Object -First 1).Source
& $exe
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'outro.ps1')
[Environment]::Exit(0)
