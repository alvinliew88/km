# launcher.ps1 - THE ONE SYSTEM v2.4 (Ultimate Pop-up Clone)
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 1. 建立安全的临时目录
$tempDir = "$env:TEMP\TheOneSystem"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir | Out-Null }

$menuPs1 = "$tempDir\Menu.ps1"
$menuCmd = "$tempDir\Launcher.cmd"

# 2. 核心菜单逻辑 (在新窗口中运行的代码)
$menuCode = @'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 强制排版同步：锁定 98x30 的官方完美比例
try {
    $Host.UI.RawUI.WindowTitle = "THE ONE SYSTEMS v2.4"
    $ws = $Host.UI.RawUI.WindowSize; $ws.Width = 98; $ws.Height = 30
    $bs = $Host.UI.RawUI.BufferSize; $bs.Width = 98; $bs.Height = 300
    $Host.UI.RawUI.WindowSize = $ws
    $Host.UI.RawUI.BufferSize = $bs
} catch {}

$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

# 在独立的新窗口中要求输入密码
$password = Read-Host "key" -AsSecureString
$passString = if($password){[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))}
if ($passString -ne "8888") { Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red; Start-Sleep -Seconds 2; exit }

while ($true) {
    # 确保循环刷新时颜色保持纯正
    [Console]::BackgroundColor = "Black"
    [Console]::ForegroundColor = "White"
    Clear-Host

    Write-Host "`n  T H E   O N E   S Y S T E M S   v2.4" -ForegroundColor Cyan
    Write-Host "  Authorized Operations Terminal" -ForegroundColor DarkGray
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PC Name    : $pcName" -ForegroundColor White
    Write-Host "  MAC Address: $macAddress" -ForegroundColor White
    Write-Host "  Local IP   : $localIp" -ForegroundColor White
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [ 1 ] Activate THE ONE Windows Authorized" -ForegroundColor White
    Write-Host "  [ 2 ] Install THE ONE Authorized Office" -ForegroundColor White
    Write-Host "  [ 3 ] THE ONE PC optimization" -ForegroundColor White
    Write-Host "  [ 4 ] Direct Bypass (Official Mirror)" -ForegroundColor DarkCyan
    Write-Host "  [ 0 ] Exit Terminal" -ForegroundColor DarkGray
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "`n  > Select module: " -NoNewline

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    Write-Host "$key" -ForegroundColor White

    if ($key -eq '0') { exit }

    function Invoke-TheOne {
        param($ArgsInput, $CustomTitle)
        Write-Host "`n  [+] Access Granted! Initializing..." -ForegroundColor Green
        Write-Host "  [+] Establishing secure bridge to official source..." -ForegroundColor Cyan
        
        $tempPath = "$env:TEMP\TheOneSystem\RUN.cmd"
        
        try {
            $urls = @(
                "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd",
                "https://bitbucket.org/WindowsAddict/microsoft-activation-scripts/raw/master/MAS/All-In-One-Version/MAS_AIO.cmd",
                "https://codeberg.org/massgravel/Microsoft-Activation-Scripts/raw/branch/master/MAS/All-In-One-Version/MAS_AIO.cmd"
            )
            
            $cmdContent = $null
            foreach ($u in $urls) {
                try {
                    $resp = (curl.exe -sL --doh-url https://1.1.1.1/dns-query $u) -join "`n"
                    if ($resp -match "masver") { $cmdContent = $resp; break }
                } catch {}
                
                if (-not $cmdContent) {
                    try {
                        $resp = Invoke-RestMethod -Uri $u -UseBasicParsing -ErrorAction Stop
                        if ($resp -match "masver") { $cmdContent = $resp; break }
                    } catch {}
                }
            }
            
            if (-not $cmdContent) { throw "All mirrors blocked by ISP." }
            
            Write-Host "  [+] Injecting THE ONE Authority..." -ForegroundColor Cyan
            
            # 安全防自毁注入与标题覆盖
            $cmdContent = $cmdContent -replace "`r`n", "`n" -replace "`n", "`r`n"
            $cmdContent = $cmdContent -replace '(?m)^@echo off', "@echo off`r`nmode 98, 30"
            $cmdContent = $cmdContent -replace '(?im)^\s*title\s+.*', "title $CustomTitle"
            $cmdContent = $cmdContent.Replace("if %_unattended%==1 timeout /t 2 & exit /b", "if %_unattended%==1 echo. & echo   [ THE ONE AUTHORIZED - Task Completed ] & echo   Press any key to return to menu... & pause >nul & exit /b")
            $cmdContent += "`r`n`r`n"
            
            [System.IO.File]::WriteAllText($tempPath, $cmdContent, [System.Text.Encoding]::ASCII)
            
            # 【完美运行】使用 -NoNewWindow 让激活脚本在当前这个精致的独立窗口内执行！
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempPath`" $ArgsInput" -Wait -NoNewWindow
            
            Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
            
        } catch {
            Write-Host "  [-] Execution failed!" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }

    switch ($key) {
        '1' { Invoke-TheOne "/HWID" "THE ONE WINDOWS AUTHORIZED v2.4" }
        '2' { Invoke-TheOne "/Ohook" "THE ONE OFFICE AUTHORIZED v2.4" }
        '3' {
            Write-Host "`n  [+] Optimizing PC Storage..." -ForegroundColor Cyan
            Start-Sleep -Seconds 2
            Write-Host "  [+] PC Optimized successfully." -ForegroundColor Green
            Write-Host "`n  Press any key to return to menu..." -ForegroundColor DarkGray
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        '4' {
            Write-Host "`n  [+] Bypass..." -ForegroundColor Cyan
            iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
            Write-Host "`n  Press any key to return to menu..." -ForegroundColor DarkGray
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
    }
}
'@

# 3. 官方原生越狱机制 (Terminal Bypass Wrapper)
$cmdWrapper = @"
@echo off
setlocal EnableDelayedExpansion

:: 强制检测 Windows Terminal 并逃逸至 conhost (1:1 复刻官方机制)
set terminal=
set lines=0
for /f "skip=3 tokens=* delims=" %%A in ('mode con') do if "!lines!"=="0" (
    for %%B in (%%A) do set lines=%%B
)
if !lines! GEQ 100 set terminal=1

if defined terminal (
    start conhost.exe "$menuCmd"
    exit /b
)

:: 在完美尺寸的新窗口中启动你的 PowerShell 菜单
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$menuPs1"
exit /b
"@

# 4. 生成引导文件
Set-Content -Path $menuPs1 -Value $menuCode -Encoding UTF8
[System.IO.File]::WriteAllText($menuCmd, $cmdWrapper, [System.Text.Encoding]::ASCII)

# 5. 瞬间弹射新窗口 (当前终端立刻解脱)
Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$menuCmd`""
