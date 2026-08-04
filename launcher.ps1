# launcher.ps1 - THE ONE SYSTEM v3.12 (Auto-updating activation, simple menu)

# Clear terminal history
try {
    [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
    Clear-History
    $hp = (Get-PSReadLineOption).HistorySavePath
    if ($hp -and (Test-Path $hp)) { Remove-Item $hp -Force -ErrorAction SilentlyContinue }
} catch {}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# System information (silent fallbacks)
$pcName = $env:COMPUTERNAME
$userName = $env:USERNAME

$localIp = "Unknown"
try { $temp = Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred -ErrorAction Stop 2>$null; $localIp = ($temp | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress } catch { try { $l = & ipconfig.exe | Select-String "IPv4 Address"; if ($l) { $localIp = ($l[0] -replace '.*:\s*', '').Trim() } } catch {} }

$macAddress = "UNKNOWN"
try { $macAddress = (Get-NetAdapter -ErrorAction Stop 2>$null | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { try { $m = & getmac.exe /fo csv; $l = $m -split "`n"; if ($l.Count -ge 2) { $macAddress = ($l[1] -split ',')[0].Trim('"') } } catch {} }

$brand = "Unknown"
try { $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop; if ($cs.Manufacturer) { $brand = $cs.Manufacturer } } catch {}

$windowsVersion = "Unknown"
try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop; $c = $os.Caption -replace 'Microsoft ', ''; $dv = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue).DisplayVersion; if ($dv) { $c += " $dv" }; $windowsVersion = $c } catch {}

$installDate = "Unknown"
try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop; if ($os.InstallDate) { $installDate = $os.InstallDate.ToString("yyyy-MM-dd") } } catch {}

$processor = "Unknown"
try { $cpu = Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1; $processor = $cpu.Name -replace '\s+', ' ' } catch {}

$ram = "Unknown"
try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop; $totalGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1); $ram = "$totalGB GB" } catch {}

$storage = "Unknown"
try { $c = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='C:'" -ErrorAction Stop; $totalGB = [math]::Round($c.Size / 1GB, 1); $freeGB = [math]::Round($c.FreeSpace / 1GB, 1); $storage = "$totalGB GB total / $freeGB GB free" } catch {}

$password = Read-Host "key" -AsSecureString
$passString = if ($password) { [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)) }
if ($passString -ne "8888") { Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red; Start-Sleep 2; exit }

# ---------- Auto-updating activation using official standalone scripts ----------
function Start-Activation {
    param(
        [string]$FriendlyName,      # e.g. "Windows" or "Office"
        [string]$OfficialScript,    # e.g. "HWID_Activation.cmd" or "Ohook_Activation_AIO.cmd"
        [string]$CustomTitle        # e.g. "THE ONE WINDOWS AUTHORIZED v3.12"
    )
    Write-Host "`n  [+] Downloading latest $FriendlyName activation script..." -ForegroundColor Green
    $url = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/Activators/$OfficialScript"
    $tempPath = "$env:TEMP\THE_ONE_$OfficialScript"

    try {
        # Download the official script
        $web = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 10
        $content = $web.Content

        # Replace the title line only (first occurrence)
        $content = $content -replace '(?im)^title .*$', "title  $CustomTitle"

        # Remove the PowerShell diagnostic line that can trigger Defender
        $content = $content -replace '.*PSEdition -ne.*Core.*pstst.*', 'rem disabled for compatibility'

        # Ensure correct line endings
        $content = $content -replace '(?<!\r)\n', "`r`n"
        if (-not $content.EndsWith("`r`n")) { $content += "`r`n" }

        # Save to temp and run
        [System.IO.File]::WriteAllText($tempPath, $content, [System.Text.Encoding]::ASCII)
        Write-Host "  Launching activation window..." -ForegroundColor Cyan
        $proc = Start-Process -FilePath cmd.exe -ArgumentList "/c `"$tempPath`"" -PassThru -Wait
        Remove-Item $tempPath -Force -ErrorAction SilentlyContinue

        Write-Host "`n  Activation window closed. Returning to main menu." -ForegroundColor Cyan
    } catch {
        Write-Host "  [-] Failed to download or run activation script." -ForegroundColor Red
        Start-Sleep 3
    }
}

function Exit-And-Clean {
    try { $hp = (Get-PSReadLineOption).HistorySavePath; if ($hp -and (Test-Path $hp)) { Remove-Item $hp -Force -ErrorAction SilentlyContinue } } catch {}
    exit
}

# ---------- Main menu ----------
while ($true) {
    Clear-Host
    Write-Host "`n  T H E   O N E   S Y S T E M S   v3.12" -ForegroundColor Cyan
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
    Write-Host "  [3] Full THE ONE Activation Suite (All Options)" -ForegroundColor Green
    Write-Host "  [0] Exit Terminal" -ForegroundColor DarkGray
    Write-Host "  ────────────────────────────────────────────────" -ForegroundColor DarkCyan

    while ([Console]::KeyAvailable) { [Console]::ReadKey($true) | Out-Null }
    Write-Host "`n  > Select module (30s idle exit): " -NoNewline

    $timeout = 30
    $key = $null
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    while ($sw.Elapsed.TotalSeconds -lt $timeout -and !$key) {
        if ([Console]::KeyAvailable) { $key = [Console]::ReadKey($true) }
        Start-Sleep -Milliseconds 200
    }
    $sw.Stop()

    if (!$key) {
        Write-Host "`n  [!] No input for 30 seconds. Exiting..." -ForegroundColor Red
        Start-Sleep 2
        Exit-And-Clean
    }

    $ch = $key.KeyChar
    Write-Host $ch -ForegroundColor White
    if ($ch -eq '0') { Exit-And-Clean }

    switch ($ch) {
        '1' { Start-Activation "Windows" "HWID_Activation.cmd" "THE ONE WINDOWS AUTHORIZED v3.12" }
        '2' { Start-Activation "Office" "Ohook_Activation_AIO.cmd" "THE ONE OFFICE AUTHORIZED v3.12" }
        '3' {
            Write-Host "`n  [+] Launching Full THE ONE Activation Suite..." -ForegroundColor Cyan
            cmd /c "start `"Full MAS`" powershell -NoExit -Command `"irm https://get.activated.win | iex`""
        }
    }
}
