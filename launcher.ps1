# 1. 密码验证逻辑
$password = Read-Host "keygen" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$passString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

if ($passString -eq "8888") {
    Write-Host "密码正确，正在启动..." -ForegroundColor Green
    
    # 2. 确保这里的 URL 准确指向您的 THE ONE.cmd
    # 请手动在浏览器打开该地址，确认能直接下载该文件
    $targetUrl = "https://raw.githubusercontent.com/alvinliew88/km/main/THE%20ONE.cmd"
    $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
    
    try {
        Invoke-RestMethod -Uri $targetUrl -OutFile $tempPath -ErrorAction Stop
        Start-Process "$tempPath" -Verb RunAs
    } catch {
        Write-Host "下载失败，请检查 URL 是否正确: $targetUrl" -ForegroundColor Red
        Start-Sleep -Seconds 5
    }
} else {
    Write-Host "密码错误，程序已终止。" -ForegroundColor Red
    Start-Sleep -Seconds 2
}
