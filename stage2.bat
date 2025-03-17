@powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$_=((Get-Content \"%~f0\") -join \"`n\");iex $_.Substring($_.IndexOf(\"goto :\"+\"EOF\")+9)"
@goto :EOF

$nextStage = "stage3.bat"
$dir = "C:\temp"
$url = "https://raw.githubusercontent.com/itcentrenz/win10debloat/main/$($nextStage)"
$download_path = "$($dir)\$($nextStage)"
$Exist = (Test-Path -Path $dir)
If (-not $Exist ) {
    New-Item -Path $dir -ItemType directory
}

# Set up logging
$logFile = "Focus_W11_Setup.log"
$logFullPath = "$($dir)\$($logFile)"

Function Write-Log {
    Param (
        [string]$LogString
    )
    Add-Content -Path $logFullPath -Value $LogString
}

Invoke-WebRequest -Uri $url -OutFile $download_path -UseBasicParsing
Get-Item $download_path | Unblock-File

Write-Host "Re-running Windows Update as it then installs the latest Optional Updates"
Get-WindowsUpdate -install -acceptall -IgnoreReboot -Confirm:$false -Verbose
# Read-Host "Did Get-WindowsUpdate work?"

# http://download.windowsupdate.com/d/msdownload/update/software/updt/2021/11/windows10.0-kb5007253-x64_56eae3ea4ddb22105db274b6d903cd73dfaea5ed.msu
# x64 Feature Update

Write-Log "Microsoft Update (second run) complete."

Write-Host "Cleaning Up Temp Files"

# From https://docs.microsoft.com/en-us/windows/win32/lwef/disk-cleanup
# DDEVCF_DOSUBDIRS (0x00000001). Search and remove recursively.
# DDEVCF_REMOVEAFTERCLEAN (0x00000002). After the handler is run once, remove it from the registry.
# DDEVCF_REMOVEREADONLY (0x00000004). Remove files that meet the search criteria even if they are read-only.
# DDEVCF_REMOVESYSTEM (0x00000008). Remove files that meet the search criteria even if they are system files.
# DDEVCF_REMOVEHIDDEN (0x00000010). Remove files that meet the search criteria even if they are hidden files.

New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files' -PropertyType 'DWORD' -Force -Name 'StateFlags1337' -Value 0x2
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations' -PropertyType 'DWORD' -Force -Name 'StateFlags1337' -Value 0x2
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Delivery Optimization Files' -PropertyType 'DWORD' -Force -Name 'StateFlags1337' -Value 0x2
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin' -PropertyType 'DWORD' -Force -Name 'StateFlags1337' -Value 0x2
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files' -PropertyType 'DWORD' -Force -Name 'StateFlags1337' -Value 0x2
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows ESD installation files' -PropertyType 'DWORD' -Force -Name 'StateFlags1337' -Value 0x2
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Update Cleanup' -PropertyType 'DWORD' -Force -Name 'StateFlags1337' -Value 0x2
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Defender' -PropertyType 'DWORD' -Force -Name 'StateFlags1337' -Value 0x2

$clnmgr = "cleanmgr.exe"
$arguments = "/SAGERUN:1337"
start-process $clnmgr $arguments -NoNewWindow -Wait
# Read-Host "Did CleanMgr Work?"

Write-Log "Disk Cleanup complete."

# Add 3rd stage to RunOnce Registry Key
$value = "$($dir)\$($nextStage)"
$name = "!$($nextStage)"
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name $name -Value $value -Force

Write-Log "Stage 2 complete, rebooting."

Restart-Computer -Force -Confirm:$false