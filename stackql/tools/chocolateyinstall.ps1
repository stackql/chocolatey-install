$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$url64 = 'https://releases.stackql.io/stackql/latest/stackql_windows_amd64.msi'

# Download the file temporarily to calculate checksum
$tempFile = Join-Path $env:TEMP 'stackql.msi'
Invoke-WebRequest -Uri $url64 -OutFile $tempFile

# Calculate checksum
$checksum64 = (certutil -hashfile $tempFile SHA256)[1] -replace " ", ""
Remove-Item $tempFile -Force

$packageArgs = @{
    packageName   = $env:ChocolateyPackageName
    unzipLocation = $toolsDir
    fileType      = 'MSI'
    url64bit      = $url64
    softwareName  = 'stackql*'
    checksum64    = $checksum64.Hash
    checksumType64= 'sha256'
    silentArgs    = "/passive /l* stackql.log"
    validExitCodes= @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs