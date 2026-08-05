# launcher.ps1 - THE ONE SYSTEM v3.2 (Dual fallback URLs, zero red errors)

# ---------- Privacy Cleanup ----------
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

$pcName = $env:COMPUTERNAME
$userName = $env:USERNAME

# IP Address (silent fallback to ipconfig)
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

# MAC Address (silent fallback to getmac)
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

# Brand
$brand = "Unknown"
try { $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop; if ($cs.Manufacturer) { $brand = $cs.Manufacturer } } catch {}

# Windows Version
$windowsVersion = "Unknown"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $caption = $os.Caption -replace 'Microsoft ', ''
    $dv = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).DisplayVersion
    if ($dv) { $caption += " $dv" }
    $windowsVersion = $caption
} catch {}

# Install Date
$installDate = "Unknown"
try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop; if ($os.InstallDate) { $installDate = $os.InstallDate.ToString("yyyy-MM-dd") } } catch {}

# Processor
$processor = "Unknown"
try {
    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
    $processor = $cpu.Name -replace '\s+', ' '
    if ($processor.Length -gt 45) { $processor = $processor.Substring(0, 45) + "..." }
} catch {}

# RAM
$ram = "Unknown"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $ram = "$totalGB GB"
} catch {}

# Disk C:
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

# ------------------------------------------------------------
#  Download Function (with fallback URLs)
# ------------------------------------------------------------
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

    throw "Unable to download MAS script from any known URL. Please check your internet connection or contact support."
}

function Start-Activation {
    param([string]$Mode, [string]$FriendlyName)
    Write-Host "`n  [+] Access Granted! Starting $FriendlyName..." -ForegroundColor Green

    $tempAIO   = "$env:TEMP\THE_ONE_AIO.cmd"
    $tempRun   = "$env:TEMP\THE_ONE_RUN.cmd"
    $flagFile  = "$env:TEMP\THE_ONE_EXIT.flag"

    try {
        # Get script (auto fallback)
        $raw = Get-MASScript

        # Extract version
        $ver = '?.?'
        if ($raw -match 'set\s+masver=([\d.]+)') { $ver = $Matches[1] }

        # Only modify title
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
    Write-Host "`n  [+] PC Optimized successfully. Exiting all terminals now..." -ForegroundColor Green
    Start-Sleep -Seconds 2
    Exit-And-Clean
}

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

function Get-MASVersion {
    try {
        $raw = Invoke-RestMethod "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd" -ErrorAction Stop
        if ($raw -match 'set\s+masver=([\d.]+)') { return $Matches[1] }
    } catch {}
    return "?.?"
}

# ------------------------------------------------------------
#  [5] WinGet App Installer
# ------------------------------------------------------------
function Start-WingetInstaller {
    $flagFile = "$env:TEMP\THE_ONE_EXIT.flag"
    Remove-Item -Path $flagFile -Force -ErrorAction SilentlyContinue

    $tempPs1 = "$env:TEMP\THE_ONE_WINGET.ps1"

    $scriptContent = @'
$Host.UI.RawUI.WindowTitle = "THE ONE"
$flagFile = "$env:TEMP\THE_ONE_EXIT.flag"

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================" -ForegroundColor Cyan
    Write-Host "       T H E   O N E   S Y S T E M S" -ForegroundColor Cyan
    Write-Host "  ================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  WinGet App Installer - Ad-Free Only" -ForegroundColor White
    Write-Host ""
    Write-Host "  -----------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  [1] Google Chrome" -ForegroundColor White
    Write-Host "  [2] 7-Zip" -ForegroundColor White
    Write-Host "  [3] MPC-HC Media Player" -ForegroundColor White
    Write-Host "  [4] Install ALL of the above" -ForegroundColor Green
    Write-Host "  [0] Close this terminal (Back to main menu)" -ForegroundColor DarkGray
    Write-Host "  -----------------------------------------------" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  AUTHORIZED AND DESIGN BY THE ONE SERVER 2026" -ForegroundColor DarkGray
    Write-Host ""
}

function Test-WingetAvailable {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        Write-Host ""
        Write-Host "  [!] WinGet not found." -ForegroundColor Red
        Write-Host "      Please install 'App Installer' from Microsoft Store." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  Press any key to return..." -ForegroundColor DarkGray
        $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        return $false
    }
}

function Install-App {
    param([string]$Id, [string]$Name)
    Write-Host "  [>] Installing $Name..." -ForegroundColor Cyan -NoNewline
    try {
        $proc = Start-Process -FilePath "winget" -ArgumentList "install","--id",$Id,"-e","--silent","--accept-package-agreements","--accept-source-agreements" -Wait -PassThru -WindowStyle Hidden
        if ($proc.ExitCode -eq 0) {
            Write-Host " [OK]" -ForegroundColor Green
        } else {
            Write-Host " [ExitCode $($proc.ExitCode)]" -ForegroundColor Yellow
        }
    } catch {
        Write-Host " [FAIL]" -ForegroundColor Red
    }
}

if (-not (Test-WingetAvailable)) {
    if (Test-Path $flagFile) { Remove-Item $flagFile -Force -ErrorAction SilentlyContinue }
    exit
}

while ($true) {
    Show-Menu
    Write-Host "  > Enter numbers (e.g. 1 3, or type 'all'): " -NoNewline -ForegroundColor White
    $input = Read-Host
    $input = $input.Trim().ToLower()

    if ($input -eq '0') { break }
    if ($input -eq 'all' -or $input -eq '4') { $input = '1 2 3' }

    $selected = @()
    foreach ($c in $input.ToCharArray()) {
        if ($c -eq ' ') { continue }
        if ($c -in @('1','2','3')) { $selected += $c }
    }
    $selected = $selected | Select-Object -Unique

    if ($selected.Count -eq 0) {
        Write-Host ""
        Write-Host "  [!] Invalid input. Try again." -ForegroundColor Red
        Start-Sleep -Seconds 2
        continue
    }

    Write-Host ""
    Write-Host "  Starting installation..." -ForegroundColor Green
    Write-Host ""

    foreach ($s in $selected) {
        switch ($s) {
            '1' { Install-App -Id "Google.Chrome" -Name "Google Chrome" }
            '2' { Install-App -Id "7zip.7zip" -Name "7-Zip" }
            '3' { Install-App -Id "clsid2.mpc-hc" -Name "MPC-HC Media Player" }
        }
    }

    Write-Host ""
    Write-Host "  [+] Installation complete." -ForegroundColor Green
    Write-Host ""
    Write-Host "  Press any key to return to main menu (30s timeout)..." -ForegroundColor DarkGray

    $timeout = 30
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $pressed = $false
    while ($sw.Elapsed.TotalSeconds -lt $timeout) {
        if ($Host.UI.RawUI.KeyAvailable) {
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
            $pressed = $true
            break
        }
        Start-Sleep -Milliseconds 100
    }
    $sw.Stop()

    if (-not $pressed) {
        Write-Host ""
        Write-Host "  [!] Timeout. Closing all terminals..." -ForegroundColor Red
        "timeout" | Out-File -FilePath $flagFile -Encoding ASCII -Force
        Start-Sleep -Seconds 1
        exit
    }
}

if (Test-Path $flagFile) { Remove-Item $flagFile -Force -ErrorAction SilentlyContinue }
'@

    [System.IO.File]::WriteAllText($tempPs1, $scriptContent, [System.Text.Encoding]::UTF8)

    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-WindowStyle","Normal","-File","$tempPs1" -PassThru
    $proc.WaitForExit()

    if (Test-Path $flagFile) {
        Remove-Item -Path $flagFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempPs1 -Force -ErrorAction SilentlyContinue
        Write-Host "`n  [!] Installer timed out. Exiting all terminals..." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Exit-And-Clean
    } else {
        Remove-Item -Path $tempPs1 -Force -ErrorAction SilentlyContinue
        Write-Host "`n  [+] Installer closed. Returning to main menu." -ForegroundColor Cyan
    }
}

# ------------------------------------------------------------
#  [6] Safe App Uninstaller
# ------------------------------------------------------------
function Start-AppUninstaller {
    $flagFile = "$env:TEMP\THE_ONE_EXIT.flag"
    Remove-Item -Path $flagFile -Force -ErrorAction SilentlyContinue

    $tempPs1 = "$env:TEMP\THE_ONE_UNINSTALL.ps1"

    $scriptContent = @'
$Host.UI.RawUI.WindowTitle = "THE ONE"
$flagFile = "$env:TEMP\THE_ONE_EXIT.flag"

function Show-Menu {
    Clear-Host
    Write-Host ""
    Write-Host "  ================================================" -ForegroundColor Cyan
    Write-Host "       T H E   O N E   S Y S T E M S" -ForegroundColor Cyan
    Write-Host "  ================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Safe App Uninstaller - 100% Stable" -ForegroundColor White
    Write-Host ""
    Write-Host "  The following apps/services will be REMOVED:" -ForegroundColor White
    Write-Host ""
    Write-Host "    [1] Microsoft OneDrive" -ForegroundColor White
    Write-Host "    [2] Cortana" -ForegroundColor White
    Write-Host "    [3] Xbox App" -ForegroundColor White
    Write-Host "    [4] Xbox Game Bar" -ForegroundColor White
    Write-Host "    [5] Xbox SpeechToText Overlay" -ForegroundColor White
    Write-Host ""
    Write-Host "  -----------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  [1] Confirm and Uninstall" -ForegroundColor Yellow
    Write-Host "  [6] Uninstall ALL listed above" -ForegroundColor Green
    Write-Host "  [0] Close this window (Back to main menu)" -ForegroundColor DarkGray
    Write-Host "  -----------------------------------------------" -ForegroundColor DarkCyan
    Write-Host ""
    Write-Host "  AUTHORIZED AND DESIGN BY THE ONE SERVER 2026" -ForegroundColor DarkGray
    Write-Host ""
}

function Remove-Safe {
    param([string]$Name, [scriptblock]$Action)
    Write-Host "  [>] Removing $Name..." -ForegroundColor Cyan -NoNewline
    try {
        & $Action
        Write-Host " [OK]" -ForegroundColor Green
    } catch {
        if ($_.Exception.Message -match "Cannot find") {
            Write-Host " [Already removed or not found]" -ForegroundColor DarkGray
        } else {
            Write-Host " [SKIP]" -ForegroundColor Yellow
        }
    }
}

while ($true) {
    Show-Menu
    Write-Host "  > Select: " -NoNewline -ForegroundColor White
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    Write-Host "$key" -ForegroundColor White
    Write-Host ""

    if ($key -eq '0') { break }

    if ($key -eq '1' -or $key -eq '6') {
        Write-Host "  Starting uninstallation..." -ForegroundColor Green
        Write-Host ""

        Remove-Safe "Microsoft OneDrive" {
            Start-Process -FilePath "winget" -ArgumentList "uninstall","--id","Microsoft.OneDrive","--silent","--accept-source-agreements" -Wait -WindowStyle Hidden
        }

        Remove-Safe "Cortana" {
            Start-Process -FilePath "winget" -ArgumentList "uninstall","--id","Microsoft.549981C3F5F10","--silent","--accept-source-agreements" -Wait -WindowStyle Hidden
        }

        Remove-Safe "Xbox App" {
            Get-AppxPackage -AllUsers Microsoft.XboxApp | Remove-AppxPackage -ErrorAction Stop
        }

        Remove-Safe "Xbox Game Bar" {
            Get-AppxPackage -AllUsers Microsoft.XboxGamingOverlay | Remove-AppxPackage -ErrorAction Stop
        }

        Remove-Safe "Xbox SpeechToText Overlay" {
            Get-AppxPackage -AllUsers Microsoft.XboxSpeechToTextOverlay | Remove-AppxPackage -ErrorAction Stop
        }

        Write-Host ""
        Write-Host "  [+] Uninstallation complete." -ForegroundColor Green
        Write-Host ""
        Write-Host "  Press any key to return to main menu (30s timeout)..." -ForegroundColor DarkGray

        $timeout = 30
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        $pressed = $false
        while ($sw.Elapsed.TotalSeconds -lt $timeout) {
            if ($Host.UI.RawUI.KeyAvailable) {
                $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
                $pressed = $true
                break
            }
            Start-Sleep -Milliseconds 100
        }
        $sw.Stop()

        if (-not $pressed) {
            Write-Host ""
            Write-Host "  [!] Timeout. Closing all terminals..." -ForegroundColor Red
            "timeout" | Out-File -FilePath $flagFile -Encoding ASCII -Force
            Start-Sleep -Seconds 1
            exit
        }
    } else {
        Write-Host "  [!] Invalid selection." -ForegroundColor Red
        Start-Sleep -Seconds 2
    }
}

if (Test-Path $flagFile) { Remove-Item $flagFile -Force -ErrorAction SilentlyContinue }
'@

    [System.IO.File]::WriteAllText($tempPs1, $scriptContent, [System.Text.Encoding]::UTF8)

    $proc = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-WindowStyle","Normal","-File","$tempPs1" -PassThru
    $proc.WaitForExit()

    if (Test-Path $flagFile) {
        Remove-Item -Path $flagFile -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $tempPs1 -Force -ErrorAction SilentlyContinue
        Write-Host "`n  [!] Uninstaller timed out. Exiting all terminals..." -ForegroundColor Red
        Start-Sleep -Seconds 1
        Exit-And-Clean
    } else {
        Remove-Item -Path $tempPs1 -Force -ErrorAction SilentlyContinue
        Write-Host "`n  [+] Uninstaller closed. Returning to main menu." -ForegroundColor Cyan
    }
}

# ------------------------------------------------------------
#  Modern Clean Interface
# ------------------------------------------------------------
while ($true) {
    $masver = Get-MASVersion
    Clear-Host

    Write-Host "`n  T H E   O N E   S Y S T E M S   v$masver" -ForegroundColor Cyan
    Write-Host "  Authorized Operations Terminal" -ForegroundColor DarkGray
    Write-Host "  -----------------------------------------------" -ForegroundColor DarkCyan

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

    Write-Host "  -----------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  [1] Reactivate THE ONE PC Authorized Windows" -ForegroundColor Green
    Write-Host "  [2] Reactivate THE ONE PC Office" -ForegroundColor Green
    Write-Host "  [3] THE ONE PC Optimization" -ForegroundColor Green
    Write-Host "  [4] Full THE ONE Activation Suite (All Options)" -ForegroundColor Green
    Write-Host "  [5] Install Essential Apps (WinGet)" -ForegroundColor Green
    Write-Host "  [6] Remove Bulky Windows Apps (Safe)" -ForegroundColor Green
    Write-Host "  [0] Exit Terminal" -ForegroundColor DarkGray
    Write-Host "  -----------------------------------------------" -ForegroundColor DarkCyan
    Write-Host "  AUTHORIZED AND DESIGN BY THE ONE SERVER 2026" -ForegroundColor DarkGray

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
        '5' { Start-WingetInstaller }
        '6' { Start-AppUninstaller }
    }
}
