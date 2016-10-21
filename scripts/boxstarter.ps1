$WinlogonPath = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon"
Remove-ItemProperty -Path $WinlogonPath -Name AutoAdminLogon
Remove-ItemProperty -Path $WinlogonPath -Name DefaultUserName

$regKey="HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings"
Set-ItemProperty -path $regKey AutoConfigURL -Value 'http://dellwebfarm.us.dell.com/DRAGNet/PAC/PAC-Global-Vista.asp'

[byte[]]$defConSet='70,0,0,0,4,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,63,0,0,0,104,116,116,112,58,47,47,100,101,108,108,119,101,98,102,97,114,109,46,117,115,46,100,101,108,108,46,99,111,109,47,68,82,65,71,78,101,116,47,80,65,67,47,80,65,67,45,71,108,111,98,97,108,45,86,105,115,116,97,46,97,115,112,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0' -split ','
$regKeyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\"
Set-ItemProperty -Path $regKeyPath -Name DefaultConnectionSettings -Value $defConSet

$password = ConvertTo-SecureString 'Readonly@123' -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential('ServiceDCSGReadonly',$password)
[System.Net.WebRequest]::DefaultWebProxy.Credentials = $credential

$env:chocolateyProxyLocation='http://proxy:80'
$env:chocolateyProxyUser='ServiceDCSGReadonly'
$env:chocolateyProxyPassword='Readonly@123'
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))

choco config set proxy http://proxy:80
choco config set proxyUser ServiceDCSGReadonly
choco config set proxyPassword Readonly@123

iex ((new-object net.webclient).DownloadString('https://raw.githubusercontent.com/mwrock/boxstarter/master/BuildScripts/bootstrapper.ps1'))
Get-Boxstarter -Force

$secpasswd = ConvertTo-SecureString "vagrant" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("vagrant", $secpasswd)

Import-Module $env:appdata\boxstarter\boxstarter.chocolatey\boxstarter.chocolatey.psd1
Install-BoxstarterPackage -PackageName a:\package.ps1 -Credential $cred
