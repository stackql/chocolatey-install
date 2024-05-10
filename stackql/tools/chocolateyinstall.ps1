$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url64 = 'https://releases.stackql.io/stackql/latest/stackql_windows_amd64.msi'

$packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    unzipLocation  = $toolsDir
    fileType       = 'MSI'
    url64bit       = $url64
    softwareName   = 'stackql*'
    checksum64     = 'acf5e270f9c20c5897ad997528ef474714348e7f8f7ba1002481b68ed2416ee5'
    checksumType64 = 'sha256'
    silentArgs     = "/passive /l* stackql.log"
    validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs







