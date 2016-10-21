$ErrorActionPreference = "Stop"
. a:\Test-Command.ps1

Write-Host "Enabling file sharing firewall rules"
netsh advfirewall firewall set rule group="File and Printer Sharing" new enable=yes

[byte[]]$defConSet='70,0,0,0,4,0,0,0,5,0,0,0,0,0,0,0,0,0,0,0,63,0,0,0,104,116,116,112,58,47,47,100,101,108,108,119,101,98,102,97,114,109,46,117,115,46,100,101,108,108,46,99,111,109,47,68,82,65,71,78,101,116,47,80,65,67,47,80,65,67,45,71,108,111,98,97,108,45,86,105,115,116,97,46,97,115,112,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0' -split ','
$regKeyPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections\"
Set-ItemProperty -Path $regKeyPath -Name DefaultConnectionSettings -Value $defConSet

$password = ConvertTo-SecureString 'Readonly@123' -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential('ServiceDCSGReadonly',$password)
[System.Net.WebRequest]::DefaultWebProxy.Credentials = $credential

choco config set proxy http://proxy:80
choco config set proxyUser ServiceDCSGReadonly
choco config set proxyPassword Readonly@123

if(Test-Path "C:\Users\vagrant\VBoxGuestAdditions.iso") {
    Write-Host "Installing Guest Additions"
    certutil -addstore -f "TrustedPublisher" A:\oracle.cer
    cinst 7zip.commandline -y
    Move-Item C:\Users\vagrant\VBoxGuestAdditions.iso C:\Windows\Temp
    ."C:\ProgramData\chocolatey\lib\7zip.commandline\tools\7z.exe" x C:\Windows\Temp\VBoxGuestAdditions.iso -oC:\Windows\Temp\virtualbox

    Start-Process -FilePath "C:\Windows\Temp\virtualbox\VBoxWindowsAdditions.exe" -ArgumentList "/S" -WorkingDirectory "C:\Windows\Temp\virtualbox" -Wait

    Remove-Item C:\Windows\Temp\virtualbox -Recurse -Force
    Remove-Item C:\Windows\Temp\VBoxGuestAdditions.iso -Force
}

Write-Host "Cleaning SxS..."
Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase

@(
    "$env:localappdata\Nuget",
    "$env:localappdata\temp\*",
    "$env:windir\logs",
    "$env:windir\panther",
    "$env:windir\temp\*",
    "$env:windir\winsxs\manifestcache"
) | % {
        if(Test-Path $_) {
            Write-Host "Removing $_"
            try {
              Takeown /d Y /R /f $_
              Icacls $_ /GRANT:r administrators:F /T /c /q  2>&1 | Out-Null
              Remove-Item $_ -Recurse -Force | Out-Null 
            } catch { $global:error.RemoveAt(0) }
        }
    }

Write-Host "defragging..."
if (Test-Command -cmdname 'Optimize-Volume') {
    Optimize-Volume -DriveLetter C
    } else {
    Defrag.exe c: /H
}

Write-Host "0ing out empty space..."
$FilePath="c:\zero.tmp"
$Volume = Get-WmiObject win32_logicaldisk -filter "DeviceID='C:'"
$ArraySize= 64kb
$SpaceToLeave= $Volume.Size * 0.05
$FileSize= $Volume.FreeSpace - $SpacetoLeave
$ZeroArray= new-object byte[]($ArraySize)
 
$Stream= [io.File]::OpenWrite($FilePath)
try {
   $CurFileSize = 0
    while($CurFileSize -lt $FileSize) {
        $Stream.Write($ZeroArray,0, $ZeroArray.Length)
        $CurFileSize +=$ZeroArray.Length
    }
}
finally {
    if($Stream) {
        $Stream.Close()
    }
}
 
Del $FilePath

Write-Host "copying auto unattend file"
mkdir C:\Windows\setup\scripts
copy-item a:\SetupComplete-2012.cmd C:\Windows\setup\scripts\SetupComplete.cmd -Force

mkdir C:\Windows\Panther\Unattend
copy-item a:\postunattend.xml C:\Windows\Panther\Unattend\unattend.xml

Write-Host "Recreate pagefile after sysprep"
$System = GWMI Win32_ComputerSystem -EnableAllPrivileges
if ($system -ne $null) {
  $System.AutomaticManagedPagefile = $true
  $System.Put()
}
