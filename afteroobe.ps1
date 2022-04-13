# Tim Welch
# 16/03/2022
# Script to run immediately after OOBE to clean things up.

#Set Search Bar to Icon
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search"
$Name = "SearchboxTaskbarMode"
$value = "1"
$SearchBar = Get-Item -Path $registryPath
If($null -eq $SearchBar.GetValue($Name)) {
  New-ItemProperty -Path $registryPath -Name $Name -Value $value -PropertyType DWord
} else {
  Set-ItemProperty -Path $registryPath -Name $Name -Value $value
}

#Remove Task View Button
$registryPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
$Name = "ShowTaskViewButton"
$value = "0"
$TaskBar = Get-Item -Path $registryPath
If($null -eq $TaskBar.GetValue($Name)) {
  New-ItemProperty -Path $registryPath -Name $Name -Value $value -PropertyType DWord
} else {
  Set-ItemProperty -Path $registryPath -Name $Name -Value $value
}

#Show My Computer on the Desktop
$Path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
$Name = "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
$Exist = Get-ItemProperty -Path $Path -Name $Name
if ($Exist)
{
    Set-ItemProperty -Path $Path -Name $Name -Value 0
}
Else
{
    New-ItemProperty -Path $Path -Name $Name -Value 0
}

# Remove News And Interests
$registryPath = "HKCU:SOFTWARE\Microsoft\Windows\CurrentVersion\Feeds"
$Name = "ShellFeedsTaskbarViewMode"
$value = "2"
new-item 'HKLM:SOFTWARE\Policies\Microsoft\Windows' -Name 'Windows Feeds'
$TaskBar = Get-Item -Path $registryPath
If($null -eq $TaskBar.GetValue($Name)) {
   New-ItemProperty -Path $registryPath -Name $Name -Value $value -PropertyType DWord
} else {
   Set-ItemProperty -Path $registryPath -Name $Name -Value $value
}

#Remove suggestions from the Start Menu
REG ADD "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 1 /f

#Rename PC and reboot
If (Test-Path -Path "C:\temp\computername.txt") {
  $NewComputerName = get-content "C:\temp\computername.txt"
  Rename-Computer -NewName $NewComputerName -Force
}
else {
  Write-Host "Unable to rename PC - do it manually"
}

# Install RMM Agent if it has been requested and copied over
$ITCFolder = "C:\IT Centre"
$SolarWinds = "AGENT.exe"
$Exist = (Test-Path -Path "$ITCFolder\$SolarWinds")
If($Exist){
  start-process -filepath "$ITCFolder\$SolarWinds" -wait -passthru
}

# Install AnyDesk
$AnyDesk = "IT-Centre-AnyDesk-Setup.exe"
$Exist = (Test-Path -Path "$ITCFolder\$AnyDesk")
$arguments = "/S"
If($Exist){
  start-process -filepath "$ITCFolder\$AnyDesk" -ArgumentList $arguments -wait -passthru
}

#Unpin Microsoft Store
$appname = "Microsoft Store"
((New-Object -Com Shell.Application).NameSpace('shell:::{4234d49b-0245-4df3-b780-3893943456e1}').Items() | Where-Object{$_.Name -eq $appname}).Verbs() | Where-Object{$_.Name.replace('&','') -match 'Unpin from taskbar'} | ForEach-Object{$_.DoIt(); $exec = $true}

#Remove remaining files
Remove-Item -Path "C:\temp\*" -Force
Restart-Computer -Force -Confirm:$false