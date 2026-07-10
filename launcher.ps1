# 1-Click Patcher for THE ONE SYSTEM
$files = Get-ChildItem -Filter "*.cmd"

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    # 替换配色为黑底青字
    $content = $content -replace 'color 07', 'color 0B'
    
    # 拦截自动闪退：将 2秒退出 替换为 永久暂停等待按键
    $content = $content -replace 'timeout /t 2 & exit /b', 'echo. & echo   [ THE ONE AUTHORIZED - Task Completed ] & pause >nul & exit /b'
    
    # 替换所有窗口标题
    $content = $content -replace 'title  Microsoft_Activation_Scripts %masver%', 'title  THE ONE AUTHORIZED [SYSTEM]'
    $content = $content -replace 'title  HWID Activation %masver%', 'title  THE ONE WINDOWS AUTHORIZED'
    $content = $content -replace 'title  Ohook Activation %masver%', 'title  THE ONE OFFICE AUTHORIZED'
    
    Set-Content -Path $file.FullName -Value $content -Encoding Ascii
    Write-Host "Patched: $($file.Name)" -ForegroundColor Green
}
