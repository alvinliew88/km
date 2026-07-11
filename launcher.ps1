# launcher.ps1 - THE ONE SYSTEM v3.1 (Authorized IT Execution Script)

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
# Download a script from YOUR repo, save to temp, and execute
# ---------------------------------------------------------
function Invoke-OwnScript {
    param(
        [string]$ScriptName,   # e.g. "HWID_Activation.cmd"
        [string]$CustomTitle   # Already in the file, but shown for logging
    )

    Write-Host "`n  [+] Access Granted! Initializing..." -ForegroundColor Green

    $tempPath = "$env:TEMP\$ScriptName"
    # !!! REPLACE WITH YOUR ACTUAL REPO URL !!!
    $repoBase = "https://raw.githubusercontent.com/你的用户名/仓库名/main"

    try {
        # Download the script from YOUR repository
        $rawText = & curl.exe -sSfL --doh-url https://1.1.1.1/dns-query "$repoBase/$ScriptName" | Out-String
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to download $ScriptName from your repo."
        }

        # Save with UTF-8 without BOM (preserves special characters)
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($tempPath, $rawText, $utf8NoBom)

        # Launch the .cmd file – opens a new console window with your custom title
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
# Main Menu Loop (Green Theme)
# ---------------------------------------------------------
while ($true) {
    Clear-Host
    Write-Host "`n  T H E   O N E   S Y S T E M S   v3.1" -ForegroundColor Green
    Write-Host "  Authorized Operations Terminal" -ForegroundColor DarkGreen
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGreen
    Write-Host "  PC Name    : $pcName" -ForegroundColor Green
    Write-Host "  MAC Address: $macAddress" -ForegroundColor Green
    Write-Host "  Local IP   : $localIp" -ForegroundColor Green
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGreen
    Write-Host "  [ 1 ] Activate THE ONE Windows Authorized" -ForegroundColor Green
    Write-Host "  [ 2 ] Activate THE ONE Office Authorized" -ForegroundColor Green
    Write-Host "  [ 3 ] THE ONE PC Optimization (Clear Temp)" -ForegroundColor Green
    Write-Host "  [ 4 ] Direct Bypass (Official Mirror)" -ForegroundColor Green
    Write-Host "  [ 0 ] Exit Terminal" -ForegroundColor DarkGreen
    Write-Host "  --------------------------------------------------" -ForegroundColor DarkGreen
    Write-Host "`n  > Select module: " -NoNewline

    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown").Character
    Write-Host "$key" -ForegroundColor Green

    if ($key -eq '0') { exit }

    switch ($key) {
        '1' {
            Invoke-OwnScript -ScriptName "HWID_Activation.cmd" -CustomTitle "THE ONE WINDOWS AUTHORIZED v3.1"
        }
        '2' {
            Invoke-OwnScript -ScriptName "Ohook_Activation_AIO.cmd" -CustomTitle "THE ONE OFFICE AUTHORIZED v3.1"
        }
        '3' {
            Write-Host "`n  [+] Cleaning temporary files..." -ForegroundColor Green
            $tempFolders = @($env:TEMP, "$env:SystemRoot\Temp")
            foreach ($folder in $tempFolders) {
                if (Test-Path $folder) {
                    Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue |
                        Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
                }
            }
            Write-Host "  [+] PC Optimized successfully." -ForegroundColor Green
            Write-Host "`n  Press any key to return to menu..." -ForegroundColor DarkGreen
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        '4' {
            Write-Host "`n  [+] Bypassing..." -ForegroundColor Green
            iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
        }
    }
}
