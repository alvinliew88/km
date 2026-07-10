# launcher.ps1 - THE ONE SYSTEM
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# --- STEALTH MODULE ---
Clear-History
try { $psHistoryPath = (Get-PSReadLineOption -ErrorAction SilentlyContinue).HistorySavePath; if ($psHistoryPath -and (Test-Path $psHistoryPath)) { Clear-Content -Path $psHistoryPath -ErrorAction SilentlyContinue } } catch {}

# Fetch local hardware data
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

# PASSWORD PROMPT
$password = Read-Host "key" -AsSecureString
$passString = ""
if ($password -ne $null -and $password.Length -gt 0) {
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    $passString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)
}

if ($passString -ne "8888") {
    Write-Host "`n[!] CRITICAL SECURITY BREACH DETECTED" -ForegroundColor Red
    Start-Sleep -Seconds 3; exit
}

# ---------------------------------------------------------
# MINIMA MODERN UI DISPLAY
# ---------------------------------------------------------
Clear-Host
Write-Host "`n  T H E   O N E   S Y S T E M S" -ForegroundColor Cyan
Write-Host "  Authorized Operations Terminal" -ForegroundColor DarkGray
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Network Identity: [!] ACTIVE TRACE LOGGING ENABLED" -ForegroundColor Red
Write-Host "  MAC Address: $macAddress" -ForegroundColor White
Write-Host "  Local IP   : $localIp" -ForegroundColor White
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Available Modules:" -ForegroundColor Gray
Write-Host "  [ 1 ] Activate THE ONE Windows Authorized" -ForegroundColor White
Write-Host "  [ 2 ] Install THE ONE Authorized Office" -ForegroundColor White
Write-Host "  [ 3 ] THE ONE PC optimization" -ForegroundColor White
Write-Host "  [ 4 ] BLOCKED (by ISP/DNS) - Direct Bypass" -ForegroundColor DarkCyan
Write-Host "  [ 0 ] Exit Terminal" -ForegroundColor DarkGray
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "`n  > Select module: " -NoNewline

$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
Write-Host "$key" -ForegroundColor White

# Logic for downloading AIO with Deep Text Injection
function Invoke-TheOne {
    param($Param)
    Write-Host "`n  [+] Injecting THE ONE Authority..." -ForegroundColor Cyan
    $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
    try {
        $targetUrl = "https://raw.githubusercontent.com/massgrave/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd"
        $scriptContent = Invoke-RestMethod -Uri $targetUrl -UseBasicParsing -ErrorAction Stop
        
        # UI & Branding Patching
        $scriptContent = $scriptContent -replace 'color 07', 'color 0B'
        $scriptContent = $scriptContent -ireplace 'title\s+.*', 'title THE ONE AUTHORIZE [SYSTEM]'
        
        # Deep Injection: Force Rename Official Menus
        $scriptContent = $scriptContent -replace '\[1\] HWID', '[1] THE ONE WINDOWS AUTHORIZED'
        $scriptContent = $scriptContent -replace '\[2\] Ohook', '[2] THE ONE OFFICE ACTIVATION'
        $scriptContent = $scriptContent -replace 'Activation Methods:', 'THE ONE ACTIVATION METHODS:'
        
        Set-Content -Path $tempPath -Value $scriptContent -Encoding UTF8
        Start-Process "$tempPath" -ArgumentList $Param -Verb RunAs -Wait
        Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  [-] Connection failure. Try Option 4." -ForegroundColor Red
        Start-Sleep -Seconds 3
    }
}

switch ($key) {
    '1' { Invoke-TheOne "/HWID" }
    '2' { Invoke-TheOne "/Ohook" }
    '3' {
        Write-Host "`n  [+] Executing storage optimization..." -ForegroundColor Cyan
        $before = (Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
        Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        $freed = [math]::Round(($before - (Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum) / 1MB, 2)
        Write-Host "  [+] Freed $freed MB." -ForegroundColor Green
        Start-Sleep -Seconds 3
    }
    '4' {
        Write-Host "`n  [+] Initializing DNS Bypass..." -ForegroundColor Cyan
        iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
    }
    default { exit }
}
