# launcher.ps1
$password = Read-Host "请输入密码" -AsSecureString
$secureString = ConvertTo-SecureString "8888" -AsPlainText -Force

if ([System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)) -eq "8888") {
    Write-Host "密码正确，正在启动..." -ForegroundColor Green
    
    # 定义您的核心脚本地址
    $targetUrl = "https://raw.githubusercontent.com/alvinliew88/km/main/THE%20ONE.cmd"
    $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
    
    # 下载并执行
    Invoke-RestMethod -Uri $targetUrl -OutFile $tempPath
    Start-Process "$tempPath" -Verb RunAs
} else {
    Write-Host "密码错误，程序已终止。" -ForegroundColor Red
    Start-Sleep -Seconds 2
}