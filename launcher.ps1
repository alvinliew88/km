# launcher.ps1
# This script requires a password to execute the target .cmd file.

# --- STEALTH MODULE: Clear Command History (Prevent UP Arrow tracking) ---
Clear-History
try {
    $psHistoryPath = (Get-PSReadLineOption -ErrorAction SilentlyContinue).HistorySavePath
    if ($psHistoryPath -and (Test-Path $psHistoryPath)) { 
        Clear-Content -Path $psHistoryPath -ErrorAction SilentlyContinue 
    }
} catch {}
# -------------------------------------------------------------------------

# Fetch the active local IPv4 address early for security logging
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress

$password = Read-Host "keygen" -AsSecureString

# Convert the secure string to a plain text string for comparison
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$passString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

# Wrong password trigger: Fake Camera & IP capture warning (IT Security Theme)
if ($passString -ne "8888") {
    Write-Host "`n[!] CRITICAL SECURITY BREACH DETECTED" -ForegroundColor Red
    Write-Host "[!] CAMERA SCREENSHOT INTERCEPTED & SAVED" -ForegroundColor Red
    Write-Host "[!] INTRUDER IP: " -NoNewline -ForegroundColor Red
    Write-Host "$localIp " -NoNewline -ForegroundColor White
    Write-Host "/ LOGGED TO SYSTEM`n" -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit
}

# Fetch the public (external) IP address
try {
    $publicIp = Invoke-RestMethod -Uri 'https://api.ipify.org' -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
} catch {
    $publicIp = "DETECTED, saved/"
}

# Display the custom menu (IT Professional Theme with clear separators)
Clear-Host
Write-Host "[!] CAUTION: AUTHORIZED IT PERSONNEL ONLY. ALL ACTIONS ARE LOGGED.`n" -ForegroundColor Red

Write-Host "==================================================" -ForegroundColor DarkCyan
Write-Host "               THE ONE AUTHORIZED                 " -ForegroundColor Red
Write-Host "==================================================" -ForegroundColor DarkCyan
Write-Host ""
Write-Host " [!] SYSTEM SECURITY STATUS:" -ForegroundColor Yellow
Write-Host "     -> Local IP  : " -NoNewline -ForegroundColor Yellow
Write-Host "$localIp" -ForegroundColor White
Write-Host "     -> Public IP : " -NoNewline -ForegroundColor Yellow
Write-Host "$publicIp" -ForegroundColor White
Write-Host ""
Write-Host "--------------------------------------------------" -ForegroundColor DarkCyan
Write-Host ""
Write-Host " [1] INSTALL THE ONE AUTHORIZED OFFICE" -ForegroundColor Green
Write-Host " [2] ACTIVATE THE ONE WINDOWS AUTHORIZED" -ForegroundColor Green
Write-Host " [3] CLEAN PC %TEMP% FILES PERMANENTLY" -ForegroundColor Cyan
Write-Host ""
Write-Host " [0] EXIT" -ForegroundColor DarkGray
Write-Host ""
Write-Host "==================================================" -ForegroundColor DarkCyan

$choice = Read-Host "`n Select an option (1, 2, 3, or 0)"

if ($choice -eq '3') {
    Write-Host "`n [+] INITIALIZING TEMP PURGE PROTOCOL..." -ForegroundColor Cyan
    $tempDir = $env:TEMP
    
    # Calculate size before deletion
    $beforeSize = (Get-ChildItem -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    
    Write-Host " [+] BYPASSING LOCKED SYSTEM FILES..." -ForegroundColor Cyan
    # Delete files silently to maximize speed
    Get-ChildItem -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    
    # Calculate size after deletion
    $afterSize = (Get-ChildItem -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    
    # Calculate freed space in MB
    $freedSpace = [math]::Round(($beforeSize - $afterSize) / 1MB, 2)
    
    Write-Host " --------------------------------------------------" -ForegroundColor DarkCyan
    Write-Host " >>> PURGE COMPLETE. STORAGE FREED: $freedSpace MB" -ForegroundColor Green
    Write-Host " >>> TERMINATING SESSION IN 7 SECONDS..." -ForegroundColor DarkCyan
    
    # Auto-close after EXACTLY 7 seconds
    Start-Sleep -Seconds 7
    exit

} elseif ($choice -eq '1') {
    $targetUrl = "https://raw.githubusercontent.com/massgrave/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/Ohook_Activation_AIO.cmd"
} elseif ($choice -eq '2') {
    $targetUrl = "https://raw.githubusercontent.com/massgrave/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/HWID_Activation.cmd"
} elseif ($choice -eq '0') {
    exit
} else {
    Write-Host " Invalid option!" -ForegroundColor Red
    Start-Sleep -Seconds 2
    exit
}

Write-Host "`n [+] DOWNLOADING ORIGINAL PAYLOAD AND INITIALIZING..." -ForegroundColor Cyan
$tempPath = "$env:TEMP\THE_ONE_RUN.cmd"

try {
    # Download the latest file content into memory
    $scriptContent = Invoke-RestMethod -Uri $targetUrl -ErrorAction Stop
    
    # 1. Change all color to green (0a)
    $scriptContent = $scriptContent -replace 'color 07', 'color 0a'
    
    # 2. Precision replace for the Top Title
    $scriptContent = $scriptContent -ireplace 'title\s+Ohook Activation %masver%', 'title THE ONE AUTHORIZE %masver%'
    $scriptContent = $scriptContent -ireplace 'title\s+HWID Activation %masver%', 'title THE ONE AUTHORIZE %masver%'
    
    # 3. Precision replace for Menu text
    $scriptContent = $scriptContent -ireplace 'Install Ohook Office Activation', 'Install THE ONE Authorized Office'
    $scriptContent = $scriptContent -ireplace 'Choose a menu option using your keyboard', 'Choose a menu. THE ONE AUTHORIZED'
    
    # Write the modified content to the temporary path
    Set-Content -Path $tempPath -Value $scriptContent -Encoding UTF8
    
    # Start the script as Administrator and wait for it to close
    Start-Process "$tempPath" -Verb RunAs -Wait
    
    # Clean up the temporary file after execution
    Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "`n [-] CONNECTION FAILED!" -ForegroundColor Red
    Write-Host " URL: $targetUrl" -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}
