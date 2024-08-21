# chocolatey install for stackql

Creates a chocolatey package for stackql

## Update checksum in `chocolateyinstall.ps1`

run the following command in powershell from the root of the repository:

```powershell
.\update_checksum.ps1
```

## Bump the version

To bump the version, update the `version` and `releaseNotes` fields in `stackql/stackql.nuspec`.

```xml
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>stackql</id>
    <version>0.5.724</version>
    <releaseNotes>https://github.com/stackql/stackql/releases/tag/v0.5.724</releaseNotes>
    ...
```

## Build Locally

To build locally, run the following command in powershell (as Administrator) from the root of the repository:

```powershell
cd stackql; choco pack
```

## Test Locally

To install locally run:

```powershell
choco install stackql -dv -s "'.;https://chocolatey.org/api/v2/'"
```

To uninstall locally run:

```powershell
choco uninstall stackql
```

## Publish via GitHub Actions

New packages are automatically published to chocolatey.org via GitHub Actions when a merge to the `main` branch is performed.