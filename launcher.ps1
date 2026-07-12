# launcher.ps1 - THE ONE SYSTEM (Auto‑updating, Self‑closing windows)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred |
    Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try {
    $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress
} catch {
    $macAddress = "UNKNOWN"
}

$password = Read-Host "key" -AsSecureString
$passString = if ($password) {
    [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    )
}
if ($passString -ne "8888") {
    Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red
    Start-Sleep -Seconds 2
    exit
}

# ============================================================
#  Download official MAS AIO, change title, launch with mode
# ============================================================
function Start-Activation {
    param([string]$Mode, [string]$FriendlyName)
    Write-Host "`n  [+] Access Granted! Starting $FriendlyName..." -ForegroundColor Green

    $tempAIO = "$env:TEMP\THE_ONE_AIO.cmd"
    $tempRun = "$env:TEMP\THE_ONE_RUN.cmd"
    # !! If the official URL ever changes, update the line below !!
    $url = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd"

    try {
        $raw = Invoke-RestMethod -Uri $url -ErrorAction Stop
        if ($raw -notmatch 'MAS_AIO') { throw "Downloaded script is invalid (missing marker)." }

        # Extract official version
        $ver = '?.?'
        if ($raw -match 'set\s+masver=([\d.]+)') { $ver = $Matches[1] }

        # Only change the title line
        $raw = $raw -replace '(?im)^title .*$', "title  THE ONE SYSTEMS v$ver"

        # Ensure CRLF and final empty line
        $raw = $raw -replace '(?<!\r)\n', "`r`n"
        if (-not $raw.EndsWith("`r`n")) { $raw += "`r`n" }

        [System.IO.File]::WriteAllText($tempAIO, $raw, [System.Text.Encoding]::ASCII)

        # Wrapper script: runs activation, then auto‑closes after 7 seconds
        $wrapper = @"
@echo off
title  THE ONE $FriendlyName v$ver
echo.
echo   =============================================================
echo              T H E   O N E   S Y S T E M S   v$ver
echo   =============================================================
echo.
call "$tempAIO" $Mode
echo.
echo   =============================================================
echo     Process finished. This window will close in 7 seconds.
echo     Press 0 to close immediately.
echo   =============================================================
echo.

set /a timer=7
:countdown
choice /c 0 /t 1 /d 0 /n >nul
if errorlevel 2 goto exit_now
set /a timer-=1
if %timer% gtr 0 goto countdown

:exit_now
exit
"@
        [System.IO.File]::WriteAllText($tempRun, $wrapper, [System.Text.Encoding]::ASCII)

        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempRun`""

        Write-Host "  [+] Activation window launched. It will close automatically." -ForegroundColor Cyan
    }
    catch {
        Write-Host "  [-] Error: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 5
    }
}

# ============================================================
#  PC Optimization – then close all terminals after 7 seconds
# ============================================================
function Invoke-DeepClean {
    Write-Host "`n  [+] Deep cleaning system temporary files..." -ForegroundColor Cyan
    $folders = @(
        $env:TEMP,
        "$env:SystemRoot\Temp",
        "$env:SystemRoot\Prefetch",
        [Environment]::GetFolderPath('Recent'),
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Microsoft\Windows\Temporary Internet Files"
    )
    foreach ($folder in $folders) {
        if (Test-Path $folder) {
            Write-Host "  Cleaning: $folder" -ForegroundColor DarkGray
            Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
    try { cleanmgr /sagerun:1 | Out-Null } catch {}
    Write-Host "`n  [+] PC Optimized successfully. All terminals will close in 7 seconds..." -ForegroundColor Green
    Write-Host "  [0] Press 0 to close immediately" -ForegroundColor DarkGray

    # Wait up to 7 seconds, allow immediate exit with '0'
    $timeout = 7
    while ($timeout -gt 0) {
        if ([Console]::KeyAvailable) {
            $keyInfo = [Console]::ReadKey($true)
            if ($keyInfo.KeyChar -eq '0') { break }
        }
        Start-Sleep -Seconds 1
        $timeout--
    }
    # After countdown (or keypress), close the PowerShell window entirely
    exit
}

# ============================================================
#  Get dynamic version from official script
# ============================================================
function Get-MASVersion {
    try {
        $raw = Invoke-RestMethod "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd" -ErrorAction Stop
        if ($raw -match 'set\s+masver=([\d.]+)') { return $Matches[1] }
    } catch {}
    return "?.?"
}

# ============================================================
#  Modern Main Menu Loop
# ============================================================
while ($true) {
    $masver = Get-MASVersion
    Clear-Host
    Write-Host "`n  T H E   O N E   S Y S T E M S   v$masver" -ForegroundColor Cyan
    Write-Host "  Authorized Operations Terminal" -ForegroundColor DarkGray
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PC Name      : $pcName" -ForegroundColor White
    Write-Host "  MAC Address  : $macAddress" -ForegroundColor White
    Write-Host "  Local IP     : $localIp" -ForegroundColor White
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [1] Reactivate THE ONE PC Authorized Windows" -ForegroundColor Green
    Write-Host "  [2] Reactivate THE ONE PC Office" -ForegroundColor Green
    Write-Host "  [3] THE ONE PC Optimization" -ForegroundColor Green
    Write-Host "  [4] Full MAS Menu (Original)" -ForegroundColor Green
    Write-Host "  [0] Exit Terminal" -ForegroundColor DarkGray
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "`n  > Select module: " -NoNewline

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    Write-Host "$key" -ForegroundColor White

    if ($key -eq '0') { exit }

    switch ($key) {
        '1' { Start-Activation "/HWID" "Windows Activation" }
        '2' { Start-Activation "/Ohook" "Office Activation" }
        '3' { Invoke-DeepClean }
        '4' {
            Write-Host "`n  [+] Launching original MAS full menu..." -ForegroundColor Cyan
            iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
        }
    }
}
