# launcher.ps1 - THE ONE SYSTEM v3.12 (生成 .bat 激活，Defender 不拦截)

# 清除终端历史
try {
    [Microsoft.PowerShell.PSConsoleReadLine]::ClearHistory()
    Clear-History
    $hp = (Get-PSReadLineOption).HistorySavePath
    if ($hp -and (Test-Path $hp)) { Remove-Item $hp -Force -ErrorAction SilentlyContinue }
} catch {}

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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

# ---------- 激活：生成纯文本 .bat 文件，只包含您验证过的安全命令 ----------
function Start-Activation($Mode) {
    Write-Host "`n  [+] 正在准备激活..." -ForegroundColor Green
    $tempBat = "$env:TEMP\THE_ONE_Activate.bat"
    # 只写入最简单的原版 MAS 在线激活命令，Defender 绝不会拦截
    @"
@echo off
title THE ONE Activation
powershell -NoExit -Command "irm https://get.activated.win | iex ; $Mode"
"@ | Out-File -FilePath $tempBat -Encoding ASCII
    Start-Process -FilePath cmd.exe -ArgumentList "/c `"$tempBat`"" -Wait
    Remove-Item $tempBat -Force -ErrorAction SilentlyContinue
    Write-Host "`n  激活窗口已关闭，返回主菜单。" -ForegroundColor Cyan
}

function Invoke-DeepClean {
    Write-Host "`n  [+] 正在深度清理临时文件...`n" -ForegroundColor Cyan
    $folders = @($env:TEMP, "$env:SystemRoot\Temp", "$env:SystemRoot\Prefetch", [Environment]::GetFolderPath('Recent'), "$env:LOCALAPPDATA\Microsoft\Windows\INetCache", "$env:LOCALAPPDATA\Microsoft\Windows\Temporary Internet Files")
    foreach ($f in $folders) {
        if (Test-Path $f) {
            Write-Host "  清理: $f" -ForegroundColor DarkGray
            $items = Get-ChildItem $f -Recurse -Force -ErrorAction SilentlyContinue
            $c = 0
            foreach ($i in $items) { try { Remove-Item $i.FullName -Force -Recurse -ErrorAction Stop } catch {}; $c++; if ($c % 50 -eq 0) { Write-Host "." -NoNewline } }
            Write-Host " 完成。"
        }
    }
    try { cleanmgr /sagerun:1 | Out-Null } catch {}
    Write-Host "`n  [+] 优化完成，7 秒后退出所有终端..." -ForegroundColor Green
    Start-Sleep 7
    Exit-And-Clean
}

function Invoke-SoftwareInstall {
    Write-Host "`n  正在启动软件安装器..." -ForegroundColor Cyan
    $tempPs1 = "$env:TEMP\THE_ONE_INSTALL.ps1"
    @'
$host.UI.RawUI.WindowTitle = "THE ONE Software Installer (30s auto-close)"
Write-Host "`n  --------------------------------------------------------" -ForegroundColor Cyan
Write-Host "        T H E   O N E   S O F T W A R E   I N S T A L L E R" -ForegroundColor Cyan
Write-Host "  --------------------------------------------------------`n"
function Wait-KeyOrTimeout($s, $msg) { Write-Host $msg -NoNewline; $end = (Get-Date).AddSeconds($s); while ((Get-Date) -lt $end) { if ([Console]::KeyAvailable) { $k = [Console]::ReadKey($true); return $k.KeyChar } Start-Sleep -Milliseconds 200 } return $null }
if (!(Get-Command winget.exe -ErrorAction SilentlyContinue)) { Write-Host "  [ERROR] 未找到 winget。" -ForegroundColor Red; Read-Host "  按 Enter 返回"; exit }
Write-Host "  [1] Google Chrome`n  [2] 7-Zip`n  [3] VLC`n  [4] GIMP`n  [A] 全部安装 (1-3)`n  [0] 返回" -ForegroundColor White
$choice = Wait-KeyOrTimeout 30 "  输入选项 (30s 超时): "; if (!$choice) { Write-Host "`n  超时。"; Start-Sleep 1; exit }
Write-Host $choice
switch -Wildcard ($choice) {
    '0' { exit }
    'A' { winget install --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements; winget install --id 7zip.7zip --silent --accept-source-agreements --accept-package-agreements; winget install --id VideoLAN.VLC --silent --accept-source-agreements --accept-package-agreements }
    '1' { winget install --id Google.Chrome --silent --accept-source-agreements --accept-package-agreements }
    '2' { winget install --id 7zip.7zip --silent --accept-source-agreements --accept-package-agreements }
    '3' { winget install --id VideoLAN.VLC --silent --accept-source-agreements --accept-package-agreements }
    '4' { winget install --id GIMP.GIMP --silent --accept-source-agreements --accept-package-agreements }
    default { Write-Host "  无效选项。" -ForegroundColor Red; Start-Sleep 2 }
}
Write-Host "`n  安装完成。窗口将在 10 秒内关闭，或按 Enter 立即关闭。" -ForegroundColor Green
$timeout = 10; while ($timeout -gt 0) { if ([Console]::KeyAvailable) { $k = [Console]::ReadKey($true); if ($k.Key -eq "Enter") { break } } Start-Sleep 1; $timeout-- }
'@ | Out-File -FilePath $tempPs1 -Encoding UTF8
    $p = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempPs1`"" -PassThru
    $p.WaitForExit()
    Remove-Item $tempPs1 -Force -ErrorAction SilentlyContinue
    while ([Console]::KeyAvailable) { [Console]::ReadKey($true) | Out-Null }
    Write-Host "`n  安装器已关闭。" -ForegroundColor Cyan
}

function Invoke-Debloat {
    Write-Host "`n  [+] 正在移除预装应用..." -ForegroundColor Cyan
    $tempPs1 = "$env:TEMP\THE_ONE_DEBLOAT.ps1"
    @'
$host.UI.RawUI.WindowTitle = "THE ONE Debloater (30s auto-close)"
Write-Host "`n  --------------------------------------------------------" -ForegroundColor Cyan
Write-Host "              T H E   O N E   D E B L O A T E R" -ForegroundColor Cyan
Write-Host "  --------------------------------------------------------`n"
$packages = @('Microsoft.549981C3F5F10','Microsoft.MicrosoftOfficeHub','Microsoft.OneDriveSync','Microsoft.XboxApp','Microsoft.XboxGameCallableUI','Microsoft.XboxSpeechToTextOverlay','Microsoft.Xbox.TCUI','Microsoft.XboxGamingOverlay','Microsoft.XboxIdentityProvider','Microsoft.BingNews','Microsoft.BingWeather','Microsoft.BingSports','Microsoft.BingFinance','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.MicrosoftSolitaireCollection','Microsoft.MixedReality.Portal','Microsoft.SkypeApp','Microsoft.WindowsFeedbackHub','Microsoft.WindowsMaps','Microsoft.YourPhone','Microsoft.ZuneMusic','Microsoft.ZuneVideo')
Write-Host "  以下应用将被移除:" -ForegroundColor White; foreach ($p in $packages) { Write-Host "    - $p" -ForegroundColor Gray }
Write-Host "`n  按 1 确认移除，按其他键取消 (30s 超时):" -ForegroundColor Yellow
function Wait-KeyOrTimeout($s, $msg) { Write-Host $msg -NoNewline; $end = (Get-Date).AddSeconds($s); while ((Get-Date) -lt $end) { if ([Console]::KeyAvailable) { $k = [Console]::ReadKey($true); return $k.KeyChar } Start-Sleep -Milliseconds 200 } return $null }
$confirm = Wait-KeyOrTimeout 30 "  您的选择: "; if (!$confirm) { Write-Host "`n  超时。"; Start-Sleep 1; exit }
Write-Host $confirm
if ($confirm -ne '1') { Write-Host "  已取消。" -ForegroundColor Yellow; Start-Sleep 2; exit }
Write-Host "`n  正在移除..." -ForegroundColor Gray
$removed = @(); $failed = @()
foreach ($pkg in $packages) { try { Get-AppxPackage -Name $pkg -ErrorAction Stop | Remove-AppxPackage -ErrorAction Stop; $removed += $pkg } catch { $failed += $pkg } }
if ($removed.Count) { Write-Host "`n  已移除: $($removed -join ', ')" -ForegroundColor Green }
if ($failed.Count) { Write-Host "  失败: $($failed -join ', ')" -ForegroundColor Red }
if (!$removed -and !$failed) { Write-Host "  未发现任何包。" -ForegroundColor Yellow }
Write-Host "`n  操作完成。窗口将在 10 秒内关闭，或按 Enter 立即关闭。" -ForegroundColor Green
$timeout = 10; while ($timeout -gt 0) { if ([Console]::KeyAvailable) { $k = [Console]::ReadKey($true); if ($k.Key -eq "Enter") { break } } Start-Sleep 1; $timeout-- }
'@ | Out-File -FilePath $tempPs1 -Encoding UTF8
    $p = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempPs1`"" -PassThru
    $p.WaitForExit()
    Remove-Item $tempPs1 -Force -ErrorAction SilentlyContinue
    while ([Console]::KeyAvailable) { [Console]::ReadKey($true) | Out-Null }
    Write-Host "`n  去臃肿已完成。" -ForegroundColor Cyan
}

function Exit-And-Clean {
    try { $hp = (Get-PSReadLineOption).HistorySavePath; if ($hp -and (Test-Path $hp)) { Remove-Item $hp -Force -ErrorAction SilentlyContinue } } catch {}
    exit
}

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
    Write-Host "  [4] THE ONE Software Installer" -ForegroundColor Green
    Write-Host "  [5] THE ONE PC Optimization" -ForegroundColor Green
    Write-Host "  [6] THE ONE Debloat Windows" -ForegroundColor Green
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
        Write-Host "`n  [!] 30 秒无操作，自动退出..." -ForegroundColor Red
        Start-Sleep 2
        Exit-And-Clean
    }

    $ch = $key.KeyChar
    Write-Host $ch -ForegroundColor White
    if ($ch -eq '0') { Exit-And-Clean }

    switch ($ch) {
        '1' { Start-Activation "/HWID" }
        '2' { Start-Activation "/Ohook" }
        '3' {
            Write-Host "`n  [+] Launching Full THE ONE Activation Suite..." -ForegroundColor Cyan
            cmd /c "start `"Full MAS`" powershell -NoExit -Command `"irm https://get.activated.win | iex`""
        }
        '4' { Invoke-SoftwareInstall }
        '5' { Invoke-DeepClean }
        '6' { Invoke-Debloat }
    }
}
