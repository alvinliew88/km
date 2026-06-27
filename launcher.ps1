# launcher.ps1
$password = Read-Host "keygen" -AsSecureString
# ... (密码逻辑保持不变)

if ($passString -eq "8888") {
    # 确保此处的 URL 与 GitHub 上的文件名 100% 匹配
    $targetUrl = "https://raw.githubusercontent.com/alvinliew88/km/main/THE_ONE.cmd"
    $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
    
    # 尝试直接下载
    try {
        Invoke-RestMethod -Uri $targetUrl -OutFile $tempPath -ErrorAction Stop
        Start-Process "$tempPath" -Verb RunAs
    } catch {
        # 如果还是失败，这行代码会打印出真实的错误原因
        Write-Host "Download failed! URL: $targetUrl" -ForegroundColor Red
        $_.Exception.Message | Write-Host -ForegroundColor Yellow
        Start-Sleep -Seconds 10
    }
} else {
    Write-Host "Wrong Password!" -ForegroundColor Red
    Start-Sleep -Seconds 2
}
