# launcher.ps1 - THE ONE SYSTEM v2.6 (Bulletproof Fetcher)
# Authorized IT Execution Script

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# 1. Create a secure temporary directory
$tempDir = "$env:TEMP\TheOneSystem"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir | Out-Null }

$menuPs1 = "$tempDir\Menu.ps1"
$menuCmd = "$tempDir\Launcher.cmd"

# 2. Core Menu Logic (Executed in the standalone window)
$menuCode = @'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Force classic window size 98x30 to perfectly match the original MAS layout
try {
    $Host.UI.RawUI.WindowTitle = "THE ONE SYSTEMS v2.6"
    $ws = $Host.UI.RawUI.WindowSize; $ws.Width = 98; $ws.Height = 30
    $bs = $Host.UI.RawUI.BufferSize; $bs.Width = 98; $bs.Height = 300
    $Host.UI.RawUI.WindowSize = $ws
    $Host.UI.RawUI.BufferSize = $bs
} catch {}

$pcName = $env:COMPUTERNAME
$localIp = (Get-NetIPAddress -AddressFamily IPv4 -AddressState Preferred | Where-Object InterfaceAlias -NotMatch 'Loopback' | Select-Object -First 1).IPAddress
try { $macAddress = (Get-NetAdapter | Where-Object Status -eq 'Up' | Select-Object -First 1).MacAddress } catch { $macAddress = "UNKNOWN" }

# Prompt for password in the new independent window
$password = Read-Host "key" -AsSecureString
$passString = if($password){[System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))}
if ($passString -ne "8888") { Write-Host "`n[!] ACCESS DENIED" -ForegroundColor Red; Start-Sleep -Seconds 2; exit }

while ($true) {
    # Ensure pure colors during loop refreshes
    [Console]::BackgroundColor = "Black"
    [Console]::ForegroundColor = "White"
    Clear-Host

    Write-Host "`n  T H E   O N E   S Y S T E M S   v2.6" -ForegroundColor Cyan
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
        
        $tempPath = "$env:TEMP\TheOneSystem\RUN.cmd"
        $cmdContent = $null
        
        try {
            # STAGE 1: Dynamically intercept the unblocked get.activated.win wrapper and parse its mirrors
            try {
                $wrapper = Invoke-RestMethod -Uri "https://get.activated.win" -UseBasicParsing -ErrorAction Stop
                $urls = [regex]::Matches($wrapper, 'https://[^\s"''`*]+\.cmd') | ForEach-Object { $_.Value } | Select-Object -Unique
                
                foreach ($u in $urls) {
                    if ($u -match "MAS_AIO.cmd") {
                        $cmdContent = (New-Object System.Net.WebClient).DownloadString($u)
                        if ($cmdContent -match "masver") { break }
                    }
                }
            } catch {}

            # STAGE 2: Fallback to the official anti-censorship mirror and standard domains
            if (-not $cmdContent -or $cmdContent -notmatch "masver") {
                $fallbackUrls = @(
                    "https://git.activated.win/massgravel/Microsoft-Activation-Scripts/raw/branch/master/MAS/All-In-One-Version/MAS_AIO.cmd",
                    "https://raw.githubusercontent.com/massgravel/Microsoft-Activation-Scripts/master/MAS/All-In-One-Version/MAS_AIO.cmd",
                    "https://bitbucket.org/WindowsAddict/microsoft-activation-scripts/raw/master/MAS/All-In-One-Version/MAS_AIO.cmd",
                    "https://codeberg.org/massgravel/Microsoft-Activation-Scripts/raw/branch/master/MAS/All-In-One-Version/MAS_AIO.cmd"
                )
                foreach ($u in $fallbackUrls) {
                    try {
                        $cmdContent = (New-Object System.Net.WebClient).DownloadString($u)
                        if ($cmdContent -match "masver") { break }
                    } catch {}
                }
            }
            
            if (-not $cmdContent -or $cmdContent -notmatch "masver") { throw "All mirrors blocked by ISP." }
            
            Write-Host "  [+] Injecting THE ONE Authority..." -ForegroundColor Cyan
            
            # Safe anti-self-destruct injection and title override
            $cmdContent = $cmdContent -replace "`r`n", "`n" -replace "`n", "`r`n"
            $cmdContent = $cmdContent -replace '(?m)^@echo off', "@echo off`r`nmode 98, 30"
            $cmdContent = $cmdContent -replace '(?im)^\s*title\s+.*', "title $CustomTitle"
            $cmdContent = $cmdContent.Replace("if %_unattended%==1 timeout /t 2 & exit /b", "if %_unattended%==1 echo. & echo   [ THE ONE AUTHORIZED - Task Completed ] & echo   Press any key to return to menu... & pause >nul & exit /b")
            $cmdContent += "`r`n`r`n"
            
            [System.IO.File]::WriteAllText($tempPath, $cmdContent, [System.Text.Encoding]::ASCII)
            
            # Execute the activation script inside this EXACT window layout without popping another one
            Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$tempPath`" $ArgsInput" -Wait -NoNewWindow
            
            Remove-Item -Path $tempPath -ErrorAction SilentlyContinue
            
        } catch {
            Write-Host "  [-] Execution failed!" -ForegroundColor Red
            Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
        }
    }

    switch ($key) {
        '1' { Invoke-TheOne "/HWID" "THE ONE WINDOWS AUTHORIZED v2.6" }
        '2' { Invoke-TheOne "/Ohook" "THE ONE OFFICE AUTHORIZED v2.6" }
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
'@

# 3. Official Terminal Bypass Wrapper with Safety Lock
$cmdWrapper = @"
@echo off
setlocal EnableDelayedExpansion

:: [SAFETY LOCK]: Instantly breaks infinite loop bombs
if "%~1"=="-qedit" goto :skipQE

:: Force detect Windows Terminal and escape to conhost
set terminal=
set lines=0
for /f "skip=3 tokens=* delims=" %%A in ('mode con') do if "!lines!"=="0" (
    for %%B in (%%A) do set lines=%%B
)
if !lines! GEQ 100 set terminal=1

if defined terminal (
    start conhost.exe "%~f0" -qedit
    exit /b
)

:skipQE
:: Launch the PowerShell menu in the perfectly sized new window
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "$menuPs1"
exit /b
"@

# 4. Generate bootstrapper files
Set-Content -Path $menuPs1 -Value $menuCode -Encoding UTF8
[System.IO.File]::WriteAllText($menuCmd, $cmdWrapper, [System.Text.Encoding]::ASCII)

# 5. Instantly launch the new window (freeing the current terminal)
Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$menuCmd`""
