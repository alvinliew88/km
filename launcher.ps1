# launcher.ps1 - THE ONE SYSTEM
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Hardware/Network Identity
$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

# PASSWORD PROMPT (Uses your required keygen input)
$password = Read-Host "keygen" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$passString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

if ($passString -ne "8888") {
    Write-Host "Wrong Password!" -ForegroundColor Red
    Start-Sleep -Seconds 2
    exit
}

# ---------------------------------------------------------
# UI DISPLAY (Wrapped in an infinite loop so it NEVER closes)
# ---------------------------------------------------------
while ($true) {
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

    # Official Script Launcher Logic
    function Invoke-Official {
        param($ArgsInput, $CustomTitle)
        
        Write-Host "`n  [+] Access Granted! Initializing..." -ForegroundColor Green
        $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
        
        try {
            Write-Host "  [+] Establishing secure bridge..." -ForegroundColor Cyan
            
            # Download using your trusted method
            $url = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd"
            $cmdContent = Invoke-RestMethod -Uri $url -UseBasicParsing -ErrorAction Stop
            
            Write-Host "  [+] Injecting THE ONE Authority..." -ForegroundColor Cyan

            # 1. Apply Theme
            $cmdContent = $cmdContent.Replace("color 07", "color 0B")
            
            # 2. Force Title Override
            $cmdContent = $cmdContent -replace '(?m)^\s*title\s+.*', "title $CustomTitle"
            
            # 3. Prevent Auto-Close. Replaces the 2-second timeout with an infinite pause.
            $cmdContent = $cmdContent.Replace("if %_unattended%==1 timeout /t 2 & exit /b", "if %_unattended%==1 echo. & echo   [ THE ONE AUTHORIZED - Task Completed ] & echo   Press any key to close this window... & pause >nul & exit /b")

            Set-Content -Path $tempPath -Value $cmdContent -Encoding Ascii
            
            # Start the script. CRITICAL FIX: We no longer delete the file immediately, 
            # ensuring the script doesn't crash when it relaunches itself.
            Start-Process "$tempPath" -ArgumentList $ArgsInput -Verb RunAs -Wait
            
        } catch {
            Write-Host "  [-] Execution failed!" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Seconds 7
        }
    }

    switch ($key) {
        '1' { Invoke-Official "/HWID" "THE ONE WINDOWS AUTHORIZED" }
        '2' { Invoke-Official "/Ohook" "THE ONE OFFICE AUTHORIZED" }
        '3' {
            Write-Host "`n  [+] Optimizing PC Storage..." -ForegroundColor Cyan
            # Continues to execute your desired temp deletion
            Get-ChildItem -Path $env:TEMP -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
            Write-Host "  [+] PC Optimized successfully." -ForegroundColor Green
            Write-Host "`n  Press any key to return to menu..." -ForegroundColor DarkGray
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        '4' {
            Write-Host "`n  [+] Bypass..." -ForegroundColor Cyan
            iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
        }
        '0' { exit }
    }
}
