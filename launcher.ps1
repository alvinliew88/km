# launcher.ps1 - THE ONE SYSTEM
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Fetch Hardware Data
$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

# Password Verification
$password = Read-Host "key" -AsSecureString
$passString = if($password){[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))}
if ($passString -ne "8888") { Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red; Start-Sleep -Seconds 2; exit }

# ---------------------------------------------------------
# UI DISPLAY (Infinite Loop: Never Auto-Closes)
# ---------------------------------------------------------
while ($true) {
    Clear-Host
    Write-Host "`n  T H E   O N E   S Y S T E M S" -ForegroundColor Cyan
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
            # 1. 动态获取官方最新链接，防止过期
            $wrapper = Invoke-RestMethod -Uri "https://get.activated.win" -UseBasicParsing -ErrorAction Stop
            $urls = [regex]::Matches($wrapper, 'https://[^\s"''`*]+MAS_AIO\.cmd') | ForEach-Object { $_.Value } | Select-Object -Unique
            
            $cmdContent = $null
            foreach ($u in $urls) {
                try {
                    $cmdContent = Invoke-RestMethod -Uri $u -UseBasicParsing -ErrorAction Stop
                    if ($cmdContent.Length -gt 50000) { break }
                } catch {}
            }
            if (-not $cmdContent) { throw "All dynamic mirrors failed to respond." }
            
            Write-Host "  [+] Injecting THE ONE Authority..." -ForegroundColor Cyan
            
            # 2. 【核心修复：LF Line Ending 报错】强制转换换行符为 Windows 标准 (CRLF) 并追加空白行
            $cmdContent = $cmdContent -replace "`r`n", "`n" -replace "`n", "`r`n"
            $cmdContent += "`r`n`r`n"
            
            # 3. 替换颜色与强制覆盖官方标题
            $cmdContent = $cmdContent.Replace("color 07", "color 0B")
            $cmdContent = $cmdContent -replace '(?im)^\s*title\s+.*', "title $CustomTitle"
            
            # 4. 拦截自动闪退：将官方静默执行后的强制退出，替换为等待按键
            $cmdContent = $cmdContent.Replace("if %_unattended%==1 timeout /t 2 & exit /b", "if %_unattended%==1 echo. & echo   [ THE ONE AUTHORIZED - Task Completed ] & echo   Press any key to close this window... & pause >nul & exit /b")
            
            # 保存到本地
            Set-Content -Path $tempPath -Value $cmdContent -Encoding Ascii
            
            # 5. 打开原生的新 CMD 窗口执行，完美还原官方的字体间距
            Start-Process -FilePath $tempPath -ArgumentList $ArgsInput -Verb RunAs -Wait
            
            Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
            
        } catch {
            Write-Host "  [-] Execution failed!" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }

    switch ($key) {
        '1' { Invoke-TheOne "/HWID" "THE ONE WINDOWS AUTHORIZED" }
        '2' { Invoke-TheOne "/Ohook" "THE ONE OFFICE AUTHORIZED" }
        '3' {
            Write-Host "`n  [+] Optimizing PC Storage..." -ForegroundColor Cyan
            Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
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
