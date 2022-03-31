# Tim Welch
# BUILD SCRIPT FOR WINDOWS 10

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

#Set Language to NZ 
Set-Culture en-NZ
Set-WinSystemLocale -SystemLocale en-NZ
Set-TimeZone -Name 'New Zealand Standard Time'
Set-WinHomeLocation -GeoId 0xb7
Set-WinUserLanguageList en-NZ -Force -Confirm:$false

#Rename Computer - Update 03/11/21 There is no point in doing this as it gets rewritten during OOBE - so we write it to a file and then rename as part of OOBE
Write-Host "Renaming Computer"
Write-Host "Current computer name is: $env:COMPUTERNAME"
$NewComputerName = Read-Host "Enter new computer name, or just hit [Enter] to rename to serial number"
If ("" -eq $NewComputerName){
    $NewComputerName = Get-CimInstance -ClassName Win32_BIOS -Property SerialNumber | Select-Object -ExpandProperty SerialNumber
} 
add-content -Path "$($dir)\computername.txt" $NewComputerName
Write-Host "New computername after OOBE will be: $NewComputerName"

$InstallITCTools = Read-Host "Would you like IT Centre Tools installed? Y\[N]"
If ("y" -eq $InstallITCTools.ToLower()){
  #Run IT Centre Tools installation
  New-Item -Path "c:\" -Name "IT Centre" -ItemType "directory"
  $Path = "\\172.20.20.2\Temp"
  $Destination = "C:\IT Centre"
  $AnyDesk = "\AnyDesk\IT Centre AnyDesk Setup.exe"
  $SolarWinds = "\N-Able\AGENT.EXE"
  
  Copy-Item -Path $Path$AnyDesk -Destination $Destination -Force
  Copy-Item -Path $Path$SolarWinds -Destination $Destination -Force
  #Installation of Agents takes place after OOBE so that the machine has the correct name
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
# Moved adding to registry to end before reboot.

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

# Prevent Edge from adding shortcuts to desktop
reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "CreateDesktopShortcutDefault" /t REG_DWORD /d 0 /f /reg:64 | Out-Host

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

Write-Host "Disable Turn-on Automatic Setup of Network Connected Devices"
# DISABLE 'TURN ON AUTOMATIC SETUP OF NETWORK CONNECTED DEVICES' (Automatically adds printers)
New-Item -Path "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup" -Name "Private"
New-ItemProperty "hklm:\SOFTWARE\Microsoft\Windows\CurrentVersion\NcdAutoSetup\Private" -Name "AutoSetup" -Value 0 -PropertyType "DWord"
Write-Host "Disabled Turn-on Automatic Setup of Network Connected Devices"

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
)

ForEach ($toremove in $DefaultRemove) {
    Get-ProvisionedAppxPackage -Online | Where-Object DisplayName -EQ $toremove | Remove-ProvisionedAppxPackage -Online -AllUsers | Out-Null
    Write-Host "REMOVED: $toremove" -BackgroundColor Green -ForegroundColor Black
}
Write-Host "Completed automatic removal of provisioned apps" -BackgroundColor Magenta

#Remove Paint 3D edit from Explorer Context
$AppExtensions = @(
    ".bmp"
    ".gif"
    ".jpeg"
    ".jpg"
    ".jpe"
    ".png"
    ".tiff"
    ".tif"
)
ForEach ($AppExtension in $AppExtensions) {
  Remove-Item -Path "HKLM:\SOFTWARE\Classes\SystemFileAssociations\$AppExtension\Shell\3D Edit" -Recurse
}
Write-Host "Removed Paint3D from Explorer Context" -BackgroundColor Green -ForegroundColor Black

$StartLayoutStr = @"
<LayoutModificationTemplate xmlns:defaultlayout="http://schemas.microsoft.com/Start/2014/FullDefaultLayout" xmlns:start="http://schemas.microsoft.com/Start/2014/StartLayout" Version="1" xmlns="http://schemas.microsoft.com/Start/2014/LayoutModification">
  <LayoutOptions StartTileGroupCellWidth="6" />
  <DefaultLayoutOverride>
    <StartLayoutCollection>
      <defaultlayout:StartLayout GroupCellWidth="6">
        <start:Group Name="Internet">
          <start:DesktopApplicationTile Size="2x2" Column="2" Row="0" DesktopApplicationID="MSEdge" />
          <start:DesktopApplicationTile Size="2x2" Column="0" Row="0" DesktopApplicationID="Chrome" />
        </start:Group>
      </defaultlayout:StartLayout>
    </StartLayoutCollection>
  </DefaultLayoutOverride>
</LayoutModificationTemplate>
"@

# This changes the default user start menu and the currently logged in user
add-content $Env:TEMP\startlayout.xml $StartLayoutStr
import-startlayout -layoutpath $Env:TEMP\startlayout.xml -mountpath $Env:SYSTEMDRIVE\
New-Item -Path HKCU:\SOFTWARE\Policies\Microsoft\Windows -Name Explorer -ErrorAction SilentlyContinue
Reg Add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /V LockedStartLayout /T REG_DWORD /D 1 /F
Reg Add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /V StartLayoutFile /T REG_EXPAND_SZ /D '$Env:TEMP\startlayout.xml' /F
Stop-Process -ProcessName explorer
Start-Sleep -s 10
#sleep is to let explorer finish restart b4 deleting reg keys
Remove-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "LockedStartLayout" -Force
Remove-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "StartLayoutFile" -Force
Stop-Process -ProcessName explorer
remove-item $Env:TEMP\startlayout.xml -ErrorAction SilentlyContinue -Force
Write-Host "Completed importing new Start Menu" -BackgroundColor Green -ForegroundColor Black

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

  Import-Module -Name Appx -Force
  Add-AppxPackage -Path $VCLibs_path -confirm:$false
  Add-AppxPackage -Path $download_path -confirm:$false
}

$Applications = @(
  "Google.Chrome"
  "Adobe.Acrobat.Reader.32-bit"
  "VideoLAN.VLC"
)
Write-Host "Installing Applications" -BackgroundColor Green -ForegroundColor Black
Foreach ($application in $Applications) {
  Winget install -e $application -h --accept-source-agreements --accept-package-agreements --force
}

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

Write-Host "Checking if HP and remove bloatware..." -BackgroundColor Blue
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
}
elseif ($Manufacturer -eq "LENOVO") {
  Write-Host "This is an Lenovo and we're about to remove bloatware..." -BackgroundColor Blue
  Read-Host -Promt "Waiting for input"
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
  Start-Process -Wait -FilePath “C:\temp\MCPR\Mccleanup.exe” -ArgumentList “-p StopServices,MFSY,PEF,MXD,CSP,Sustainability,MOCP,MFP,APPSTATS,Auth,EMproxy,FWdiver,HW,MAS,MAT,MBK,MCPR,McProxy,McSvcHost,VUL,MHN,MNA,MOBK,MPFP,MPFPCU,MPS,SHRED,MPSCU,MQC,MQCCU,MSAD,MSHR,MSK,MSKCU,MWL,NMC,RedirSvc,VS,REMEDIATION,MSC,YAP,TRUEKEY,LAM,PCB,Symlink,SafeConnect,MGS,WMIRemover,RESIDUE -v -s” -WindowStyle Minimized
  Read-Host -Promt "At this point we should have silently remove McAfee etc"
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


# Add 2rd stage to RunOnce Registry Key
$value = "$($dir)\$($nextStage)"
$name = "!$($nextStage)"
New-Item "HKCU:\Software\Microsoft\Windows\CurrentVersion" -Name "RunOnce" -Force
Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce" -Name $name -Value $value -Force
Restart-Computer -Force -Confirm:$false