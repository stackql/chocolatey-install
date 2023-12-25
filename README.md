# chocolatey install for stackql

Creates a chocolatey package for stackql

## Bump the version

To bump the version, update the `version` field in `stackql/stackql.nuspec` to the new version number.

```xml
<package xmlns="http://schemas.microsoft.com/packaging/2015/06/nuspec.xsd">
  <metadata>
    <id>stackql</id>
    <version>0.5.509</version>
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