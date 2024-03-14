$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url64 = 'https://releases.stackql.io/stackql/latest/stackql_windows_amd64.msi'

$packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    unzipLocation  = $toolsDir
    fileType       = 'MSI'
    url64bit       = $url64
    softwareName   = 'stackql*'
    checksum64     = '11106f87a19ff9f663ac152fa56d339be4b3d9ed07fead3ebb9245faf768bd7d'
    checksumType64 = 'sha256'
    silentArgs     = "/passive /l* stackql.log"
    validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs




