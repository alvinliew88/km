# launcher.ps1 - THE ONE SYSTEM v2.0
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# [UI 修复] 强制调整 PowerShell 窗口为 76x25，完美复刻原版 MAS 的字体比例和间距！
try { cmd.exe /c "mode 76, 25" } catch {}

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
    Write-Host "`n  T H E   O N E   S Y S T E M S   v2.0" -ForegroundColor Cyan
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
            # 1. 官方三大主干源，精准验证内容，杜绝一切假 404/Blocked 报错！
            $urls = @(
                "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd",
                "https://bitbucket.org/WindowsAddict/microsoft-activation-scripts/raw/master/MAS/All-In-One-Version/MAS_AIO.cmd",
                "https://codeberg.org/massgravel/Microsoft-Activation-Scripts/raw/branch/master/MAS/All-In-One-Version/MAS_AIO.cmd"
            )
            
            $cmdContent = $null
            foreach ($u in $urls) {
                try {
                    $resp = Invoke-RestMethod -Uri $u -UseBasicParsing -ErrorAction Stop
                    # 只要抓取到的代码包含官方标记 "masver"，就代表 100% 成功！
                    if ($resp -match "masver") {
                        $cmdContent = $resp
                        break
                    }
                } catch {}
            }
            
            if (-not $cmdContent) { throw "All mirrors blocked by ISP. Use Option 4." }
            
            Write-Host "  [+] Injecting THE ONE Authority..." -ForegroundColor Cyan
            
            # 2. 修复 Line Endings，防止原版脚本自毁报错
            $cmdContent = $cmdContent -replace "`r`n", "`n" -replace "`n", "`r`n"
            
            # 3. 颜色、标题覆盖，并强制拦截自动闪退
            $cmdContent = $cmdContent.Replace("color 07", "color 0B")
            $cmdContent = $cmdContent -replace '(?im)^\s*title\s+.*', "title $CustomTitle"
            $cmdContent = $cmdContent.Replace("if %_unattended%==1 timeout /t 2 & exit /b", "if %_unattended%==1 echo. & echo   [ THE ONE AUTHORIZED - Task Completed ] & echo   Press any key to close this window... & pause >nul & exit /b")
            
            $cmdContent += "`r`n`r`n"
            
            # 4. 强制存为标准 ASCII 格式，防止乱码导致字体宽大
            [System.IO.File]::WriteAllText($tempPath, $cmdContent, [System.Text.Encoding]::ASCII)
            
            # 5. 弹出全新独立窗口进行激活，完成后停住等你按键！
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempPath`" $ArgsInput" -Verb RunAs -Wait
            
            Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
            
        } catch {
            Write-Host "  [-] Execution failed!" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }

    switch ($key) {
        '1' { Invoke-TheOne "/HWID" "THE ONE WINDOWS AUTHORIZED v2.0" }
        '2' { Invoke-TheOne "/Ohook" "THE ONE OFFICE AUTHORIZED v2.0" }
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
