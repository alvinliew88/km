# launcher.ps1 - THE ONE SYSTEM v3.1 (Stable: GIMP included, PDF24 multi-ID, version fix)

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
    if ($processor.Length -gt 45) { $processor = $processor.Substring(0, 45) + "..." }
} catch {}

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

# ----- Activation (keeps window open, 7-sec timeout) -----
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
echo    Press any key within 7 seconds to return to main menu.
echo    Otherwise ALL TERMINALS WILL BE CLOSED.
echo   --------------------------------------------------------
echo.

choice /c 0 /t 7 /d 0 /n >nul
if errorlevel 2 goto :stay
echo timeout > "$flagFile"
:stay
exit
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
            Write-Host "`n  [+] User pressed a key. Returning to main menu." -ForegroundColor Cyan
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

# ----- Software Installer (Menu 5) – GIMP included, PDF24 multi-ID + web fallback -----
function Invoke-SoftwareInstall {
    Write-Host "`n  Launching Software Installation Menu in a new window..." -ForegroundColor Cyan

    $tempPs1 = "$env:TEMP\THE_ONE_INSTALL.ps1"

    $installerScript = @'
$host.UI.RawUI.WindowTitle = "THE ONE Software Installer"
Write-Host "`n  --------------------------------------------------------" -ForegroundColor Cyan
Write-Host "        T H E   O N E   S O F T W A R E   I N S T A L L E R" -ForegroundColor Cyan
Write-Host "  --------------------------------------------------------`n"
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
Write-Host "  │  [2] GIMP (Image Editor)                    │"
Write-Host "  │  [3] PDF24 (PDF Tool)                       │"
Write-Host "  │  [4] 7-Zip (Archive Utility)                │"
Write-Host "  │  [5] VLC Media Player                       │"
Write-Host "  │  [A] Install ALL                            │"
Write-Host "  │  [0] Return to Main Menu                    │"
Write-Host "  └─────────────────────────────────────────────┘`n"
$choice = Read-Host "  Enter your choice"

function Install-PDF24 {
    Write-Host "  Attempting to install PDF24 via winget..." -ForegroundColor Yellow
    $ids = @("PDF24.PDF24", "PDF24.Creator", "geeksoftware.PDF24.Creator")
    $installed = $false
    foreach ($id in $ids) {
        winget install --id $id --silent --accept-source-agreements --accept-package-agreements
        if ($LASTEXITCODE -eq 0) {
            $installed = $true
            Write-Host "  Successfully installed using ID: $id" -ForegroundColor Green
            break
        }
    }
    if (-not $installed) {
        Write-Host "  Could not install PDF24 automatically." -ForegroundColor Red
        Write-Host "  Opening official download page in your browser..." -ForegroundColor Yellow
        Start-Process "https://tools.pdf24.org/en/creator"
        Write-Host "  Please download and install manually." -ForegroundColor Cyan
    }
}

switch -Wildcard ($choice.ToUpper()) {
    '0' { exit }
    'A' {
        winget install --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements
        winget install --id GIMP.GIMP --silent --accept-source-agreements --accept-package-agreements
        Install-PDF24
        winget install --id 7zip.7zip --silent --accept-source-agreements --accept-package-agreements
        winget install --id VideoLAN.VLC --silent --accept-source-agreements --accept-package-agreements
    }
    '1' { winget install --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements }
    '2' { winget install --id GIMP.GIMP --silent --accept-source-agreements --accept-package-agreements }
    '3' { Install-PDF24 }
    '4' { winget install --id 7zip.7zip --silent --accept-source-agreements --accept-package-agreements }
    '5' { winget install --id VideoLAN.VLC --silent --accept-source-agreements --accept-package-agreements }
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

    Write-Host "`n  Installer window closed. Returning to main menu." -ForegroundColor Cyan
}

# ----- Debloat Windows (Menu 6) – Stable -----
function Invoke-Debloat {
    Write-Host "`n  [+] Removing bloatware in a new window..." -ForegroundColor Cyan

    $tempPs1 = "$env:TEMP\THE_ONE_DEBLOAT.ps1"

    $debloatScript = @'
$host.UI.RawUI.WindowTitle = "THE ONE Debloater"
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
if ($removed.Count -gt 0) { Write-Host "  Removed: $($removed -join ', ')" -ForegroundColor Green }
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

    Write-Host "`n  Debloat window closed. Returning to main menu." -ForegroundColor Cyan
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
#  MAIN MENU (Modern Clean UI)
# ============================================================
while ($true) {
    $masver = Get-MASVersion
    Clear-Host

    Write-Host "`n  T H E   O N E   S Y S T E M S   v$masver" -ForegroundColor Cyan
    Write-Host "  Authorized Operations Terminal" -ForegroundColor DarkGray
    Write-Host "  ────────────────────────────────────────────────" -ForegroundColor DarkCyan

    Write-Host "  PC Name      : $pcName" -ForegroundColor White
    Write-Host "  User Account : $userName" -ForegroundColor White
    Write-Host "  Brand        : $brand" -ForegroundColor White
    Write-Host "  MAC Address  : $macAddress" -ForegroundColor White
    Write-Host "  Local IP     : $localIp" -ForegroundColor White
    Write-Host "  Windows      : $windowsVersion" -ForegroundColor White
    Write-Host "  Install Date : $installDate" -ForegroundColor White
    Write-Host "  Processor    : $processor" -ForegroundColor White
    Write-Host "  RAM          : $ram" -ForegroundColor White
    Write-Host "  Storage (C:) : $storage" -ForegroundColor White

    Write-Host "  ────────────────────────────────────────────────" -ForegroundColor DarkCyan
    Write-Host "  [1] Reactivate THE ONE PC Authorized Windows" -ForegroundColor Green
    Write-Host "  [2] Reactivate THE ONE PC Office" -ForegroundColor Green
    Write-Host "  [3] THE ONE PC Optimization" -ForegroundColor Green
    Write-Host "  [4] Full THE ONE Activation Suite (All Options)" -ForegroundColor Green
    Write-Host "  [5] THE ONE Software Installer" -ForegroundColor Green
    Write-Host "  [6] THE ONE Debloat Windows" -ForegroundColor Green
    Write-Host "  [0] Exit Terminal" -ForegroundColor DarkGray
    Write-Host "  ────────────────────────────────────────────────" -ForegroundColor DarkCyan

    Write-Host "`n  > Select module: " -NoNewline
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    Write-Host "$key" -ForegroundColor White

    if ($key -eq '0') { Exit-And-Clean }

    switch ($key) {
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
