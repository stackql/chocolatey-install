$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$urlAmd64 = 'https://releases.stackql.io/stackql/0.12.732/stackql_windows_amd64.msi'
$checksumAmd64 = '75c25e552f378456c6a4c74b705c0a96cc1d67c3a56ecd0017cbdda7cc1c0c2f'
# Populated by publish-prep.ps1 for the first ARM64 release.
$urlArm64 = ''
$checksumArm64 = ''

if (-not [Environment]::Is64BitOperatingSystem) {
    throw 'StackQL requires AMD64 or ARM64 Windows.'
}

# Query the platform architecture even when PowerShell runs under emulation.
$architecture = Get-CimInstance -ClassName Win32_Processor -Property Architecture |
    Select-Object -First 1 -ExpandProperty Architecture
switch ($architecture) {
    9  { $url = $urlAmd64; $checksum = $checksumAmd64 }
    12 { $url = $urlArm64; $checksum = $checksumArm64 }
    default { throw "Unsupported processor architecture: $architecture" }
}
if (-not $url -or $checksum -notmatch '^[a-fA-F0-9]{64}$') {
    throw 'This package has not been prepared for this architecture. Run publish-prep.ps1 before publishing.'
}

$packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    unzipLocation  = $toolsDir
    fileType       = 'MSI'
    url            = $url
    softwareName   = 'stackql*'
    checksum       = $checksum
    checksumType   = 'sha256'
    silentArgs     = "/passive /l* stackql.log"
    validExitCodes = @(0, 3010, 1641)
}

Install-ChocolateyPackage @packageArgs
