# launcher.ps1 - THE ONE SYSTEM
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- STEALTH MODULE ---
Clear-History
try { $psHistoryPath = (Get-PSReadLineOption -ErrorAction SilentlyContinue).HistorySavePath; if ($psHistoryPath -and (Test-Path $psHistoryPath)) { Clear-Content -Path $psHistoryPath -ErrorAction SilentlyContinue } } catch {}

# Fetch Hardware Data
$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

# PASSWORD
$password = Read-Host "key" -AsSecureString
$passString = if($password){[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))}
if ($passString -ne "8888") { Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red; Start-Sleep -Seconds 2; exit }

# ---------------------------------------------------------
# UI DISPLAY
# ---------------------------------------------------------
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
Write-Host "  [ 0 ] Exit Terminal" -ForegroundColor DarkGray
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "`n  > Select module: " -NoNewline

$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
Write-Host "$key" -ForegroundColor White

if ($key -eq '0') { exit }

# Action Logic
$tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
$url = "https://raw.githubusercontent.com/massgrave/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd"

Write-Host "`n  [+] Establishing secure bridge..." -ForegroundColor Cyan

try {
    # 尝试下载，增加超时设定
    Invoke-WebRequest -Uri $url -OutFile $tempPath -UseBasicParsing -TimeoutSec 15
    
    # 检查文件是否下载成功（如果小于 50KB 说明是 404 或空文件）
    if ((Get-Item $tempPath).Length -lt 50000) {
        throw "Download returned incomplete file or 404."
    }

    # 品牌化注入
    $content = Get-Content $tempPath -Raw
    $content = $content -replace 'color 07', 'color 0B'
    $content = $content -ireplace 'title\s+.*', 'title THE ONE AUTHORIZE [SYSTEM]'
    $content = $content -replace '\[1\] HWID', '[1] THE ONE WINDOWS AUTHORIZED'
    $content = $content -replace '\[2\] Ohook', '[2] THE ONE OFFICE ACTIVATION'
    $content = $content -replace 'Activation Methods:', 'THE ONE ACTIVATION METHODS:'
    Set-Content -Path $tempPath -Value $content -Encoding ascii
    
    # 确定参数
    $arg = ""
    if ($key -eq '1') { $arg = "/HWID" }
    elseif ($key -eq '2') { $arg = "/Ohook" }
    elseif ($key -eq '3') {
        Write-Host "  [+] Optimizing..." -ForegroundColor Cyan
        Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "  [+] Done." -ForegroundColor Green; Start-Sleep -Seconds 2; exit
    }
    
    Start-Process "$tempPath" -ArgumentList $arg -Verb RunAs -Wait
    Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
} catch {
    Write-Host "`n  [-] CONNECTION FAILED." -ForegroundColor Red
    Write-Host "  Error Detail: $($_.Exception.Message)" -ForegroundColor DarkGray
    Write-Host "`n  [!] TIP: Your ISP is blocking GitHub." -ForegroundColor Yellow
    Write-Host "  Please use a VPN or try Option 4 (if available) to bypass." -ForegroundColor White
    Start-Sleep -Seconds 10
}
