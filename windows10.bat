@powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$_=((Get-Content \"%~f0\") -join \"`n\");iex $_.Substring($_.IndexOf(\"goto :\"+\"EOF\")+9)"
@goto :EOF
If (-Not (Get-NetConnectionProfile).IPv4Connectivity -contains "Internet") { 
	Write-host "Manually connect Wi-Fi or Ethernet..." -BackgroundColor Red -ForegroundColor Black
	Read-host -Prompt "Press a key to continue when connected"
}
# Test Network Connection
[int]$SleepTimer = "2" #seconds to attempt after 
[int]$Attempts = "5"
$AttemptsCounter = 0
$RemainingAttempts = $Attempts - $AttemptsCounter
Write-Host "Testing to see if network connection is avilable..."
while($RemainingAttempts -gt 0) {
    if(Test-Connection raw.githubusercontent.com -Quiet -Count 1) {
        Write-Host "Network connection is Good!" -BackgroundColor Green -ForegroundColor Black
        break
    } else {
        Write-Host "Network is not connected. Retrying..." -BackgroundColor Red -ForegroundColor Black
        Start-Sleep -Seconds ($SleepTimer)
        $RemainingAttempts--
    }
}
if($RemainingAttempts -eq 0) {
    Write-Host "Maximum number of attempts reached trying to connection to the internet"
    Write-Host "Internet Connection Failed" -BackgroundColor Red
    Exit
}
Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://git.io/JXBtp'))