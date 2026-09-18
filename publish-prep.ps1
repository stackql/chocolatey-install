# .\publish-prep.ps1 0.11.669
# .\publish-prep.ps1 v0.11.669
#
# Step 3 of the Windows release flow (run after release.ps1, from the root of
# this repo, once the releases proxy is serving the new MSI).
#
# Downloads the latest MSI from https://releases.stackql.io, confirms that its
# ProductVersion matches the version argument (nothing is installed), then
# updates the Chocolatey package files:
#   - chocolatey\tools\chocolateyinstall.ps1  (checksum64)
#   - chocolatey\stackql.nuspec               (version, releaseNotes)
#
# Commit and push the result to main to publish the package to Chocolatey.

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Version
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$msiUrl = 'https://releases.stackql.io/stackql/latest/stackql_windows_amd64.msi'
$nuspecPath = Join-Path $PSScriptRoot 'chocolatey\stackql.nuspec'
$installScriptPath = Join-Path $PSScriptRoot 'chocolatey\tools\chocolateyinstall.ps1'
$msiTempPath = Join-Path ([System.IO.Path]::GetTempPath()) 'stackql_windows_amd64.msi'

function Write-Banner([string]$Message) {
    Write-Host "*******************************************************************************"
    Write-Host $Message
    Write-Host "*******************************************************************************"
}

function Get-MsiProductVersion([string]$Path) {
    # Opens the MSI database read-only (mode 0) and reads the ProductVersion
    # property from the Property table. Nothing is installed or registered.
    $installer = New-Object -ComObject WindowsInstaller.Installer
    $db = $null
    $view = $null
    $record = $null
    try {
        $db = $installer.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $installer, @($Path, 0))
        $sql = "SELECT ``Value`` FROM ``Property`` WHERE ``Property`` = 'ProductVersion'"
        $view = $db.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $db, @($sql))
        $view.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view, $null) | Out-Null
        $record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)
        if ($null -eq $record) {
            throw "ProductVersion property not found in $Path"
        }
        return [string]$record.GetType().InvokeMember("StringData", "GetProperty", $null, $record, 1)
    } finally {
        if ($null -ne $view) {
            $view.GetType().InvokeMember("Close", "InvokeMethod", $null, $view, $null) | Out-Null
        }
        foreach ($obj in @($record, $view, $db, $installer)) {
            if ($null -ne $obj) {
                [System.Runtime.InteropServices.Marshal]::ReleaseComObject($obj) | Out-Null
            }
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
}

function Update-TextFile([string]$Path, [scriptblock]$Transform) {
    # Rewrites a text file in place, preserving whether or not it has a UTF-8 BOM
    # and without appending a trailing newline.
    $bytes = [System.IO.File]::ReadAllBytes($Path)
    $hasBom = ($bytes.Length -ge 3) -and ($bytes[0] -eq 0xEF) -and ($bytes[1] -eq 0xBB) -and ($bytes[2] -eq 0xBF)
    $text = [System.IO.File]::ReadAllText($Path)
    $newText = & $Transform $text
    $encoding = New-Object System.Text.UTF8Encoding($hasBom)
    [System.IO.File]::WriteAllText($Path, $newText, $encoding)
}

$expectedVersion = $Version.Trim() -replace '^[vV]', ''
if ($expectedVersion -notmatch '^\d+\.\d+\.\d+$') {
    throw "Invalid version '$Version' (expected major.minor.patch with or without a leading v, e.g. 0.11.669 or v0.11.669)"
}
foreach ($file in @($nuspecPath, $installScriptPath)) {
    if (-not (Test-Path $file)) {
        throw "Not found: $file"
    }
}

try {
    Write-Banner "Downloading latest MSI from the releases proxy"

    Write-Host "URL           : $msiUrl"
    $response = Invoke-WebRequest -Uri $msiUrl -OutFile $msiTempPath -UseBasicParsing -PassThru
    Write-Host "Size          : $((Get-Item $msiTempPath).Length) bytes"
    Write-Host "Last-Modified : $($response.Headers['Last-Modified'])"

    Write-Banner "Verifying version (nothing is installed)"

    $actualVersion = Get-MsiProductVersion $msiTempPath
    Write-Host "Expected : $expectedVersion"
    Write-Host "Actual   : $actualVersion"
    if ($actualVersion -ne $expectedVersion) {
        throw "The MSI currently served at $msiUrl is version $actualVersion, not $expectedVersion. If v$expectedVersion was just released, wait for the releases proxy to pick it up and try again."
    }

    Write-Banner "Calculating checksum"

    $checksum = (Get-FileHash -Path $msiTempPath -Algorithm SHA256).Hash.ToLower()
    Write-Host "SHA256 : $checksum"
} finally {
    Remove-Item $msiTempPath -Force -ErrorAction SilentlyContinue
}

Write-Banner "Updating Chocolatey package files"

Update-TextFile $installScriptPath {
    param($text)
    if ($text -notmatch "checksum64\s*=\s*'[^']*'") {
        throw "checksum64 entry not found in $installScriptPath"
    }
    $text -replace "(checksum64\s*=\s*)'[^']*'", "`$1'$checksum'"
}
Write-Host "Updated $installScriptPath"
Write-Host "  checksum64   : $checksum"

$releaseNotesUrl = "https://github.com/stackql/stackql/releases/tag/v$expectedVersion"
Update-TextFile $nuspecPath {
    param($text)
    if ($text -notmatch '<version>[^<]*</version>') {
        throw "<version> element not found in $nuspecPath"
    }
    if ($text -notmatch '<releaseNotes>[^<]*</releaseNotes>') {
        throw "<releaseNotes> element not found in $nuspecPath"
    }
    $text = $text -replace '<version>[^<]*</version>', "<version>$expectedVersion</version>"
    $text -replace '<releaseNotes>[^<]*</releaseNotes>', "<releaseNotes>$releaseNotesUrl</releaseNotes>"
}
Write-Host "Updated $nuspecPath"
Write-Host "  version      : $expectedVersion"
Write-Host "  releaseNotes : $releaseNotesUrl"

Write-Banner "Done"

Write-Host "Review the changes (git diff), then commit and push to main to publish to Chocolatey:"
Write-Host "  git add chocolatey"
Write-Host "  git commit -m `"v$expectedVersion`""
Write-Host "  git push origin main"
