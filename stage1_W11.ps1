# Tim Welch
# BUILD SCRIPT FOR WINDOWS 10

$nextStage = "stage2.bat"
$logDir = "C:\Temp"
$dir = "C:\temp"
$url = "https://raw.githubusercontent.com/itcentrenz/win10debloat/main/$($nextStage)"
$download_path = "$($dir)\$($nextStage)"
$Exist = (Test-Path -Path $dir)
If (-not $Exist ) {
    New-Item -Path $dir -ItemType directory
}
Invoke-WebRequest -Uri $url -OutFile $download_path -UseBasicParsing
Get-Item $download_path | Unblock-File

# Set up logging
$logFile = "Focus_W11_Setup.log"
$logFullPath = "$($logDir)\$($logFile)"

Function Write-Log {
    Param (
        [string]$LogString
    )
    Add-Content -Path $logFullPath -Value $LogString
}



# Disable UAC prompts for Administrator
REG ADD "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v FilterAdministratorToken /t REG_DWORD /d 0 /f

# Removed the Rename operation for Windows 11, as it now prompts anyway
# Write-Host "Renaming Computer"
# Write-Host "Current computer name is: $env:COMPUTERNAME"
# $NewComputerName = Read-Host "Enter new computer name, or just hit [Enter] to rename to serial number"
# If ("" -eq $NewComputerName){
#    $NewComputerName = Get-CimInstance -ClassName Win32_BIOS -Property SerialNumber | Select-Object -ExpandProperty SerialNumber
# } 
# add-content -Path "$($dir)\computername.txt" $NewComputerName
# Write-Host "New computername after OOBE will be: $NewComputerName"

$InstallITCTools = Read-Host "Would you like IT Centre Tools installed (Anydesk & N-Able RMM)? Y\[N]"
If ("y" -eq $InstallITCTools.ToLower()){
  #Run IT Centre Tools installation
  New-Item -Path "c:\" -Name "IT Centre" -ItemType "directory"
  $dir = "c:\IT Centre"
  $filename = "AGENT.exe"
  $download_path = "$($dir)\$($filename)"
  #The following will break if the URL changes - update as required
  $url = 'https://itcentre.nz/wp-content/uploads/2023/07/AGENT.exe'
  Invoke-WebRequest -Uri $url -OutFile $download_path -UseBasicParsing
  Get-Item $download_path | Unblock-File
  $filename = "IT-Centre-AnyDesk-Setup.exe"
  $download_path = "$($dir)\$($filename)"
  #The following will break if the URL changes - update as required
  $url = "https://itcentre.nz/wp-content/uploads/2023/09/IT-Centre-AnyDesk-Setup.exe"
  Invoke-WebRequest -Uri $url -OutFile $download_path -UseBasicParsing
  Get-Item $download_path | Unblock-File
  #Installation of Agents takes place after OOBE so that the machine has the correct name
  Write-Log "IT Centre tools set to install after OOBDE."
} 

#Add Windows Forms Assembly as it seems to be missing on a lot of machines
Add-Type -AssemblyName System.Windows.Forms

$nextStage = "stage2.bat"
$dir = "C:\temp"
$url = "https://raw.githubusercontent.com/itcentrenz/win10debloat/main/$($nextStage)"
$download_path = "$($dir)\$($nextStage)"
$Exist = (Test-Path -Path $dir)
If (-not $Exist ) {
    New-Item -Path $dir -ItemType directory
}
Invoke-WebRequest -Uri $url -OutFile $download_path -UseBasicParsing
Get-Item $download_path | Unblock-File
Write-Log "Stage 2 downloaded."
# Moved adding to registry to end before reboot.

#Set Language to NZ 
Write-Host "Installing English-NZ, this can take a couple of minutes."
Install-Language -Language en-nz
Set-Culture en-NZ
Set-WinSystemLocale -SystemLocale en-NZ
Set-TimeZone -Name 'New Zealand Standard Time'
Set-WinHomeLocation -GeoId 0xb7
Set-WinUserLanguageList en-NZ -Force -Confirm:$false
Write-Log "English-NZ installed."

# Prevent Edge from adding shortcuts to desktop
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "CreateDesktopShortcutDefault" /t REG_DWORD /d 0 /f /reg:64 | Out-Host

Write-Host "Disable Turn-on Automatic Setup of Network Connected Devices"
# DISABLE 'TURN ON AUTOMATIC SETUP OF NETWORK CONNECTED DEVICES' (Automatically adds printers)
New-Item -Path "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup" -Name "Private"
New-ItemProperty "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private" -Name "AutoSetup" -Value 0 -PropertyType "DWord"
Write-Host "Disabled Turn-on Automatic Setup of Network Connected Devices"
Write-Log "Disabled Turn-on Automatic Setup of Network Connected Devices."

Write-Host "Started Provisioned App Removal"
#Provisioned App Removal List and afterwards loop through the remaining...
$DefaultRemove = @(
    "Microsoft.549981C3F5F10"
    "Microsoft.BingWeather"
    "Microsoft.BingNews"
    "Microsoft.GetHelp"
    "Microsoft.Getstarted"
    "Microsoft.Microsoft3DViewer"
    "Microsoft.MicrosoftOfficeHub"
    "Microsoft.MicrosoftSolitaireCollection"
    "Microsoft.MicrosoftStickyNotes"
    "Microsoft.MixedReality.Portal"
    "Microsoft.Office.OneNote"
    "Microsoft.People"
    "Microsoft.MSPaint"
    "Microsoft.SkypeApp"
    "Microsoft.Wallet"
    "Microsoft.Whiteboard"
    "Microsoft.WindowsAlarms"
    "microsoft.windowscommunicationsapps"
    "Microsoft.WindowsFeedbackHub"
    "Microsoft.WindowsMaps"
    "Microsoft.WindowsSoundRecorder"
    "Microsoft.Xbox.TCUI"
    "Microsoft.XboxApp"
    "Microsoft.XboxGameOverlay"
    "Microsoft.XboxGamingOverlay"
    "Microsoft.XboxIdentityProvider"
    "Microsoft.XboxSpeechToTextOverlay"
    "Microsoft.YourPhone"
    "Microsoft.ZuneMusic"
    "Microsoft.ZuneVideo"
    "DropboxInc.Dropbox"
    "Microsoft.GamingApp"
    "MicrosoftTeams"
    "AD2F1837.HPJumpStart"
	"7EE7776C.LinkedInforWindows"
)

ForEach ($toremove in $DefaultRemove) {
    Get-ProvisionedAppxPackage -Online | Where-Object DisplayName -EQ $toremove | Remove-ProvisionedAppxPackage -Online -AllUsers
    Write-Host "REMOVED: $toremove" -BackgroundColor Green -ForegroundColor Black
}
Write-Host "Completed automatic removal of provisioned apps" -BackgroundColor Magenta
Write-Log "Completed automatic removal of provisioned apps."

# Copy template Start Menu (start.bin) to Default User
$url = "https://github.com/itcentrenz/win10debloat/raw/main/start.bin"
$StartBin = "C:\temp\start.bin"
$StartDest = "C:\Users\Default\AppData\Local\Packages\Microsoft.Windows.StartMenuExperienceHost_cw5n1h2txyewy\LocalState"
Invoke-WebRequest -Uri $url -OutFile $StartBin -UseBasicParsing
Get-Item $StartBin | Unblock-File
If (!(Test-Path -Path $StartDest)) {New-Item $StartDest -Force -Type Directory} 
Copy-Item $startBin -Destination $StartDest
Write-Host "Completed importing new Start Menu" -BackgroundColor Green -ForegroundColor Black
Write-Log "Completed importing new Start Menu."
#Read-Host -prompt "Enter to continue."

Write-Host "Download and install Winget" -BackgroundColor Blue
#Download and install the latest version of Winget CLI Package Manager
try {
  Get-Command "winget.exe" -ErrorAction Stop
}
catch {
  $latestRelease = Invoke-WebRequest https://github.com/microsoft/winget-cli/releases/latest -Headers @{"Accept"="application/json"} -UseBasicParsing
  $json = $latestRelease.Content | ConvertFrom-Json
  $latestVersion = $json.tag_name
  $url = "https://github.com/microsoft/winget-cli/releases/download/$latestVersion/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
  $download_path = "$env:USERPROFILE\Downloads\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
  Invoke-WebRequest -Uri $url -OutFile $download_path -UseBasicParsing
  Get-Item $download_path | Unblock-File

  #WINGET Relies on VCLibs https://docs.microsoft.com/en-us/troubleshoot/cpp/c-runtime-packages-desktop-bridge
  $VCLibsURL = "https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx"
  $VCLibs_path = "$env:USERPROFILE\Downloads\Microsoft.VCLibs.x64.14.00.Desktop.appx"
  Invoke-WebRequest -Uri $VCLibsURL -OutFile $VCLibs_path -UseBasicParsing
  Get-Item $VCLibs_path | Unblock-File
  
  #WINGET Relies on XAML 
  $UI_XAML_URL = "https://github.com/itcentrenz/win10debloat/raw/main/Microsoft.UI.Xaml.2.8.appx"
  $UI_XAML_path = "$env:USERPROFILE\Downloads\Microsoft.UI.Xaml.2.8.appx"
  Invoke-WebRequest -Uri $UI_XAML_URL -OutFile $UI_XAML_path -UseBasicParsing
  Get-Item $UI_XAML_path | Unblock-File


  Import-Module -Name Appx -Force
  Add-AppxPackage -Path $VCLibs_path -confirm:$false
  Add-AppxPackage -Path $UI_XAML_path -confirm:$false
  Add-AppxPackage -Path $download_path -confirm:$false
}

$Applications = @(
  "Google.Chrome"
  "Adobe.Acrobat.Reader.64-bit"
  "VideoLAN.VLC"
)
Write-Host "Installing Applications" -BackgroundColor Green -ForegroundColor Black
Foreach ($application in $Applications) {
  Winget install -e $application -h --accept-source-agreements --accept-package-agreements --force --log "$logDir\$application.log"
}
Write-Log "Third-party applications installed."

# Install M365
Write-Host "Installing M365" -BackgroundColor Green -ForegroundColor Black
$url = "https://github.com/itcentrenz/win10debloat/raw/main/setup.exe"
$M365Setup = "C:\temp\setup.exe"
Invoke-WebRequest -Uri $url -OutFile $M365Setup -UseBasicParsing
Get-Item $M365Setup | Unblock-File
$url = "https://github.com/itcentrenz/win10debloat/raw/main/Configuration-M365BusApps.xml"
$M365Conf = "C:\temp\Configuration-M365BusApps.xml"
Invoke-WebRequest -Uri $url -OutFile $M365Conf -UseBasicParsing
Get-Item $M365Conf | Unblock-File

Start-Process -Wait -FilePath $M365Setup -ArgumentList ("/configure " + $M365Conf)
Write-Host "M365 install complete" -BackgroundColor Green -ForegroundColor Black
Write-Log "M365 install complete."

#Ads deliver malware and lead users to install fake programs.
Write-Host "Installing UBlock Origin Extension in Google Chrome" -BackgroundColor Blue
$registryPath = "HKLM:\SOFTWARE\Policies\Google\Chrome\ExtensionSettings\cjpalhdlnbpafiamejdnhcphjbkeiagm"
$Name = "installation_mode"
$value = "normal_installed"
$PropertyType = "String"
New-Item $registryPath -Force
New-ItemProperty -Path $registryPath -Name $Name -Value $value -PropertyType $PropertyType
$Name = "update_url"
$value = "https://clients2.google.com/service/update2/crx"
$PropertyType = "String"
New-ItemProperty -Path $registryPath -Name $Name -Value $value -PropertyType $PropertyType

Write-Host "Installing UBlock Origin Extension in Microsoft Edge" -BackgroundColor Blue
$registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Edge\ExtensionSettings\odfafepnkmbhccpbejgmiehpchacaeak"
$Name = "installation_mode"
$value = "normal_installed"
$PropertyType = "String"
New-Item $registryPath -Force
New-ItemProperty -Path $registryPath -Name $Name -Value $value -PropertyType $PropertyType
$Name = "update_url"
$value = "https://edge.microsoft.com/extensionwebstorebase/v1/crx"
$PropertyType = "String"
New-ItemProperty -Path $registryPath -Name $Name -Value $value -PropertyType $PropertyType

Write-Host "Completed installation of Winget and apps" -BackgroundColor Green -ForegroundColor Black

Write-Host "Removing Desktop links" -BackgroundColor Blue
Remove-Item "C:\Users\*\Desktop\*.lnk" -Force

Write-Host "Set Windows Update to update other Microsoft Products" -BackgroundColor Blue
$ServiceManager = New-Object -ComObject "Microsoft.Update.ServiceManager"
$ServiceManager.ClientApplicationID = "Update Other Microsoft Products"
$NewService = $ServiceManager.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")

Write-Host "Checking if HP or Lenvo, then removing bloatware..." -BackgroundColor Blue
$Manufacturer = (Get-CimInstance -ClassName Win32_ComputerSystem).Manufacturer
If ($Manufacturer -eq "HP" -Or $Manufacturer -eq "Hewlett-Packard") {
  Write-Host "This is an HP and we're about to remove bloatware..." -BackgroundColor Blue
  # List of built-in apps to remove
  $UninstallPackages = @(
      "AD2F1837.HPJumpStarts"
      "AD2F1837.HPPrivacySettings"
      "AD2F1837.HPQuickDrop"
      "AD2F1837.HPWorkWell"
      "AD2F1837.myHP"
  )
  $InstalledPackages = Get-AppxPackage -AllUsers | Where-Object {($UninstallPackages -contains $_.Name)} #-or ($_.Name -match "^$HPidentifier")}
  $ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object {($UninstallPackages -contains $_.DisplayName)} #-or ($_.DisplayName -match "^$HPidentifier")}
  
  ForEach ($ProvPackage in $ProvisionedPackages) {
    Write-Host -Object "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."
    Try {
        $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
        Write-Host -Object "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
    }
    Catch {Write-Warning -Message "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]"}
  }
  ForEach ($AppxPackage in $InstalledPackages) {
    Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
    Try {
        $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
        Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
    }
    Catch {Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]"}
  }

  # $InstalledPrograms = Get-Package | Where {$UninstallPrograms -contains $_.Name}
  Get-Package | Where-Object Name -Like "HP Wolf*" | Uninstall-Package -AllVersions -Force
  Get-Package | Where-Object Name -Like "HP Client Security Manager*" | Uninstall-Package -AllVersions -Force
  Get-Package | Where-Object Name -Like "HP Security Update Service*" | Uninstall-Package -AllVersions -Force
  # "HP Connection Optimizer"

  # Remove HP Shortcuts
  Remove-Item -LiteralPath "C:\ProgramData\HP\TCO" -Force -Recurse -ErrorAction SilentlyContinue
  Remove-Item -LiteralPath "C:\Online Services" -Force -Recurse -ErrorAction SilentlyContinue
  Remove-Item -Path "C:\Users\Public\Desktop\TCO Certified.lnk" -Force -Recurse -ErrorAction SilentlyContinue

  #Remove Adobe Trial Shortcuts
  Remove-Item -LiteralPath "C:\Program Files (x86)\Online Services" -Force -Recurse -ErrorAction SilentlyContinue
  Remove-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Proefversies.lnk" -Force -Recurse -ErrorAction SilentlyContinue
  
  Write-Log "HP bloatware removed."
}
elseif ($Manufacturer -eq "LENOVO") {
  Write-Host "This is an Lenovo and we're about to remove bloatware..." -BackgroundColor Blue
  # Read-Host -Promt "Waiting for input"
  # List of built-in apps to remove
  $UninstallPackages = @(
      "4505Fortemedia.FMAPOControl"
      "E046963F.AIMeetingManager"
      "MirametrixInc.GlancebyMirametrix"
  )
  $InstalledPackages = Get-AppxPackage -AllUsers | Where-Object {($UninstallPackages -contains $_.Name)} 
  $ProvisionedPackages = Get-AppxProvisionedPackage -Online | Where-Object {($UninstallPackages -contains $_.DisplayName)} 
  ForEach ($ProvPackage in $ProvisionedPackages) {
    Write-Host -Object "Attempting to remove provisioned package: [$($ProvPackage.DisplayName)]..."
    Try {
        $Null = Remove-AppxProvisionedPackage -PackageName $ProvPackage.PackageName -Online -ErrorAction Stop
        Write-Host -Object "Successfully removed provisioned package: [$($ProvPackage.DisplayName)]"
    }
    Catch {Write-Warning -Message "Failed to remove provisioned package: [$($ProvPackage.DisplayName)]"}
  }
  ForEach ($AppxPackage in $InstalledPackages) {
    Write-Host -Object "Attempting to remove Appx package: [$($AppxPackage.Name)]..."
    Try {
        $Null = Remove-AppxPackage -Package $AppxPackage.PackageFullName -AllUsers -ErrorAction Stop
        Write-Host -Object "Successfully removed Appx package: [$($AppxPackage.Name)]"
    }
    Catch {Write-Warning -Message "Failed to remove Appx package: [$($AppxPackage.Name)]"}
  }
  #Download McAfee removal tool
  # This is from https://christianlehrer.com/?p=359 and was working but may need reinvestigating.
  $url = "https://github.com/itcentrenz/win10debloat/raw/main/KillMcAfee.zip"
  $KillMcAfee = "C:\temp\KillMcAfee.zip"
  Invoke-WebRequest -Uri $url -OutFile $KillMcAfee -UseBasicParsing
  Get-Item $KillMcAfee | Unblock-File
  Expand-Archive -Path $KillMcAfee -DestinationPath "C:\temp"
  Start-Process -Wait -FilePath "C:\temp\MCPR\Mccleanup.exe" -ArgumentList "-p StopServices,MFSY,PEF,MXD,CSP,Sustainability,MOCP,MFP,APPSTATS,Auth,EMproxy,FWdiver,HW,MAS,MAT,MBK,MCPR,McProxy,McSvcHost,VUL,MHN,MNA,MOBK,MPFP,MPFPCU,MPS,SHRED,MPSCU,MQC,MQCCU,MSAD,MSHR,MSK,MSKCU,MWL,NMC,RedirSvc,VS,REMEDIATION,MSC,YAP,TRUEKEY,LAM,PCB,Symlink,SafeConnect,MGS,WMIRemover,RESIDUE -v -s" -WindowStyle Minimized
  # Read-Host -Prompt "At this point we should have silently remove McAfee etc"
  Write-Log "Lenovo bloatware removed."
}
else {
  Write-Host "This host is not an HP or a Lenovo" -BackgroundColor Magenta
  Write-Host "Watch out for a Windows Message being under this Window about now..."
  $continue = [System.Windows.Forms.MessageBox]::Show("Do you want to continue through remaining Provisioned Applications?","Batch Windows 10 App Removal", "YesNo" , "Information" , "Button1")
  # Write-Host "Do you want to continue through remaining AppX Packages? [y]es or [n]o"
  # $continue = $Host.UI.RawUI.ReadKey()
  Switch ($continue) {
      'Yes' {
          # Now retrieve remaining Provisioned Packages...
          $ProvisionedFiles = @(Get-ProvisionedAppxPackage -Online | Select-Object DisplayName)
  
          ForEach ($files in $ProvisionedFiles) {
              $msg   = "Remove " + $files.DisplayName + "?"
              $remove = [System.Windows.Forms.MessageBox]::Show($msg,"Batch Windows 10 App Removal", "YesNo" , "Information" , "Button1")
              switch  ($remove) {
                'Yes' {
                  Get-ProvisionedAppxPackage -Online | Where-Object DisplayName -EQ $files.DisplayName | Remove-ProvisionedAppxPackage -Online -AllUsers | Out-Null
                  Write-Host "REMOVED: $files.DisplayName" -BackgroundColor Red
                    }
                'No' {
                  Write-Host "Kept: $files.DisplayName" -BackgroundColor Green
                    }
              }
          }
          Write-Host "Completed stepping through the rest of the provisoned apps"
      }
      'No' {
      }
  
  }
}

# Customize the Taskbar and Desktop icons for the Default User
REG LOAD HKLM\Default C:\Users\Default\NTUSER.DAT
 
# Removes Widgets from the Taskbar
REG ADD "HKLM\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f
 
# Removes Chat from the Taskbar
REG ADD "HKLM\Default\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarMn /t REG_DWORD /d 0 /f
 
# Set Search in Taskbar to icon only
REG ADD "HKLM\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v SearchboxTaskbarMode /t REG_DWORD /d 1 /f

# Turn on My Computer on the Desktop
REG ADD "HKLM\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{20D04FE0-3AEA-1069-A2D8-08002B30309D}" /t REG_DWORD /d 0 /f

# Turn on User's Files on the Desktop
REG ADD "HKLM\Default\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{59031a47-3f72-44a7-89c5-5595fe6b30ee}" /t REG_DWORD /d 0 /f

REG UNLOAD HKLM\Default
#Read-Host -prompt "Customized Taskbar and Desktop reg values"

# Remove Microsoft News and Interests from Taskbar
Write-Host "Remove News and Interests"
$registryPath = "HKLM:SOFTWARE\Policies\Microsoft\Windows\Windows Feeds"
$Name = "EnableFeeds"
$value = "0"
new-item 'HKLM:SOFTWARE\Policies\Microsoft\Windows' -Name 'Windows Feeds'
$TaskBar = Get-Item -Path $registryPath -ErrorAction SilentlyContinue
If($null -eq $TaskBar.GetValue($Name)) {
   New-ItemProperty -Path $registryPath -Name $Name -Value $value -PropertyType DWord
} else {
   Set-ItemProperty -Path $registryPath -Name $Name -Value $value
}

Write-Host "Removing Meet Now from Taskbar"
$registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
$Name = "HideSCAMeetNow"
$value = "1"
$Exist = Get-ItemProperty -Path $registryPath -Name $Name -ErrorAction SilentlyContinue
if ($Exist) {
    Set-ItemProperty -Path $registryPath -Name $Name -Value $value
} Else {
    New-ItemProperty -Path $registryPath -Name $Name -Value $value -PropertyType DWord
}
Write-Host "Removed Meet Now from Taskbar" -BackgroundColor Green -ForegroundColor Black

Write-Log "Taskbar configured."


Clear-Host 
Write-Host "Running Windows Updates" -BackgroundColor Blue
Set-ExecutionPolicy Bypass -Force -Confirm:$false
Install-PackageProvider -Name NuGet -Force
Write-Host "Installed NuGet" -BackgroundColor Green -ForegroundColor Black
Install-Module PSWindowsUpdate -Confirm:$false -Force
Write-Host "Installed PSWindowsUpdate" -BackgroundColor Green -ForegroundColor Black
Write-Host "Running Get-WindowsUpdate" -BackgroundColor Magenta
Get-WindowsUpdate -Hide -Title "Silverlight"
Get-WindowsUpdate -install -acceptall -IgnoreReboot -Confirm:$false -Verbose -NotTitle "Silverlight"

Write-Log "Microsoft Update (first run) complete."

# Add 2rd stage to RunOnce Registry Key
$value = "$($dir)\$($nextStage)"
$name = "!$($nextStage)"
New-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion" -Name "RunOnce" -Force
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name $name -Value $value -Force

Write-Log "Stage 1 complete, rebooting."

Restart-Computer -Force -Confirm:$false