# 1. 密码验证逻辑
$password = Read-Host "keygen" -AsSecureString
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$passString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

if ($passString -eq "8888") {
    Write-Host "密码正确，正在启动..." -ForegroundColor Green
    
    # 指向重命名后的 THE_ONE.cmd
    $targetUrl = "https://raw.githubusercontent.com/alvinliew88/km/main/THE_ONE.cmd"
    $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
    
    try {
        Invoke-RestMethod -Uri $targetUrl -OutFile $tempPath -ErrorAction Stop
        Start-Process "$tempPath" -Verb RunAs
    } catch {
        Write-Host "下载失败，请检查 URL 是否正确。" -ForegroundColor Red
        Start-Sleep -Seconds 5
    }
} else {
    Write-Host "密码错误，程序已终止。" -ForegroundColor Red
    Start-Sleep -Seconds 2
}
