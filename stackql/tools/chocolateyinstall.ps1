$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url64 = 'https://releases.stackql.io/stackql/latest/stackql_windows_amd64.msi'

$packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    unzipLocation  = $toolsDir
    fileType       = 'MSI'
    url64bit       = $url64
    softwareName   = 'stackql*'
    checksum64     = '22e7b46790ee73abf375923819c36fc0abe5886f049c4ac1f03961d28243e2aa'
    checksumType64 = 'sha256'
    silentArgs     = "/passive /l* stackql.log"
    validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs

