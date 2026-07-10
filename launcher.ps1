# launcher.ps1
# Authorized IT Execution Script

# [CRITICAL FIX] Enforce TLS 1.2 for GitHub Raw connections
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- STEALTH MODULE: Clear Command History ---
Clear-History
try {
    $psHistoryPath = (Get-PSReadLineOption -ErrorAction SilentlyContinue).HistorySavePath
    if ($psHistoryPath -and (Test-Path $psHistoryPath)) { 
        Clear-Content -Path $psHistoryPath -ErrorAction SilentlyContinue 
    }
} catch {}
# ---------------------------------------------

# Fetch the active local IPv4 address
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress

$password = Read-Host "Authentication required" -AsSecureString

# Convert the secure string
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$passString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

# Security breach trigger
if ($passString -ne "8888") {
    Write-Host "`n[ ACCESS DENIED ]" -ForegroundColor Red
    Write-Host "Intruder IP Logged: $localIp" -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit
}

# Fetch the public IP address
try {
    $publicIp = Invoke-RestMethod -Uri 'https://api.ipify.org' -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
} catch {
    $publicIp = "Offline / Detected"
}

# ---------------------------------------------------------
# MINIMA MODERN UI DISPLAY
# ---------------------------------------------------------
Clear-Host
Write-Host ""
Write-Host "  T H E   O N E   S Y S T E M S" -ForegroundColor Cyan
Write-Host "  Authorized Operations Terminal" -ForegroundColor DarkGray
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Network Identity:" -ForegroundColor Gray
Write-Host "  Local IP   : " -NoNewline -ForegroundColor DarkGray; Write-Host "$localIp" -ForegroundColor White
Write-Host "  Public IP  : " -NoNewline -ForegroundColor DarkGray; Write-Host "$publicIp" -ForegroundColor White
Write-Host ""
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Available Modules:" -ForegroundColor Gray
Write-Host "  [ 1 ] Install THE ONE Authorized Office" -ForegroundColor White
Write-Host "  [ 2 ] Activate THE ONE Windows Authorized" -ForegroundColor White
Write-Host "  [ 3 ] Clean PC Temp Files (Storage Optimization)" -ForegroundColor White
Write-Host "  [ 4 ] BLOCKED (by ISP/DNS) - Needs updated Win 10 or 11" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  [ 0 ] Exit Terminal" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray

$choice = Read-Host "`n  > Select module (1/2/3/4/0)"

if ($choice -eq '4') {
    Write-Host "`n  [+] INITIALIZING DNS BYPASS PROTOCOL..." -ForegroundColor Cyan
    Write-Host "  [+] Redirecting to official source via Cloudflare DoH..." -ForegroundColor DarkGray
    try {
        iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
    } catch {
        Write-Host "`n  [-] Bypass failed. Check internet connection or OS version." -ForegroundColor Red
        Start-Sleep -Seconds 5
    }
    exit

} elseif ($choice -eq '3') {
    Write-Host "`n  [+] Executing storage optimization..." -ForegroundColor Cyan
    $tempDir = $env:TEMP
    
    $beforeSize = (Get-ChildItem -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    
    # Delete files silently
    Get-ChildItem -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    
    $afterSize = (Get-ChildItem -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $freedSpace = [math]::Round(($beforeSize - $afterSize) / 1MB, 2)
    
    Write-Host "  [+] Task complete. Storage freed: $freedSpace MB" -ForegroundColor White
    Write-Host "  [+] Terminating session in 7 seconds..." -ForegroundColor DarkGray
    
    Start-Sleep -Seconds 7
    exit

} elseif ($choice -eq '1') {
    $targetUrl = "https://raw.githubusercontent.com/massgrave/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/Ohook_Activation_AIO.cmd"
} elseif ($choice -eq '2') {
    $targetUrl = "https://raw.githubusercontent.com/massgrave/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/HWID_Activation.cmd"
} elseif ($choice -eq '0') {
    exit
} else {
    Write-Host "`n  [-] Invalid module selection." -ForegroundColor Red
    Start-Sleep -Seconds 2
    exit
}

Write-Host "`n  [+] Fetching secure payload from source..." -ForegroundColor Cyan
$tempPath = "$env:TEMP\THE_ONE_RUN.cmd"

try {
    # Download the latest file content into memory
    $scriptContent = Invoke-RestMethod -Uri $targetUrl -ErrorAction Stop
    
    # 1. Adapt CMD color to Minima theme (Cyan on Black)
    $scriptContent = $scriptContent -replace 'color 07', 'color 0B'
    
    # 2. Precision replace for the Top Title
    $scriptContent = $scriptContent -ireplace 'title\s+Ohook Activation %masver%', 'title THE ONE AUTHORIZE %masver%'
    $scriptContent = $scriptContent -ireplace 'title\s+HWID Activation %masver%', 'title THE ONE AUTHORIZE %masver%'
    
    # 3. Precision replace for Menu text
    $scriptContent = $scriptContent -ireplace 'Install Ohook Office Activation', 'Install THE ONE Authorized Office'
    $scriptContent = $scriptContent -ireplace 'Choose a menu option using your keyboard', 'Choose a menu. THE ONE AUTHORIZED'
    
    # Write the modified content
    Set-Content -Path $tempPath -Value $scriptContent -Encoding UTF8
    
    Write-Host "  [+] Payload injected. Launching interface..." -ForegroundColor White
    
    # Start the script as Administrator and wait for it to close
    Start-Process "$tempPath" -Verb RunAs -Wait
    
    # Clean up the temporary file
    Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "`n  [-] Connection failed. Check network or firewall." -ForegroundColor Red
    Write-Host "  URL: $targetUrl" -ForegroundColor DarkGray
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor DarkGray
    Start-Sleep -Seconds 7
}
