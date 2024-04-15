$ErrorActionPreference = 'Stop'

# Define URLs and paths
$msiUrl = 'https://releases.stackql.io/stackql/latest/stackql_windows_amd64.msi'
$msiTempPath = Join-Path $env:TEMP 'stackql_windows_amd64.msi'
$installScriptPath = 'stackql\tools\chocolateyinstall.ps1'

# Download the MSI file
Invoke-WebRequest -Uri $msiUrl -OutFile $msiTempPath

# Display the created date of the downloaded MSI file
$msiFileInfo = Get-Item $msiTempPath
$msiCreationTime = $msiFileInfo.CreationTime
Write-Host "The creation date of the downloaded MSI file is: $msiCreationTime"

# Calculate the checksum
$checksum = (certutil -hashfile $msiTempPath SHA256)[1] -replace " ", ""

# Remove the temporary MSI file
Remove-Item $msiTempPath -Force

# Update the install script with the new checksum
$scriptContent = Get-Content $installScriptPath -Raw
$updatedScriptContent = $scriptContent -replace "(checksum64\s*=\s*)'.*'", "`$1'$checksum'"
Set-Content $installScriptPath -Value $updatedScriptContent -Force

Write-Host "Updated checksum in $installScriptPath"
