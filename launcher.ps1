# launcher.ps1 - THE ONE SYSTEM
# Authorized IT Execution Script

# 强制使用 TLS 1.2 保证与官方服务器加密连接
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- STEALTH MODULE: 隐私清除 ---
Clear-History
try { $psHistoryPath = (Get-PSReadLineOption -ErrorAction SilentlyContinue).HistorySavePath; if ($psHistoryPath -and (Test-Path $psHistoryPath)) { Clear-Content -Path $psHistoryPath -ErrorAction SilentlyContinue } } catch {}

# 获取系统硬件标识
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

# 隐形密码验证
$password = Read-Host "key" -AsSecureString
$passString = if($password){[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))}
if ($passString -ne "8888") { Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red; Start-Sleep -Seconds 2; exit }

# ---------------------------------------------------------
# MINIMA MODERN UI
# ---------------------------------------------------------
Clear-Host
Write-Host "`n  T H E   O N E   S Y S T E M S" -ForegroundColor Cyan
Write-Host "  Authorized Operations Terminal" -ForegroundColor DarkGray
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  MAC Address: $macAddress" -ForegroundColor White
Write-Host "  Local IP   : $localIp" -ForegroundColor White
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  [ 1 ] Activate THE ONE Windows Authorized" -ForegroundColor White
Write-Host "  [ 2 ] Install THE ONE Authorized Office" -ForegroundColor White
Write-Host "  [ 3 ] THE ONE PC optimization" -ForegroundColor White
Write-Host "  [ 0 ] Exit Terminal" -ForegroundColor DarkGray
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "`n  > Select module: " -NoNewline

$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
Write-Host "$key" -ForegroundColor White

# 核心：通过 DoH 下载并进行品牌化注入
function Invoke-TheOne {
    param($Param)
    $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
    Write-Host "`n  [+] Establishing secure channel..." -ForegroundColor Cyan
    
    # 强制使用 curl + DoH 绕过所有拦截
    curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win -o "$tempPath"
    
    if (!(Test-Path $tempPath)) { Write-Host "  [-] Failed to acquire source." -ForegroundColor Red; Start-Sleep -Seconds 2; return }

    # 注入 THE ONE 品牌主题
    $content = Get-Content "$tempPath" -Raw
    $content = $content -replace 'color 07', 'color 0B'
    $content = $content -ireplace 'title\s+.*', 'title THE ONE AUTHORIZE [SYSTEM]'
    # 替换官方菜单文字为你的品牌
    $content = $content -replace '\[1\] HWID', '[1] THE ONE WINDOWS AUTHORIZED'
    $content = $content -replace '\[2\] Ohook', '[2] THE ONE OFFICE ACTIVATION'
    $content = $content -replace 'Activation Methods:', 'THE ONE ACTIVATION METHODS:'
    
    Set-Content -Path "$tempPath" -Value $content -Encoding ascii
    
    # 执行
    Start-Process "$tempPath" -ArgumentList $Param -Verb RunAs -Wait
    Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
}

switch ($key) {
    '1' { Invoke-TheOne "/HWID" }
    '2' { Invoke-TheOne "/Ohook" }
    '3' {
        Write-Host "`n  [+] Executing PC optimization..." -ForegroundColor Cyan
        Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "  [+] Optimization Complete." -ForegroundColor Green
        Start-Sleep -Seconds 2
    }
    default { exit }
}
