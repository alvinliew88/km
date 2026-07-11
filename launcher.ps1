# launcher.ps1 - THE ONE SYSTEM v3.1
# Fetches latest MAS scripts from official repo, modifies title and menu, runs in new window.

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred |
    Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try {
    $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress
} catch {
    $macAddress = "UNKNOWN"
}

# Password Verification
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
# Download, modify title/menu, and execute in new window
# ---------------------------------------------------------
function Invoke-ModifiedScript {
    param(
        [string]$ScriptName,             # 'HWID_Activation.cmd' or 'Ohook_Activation_AIO.cmd'
        [string]$CustomTitle,            # New title for the window
        [hashtable]$Replacements         # Additional text replacements (e.g., menu items)
    )

    Write-Host "`n  [+] Access Granted! Initializing..." -ForegroundColor Green

    $tempPath = "$env:TEMP\$ScriptName"
    $baseRawUrl = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/Activators"

    try {
        # Download the original script from official repo
        $rawText = & curl.exe -sSfL --doh-url https://1.1.1.1/dns-query "$baseRawUrl/$ScriptName" | Out-String
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to download $ScriptName. Check your internet connection."
        }

        # Replace the window title (first occurrence)
        if ($ScriptName -eq "HWID_Activation.cmd") {
            $rawText = $rawText -replace 'title\s+HWID Activation.*', "title  $CustomTitle"
        } elseif ($ScriptName -eq "Ohook_Activation_AIO.cmd") {
            # Change title
            $rawText = $rawText -replace 'title\s+Ohook Activation.*', "title  $CustomTitle"
            # Change menu texts (the Ohook menu lines)
            $rawText = $rawText -replace 'Install Ohook Office Activation', 'Install THE ONE Office Activation'
            $rawText = $rawText -replace 'Uninstall Ohook', 'Uninstall THE ONE'
            # Change "Ohook activation is not installed" / "uninstalled" messages
            $rawText = $rawText -replace 'Ohook activation is not installed\.', 'THE ONE activation is not installed.'
            $rawText = $rawText -replace 'Successfully uninstalled Ohook activation\.', 'Successfully uninstalled THE ONE activation.'
            $rawText = $rawText -replace 'Failed to uninstall Ohook activation\.', 'Failed to uninstall THE ONE activation.'
            $rawText = $rawText -replace 'Uninstalling Ohook activation\.\.\.', 'Uninstalling THE ONE activation...'
            # Change any "Installing Ohook" messages
            $rawText = $rawText -replace 'Installing Ohook\b', 'Installing THE ONE'
            # Change "Remove Previous Ohook Install"
            $rawText = $rawText -replace 'Remove Previous Ohook Install', 'Remove Previous THE ONE Install'
            # Change Smart App Control message
            $rawText = $rawText -replace 'after Ohook activation', 'after THE ONE activation'
        }

        # Save as UTF-8 without BOM (preserves special characters)
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($tempPath, $rawText, $utf8NoBom)

        # Launch the .cmd file in a NEW console window
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
# Main Menu Loop (Professional IT Color Scheme)
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
            Invoke-ModifiedScript -ScriptName "HWID_Activation.cmd" -CustomTitle "THE ONE WINDOWS AUTHORIZED v3.1"
        }
        '2' {
            Invoke-ModifiedScript -ScriptName "Ohook_Activation_AIO.cmd" -CustomTitle "THE ONE OFFICE AUTHORIZED v3.1"
        }
        '3' {
            Write-Host "`n  [+] Cleaning temporary files..." -ForegroundColor Cyan
            $tempFolders = @($env:TEMP, "$env:SystemRoot\Temp")
            foreach ($folder in $tempFolders) {
                if (Test-Path $folder) {
                    Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue |
                        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                }
            }
            Write-Host "  [+] PC Optimized successfully." -ForegroundColor Green
            Write-Host "`n  Press any key to return to menu..." -ForegroundColor DarkGray
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        '4' {
            Write-Host "`n  [+] Bypassing..." -ForegroundColor Cyan
            iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
        }
    }
}
