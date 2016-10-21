$WinlogonPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
Remove-ItemProperty -Path $WinlogonPath -Name AutoAdminLogon
Remove-ItemProperty -Path $WinlogonPath -Name DefaultUserName

$password = ConvertTo-SecureString 'Readonly@123' -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential('ServiceDCSGReadonly',$password)
[System.Net.WebRequest]::DefaultWebProxy.Credentials = $credential

. a:\bootstrapper.ps1
Get-Boxstarter -Force

$secpasswd = ConvertTo-SecureString "vagrant" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("vagrant", $secpasswd)

Import-Module $env:appdata\boxstarter\boxstarter.chocolatey\boxstarter.chocolatey.psd1
Install-BoxstarterPackage -PackageName a:\package.ps1 -Credential $cred
