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
# UI DISPLAY (Infinite Loop)
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
        Write-Host "  [+] Establishing secure bridge to original source..." -ForegroundColor Cyan
        
        $tempDir = "$env:TEMP\TheOneSystem"
        if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir | Out-Null }
        $tempScript = "$tempDir\RUN.cmd"
        
        try {
            # 1. 下载官方最新的 AIO 源码 (使用你验证过 100% 成功的途径)
            $sourceCode = Invoke-RestMethod -Uri "https://get.activated.win" -UseBasicParsing -ErrorAction Stop
            
            Write-Host "  [+] Injecting THE ONE Authority..." -ForegroundColor Cyan

            # 2. 构建本地外壳 (Wrapper)，这能完美保留排版，替换标题，并阻止退出
            $wrapperCode = @"
@echo off
color 0B
title $CustomTitle

$sourceCode

echo.
echo   =================================================
echo   [ THE ONE AUTHORIZED - Task Completed ]
echo   =================================================
echo   Press any key to close this window...
pause >nul
exit /b
"@

            # 将带有外壳的代码写入本地临时文件
            Set-Content -Path $tempScript -Value $wrapperCode -Encoding Default

            # 3. 在全新的窗口中执行，确保 100% 还原官方的字体间距和窗口大小
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempScript`" $ArgsInput -qedit" -Verb RunAs -Wait
            
            # 执行完毕后清理
            Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
            
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
