# 1. 自动清除键盘向上方向键的历史记录
if (Get-Module PSReadLine) {
    Remove-History -ErrorAction SilentlyContinue
    Set-PSReadLineOption -HistorySavePath $null -ErrorAction SilentlyContinue
}

# 2. 强制管理员提权
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://raw.githubusercontent.com/alvinliew88/km/main/launcher.ps1 | iex`"" -Verb RunAs
    exit
}

# 3. 调用底层 API：强制将 CMD/PowerShell 窗口拉到屏幕最前方，不被 Chrome 挡住
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class Win32 {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd);
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();
}
"@
[Win32]::SetForegroundWindow([Win32]::GetConsoleWindow()) | Out-Null

# 4. 倒计时输入监听器 (带星号掩码)
function Read-ConsoleInput {
    param (
        [string]$Prompt,
        [int]$Timeout = 30,
        [switch]$IsPassword
    )
    Write-Host $Prompt -NoNewline
    $inputStr = ""
    $start = Get-Date

    while ($true) {
        if ([console]::KeyAvailable) {
            $key = [console]::ReadKey($true)
            if ($key.Key -eq 'Enter') {
                Write-Host ""
                return $inputStr
            } elseif ($key.Key -eq 'Backspace') {
                if ($inputStr.Length -gt 0) {
                    $inputStr = $inputStr.Substring(0, $inputStr.Length - 1)
                    Write-Host "`b `b" -NoNewline
                }
            } else {
                $inputStr += $key.KeyChar
                if ($IsPassword) { Write-Host "*" -NoNewline }
                else { Write-Host $key.KeyChar -NoNewline }
            }
            $start = Get-Date
        }
        
        if ((Get-Date).Subtract($start).TotalSeconds -ge $Timeout) {
            return $null
        }
        Start-Sleep -Milliseconds 50
    }
}

# 5. 极简密码锁验证 (只显示 $)
Clear-Host
$pwd = Read-ConsoleInput -Prompt "$ " -Timeout 30 -IsPassword

# 如果密码不是 8888 或者超时 30 秒没有操作，直接安全退出
if ($null -eq $pwd -or $pwd -ne "8888") {
    exit
}

Clear-Host

# 6. 核心优化函数
function Run-OptimizationSuite {
    Clear-Host
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "   THE ONE SYSTEMS - Ultimate Optimization Suite   " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
    
    Write-Host "[1/6] Enabling MMAgent Memory Compression..." -ForegroundColor Green
    Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
    
    Write-Host "[2/6] Disabling SysMain (Superfetch)..." -ForegroundColor Green
    Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
    
    Write-Host "[3/6] Disabling DiagTrack & Telemetry..." -ForegroundColor Green
    Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    $DiagPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if (!(Test-Path $DiagPath)) { New-Item -Path $DiagPath -Force | Out-Null }
    Set-ItemProperty -Path $DiagPath -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
    
    Write-Host "[4/6] Disabling Windows Search (WSearch)..." -ForegroundColor Green
    Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
    Set-Service -Name "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue
    
    Write-Host "[5/6] Applying Performance Visual Effects..." -ForegroundColor Green
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 3 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "FontSmoothing" -Value "2" -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "IconsOnly" -Value 0 -Force -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "DropShadow" -Value 1 -Force -ErrorAction SilentlyContinue
    
    Write-Host "[6/6] Restarting Explorer for instant visual application..." -ForegroundColor Green
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    
    Write-Host "===================================================" -ForegroundColor Cyan
    Write-Host "   Optimization Complete! Returning to Terminal.   " -ForegroundColor Cyan
    Write-Host "===================================================" -ForegroundColor Cyan
}

# 7. 主菜单循环设计
while ($true) {
    Clear-Host
    Write-Host "---------------------------------------------------" -ForegroundColor Cyan
    Write-Host " T H E   O N E   S Y S T E M S   v2.0" -ForegroundColor Cyan
    Write-Host " Authorized Operations Terminal (Cloud Edition)" -ForegroundColor DarkGray
    Write-Host "---------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "[1] Reactivate THE ONE PC Authorized Windows" -ForegroundColor Green
    Write-Host "[2] Reactivate THE ONE PC Office" -ForegroundColor Green
    Write-Host "[3] THE ONE PC Optimization (Clear Temp & Cache)" -ForegroundColor Green
    Write-Host "[4] Full THE ONE Activation Suite (Run Local .cmd)" -ForegroundColor Green
    Write-Host "[5] Install Essential Apps (WinGet)" -ForegroundColor Green
    Write-Host "[6] Remove Bulky Windows Apps (Safe)" -ForegroundColor Green
    Write-Host "[7] Enable MM Agent & Full Optimization Suite" -ForegroundColor Green
    Write-Host "[8] Restart PC Immediately" -ForegroundColor Red
    Write-Host "[0] Exit Terminal" -ForegroundColor DarkGray
    Write-Host "---------------------------------------------------" -ForegroundColor Cyan
    
    $choice = Read-ConsoleInput -Prompt "> Select module: " -Timeout 30
    
    if ($null -eq $choice) {
        exit
    }
    
    switch ($choice) {
        '1' { 
            Write-Host "Activating Windows via MAS HWID..." -ForegroundColor Yellow
            & ([ScriptBlock]::Create((irm https://get.activated.win))) /HWID
        }
        '2' { 
            Write-Host "Activating Office via MAS Ohook..." -ForegroundColor Yellow
            & ([ScriptBlock]::Create((irm https://get.activated.win))) /Ohook
        }
        '3' { 
            Write-Host "Clearing System Temp Files..." -ForegroundColor Yellow
            Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:windir\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Cleanup Complete." -ForegroundColor Green
        }
        '4' { 
            Write-Host "Downloading and executing Ohook_Activation_AIO.cmd from GitHub..." -ForegroundColor Yellow
            $cmdPath = "$env:TEMP\Ohook_Activation_AIO.cmd"
            Invoke-WebRequest -Uri "https://raw.githubusercontent.com/alvinliew88/km/main/Ohook_Activation_AIO.cmd" -OutFile $cmdPath -UseBasicParsing
            Start-Process -FilePath $cmdPath -Wait
            Remove-Item $cmdPath -Force -ErrorAction SilentlyContinue
        }
        '5' { 
            Write-Host "Installing Essential Apps (Google Chrome, 7-Zip, VLC, WhatsApp)..." -ForegroundColor Yellow
            winget install -e --id Google.Chrome --accept-source-agreements --accept-package-agreements
            winget install -e --id 7zip.7zip --accept-source-agreements --accept-package-agreements
            winget install -e --id VideoLAN.VLC --accept-source-agreements --accept-package-agreements
            winget install -e --id WhatsApp.WhatsApp --accept-source-agreements --accept-package-agreements
            Write-Host "Installation Complete." -ForegroundColor Green
        }
        '6' { 
            Write-Host "Removing pre-installed bloatware (TikTok, Instagram, etc.)..." -ForegroundColor Yellow
            Get-AppxPackage *TikTok* | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxPackage *Instagram* | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxPackage *Facebook* | Remove-AppxPackage -ErrorAction SilentlyContinue
            Write-Host "Bloatware removed safely." -ForegroundColor Green
        }
        '7' { Run-OptimizationSuite }
        '8' { 
            Clear-Host
            Write-Host "Initiating Immediate System Restart..." -ForegroundColor Red
            Restart-Computer -Force 
        }
        '0' { exit }
        default {
            Write-Host "Invalid option. Please try again." -ForegroundColor Red
        }
    }
    
    if ($choice -ne '8' -and $choice -ne '0') {
        Write-Host "`nOperation finished." -ForegroundColor Cyan
        $returnWait = Read-ConsoleInput -Prompt "Press Enter to return to Main Menu... (30s timeout)" -Timeout 30
        if ($null -eq $returnWait) { exit }
    }
}
