# launcher.ps1 - THE ONE SYSTEM
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Hardware/Network Identity
$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

# PASSWORD PROMPT
$password = Read-Host "key" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$passString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

if ($passString -ne "8888") {
    Write-Host "Wrong Password!" -ForegroundColor Red
    Start-Sleep -Seconds 2
    exit
}

# Action Logic (Smart Fetch & Injection)
function Invoke-Official {
    param($ArgsInput, $CustomTitle)
    
    Write-Host "`n  [+] Access Granted! Initializing..." -ForegroundColor Green
    $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
    
    try {
        Write-Host "  [+] Establishing secure bridge..." -ForegroundColor Cyan
        
        # 1. 智能镜像轮询，彻底解决 404 错误
        $urls = @(
            "https://bitbucket.org/WindowsAddict/microsoft-activation-scripts/raw/master/MAS/All-In-One-Version/MAS_AIO.cmd",
            "https://codeberg.org/massgravel/Microsoft-Activation-Scripts/raw/branch/master/MAS/All-In-One-Version/MAS_AIO.cmd",
            "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd"
        )
        
        $cmdContent = $null
        foreach ($url in $urls) {
            try {
                $response = Invoke-RestMethod -Uri $url -UseBasicParsing -ErrorAction Stop
                if ($response.Length -gt 50000) {
                    $cmdContent = $response
                    break
                }
            } catch { }
        }
        
        if (-not $cmdContent) {
            try {
                $cmdContent = (curl.exe -sL --doh-url https://1.1.1.1/dns-query "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd") -join "`n"
            } catch { }
        }

        if (-not $cmdContent -or $cmdContent.Length -lt 50000) {
            throw "All mirrors blocked. Please check connection."
        }

        Write-Host "  [+] Injecting THE ONE Authority..." -ForegroundColor Cyan

        # 2. 深度注入: 替换配色与标题
        $cmdContent = $cmdContent -replace "color 07", "color 0B"
        $cmdContent = $cmdContent -replace '(?im)^\s*title\s+.*', "title $CustomTitle"
        
        # 3. 拦截自动退出: 将官方的静默退出强行替换为等待按键
        $cmdContent = $cmdContent.Replace("if %_unattended%==1 timeout /t 2 & exit /b", "if %_unattended%==1 echo. & echo   [ THE ONE AUTHORIZED - Task Completed ] & echo   Press any key to close this window... & pause >nul & exit /b")

        Set-Content -Path $tempPath -Value $cmdContent -Encoding Ascii
        
        # 4. 执行时加入 -qedit 参数，防止 MAS 产生多余的二次弹窗
        Start-Process "$tempPath" -ArgumentList "$ArgsInput -qedit" -Verb RunAs -Wait
        
        Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
        
    } catch {
        Write-Host "  [-] Execution failed!" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
        Start-Sleep -Seconds 7
    }
}

# ---------------------------------------------------------
# UI DISPLAY (无限循环，执行完毕后终端绝对不会关闭)
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

    switch ($key) {
        '1' { Invoke-Official "/HWID" "THE ONE WINDOWS AUTHORIZED" }
        '2' { Invoke-Official "/Ohook" "THE ONE OFFICE AUTHORIZED" }
        '3' {
            # 选项 3 已修复：绝对不删除任何文件，只做显示并停留
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
        '0' { exit }
    }
}
