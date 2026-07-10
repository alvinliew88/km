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
$passString = if($password){[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))}
if ($passString -ne "8888") { Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red; Start-Sleep -Seconds 2; exit }

# ---------------------------------------------------------
# UI DISPLAY (No injection, pure branding)
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

# Official Script Launcher
function Invoke-Official {
    param($ArgsInput)
    $tempPath = "$env:TEMP\MAS_AIO.cmd"
    Write-Host "`n  [+] Launching official activation..." -ForegroundColor Cyan
    try {
        # 直接拉取官方脚本
        $url = "https://raw.githubusercontent.com/massgrave/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd"
        Invoke-WebRequest -Uri $url -OutFile $tempPath -UseBasicParsing
        # 运行官方脚本，并传入参数，不需要手动导航
        Start-Process "$tempPath" -ArgumentList $ArgsInput -Verb RunAs -Wait
        Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  [-] Connection failure. Use Option 4." -ForegroundColor Red
        Start-Sleep -Seconds 3
    }
}

switch ($key) {
    '1' { Invoke-Official "/HWID" }
    '2' { Invoke-Official "/Ohook" }
    '3' {
        Write-Host "`n  [+] Optimizing..." -ForegroundColor Cyan
        Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "  [+] Done." -ForegroundColor Green; Start-Sleep -Seconds 2
    }
    '4' {
        Write-Host "`n  [+] Bypass..." -ForegroundColor Cyan
        iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
    }
    default { exit }
}
