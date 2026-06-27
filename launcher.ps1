# launcher.ps1
# This script requires a password to execute the target .cmd file.

$password = Read-Host "keygen" -AsSecureString

# Convert the secure string to a plain text string for comparison
$bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$passString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr)

if ($passString -eq "8888") {
    Write-Host "Access Granted! Initializing..." -ForegroundColor Green
    
    # URL of your main script (Ensure it matches your GitHub filename exactly)
    $targetUrl = "https://raw.githubusercontent.com/alvinliew88/km/main/THE_ONE.cmd"
    $tempPath = "$env:TEMP\THE_ONE_RUN.cmd"
    
    try {
        # Download the file to a temp location to avoid command line length limits
        Invoke-RestMethod -Uri $targetUrl -OutFile $tempPath -ErrorAction Stop
        
        # Start the script as Administrator
        Start-Process "$tempPath" -Verb RunAs
    } catch {
        Write-Host "Download failed!" -ForegroundColor Red
        Write-Host "URL: $targetUrl" -ForegroundColor Yellow
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Yellow
        Start-Sleep -Seconds 15
    }
} else {
    Write-Host "Wrong Password!" -ForegroundColor Red
    Start-Sleep -Seconds 2
}
