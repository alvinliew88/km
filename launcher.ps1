# launcher.ps1 - THE ONE SYSTEM v2.3 (Conhost Pop-up Edition)
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$tempScript = "$env:TEMP\TheOneMenu.ps1"

$menuCode = @'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Force classic window size 98x30 to match original fork perfectly
try {
    $Host.UI.RawUI.WindowTitle = "THE ONE SYSTEMS v2.3"
    $ws = $Host.UI.RawUI.WindowSize; $ws.Width = 98; $ws.Height = 30
    $bs = $Host.UI.RawUI.BufferSize; $bs.Width = 98; $bs.Height = 300
    $Host.UI.RawUI.WindowSize = $ws
    $Host.UI.RawUI.BufferSize = $bs
} catch {}

$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

$password = Read-Host "key" -AsSecureString
$passString = if($password){[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))}
if ($passString -ne "8888") { Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red; Start-Sleep -Seconds 2; exit }

# ---------------------------------------------------------
# UI DISPLAY (Infinite Loop)
# ---------------------------------------------------------
while ($true) {
    Clear-Host
    Write-Host "`n  T H E   O N E   S Y S T E M S   v2.3" -ForegroundColor Cyan
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

    if ($key -eq '0') { exit }

    function Invoke-TheOne {
        param($ArgsInput, $CustomTitle)
        Write-Host "`n  [+] Access Granted! Initializing..." -ForegroundColor Green
        Write-Host "  [+] Establishing secure bridge to official source..." -ForegroundColor Cyan
        
        $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
        
        try {
            $urls = @(
                "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd",
                "https://bitbucket.org/WindowsAddict/microsoft-activation-scripts/raw/master/MAS/All-In-One-Version/MAS_AIO.cmd",
                "https://codeberg.org/massgravel/Microsoft-Activation-Scripts/raw/branch/master/MAS/All-In-One-Version/MAS_AIO.cmd"
            )
            
            $cmdContent = $null
            foreach ($u in $urls) {
                try {
                    $resp = (curl.exe -sL --doh-url https://1.1.1.1/dns-query $u) -join "`n"
                    if ($resp -match "masver") { $cmdContent = $resp; break }
                } catch {}
                
                if (-not $cmdContent) {
                    try {
                        $resp = Invoke-RestMethod -Uri $u -UseBasicParsing -ErrorAction Stop
                        if ($resp -match "masver") { $cmdContent = $resp; break }
                    } catch {}
                }
            }
            
            if (-not $cmdContent) { throw "All mirrors blocked by ISP." }
            
            Write-Host "  [+] Injecting THE ONE Authority..." -ForegroundColor Cyan
            
            $cmdContent = $cmdContent -replace "`r`n", "`n" -replace "`n", "`r`n"
            $cmdContent = $cmdContent -replace '(?m)^@echo off', "@echo off`r`nmode 98, 30"
            $cmdContent = $cmdContent -replace '(?im)^\s*title\s+.*', "title $CustomTitle"
            $cmdContent = $cmdContent.Replace("if %_unattended%==1 timeout /t 2 & exit /b", "if %_unattended%==1 echo. & echo   [ THE ONE AUTHORIZED - Task Completed ] & echo   Press any key to close this window... & pause >nul & exit /b")
            $cmdContent += "`r`n`r`n"
            
            [System.IO.File]::WriteAllText($tempPath, $cmdContent, [System.Text.Encoding]::ASCII)
            
            # Use conhost.exe to force a classic standalone CMD window with perfect original font scaling
            Start-Process -FilePath "conhost.exe" -ArgumentList "cmd.exe /c `"$tempPath`" $ArgsInput" -Verb RunAs -Wait
            
            Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
            
        } catch {
            Write-Host "  [-] Execution failed!" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }

    switch ($key) {
        '1' { Invoke-TheOne "/HWID" "THE ONE WINDOWS AUTHORIZED v2.3" }
        '2' { Invoke-TheOne "/Ohook" "THE ONE OFFICE AUTHORIZED v2.3" }
        '3' {
            Write-Host "`n  [+] Optimizing PC Storage..." -ForegroundColor Cyan
            Get-ChildItem -Path $env:TEMP -Recurse -File -ErrorAction SilentlyContinue | 
                Where-Object { $_.Name -ne 'TheOneMenu.ps1' -and $_.Name -ne 'THE_ONE_RUN.cmd' } | 
                Remove-Item -Force -ErrorAction SilentlyContinue
            Write-Host "  [+] PC Optimized successfully." -ForegroundColor Green
            Write-Host "`n  Press any key to return to menu..." -ForegroundColor DarkGray
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
        '4' {
            Write-Host "`n  [+] Bypass..." -ForegroundColor Cyan
            iex (curl.exe -s --doh-url https://1.1.1.1/dns-query https://get.activated.win | Out-String)
            Write-Host "`n  Press any key to return to menu..." -ForegroundColor DarkGray
            $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
        }
    }
}
'@

Set-Content -Path $tempScript -Value $menuCode -Encoding UTF8

# The Magic Bullet: Force legacy console host to escape Windows Terminal tab hijacking
Start-Process -FilePath "conhost.exe" -ArgumentList "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$tempScript`"" -Verb RunAs
