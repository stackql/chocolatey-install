# .\build.ps1 true

#
# NOTES:
# 1. File versioning will not work if the directory for this repo is a Dropbox, OneDrive dir etc
# 2. McAfee AV must be temporarily disabled for version stamping
#

$ErrorActionPreference = 'Stop'
$sign = $args[0] -eq 'true'
$architectures = @('amd64', 'arm64')

$Product = "StackQL - Query and Provision Cloud Services using SQL."
$FileDescription = "StackQL Executable"
$IconPath = ".\inc\stackql.ico"
$LegalCopyright = "Copyright (c) 2020-2025 StackQL Studios. All rights reserved."

function Write-Banner([string]$Message) {
    Write-Output "*******************************************************************************"
    Write-Output $Message
    Write-Output "*******************************************************************************"
}

foreach ($architecture in $architectures) {
    $inputPath = ".\downloaded\stackql_windows_${architecture}.zip"
    if (-not (Test-Path -LiteralPath $inputPath -PathType Leaf)) {
        throw "Not found: $inputPath"
    }
}

if ($sign) {
    Write-Output "Binaries and packages will be signed. Ensure smart token is installed before pressing enter..."
    pause
}

Write-Banner "Clearing msi and bin directories"
foreach ($directory in @('msi', 'bin')) {
    if (Test-Path -LiteralPath ".\$directory") {
        Get-ChildItem -LiteralPath ".\$directory" -Force | Remove-Item -Force -Recurse
    } else {
        New-Item -ItemType Directory -Path ".\$directory" | Out-Null
    }
}

foreach ($architecture in $architectures) {
    Write-Banner "Extracting $architecture build"
    $exePath = ".\bin\$architecture\stackql.exe"
    Expand-Archive -Path ".\downloaded\stackql_windows_${architecture}.zip" -DestinationPath ".\bin\$architecture"
    if (-not (Test-Path -LiteralPath $exePath -PathType Leaf)) {
        throw "stackql.exe not found in the $architecture archive"
    }

    $reader = New-Object System.IO.BinaryReader([System.IO.File]::OpenRead((Resolve-Path $exePath).Path))
    try {
        $reader.BaseStream.Position = 0x3c
        $reader.BaseStream.Position = $reader.ReadInt32()
        if ($reader.ReadUInt32() -ne 0x00004550) {
            throw "Invalid PE header in $exePath"
        }
        $machine = $reader.ReadUInt16()
        $expectedMachine = if ($architecture -eq 'amd64') { 0x8664 } else { 0xaa64 }
        if ($machine -ne $expectedMachine) {
            throw "Unexpected processor architecture in $exePath"
        }
    } finally {
        $reader.Dispose()
    }
}

# Read the shared version from a copy so resource editing never touches a just-run EXE.
Write-Banner "Reading shared StackQL version"
Copy-Item -LiteralPath .\bin\amd64\stackql.exe -Destination .\bin\stackql-version.exe
$VersionOutput = & .\bin\stackql-version.exe --version
if ($LASTEXITCODE -ne 0) { throw "Reading StackQL version failed (exit $LASTEXITCODE)" }
Write-Output $VersionOutput
if (($VersionOutput | Out-String) -notmatch '\bv(\d+\.\d+\.\d+)\b') {
    throw "Could not read the StackQL version"
}
$Version = $Matches[1]
$env:StackQLBuildVersion = $Version

foreach ($architecture in $architectures) {
    $exePath = ".\bin\$architecture\stackql.exe"

    Write-Banner "Versioning $architecture EXE: $Version"
    .\lib\rcedit-x86.exe $exePath `
        --set-product-version $Version `
        --set-file-version $Version `
        --set-version-string "ProductName" $Product `
        --set-version-string "FileDescription" $FileDescription `
        --set-version-string "LegalCopyright" $LegalCopyright `
        --set-icon $IconPath
    if ($LASTEXITCODE -ne 0) { throw "Versioning $architecture EXE failed (exit $LASTEXITCODE)" }
}

if ($sign) {
    foreach ($architecture in $architectures) {
        $exePath = ".\bin\$architecture\stackql.exe"
        Write-Banner "Signing $architecture EXE"
        .\lib\signtool sign /tr http://timestamp.comodoca.com /td sha256 /fd sha256 /n StackQL $exePath
        if ($LASTEXITCODE -ne 0) { throw "Signing $architecture EXE failed (exit $LASTEXITCODE)" }
    }
}

foreach ($architecture in $architectures) {
    $exePath = ".\bin\$architecture\stackql.exe"
    $msiPath = ".\msi\stackql_${Version}_windows_${architecture}.msi"
    $zipPath = ".\msi\stackql_${Version}_windows_${architecture}.zip"
    $wixArchitecture = if ($architecture -eq 'amd64') { 'x64' } else { 'arm64' }

    Write-Banner "Building $architecture MSI"
    wix.exe build .\stackql.wxs -arch $wixArchitecture -d "BinaryPath=$exePath" -ext WixToolset.UI.wixext -o $msiPath
    if ($LASTEXITCODE -ne 0) { throw "Building $architecture MSI failed (exit $LASTEXITCODE)" }

    if ($sign) {
        Write-Banner "Signing $architecture MSI"
        .\lib\signtool sign /tr http://timestamp.comodoca.com /td sha256 /fd sha256 /n StackQL $msiPath
        if ($LASTEXITCODE -ne 0) { throw "Signing $architecture MSI failed (exit $LASTEXITCODE)" }
    }

    Copy-Item -LiteralPath $msiPath -Destination ".\msi\stackql_windows_${architecture}.msi"

    Write-Banner "Creating $architecture ZIP"
    Compress-Archive -Path $exePath -DestinationPath $zipPath
    Copy-Item -LiteralPath $zipPath -Destination ".\msi\stackql_windows_${architecture}.zip"
}
