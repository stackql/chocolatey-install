$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url64 = 'https://releases.stackql.io/stackql/latest/stackql_windows_amd64.msi'

$packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    unzipLocation  = $toolsDir
    fileType       = 'MSI'
    url64bit       = $url64
    softwareName   = 'stackql*'
    checksum64     = '6133524b68efc2619e99ca7a420ba65013c661b9d183678d79bbe181edbfc6ff'
    checksumType64 = 'sha256'
    silentArgs     = "/passive /l* stackql.log"
    validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs























