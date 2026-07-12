# launcher.ps1 - THE ONE SYSTEM v3.1
# Fetches latest MAS AIO from official repo, modifies title & menu, runs in new window.

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

# ---------------------------------------------------------
# Download, modify, launch
# ---------------------------------------------------------
function Invoke-THEONE {
    Write-Host "`n  [+] Access Granted! Initializing..." -ForegroundColor Green

    $tempPath = "$env:TEMP\THE_ONE_AIO.cmd"
    $officialUrl = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd"

    try {
        # Download the latest official AIO script
        $rawText = Invoke-RestMethod -Uri $officialUrl -ErrorAction Stop

        # Validate content
        if ($rawText -notmatch 'MAS_AIO') {
            throw "Downloaded script does not contain expected marker. Possible network issue or script moved."
        }

        # Replace titles and menu entries (case-insensitive, first occurrence)
        $rawText = $rawText -replace '(?im)^title .*$', 'title  THE ONE SYSTEMS v3.1'
        $rawText = $rawText -replace 'HWID Activation', 'THE ONE Windows Authorized'
        $rawText = $rawText -replace 'Ohook Activation', 'THE ONE Office Authorized'
        $rawText = $rawText -replace 'KMS38 Activation', 'THE ONE Server Authorized'
        $rawText = $rawText -replace 'Online KMS', 'THE ONE Online Activation'

        # Fix any LF line ending to CRLF to avoid the script error
        $rawText = $rawText -replace '(?<!\r)\n', "`r`n"

        # Ensure an empty line at the very end
        if (-not $rawText.EndsWith("`r`n")) {
            $rawText += "`r`n"
        }

        # Save as ASCII (MAS scripts are ASCII compatible, avoids encoding issues)
        [System.IO.File]::WriteAllText($tempPath, $rawText, [System.Text.Encoding]::ASCII)

        # Launch in new window
        Start-Process -FilePath $tempPath

        Start-Sleep -Seconds 3
        Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "  [-] Execution failed!" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
        Start-Sleep -Seconds 5
    }
}

# ---------------------------------------------------------
# Deep Clean
# ---------------------------------------------------------
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
    Write-Host "`n  (Note: Files locked by running programs cannot be deleted.)" -ForegroundColor DarkGray
}

# ---------------------------------------------------------
# Main Menu Loop
# ---------------------------------------------------------
while ($true) {
    Clear-Host
    Write-Host "`n  T H E   O N E   S Y S T E M S   v3.1" -ForegroundColor Cyan
    Write-Host "  Authorized Operations Terminal" -ForegroundColor DarkGray
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  PC Name    : $pcName" -ForegroundColor White
    Write-Host "  MAC Address: $macAddress" -ForegroundColor White
    Write-Host "  Local IP   : $localIp" -ForegroundColor White
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "  [ 1 ] Activate THE ONE Windows Authorized" -ForegroundColor Green
    Write-Host "  [ 2 ] Activate THE ONE Office Authorized" -ForegroundColor Green
    Write-Host "  [ 3 ] THE ONE PC Optimization" -ForegroundColor Green
    Write-Host "  [ 4 ] Direct Bypass" -ForegroundColor Green
    Write-Host "  [ 0 ] Exit Terminal" -ForegroundColor DarkGray
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGray
    Write-Host "`n  > Select module: " -NoNewline

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    Write-Host "$key" -ForegroundColor White

    if ($key -eq '0') { exit }

    switch ($key) {
        '1' {
            Invoke-THEONE
        }
        '2' {
            Invoke-THEONE
        }
        '3' {
            Invoke-DeepClean
            Write-Host "`n  Press any key to return to menu..." -ForegroundColor DarkGray
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        '4' {
            Write-Host "`n  [+] Bypassing..." -ForegroundColor Cyan
            iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
        }
    }
}
