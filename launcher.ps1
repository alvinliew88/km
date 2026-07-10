# launcher.ps1
# This script requires a password to execute the target .cmd file.

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
    Write-Host "[!] INTRUDER IP: $localIp / LOGGED TO SYSTEM" -ForegroundColor Red
    Start-Sleep -Seconds 3
    exit
}

# Fetch the public (external) IP address
try {
    $publicIp = Invoke-RestMethod -Uri 'https://api.ipify.org' -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
} catch {
    $publicIp = "DETECTED, saved/"
}

# Display the custom menu (IT Professional Theme)
Clear-Host
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host "           THE ONE used only            " -ForegroundColor Red
Write-Host "========================================" -ForegroundColor DarkCyan
Write-Host "[!] WARNING: Detected IPs" -ForegroundColor Yellow
Write-Host "    -> Local IP:  $localIp" -ForegroundColor Yellow
Write-Host "    -> Public IP: $publicIp" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor DarkCyan
Write-Host "[1] Install THE ONE authorized office" -ForegroundColor Green
Write-Host "[2] THE ONE window AUTHORIZED" -ForegroundColor Green
Write-Host "[3] Clean PC %TEMP% files permanently" -ForegroundColor Cyan
Write-Host "[0] Exit" -ForegroundColor DarkGray
Write-Host "========================================" -ForegroundColor DarkCyan

$choice = Read-Host "Select an option (1, 2, 3, or 0)"

if ($choice -eq '3') {
    Write-Host "`n[+] INITIALIZING TEMP PURGE PROTOCOL..." -ForegroundColor Cyan
    $tempDir = $env:TEMP
    
    # Calculate size before deletion
    $beforeSize = (Get-ChildItem -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    
    Write-Host "[+] BYPASSING LOCKED SYSTEM FILES..." -ForegroundColor Cyan
    # Delete files silently to maximize speed
    Get-ChildItem -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    
    # Calculate size after deletion
    $afterSize = (Get-ChildItem -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
    
    # Calculate freed space in MB
    $freedSpace = [math]::Round(($beforeSize - $afterSize) / 1MB, 2)
    
    Write-Host "----------------------------------------" -ForegroundColor DarkCyan
    Write-Host ">>> PURGE COMPLETE. STORAGE FREED: $freedSpace MB" -ForegroundColor Green
    Write-Host ">>> TERMINATING SESSION..." -ForegroundColor DarkCyan
    
    # Auto-close after 3 seconds
    Start-Sleep -Seconds 3
    exit

} elseif ($choice -eq '1') {
    $targetUrl = "https://raw.githubusercontent.com/massgrave/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/Ohook-Activation.cmd"
} elseif ($choice -eq '2') {
    $targetUrl = "https://raw.githubusercontent.com/massgrave/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/HWID-Activation.cmd"
} elseif ($choice -eq '0') {
    exit
} else {
    Write-Host "Invalid option!" -ForegroundColor Red
    Start-Sleep -Seconds 2
    exit
}

Write-Host "`n[+] DOWNLOADING ORIGINAL PAYLOAD AND INITIALIZING..." -ForegroundColor Cyan
$tempPath = "$env:TEMP\THE_ONE_RUN.cmd"

try {
    # Download the latest file content into memory
    $scriptContent = Invoke-RestMethod -Uri $targetUrl -ErrorAction Stop
    
    # 1. Change all color to green (0a)
    $scriptContent = $scriptContent -replace 'color 07', 'color 0a'
    
    # 2. Change the top title for both scripts
    $scriptContent = $scriptContent -replace 'title  Ohook Activation %masver%', 'title TO THE ONE USE'
    $scriptContent = $scriptContent -replace 'title  HWID Activation %masver%', 'title TO THE ONE USE'
    
    # 3. Change specific menu writings
    $scriptContent = $scriptContent -replace 'Install Ohook Office Activation', 'install ohook activator to THE ONE'
    $scriptContent = $scriptContent -replace 'Choose a menu option using your keyboard', 'Choose a menu. THE ONE AUTHORIZED'
    
    # Write the modified content to the temporary path
    Set-Content -Path $tempPath -Value $scriptContent -Encoding UTF8
    
    # Start the script as Administrator and wait for it to close
    Start-Process "$tempPath" -Verb RunAs -Wait
    
    # Clean up the temporary file after execution
    Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
    
} catch {
    Write-Host "[-] CONNECTION FAILED!" -ForegroundColor Red
    Write-Host "URL: $targetUrl" -ForegroundColor Yellow
    Start-Sleep -Seconds 5
}
