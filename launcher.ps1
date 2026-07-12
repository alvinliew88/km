# launcher.ps1 - THE ONE SYSTEM v3.1 (No red errors, universal compatibility)

# 清除终端历史（隐私保护）
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

# IP地址获取（自动回退到 ipconfig，无红字）
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

# MAC地址获取（自动回退到 getmac，无红字）
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

# 品牌（制造商）
$brand = "Unknown"
try { $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop; if ($cs.Manufacturer) { $brand = $cs.Manufacturer } } catch {}

# Windows版本
$windowsVersion = "Unknown"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $caption = $os.Caption -replace 'Microsoft ', ''
    $dv = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).DisplayVersion
    if ($dv) { $caption += " $dv" }
    $windowsVersion = $caption
} catch {}

# 安装日期
$installDate = "Unknown"
try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop; if ($os.InstallDate) { $installDate = $os.InstallDate.ToString("yyyy-MM-dd") } } catch {}

# 处理器
$processor = "Unknown"
try {
    $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1
    $processor = $cpu.Name -replace '\s+', ' '
    if ($processor.Length -gt 45) { $processor = $processor.Substring(0, 45) + "..." }
} catch {}

# 内存
$ram = "Unknown"
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
    $ram = "$totalGB GB"
} catch {}

# C盘存储
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

    $tempAIO   = "$env:TEMP\THE_ONE_AIO.cmd"
    $tempRun   = "$env:TEMP\THE_ONE_RUN.cmd"
    $flagFile  = "$env:TEMP\THE_ONE_EXIT.flag"
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
    # 最终历史记录清理
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
        $raw = Invoke-RestMethod "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd" -ErrorAction Stop
        if ($raw -match 'set\s+masver=([\d.]+)') { return $Matches[1] }
    } catch {}
    return "?.?"
}

# ------------------------------------------------------------
#  现代简洁界面
# ------------------------------------------------------------
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
    }
}
