# .\build.ps1 true

#
# NOTES:
# 1. File versioning will not work if the directory for this repo is a Dropbox, OneDrive dir etc
# 2. AV scanning needs to be temporarily suspended
#

$signparam=$args[0]

if ($signparam -eq "true") {
    $sign = $true
    Write-Output "Binaries and package will be signed. Ensure smart token is installed before pressing enter..."
    pause
} else {
    $sign = $false
} 

$cwd = Get-Location
$org = "stackql"
$repo = "stackql"

$Product = "StackQL - Query and Provision Cloud Services using SQL."
$FileDescription = "StackQL Executable"
$IconPath = ".\inc\stackql.ico"
$LegalCopyright = "Copyright (c) 2020-2025 StackQL Studios. All rights reserved."

Write-Output "*******************************************************************************"
Write-Output "Clearing msi and bin directories"
Write-Output "*******************************************************************************"

# Remove contents in the 'msi' directory
if (Test-Path -Path .\msi) {
    Get-ChildItem -Path .\msi\* -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Write-Output "'msi' directory contents removed."
} else {
    Write-Output "'msi' directory does not exist, skipping."
}

# Remove contents in the 'bin' directory
if (Test-Path -Path .\bin) {
    Get-ChildItem -Path .\bin\* -Force | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    Write-Output "'bin' directory contents removed."
} else {
    Write-Output "'bin' directory does not exist, skipping."
}

Write-Output "*******************************************************************************"
Write-Output "Downloading latest build from ${org}/${repo}"
Write-Output "*******************************************************************************"

Expand-Archive -Path "downloaded/stackql_windows_amd64.zip" -Force -DestinationPath "bin/"

Write-Output "*******************************************************************************"
Write-Output "Removing previous MSI and EXE"
Write-Output "*******************************************************************************"

Remove-Item -Path .\msi\* -Force -ErrorAction SilentlyContinue

Write-Output "*******************************************************************************"
Write-Output "Versioning EXE"
Write-Output "*******************************************************************************"

$VersionOutput = .\bin\stackql.exe --version
Write-Output $VersionOutput
$Version = ($VersionOutput -split '\n')[0].Split("v")[1].Split(" W")[0]
$env:StackQLBuildVersion = $Version
Write-Output "Version: ${Version}"

Write-Output "Setting File Properties..."
.\lib\rcedit-x86.exe .\bin\stackql.exe `
--set-product-version "${Version}" `
--set-file-version "${Version}" `
--set-version-string "ProductName" "${Product}" `
--set-version-string "FileDescription" "${FileDescription}" `
--set-version-string "LegalCopyright" "${LegalCopyright}" `
--set-icon $IconPath
Write-Output "File Properties Set..."

if ($sign) {
    Write-Output "*******************************************************************************"
    Write-Output "Signing EXE..."
    Write-Output "*******************************************************************************"
    .\lib\signtool sign /tr http://timestamp.comodoca.com /td sha256 /fd sha256 /n StackQL .\bin\stackql.exe
}

Write-Output "*******************************************************************************"
Write-Output "Compiling and Linking WiX source file using WiX v4..."
Write-Output "*******************************************************************************"

# Compile and link in one step with WiX v4
# wix.exe build .\stackql.wxs -o .\msi\stackql.msi
wix.exe build .\stackql.wxs -ext WixToolset.UI.wixext -o .\msi\stackql.msi

if ($sign) {
    Write-Output "*******************************************************************************"
    Write-Output "Signing MSI..."
    Write-Output "*******************************************************************************"
    .\lib\signtool sign /tr http://timestamp.comodoca.com /td sha256 /fd sha256 /n StackQL .\msi\stackql.msi
}

Write-Output "*******************************************************************************"
Write-Output "Renaming MSI..."
Write-Output "*******************************************************************************"

Rename-Item -Path ".\msi\stackql.msi" -NewName "stackql_${Version}_windows_amd64.msi"

Write-Output "*******************************************************************************"
Write-Output "Copying and Renaming MSI..."
Write-Output "*******************************************************************************"

Copy-Item ".\msi\stackql_${Version}_windows_amd64.msi" -Destination ".\msi\stackql_windows_amd64.msi"

Write-Output "*******************************************************************************"
Write-Output "Creating ZIP file from Signed EXE..."
Write-Output "*******************************************************************************"

Compress-Archive -Path ".\bin\stackql.exe" -Update -DestinationPath ".\msi\stackql_${Version}_windows_amd64.zip"
Copy-Item ".\msi\stackql_${Version}_windows_amd64.zip" -Destination ".\msi\stackql_windows_amd64.zip"
