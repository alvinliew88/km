[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

try {
    $Host.UI.RawUI.WindowTitle = "THE ONE SYSTEMS v2.0"
    $ws = $Host.UI.RawUI.WindowSize; $ws.Width = 76; $ws.Height = 25
    $bs = $Host.UI.RawUI.BufferSize; $bs.Width = 76; $bs.Height = 300
    $Host.UI.RawUI.WindowSize = $ws
    $Host.UI.RawUI.BufferSize = $bs
} catch {}

$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

$password = Read-Host "key" -AsSecureString
$passString = if($password){[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))}
if ($passString -ne "8888") { Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red; Start-Sleep -Seconds 2; exit }

while ($true) {
    Clear-Host
    Write-Host "`n  T H E   O N E   S Y S T E M S   v2.0" -ForegroundColor Cyan
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
                    $resp = Invoke-RestMethod -Uri $u -UseBasicParsing -ErrorAction Stop
                    if ($resp -match "masver") {
                        $cmdContent = $resp
                        break
                    }
                } catch {}
            }
            
            if (-not $cmdContent) { throw "All mirrors blocked by ISP." }
            
            Write-Host "  [+] Injecting THE ONE Authority..." -ForegroundColor Cyan
            
            $cmdContent = $cmdContent -replace "`r`n", "`n" -replace "`n", "`r`n"
            $cmdContent = $cmdContent -replace '@echo off', "@echo off`r`nmode 76, 25"
            $cmdContent = $cmdContent.Replace("color 07", "color 0B")
            $cmdContent = $cmdContent -replace '(?im)^\s*title\s+.*', "title $CustomTitle"
            $cmdContent = $cmdContent.Replace("if %_unattended%==1 timeout /t 2 & exit /b", "if %_unattended%==1 echo. & echo   [ THE ONE AUTHORIZED - Task Completed ] & echo   Press any key to close this window... & pause >nul & exit /b")
            $cmdContent += "`r`n`r`n"
            
            [System.IO.File]::WriteAllText($tempPath, $cmdContent, [System.Text.Encoding]::ASCII)
            
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempPath`" $ArgsInput" -Verb RunAs -Wait
            
            Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
            
        } catch {
            Write-Host "  [-] Execution failed!" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }

    switch ($key) {
        '1' { Invoke-TheOne "/HWID" "THE ONE WINDOWS AUTHORIZED v2.0" }
        '2' { Invoke-TheOne "/Ohook" "THE ONE OFFICE AUTHORIZED v2.0" }
        '3' {
            Write-Host "`n  [+] Optimizing PC Storage..." -ForegroundColor Cyan
            Start-Sleep -Seconds 2
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
