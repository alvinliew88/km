# launcher.ps1 - THE ONE SYSTEM v3.1
# Downloads official MAS AIO, changes title only, and starts activation directly.

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

    Write-Host "`n  [+] Access Granted! Initializing..." -ForegroundColor Green
    $tempPath = "$env:TEMP\THE_ONE_AIO.cmd"
    $url = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version-KL/MAS_AIO.cmd"

    try {
        $raw = Invoke-RestMethod -Uri $url -ErrorAction Stop
        if ($raw -notmatch 'MAS_AIO') { throw "Invalid download" }

        # Only change the window title, leave everything else intact.
        $raw = $raw -replace '(?im)^title .*$', 'title  THE ONE SYSTEMS v3.1'

        # Ensure CRLF line endings and final empty line.
        $raw = $raw -replace '(?<!\r)\n', "`r`n"
        if (-not $raw.EndsWith("`r`n")) { $raw += "`r`n" }

        [System.IO.File]::WriteAllText($tempPath, $raw, [System.Text.Encoding]::ASCII)

        # Launch with the activation mode to skip the menu.
        Start-Process -FilePath $tempPath -ArgumentList $Mode

        Start-Sleep -Seconds 3
        Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
    }
    catch {
        Write-Host "  [-] Error: $($_.Exception.Message)" -ForegroundColor Red
        Start-Sleep -Seconds 5
    }
}

function Invoke-DeepClean {
    Write-Host "`n  [+] Deep cleaning..." -ForegroundColor Cyan
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
            Get-ChildItem $folder -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
        }
    }
    try { cleanmgr /sagerun:1 | Out-Null } catch {}
    Write-Host "  [+] PC Optimized." -ForegroundColor Green
}

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
            Write-Host "`n  Press any key to return..." -ForegroundColor DarkGray
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        '4' {
            Write-Host "`n  [+] Launching original MAS menu..." -ForegroundColor Cyan
            iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
        }
    }
}
