# launcher.ps1 - THE ONE SYSTEM v3.1 (Keeps activation window open)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred |
    Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try {
    $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress
} catch {
    $macAddress = "UNKNOWN"
}

$password = Read-Host "key" -AsSecureString
$passString = if ($password) {
    [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
    )
}
if ($passString -ne "8888") {
    Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red
    Start-Sleep -Seconds 2
    exit
}

function Start-Activation {
    param([string]$Mode)   # /HWID, /Ohook, etc.

    Write-Host "`n  [+] Access Granted! Preparing activation..." -ForegroundColor Green

    $tempAIO = "$env:TEMP\THE_ONE_AIO.cmd"
    $tempRun = "$env:TEMP\THE_ONE_RUN.cmd"
    $url = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd"

    try {
        # Download the official AIO script
        $raw = Invoke-RestMethod -Uri $url -ErrorAction Stop
        if ($raw -notmatch 'MAS_AIO') { throw "Invalid download (marker missing)" }

        # Only change the window title, nothing else.
        $raw = $raw -replace '(?im)^title .*$', 'title  THE ONE SYSTEMS v3.1'

        # Fix line endings and ensure final empty line (avoids LF error)
        $raw = $raw -replace '(?<!\r)\n', "`r`n"
        if (-not $raw.EndsWith("`r`n")) { $raw += "`r`n" }

        # Save the modified AIO script as ASCII (compatible with all its content)
        [System.IO.File]::WriteAllText($tempAIO, $raw, [System.Text.Encoding]::ASCII)

        # Create a wrapper script that calls the AIO with the desired mode AND pauses
        $wrapper = @"
@echo off
call "$tempAIO" $Mode
echo.
echo ==========================================
echo   Press any key to return to THE ONE menu
echo ==========================================
pause >nul
"@
        [System.IO.File]::WriteAllText($tempRun, $wrapper, [System.Text.Encoding]::ASCII)

        # Launch the wrapper in a new cmd window (keeps open after activation)
        Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempRun`""

        Write-Host "  [+] Activation window opened. Check the new window for progress." -ForegroundColor Cyan

        # Wait a moment for the process to start, then clean up the script files
        # (the AIO script may still be running, but we can remove the temp files after a delay)
        Start-Sleep -Seconds 5
        Remove-Item -Path $tempAIO, $tempRun -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "  [-] Error: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 5
    }
}

function Invoke-DeepClean {
    Write-Host "`n  [+] Deep cleaning system temporary files..." -ForegroundColor Cyan
    $folders = @(
        $env:TEMP,
        "$env:SystemRoot\Temp",
        "$env:SystemRoot\Prefetch",
        [Environment]::GetFolderPath('Recent'),
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Microsoft\Windows\Temporary Internet Files"
    )
    foreach ($folder in $folders) {
        if (Test-Path $folder) {
            Write-Host "  Cleaning: $folder" -ForegroundColor DarkGray
            Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
    try { cleanmgr /sagerun:1 | Out-Null } catch {}
    Write-Host "  [+] PC Optimized successfully." -ForegroundColor Green
}

# Main Menu Loop
while ($true) {
    Clear-Host
    Write-Host "`n  T H E   O N E   S Y S T E M S   v3.1" -ForegroundColor Cyan
    Write-Host "  Authorized Operations Terminal" -ForegroundColor DarkGray
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PC Name    : $pcName" -ForegroundColor White
    Write-Host "  MAC Address: $macAddress" -ForegroundColor White
    Write-Host "  Local IP   : $localIp" -ForegroundColor White
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [ 1 ] Activate THE ONE Windows" -ForegroundColor Green
    Write-Host "  [ 2 ] Activate THE ONE Office" -ForegroundColor Green
    Write-Host "  [ 3 ] THE ONE PC Optimization" -ForegroundColor Green
    Write-Host "  [ 4 ] Full MAS Menu (Original)" -ForegroundColor Green
    Write-Host "  [ 0 ] Exit Terminal" -ForegroundColor DarkGray
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "`n  > Select module: " -NoNewline

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    Write-Host "$key" -ForegroundColor White

    if ($key -eq '0') { exit }

    switch ($key) {
        '1' { Start-Activation "/HWID" }
        '2' { Start-Activation "/Ohook" }
        '3' {
            Invoke-DeepClean
            Write-Host "`n  Press any key to return to menu..." -ForegroundColor DarkGray
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        '4' {
            Write-Host "`n  [+] Launching full MAS menu..." -ForegroundColor Cyan
            iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
        }
    }
}
