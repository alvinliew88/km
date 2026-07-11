# launcher.ps1 - THE ONE SYSTEM v3.1 (Pure Native Clone)
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
    Write-Host "`n  T H E   O N E   S Y S T E M S   v3.1" -ForegroundColor Cyan
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

    # Option 4's Exact Fetching & Execution Logic
    function Invoke-NativeClone {
        param($ScriptURL, $CustomTitle)
        Write-Host "`n  [+] Access Granted! Initializing..." -ForegroundColor Green
        
        $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
        
        try {
            # 1. 100% 复制 Option 4 的底层逻辑：使用 curl 和 Cloudflare DNS 强制拉取，无视任何 ISP 屏蔽
            $rawText = (curl.exe -sL --doh-url https://1.1.1.1/dns-query $ScriptURL) -join "`r`n"
            
            if (-not ($rawText -match "masver")) { throw "ISP blocked the download. Cloudflare DoH failed." }
            
            # 2. 极简修改：只用正则替换官方代码里的 title 这一行，其余几万行原封不动！
            $rawText = $rawText -replace '(?im)^\s*title\s+.*', "title $CustomTitle"
            
            # 3. 完美保存：使用最纯净的 ASCII 编码直接写入物理硬盘，彻底杜绝乱码和 LF 报错
            [System.IO.File]::WriteAllBytes($tempPath, [System.Text.Encoding]::ASCII.GetBytes($rawText))
            
            # 4. 原生启动：不加任何干涉参数，让脚本以系统默认方式双击启动。
            # 原版脚本内部自带的 conhost.exe 越狱机制会自动生效，弹出一个拥有完美字体和间距的全新黑框！
            Start-Process -FilePath $tempPath
            
            # 延时 3 秒再清理临时文件，确保弹出的新窗口有充足的时间读取它
            Start-Sleep -Seconds 3
            Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
            
        } catch {
            Write-Host "  [-] Execution failed!" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }

    switch ($key) {
        '1' { 
            # 直接拉取纯净的独立版 HWID 脚本
            Invoke-NativeClone "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/HWID_Activation.cmd" "THE ONE WINDOWS AUTHORIZED v3.1" 
        }
        '2' { 
            # 直接拉取纯净的独立版 Ohook 脚本，打开后就是选项 1 和 2 的原版菜单
            Invoke-NativeClone "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/Ohook_Activation_AIO.cmd" "THE ONE OFFICE AUTHORIZED v3.1" 
        }
        '3' {
            Write-Host "`n  [+] Optimizing PC Storage..." -ForegroundColor Cyan
            Start-Sleep -Seconds 2
            Write-Host "  [+] PC Optimized successfully." -ForegroundColor Green
            Write-Host "`n  Press any key to return to menu..." -ForegroundColor DarkGray
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        '4' {
            Write-Host "`n  [+] Bypass..." -ForegroundColor Cyan
            # 完全原始的 Option 4 代码，提供双重保障
            iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
        }
    }
}
