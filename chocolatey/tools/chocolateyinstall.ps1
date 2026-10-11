$ErrorActionPreference = 'Stop';
$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
$urlAmd64 = 'https://releases.stackql.io/stackql/0.12.778/stackql_windows_amd64.msi'
$checksumAmd64 = '43ef01623569921a043f4d39c702f89e99ae1ebc6eede84a708621b1c35d8a10'
# Populated by publish-prep.ps1 for the first ARM64 release.
$urlArm64 = 'https://releases.stackql.io/stackql/0.12.778/stackql_windows_arm64.msi'
$checksumArm64 = 'c1ca5c4ddfa18c39aa1fd44b39a71da9cec9d01539e59b63d4998f56ef714a7a'

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
