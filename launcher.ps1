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

# Fetch local IP early
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress

# PASSWORD PROMPT
$password = Read-Host "key" -AsSecureString

# Safeguard against empty password (just pressing Enter) to prevent red errors
$passString = ""
if ($password -ne $null -and $password.Length -gt 0) {
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $passString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

# Security breach trigger
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

# Generate a fake session ID for IT professional look
$sessionId = [guid]::NewGuid().ToString().ToUpper().Substring(0,18)

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
Write-Host "  Session ID : " -NoNewline -ForegroundColor DarkGray; Write-Host "$sessionId" -ForegroundColor DarkCyan
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
    # Dynamically extract the latest AIO CMD URL from official redirector to prevent 404 forever
    $irmContent = Invoke-RestMethod -Uri 'https://get.activated.win' -UseBasicParsing -ErrorAction Stop
    $targetUrl = ([regex]::Match($irmContent, 'https://raw\.githubusercontent\.com/\S+\.cmd')).Value
    
    if (-not $targetUrl) { throw "Unable to resolve target URL." }

    # Download the actual script content
    $scriptContent = Invoke-RestMethod -Uri $targetUrl -ErrorAction Stop
    
    # 1. Adapt CMD color to Minima theme
    $scriptContent = $scriptContent -replace 'color 07', 'color 0B'
    
    # 2. Replace generic MAS titles and Menus with THE ONE branding
    $scriptContent = $scriptContent -replace 'title MAS %masver%', 'title THE ONE AUTHORIZE %masver%'
    $scriptContent = $scriptContent -replace 'HWID Activation', 'THE ONE WINDOWS AUTHORIZED'
    $scriptContent = $scriptContent -replace 'Ohook Activation', 'THE ONE OFFICE AUTHORIZED'
    $scriptContent = $scriptContent -replace 'Choose a menu option using your keyboard', 'Choose a menu. THE ONE AUTHORIZED'
    
    Set-Content -Path $tempPath -Value $scriptContent -Encoding UTF8
    Write-Host "  [+] Payload injected. Launching interface..." -ForegroundColor White
    
    Start-Process "$tempPath" -Verb RunAs -Wait
    Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "`n  [-] Connection failed. Check network or firewall." -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor DarkGray
    Start-Sleep -Seconds 7
}
