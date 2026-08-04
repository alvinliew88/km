# launcher.ps1 - THE ONE SYSTEM v3.1 (Key buffer clear, aligned box, stable)

# ---------- Privacy: clear terminal history ----------
try {
    [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
    Clear-History
    $historyPaths = @(
        "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
        (Get-PSReadLineOption).HistorySavePath
    )
    foreach ($hp in $historyPaths) {
        if ($hp -and (Test-Path $hp)) { Remove-Item $hp -Force -ErrorAction SilentlyContinue }
    }
} catch {}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# ----- System Info (silent fallbacks) -----
$pcName = $env:COMPUTERNAME
$userName = $env:USERNAME

$localIp = "Unknown"
try {
    $temp = Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred -ErrorAction Stop 2>$null
    $localIp = ($temp | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
} catch {
    try {
        $lines = & ipconfig.exe | Select-String "IPv4 Address"
        if ($lines.Count -gt 0) { $localIp = ($lines[0] -replace '.*:\s*', '').Trim() }
    } catch {}
}

$macAddress = "UNKNOWN"
try {
    $temp = Get-NetAdapter -ErrorAction Stop 2>$null
    $macAddress = ($temp | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress
} catch {
    try {
        $macOutput = & getmac.exe /fo csv
        $lines = $macOutput -split "`n"
        if ($lines.Count -ge 2) { $macAddress = ($lines[1] -split ',')[0].Trim('"') }
    } catch {}
}

$brand = "Unknown"
try { $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop; if ($cs.Manufacturer) { $brand = $cs.Manufacturer } } catch {}
$brand = if ($brand.Length -gt 35) { $brand.Substring(0, 35) + "..." } else { $brand }

$windowsVersion = "Unknown"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $caption = $os.Caption -replace 'Microsoft ', ''
    $dv = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).DisplayVersion
    if ($dv) { $caption += " $dv" }
    $windowsVersion = $caption
} catch {}

$installDate = "Unknown"
try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop; if ($os.InstallDate) { $installDate = $os.InstallDate.ToString("yyyy-MM-dd") } } catch {}

$processor = "Unknown"
try {
    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
    $processor = $cpu.Name -replace '\s+', ' '
} catch {}
$processor = if ($processor.Length -gt 35) { $processor.Substring(0, 35) + "..." } else { $processor }

$ram = "Unknown"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $ram = "$totalGB GB"
} catch {}

$storage = "Unknown"
try {
    $cDrive = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop
    $totalGB = [math]::Round($cDrive.Size / 1GB, 1)
    $freeGB  = [math]::Round($cDrive.FreeSpace / 1GB, 1)
    $storage = "$totalGB GB total / $freeGB GB free"
} catch {}
$storage = if ($storage.Length -gt 35) { $storage.Substring(0, 35) + "..." } else { $storage }

# ----- Password -----
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

# ----- Download MAS AIO with correct primary URL and fallback -----
function Get-MASScript {
    $primaryUrl   = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd"
    $fallbackUrl  = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd"
    try {
        Write-Host "  Downloading latest MAS script..." -ForegroundColor Gray
        $raw = Invoke-RestMethod -Uri $primaryUrl -ErrorAction Stop
        if ($raw -match 'MAS_AIO') { return $raw }
    } catch {}
    try {
        Write-Host "  Primary URL failed, trying fallback..." -ForegroundColor Yellow
        $raw = Invoke-RestMethod -Uri $fallbackUrl -ErrorAction Stop
        if ($raw -match 'MAS_AIO') { return $raw }
    } catch {}
    throw "Unable to download MAS script from any known URL."
}

# ----- Activation (keeps window open, 7-sec timeout, ESC to exit) -----
function Start-Activation {
    param([string]$Mode, [string]$FriendlyName)
    Write-Host "`n  [+] Access Granted! Starting $FriendlyName..." -ForegroundColor Green

    $tempAIO   = "$env:TEMP\THE_ONE_AIO.cmd"
    $tempRun   = "$env:TEMP\THE_ONE_RUN.cmd"
    $flagFile  = "$env:TEMP\THE_ONE_EXIT.flag"

    try {
        $raw = Get-MASScript
        $ver = '?.?'
        if ($raw -match 'set\s+masver=([\d.]+)') { $ver = $Matches[1] }

        $raw = $raw -replace '(?im)^title .*$', "title  THE ONE SYSTEMS v$ver"
        $raw = $raw -replace '(?<!\r)\n', "`r`n"
        if (-not $raw.EndsWith("`r`n")) { $raw += "`r`n" }

        [System.IO.File]::WriteAllText($tempAIO, $raw, [System.Text.Encoding]::ASCII)
        Remove-Item -Path $flagFile -Force -ErrorAction SilentlyContinue

        $wrapper = @"
@echo off
title  THE ONE $FriendlyName v$ver
echo.
echo   --------------------------------------------------------
echo          T H E   O N E   S Y S T E M S   v$ver
echo   --------------------------------------------------------
echo.
call "$tempAIO" $Mode
echo.
echo   --------------------------------------------------------
echo    Press any key to return to main menu, or ESC to exit all.
echo   --------------------------------------------------------
echo.

choice /c 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ /t 7 /d 0 /n >nul
if errorlevel 1 goto :keypressed
:keypressed
if "%errorlevel%"=="0" echo timeout > "$flagFile" & exit /b
if "%errorlevel%"=="27" exit
exit /b
"@
        [System.IO.File]::WriteAllText($tempRun, $wrapper, [System.Text.Encoding]::ASCII)

        $proc = Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempRun`"" -PassThru
        $proc.WaitForExit()

        if (Test-Path $flagFile) {
            Remove-Item -Path $flagFile -Force -ErrorAction SilentlyContinue
            Write-Host "`n  [!] No key was pressed. Exiting all terminals..." -ForegroundColor Red
            Start-Sleep -Seconds 1
            Exit-And-Clean
        } else {
            Write-Host "`n  [+] Returning to main menu." -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "  [-] Error: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 5
    }
}

# ----- PC Optimization (progress dots, auto‑exit after 7s) -----
function Invoke-DeepClean {
    Write-Host "`n  [+] Deep cleaning system temporary files...`n" -ForegroundColor Cyan

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
            $files = Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue
            $cnt = 0
            foreach ($file in $files) {
                try { Remove-Item $file.FullName -Force -Recurse -ErrorAction Stop } catch {}
                $cnt++
                if ($cnt % 50 -eq 0) { Write-Host "." -NoNewline }
            }
            Write-Host " Done."
        }
    }

    try { cleanmgr /sagerun:1 | Out-Null } catch {}
    Write-Host "`n  [+] PC Optimized successfully. Exiting all terminals in 7 seconds..." -ForegroundColor Green
    Start-Sleep -Seconds 7
    Exit-And-Clean
}

# ----- Software Installer (Menu 5) – PDF removed, GIMP not in ALL, idle timeout -----
function Invoke-SoftwareInstall {
    Write-Host "`n  Launching Software Installation Menu in a new window..." -ForegroundColor Cyan

    $tempPs1 = "$env:TEMP\THE_ONE_INSTALL.ps1"

    $installerScript = @'
$host.UI.RawUI.WindowTitle = "THE ONE Software Installer (Auto-close in 30s)"
Write-Host "`n  --------------------------------------------------------" -ForegroundColor Cyan
Write-Host "        T H E   O N E   S O F T W A R E   I N S T A L L E R" -ForegroundColor Cyan
Write-Host "  --------------------------------------------------------`n"

function Wait-KeyOrTimeout($seconds, $message) {
    Write-Host $message -NoNewline
    $end = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $end) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            return $key.KeyChar
        }
        Start-Sleep -Milliseconds 200
    }
    return $null
}

$winget = Get-Command winget.exe -ErrorAction SilentlyContinue
if (-not $winget) {
    Write-Host "  [ERROR] Windows Package Manager (winget) not found." -ForegroundColor Red
    Write-Host "  Please update your system or install App Installer from Microsoft Store.`n"
    Read-Host "  Press Enter to return to main menu"
    exit
}

Write-Host "  Available software:" -ForegroundColor White
Write-Host "  ┌─────────────────────────────────────────────┐"
Write-Host "  │  [1] Google Chrome                          │"
Write-Host "  │  [2] 7-Zip (Archive Utility)                │"
Write-Host "  │  [3] VLC Media Player                       │"
Write-Host "  │  [4] GIMP (Image Editor)                    │"
Write-Host "  │  [A] Install ALL (Chrome + 7-Zip + VLC)     │"
Write-Host "  │  [0] Return to Main Menu                    │"
Write-Host "  └─────────────────────────────────────────────┘`n"

$choice = Wait-KeyOrTimeout 30 "  Enter your choice (30s timeout): "
if ($null -eq $choice) {
    Write-Host "`n  Timeout reached. Exiting..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    exit
}
Write-Host $choice

switch -Wildcard ($choice) {
    '0' { exit }
    'A' {
        winget install --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements
        winget install --id 7zip.7zip --silent --accept-source-agreements --accept-package-agreements
        winget install --id VideoLAN.VLC --silent --accept-source-agreements --accept-package-agreements
    }
    '1' { winget install --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements }
    '2' { winget install --id 7zip.7zip --silent --accept-source-agreements --accept-package-agreements }
    '3' { winget install --id VideoLAN.VLC --silent --accept-source-agreements --accept-package-agreements }
    '4' { winget install --id GIMP.GIMP --silent --accept-source-agreements --accept-package-agreements }
    default { Write-Host "  Invalid choice." -ForegroundColor Red; Start-Sleep 2 }
}
Write-Host "`n  --------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  Installation completed. This window will close in 10 seconds, or press Enter." -ForegroundColor Green
$timeout = 10
while ($timeout -gt 0) {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq "Enter") { break }
    }
    Start-Sleep -Seconds 1
    $timeout--
}
'@

    [System.IO.File]::WriteAllText($tempPs1, $installerScript, [System.Text.Encoding]::UTF8)

    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempPs1`"" -PassThru
    $proc.WaitForExit()

    # Clear any stray key presses accumulated while sub-window was open
    while ([Console]::KeyAvailable) { [Console]::ReadKey($true) | Out-Null }
    Write-Host "`n  Installer window closed. Returning to main menu." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 300
}

# ----- Debloat Windows (Menu 6) – Confirmation with timeout -----
function Invoke-Debloat {
    Write-Host "`n  [+] Removing bloatware in a new window..." -ForegroundColor Cyan

    $tempPs1 = "$env:TEMP\THE_ONE_DEBLOAT.ps1"

    $debloatScript = @'
$host.UI.RawUI.WindowTitle = "THE ONE Debloater (Auto-close in 30s)"
Write-Host "`n  --------------------------------------------------------" -ForegroundColor Cyan
Write-Host "              T H E   O N E   D E B L O A T E R" -ForegroundColor Cyan
Write-Host "  --------------------------------------------------------`n"
$packages = @(
    'Microsoft.549981C3F5F10',
    'Microsoft.MicrosoftOfficeHub',
    'Microsoft.OneDriveSync',
    'Microsoft.XboxApp',
    'Microsoft.XboxGameCallableUI',
    'Microsoft.XboxSpeechToTextOverlay',
    'Microsoft.Xbox.TCUI',
    'Microsoft.XboxGamingOverlay',
    'Microsoft.XboxIdentityProvider',
    'Microsoft.BingNews',
    'Microsoft.BingWeather',
    'Microsoft.BingSports',
    'Microsoft.BingFinance',
    'Microsoft.GetHelp',
    'Microsoft.Getstarted',
    'Microsoft.MicrosoftSolitaireCollection',
    'Microsoft.MixedReality.Portal',
    'Microsoft.SkypeApp',
    'Microsoft.WindowsFeedbackHub',
    'Microsoft.WindowsMaps',
    'Microsoft.YourPhone',
    'Microsoft.ZuneMusic',
    'Microsoft.ZuneVideo'
)
Write-Host "  The following apps will be removed:" -ForegroundColor White
foreach ($p in $packages) {
    Write-Host "    - $p" -ForegroundColor Gray
}
Write-Host "`n  Press 1 to confirm removal, or any other key to cancel. (30s timeout)" -ForegroundColor Yellow

function Wait-KeyOrTimeout($seconds, $message) {
    Write-Host $message -NoNewline
    $end = (Get-Date).AddSeconds($seconds)
    while ((Get-Date) -lt $end) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            return $key.KeyChar
        }
        Start-Sleep -Milliseconds 200
    }
    return $null
}

$confirm = Wait-KeyOrTimeout 30 "  Your choice: "
if ($null -eq $confirm) {
    Write-Host "`n  Timeout reached. Exiting..." -ForegroundColor Yellow
    Start-Sleep -Seconds 1
    exit
}
Write-Host $confirm

if ($confirm -ne '1') {
    Write-Host "  Removal cancelled." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    exit
}

$removed = @()
$failed  = @()
foreach ($pkg in $packages) {
    try {
        Get-AppxPackage -Name $pkg -ErrorAction Stop | Remove-AppxPackage -ErrorAction Stop
        $removed += $pkg
    } catch {
        $failed += $pkg
    }
}
if ($removed.Count -gt 0) { Write-Host "`n  Removed: $($removed -join ', ')" -ForegroundColor Green }
if ($failed.Count -gt 0) { Write-Host "  Failed: $($failed -join ', ')" -ForegroundColor Red }
if ($removed.Count -eq 0 -and $failed.Count -eq 0) { Write-Host "  No packages found to remove." -ForegroundColor Yellow }
Write-Host "`n  --------------------------------------------------------" -ForegroundColor Cyan
Write-Host "  Process finished. This window will close in 10 seconds, or press Enter." -ForegroundColor Green
$timeout = 10
while ($timeout -gt 0) {
    if ([Console]::KeyAvailable) {
        $key = [Console]::ReadKey($true)
        if ($key.Key -eq "Enter") { break }
    }
    Start-Sleep -Seconds 1
    $timeout--
}
'@

    [System.IO.File]::WriteAllText($tempPs1, $debloatScript, [System.Text.Encoding]::UTF8)

    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempPs1`"" -PassThru
    $proc.WaitForExit()

    # Clear any stray keys
    while ([Console]::KeyAvailable) { [Console]::ReadKey($true) | Out-Null }
    Write-Host "`n  Debloat window closed. Returning to main menu." -ForegroundColor Cyan
    Start-Sleep -Milliseconds 300
}

# ----- Clean exit with history removal -----
function Exit-And-Clean {
    try {
        $historyPaths = @(
            "$env:APPDATA\Microsoft\Windows\PowerShell\PSReadLine\ConsoleHost_history.txt"
            (Get-PSReadLineOption).HistorySavePath
        )
        foreach ($hp in $historyPaths) {
            if ($hp -and (Test-Path $hp)) { Remove-Item $hp -Force -ErrorAction SilentlyContinue }
        }
    } catch {}
    exit
}

# ----- Get MAS version with fallback (fixes v?.?) -----
function Get-MASVersion {
    $primaryUrl   = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd"
    $fallbackUrl  = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd"
    $urls = @($primaryUrl, $fallbackUrl)
    foreach ($url in $urls) {
        try {
            $raw = Invoke-RestMethod -Uri $url -ErrorAction Stop
            if ($raw -match 'set\s+masver=([\d.]+)') { return $Matches[1] }
        } catch {}
    }
    return "?.?"
}

# ============================================================
#  MAIN MENU (Box UI, 30-sec idle exit, key buffer cleared)
# ============================================================
while ($true) {
    $masver = Get-MASVersion
    Clear-Host

    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor DarkCyan
    Write-Host "  ║        T H E   O N E   S Y S T E M S   v$masver          ║" -ForegroundColor Cyan
    Write-Host "  ║         Authorized Operations Terminal                   ║" -ForegroundColor DarkGray
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor DarkCyan
    Write-Host "  ║  PC Name      : $($pcName.PadRight(35))   ║" -ForegroundColor White
    Write-Host "  ║  User Account : $($userName.PadRight(35))   ║" -ForegroundColor White
    Write-Host "  ║  Brand        : $($brand.PadRight(35))   ║" -ForegroundColor White
    Write-Host "  ║  MAC Address  : $($macAddress.PadRight(35))   ║" -ForegroundColor White
    Write-Host "  ║  Local IP     : $($localIp.PadRight(35))   ║" -ForegroundColor White
    Write-Host "  ║  Windows      : $($windowsVersion.PadRight(35))   ║" -ForegroundColor White
    Write-Host "  ║  Install Date : $($installDate.PadRight(35))   ║" -ForegroundColor White
    Write-Host "  ║  Processor    : $($processor.PadRight(35))   ║" -ForegroundColor White
    Write-Host "  ║  RAM          : $($ram.PadRight(35))   ║" -ForegroundColor White
    Write-Host "  ║  Storage (C:) : $($storage.PadRight(35))   ║" -ForegroundColor White
    Write-Host "  ╠══════════════════════════════════════════════════════════╣" -ForegroundColor DarkCyan
    Write-Host "  ║  [1] Reactivate THE ONE PC Authorized Windows           ║" -ForegroundColor Green
    Write-Host "  ║  [2] Reactivate THE ONE PC Office                       ║" -ForegroundColor Green
    Write-Host "  ║  [3] THE ONE PC Optimization                            ║" -ForegroundColor Green
    Write-Host "  ║  [4] Full THE ONE Activation Suite (All Options)        ║" -ForegroundColor Green
    Write-Host "  ║  [5] THE ONE Software Installer                         ║" -ForegroundColor Green
    Write-Host "  ║  [6] THE ONE Debloat Windows                            ║" -ForegroundColor Green
    Write-Host "  ║  [0] Exit Terminal                                      ║" -ForegroundColor DarkGray
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor DarkCyan

    # Clear any leftover keystrokes before waiting
    while ([Console]::KeyAvailable) { [Console]::ReadKey($true) | Out-Null }

    Write-Host "`n  > Select module (30s idle exit): " -NoNewline
    $startTime = Get-Date
    $timeoutSeconds = 30
    $key = $null
    while ($null -eq $key -and ((Get-Date) - $startTime).TotalSeconds -lt $timeoutSeconds) {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            break
        }
        Start-Sleep -Milliseconds 200
    }

    if ($null -eq $key) {
        Write-Host "`n  [!] No input detected for 30 seconds. Exiting..." -ForegroundColor Red
        Start-Sleep -Seconds 2
        Exit-And-Clean
    }

    $keyChar = $key.KeyChar
    Write-Host $keyChar -ForegroundColor White

    if ($keyChar -eq '0') { Exit-And-Clean }

    switch ($keyChar) {
        '1' { Start-Activation "/HWID" "Windows Activation" }
        '2' { Start-Activation "/Ohook" "Office Activation" }
        '3' { Invoke-DeepClean }
        '4' {
            Write-Host "`n  [+] Launching Full THE ONE Activation Suite..." -ForegroundColor Cyan
            iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
        }
        '5' { Invoke-SoftwareInstall }
        '6' { Invoke-Debloat }
    }
}
