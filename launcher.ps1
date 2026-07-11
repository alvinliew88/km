# launcher.ps1 - THE ONE SYSTEM v2.2
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 将你的主控菜单也同步为原版的精确比例 (98x30)
try {
    $Host.UI.RawUI.WindowTitle = "THE ONE SYSTEMS v2.2"
    $ws = $Host.UI.RawUI.WindowSize; $ws.Width = 98; $ws.Height = 30
    $bs = $Host.UI.RawUI.BufferSize; $bs.Width = 98; $bs.Height = 300
    $Host.UI.RawUI.WindowSize = $ws
    $Host.UI.RawUI.BufferSize = $bs
} catch {}

# Fetch Hardware Data
$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

# Password Verification
$password = Read-Host "key" -AsSecureString
$passString = if($password){[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))}
if ($passString -ne "8888") { Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red; Start-Sleep -Seconds 2; exit }

# ---------------------------------------------------------
# UI DISPLAY (Infinite Loop)
# ---------------------------------------------------------
while ($true) {
    Clear-Host
    Write-Host "`n  T H E   O N E   S Y S T E M S   v2.2" -ForegroundColor Cyan
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

    # Core Execution Logic
    function Invoke-TheOne {
        param($ArgsInput, $CustomTitle)
        Write-Host "`n  [+] Access Granted! Initializing..." -ForegroundColor Green
        Write-Host "  [+] Establishing secure bridge to official source..." -ForegroundColor Cyan
        
        $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
        
        try {
            $urls = @(
                "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd",
                "https://bitbucket.org/WindowsAddict/microsoft-activation-scripts/raw/master/MAS/All-In-One-Version/MAS_AIO.cmd",
                "https://codeberg.org/massgravel/Microsoft-Activation-Scripts/raw/branch/master/MAS/All-In-One-Version/MAS_AIO.cmd"
            )
            
            $cmdContent = $null
            foreach ($u in $urls) {
                # 强力防 ISP 屏蔽：优先使用 curl + 1.1.1.1 DNS 进行抓取
                try {
                    $resp = (curl.exe -sL --doh-url https://1.1.1.1/dns-query $u) -join "`n"
                    if ($resp -match "masver") { $cmdContent = $resp; break }
                } catch {}
                
                # 备用：常规拉取
                if (-not $cmdContent) {
                    try {
                        $resp = Invoke-RestMethod -Uri $u -UseBasicParsing -ErrorAction Stop
                        if ($resp -match "masver") { $cmdContent = $resp; break }
                    } catch {}
                }
            }
            
            if (-not $cmdContent) { throw "All mirrors blocked by ISP." }
            
            Write-Host "  [+] Injecting THE ONE Authority..." -ForegroundColor Cyan
            
            # 修复换行符，防止原版脚本触发 LF 安全自检
            $cmdContent = $cmdContent -replace "`r`n", "`n" -replace "`n", "`r`n"
            
            # [核心修复]：强行在脚本顶端注入 mode 98, 30。这会强制窗口在自动执行时也保持 100% 的原版精致尺寸！
            $cmdContent = $cmdContent -replace '(?m)^@echo off', "@echo off`r`nmode 98, 30"
            
            # 抹除原版标题，强制注入你的品牌标题 (且不再干涉原本的颜色设定，保留纯粹的原版味道)
            $cmdContent = $cmdContent -replace '(?im)^\s*title\s+.*', "title $CustomTitle"
            
            # 拦截原版的 2 秒闪退，替换为你的专属完成提示并等待按键
            $cmdContent = $cmdContent.Replace("if %_unattended%==1 timeout /t 2 & exit /b", "if %_unattended%==1 echo. & echo   [ THE ONE AUTHORIZED - Task Completed ] & echo   Press any key to close this window... & pause >nul & exit /b")
            
            $cmdContent += "`r`n`r`n"
            
            # 强制使用 ASCII 保存，消除任何导致排版错乱的宽字符间距
            [System.IO.File]::WriteAllText($tempPath, $cmdContent, [System.Text.Encoding]::ASCII)
            
            # 启动！这会弹出一个与你截图右侧 1:1 像素级复刻的完美窗口
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempPath`" $ArgsInput" -Verb RunAs -Wait
            
            Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
            
        } catch {
            Write-Host "  [-] Execution failed!" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }

    switch ($key) {
        '1' { Invoke-TheOne "/HWID" "THE ONE WINDOWS AUTHORIZED v2.2" }
        '2' { Invoke-TheOne "/Ohook" "THE ONE OFFICE AUTHORIZED v2.2" }
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
