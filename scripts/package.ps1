$ErrorActionPreference = "Stop"

. a:\Test-Command.ps1

Enable-RemoteDesktop
netsh advfirewall firewall add rule name="Remote Desktop" dir=in localport=3389 protocol=TCP action=allow

Update-ExecutionPolicy -Policy Unrestricted

if (Test-Command -cmdname 'Uninstall-WindowsFeature') {
    Write-BoxstarterMessage "Removing unused features..."
    Remove-WindowsFeature -Name 'Powershell-ISE'
    Get-WindowsFeature | 
    ? { $_.InstallState -eq 'Available' } | 
    Uninstall-WindowsFeature -Remove
}

$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-ItemProperty -path $regKey AutoConfigURL -Value 'http://dellwebfarm.us.dell.com/DRAGNet/PAC/PAC-Global-Vista.asp'

[byte[]]$defConSet='70,0,0,0,4,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,63,0,0,0,104,116,116,112,58,47,47,100,101,108,108,119,101,98,102,97,114,109,46,117,115,46,100,101,108,108,46,99,111,109,47,68,82,65,71,78,101,116,47,80,65,67,47,80,65,67,45,71,108,111,98,97,108,45,86,105,115,116,97,46,97,115,112,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0' -split ','
$regKeyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\"
Set-ItemProperty -Path $regKeyPath -Name DefaultConnectionSettings -Value $defConSet

# $flagIndex = 8
# $autoProxyFlag = 8
# $conSet = $(Get-ItemProperty $regKeyPath).DefaultConnectionSettings
# if ($($conSet[$flagIndex] -band $autoProxyFlag) -eq $autoProxyFlag)
# {
#     Write-Host "Disabling 'Automatically detect proxy settings'."
#     $mask = -bnot $autoProxyFlag
#     $conSet[$flagIndex] = $conSet[$flagIndex] -band $mask
#     $conSet[4]++
#     Set-ItemProperty -Path $regKeyPath -Name DefaultConnectionSettings -Value $conSet
# }
# $conSet = $(Get-ItemProperty $regKeyPath).DefaultConnectionSettings
# if ($($conSet[$flagIndex] -band $autoProxyFlag) -ne $autoProxyFlag)
# {
#     Write-Host "'Automatically detect proxy settings' is disabled."
# }

$password = ConvertTo-SecureString 'Readonly@123' -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential('ServiceDCSGReadonly',$password)
[System.Net.WebRequest]::DefaultWebProxy.Credentials = $credential

# Install-WindowsUpdate -AcceptEula

Write-BoxstarterMessage "Removing page file"
$pageFileMemoryKey = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
Set-ItemProperty -Path $pageFileMemoryKey -Name PagingFiles -Value ""

if(Test-PendingReboot){ Invoke-Reboot }

Write-BoxstarterMessage "Setting up winrm"
netsh advfirewall firewall add rule name="WinRM-HTTP" dir=in localport=5985 protocol=TCP action=allow

$enableArgs=@{Force=$true}
try {
 $command=Get-Command Enable-PSRemoting
  if($command.Parameters.Keys -contains "skipnetworkprofilecheck"){
      $enableArgs.skipnetworkprofilecheck=$true
  }
}
catch {
  $global:error.RemoveAt(0)
}
Enable-PSRemoting @enableArgs
Enable-WSManCredSSP -Force -Role Server
winrm set winrm/config/client/auth '@{Basic="true"}'
winrm set winrm/config/service/auth '@{Basic="true"}'
winrm set winrm/config/service '@{AllowUnencrypted="true"}'
Write-BoxstarterMessage "winrm setup complete"