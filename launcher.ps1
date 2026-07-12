# launcher.ps1 - THE ONE SYSTEM v3.1 (Auto-download with fallback, deep clean)

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

function Invoke-ModifiedScript {
    param(
        [string]$ScriptName,
        [string]$CustomTitle,
        [string]$ValidationKeyword
    )
    Write-Host "`n  [+] Access Granted! Initializing..." -ForegroundColor Green
    $tempPath = "$env:TEMP\$ScriptName"
    $baseUrl = "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/Separate-Files-Version/Activators"
    try {
        try {
            $rawText = Invoke-RestMethod -Uri "$baseUrl/$ScriptName" -ErrorAction Stop
        } catch {
            Write-Host "  [!] Invoke-RestMethod failed, trying curl..." -ForegroundColor Yellow
            $rawText = & curl.exe -sSfL --doh-url https://1.1.1.1/dns-query "$baseUrl/$ScriptName" | Out-String
            if ($LASTEXITCODE -ne 0) { throw "Both download methods failed." }
        }
        if ($rawText -notmatch $ValidationKeyword) {
            throw "Downloaded content does not contain '$ValidationKeyword'. Script may have moved."
        }
        $rawText = $rawText -replace '(?im)^\s*title\s+.*$', "title  $CustomTitle"
        if ($ScriptName -eq "Ohook_Activation_AIO.cmd") {
            $rawText = $rawText -replace 'Install Ohook Office Activation', 'Install THE ONE Office Activation'
            $rawText = $rawText -replace 'Uninstall Ohook', 'Uninstall THE ONE'
            $rawText = $rawText -replace 'Ohook activation is not installed\.', 'THE ONE activation is not installed.'
            $rawText = $rawText -replace 'Successfully uninstalled Ohook activation\.', 'Successfully uninstalled THE ONE activation.'
            $rawText = $rawText -replace 'Failed to uninstall Ohook activation\.', 'Failed to uninstall THE ONE activation.'
            $rawText = $rawText -replace 'Uninstalling Ohook activation', 'Uninstalling THE ONE activation'
            $rawText = $rawText -replace 'Installing Ohook\b', 'Installing THE ONE'
            $rawText = $rawText -replace 'Remove Previous Ohook Install', 'Remove Previous THE ONE Install'
            $rawText = $rawText -replace 'after Ohook activation', 'after THE ONE activation'
        }
        $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
        [System.IO.File]::WriteAllText($tempPath, $rawText, $utf8NoBom)
        Start-Process -FilePath $tempPath
        Start-Sleep -Seconds 3
        Remove-Item -Path $tempPath -Force -ErrorAction SilentlyContinue
    } catch {
        Write-Host "  [-] Execution failed!" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
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
    Write-Host "`n  (Note: Files locked by running programs cannot be deleted.)" -ForegroundColor DarkGray
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
            Invoke-ModifiedScript -ScriptName "HWID_Activation.cmd" `
                -CustomTitle "THE ONE WINDOWS AUTHORIZED v3.1" `
                -ValidationKeyword "masver"
        }
        '2' {
            Invoke-ModifiedScript -ScriptName "Ohook_Activation_AIO.cmd" `
                -CustomTitle "THE ONE OFFICE AUTHORIZED v3.1" `
                -ValidationKeyword "oh_menu"
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
