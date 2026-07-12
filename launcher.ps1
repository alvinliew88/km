# launcher.ps1 - THE ONE SYSTEM (Professional IT Console UI)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$pcName = $env:COMPUTERNAME
$userName = $env:USERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred |
    Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try {
    $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress
} catch {
    $macAddress = "UNKNOWN"
}

# Windows Version
$windowsVersion = "Unknown"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $caption = $os.Caption -replace 'Microsoft ', ''
    $displayVersion = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).DisplayVersion
    if ($displayVersion) { $caption += " $displayVersion" }
    $windowsVersion = $caption
} catch {}

# Install Date
$installDate = "Unknown"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    if ($os.InstallDate) { $installDate = $os.InstallDate.ToString("yyyy-MM-dd") }
} catch {}

# Processor
$processor = "Unknown"
try {
    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
    $processor = $cpu.Name -replace '\s+', ' '
    if ($processor.Length -gt 40) { $processor = $processor.Substring(0, 40) + "..." }
} catch {}

# RAM
$ram = "Unknown"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $ram = "$totalGB GB"
} catch {}

# Storage (C:)
$storage = "Unknown"
try {
    $cDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop
    $totalGB = [math]::Round($cDrive.Size / 1GB, 1)
    $freeGB  = [math]::Round($cDrive.FreeSpace / 1GB, 1)
    $storage = "$totalGB GB total / $freeGB GB free"
} catch {}

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

function Start-Activation {
    param([string]$Mode, [string]$FriendlyName)
    Write-Host "`n  [+] Access Granted! Starting $FriendlyName..." -ForegroundColor Green

    $tempAIO = "$env:TEMP\THE_ONE_AIO.cmd"
    $tempRun = "$env:TEMP\THE_ONE_RUN.cmd"
    $url = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd"

    try {
        $raw = Invoke-RestMethod -Uri $url -ErrorAction Stop
        if ($raw -notmatch 'MAS_AIO') { throw "Downloaded script is invalid (missing marker)." }

        $ver = '?.?'
        if ($raw -match 'set\s+masver=([\d.]+)') { $ver = $Matches[1] }

        $raw = $raw -replace '(?im)^title .*$', "title  THE ONE SYSTEMS v$ver"
        $raw = $raw -replace '(?<!\r)\n', "`r`n"
        if (-not $raw.EndsWith("`r`n")) { $raw += "`r`n" }

        [System.IO.File]::WriteAllText($tempAIO, $raw, [System.Text.Encoding]::ASCII)

        # Wrapper: shows result, waits for keypress, then closes
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
echo     Process finished. Press any key to close this window
echo     and return to THE ONE main menu.
echo   =============================================================
pause >nul
"@
        [System.IO.File]::WriteAllText($tempRun, $wrapper, [System.Text.Encoding]::ASCII)

        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempRun`""

        Write-Host "  [+] Activation window launched. The main menu remains active." -ForegroundColor Cyan
    }
    catch {
        Write-Host "  [-] Error: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 5
    }
}

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
    Write-Host "`n  [+] PC Optimized successfully. Press any key to return to main menu." -ForegroundColor Green
    Write-Host "  [0] Press 0 to close all terminals immediately. Will auto-exit in 7 seconds." -ForegroundColor DarkGray

    $timeout = 7
    $keyPressed = $false
    while ($timeout -gt 0 -and -not $keyPressed) {
        if ([Console]::KeyAvailable) {
            $keyInfo = [Console]::ReadKey($true)
            # Any key returns to menu (including 0, but we treat 0 specially below)
            $keyPressed = $true
        } else {
            Start-Sleep -Seconds 1
            $timeout--
        }
    }

    if ($keyPressed) {
        # Any key pressed -> return to main menu (continue in the loop)
        return
    } else {
        # Timeout -> close all terminals (exit the entire script)
        exit
    }
}

function Get-MASVersion {
    try {
        $raw = Invoke-RestMethod "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd" -ErrorAction Stop
        if ($raw -match 'set\s+masver=([\d.]+)') { return $Matches[1] }
    } catch {}
    return "?.?"
}

# ------------------------------------------------------------
#  PROFESSIONAL UI MAIN MENU
# ------------------------------------------------------------
while ($true) {
    $masver = Get-MASVersion
    Clear-Host

    Write-Host "  ╔══════════════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "            T H E   O N E   S Y S T E M S   v$masver            " -NoNewline -ForegroundColor Cyan
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "               Authorized Operations Terminal                   " -NoNewline -ForegroundColor DarkGray
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ╠══════════════════════════════════════════════════════════════════╣" -ForegroundColor DarkCyan

    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  PC Name      : $($pcName.PadRight(38))" -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  User Account : $($userName.PadRight(38))" -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  MAC Address  : $($macAddress.PadRight(38))" -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  Local IP     : $($localIp.PadRight(38))" -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  Windows      : $($windowsVersion.PadRight(38))" -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  Install Date : $($installDate.PadRight(38))" -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  Processor    : $($processor.PadRight(38))" -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  RAM          : $($ram.PadRight(38))" -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  Storage (C:) : $($storage.PadRight(38))" -NoNewline -ForegroundColor White
    Write-Host "║" -ForegroundColor DarkCyan

    Write-Host "  ╠══════════════════════════════════════════════════════════════════╣" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  [1] Reactivate THE ONE PC Authorized Windows                  " -NoNewline -ForegroundColor Green
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  [2] Reactivate THE ONE PC Office                              " -NoNewline -ForegroundColor Green
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  [3] THE ONE PC Optimization                                   " -NoNewline -ForegroundColor Green
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  [4] Full THE ONE Activation Suite (All Options)               " -NoNewline -ForegroundColor Green
    Write-Host "║" -ForegroundColor DarkCyan

    Write-Host "  ╠══════════════════════════════════════════════════════════════════╣" -ForegroundColor DarkCyan
    Write-Host "  ║" -NoNewline -ForegroundColor DarkCyan
    Write-Host "  [0] Exit Terminal                                             " -NoNewline -ForegroundColor DarkGray
    Write-Host "║" -ForegroundColor DarkCyan
    Write-Host "  ╚══════════════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan

    Write-Host "`n  > Select module: " -NoNewline
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    Write-Host "$key" -ForegroundColor White

    if ($key -eq '0') { exit }

    switch ($key) {
        '1' { Start-Activation "/HWID" "Windows Activation" }
        '2' { Start-Activation "/Ohook" "Office Activation" }
        '3' { Invoke-DeepClean }
        '4' {
            Write-Host "`n  [+] Launching Full THE ONE Activation Suite..." -ForegroundColor Cyan
            iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
        }
    }
}
