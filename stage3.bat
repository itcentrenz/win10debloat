@powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$_=((Get-Content \"%~f0\") -join \"`n\");iex $_.Substring($_.IndexOf(\"goto :\"+\"EOF\")+9)"
@goto :EOF

# Kill Sysprep before trying to run it again...
Stop-Process -name Sysprep -Force

# Enable UAC prompts for Administrator
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v FilterAdministratorToken /t REG_DWORD /d 1 /f

$path = $Env:windir + '\system32\oobe\info\'
If (-not(Test-Path -Path $path -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $path -ErrorAction Continue
}
$oobexmlStr = @"
<FirstExperience>
  <oobe>
    <defaults>
      <language>1033</language>
      <location>183</location>
      <keyboard>1409:00000409</keyboard>
      <timezone>New Zealand Standard Time</timezone>
      <adjustForDST>true</adjustForDST>
    </defaults>
  </oobe>
</FirstExperience>
"@
add-content $path\oobe.xml $oobexmlStr

# Run Script after OOBE to clean up
$ScriptPath = $Env:windir + '\Panther\'
If (-not(Test-Path -Path $ScriptPath -PathType Container)) {
    $null = New-Item -ItemType Directory -Path $ScriptPath -ErrorAction Continue
}
# Source file location
$source = 'https://raw.githubusercontent.com/itcentrenz/win10debloat/main/afteroobe.ps1'
# Destination to save the file
$destination = $ScriptPath + 'afteroobe.ps1'
#Download the file
Invoke-WebRequest -Uri $source -OutFile $destination
Unblock-File -Path $destination

$source = 'https://raw.githubusercontent.com/itcentrenz/win10debloat/main/unattend.xml'
$ScriptPath = $Env:windir + '\Panther\'
$UnattendXML = $ScriptPath + 'unattend.xml'
Invoke-WebRequest -Uri $source -OutFile $UnattendXML

$SysPrep = $Env:windir + '\System32\Sysprep\sysprep.exe'
# Write a cmd file and run it for Sysprep?
$SysPrepCMD = @"
$SysPrep /quiet /oobe /reboot /unattend:$UnattendXML
"@
add-content $ScriptPath\runsysprep.cmd $SysPrepCMD

$Exist = (Test-Path -Path $UnattendXML) -and (Test-Path -Path $ScriptPath\runsysprep.cmd)
If ($Exist) {
    # & $SysPrep $cmdArgList
    Invoke-Item $ScriptPath\runsysprep.cmd
}
